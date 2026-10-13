# Historical Orchard node baseline

Status: **ordinary regtest funding and spend confirmed; exploit replay absent**.
This uses only synthetic ZEC on an isolated `zcashd v6.12.3` regtest chain.
It does not confirm a double-spend, excess withdrawal, or the Orchard
Action proofs from the [circuit lab](historical-pilot.md).

## Source and replay

The node source is `zcash/zcash@0f49b8d30e43580587f1b9dea57128682c0057b9`
(`v6.12.3`). The local build produced `zcashd` and `zcash-cli` reporting
`v6.12.3`; the local `zcashd` binary SHA-256 was
`fbb6c89230918f6287d55c79c45d1f3023448ee5d4260c4e6f324ff7a68412da`.
Binary hashes can differ across build environments; the source revision is the
pin. Build from that revision using its `./zcutil/build.sh` and dependencies.
This executor needed Autotools installed under `/tmp` and a serial dependency
build to avoid a Berkeley DB install race; `make -C src -j8 zcashd zcash-cli`
completed the binaries.

On a host with the upstream build prerequisites installed, the source pin and
build commands are:

```sh
git clone https://github.com/zcash/zcash.git /tmp/zkbounty-zcashd-vulnerable
git -C /tmp/zkbounty-zcashd-vulnerable checkout 0f49b8d30e43580587f1b9dea57128682c0057b9
cd /tmp/zkbounty-zcashd-vulnerable
./zcutil/build.sh -j1
```

From the zkbounty repository, replay the ordinary baseline in a fresh path:

```sh
ZCASHD_BIN=/tmp/zkbounty-zcashd-vulnerable/src/zcashd \
ZCASH_CLI_BIN=/tmp/zkbounty-zcashd-vulnerable/src/zcash-cli \
  bash scripts/check_historical_node_baseline.sh /tmp/zkbounty-node-baseline
```

Alternatively put those binaries on `PATH` and omit the environment variables.
The script refuses an existing data directory, binds RPC to loopback, disables
peer connections, uses local cookie authentication, activates NU5 at block 1,
and stops the node afterward. It creates a local wallet containing private
regtest keys under the chosen data directory; keep that directory out of Git.
The replay checks balances and block inclusion. Wallet randomness means its
transaction IDs and block hashes can differ from this observed run.

## Observed fresh replay

The script mined blocks 1–102, including two distinct mature 6.25 ZEC
coinbase outputs. Two separate Orchard accounts received 6.24985 ZEC each,
paying 0.00015 ZEC per deposit. Both transactions confirmed in block 103,
`0caa787fe11a1aa500a4f7935c94ed707510a21f0dba225e9391578ba954f731`:

| Transaction | Role | Orchard received |
| --- | --- | ---: |
| `337b7464278f8366b90c2536b79969ddd95fa0ad6d14be5458ad8775f1fcf004` | Account 0 deposit | 624,985,000 zatoshis |
| `06852af801607d1db4a9ddc01c35e815112836ffd5cd8d8dd3fd3060371f1ef0` | Account 1 deposit | 624,985,000 zatoshis |

The Orchard pool then held **1,249,970,000 zatoshis**. Account 0 sent an
ordinary 1 ZEC Orchard transfer to account 1 with a 15,000-zatoshi fee.
Transaction `98bfc7d06981341042e4c007709f80a1e4293a57113d33f9435177b9f57fde12`
confirmed in block 104,
`04c3a19513fe48af8e8c7a625be1dcfe2feb0425c9e6838b1246fb64babd6d8c`.
Account 0 then held 524,970,000 zatoshis; account 1 held 724,985,000.
The Orchard pool held **1,249,955,000 zatoshis**, a decrease equal to that
ordinary transaction's fee. Both accounts belong to the same disposable
regtest wallet; they model separate participants but are not independent
custody evidence.

The missing step is a transaction builder that packages the two adversarial
same-note proofs with distinct nullifiers, authorization, and valid consensus
serialization. Until the node confirms those transactions and the resulting
excess withdrawal, this baseline cannot satisfy the bounty gate.
