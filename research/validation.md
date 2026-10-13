# Validation record

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

## Historical Orchard circuit lab: 2026-10-12

The pinned pre-fix `zcash/halo2@32a87582dfb0ad9364ef3ffe71751ceab2a502ea`
and `zcash/orchard@f8915bc5c8d1c9fa3124ad28bcf73ce232ef3669`
(Orchard 0.13.1) were checked out. A lab-only feature substitutes the witness
assigned in the two incomplete multiplication stages without changing the
historical constraint gates or adding a copy constraint. The upstream pinned
historical circuit description still matches in the honest `round_trip` test.

The `adversarial_nullifier_round_trip` test used one synthetic 1 ZEC note and
Merkle path twice. With two independently chosen incorrect nullifier keys, it
created distinct nullifiers and two real Halo 2 Action proofs. Both verified
under the historical key; each Action had a +1 ZEC Orchard value balance and a
4,992-byte proof. The corrected-binding test copied the original base into the
first incomplete row, following the [upstream repair](https://github.com/zcash/halo2/pull/888),
and rejected both adversarial witnesses. An honest Action proof passed under
that corrected binding. These are local circuit-level observations; the
corrected test does not claim a byte-for-byte comparison with the released
post-NU6.2 verifying key.

The deterministic test printed these serialized nullifiers, in test order:

```text
c0fdcc33c177277e261eb8f1c1b5e9e17f6fb56529e323dcc88c8ebf821da323
93e33c4876d8874ac5182e6517366f1d4358678016e4d7f704176be96e200227
```

The entire `scripts/check_historical_orchard.sh` workflow passed from fresh
pinned checkouts: ordinary historical proof, two malicious historical proofs,
ordinary corrected proof, and corrected rejection of both malicious witnesses.

`zcashd v6.12.3` resolves Orchard 0.11.0; its checked-in
`circuit_description` is byte-identical to Orchard 0.13.1's (SHA-256
`946e86ffd3798cd96b6d1abd0e8f8b9f08c26c4a8be61602d38c20fcf8e696a1`).
The 0.11.0 and 0.13.1 checkouts also contain the same 5,154-byte
`circuit_proof_test_case.bin` (SHA-256
`40347437e6bf604f51af059ee7d560ee893507c2ba35b61e3dd0db5ec1358662`),
and each version's `serialized_proof_test_case` verified that fixture. The node
uses `halo2_gadgets` 0.3.1 and `halo2_proofs` 0.3.0, whereas the 0.13.1 lab uses
0.4.0 and 0.3.2. Shared honest-fixture acceptance narrows that version gap but
does not establish acceptance of either adversarial proof by the node.
Reproduction patches and commands are in the
[historical pilot record](historical-pilot.md).

The pinned `zcashd v6.12.3` binary was compiled from source and ran on isolated
NU5 regtest. A fresh replay confirmed two ordinary synthetic Orchard deposits
in block 103 and an ordinary Orchard spend in block 104. The pool rose to
1,249,970,000 zatoshis after deposits, then fell by the ordinary spend's
15,000-zatoshi fee to 1,249,955,000. The exact transactions, blocks, account
balances, build pin, and replay command are in the
[node baseline record](historical-node-baseline.md). The adversarial Action
proofs were not included in these transactions.

The native ETH escrow contract compiled with Solidity 0.8.24. `forge test -vv`
passed six local tests covering funding, reviewer authority, duplicate claims,
one-time withdrawal, refund, and expiry. The reproducible
`bash scripts/check_bounty_anvil.sh` run deployed two ephemeral contracts on
Anvil, funded each with 0.001 local ETH, observed one claimant withdrawal and
one funder refund, and rejected unauthorized approval, duplicate withdrawal,
and a late claim. The claimant's balance gain plus the withdrawal gas fee was
exactly 0.001 ETH. This is local-chain evidence only; the contract has not been
deployed or funded on Sepolia.

## Not yet established

No transaction containing the adversarial historical Orchard proofs, nor any
excess-withdrawal replay, has been accepted by a node. The RISC Zero guest has
not parsed or proved an Orchard transaction. No new Zcash bug has been
identified. The Lean formalization has
not been independently machine-checked. No Sepolia transaction, funded payout,
wallet integration, or private report transfer has been completed. The contract
only exists locally and trusts a human reviewer.

The October 12 baseline rerun passed `cargo test -p zkbounty-claims` (two tests)
and `cargo fmt --all -- --check`. `cargo check -p zkbounty-host` could not finish
on this executor because the RISC Zero guest Rust toolchain was absent:
`Risc Zero Rust toolchain not found`. That environment failure does not undo the
October 11 host/receipt evidence, but it prevents a fresh host verification here.

The upstream tests are regressions of selected expected behaviors, not an independent
proof of security. The toy predicate is an instructional model of missing binding,
not a port of the affected elliptic-curve gadget.
