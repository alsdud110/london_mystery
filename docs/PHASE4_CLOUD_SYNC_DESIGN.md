# Phase 4 — 클라우드 동기화 설계 v2 (검토용 · 구현 전)

> **상태:** 설계 v2 (2026-10-14) — 사용자 결정 반영, dev-review 반영 · **4.1 규칙 구현됨(배포 없음, §12)** · 동기화 코드 없음 · 지갑 음수 정책 **R3 채택**(§4)
> **전제:** Phase 2의 `SaveJournal`·`Outbox`·`mergeCase`·`mergeWallet`·`SyncApplier`·epoch, Phase 3A-3의 `users/{uid}/profiles/{id}` + `consents/{uid}` 규칙, Phase 3B의 계정·프로필 화면, 계정 삭제 F안(미배포)을 그대로 쓴다.
> **표기:** `[OPEN]` 결정 필요 · `[LEGAL]` 법률 검토 · `[D]` 사용자 결정(2026-10-14)

## 0. 사용자 결정 `[D]`

| # | 결정 |
|---|---|
| D1 | **Coin 잔액은 음수가 될 수 없다.** |
| D2 | 게스트 데이터 가져오기는 **Phase 4b**로 분리. 게스트 데이터는 자동 업로드·자동 계정 연결하지 않는다. |
| D3 | 동의 미확인이면 **앱의 업로드와 다운로드 모두 차단.** |
| D4 | 규칙은 **본인 데이터 읽기 허용**(열람·복구·삭제 확인), 앱의 동기화 실행에는 동의 확인 필요. |
| D5 | 전송 시점: **로그인·복원 완료 후, 앱 활성화 시, 게임 진행 저장 후.** |
| D6 | 네트워크 장애 시 기존 **Outbox에 보관**하고 안전하게 재시도. |
| D7 | 충돌 데이터는 **자동으로 덮어쓰지 않고 충돌 상태를 기록.** |
| D8 | 클라우드 문서에 서버 기준 **`cloudVersion`**. |
| D9 | 쓰기는 **Firestore 트랜잭션**: 서버 데이터를 읽고 병합한 뒤 저장. |
| D10 | 지갑 이벤트 ID에 **epoch 포함**, 현재 epoch 이벤트만 복원. |
| D11 | 같은 이벤트 ID·다른 금액 = **영구 충돌**로 기록, 재시도하지 않음. |
| D12 | 일반 `permission-denied`만으로 **Outbox를 삭제하지 않는다.** |

## 1. 동기화 게이트 (모두 참일 때만 업로드·다운로드)

| 조건 | 어디서 |
|---|---|
| 클라우드 허용 빌드·환경 | `CloudDecision`(Operator 빌드 + PROD = 차단), 현재 PROD 이메일 로그인 꺼짐 → **DEV에서만** |
| 로그인 + 동의 확인 `[D3]` | 앱: `AccountState.cloudFeaturesAllowed`(업로드·다운로드 둘 다). 서버: 규칙 `canWrite`(쓰기만, 읽기는 `[D4]`로 본인 허용) |
| 계정 탐정 | `DetectiveProfile.syncable`(`kind == account`, `ownerUid == uid`, playtest·needsReview 아님) |
| 기록 단위 | Operator 기록(`playtest`) 제외(`SyncPolicy`) |
| 삭제 진행 중 아님 | 앱: 로컬 `deletionInProgress(uid)` 표시가 없을 것. 서버: 규칙이 `deletions/{uid}`가 있으면 쓰기 거부(§5.7) |

게이트가 닫히면 Sender는 **멈추기만** 하고 Outbox는 보관한다(`[D6][D12]`).

## 2. 클라우드 데이터 구조 (`users/{uid}/profiles/{pid}` 아래)

```text
profiles/{pid}                 (3A-3) schema, detectiveName, createdAt
  sync/meta                    epoch, cloudVersion, updatedAt(server)   ← 「새 모험」 세대, 증가만
  cases/{episodeId}            epoch, runId, runSeq, cloudVersion, progress{…}, updatedAt(server)
  season/state                 epoch, cloudVersion, solvedEpisodeIds[], updatedAt(server)
  wallet/summary               epoch, cloudVersion, balance(≥0), lastEventId, updatedAt(server)
  wallet/{epoch}_{entryKey}    epoch, key, amount, source, at           ← 생성만 `[D10]`
```

- `cloudVersion`: 문서마다 1부터, **쓰기마다 정확히 +1**(규칙 강제) `[D8]`. 기기별 `rev`는 로컬 병합 판단에만 쓰고 클라우드 순서에는 쓰지 않는다(dev-review P1).
- `progress`: 동기화 필요 필드만, `playtest` 회차 제외. 이메일·기기 ID 없음.
- 모든 문서는 `users/{uid}` 아래 → 계정 삭제 F안의 재귀 삭제가 전부 지운다.

## 3. 쓰기: 트랜잭션 + cloudVersion `[D8][D9]`

```text
syncSubject(subject):                          # case / season / wallet 묶음
  repeat up to 3 rounds:
    result = runTransaction(tx =>              # 콜백은 재실행될 수 있다 → 순수 계산만
      meta  = tx.get(sync/meta)                # 모든 쓰기는 현재 meta와 같은 트랜잭션에서 비교
      cloud = tx.get(subject doc) (+ wallet/summary)
      if meta.epoch > local.epoch:  return {decision: 'adoptCloudEpoch', meta, cloud}   # 쓰기 없음
      if local.epoch > meta.epoch:  return {decision: 'resetFirst'}                      # §3.1 먼저
      next = cloud.cloudVersion == local.baseVersion ? local : merge(local, cloud)       # 메모리 계산
      tx.set(subject doc, next with cloudVersion = cloud.cloudVersion + 1 (create: 1))
      return {decision: 'written', next, version})
    # ↓ 로컬 적용은 커밋(또는 쓰기 없는 결정) 뒤에 정확히 한 번만 (dev-review P1)
    switch result.decision:
      'written'         → 로컬에 next + baseVersion 저장(저널 커밋), 충돌 기록 [D7], 이벤트 ack, done
      'adoptCloudEpoch' → SyncApplier로 클라우드 epoch 적용(로컬 진행은 preserved), done
      'resetFirst'      → §3.1 실행 후 다음 라운드
  contention / abort  → 다음 라운드
  3라운드 후: release events, backoff (§5.8)
```

- 트랜잭션 콜백 안에서는 **로컬 저장·충돌 기록·Outbox 변경을 하지 않는다.** Firestore는 경합 시 콜백을 다시 실행하므로, 결정과 계산 결과만 반환하고 커밋된 뒤 한 번 적용한다.

### 3.1 「새 모험」(epoch 증가)의 서버 반영 (dev-review P1)

```text
resetEpoch():                                   # 로컬 resetAll 뒤 첫 동기화에서, 다른 대상보다 먼저
  runTransaction(tx =>
    meta = tx.get(sync/meta)
    if local.epoch > meta.epoch: tx.set(sync/meta, {epoch: local.epoch, cloudVersion: meta.cloudVersion + 1})
    return meta)
```

- 규칙: `sync/meta.epoch`는 **증가만**, cloudVersion +1. cases·season·wallet 쓰기는 `request.epoch == getAfter(sync/meta).epoch`(같은 트랜잭션의 meta 변경 반영)일 때만 허용 → 초기화가 서버에 반영되면 낡은 epoch의 늦은 업로드는 거부된다.
- 초기화한 기기가 오프라인이면 서버 meta가 아직 이전 epoch다. 그동안 다른 기기의 이전 epoch 업로드는 허용되지만, 초기화 기기가 접속하면 resetEpoch가 먼저 실행되고 이후 그 기기는 새 epoch만 올린다. 이전 epoch 문서는 내려받기에서 무시된다(현재 epoch만 적용).
- 테스트: A가 초기화(온라인) → 오프라인 B가 나중에 접속해 이전 진행 업로드 시도 → 거부, B는 새 epoch를 받고 이전 진행은 로컬 preserved.

- 같은 데이터 재전송은 `merge(x, x) == x`라 무해(멱등).
- 규칙: `create`는 `cloudVersion == 1`, `update`는 `request.cloudVersion == resource.cloudVersion + 1`, `epoch`는 `sync/meta.epoch` 이상, 같은 epoch에서 `runSeq` 감소 불가, `playtest` 거부, 필드 화이트리스트·크기 제한, `updatedAt == request.time`.

## 4. 지갑: 중복 지급 방지와 음수 금지 `[D1][D10][D11]`

- 항목 문서 ID = `{epoch}_{인코딩된 키}` → 같은 지급은 문서가 하나뿐(중복 불가), 「새 모험」 후 같은 키도 다른 문서.
- 규칙: 항목은 **create만**(수정·삭제 불가), 금액 화이트리스트, epoch = 현재 `sync/meta.epoch`.
- 음수 금지 `[D1]`의 문제: 두 기기가 오프라인으로 각각 마지막 Coin을 쓰면(TIP 2 −20씩), 합치는 순간 잔액이 음수가 된다. 방법별 비교 (dev-review P2: 클라이언트가 만드는 보정 항목은 **Coin 생성**이며 규칙으로 정당성을 증명할 수 없다):

| 안 | 동작 | 음수 | Coin 생성 | 서버 필요 | 신뢰 경계 |
|---|---|---|---|---|---|
| R1. 클라이언트 보정 항목 | 동기화 트랜잭션에서 덮지 못한 사용마다 `{epoch}_refund:{tipKey}` +20 | 없음 | **있음**(사용 1건당 1회) | 아니오 | 변조된 앱이 가짜 보정·요약을 만들 수 있음(규칙은 합계를 셀 수 없음) → "본인 계정에서 Coin을 만들 수 있다"를 수용해야 함 |
| R2. 서버 확정 보정(Functions) | 서버가 도착 순서로 처리, 덮지 못한 사용을 무료 도움(0)으로 확정 | 없음 | 없음 | **Blaze** | 서버 권위 |
| R3. 오프라인 유료 TIP 금지 | 오프라인에서 TIP 2는 항상 "무료 도움"(0) | 없음 | 없음 | 아니오 | 비행기 모드로 무료 TIP 가능, 오프라인 경제 규칙이 달라짐 |

- **결정 (2026-10-14): R3 채택.** 온라인에서는 기존 차감(TIP 2 = 20 Coin) 유지, 오프라인에서는 TIP 2를 무료로 제공하고 **차감 이벤트(−20)를 만들지 않는다**(TIP 소유 기록은 금액 0 항목). **R1 보정 지급은 허용하지 않는다**(규칙에 보정 출처 없음, Dart 테스트로 고정). Coin 잔액은 음수가 될 수 없다. 결제·광고 보상과 연결할 때 R2(서버 확정)를 재검토한다.
- 규칙(§12): 지갑 이벤트는 반드시 `wallet/summary`와 같은 쓰기에서 기록되고, 요약 잔액 = 이전 잔액 + 새 이벤트 금액, **0 미만 거부**. 그래서 두 기기가 동시에 온라인에서 마지막 Coin을 써도 서버에는 하나만 들어간다.
- **Coin 소비 전수 조사(2026-10-14):** 소비는 **TIP 2(−20) 하나뿐**. TIP 1은 항상 0, 그 밖의 출처(`start` 20, `mission` 30/60, `backfill` 30/60)는 지급뿐. 다른 소비 기능 없음(`WalletController.unlockTip`이 유일한 음수 항목 생성 지점).
- **R3 후속 구현(4.3, 게임 로직 변경 → 별도 승인):** 동기화 대상 탐정의 TIP 2 구매는 그 자리에서 클라우드 트랜잭션(이벤트 + 요약)으로 확정될 때만 −20, 오프라인·실패·잔액 부족이면 무료(0). 게스트·동의 미확인 탐정은 클라우드가 없으므로 지금처럼 로컬 규칙. 이미 로컬에 −20이 있는데 서버가 거부한 경우(동시 구매)는 영구 충돌로 기록(§4 위, `[D11]`)하고 잔액 보정 없이 사용자에게 표시하는 방식 `[OPEN]`.
- 화면 잔액은 항상 0 이상, TIP 소유는 유지(아이는 막히지 않음).
- 같은 ID·다른 금액: 기존 문서를 읽어 다르면 **영구 충돌** → 로컬 `conflicts`에 1회 기록, 그 이벤트 상태 `conflicted`(재시도 안 함), 잔액 변경 없음 `[D11]`.
- 복원: `sync/meta.epoch`와 같은 epoch 항목만 적용 `[D10]`.

