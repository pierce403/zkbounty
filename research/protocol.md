# RISC Zero proof-of-vulnerability prototype

## Statement

An accepted claim means: for a fixed guest image and predicate version, the prover
knows a witness that the vulnerable predicate accepts and the intended predicate
rejects. The journal binds that result to a bounty, claimant commitment, and salted
evidence commitment. The current guest evaluates a tiny arithmetic model, not
Zcash. The guest image is selected by the verifier, never supplied by the claimant.

[RISC Zero receipts](https://dev.risczero.com/api/zkvm) attest to execution of a
particular image and carry public journal outputs. The application still defines
what counts as a bug. Compiling an honest witness generator into a zkVM is inadequate:
missing-constraint attacks depend on witnesses the honest generator never emits.
We need a checker for adversarial assignments and an independent intended invariant.

## Why begin with this model

It tests private input, deterministic counterexample checking, receipt verification,
context binding, and evidence commitments with very low computation cost. The
`claims` crate runs the same predicate in native tests and in the guest. This reduces
duplication; it is not an independent oracle. A real Zcash experiment needs independent
algebraic specification and circuit checking to avoid proving the same error twice.

The current model neither performs elliptic-curve multiplication nor demonstrates
Orchard inflation. The field size is instructional and has no cryptographic security.
SHA-256 only provides the evidence commitment; secrecy requires unpredictable salts.

## Security and settlement boundaries

- A proof is transferable. Binding a claimant commitment makes later payment
  authorization possible, but the prototype has no claimant signatures or redemption.
- Verifiers must compare expected context; accepting any valid receipt is insufficient.
- Do not publish the private witness. Verifier privacy does not protect inputs from
  an outsourced prover. The initial workflow is local.
- Dev receipts are rejected explicitly, independently of environment configuration.
- A vulnerability proof does not deliver a report to its buyer. Encrypted disclosure,
  key release, adjudication, and duplicate-claim policy require a separate protocol.
- Zcash shielded payments could settle an accepted claim, but RISC Zero receipts
  are not automatically executable payout conditions on Zcash. No such integration
  is assumed or implemented here.

## Milestones

1. Establish the starter's real proof and verification, plus wrong-context and
   tampered-receipt rejection; save cycle counts, proving time, memory, and proof size.
2. Reproduce the historical Orchard defect locally using pinned upstream code and
   compare against the fixed constraints. Keep exploit witnesses private in a real bounty.
3. Port a bounded checker to the guest, preserving circuit/key/version identity and
   exact public-input semantics. Benchmark before attempting full Halo 2 recursion.
4. Define bounty manifests: verifier image, source digest, acceptance invariant,
   reward, disclosure deadline, claimant authorization, and duplicate handling.
5. Design shielded ZEC funding and payout after selecting an explicit trust model
   for adjudication and disclosure. Testnet first.

## Environment notes

RISC Zero SDK/build: 3.0.6. Source reference:
`risc0/risc0@1cc70cf05033a79ebc90f07c679cb4bd1cd301b9` (v3.0.6).
See README for commands. Record completed validation separately; scaffold creation
must not be described as a completed proof or a Zcash audit.
