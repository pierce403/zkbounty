# Historical Orchard bounty pilot

Status: **circuit exploit reproduced; end-to-end payout gate closed**. This
experiment concerns the disclosed and remediated
[GHSA-ww9q-8r59-xv46 / CVE-2026-54496](https://github.com/ZcashFoundation/zebra/security/advisories/GHSA-ww9q-8r59-xv46).
Taylor Hornby discovered and reported the vulnerability. This lab does not
claim a new finding or prior mainnet exploitation.

## Pinned sources and reproduction

- Vulnerable Halo 2: `zcash/halo2@32a87582dfb0ad9364ef3ffe71751ceab2a502ea`.
- Historical proof producer: `zcash/orchard@f8915bc5c8d1c9fa3124ad28bcf73ce232ef3669`
  (0.13.1). The [v6.12.3 node](https://github.com/zcash/zcash/releases/tag/v6.12.3)
  is `zcash/zcash@0f49b8d30e43580587f1b9dea57128682c0057b9` and uses
  Orchard 0.11.0 (`zcash/orchard@0a718935644e93015c6ce548406d45db653b1d69`).
  The two Orchard versions' checked-in circuit descriptions and serialized
  honest proof fixtures are byte-identical; both versions verify that fixture.
  They use different Halo 2 dependency releases, so this comparison does not
  prove node acceptance of the malicious proofs.
- The lab patch to Halo 2 adds a witness substitution hook; in the historical
  build it leaves the gate definitions and missing copy constraint unchanged.
  A separate feature adds the two coordinate copies from the published fix so
  the same malicious witness can be checked against the repaired constraint.
  These patch features are local research instruments, not production proving APIs.
  See the [Halo 2 patch](patches/halo2-historical-lab.patch),
  [Orchard patch](patches/orchard-historical-lab.patch), and
  [reproduction script](../scripts/check_historical_orchard.sh).

Run the isolated comparison with Git 2.53+ and Rust/Cargo (tested with Rust
1.97.0). The script creates fresh sibling source checkouts and pins their SHAs:

```sh
bash scripts/check_historical_orchard.sh /tmp/zkbounty-historical-check
```

Set `CARGO_BIN` to a specific Cargo executable if the default `cargo` is a
system shim. The checkout directory must not already exist.

The test creates one synthetic 1 ZEC note and one Merkle path. It uses two
different incorrect nullifier keys, producing two distinct nullifiers and two
real 4,992-byte Action proofs against the old verifier. Both Action instances
have +1 ZEC value balance. The same witnesses fail the corrected binding, while
an ordinary proof succeeds there. This establishes a circuit-level double-spend
construction. The proofs have not yet been packaged into complete Zcash
transactions or accepted by `zcashd`; no pool withdrawal has been observed.

The pinned `zcashd v6.12.3` binary does run on isolated NU5 regtest. It
confirmed two ordinary synthetic Orchard deposits and an ordinary Orchard
spend; the [fresh-data-directory node replay](historical-node-baseline.md)
records exact transactions, blocks, balances, and commands. Those transactions
do not contain the adversarial same-note proofs.
The corrected-binding `MockProver` failure has not yet been supplemented by
a serialized-proof check against the released fixed verifier.

The [official advisory](https://github.com/ZcashFoundation/zebra/security/advisories/GHSA-ww9q-8r59-xv46)
explains why distinct nullifiers for one note could inflate the historical
Orchard pool. The turnstile bounds total value leaving that pool. A successful
node replay must seed the synthetic pool with another depositor's value, include
both attacker withdrawals after fees, confirm both transactions in blocks, and
show attacker withdrawals greater than the attacker's own deposit while the
pool remains nonnegative. Neither circuit verification nor two positive value
balances alone establishes that outcome.

## Proof and reward gate

The current RISC Zero guest still verifies the teaching predicate. The target
guest must verify complete serialized historical transactions and proofs,
authorization, the private same-note opening, distinct nullifiers, and pool
accounting. Its public journal must bind the pinned target and key, bounty,
claimant Sepolia address, transcript digest, value change, and salted report
commitment. Native node replay and RISC Zero verification must agree.

`contracts/HistoricalOrchardBounty.sol` is a local escrow that relies on the
reviewer's proof checks:
its reviewer approves a claim only after checking the real receipt, node replay,
and private report. A claimant submits from the address bound into the receipt;
the contract records the journal digest and report commitment, then lets the
approved claimant withdraw 0.001 test ETH once. Funding starts a seven-day
review period; if no claim is approved, the funder can refund after it ends.
Six Solidity tests and `bash scripts/check_bounty_anvil.sh` pass locally. The
Anvil script uses public development accounts to test a funded payout and
refund, unauthorized approval, duplicate withdrawal, and expiry. No Sepolia
contract has been deployed or funded.

The reviewer must not approve or advertise a completed bounty until the native
node and full RISC Zero gates pass. If either cannot be reproduced, keep the
site's pilot status incomplete and record the precise limitation. The live
Zcash network uses corrected rules; this lab does not target it.