## 5. 검토 항목 (사용자 지정)

### 5.1 여러 기기 동시 진행 — 데이터 손실 방지
cloudVersion 조건부 쓰기 + 트랜잭션 안 병합 → 낡은 기기는 덮어쓰지 못하고 먼저 병합한다. 같은 회차는 합집합(완료·증거·배지)·최댓값(시도·힌트), 다른 회차 충돌은 `preserved`로 기록 `[D7]`. 테스트: 두 기기가 서로 다른 미션 완료 → 둘 다 남음; 높은 rev의 낡은 기기 → 덮어쓰기 실패 후 병합.

### 5.2 「새 모험」 이후 과거 데이터 재등장 방지
epoch는 로컬·클라우드 모두 증가만. 낮은 epoch 쓰기는 규칙이 거부, 내려받기는 현재 epoch만 적용. 지갑은 ID에 epoch. 테스트: 초기화 전 오프라인 기기가 나중에 접속 → 이전 진행이 되살아나지 않고 그 기기가 새 epoch를 받음(이전 데이터는 로컬 `preserved`).

### 5.3 Coin 중복 지급 방지
지급은 키(`mission:<id>`) + epoch로 문서 1개(create-only). 같은 미션을 두 기기에서 풀어도 1회. Outbox도 키당 1개(기존). 테스트: 동시 지급 2회 → 1건; 재전송 → 1건.

### 5.4 오프라인 저장·재전송
저장은 항상 로컬 저널 커밋 먼저, 이벤트는 Outbox에. Firestore SDK 오프라인 쓰기 큐에 의존하지 않는다(트랜잭션은 온라인에서만) → Outbox가 유일한 대기열. 앱 재시작 시 `inFlight → pending`(기존). 테스트: 비행기 모드 플레이 → 재연결 후 전송, 중간 종료 후 재시작 전송.

### 5.5 계정 전환 시 격리
Sender는 로그인 uid 하나에 묶이고, 로그아웃·전환 즉시 중단(커밋 전 트랜잭션은 반영 안 됨, claim은 release). 다른 계정 탐정은 로컬에서 잠김(3B). 규칙이 경로 소유권 강제(3A-3). 테스트: 전환 중 전송 → 이전 계정 데이터가 새 계정 경로에 쓰이지 않음.

### 5.6 게스트 기록 보존 `[D2]`
게스트는 Sender 대상이 아니다. Phase 4b에서 "게스트 기록을 새 계정 탐정으로 **복사**"(원본 유지, 사용자 확인)만 검토. 테스트: 로그인·동기화 후 게스트 저장 바이트 동일.

### 5.7 삭제 진행 중 동기화 차단
앱: 삭제 확인 → 로컬 `deletionInProgress(uid)` 기록 → Sender 중단 → `deleteAccount` 호출. 서버: 규칙이 `exists(deletions/{uid})`이면 그 계정의 모든 쓰기 거부 → 다른 기기의 늦은 업로드가 삭제 후 데이터를 다시 만들지 못함.
- **삭제는 시작되면 되돌리지 않는다(한 방향, dev-review P2).** 함수가 `started` 기록을 만든 뒤 실패해도(일부 데이터가 이미 지워졌을 수 있음) 동기화를 재개하지 않는다. 모든 기기에서 그 계정은 "삭제 진행 중 — 다시 시도" 상태로 유지되고, 다시 시도는 같은 `deleteAccount`(멱등) 호출, 사용자가 다시 시도하지 않아도 서버 정리 작업(15분)이 마무리한다.
- `started` 기록이 생기기 전에 실패하면(호출 자체 실패·재인증 실패) 서버 표시가 없으므로 로컬 표시를 해제하고 정상으로 돌아간다(서버 `deletions/{uid}` 존재 여부를 읽어 판단).
- **다른 기기가 아는 방법(dev-review P3):** 규칙에서 `deletions/{uid}`의 **본인 get만 허용**(쓰기는 계속 서버만, 필드는 status·step·시각뿐). 모든 기기는 로그인·앱 활성화 때, 그리고 쓰기가 `permission-denied`일 때 `consents/{uid}`와 `deletions/{uid}`를 함께 읽어 원인을 분류한다(§5.8): 삭제 표시가 있으면 그 기기도 "삭제 진행 중 — 다시 시도" 상태로 들어가 동기화를 멈춘다.
- 로컬 Outbox 폐기는 `deleteAccount`의 성공 결과를 받았을 때만 `[D12]`.
- 테스트: 삭제 시작 후 다른 기기 업로드 거부, started 후 실패 → 동기화 재개 안 함·다시 시도로 완료, started 전 실패 → 정상 복귀.

### 5.8 cloudVersion 충돌 재시도 상한·복구
- 한 번의 동기화 안: 트랜잭션 재시도(SDK 기본) + 병합 라운드 **최대 3회**.
- 실패하면 이벤트 `release` + **지수 백오프**(30초 → 최대 1시간, 지터).
- 같은 대상이 **연속 10회** 실패하면 그 대상을 `stalled`로 표시하고 자동 재시도 중단 → 다음 앱 시작 또는 로그인 때 **전체 상태 재동기화**(로컬 전체 ↔ 클라우드 전체 병합) 1회 시도. 데이터는 로컬에 항상 남는다.
- 권한 거부(`permission-denied`): 응답만으로는 원인을 구분할 수 없으므로 **멈추고 보관**만 한다 `[D12]`. 이어서 `consents/{uid}`와 `deletions/{uid}`(본인 get 허용)를 읽어 분류: 삭제 표시 있음 → 삭제 진행 상태(§5.7), 동의 미확인 → 동의 대기, 둘 다 아님 → 규칙 위반으로 보고 해당 대상 `stalled`.

## 6. 전송 시점 `[D5]`

| 시점 | 동작 |
|---|---|
| 로그인 + 동의 확인 + 탐정 선택 | **복원 먼저**(내려받기·병합·세션 재생성), 그다음 대기 이벤트 전송 |
| 앱 활성화(foreground) | 게이트 확인 후 대기 이벤트 전송 |
| 게임 진행 저장 후 | 저널 커밋 직후 짧은 지연(디바운스 수 초) 후 전송 |
| 실패 | §5.8 |

## 7. 구현 단계 계획 (각 단계 승인 후 진행)

| 단계 | 범위 | 완료 기준 |
|---|---|---|
| 4.1 규칙 | `sync/meta`·`cases`·`season`·`wallet`·`deletions` 차단 규칙(cloudVersion +1, epoch 단조, create-only 지갑, 금액 화이트리스트, playtest 거부, 동의·삭제 게이트) | 에뮬레이터 규칙 테스트 통과. **배포 없음** |
| 4.2 매퍼·정책 | 로컬 저장 ↔ 클라우드 문서 변환, 동기화 게이트, 백오프·stalled 상태(Outbox `conflicted`/`stalled` 추가, 하위 호환) | Dart 단위 테스트(가짜 저장소) |
| 4.3 Sender | 트랜잭션 쓰기(콜백 순수, 커밋 후 1회 적용)·resetEpoch 선행·병합 라운드·지갑 음수 정책(결정된 안)·영구 충돌 | 가짜 클라우드 + Firestore 에뮬레이터 테스트(콜백 재실행 시 로컬 변경 1회 확인) |
| 4.4 복원 | 로그인 후 내려받기·병합·세션 재생성, 새 기기 복원(같은 프로필 ID) | 위젯·에뮬레이터 테스트 |
| 4.5 DEV 검증 | 전용 AVD 2대로 두 기기 시나리오(§5) | DEV E2E 통과, 테스트 데이터 정리 |
| 4b | 게스트 → 계정 복사(확인 화면) | 별도 승인 |
| PROD | 동의 절차·처리방침 확정 후 | 별도 승인 `[LEGAL]` |

## 8. 테스트 계획

| 영역 | 테스트 |
|---|---|
| 규칙(에뮬레이터) | `deletions/{uid}` 본인 get 허용·타인 거부·클라이언트 쓰기 거부, meta.epoch 증가만·cloudVersion +1, 다른 대상 쓰기의 epoch == getAfter(meta).epoch, 동의 없는 쓰기 거부, 본인 읽기 허용·타인 거부, cloudVersion +1만, 낮은 epoch 거부, runSeq 감소 거부, 지갑 create-only·금액 화이트리스트·epoch 일치, playtest 거부, `deletions/{uid}` 있으면 쓰기 거부, summary.balance ≥ 0 |
| 초기화(epoch) | A 초기화 후 오프라인 B 재접속 → 이전 epoch 업로드 거부, B가 새 epoch 채택·이전 진행 preserved |
| 병합(Dart) | 두 기기 다른 미션 → 합집합, 낡은 기기 높은 rev → 병합 후 기록, 같은 회차 재전송 멱등 |
| 지갑(Dart) | 동시 지급 1건, 초기화 전 지연 지급 무시, 오프라인 두 기기 TIP 구매 → 보정 항목으로 잔액 ≥ 0, 같은 ID 다른 금액 → conflicted·재시도 없음 |
| Sender(Dart) | 게이트(로그아웃·동의 없음·삭제 중·게스트·playtest) 시 전송 0, 오프라인 → 재연결 전송, 재시작 후 재전송, 3라운드·백오프·10회 stalled·재동기화, permission-denied에서 Outbox 유지 |
| 복원 | 새 기기 로그인 → 같은 탐정 복원, 현재 epoch만, 세션 재생성 후 화면 일치 |
| 격리 | 전송 중 계정 전환 → 이전 계정 데이터가 새 경로에 없음 |
| 게스트 | 모든 시나리오 후 게스트 저장 바이트 동일 |
| E2E(DEV) | 전용 AVD 2대: 동시 진행, 새 모험, 오프라인, 계정 전환 |

## 9. 남은 위험

- 지갑 음수 정책은 미결정(§4: R1/R2/R3). R1은 변조된 앱이 본인 계정 Coin을 만들 수 있다는 신뢰 경계를 수용해야 하고, R2는 Blaze가 필요하다.
- 초기화 기기가 오래 오프라인이면 그동안 다른 기기의 이전 epoch 업로드가 서버에 쌓인다(초기화 반영 후 무시되지만 문서는 남음 → 정리 정책 `[OPEN]`).
- 삭제는 시작 후 취소할 수 없다(서버 정리로 반드시 완료).
- 트랜잭션은 온라인에서만 → 오프라인이 길면 전송이 늦어진다(데이터는 로컬 보존).
- 본인 읽기 허용 `[D4]` → 동의 철회 후에도 변조된 앱은 본인 데이터를 읽을 수 있다(정책상 허용, 처리방침에 명시 `[LEGAL]`).
- 보정 항목은 Phase 2의 "같은 키 다른 금액 = 충돌" 원칙과 별개 키라 충돌하지 않지만, 로컬 `mergeWallet`에 `syncRefund` 출처 처리가 필요하다(4.2).
- PROD 동기화는 동의 절차·개인정보 처리방침 확정 전까지 불가.

