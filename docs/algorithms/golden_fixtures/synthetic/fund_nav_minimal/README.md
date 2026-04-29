# fund_nav_minimal

Minimal Phase 1d-1 fixture for local official fund NAV persistence.

- File format: local app persistence file `fund_nav.v1.json`, not a public import contract.
- NAV values are encoded as fixed 4-decimal strings to preserve the official daily NAV precision.
- Dates are `yyyy-MM-dd` keys in the `Asia/Shanghai` natural day.
- Record order mirrors `FundNAVService` write order: `code` ascending, then `date` ascending.
- These rows are account-agnostic; real holdings and shadow holdings share the same fund NAV series.
- `metadata.json` documents fixture invariants; it is not a service round-trip output file.
