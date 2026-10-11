# Validation: 2026-10-11

## Completed

- `cargo test -p zkbounty-claims`: 2 tests passed, including honest-witness and
  invalid-witness rejection, canonical field bounds, and commitment context binding.
- `cargo check -p zkbounty-host`: guest and host compiled successfully.
- `cargo test -p zkbounty-host`: explicit fake-receipt rejection passed.
- Generated a real receipt using the local external r0vm 3.0.6 prover for
  `fixtures/model.json`; verified it against the compiled image ID.
- `python scripts/check_receipt.py`: accepted the real receipt, rejected mismatched
  bounty and claimant IDs, and rejected a modified journal.
- Rust formatting and Git whitespace checks passed.
- In `zcash/orchard@616a669df8c9a59c33d47064d3ce04b25d026b2e`, the following
  upstream tests passed with `cargo test --locked`:
  - `post_nu6_3_cross_address_restriction_is_conditional`
  - `nu6_3_flags_parsing_handles_the_cross_address_bit`
  - `only_orchard_post_nu6_3_requires_the_cross_address_restriction`

## Proof observation

The teaching receipt serialized to **629,246 bytes of JSON**, not a compressed
on-chain proof-size measurement. Guest image ID (RISC Zero u32 representation):

```text
[4019177671, 846061282, 589024350, 1642461327,
 1533884399, 3665834630, 3531872565, 3858825604]
```

The receipt and build products are ignored. Reproduce the receipt using the
README commands. Both workspace and guest dependency lockfiles are tracked.

Build environment: host Rust 1.99.0; RISC Zero guest Rust 1.97.0-dev from the
official `r0.1.97.0` release; risc0-zkvm/risc0-build/cargo-risczero/r0vm 3.0.6.
The rzup installer hit an unknown-issuer certificate error. The official release
archives were downloaded with curl's certificate checks intact and registered
locally with rzup. No certificate verification was disabled.

## Not yet established

No historical Orchard exploit has been reproduced in this repository. No new
Zcash bug has been identified. The Lean formalization has not been independently
machine-checked. No Zcash transaction is parsed or proved by the guest. No production
benchmark, wallet integration, payout authorization, or escrow is implemented.

The upstream tests are regressions of selected expected behaviors, not an independent
proof of security. The toy predicate is an instructional model of missing binding,
not a port of the affected elliptic-curve gadget.
