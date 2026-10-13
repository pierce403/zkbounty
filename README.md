# zkbounty research lab

The [live project overview](https://zkbounty.org/) is a static HTML/CSS site
deployed with Cloudflare Workers Static Assets. It describes the research;
proving and receipt verification stay local.
See [deployment](research/deployment.md) for the publishing workflow and live evidence.

Fresh Rust/RISC Zero start, replacing the original Next.js/Flask scaffold. The original
files remain in Git history at `bd0687747247f181f7a73da1fe8e32fc6afd4b41`.

## First experiment

Prove knowledge of a private counterexample to a **toy missing-binding predicate**.
The vulnerable model checks `output = scalar * loop_base (mod 97)` but never binds
`loop_base` to `base`. The intended model checks `output = scalar * base (mod 97)`.
The guest accepts only witnesses satisfying the first and violating the second.
This demonstrates the class of error; it is not an Orchard exploit or Halo 2 verifier.

The receipt journal exposes a schema version, fixed target digest, bounty ID,
claimant commitment, and salted evidence commitment. The witness stays outside the
journal. The host verifies the compiled guest image and expected bounty/claimant IDs,
and rejects development receipts. A separate, locally tested Sepolia escrow
contract exists for the historical pilot; it has not been deployed or funded.

## Run

Install Rust with rustup, then follow the [RISC Zero installation guide](https://dev.risczero.com/api/zkvm/install).
The SDK/build crates are pinned to **3.0.6**; install matching cargo-risczero and r0vm.
The custom RISC Zero Rust toolchain is also required for guest builds. This prototype
was built with `rzup install rust 1.97.0`, `rzup install cargo-risczero 3.0.6`, and
`rzup install r0vm 3.0.6`.

```sh
cargo test -p zkbounty-claims
mkdir -p artifacts
cargo run -p zkbounty-host -- prove fixtures/model.json artifacts/receipt.json
cargo run -p zkbounty-host -- verify artifacts/receipt.json \
  0101010101010101010101010101010101010101010101010101010101010101 \
  0202020202020202020202020202020202020202020202020202020202020202
python scripts/check_receipt.py
```

The default host uses r0vm; `--features prove` compiles local proving into the host.
Do not set `RISC0_DEV_MODE` for these commands. The checked-in fixture and its salt are
public teaching data. Actual submissions must use private witnesses and fresh random salts.
Do not configure a remote prover for undisclosed vulnerability inputs without an explicit
confidentiality decision: ZK protects the verifier, not a prover that receives the witness.

Run selected upstream Ironwood regressions in a separate checkout:
`bash scripts/check_orchard.sh /tmp/zkbounty-orchard-research`.

The [historical Orchard pilot](research/historical-pilot.md) includes a pinned
two-proof same-note circuit experiment and a local escrow contract. Its
historical node replay, full RISC Zero receipt, and Sepolia payment remain open.
Run its circuit comparison in a new checkout directory with
`bash scripts/check_historical_orchard.sh /tmp/zkbounty-historical-check`.
With a pinned `zcashd v6.12.3` and `zcash-cli` on `PATH`, replay the
[ordinary isolated node baseline](research/historical-node-baseline.md) with
`bash scripts/check_historical_node_baseline.sh /tmp/zkbounty-node-baseline`.
Run the escrow tests with `forge test -vv` and the local transaction flow with
`bash scripts/check_bounty_anvil.sh`. The latter starts and stops a fresh Anvil
node using its public development accounts; it never reaches Sepolia.

## Research

- [Zcash incident and circuit evaluation](research/zcash.md)
- [Proof statement and prototype roadmap](research/protocol.md)
- [Completed validation and limits](research/validation.md)
- [Static site deployment](research/deployment.md)
- [Historical Orchard bounty pilot](research/historical-pilot.md)
- [Historical node baseline](research/historical-node-baseline.md)

## Working conventions

[AGENTS.md](AGENTS.md) records project instructions, verified commands, and lessons;
[FEATURES.md](FEATURES.md) tracks acceptance criteria and readiness;
[MEMORY.md](MEMORY.md) indexes durable decisions. These adapt the guidance at
[recurse.bot](https://recurse.bot). Completed changes are pushed directly to `main`.

This is a research prototype. A successful receipt proves the pinned model ran on a
counterexample; it does not establish a vulnerability in Zcash or entitlement to a payout.