## 12. Phase 4.1 — Firestore 규칙 (구현, 배포 없음, 2026-10-14)

### 12.1 구조 (`firebase/firestore.rules`)

| 경로 | 읽기 | 생성 | 수정 | 삭제 |
|---|---|---|---|---|
| `…/sync/meta` | 본인 | `canSync` + **epoch == 0**(클라우드 기준선) + cloudVersion==1 + 서버 시각 | `canSync` + **epoch 정확히 +1** + cloudVersion **정확히 +1** | 불가 |
| `…/cases/{caseId}` | 본인 | `canSync` + **출시된 사건 ID만**(ep01–ep12) + 필드 6개·자료형 + **progress 스키마**(허용 필드 20개·자료형, 미션 맵·완료 목록은 **그 사건의 미션 ID만**, 크기 제한, `playtest` 금지) + v1 + `epoch == getAfter(meta).epoch` | v+1 + 서버 epoch 일치 + 같은 epoch에서 `runSeq` 감소 금지 | 불가 |
| `…/season/state` | 본인 | v1 + 서버 epoch + 필드 4개, `solvedEpisodeIds`는 **출시된 사건 ID만**(≤ 12) | v+1 + 서버 epoch | 불가 |
| `…/wallet/{epoch}_{key}` | 본인 | id = `"{epoch}_{key}"`, 서버 epoch, 출처·키·금액 쌍 화이트리스트: start 20 / mission·backfill = **출시된 미션의 고유 금액**(일반 30, Final 60) / tip:1 0 / tip:2 0·−20(**출시된 미션만**), 같은 쓰기의 요약이 이 이벤트를 가리킬 것 | **불가**(생성만) | 불가 |
| `…/wallet/summary` | 본인 | v1, 잔액 == 첫 이벤트 금액 | v+1, 잔액 == (같은 epoch면 이전 잔액, 새 epoch면 0) + **이번 쓰기에서 새로 생긴** 이벤트 금액, **잔액 ≥ 0** | 불가 |
| `deletions/{uid}` | 본인 get | 불가(서버만) | 불가 | 불가 |
| 그 밖의 프로필 하위 경로 | 불가 | 불가 | 불가 | 불가 |

- `canSync(uid, pid)` = 본인 + 동의 `confirmed` + **`deletions/{uid}` 없음** + 프로필 문서 존재. 삭제 게이트는 공통 `canWrite`에 넣어 `users`·`profiles` 쓰기에도 적용(삭제 중 계정 문서 재생성 방지).
- 「새 모험」은 `sync/meta` epoch +1과 새 epoch의 첫 쓰기를 한 배치로 할 수 있다(`getAfter`). 첫 동기화 전에 여러 번 초기화한 기기는 0에서 한 단계씩 올린다.
- 출시 시즌 목록(`missionCoins()`·`episodeIds()`·`caseMissions()`)은 번들 카탈로그에서 생성했고, Dart 테스트가 카탈로그와 다르면 실패한다(콘텐츠 변경 시 재생성).
- Rules는 요청당 **1,000개 식** 제한이 있다 → 사건 미션 목록을 한 번만 만들어(`let`) 넘기고, 가장 큰 실제 진행(미션 6개 전부, 단어 300개)으로 예산 테스트를 둔다.

### 12.2 테스트 (`firebase/test/sync.rules.test.mjs` 27개 + 기존 33개 = 60개 통과)

epoch 기준선 0·정확히 +1(높은 초기값·건너뛰기 거부, 오프라인 다회 초기화는 한 단계씩), 가짜 미션 보상·금액 바꿔치기·가짜 미션 TIP 거부, 출시되지 않은 사건·다른 사건 미션·progress 미지 필드·자료형 오류 거부, 최대 크기 진행 예산 통과, cloudVersion 최초 1·정확히 +1·건너뛰기/반복/감소 거부, 다른 UID·비로그인 읽기·쓰기 거부, 본인 읽기 허용, 동의 미확인·클라이언트 동의 위조 거부, 삭제 중 모든 쓰기 거부·본인만 표시 조회, epoch 불일치·초기화 후 이전 epoch 쓰기 거부, 초기화 + 첫 쓰기 한 배치 허용, 같은 epoch 이전 회차 거부, 지갑 중복 생성 거부·수정/삭제 거부·요약 없는 이벤트 거부·합계 불일치 거부·0 미만 거부·보정/임의 금액·출처 거부·id epoch 불일치 거부, 새 epoch 잔액 재시작, 임의 필드·자료형 오류 거부, 존재하지 않는 프로필 거부. Dart: 규칙 금액 = `AppConstants`(보정 출처 없음) 확인.

### 12.3 규칙으로 검증할 수 없는 것 (클라이언트·서버 몫)

| 불변식 | 규칙의 한계 | 담당 |
|---|---|---|
| `progress` 값 하나하나의 자료형·범위(음수 시도 수, `xpRules` 1–4 밖 등) | 허용 필드·최상위 자료형·키 목록·크기는 확인, **맵 값·목록 원소는 하나씩 못 봄** | **4.2 변환기 정규화 필수**(§12.4). 지금 `fromJson`은 음수도 받으므로 변환기 없이 적용 금지 |
| 미션 보상이 **실제로 그 미션을 풀어서**인지 | 출시된 미션 ID와 그 금액만 확인(가짜 미션·금액 차단) | **신뢰 경계:** 변조된 앱은 본인 계정에서 아직 안 푼 실제 미션의 보상을 받을 수 있다. 한 epoch 잔액 상한 = 시즌 전체(시작 20 + 미션 1,860 = 1,880), 미션당 1회. epoch를 올리면 잔액이 0에서 다시 시작하므로 누적되지 않음. Coin에 가치가 생기면 R2(서버) |
| 「새 모험」을 정말 했는지 | epoch는 한 번에 +1만 | 본인이 반복해서 올리면 자기 이전 데이터만 무시됨(타 계정 무해) |
| 요약이 epoch의 **모든** 이벤트 합인지 | 쓰기마다 +1 이벤트만 확인(귀납적으로 일치), 규칙 밖(Admin) 쓰기는 대상 아님 | 서버 정리 시 재계산 가능(Functions) |
| 오프라인 무료 TIP 2 판정(R3) | 규칙은 금액 0을 허용할 뿐 "오프라인이었는지" 모름 | 클라이언트(조작 시 본인 계정 무료 TIP뿐) |
| `runId`·`at` 값의 진실성 | 형식만 | 클라이언트 |
| 계정 삭제 후 Auth 토큰이 남은 짧은 시간 | `deletions/{uid}`로 쓰기 차단, 읽기는 본인 허용 | 서버 삭제 순서(Auth 마지막) |

### 12.4 Phase 4.2 준비사항

- **클라우드 → 로컬 정규화(dev-review P3, 필수):** 규칙은 미션 맵의 값을 하나씩 검사하지 못하고, 지금의 `GameProgress.fromJson`(`intMap`)은 음수도 받아들인다. 그래서 변환기가 클라우드 값을 적용하기 전에 정규화한다: 시도·오답·힌트·풀이 시간·플레이 시간은 **0 이상 정수**, 힌트는 그 미션의 힌트 수 이하, `xpRules`는 **1–4**, 목록 원소는 문자열만. 범위 밖 값은 버리고 충돌로 기록. 기존 로컬 저장 해석(`fromJson`)은 바꾸지 않는다(로컬 데이터 무변경). 테스트: `attempts:{m01:-1}`, `hintsUsed:{m01:-9}`, `xpRules:{m01:99}` 정규화.
- 로컬 ↔ 클라우드 변환: `GameProgress` → `progress`(허용 필드 20개, 사건 미션만, playtest 회차 제외), 지갑 항목 → `{epoch}_{key}` 이벤트 + 요약, `cloudVersion`·`baseVersion` 로컬 보관(저장 형식은 새 키로 추가, 기존 형식 유지).
- Outbox 상태 추가: `conflicted`, `stalled`(하위 호환 디코딩).
- 동기화 게이트 객체(빌드·로그인·동의·삭제·탐정 종류)와 백오프 정책을 순수 함수로.
- R3 구매 흐름 설계(온라인 확정 트랜잭션 / 오프라인 무료)와 동시 구매 충돌 표시 `[OPEN]` — 게임 로직 변경이므로 별도 승인.
- 4.3 이전에 규칙 배포는 하지 않는다(DEV 배포도 별도 승인).


## 13. Phase 4.2 — 변환·검증·메타데이터·게이트·재시도 (구현, Firestore I/O 없음, 2026-10-14)

### 13.1 파일

| 파일 | 내용 |
|---|---|
| `lib/data/sync/cloud/cloud_catalog.dart` | 출시 시즌(사건·미션·TIP 수·보상)을 번들 카탈로그에서 생성. 규칙의 `missionCoins()`·`caseMissions()`와 같은 기준 |
| `lib/data/sync/cloud/cloud_codec.dart` | 로컬 → 클라우드 문서(`metaToCloud`, `caseToCloud`, `seasonToCloud`, `eventToCloud`, `summaryAfter`), 클라우드 → 로컬 검증(`readMeta`, `readCase`, `readSeason`, `readWallet`). 결과는 `CloudAccepted`(병합 가능) / `CloudStale`(이전 epoch: 적용·충돌 아님) / `CloudRejected`(적용 안 함, `conflictRecord()`로 충돌 저장) |
| `lib/data/sync/cloud/cloud_sync_meta.dart` | `lm.p.<id>.cloud.v1`(새 키, 게임 저장 형식 무변경): 대상별 확정 cloudVersion·epoch, 연속 실패, 다음 시도 시각, stalled, `needsFullResync` |
| `lib/data/sync/cloud/sync_retry_policy.dart` | 실행당 3라운드, 30초 → 2배 → 최대 1시간(지터 0.5–1), 10회 연속 실패 시 stall |
| `lib/features/sync/sync_gate.dart` | `SyncGate.check`(빌드·Firebase 준비, 로그인, 동의 confirmed, 삭제 진행 아님, 게스트 아님, 현재 계정 소유, Operator 프로필 아님, 검토 대기 아님)와 `SyncRun.stillValid`(쓰기·적용 직전마다 재확인 → 로그아웃·계정 전환·동의 변경·삭제·프로필 전환 시 중단) |
| `lib/data/sync/outbox.dart` | 상태 `conflicted`(영구 충돌, 자동 재시도·자동 해제 없음), `stalled`(다음 시작의 전체 재동기화까지 대기) + `markConflicted`·`markStalled`·`resumeStalled`. stalled 대상의 새 변경도 stalled로 대기 |
| `lib/data/repositories/progress_repository.dart` | `cloudSync` / `updateCloudSync`(저널 트랜잭션 안에서 확인 기록과 ack를 함께 커밋) |
| `lib/core/constants/app_constants.dart` | `cloudSyncKey` |

### 13.2 규칙

- **검증 실패는 보정하지 않는다:** 음수 정수, TIP 수 초과, `xpRules` 1–4 밖, 다른 사건의 미션, 미지 필드, 자료형 오류, 문서·진행의 run 불일치, epoch가 서버보다 앞섬, cloudVersion < 1 → 문서 전체 `CloudRejected`(지갑은 이벤트별), 로컬 데이터는 그대로.
- **epoch:** 서버 `sync/meta` epoch와 같은 문서만 병합. 이전 epoch는 `CloudStale`(무시), 지갑은 현재 epoch 이벤트만 복원.
- **cloudVersion:** `confirmed()`만 기록한다 — 서버 트랜잭션 커밋(또는 서버 상태 병합 완료) 뒤에만 호출. 확정값이 없으면(첫 동기화, 메타 소실, 전체 초기화 후) 항상 서버 사본과 먼저 병합하므로 안전. 다른 기기 초기화(`adoptEpoch`)는 메타를 유지(문서 버전은 계속 이어짐).
- **충돌·재시도:** permission-denied만으로 Outbox를 지우지 않는다(4.3 Sender가 상태를 읽어 분류). `conflicted`는 사람의 확인 전까지 그대로.
- **게스트:** Sync Gate가 항상 닫음(`guestProfile`).

