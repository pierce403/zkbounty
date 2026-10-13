#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
checkout_root=${1:?usage: bash scripts/check_historical_orchard.sh NEW_EMPTY_DIRECTORY}
if [[ -e "$checkout_root" ]]; then
  printf 'checkout directory already exists: %s\n' "$checkout_root" >&2
  exit 2
fi

mkdir -p "$checkout_root"
checkout_root=$(cd "$checkout_root" && pwd)
halo2="$checkout_root/zkbounty-halo2-vulnerable"
orchard="$checkout_root/zkbounty-orchard-vulnerable"

git clone --filter=blob:none --revision=32a87582dfb0ad9364ef3ffe71751ceab2a502ea \
  https://github.com/zcash/halo2.git "$halo2"
git clone --filter=blob:none --branch 0.13.1 --depth 1 \
  https://github.com/zcash/orchard.git "$orchard"

[[ $(git -C "$halo2" rev-parse HEAD) == 32a87582dfb0ad9364ef3ffe71751ceab2a502ea ]]
[[ $(git -C "$orchard" rev-parse HEAD) == f8915bc5c8d1c9fa3124ad28bcf73ce232ef3669 ]]

git -C "$halo2" apply "$repo_root/research/patches/halo2-historical-lab.patch"
git -C "$orchard" apply "$repo_root/research/patches/orchard-historical-lab.patch"

if [[ -n ${CARGO_BIN:-} ]]; then
  PATH=$(dirname "$CARGO_BIN"):$PATH
  export PATH
  cargo_cmd=$CARGO_BIN
else
  cargo_cmd=cargo
fi

(
  cd "$orchard"
  "$cargo_cmd" test --locked --features circuit circuit::tests::round_trip
  "$cargo_cmd" test --locked --features circuit circuit::tests::adversarial_nullifier_round_trip
  "$cargo_cmd" test --locked --features 'circuit fixed-binding' circuit::tests::round_trip
  "$cargo_cmd" test --locked --features 'circuit fixed-binding' circuit::tests::adversarial_nullifier_round_trip
)

printf 'Historical circuit comparison passed in %s\n' "$checkout_root"
