#!/usr/bin/env bash
set -euo pipefail
# Read-only historical research target. The checkout lives outside this repository.
checkout="${1:?usage: bash scripts/check_orchard.sh /path/to/research-checkout}"
revision=616a669df8c9a59c33d47064d3ce04b25d026b2e
if [[ ! -d "$checkout/.git" ]]; then
  git clone https://github.com/zcash/orchard.git "$checkout"
fi
if [[ -n "$(git -C "$checkout" status --porcelain)" ]]; then
  echo "Refusing to change a checkout with local edits" >&2
  exit 1
fi
git -C "$checkout" checkout --detach "$revision"
cd "$checkout"
cargo test --locked post_nu6_3_cross_address_restriction_is_conditional
cargo test --locked nu6_3_flags_parsing_handles_the_cross_address_bit
cargo test --locked only_orchard_post_nu6_3_requires_the_cross_address_restriction