### 13.3 R3 TIP 2 구매 상태 전이 (4.3 구현용, 이번 단계 구매 로직 변경 없음)

```text
[TIP 2 요청] (동기화 대상 탐정만; 게스트·동의 미확인은 지금처럼 로컬 규칙)
  ├─ 확실한 오프라인(연결 없음 확인) ───────────────→ [무료 TIP] 이벤트 0 (차감 없음)
  └─ 온라인 → 트랜잭션: summary 읽기 → 이벤트 {epoch}_tip:<m>:2 (−20) + summary
        ├─ 커밋 성공 ─────────────────────────────→ [유료 확정] 로컬 −20 기록, 확인 저장
        ├─ 서버가 잔액 부족으로 거부(balance < 20 확인) → [무료 TIP] 이벤트 0
        ├─ 이미 같은 이벤트 존재(재시도) ──→ 그 문서의 금액을 그대로 로컬에 반영(−20 또는 0)
        └─ 결과 불명(타임아웃·끊김) ──────→ [확인 대기] 같은 이벤트 ID로 서버 문서 조회
              ├─ 문서 있음 → 그 금액 반영
              └─ 문서 없음(확실) → 다시 시도 또는 오프라인이면 무료 TIP
  보정 Coin 없음 · 잔액 음수 없음 · TIP은 어떤 경우든 즉시 열림(아이는 막히지 않음)
```

테스트 시나리오(4.3): 온라인 성공, 잔액 부족 → 무료, 오프라인 → 무료(이벤트 0), 타임아웃 후 문서 있음/없음, 두 기기 동시 구매 → 한쪽만 −20, 재시작 후 확인 대기 재개, 게스트·동의 미확인은 기존 로컬 규칙.

### 13.4 테스트

`test/cloud_sync_test.dart` 48개: 카탈로그·규칙 필드 일치, 사건 왕복(현재 저장·예전 저장), Operator·미지 사건·다른 사건 미션 업로드 거부, 잘못된 클라우드 데이터 23종 거부, 이전 epoch 무시, 시즌·지갑 왕복과 거부, 요약 불일치 거부, 음수 요약 불가, 메타 검증, 확정 버전·백오프·stall·재시작 재동기화, 저장 키 분리·초기화/epoch 이동, 재시도 지연표, Outbox conflicted/stalled 전이와 하위 호환, Sync Gate 조건별 차단, 로그아웃·계정 전환·동의·삭제·프로필 전환 시 실행 중단.

### 13.5 dev-review 반영 (`qitem-20261013171957`)

- **지갑은 현재 epoch 단위로 전부 아니면 전무:** 현재 epoch 이벤트가 하나라도 잘못됐거나, 요약이 없거나·epoch가 앞서거나·`lastEventId`가 이번 epoch 이벤트를 가리키지 않거나·합계가 다르면 그 지갑은 적용하지 않는다(`accepted: false`, 빈 지갑). 이전 epoch의 잘못된 문서는 보고만 하고 현재 지갑을 막지 않는다. 음수·고아 차감 지갑은 노출되지 않는다.
- **메타데이터 형식 버전:** `lm.p.<id>.cloud.v1`은 `v == 1`일 때만 읽는다. 다른 버전·누락은 "확정 없음"(서버와 먼저 병합).
- **Outbox 형식 v2와 다운그레이드 계약:** 지금까지 배포된 어떤 빌드에도 전송기가 없으므로 예전 앱이 v2 이벤트를 보낼 수 없다. 이후 규칙: 이 빌드보다 새 형식(`v` > 2)이나 모르는 상태는 **conflicted**로 보관 — 자동 전송·자동 재개(`resumeStalled`) 모두 없음. 전송기는 자기가 모르는 형식에서 보내지 않는다.

## 14. Phase 4.3A — 전송 엔진 (에뮬레이터 검증, 2026-10-14, 실제 프로젝트 쓰기 없음)

### 14.1 파일

| 파일 | 내용 |
|---|---|
| `lib/data/sync/cloud/cloud_store.dart` | `CloudStore`/`CloudTx` 인터페이스(평문 맵, DateTime), `CloudFailure`(permissionDenied·aborted·unavailable·unknown), `SyncPaths` |
| `lib/data/sync/cloud/firestore_cloud_store.dart` | Firestore 플러그인 어댑터: Timestamp ↔ DateTime, `CloudServerTime` → `FieldValue.serverTimestamp()`, 오류 코드 매핑, 트랜잭션 최대 5회 |
| `lib/data/sync/cloud/sync_sender.dart` | 전송 엔진 `SyncSender`(아래) |
| `lib/data/sync/cloud/cloud_codec.dart` | `readEvent`·`summaryProblems` 분리(전송기 트랜잭션용), `CloudStale.cloudVersion` |
| `test/support/cloud_stores.dart` | 에뮬레이터 REST 저장소(사용자 토큰 → 실제 규칙 적용, SDK처럼 낙관적 트랜잭션: 읽기 재확인 + 쓰기 전제조건 + 재실행), 메모리 저장소, 장애 주입(`FaultyStore`: 오프라인·커밋 후 응답 유실·커밋 직전 경합) |
| `test/sync_sender_test.dart` | 메모리 13 + 에뮬레이터 12 시나리오 (`cd firebase && npm run test:sync`) |
| `integration_test/sync_adapter_emulator_test.dart` | 플러그인 어댑터 + 전송기, 시뮬레이터에서 로컬 Firestore·Auth 에뮬레이터만 (`DEVICE=<id> npm run test:sync-device`) |

### 14.2 동작

1. **epoch 먼저:** `sync/meta`가 없으면 0으로 만들고, 로컬이 앞서면 한 단계씩(+1) 올린다. 서버가 앞서면 로컬이 `adoptEpoch`(현 세대 저장은 충돌로 보존). 이전 세대 쓰기는 하지 않는다.
2. **사건·시즌:** 트랜잭션 안에서 서버 epoch 확인 → 서버 문서 읽기·검증 → 확정 버전이 아니면 병합(`mergeCase`/`mergeSeason`) → `cloudVersion + 1` 쓰기. 콜백은 계산·쓰기만 하고 결과를 반환. 커밋 후 한 번: `SyncApplier` 적용 + 버전 확정 + ack(한 저장).
3. **지갑:** 항목마다 트랜잭션: 같은 ID가 이미 있으면 같은 금액 → 확인만(재지급 없음), 다른 금액 → 영구 충돌; 없으면 이벤트 + 요약을 함께 쓰기(0 미만이면 쓰지 않고 영구 충돌).
4. **실패:** 경합(aborted) → 다음 라운드(최대 3); 네트워크·불명 → release + 백오프(10회 연속 stall); 권한 거부 → 동의·삭제 기록을 읽어 분류해 중단, 대기열 보존. 잘못된 서버 데이터 → 충돌 기록, 이벤트 conflicted, 서버·로컬 그대로.
5. **게이트:** 매 트랜잭션 전과 커밋 직후 `isStillValid`. 닫히면 중단·release, 로컬 적용 없음. 서버에 이미 커밋된 결과는 다음 실행이 병합으로 재조정(확정 버전이 다르므로).
6. **재시작:** `prepareAtStart` — stalled → 재개 + 전체 재동기화(이 기기가 플레이한 사건·시즌만; 플레이하지 않은 사건 내려받기는 4.4 복원).

### 14.3 검증된 시나리오

정상 전송, 중복 전송(새 쓰기 없음, 변경은 정확히 +1), 커밋 후 응답 유실(대기열 보존 → 재조정, 재지급 없음), 커밋 직전 다른 기기 경합(트랜잭션 재실행·병합·로컬 1회 적용), 두 기기 동시 진행(버전 1→2→3, 공통 start 1회), New Adventure(epoch 선행, 구 세대 기기 채택·구 데이터 미기록), 잘못된 서버 데이터(충돌 기록, 덮어쓰기·적용 없음), Coin 음수·같은 ID 다른 금액(영구 충돌, 재시작 후에도 재시도 없음), 권한 거부(동의·삭제 분류, 대기열 보존), 오프라인·백오프·10회 stall·재시작 전체 재동기화, 커밋 직전 게이트 닫힘(로컬 무변경·확정 없음·이후 재조정), 예전 저장·v1 Outbox 전송, 트랜잭션 본문 3회 재실행 시 지급 1회. 시뮬레이터: 플러그인 어댑터로 전송·서버 타임스탬프·권한 거부 매핑.

## 15. Phase 4.3B-1 — 앱 연결 (에뮬레이터 전용, 2026-10-14, 실제 프로젝트 접근 없음)

### 15.1 켜지는 조건

동기화는 DEV flavor에 `--dart-define=LM_CLOUD_EMULATOR=<host>`를 준 빌드에서만 켜진다(`CloudEmulator.forBuild`, PROD는 무시). 이 빌드는 Firebase 시작 직후, `ready`가 되기 전에 Auth·Firestore를 로컬 에뮬레이터로 돌린다(`CloudBootstrap.beforeReady`). 그 밖의 빌드(실제 DEV 포함)는 이전과 같다: 동의 저장소는 `UndecidedConsent`, 스케줄러 없음, 게임 데이터 읽기·쓰기 없음. 실제 DEV 연결은 4.3B-2.

### 15.2 파일

| 파일 | 내용 |
|---|---|
| `lib/core/cloud/cloud_emulator.dart` | 에뮬레이터 연결(1회), Firestore가 에뮬레이터를 쓰는지 확인 |
| `lib/features/sync/sync_scheduler.dart` | `SyncScheduler`: 실행 계획·직렬화·게이트·사전 확인·클라우드 프로필 생성·백오프 재시도 |
| `lib/features/sync/sync_session.dart` | `SyncSession`(프로필 세션 컨테이너 바인딩), `refreshFromSaves`·`reconcileWithSaves`(화면 반영) |
| `lib/data/sync/cloud/sync_sender.dart` | `onApplied`: 커밋 후 로컬 적용 직후 같은 동기 구간에서 알림 |
| `lib/data/repositories/progress_repository.dart` | `onQueued`: 게임 저장이 변경을 대기열에 넣으면 알림(계획만) |
| `lib/features/game/*` | `reloadFromSaves()`(사건·시즌·지갑): 저장소와 다를 때만 다시 읽음 |
| `lib/features/account/*` | `AccountController.refreshConsent()`, `FirestoreConsentRepository.lazy` |
| `lib/features/profile/profile_session.dart` | `onSessionStarted`(세션 시작·전환 알림) |
| `lib/main.dart` | 위 연결(iosApp 판단 유지) |

### 15.3 동작

