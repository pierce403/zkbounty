# zkbounty features

Uses the [features.md format](https://features.md/). Proof and settlement features
remain research prototypes; the static project overview is published.

## Features

### Public project overview

- **Stability**: stable
- **Description**: Static HTML/CSS page describing the lab, teaching example,
  observed results, research notes, and open milestones.
- **Properties**:
  - Makes the teaching model and unfinished settlement explicit.
  - Links to the original source and research record.
  - Sends no witness inputs; no proving or verification service is hosted.
  - Native Git deployments retain apex and www routes for zkbounty.org.
- **Dependencies**: Node.js 22+, Wrangler 4.149.0, Cloudflare Workers Static Assets.
- **Test Criteria**:
  - [x] Static build and Wrangler dry run pass.
  - [x] Browser renders the overview and research links.
  - [x] Cloudflare native Git build deploys the published main revision.
  - [x] Public HTTPS, asset hashes, and missing-page response verified.
  - [x] Desktop and mobile live browser checks pass.
- **Evidence**: [deployment](research/deployment.md).

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
  - [x] Native historical Orchard malicious-witness proof reproduction; the
    RISC Zero guest still proves only the teaching predicate.
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
  - [x] Two nonzero same-note adversarial Action proofs verify under the
    historical circuit; the corrected coordinate binding rejects their witnesses.
  - [ ] A pinned historical node accepts transactions containing both spends.
  - [ ] Independently machine-check pinned Lean formalization.
- **Evidence**: [research](research/zcash.md), upstream checker, validation record.

### Historical Orchard bounty pilot

- **Stability**: in-progress
- **Description**: Reproduce the disclosed Orchard double-spend with synthetic
  value, prove the full replay in RISC Zero, and manually settle a Sepolia reward.
- **Properties**:
  - Pinned local experiments distinguish circuit proofs from accepted transactions.
  - The single-bounty contract holds 0.001 test ETH for seven days and lets one
    reviewer approve one claimant withdrawal.
  - No contract approval or public success claim is made before node replay,
    full receipt verification, and private report review.
- **Dependencies**: Historical regtest node, real exploit transactions, full
  RISC Zero guest, independent reviewer, and Sepolia test wallets.
- **Test Criteria**:
  - [x] Two same-note, distinct-nullifier historical Action proofs verify.
  - [x] Corrected binding rejects both malicious witnesses; honest proof passes.
  - [x] Pinned `zcashd v6.12.3` confirms two synthetic Orchard deposits and an
    ordinary Orchard spend with expected pool balances.
  - [ ] Released corrected verifier rejects serialized adversarial proofs.
  - [x] Escrow contract's six local Foundry tests pass.
  - [x] Local Anvil payout and refund transactions pass, including unauthorized
    approval, duplicate withdrawal, and late claim rejection.
  - [ ] Pre-fix node confirms both transactions and excess synthetic withdrawal.
  - [ ] Full RISC Zero receipt verifies the transactions and pool accounting.
  - [ ] A funded Sepolia claim pays the bound claimant.
- **Evidence**: [historical pilot](research/historical-pilot.md),
  [node baseline](research/historical-node-baseline.md).

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
