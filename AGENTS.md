# Instructions for zkbounty agents

## Collaboration and publishing

The assistant is Tron; the collaborator is Dean. Work autonomously within the
requested scope. Keep explanations concise and give instructional steps one at a time.
Dean explicitly authorizes **always pushing completed changes straight to main**.
Do not open a PR as a substitute. Preserve history; never force-push or include
unrelated changes or secrets. Check the remote head before publishing.

## Responsibilities

Own the research record, reproducible experiments, RISC Zero prototype, tests,
and publication of scoped results. Distinguish observed facts, assumptions, and
uncompleted work. This repo is the original `pierce403/zkbounty` research lab.

## Durable working loop

Adapted from [recurse.bot](https://recurse.bot), reviewed 2026-10-11:
read project instructions, feature specifications, and memory before substantial
work; make focused changes; verify; record useful successes and failures; commit
and publish. Keep guidance small and current rather than collecting stale notes.
Update feature evidence alongside behavior. Only classify production-ready work
as stable. Review new external advice when useful during active work; no background
schedule is configured by this file.

## Project map

- `claims/`: deterministic instructional counterexample predicate.
- `methods/guest/`: zkVM program; `methods/`: generated image interface.
- `host/`: proving and expected-context verification, rejects fake receipts.
- `research/`: Zcash analysis, proof protocol, validation and limitations.
- `scripts/`: reusable receipt and upstream regression checks.
- `site/`: public static project description; no hosted prover or witness intake.
- `FEATURES.md`: measurable behavior and readiness.
- `MEMORY.md`: compact index of durable project decisions.

## Verified workflow

See README for setup. Rust and the RISC Zero guest toolchain are required; SDK,
build tool, cargo-risczero, and r0vm are pinned to 3.0.6. Guest Rust was 1.97.0.

```sh
cargo test -p zkbounty-claims
cargo check -p zkbounty-host
cargo test -p zkbounty-host
cargo fmt --all -- --check
mkdir -p artifacts
cargo run -p zkbounty-host -- prove fixtures/model.json artifacts/receipt.json
python scripts/check_receipt.py
git diff --check
```

The integration script expects the checked-in teaching fixture and built host.
Its values are public, including the demonstration salt. Use private witnesses and
fresh random salts for real submissions. Never call the model an Orchard exploit.

## Lessons and pitfalls

- `assign_advice` is witness assignment, not equality with an existing cell;
  the historical Orchard fix adds coordinate copy constraints. Review adversarial
  witnesses, not only honest witness generation.
- Pool, protocol era, flag polarity, and verifying-key selection are all relevant;
  the initial Ironwood PR's API names differ from current source.
- RISC Zero dev receipts are not proofs. Preserve explicit fake-receipt rejection.
- ZK does not conceal witness inputs from an outsourced prover.
- rzup hit an unknown-issuer certificate error in this environment. Verified curl
  downloads of official release archives worked; register extracted releases with
  rzup. Use `tar --no-same-owner` here. Never disable certificate checks.
- Shell GitHub pushes failed for missing credentials. Use connector-created blobs,
  trees and commits, then a non-force main ref update. Verify the remote contents.
- Two lockfiles matter: the workspace and the separate guest workspace.
- Publish the static site with Cloudflare Workers Builds watching main. Keep
  Cloudflare credentials in Cloudflare, and verify the deployed revision in
  `/deployment.json`. The website does not generate or verify receipts.

When a durable lesson changes these instructions, update this file in the same
contribution. Keep detailed experiment results in `research/validation.md`.