1. **시점:** 로그인(동의 확인 포함), 앱 복귀(resumed), 게임 저장(2초 후, 연속 저장은 한 번으로). 백그라운드로 가면 계획 취소; 실행 중이던 실행은 끝나거나 끊기며, 끊긴 이벤트는 다음 시작에 복구된다.
2. **직렬화:** 기기 전체에서 한 번에 한 실행. 실행 중 요청은 끝난 뒤 한 번 더(연속 최대 4회, 이후 백오프 간격).
3. **세션 결합:** 실행은 시작 시점의 계정·프로필·세션 세대(`attach`마다 증가)에 묶인다. 로그아웃·계정 전환·프로필 전환(같은 프로필로 돌아와도)·동의 철회·삭제 진행 시 실행은 멈추고 로컬에 적용하지 않는다.
4. **사전 확인:** 매 실행 전에 서버의 `deletions/{uid}`(있으면 차단, 사라지면 해제)와 `consents/{uid}`(`confirmed` 아니면 계정 동의를 다시 읽어 차단)를 읽는다. 동의는 앱이 쓰지 않는다. 동의 미확정 상태에서는 복귀·로그인 때(그리고 1분에 한 번까지) 다시 읽는다.
5. **클라우드 프로필:** 처음 한 번 `users/{uid}`·`users/{uid}/profiles/{pid}`가 없으면 만든다(규칙의 `canSync` 조건). 탐정 이름이 없으면 보류.
6. **화면 반영:** 전송기가 병합을 저장한 직후 같은 동기 구간에서 해당 사건·시즌을 다시 읽는다(게임이 옛 상태로 덮어쓰지 못함). epoch 채택 시 사건·시즌·지갑을 다시 만든다. 실행 후 저장소와 화면 상태를 비교해 다르면 다시 읽는다. 입력 중인 답은 화면 위젯 상태라 유지된다.
7. **재시도:** 전송기 백오프의 다음 시각(대기 중인 주제와 `meta`)에 맞춰 계획. stall·충돌은 자동 재시도하지 않는다.

### 15.4 검증

- `test/sync_scheduler_test.dart`: 메모리 12 + 에뮬레이터 12(`npm run test:sync`, 실제 규칙).
- `test/sync_screen_refresh_test.dart`: 실제 퍼즐 화면에서 입력 중 병합 반영.
- `integration_test/sync_app_e2e_test.dart`: 실제 앱(`main`)으로 13단계(`DEVICE=<id> EMULATOR_HOST=<host> npm run test:sync-app`). 오프라인은 앱 저장소 앞단의 연결 차단으로 재현한다: Firestore `disableNetwork()`는 읽기만 막고 트랜잭션은 서버로 보낸다(실측).

## 16. Phase 4.3B-2 — 실제 DEV 연결과 두 기기 E2E (2026-10-14)

### 16.1 DEV 규칙 배포
- 배포 전 확인: CLI 활성 프로젝트 없음(`.firebaserc` 없음) → `--project london-mystery-dev` 명시, 서버에서 프로젝트 확인. 기존 DEV 규칙은 생성 당시 전체 거부(`ddb9cb89-dd2f-46c7-b69d-a56b3ae0fa33`, 2026-10-13). DEV Auth 사용자 0, Firestore 컬렉션 0(보존할 데이터 없음).
- `firebase deploy --only firestore:rules --project london-mystery-dev` (dry-run 후). 새 규칙셋 `4c8a4c0b-607a-4e53-baba-38c6947dac8e`, 서버에서 읽은 내용 = `firebase/firestore.rules`. 자동 롤백 없음(롤백은 별도 승인).

### 16.2 실제 DEV 동기화 켜기
`lib/core/cloud/cloud_sync_mode.dart`: DEV flavor + `--dart-define=LM_CLOUD_SYNC=dev`일 때만 `dev`. PROD·차단된 빌드는 어떤 옵션에도 `off`, 에뮬레이터 옵션이 우선. 일반 DEV 실행은 이전과 같음(동기화·동의 읽기 없음). 저장소를 만들 때 `Firebase.app().options`의 projectId와 플랫폼별 appId가 DEV와 같은지 다시 확인(아니면 실행 보류) — `CloudBootstrap`의 시작 시 확인에 더해.
- **operator 빌드 기준(결정 기록):** 사용자 지시는 "Operator 빌드에서는 PROD 접근을 계속 차단"이다. 따라서 operator(debug·`LM_PLAYTEST`) 빌드는 `LM_CLOUD_SYNC=dev`로 DEV에 동기화할 수 있고(통합 테스트가 모두 debug 빌드), PROD는 `CloudDecision`이 시작부터 막는다(`SyncPolicy.buildMayUseLiveCloud`: live cloud = PROD). operator 데이터(playtest 기록)는 어느 경우에도 보내지 않는다. 검토 요청 문구("operator 빌드에서 켜지지 않음")는 이 기준으로 정정한다. operator 빌드의 DEV 동기화까지 막으려면 사용자 결정이 필요하다(그 경우 실제 DEV E2E는 release/profile 빌드로 바꿔야 한다).

### 16.3 관리자 도구와 테스트 계정
`firebase/scripts/dev_admin.mjs`: Firebase CLI 로그인으로 REST 호출(서비스 계정 키 없음). 프로젝트 ID 상수 `london-mystery-dev`, 모든 URL이 그 프로젝트인지 검사, `--project` 인자 거부, 시작 시 서버에서 프로젝트 확인. 계정은 `lm-e2e-<run>-<role>@londonmystery.test`로 새로 만들고, 그 UID에만 `consents/{uid}`를 `currentDocument.exists=false`로 생성(기존 기록 변경 불가). 실행 기록 `build/dev-e2e/<run>.json`(git 제외). 정리는 그 실행의 UID 경로와 이메일 접두사가 맞는 계정만.

### 16.4 두 기기 E2E
`firebase/scripts/dev_two_device_e2e.mjs`(오케스트레이터: 계정·동의 시드, 장벽, 관리자 읽기, adb 네트워크 끄기·켜기, 결과 기록, 성공 시 정리·실패 시 보존) + `integration_test/sync_dev_two_device_test.dart`(역할 A/B). AVD `London_Mystery_DEV`(5560) · `London_Mystery_DEV_B`(5562).
제약: 다른 기기의 클라우드 프로필을 고르는 화면·복원이 없어(4.4) B는 프로필 레지스트리에 A의 프로필 ID를 등록해 같은 탐정을 고른다. 내려받기는 그 사건을 보낼 때 병합으로만 일어난다(변경 없는 사건의 풀은 4.4).

## 17. Phase 4.4 — 복원 (에뮬레이터·단위 테스트, 2026-10-14, 실제 DEV·PROD 접근 없음)

### 17.1 사용자 결정 (2026-10-14)
- operator(debug) 빌드: `LM_CLOUD_SYNC=dev`를 명시하면 DEV 동기화 허용(현행 유지). PROD는 항상 차단, operator 기록(playtest)은 보내지 않음, 계정 소유 일반 탐정만, Sync Gate 그대로, 옵션 없는 실행은 기존과 같음.
- 4.3B-2 완료 승인. DEV 규칙 유지, DEV에 추가 계정·데이터 없음.
- 4.4: 복원 구현. 충돌은 버리거나 합치지 않고 보류. 게스트 자동 가져오기 없음(별도 단계). 실제 DEV 추가 테스트는 별도 승인.

### 17.2 파일

| 파일 | 내용 |
|---|---|
| `lib/data/sync/cloud/sync_restorer.dart` | `download`(meta → cases 목록 → season → wallet 목록을 읽고 코덱으로 전부 검증. 하나라도 잘못되면 `DownloadInvalid`; 모두 읽은 뒤 meta를 항상 다시 읽어 epoch·버전이 바뀌었으면 `DownloadChanged` → 다시 읽기; dev-review P2), `apply`(한 번의 저장으로 병합 적용) |
| `lib/data/sync/cloud/cloud_store.dart` | `CloudStore.list`(컬렉션, 서버에서만 읽음), `SyncPaths.profiles/cases/wallet` |
| `lib/data/sync/cloud/firestore_cloud_store.dart` | `list` = `collection().get(Source.server)` |
| `lib/data/sync/cloud/cloud_sync_meta.dart` | `merged`: 내려받아 병합한 버전 기록, 실패 횟수·백오프·stalled는 유지 |
| `lib/features/sync/profile_restore.dart` | `ProfileRestore`: 계정 탐정 목록(`accountDetectives`), 선택한 탐정 복원(`restore`), `profileRestoreProvider` |
| `lib/features/sync/sync_scheduler.dart` | 세션 시작·로그인·앱 복귀 때 전송 전에 내려받기(pull), `exclusive`(복원은 실행과 겹치지 않음), `readAccountRecords`/`noteAccountRecords`(삭제·동의 기록 읽기 공용) |
| `lib/features/sync/sync_session.dart` | `refreshFromSaves('wallet')`: 내려받은 Coin을 같은 동기 구간에서 화면에 반영 |
| `lib/data/repositories/profile_store.dart` | `addRestored`: 클라우드와 같은 ID로 계정 탐정 추가(이미 있으면 거부) |
| `lib/features/account/ui/profile_screens.dart` | 탐정 선택 화면 "IN YOUR ACCOUNT": 이 기기에 없는 계정 탐정 → 눌러서 복원 후 플레이. 오류 문구·TRY AGAIN |
| `lib/main.dart` | 동기화하는 빌드에서만 `ProfileRestore` 생성·주입(iosApp 판단 유지) |

### 17.3 동작
1. **조회:** 로그인 + 동의 confirmed(기기·서버 기록 모두) + 삭제 진행 아님일 때만 `users/{uid}/profiles`를 읽는다. 이름·ID가 규칙에 맞지 않는 문서는 목록에서 뺀다. 이 기기에 이미 있는 탐정은 복원하지 않고 선택만 한다.
2. **복원(새 기기):** 모든 기록을 내려받아 검증 → 같은 계정이 아직 로그인돼 있으면 그 프로필 저장소에 한 번에 저장 → 그다음 레지스트리에 탐정 추가(클라우드와 같은 ID, `kind=account`, `ownerUid=uid`) → 화면이 그 탐정으로 전환. 실패·네트워크 오류·로그아웃·계정 전환이면 아무것도 저장하지 않는다(탐정도 추가되지 않음).
3. **검증:** 코덱 검증(§13) 그대로. 서버 epoch의 문서만 적용, 이전 epoch는 무시, 지갑은 현재 epoch 전부-아니면-전무. 잘못된 기록이 하나라도 있으면 복원 전체 중단(보정 없음).
4. **병합(기존 기록 보호):** 병합 규칙은 전송기와 같다(`SyncApplier`). 같은 회차는 합침, 더 나중 회차가 이김. **같은 회차 번호의 두 회차(충돌)는 보류:** 기기 저장은 그대로, 서버 회차는 `restoreHeld` 충돌 기록으로 보관, 버전 확인 안 함. 같은 Coin 키·다른 금액도 기기 항목 유지 + 충돌 기록. 서버가 더 나중 epoch이면 기존 「새 모험」 규칙(기기 저장을 충돌로 보관 후 새 epoch). 기기가 더 나중 epoch이면 아무것도 적용하지 않음(초기화 전송이 먼저).
5. **이미 있는 탐정의 내려받기(pull):** 세션 시작·로그인·앱 복귀 때 전송 전에 같은 방식으로 내려받아 병합 → 다른 기기가 진행한(이 기기가 플레이하지 않은) 사건도 들어온다. 화면은 같은 동기 구간에서 갱신(사건·시즌·Coin, epoch 채택 시 전체 재생성). 네트워크 오류는 백오프 후 재시도, 잘못된 기록은 충돌로 기록하고 적용하지 않음.
6. **재시작 안전:** stalled 대상의 재개(`prepareAtStart`)는 pull 전에 실행하고, pull의 버전 기록(`merged`)은 실패·stalled 상태를 지우지 않는다.
7. **게스트:** 목록·복원·pull 어디에도 쓰이지 않는다. 게스트 저장은 바이트 단위로 그대로(테스트로 확인). 게스트 → 계정 가져오기는 4b.

