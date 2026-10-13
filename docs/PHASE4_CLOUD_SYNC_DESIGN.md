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
