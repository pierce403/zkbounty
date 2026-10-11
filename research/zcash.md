# Zcash: Orchard bug, NU6.2, and Ironwood

Reviewed 2026-10-11. This is an initial source/implementation review, not an independent
cryptographic audit. No new vulnerability is asserted and no mainnet exploit was attempted.

## Missing binding

The authoritative [GHSA-ww9q-8r59-xv46 / CVE-2026-54496](https://github.com/ZcashFoundation/zebra/security/advisories/GHSA-ww9q-8r59-xv46)
describes an unanchored base in the incomplete scalar-multiplication stage. Witness
assignment used `assign_advice`; consistency across loop rows did not bind those rows
to the intended base. The patch copies both base coordinates into the first incomplete
row. Existing equality constraints then propagate the binding.

This undermined the diversified-address check and could permit alternate nullifiers
for repeated spends, or forged authorization with known note plaintext. Overall supply
outflows remained bounded by the turnstile; this is different from unlimited spendable
inflation outside the pool. The advisory reports no evidence of prior exploitation,
not proof of its absence. Patched versions include halo2_gadgets 0.5.0 and orchard 0.14.0.

Code reference: [halo2 PR #888](https://github.com/zcash/halo2/pull/888), specifically
`halo2_gadgets/src/ecc/chip/mul/incomplete.rs`. The regression records synthesized copy
constraints and checks the added coordinate anchors. This directly tests the omission
an honest witness generator would otherwise conceal.

## Emergency patch versus new pool

[ZIP 257](https://zips.z.cash/zip-0257) documents two distinct stages: disabling Orchard
Actions at mainnet height 3,363,426, then re-enabling them with the corrected key at
NU6.2 height 3,364,600. NU6.2 also requires canonical proof lengths of
`2720 + 2272 * nActionsOrchard` bytes. Historical proofs need the historical key;
current proofs need the fixed one. The patch repairs future verification but cannot
retroactively establish every hidden historical balance.

[ZIP 258](https://zips.z.cash/zip-0258) specifies NU6.3 and Ironwood, including
mainnet activation height 3,428,143, a separate pool balance/tree, no inflows into
Orchard, and disabled cross-address transfers within Orchard. Self-transfer/change
can still support private migration. Ironwood uses version 6 transactions and the
new note plaintext format. The retrieved ZIP still says Draft, so that label alone
must not be interpreted as deployment status. The [July 28 completion announcement](https://tachyon.z.cash/blog/ironwood-verification-complete/)
reports activation and completion of the formalization.

## Implementation examined

`zcash/orchard` at **616a669df8c9a59c33d47064d3ce04b25d026b2e**:

- `src/circuit.rs::synthesize_cross_address_checks` copies the public restriction
  input and four old/new expanded-receiver coordinates into constrained rows.
- `Instance::from_parts` converts the enabled wire flag to a disabled circuit input.
- Proving/verification reject restricted instances under unsupported circuit keys.
- `src/bundle.rs::BundleVersion` selects pool/protocol semantics. The crate cannot
  infer activation heights itself; callers must supply the correct era.
- Existing `post_nu6_3_cross_address_restriction_is_conditional` tests cover
  unrestricted transfers, restricted rejection, and valid self-transfers.

The three selected upstream regressions were subsequently run successfully;
see [validation](validation.md). These checks do not exhaustively audit the circuit.
The [NU6.3 implementation PR #504](https://github.com/zcash/orchard/pull/504)
merged into a feature branch; current APIs have since changed from
`BundlePoolRestrictions` to `BundleVersion`. Pin source SHAs instead of copying
an old PR's API examples. Proof validity alone does not enforce transaction-level
pool balances, activation, or coinbase rules.

## Formal verification boundary

The [Tachyon completion report](https://tachyon.z.cash/blog/ironwood-verification-complete/)
and [published scope](https://forum.zcashcommunity.com/t/retroactive-grant-application-ironwood-zk-snark-formal-verification-project-tachyon/57007)
describe a machine-checked algebraic verifier/knowledge-soundness formalization
linked to circuit-soundness results, subject to cryptographic assumptions. This
is strong assurance for the modeled construction, not blanket verification of
Rust execution, parsing, ledger accounting, wallets, or deployment configuration.
The announcement's pinned formalization is
`zcash/ironwood@591454c22e25cd108a1b3e0726b8daabf006fc51`.

## Next evaluation targets

1. Run and extend the upstream missing-base regression with malicious witnesses;
   record historical/fixed verifying-key fingerprints and precise source revisions.
2. Exercise NU6.3 flag polarity and all pool/era combinations, including unsupported
   keys, batch versus single verification, same receiver, and dummy Actions.
3. Inspect the formalization's verifier fingerprint and assumptions; machine-check
   the pinned Lean build before claiming independent verification.
4. Establish a bounded real Halo 2 counterexample checker and measure native cost
   before compiling it into a zkVM guest. No Zcash performance figures are measured yet.