### 17.4 검증
- `test/sync_restore_test.dart`: 순수 4 + 메모리 8 + 에뮬레이터(실제 규칙) 8 — 새 기기 복원(사건·Coin·XP·시즌 일치), 계정 소유 탐정만 조회·이미 있는 탐정은 선택만·다른 소유 ID 거부, 두 기기 진행·Coin·XP 일치(양방향), 복원 중 네트워크 단절(처음·중간)·재시도, 복원 중 로그아웃·계정 전환, 잘못된 서버 데이터(사건·지갑 요약), 「새 모험」 이후 복원(새 epoch만), 복원 후 재시작·이어서 플레이, 회차 충돌 보류, Coin 충돌 보류, stalled 유지.
- `test/profile_restore_ui_test.dart`: 탐정 화면에서 복원 후 플레이, 오프라인 문구·TRY AGAIN(320×568), 잘못된 기록 문구.
- `integration_test/sync_restore_e2e_test.dart`: 실제 앱 + 로컬 Auth·Firestore 에뮬레이터(iOS 시뮬레이터, `npm run test:restore-app`) — 옛 기기 플레이·전송 → 새 기기처럼 탐정 제거·재시작 → 오프라인 문구 → 재시도 → 잘못된 기록 탐정 거부 → 복원·플레이 일치 → 이어서 플레이 → 재시작 후 그대로.
- `npm run test:sync`는 에뮬레이터를 비우는 테스트 파일들이 겹치지 않게 `--concurrency=1`.

### 17.5 남은 위험
- 보류한 회차 충돌은 기기에 기록만 된다(충돌 해결 화면 없음). 그 사건에 대기 중인 기기 변경이 있으면 기존 전송기 규칙(4.3)이 더 진행된 회차를 올리고 다른 회차는 기기에 보존한다.
- pull은 세션 시작·로그인·복귀마다 프로필 전체(사건 ≤ 12 + 지갑 문서)를 읽는다(읽기 비용).
- 내려받기는 문서별로 읽어 한 시점의 스냅샷이 아니다. epoch 변경(meta 변경)은 매 내려받기 끝에 확인해 다시 읽고, 문서별 병합은 순서와 무관하지만 매우 짧은 사이의 쓰기는 다음 pull에 반영된다.
- 실제 DEV에서의 복원·pull은 테스트하지 않았다(별도 승인). `sync_dev_two_device_test.dart`는 이번 변경 뒤 다시 실행하지 않았다.
- 복원 화면 문구는 영어(기존 계정 화면과 같음).

## 18. Phase 4.4 실제 DEV 복원 E2E (2026-10-14)

### 18.1 방법
- 프로젝트 `london-mystery-dev`만(규칙 `4c8a4c0b…` 그대로, 배포 없음). 시작 전: 사용자 0·컬렉션 0, 배포 규칙 = `firebase/firestore.rules`, Android DEV 앱 `com.londonmystery.app.dev`(`…android:588c5b…`), iOS DEV 앱 `com.londonmystery.app.dev`(`…ios:d5f9b8…`).
- `node scripts/dev_two_device_e2e.mjs --test integration_test/sync_dev_restore_test.dart --ios <udid>`: 기존 관리자 시드(테스트 계정 2개 + 그 UID의 동의만), 전용 AVD A(5560)·B(5562), 이어서 iOS 시뮬레이터 C. 모두 통과하면 그 실행의 UID 경로·계정만 삭제.
- 오케스트레이터 변경: `--test`(DEV 동기화 기기 테스트 파일만 허용)·`--ios`(전용 시뮬레이터 `London_Mystery_DEV_iOS`가 부팅돼 있을 때만, simctl로 이름 확인 후 시드 전에 거부; dev-review P2), `/net`은 응답 후 1.5초 뒤 차단(응답 유실 방지), 마지막 네트워크 복구 실패가 정리를 막지 않음. `dev_admin.mjs`: 시드 목적 문자열 인자, 읽기 전용 `users`(uid·이메일·시각·제공자만).

### 18.2 결과 (최종 실행 `rmv81203m`, 24/24 PASS, A·B·C 종료 코드 0, 자동 정리 13문서·2계정·잔여 0; 같은 결과를 `rmv7zt2iu`에서도 확인)
| # | 시나리오 | 관측 |
|---|---|---|
| 1 | A 로그인·탐정 생성 | ANNA, 계정 a |
| 2 | 진행·XP·Coin | m01, XP 30, Coin 50 |
| 3 | 서버 동기화 | 서버 사건 = A, 잔액 50, meta epoch 0 |
| 4 | B 같은 계정, 로컬 탐정 없음 | 레지스트리·저장 0 |
| 5 | IN YOUR ACCOUNT 목록 | ANNA 표시 |
| 6 | 선택·복원 | 사건 = 서버, XP 30(A와 같음), Coin 50, 시즌 같음, 소유 a, 충돌 0 |
| 7 | B 이어서 플레이·동기화 | 서버 m01·m02, 잔액 80 |
| 8 | A 반영 | A m01·m02, Coin 80, XP 60(B와 같음), A = 서버 |
| 9 | B 재시작 | 플레이 기록 변화 없음, B = 서버, 다시 제안 안 됨(서버 v3→4는 플레이 시계만) |
| 10 | 네트워크 단절(실제 adb 차단) | 오프라인 문구, 레지스트리·저장 무변경, 재연결 후 TRY AGAIN으로 목록(재연결 직후 Firestore가 아직 연결 중이면 한 번 더 눌러야 할 수 있음) |
| 11 | 복원 중 로그아웃·계정 전환 | 둘 다 `notAllowed`, 저장·탐정 추가 없음, 계정 b 목록 0 |
| 12 | 다른 기기 New Adventure | 서버 epoch 1·지갑 50, B epoch 1(m01만, 이전 기록은 충돌로 보존), 이후 저장에도 이전 epoch 재등장 없음, A도 같음 |
| 13 | 동시 변경(같은 회차 번호의 두 회차, B 오프라인) | B pull이 A 회차를 보류(`restoreHeld`), B 기록 덮어쓰기 없음, 두 기기 모두 두 회차 보관, 서버 회차 = B, 잔액 80(재플레이 0) |
| 14 | 게스트 | A·B·iOS 게스트 저장 동일, 계정에 업로드 없음 |
| iOS | 세 번째 기기 복원(전용 시뮬레이터 `London_Mystery_DEV_iOS`) | epoch 1, 사건 = 서버, Coin 50 = 서버, 게스트 유지 |

### 18.3 실행 이력·정리
- 1–2회(이하 11회까지): emulator-5560의 VM 서비스 연결 실패(시나리오 시작 전) → 전용 AVD 재부팅으로 해결. 3회: B 연결 끊김 → 5562 재부팅. 4–7회: 테스트 판정 수정(A의 플레이 시계, Firestore 맵 키 순서, 재시작의 플레이 시계, 오프라인 중 재시도 순서 고정, `/net` 응답 유실). 앱 결함은 발견되지 않음. 8회: 전부 통과했으나 마지막 네트워크 복구 adb 시간 초과로 자동 정리 전 종료(수동 정리). 9회: 재연결 직후 TRY AGAIN 1회로는 아직 연결 중 → 테스트가 다시 누르도록 수정. 10회: 5560 시스템 서비스 중단(`DeadSystemRuntimeException`)으로 시작 직후 종료 → 재부팅, 오케스트레이터가 시드 전에 네트워크를 켜도록 변경. 11회: 통과.
- 매 실행 뒤 그 실행의 UID 경로·계정만 삭제(남은 것 0 확인), 실행 기록의 비밀번호 제거. 최종: DEV Firestore 컬렉션 0, 테스트 계정 0.
- **테스트가 만들지 않은 DEV 계정 1개**가 실행 중에 생겼다(테스트는 `lm-e2e-…@londonmystery.test` 계정만 로그인하고 가입하지 않음 → 앱에서 직접 가입된 것으로 보임). 변경·삭제하지 않았다(식별 정보는 문서에 남기지 않음).

## 19. Phase 4.5 — 충돌 해결 UI: 조사와 구현 계획 (검토용 · 구현 전, 2026-10-14)

### 19.1 사용자 결정 (2026-10-14)
- Phase 4.4 실제 DEV 복원 검증 완료 승인. 테스트가 만들지 않은 DEV 계정은 삭제·변경하지 않는다. 기존 iPhone 17 Pro 시뮬레이터(`18DAC257…`)의 DEV 앱 로컬 데이터 초기화는 테스트 부작용으로 기록한다. 이후 E2E는 전용 테스트 기기에서만.
- `flutter analyze` info 1건(`test/case06_dialogue_test.dart:222`, 병합된 브랜치 파일)은 별도 정리 대상, 임의 수정하지 않음.
- 다음 단계 = Phase 4.5 충돌 해결 UI. 이번에는 조사·계획만(구현·실제 DEV/PROD 변경·배포·커밋 없음).

### 19.2 재연결 직후 첫 TRY AGAIN 실패 — 분석과 재현
- **근거:** 실제 DEV에서 시나리오 10에 도달한 실행은 7회(`rmv7ynodf`·`7yrt3g`·`7ywkcg`·`7z2fay`·`7zt2iu`·`80k80e`·`81203m`). 첫 TRY AGAIN이 실패한 것은 **9회(`rmv80k80e`) 1회뿐**이다. 최종 실행은 "listed after 1 TRY AGAIN press". 9회의 B(5562)는 같은 실행 끝에 `adb shell am force-stop`·`uninstall`이 시간 초과될 만큼 불안정했고, 그 실행의 두 번째 `unavailable` 로그는 테스트 시간 초과 뒤에 찍혔다(요청이 오래 걸린 뒤 실패).
- **경로:** 목록은 `FirestoreCloudStore.list` = `collection().get(Source.server)`. Firestore SDK는 연결이 오프라인으로 판정된 동안 서버 읽기를 즉시 `unavailable`로 실패시키고(캐시로 대체하지 않음), 연결이 돌아오면 다음 요청부터 성공한다. 앱은 실패 시 아무것도 바꾸지 않고 문구와 TRY AGAIN만 보여 준다(데이터 영향 없음).
- **재현 시도(실제 DEV 아님):** 전용 AVD `emulator-5562` + **로컬 Firestore 에뮬레이터**, 같은 adb 방식(`svc wifi/data disable` 30초 → enable)으로 7회 끊고 켬. 매번 오프라인 읽기는 즉시 `unavailable`(27–57ms), 재연결 감지 후 0초·1초·3초 뒤 첫 읽기 **7/7 성공**(63–215ms). **재현되지 않음.** 임시 프로브 파일은 실행 후 삭제.
- **결론:** 앱 로직 결함의 근거 없음(근본 원인은 확정되지 않음; dev-review도 같은 판단). 가장 그럴듯한 원인은 9회 당시 에뮬레이터(5562)의 네트워크·adb 불안정, 또는 실제 DEV(TLS·DNS·Google 프런트엔드)에서만 생기는 재연결 지연(로컬 에뮬레이터는 평문 연결이라 재현 범위 밖). 원인이 확정되지 않았으므로 **앱 로직은 바꾸지 않는다.** 실제 DEV에서 반복 측정하려면 별도 승인이 필요하다.

### 19.3 현재 충돌 기록 (조사)
저장: 프로필별 `lm.p.<pid>.conflicts.v1` = `{"items":[…]}`, `keepConflict`가 같은 `id`면 한 번만 추가. 기기에만 있고 서버로 가지 않는다. 화면·해결 경로 없음.

