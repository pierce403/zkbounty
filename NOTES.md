# Working notes

## October 11, 2026: Cloudflare project overview

Dean requested a static HTML site describing zkbounty. The public site summarizes
the existing prototype and research without adding a proving service. Static
HTML/CSS and native Cloudflare Git deployment keep this addition small.

Implementation and verification: [deployment record](research/deployment.md).
Research validation remains in [research/validation.md](research/validation.md).

The first native Cloudflare build succeeded. Public HTML/CSS/favicon hashes matched
source, deployment identity matched main, and custom 404/header checks passed.
Proving remains in the local CLI. A recovery stash preserves the site contribution
before the local checkout was fast-forwarded to its connector-published commit.

## October 12, 2026: Registered domain routing

The owner reactivated zkbounty.org and requested DNS setup. Preserved the renewed
registrar's eight DNS values in Cloudflare, proxied apex/www, and saved the zone's
assigned cash/hope nameservers at Namecheap. Tracked apex/www routes ensure native
Git deployments retain domain serving. Activation, certificate and public checks
are recorded separately in the cloudflare-migrations project; route configuration
alone does not prove public availability.

## October 12, 2026: Historical Orchard bounty pilot

Dean requested one manually reviewed bounty around the disclosed Orchard
double-spend. The acceptance gate requires both transactions confirmed by a
pre-fix node, measured excess synthetic withdrawal, and a real RISC Zero receipt
that proves that full replay. We are keeping the gate closed until all three
conditions hold. The original finding belongs to Taylor Hornby; our work is a
historical reproduction attempt.

Pinned `zcash/halo2@32a87582dfb0ad9364ef3ffe71751ceab2a502ea` and
`zcash/orchard@f8915bc5c8d1c9fa3124ad28bcf73ce232ef3669` show the circuit
flaw concretely. A lab-only witness substitution changes the unbound base rows
but not the old gates. One 1 ZEC note and Merkle path produce two distinct
nullifiers and two 4,992-byte proofs with +1 ZEC Action value balances. Both
verify with the historical key. Adding the published coordinate copy binding
rejects both malicious witnesses; an ordinary witness still passes. The
reproducible patches and script are in `research/patches/` and `scripts/`.
These are Action proofs, not complete transactions or node-confirmed spends.
The node uses Orchard 0.11.0 with older Halo 2 crates than the proof-producing
0.13.1 lab. Both versions verify the same checked-in honest proof fixture, but
that does not yet establish node acceptance of the malicious proofs.

The local escrow prototype enforces exact 0.001 ETH funding, a seven-day claim
window, reviewer approval, one claimant withdrawal, and unapproved refund. Six
Foundry tests and a fresh Anvil payout/refund transaction script pass. The
contract trusts the reviewer to inspect a real receipt and private report;
the local Anvil ETH is not Sepolia funding or payment.

The native `zcashd v6.12.3` source is pinned at
`zcash/zcash@0f49b8d30e43580587f1b9dea57128682c0057b9`. Its first build
stopped at missing Autotools. GNU m4, autoconf, automake, and libtool were
built under `/tmp/zkbounty-gnu-build-tools/prefix` without changing system
packages. After cleaning the interrupted libevent preprocessing directory,
the native dependency build resumed. Further node and full zkVM results belong
in `research/validation.md`; do not infer them from the circuit test.

The compiled v6.12.3 node then ran with NU5 active on isolated regtest. A
fresh-data-directory script confirmed two ordinary Orchard deposits and one
ordinary spend, checking block inclusion and pool/account balances. Early
replay attempts exposed wallet privacy-policy requirements, the conventional
fee's unpaid-action limit, and wallet notification timing; the final script
uses no-change coinbase spends, a 15,000-zatoshi fee, and waits for balances.
Exact evidence is in `research/historical-node-baseline.md`. The adversarial
proofs have not been embedded in authorized transactions. No excess withdrawal
or full Orchard RISC Zero receipt exists, so no Sepolia escrow was funded.
