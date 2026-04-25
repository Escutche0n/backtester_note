# 2026-04-25 · be · legacy-ios-reuse-assessment

**Agent**: GPT
**Role**: Review
**Scope**: Read-only assessment of what the legacy FundMVP iOS project can teach, reuse, or should avoid migrating.

## What changed
- 文件：`docs/worklog/2026-04-25_be_legacy-ios-reuse-assessment.md`
- 原因：Elvis asked whether the old project at `/Users/elvischen/Developer/investment app/` has reusable lessons before Opus starts the new iOS skeleton.
- 时间：2026-04-25, written by GPT after a read-only scan.

## Legacy project scanned
- `/Users/elvischen/Developer/investment app/FundMVP/Views/Holdings/HoldingsNAVCalculator.swift`
- `/Users/elvischen/Developer/investment app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift`
- `/Users/elvischen/Developer/investment app/FundMVP/Views/Backtest/BacktestEngine.swift`
- `/Users/elvischen/Developer/investment app/FundMVP/Views/Holdings/HoldingsDiagnostics.swift`
- `/Users/elvischen/Developer/investment app/FundMVP/App/HoldingsWidgetRefreshController.swift`
- `/Users/elvischen/Developer/investment app/FundMVP/WidgetsShared/HoldingsWidgetStore.swift`
- `/Users/elvischen/Developer/investment app/FundMVP/Networking/APIClient.swift`
- `/Users/elvischen/Developer/investment app/FundMVP/Networking/ChinaTradingCalendar.swift`
- `/Users/elvischen/Developer/investment app/FundMVP/Persistence/PersistenceController.swift`
- Related models, widget views, and old backend folders were identified for context.

## Findings
- The old project is valuable as a behavior reference, not as a source tree to copy.
- `HoldingsNAVCalculator.swift` should be used for NAV/TWRR/cash-flow ledger golden behavior and fixtures.
- `BacktestEngine.swift` should be used for backtest execution, scheduled investment, rebalance, XIRR, Sharpe, Calmar, and drawdown parity tests.
- `HoldingsHomeFeature.swift` confirms that radar `overallScore` is the simple average of available dimensions. The `0.22/0.22/0.18/0.14/0.14/0.10` weights belong inside the strategy-execution dimension, not to the six-dimension radar total.
- `HoldingsWidgetStore.swift` and `HoldingsWidgetRefreshController.swift` show a clean Widget architecture: app writes an App Group JSON snapshot, widgets only read that snapshot. The new app should reuse this data-flow pattern, with new identifiers and new design styling.
- `ChinaTradingCalendar.swift` is useful for A-share trading-day behavior, official SSE holiday fallback, timezone handling, and cache layering.
- `PersistenceController.swift` has useful domain responsibilities but is too large to migrate directly. New iOS should keep a persistence facade but split stores by domain.
- Old SwiftUI feature files should be treated as workflow references only. The new iOS UI should follow `docs/design/`, not port old screens wholesale.

## Non-migration decisions reinforced
- Do not migrate real old-app private data structures into the new app.
- New app should define a clean import schema first, then the old app can export into that schema if needed.
- Do not copy the old embedded backend from the legacy iOS repo. Backend source of truth is `/Users/elvischen/Developer/backtester_backend` and GitHub `Escutche0n/backtester-backend`.
- Do not carry over derived data, module caches, old generated logs, old draft PRDs, or temporary local artifacts.

## Contract change
- None.

## Algorithm drift
- None introduced by this worklog.
- Existing confirmed algorithm decision: radar total remains six-dimension simple average, each dimension effectively `1/6` when all six are present.

## Questions for Elvis
- None. No new decision is blocked.

## Next
- [ ] Opus can use this log as part of the pre-iOS-skeleton review.
- [ ] GPT should use the old app only for backend/API/algorithm parity work, not for iOS UI ownership.
- [ ] If this assessment needs to become long-lived architecture material, promote it later into a dedicated docs note in a separate committed unit.