| kind | 생기는 곳 | 기기 저장 | 서버 | 레코드 내용 |
|---|---|---|---|---|
| `restoreHeld` | 내려받기(`SyncRestorer.apply`): 같은 회차 번호의 다른 회차 | 그대로 | 서버 회차 그대로 | `subject: case:<id>`, `cloud`(서버 회차 전체), `cloudVersion`, `reason` |
| `case` | 전송·병합(`SyncApplier.applyCase`): 같은 회차 번호 충돌 → **더 진행된 회차(해결 미션 수 → rev → 플레이 시간 → 기기)가 자동으로 이김** | 이긴 회차 | 이긴 회차 | `subject: <id>`(접두사 없음), `kept`(진 회차), 어느 쪽이 졌는지 표시 없음 |
| `wallet` | 같은 Coin 키·다른 금액(내려받기: `local`·`remote` / 전송: `local`·`cloudAmount`), 서버 잔액이 0 아래가 될 쓰기(`walletBelowZero`) | 기기 항목 유지, 그 Outbox 이벤트는 `conflicted`(자동 재시도 없음) | 서버 항목 유지(지갑 이벤트는 생성 전용) | |
| `epoch` | 다른 기기의 「새 모험」 채택(`adoptEpoch`) | 새 epoch로 비움 | 새 epoch | `local`: 이전 epoch의 모든 사건·시즌·지갑 |
| `cloudInvalid` · `localShape` | 검증 실패 서버 문서 / 클라우드 형식에 맞지 않는 기기 저장 | 그대로 | 그대로 | 사유만 |

관찰:
1. **사용자가 고를 수 있는 실제 충돌은 "사건 회차"뿐이다.** 회차 충돌은 두 기기가 같은 사건을 각각 처음 시작(또는 같은 회차에서 각자 다시 하기)했을 때만 생긴다.
2. **XP는 저장값이 아니다.** 사건 저장의 해결 미션과 `xpRules`에서 계산된다(`XpBreakdown`) → 어느 회차를 고르느냐로 결정된다.
3. **Coin은 회차와 무관하다.** 미션 보상 키 `mission:<id>`는 "평생 1회"이고 지갑은 키 합집합이라, 회차를 바꿔도 Coin은 늘거나 줄지 않는다. Coin 충돌은 사실상 TIP 2 키(`tip:<m>:2`)가 한 기기에서 −20, 다른 기기에서 0(잔액 부족·오프라인)인 경우뿐이다.
4. `restoreHeld`는 오래 머물지 않을 수 있다: 그 사건에 보낼 변경이 있으면 다음 전송에서 4.3 규칙이 자동으로 승자를 정하고 `case` 레코드가 추가된다(같은 두 회차가 레코드 2개로 남을 수 있음).
5. **보존 공백:** 이 기기에서 「새 모험」(`clear`)을 하면 충돌 기록도 함께 지워진다. "나중 회차가 이김" 규칙은 진 회차를 보존하지 않는다(같은 기기의 Play again에는 맞지만, 다른 기기에 보내지 않은 진행이 있던 회차는 사라질 수 있음).
6. 레코드에 시각·epoch·출처(기기/서버)·처리 상태가 없다.
7. 서버 규칙은 사건 문서 필드를 `hasOnly`로 고정하고 `runSeq`는 줄어들 수 없다(`>=`). → 새 필드는 규칙 변경·배포가 필요하지만, **`runSeq`를 올리는 해결은 규칙 변경 없이 가능**하다.

### 19.4 해결 방식 (제안)
**원칙:** 플레이를 막지 않는다. 아무것도 버리지 않는다. 고르지 않은 회차는 항상 보관한다. Coin은 해결로 바뀌지 않는다.

1. **해결 단위 = 사건 하나.** 같은 사건·같은 epoch의 열린 `restoreHeld`·`case` 레코드를 회차(`runId`+내용)별로 묶어 "지금 플레이 중인 기록"과 "다른 기록"으로 보여 준다(중복 레코드는 하나로).
2. **"이 기록으로 계속하기" = 고른 회차를 새 회차 번호로 다시 저장:** 내용은 고른 회차 그대로, `runSeq = max(두 회차, 서버) + 1`, 새 `runId`. 기존 "나중 회차가 이김" 규칙으로 서버·다른 기기 모두 같은 회차로 수렴한다(규칙·서버 변경 없음, 일반 저장처럼 Outbox → 전송).
   - 서버 기록 선택: 서버(또는 다른 기기) 회차를 기기에 적용 + 위처럼 전송. 지금 기기 기록은 보관.
   - 기기 기록 선택: 기기 회차를 새 회차 번호로 전송. 서버 회차는 보관(이미 레코드에 있음).
   - 나중에 결정: 아무것도 바꾸지 않음. 지금처럼 진행된 쪽으로 계속 플레이·동기화되고, 표시만 남는다.
3. **같은 회차 번호 충돌의 결정적 동점 처리(dev-review P2, `qitem-20261014134242`):** 지금 `_furtherAlong`(`merge.dart`)은 해결 미션 수·rev·플레이 시간이 모두 같으면 **기기 쪽**을 고른다. 두 기기가 오프라인에서 같은 사건을 서로 다르게 해결하면(같은 `max+1` 회차 번호, 다른 `runId`, 같은 수치) 각 기기가 자기 회차를 골라 서버를 번갈아 덮을 수 있다. → 마지막 동점 처리를 "기기"가 아니라 **`runId` 비교(양쪽에서 같은 결과)**로 바꾼다. 앞의 비교는 이미 대칭이므로 모든 기기·서버가 같은 승자를 고르고 수렴한다. 진 회차는 각 기기에 보관(아래 4). 테스트: 동점 수치 + 동기화 순서 A→B·B→A 모두 같은 서버 결과, 반복 동기화에도 서버 회차가 바뀌지 않음.
4. **다른 기기 보호(병합 규칙 보강, 로컬 코드만):** "나중 회차가 이김"에서 진 쪽에 플레이 기록이 있고 그 내용이 승자와 다르면 `case` 레코드로 **보관만** 한다(`reason: later run`, 결정 필요 아님 → 화면에는 "보관된 기록"으로만). 이로써 해결 결과를 받는 기기의 보내지 않은 진행도 사라지지 않는다.
5. **Coin 충돌은 아이에게 묻지 않는다(제안):** 화면 잔액은 바꾸지 않고(현재 규칙 유지) 레코드만 보관. 서버 금액으로 맞출지는 R3 TIP 2 구매 로직과 묶여 있어 **이번 단계 범위 밖**(별도 승인). 화면에는 "Coins are safe"만.
6. **epoch·cloudInvalid·localShape:** 선택지 없음. `epoch`는 "보관된 기록"(읽기 전용), 나머지는 아이에게 보이지 않고 진단용으로만 남긴다.
7. **레코드 v2(하위 호환):** 새 레코드에 `at`(보관 시각), `epoch`, `side`(device/account), `status`(open/resolved/archived), `resolvedAt`, `choice`를 추가. 기존 레코드는 읽을 때 `side` 추정(`restoreHeld`=account, `case`=알 수 없음 → "다른 기록"). 해결해도 **레코드는 지우지 않고 `resolved`로 바꾼다.** 보관 상한(사건당 최근 N개, 예: 10)을 넘을 때만 가장 오래된 `resolved`/`archived`부터 정리(열린 것은 절대 정리하지 않음) — N은 승인 항목.
8. **「새 모험」과 충돌 기록:** 지금은 `clear()`가 함께 지운다. 제안: 「새 모험」은 충돌 기록을 `archived`로 남기고, **탐정 삭제·계정 삭제**에서만 지운다(승인 항목).

### 19.5 화면 흐름 (아이 사용자)
- **알림 위치:** ① 탐정 선택 화면의 그 탐정 줄에 작은 표시("2 case files"), ② 시즌 화면의 해당 사건 카드에 표시, ③ 해당 사건을 열 때 한 번 시트로 안내. 앱 시작 시 팝업으로 막지 않는다.
- **비교 화면 "Two case files"(가칭):** 같은 사건의 두 기록을 위아래 두 장의 사건 파일 카드로. 각 카드: 출처(`ON THIS DEVICE` / `IN YOUR ACCOUNT`), 해결한 미션 점(●●○○), XP, 마지막 플레이(“Today”, “2 days ago”), 지금 플레이 중이면 `PLAYING NOW`. 더 진행된 쪽에 `FURTHER ALONG` 표시. Coin 줄은 한 번만: "Your coins stay the same."
- **선택:** 각 카드의 주 버튼 `KEEP PLAYING THIS ONE`, 아래 보조 버튼 `DECIDE LATER`. 선택 뒤 확인 시트 한 번: "We'll keep the other file safe. You can look at it later." → `OK`.
- **문구 원칙:** "conflict·overwrite·delete·error"를 쓰지 않는다. 짧은 문장, 한 화면 한 질문, 숫자보다 점·도장. 기존 화면처럼 영어(한국어 문구는 별도 결정).
- **보관된 기록:** 탐정 화면 하단 `SAVED CASE FILES`(읽기 전용 목록). 이번 단계에서는 보기만(되살리기는 다음 단계 후보).
- 디자인: 기존 `GameButton`·`Paper`·사건 파일 카드·`AppText`·`AppColors`만 사용, 320×568에서 한 화면에 두 카드가 들어가도록(스크롤 허용).

### 19.6 해결 중 계정 전환·네트워크 단절·재동기화
- **해결은 기기 저장만 바꾼다(한 번의 저널 트랜잭션):** 고른 회차 저장 + 다른 회차 보관 + 레코드 `resolved` + Outbox 등록. 네트워크가 없어도 끝나고, 전송은 기존 Outbox·백오프가 맡는다.
- **유효성 확인:** 적용 직전(동기) 같은 계정·같은 프로필·같은 세션·같은 epoch인지, 그리고 화면을 연 뒤 그 사건 저장·레코드가 바뀌지 않았는지(내용 해시) 확인. 다르면 아무것도 바꾸지 않고 비교 화면을 새로 그린다. 계정이 바뀌면 화면을 닫는다(다른 계정의 기록은 보이지 않음 — 레코드가 프로필 네임스페이스에 있음).
- **동기화 실행 중:** 해결은 `SyncScheduler.exclusive`로 실행 사이에 적용(복원과 같은 방식). 적용 후 같은 동기 구간에서 화면 재읽기(`refreshFromSaves('case:<id>')`).
- **다른 기기:** 다음 pull·병합에서 "나중 회차가 이김"으로 같은 회차가 된다. 그 기기의 다른 회차는 19.4-4에 따라 보관. 두 기기가 오프라인에서 서로 다른 선택을 하면 같은 새 회차 번호의 두 회차 → 다시 충돌: 진행된 쪽, 수치가 같으면 `runId` 비교로 **모든 기기가 같은 승자**(19.4-3), 다른 쪽은 보관하고 다시 표시. 데이터 손실·서버 번갈아 덮기 없음.
- **해결 중 「새 모험」이 다른 기기에서 일어나면:** epoch가 바뀌어 적용 거부(위 확인), 기존 epoch 규칙대로 보관.

### 19.7 구현 단계 (승인 후, 각 단계 dev-review)
| 단계 | 내용 | 검증 |
|---|---|---|
| 4.5-1 | 레코드 v2 읽기·쓰기(하위 호환), 사건별 묶기, 보관 상한, `clear()`의 충돌 기록 처리(결정에 따라), "나중 회차" 진 쪽 보관, 같은 회차 번호 동점의 `runId` 동점 처리(동기화 순서 바꿔도 같은 결과) | 순수·메모리 단위 테스트 |
| 4.5-2 | `ConflictResolver`(선택 적용·유효성·exclusive·Outbox) | 메모리 + Firestore 에뮬레이터(두 기기 수렴, 오프라인 선택, 계정 전환, 동시 다른 선택, 재시작) |
| 4.5-3 | 화면(표시·비교·선택·나중에·보관 목록) | 위젯 테스트(320×568·큰 화면, 스크린샷), 기존 테스트 전체 |
| 4.5-4 | 로컬 에뮬레이터 앱 E2E(iOS 시뮬레이터) | `npm run test:*` |
| 4.5-5 | 실제 DEV 두 기기 E2E | **별도 승인**, 전용 AVD·전용 시뮬레이터만 |

