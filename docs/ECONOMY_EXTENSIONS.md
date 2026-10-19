## Development preview (feature/coin-economy-rewarded-ads)

- Starting coins: 20. Mission: 5. Final: 10. XP is unchanged.
- Tip 1 remains free; tip 2 costs 20. Insufficient coins do not unlock it.
- In **Flutter debug mode only**, WATCH AD +20 simulates a fully completed rewarded ad (600ms demo wait). It adds 20 coins and shows `You earned 20 coins!`; the hint can then be purchased separately.
- In profile/release builds, the ad gateway is disabled and shows Coming soon. **No AdMob SDK or IDs are integrated.** This preview must not be shipped as a real ad implementation.
- `RewardedAdGateway` is the integration seam. Replace the disabled implementation only after checking child-directed ad policies, SDK initialization and rewarded callback; use server-side verification when available. No payout on failed/cancelled ads.
- Existing wallet ledger entries and balances are preserved; changing constants does not retroactively recalculate them.

---

# Coins, Tips and Future Rewards — Extension Notes

Status: design notes only. **No ad SDK, payment SDK, ad button or subscription UI exists in the app.**
Nothing here may ship before the policy checks in §4 are done against official, current sources.

## 1. What exists now (XP & Economy V4)

| Concept | Where | Notes |
|---|---|---|
| XP (growth record) | `lib/features/game/scoring.dart` | Computed per case from solved missions. Rule 4: mission 30, final 60. Earlier rules (1–3) stay recorded per mission (`GameProgress.xpRules`), so old XP never changes. XP is never spent. |
| Coins (spendable) | `lib/data/models/wallet.dart`, `lib/features/game/wallet_controller.dart` | One wallet per device (`lm.wallet.v1`). A ledger of `CoinEntry` rows; balance = sum of rows. |
| Prices & rewards | `lib/core/constants/app_constants.dart` | `missionCoins 30`, `finalCoins 60`, `startCoins 20`, `tipPrices [0, 20]`. |
| GET A TIP dialog | `lib/features/mission/widgets/tip_shop.dart` | Small confirm: total coins, the next tip's price (or FREE), CANCEL / REVEAL. |

Rules that protect children:
- Tip 1 is always free. Tip 2 costs 20 coins; **if the coins are short it is given free** ("Your partner helps you for free this time"). No child is ever blocked from a case by coins.
- Each mission pays coins **once ever** (key `mission:<id>`); replaying a case pays nothing more.
- Each tip is charged **once ever** (key `tip:<missionId>:<n>`); a tip already owned is read again free, in any run.
- Balance never goes below zero (a short tip is a 0-coin entry).
- Saves from before coins: on first load the wallet is made once — start coins, coins for every solved mission (`CoinSource.backfill`), and every tip already opened recorded as owned (free).
- "Reset everything" makes a fresh wallet (start coins only).

## 2. Ads (future — not implemented)

Hook point: the same `Wallet`. A rewarded ad would add a new `CoinSource` (e.g. `ad`) and write one entry:

```
CoinEntry(key: 'ad:<rewardId>', amount: <coins>, source: CoinSource.ad)
```

- `rewardId` = the unique id of the completed reward event (from the ad network's completion callback, or a server-issued id). The key makes a duplicate callback a no-op.
- Write the entry **only on verified completion**; a cancelled, failed or offline ad writes nothing.
- Server-side verification (when added) would issue the `rewardId`; the client keeps the same idempotent write.
- Child-safety design limits (to be confirmed in §4): never forced, never needed to solve a case, no prompts to watch repeatedly, and possibly no ads at all for this audience.

## 3. Subscriptions (future — not implemented)

Keep **Entitlement separate from Wallet**:
- `Entitlement` = what the account may access (e.g. ad-free, extra seasons), with `active`, `expiresAt`, source store, restore status. It is never stored as coins.
- Monthly coin benefit = a Wallet entry keyed by period: `sub:<entitlementId>:<yyyy-mm>` (one grant per month, even if the app opens many times or offline).
- Expiry removes access, never coins already granted. "Restore purchases" re-reads entitlements; it does not re-grant past months (their keys exist).
- Purchases go through a Parent Gate (`lib/features/game_master/parent_gate.dart` exists today for adult-only screens) and Google Play Billing / Apple In-App Purchase.
- Forbidden by design: putting any clue, tip or English help needed to solve a case behind a subscription.

## 4. Before any ad or subscription ships

Verify with official, current sources (not this note): Google Play Families / Designed for Families policy and ad SDK requirements, Apple App Store Kids Category and in-app purchase rules, COPPA (if distributed in the US), and Korean law on children's personal information and in-app payments by minors. Record the sources and dates with the decision.

Principles that stay regardless: no forced ads; every case solvable without ads or a subscription; no pressure to pay; real money and coins clearly separated; a child weaker in English is never disadvantaged by tip prices.
