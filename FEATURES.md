# zkbounty features

Uses the [features.md format](https://features.md/). No feature is production-ready.

## Features

### Private counterexample proof

- **Stability**: in-progress
- **Description**: RISC Zero proves a counterexample to the fixed teaching predicate.
- **Properties**:
  - Vulnerable model accepts the witness; intended model rejects it.
  - Journal commits to target, bounty, claimant, and salted evidence.
  - Private arithmetic inputs and salt are absent from the journal.
- **Dependencies**: RISC Zero 3.0.6, guest toolchain, both Cargo lockfiles.
- **Test Criteria**:
  - [x] Valid counterexample accepted; honest and malformed cases rejected.
  - [x] Real receipt generated and verified against the compiled image.
  - [ ] Actual historical Orchard malicious-witness reproduction.
  - [ ] Independent acceptance-invariant review.
- **Evidence**: [validation](research/validation.md), claims tests, receipt checker.

### Claim verification

- **Stability**: in-progress
- **Description**: Verify the pinned guest and expected claim context.
- **Properties**:
  - Reject fake receipts even when development settings would permit them.
  - Require matching bounty, claimant, and schema.
- **Dependencies**: Private counterexample proof.
- **Test Criteria**:
  - [x] Fake receipt rejected.
  - [x] Wrong bounty, wrong claimant, and altered journal rejected.
  - [ ] Claimant authorization and redemption replay prevention.
- **Evidence**: host test and `scripts/check_receipt.py`.

### Zcash circuit evaluation

- **Stability**: in-progress
- **Description**: Pinned source review and selected upstream regressions.
- **Properties**:
  - Distinguish NU6.2 remediation from Ironwood and formal verification scope.
  - Identify source revisions and reproducible tests.
- **Dependencies**: Pinned upstream Orchard checkout and Rust.
- **Test Criteria**:
  - [x] Missing-binding root cause and patch documented from primary sources.
  - [x] Three Ironwood flag/restriction regressions passed.
  - [ ] Historical/fixed adversarial circuit comparison.
  - [ ] Independently machine-check pinned Lean formalization.
- **Evidence**: [research](research/zcash.md), upstream checker, validation record.

### Shielded bounty settlement

- **Stability**: planned
- **Description**: Shielded ZEC funding, adjudication, disclosure, and payout.
- **Properties**:
  - Acceptance manifests identify the exact verifier image and target revision.
  - Settlement defines claimant authorization and duplicate-claim handling.
- **Dependencies**: Claim verification, explicit settlement/disclosure trust model.
- **Test Criteria**:
  - [ ] Agree on adjudication and report-delivery protocol.
  - [ ] Exercise funding and authorized payouts on testnet.
  - [ ] Reject replayed or unauthorized claims.