규칙·Functions·서버 데이터 형식 변경 없음(배포 불필요). R3 TIP 2 구매 로직·게스트 가져오기는 포함하지 않는다.

### 19.8 승인이 필요한 결정
1. 해결 방식: 고른 회차를 새 회차 번호로 다시 저장(19.4-2) — 권장.
2. 병합 규칙 변경 두 가지: "나중 회차가 이김"에서 진 쪽 보관(19.4-4), 같은 회차 번호 동점은 기기 대신 `runId`로 결정(19.4-3).
3. Coin 충돌은 표시·보관만, 금액 맞추기는 R3와 함께 별도(19.4-5).
4. 보관 상한 N(제안 10/사건)과 「새 모험」 때 충돌 기록 유지(19.4-7·8).
5. 화면 문구 언어(영어 유지 / 한국어).

## 20. Phase 4.5-1~4 — 충돌 해결 구현 (로컬·에뮬레이터, 2026-10-14, 실제 DEV·PROD 접근 없음)

### 20.1 사용자 결정 (2026-10-14)
§19.8 승인: 고른 기록을 새 회차 번호로 다시 저장, 병합에서 진 회차 보관, 결정적 동점 처리, Coin 충돌은 표시·보관만, 「새 모험」 이후에도 충돌 기록 보존, 화면 문구 영어. 보관 기준 사건당 10개(초과 시 자동 삭제 없음, 안전하게 보관할 수 없으면 해결 중단). 4.5-5(실제 DEV 두 기기)는 진행하지 않음.

### 20.2 파일
| 파일 | 내용 |
|---|---|
| `lib/data/sync/case_conflicts.dart` (새) | 기록 v2(`v`·`caseId`·`runId`·`runSeq`·`side`·`epoch`·`at`·`status`), 상태 `open`/`waiting`/`resolved`/`archived`(v2 이전 기록은 종류·사유로 추정), 사건별 선택 `choiceFor`(현재 epoch, 플레이 중 회차와 다른 열린 기록, 같은 회차는 하나로), `choose`(지문 재확인 → 새 회차 번호 저장 + 기록 상태 변경 + Outbox, 한 번의 저장), `noteOnServer`(서버 반영 시 resolved), `settle`(병합 후 정리), `archiveAll`(epoch 변경) |
| `lib/data/sync/merge.dart` | 같은 회차 번호 동점: 해결 미션 수 → rev → 플레이 시간 → **runId → 저장 내용** 비교(기기 쪽 우선 제거). 나중 회차가 이길 때 진 회차에 승자에 없는 플레이가 있으면 `preserved`(`sameProgress`: 회차 식별·rev·플레이 시간 제외 비교) |
| `lib/data/sync/sync_applier.dart` | 보존 기록 v2(출처: 진 쪽이 기기 저장이면 device, 아니면 account), 전송기가 넘긴 서버의 진 회차 보관, 적용 후 `settle` |
| `lib/data/sync/cloud/sync_sender.dart` | 트랜잭션 병합에서 기기 회차가 이기면 덮어쓰는 서버 회차를 기기에 보관(`_Written.serverRun`), 사건 전송 후 `noteOnServer`, Coin 충돌 기록 v2 |
| `lib/data/sync/cloud/sync_restorer.dart` | 회차 충돌은 **그 사건의 미전송 변경이 있을 때만** 보류(`restoreHeld` v2). 미전송 변경이 없으면 규칙의 승자를 적용하고 진 회차 보관(모든 기기가 같은 회차). 서버에 이미 있는 선택은 `noteOnServer` |
| `lib/data/repositories/progress_repository.dart` | `updateConflicts`(기록 삭제 불가 검사), `clear()`(「새 모험」)가 충돌 기록을 남기고 archived로, `adoptEpoch`도 archived로, 읽기 전용 `peek` |
| `lib/features/sync/sync_scheduler.dart` | `runNow`: 서버 기록을 먼저 내려받는 실행을 지금 하고 끝날 때까지 대기 |
| `lib/features/sync/case_file_choice.dart` (새) | `CaseFileChooser`: 계정·탐정 유효성 확인 → `runNow`(오프라인이면 건너뜀) → 다시 확인 → `choose` → 화면 갱신 |
| `lib/features/sync/ui/case_files_screen.dart` (새) | 비교 화면 `CaseFilesScreen`(`/case-files/:id`), `TwoFilesTag`, 사건 진입 1회 안내 `offerTwoFilesOnce` |
| `profile_screens.dart` · `season_screen.dart` · `investigation_board.dart` · `episode_select_screen.dart` · `app_router.dart` · `main.dart` | 탐정 줄 "A CASE HAS TWO FILES", 보드 사건 "2 FILES" 태그(스크린리더 문구 포함), 사건 폴더 "TWO CASE FILES · CHOOSE ONE", 사건 시작 시 1회 안내, 라우트, 동기화 빌드에서 `CaseFileChooser(sync)` 주입 |

### 20.3 규칙
- **회차 번호 ≠ epoch:** 해결은 `runSeq = max(두 회차) + 1`, epoch는 그대로(확인 후 적용). 서버 규칙(`runSeq` 감소 불가, 필드 고정)은 바꾸지 않음.
- **결정적 해결 회차 ID:** `FNV-1a(선택한 회차 ID, 그 회차 번호, 새 번호)` → 같은 선택을 다시 하거나 두 기기가 같은 파일을 고르면 같은 회차(회차 번호가 더 오르지 않고, 같은 회차로 합쳐짐).
- **보존:** 기록은 지우지 않고 상태만 바뀐다. 선택하지 않은 플레이 중 회차는 `not chosen`(archived)으로 새로 보관. 플레이 중 회차보다 낮은 회차 번호의 열린 기록(다른 기기에서 이미 선택됨, Play again)은 묻지 않고 archived.
- **전송 대기 구분:** 선택 직후 `waiting`, 서버가 그 회차를 가진 것을 확인하면 `resolved`. 다른(더 나중) 회차가 대신 들어오면 `archived`(그 회차는 병합이 보관, 필요하면 다시 묻는다).
- **재검증:** 선택 직전 서버를 다시 내려받고, 화면이 보여 준 저장(플레이 시간·rev 제외)과 기록이 그대로일 때만 적용. 다르면 `changed`(아무것도 안 바뀜, 다시 보여 줌).
- **보관 한도:** 선택에 새 기록이 필요하고 그 사건(현재 epoch)에 이미 10개 이상이거나 기록 전체가 512KB를 넘으면 `cannotKeep`(아무것도 안 바뀜, 보호자 도움 문구). 동기화 병합의 자동 보관은 한도와 무관하게 항상 보관.
- **Coin·XP:** 선택은 지갑을 건드리지 않는다. XP는 고른 회차의 해결 미션에서 계산(지급 기록 없음 → 중복 지급 불가).
- **격리:** 기록은 탐정 네임스페이스(`lm.p.<pid>.conflicts.v1`). 계정·탐정이 바뀌면 `stopped`.

### 20.4 화면 (영어, 기존 디자인 시스템)
- 탐정 선택 화면: 계정 탐정 줄에 버건디 "A CASE HAS TWO FILES". Coin 충돌(현재 epoch의 열린 `wallet` 기록)이 있으면 "COINS CHECKED · NOTHING LOST"(Coin 아이콘, 선택지 없음, 잔액 무변경; dev-review P2 `qitem-20261014143715` 반영).
- 시즌 보드: 해당 사건에 "2 FILES" 종이 태그. 사건 파일(Case Files) 폴더 안에 "TWO CASE FILES · CHOOSE ONE".
- 사건 시작(BEGIN/CONTINUE) 시 한 번: "Two Case Files — This case was played on two devices. You can choose the file to keep playing." [LOOK AT THE FILES] / Play on for now.
- 비교 화면 "Two Case Files": 카드 두 장(ON THIS DEVICE / IN YOUR ACCOUNT, PLAYING NOW, FURTHER ALONG 도장, 미션 점 + "N of 6 missions", XP, "Last played today"), 각 카드 KEEP PLAYING THIS ONE, 아래 "Your coins stay the same.", DECIDE LATER. 선택 전 확인: "Keep Playing This File? — We'll keep the other file safe." [YES, KEEP PLAYING] / Not yet.
- conflict·error·delete 등 기술 단어 없음(테스트로 확인). 새 이미지 에셋 없음.

### 20.5 검증
- `test/case_files_test.dart`: 병합 규칙(동점 결정성·회차 ID 없는 동점·나중 회차 보존·기존 규칙 회귀) + 한 기기 15개(서버 기록 선택, 기기 기록 선택, 나중에, 같은 선택 반복, 화면 이후 변경, 플레이 시간만 변경, waiting→resolved/archived, 「새 모험」·다른 기기 「새 모험」 보존, 10개 한도, 기록 삭제 불가, 탐정 격리, v2 이전 기록, Coin 충돌) + 메모리·에뮬레이터 각각: 같은 회차 번호 두 선택의 전송 순서 A→B·B→A 동일 결과·재전송 무변화, 두 기기 13개(양쪽 같은 회차·두 파일, 서버 기록 선택(Coin·XP·서버 요약 불변), 기기 기록 선택, 플레이 중 유지, 나중에, 같은 선택 반복, 오프라인 선택, 전송 실패 후 재시도, 선택 직전 서버 변경, 두 기기 동시 다른 선택, 두 기기 동시 같은 선택, 로그아웃·계정 전환, 탐정 전환·게스트 무변경).
- `test/case_files_ui_test.dart`: 320×568·390×844 비교 화면(모든 버튼 화면 안, 기술 단어 없음), 선택·확인·적용, Not yet·DECIDE LATER 무변경, 탐정 화면·보드·사건 시작 1회 안내·폴더 링크.
- `integration_test/case_files_e2e_test.dart`(`npm run test:case-files-app`, 전용 iOS 시뮬레이터 `London_Mystery_DEV_iOS` + 로컬 Auth·Firestore 에뮬레이터): 실제 앱에서 다른 기기 회차 수신 → 두 파일 → 탐정·보드 표시 → 기기 파일 선택 → 서버 반영·resolved → 다시 다른 회차 → 오프라인 선택(waiting, 서버 무변경) → 재연결 후 반영 → 재시작 후 그대로, Coin 50 불변, 게스트 무변경.
- 회귀: `flutter analyze` 0, `flutter test` 1483 통과·52 건너뜀, `npm run test:sync` 126, 규칙 60, Functions 14, `test:restore-app`·`test:sync-app` 통과.

### 20.6 남은 위험
- 저장 실패(디스크 부족) 자체는 SharedPreferences 쓰기가 비동기라 동기적으로 감지할 수 없다. 대신 기록 크기(512KB)·사건당 개수(10)로 사전에 막고, 쓰기는 기존 저널로 전부/전무.
- Play again을 다른 기기가 할 때마다 이 기기의 이전 회차가 archived 기록으로 남는다(보관 우선). 많아지면 그 사건의 "다른 파일 선택"이 한도로 막힐 수 있다(플레이 중 유지 선택은 가능).
- 오프라인에서 두 기기가 서로 다른 파일을 고르면 더 진행된 쪽으로 맞춰지고 다른 쪽은 다시 묻는다(손실 없음).
- 보관된(archived) 기록을 다시 꺼내는 화면은 없다(데이터만 보존).
- Coin 충돌은 탐정 줄의 안내 문구로만 보인다(선택·해결 화면 없음, 잔액은 기기 항목 그대로). 서버 금액으로 맞추는 일은 R3 TIP 2 작업과 함께 별도.
- 실제 DEV에서는 검증하지 않았다(4.5-5, 별도 승인).
