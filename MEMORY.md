---
summary: Durable zkbounty decisions and verification map.
---

# Project memory

- **Purpose:** prove out ZK bounty concepts using Zcash research and RISC Zero.
- **Publication:** Dean confirmed direct pushes to main on 2026-10-11.
- **Reset:** starter removed; original files retained at
  `bd0687747247f181f7a73da1fe8e32fc6afd4b41` in Git history.
- **Current proof:** private counterexample to a teaching predicate, not Orchard.
  Bounty and claimant IDs plus a salted commitment are public journal outputs.
- **Verified experiments:** [validation](research/validation.md).
- **Zcash sources and open questions:** [incident review](research/zcash.md).
- **Protocol boundaries and next milestones:** [protocol](research/protocol.md).
- **Readiness:** [FEATURES.md](FEATURES.md).
- **Website:** [live static project description](https://zkbounty.bcrt43.workers.dev/);
  Cloudflare Workers Builds watches main; proof generation remains local.
  [Cloudflare deployment and evidence](research/deployment.md).
- **Workflow lessons:** [AGENTS.md](AGENTS.md).

Keep this map project-specific. No qmd index or agent skill library is installed;
read linked notes or use `rg` instead of assuming unavailable tools exist.
