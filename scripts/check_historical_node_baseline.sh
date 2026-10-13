#!/usr/bin/env bash
set -euo pipefail

zcashd_bin=${ZCASHD_BIN:-zcashd}
zcash_cli_bin=${ZCASH_CLI_BIN:-zcash-cli}
port=${ZCASH_RPC_PORT:-18246}
data_dir=${1:?usage: bash scripts/check_historical_node_baseline.sh NEW_EMPTY_DIRECTORY}
if [[ -e "$data_dir" ]]; then
  printf 'data directory already exists: %s\n' "$data_dir" >&2
  exit 2
fi

version=$("$zcashd_bin" --version)
[[ $version == *v6.12.3* ]] || { echo 'expected zcashd v6.12.3' >&2; exit 2; }
umask 077
mkdir -p "$data_dir"
data_dir=$(cd "$data_dir" && pwd)
printf '%s\n' 'i-am-aware-zcashd-will-be-replaced-by-zebrad-and-zallet-in-2025=1' > "$data_dir/zcash.conf"

rpc() {
  "$zcash_cli_bin" -regtest -datadir="$data_dir" -rpcport="$port" "$@"
}

"$zcashd_bin" -regtest -datadir="$data_dir" -rpcbind=127.0.0.1 -rpcport="$port" -server \
  -listen=0 -connect=0 -dnsseed=0 \
  -nuparams=5ba81b19:1 -nuparams=76b809bb:1 -nuparams=c2d6d0b4:1 \
  > "$data_dir/zcashd.log" 2>&1 &
node_pid=$!
cleanup() {
  rpc stop >/dev/null 2>&1 || true
  wait "$node_pid" 2>/dev/null || true
}
trap cleanup EXIT

for _ in {1..100}; do
  if rpc getblockcount >/dev/null 2>&1; then break; fi
  sleep 0.1
done
rpc getblockcount >/dev/null

wait_op() {
  local opid=$1 result
  for _ in {1..120}; do
    result=$(rpc z_getoperationstatus "[\"$opid\"]" | python3 -c '
import json, sys
items = json.load(sys.stdin)
if not items:
    print("pending")
elif items[0]["status"] == "success":
    print(items[0]["result"]["txid"])
elif items[0]["status"] == "failed":
    print("error: " + items[0]["error"]["message"])
else:
    print("pending")
')
    if [[ $result == error:* ]]; then echo "$result" >&2; return 1; fi
    if [[ $result != pending ]]; then printf '%s\n' "$result"; return 0; fi
    sleep 0.5
  done
  echo "operation timed out: $opid" >&2
  return 1
}

account_zat() {
  rpc z_getbalanceforaccount "$1" | python3 -c 'import json,sys; print(json.load(sys.stdin)["pools"].get("orchard", {}).get("valueZat", 0))'
}

wait_account_balance() {
  local account=$1 expected=$2
  for _ in {1..40}; do
    if [[ $(account_zat "$account") == "$expected" ]]; then return 0; fi
    sleep 0.25
  done
  printf 'account %s did not reach %s zatoshis\n' "$account" "$expected" >&2
  return 1
}

rpc generate 1 >/dev/null
rpc generate 101 >/dev/null
[[ $(rpc getblockchaininfo | python3 -c 'import json,sys; print(json.load(sys.stdin)["consensus"]["chaintip"])') == c2d6d0b4 ]]

source_lines=$(rpc listunspent | python3 -c '
import json,sys
utxos = json.load(sys.stdin)
coinbase = sorted({u["address"] for u in utxos if u.get("generated") and u["amount"] == 6.25})
assert len(coinbase) >= 2, "need two mature 6.25 ZEC coinbase sources"
print("\n".join(coinbase[:2]))
')
mapfile -t sources <<< "$source_lines"
[[ ${#sources[@]} == 2 ]]

[[ $(rpc z_getnewaccount | python3 -c 'import json,sys; print(json.load(sys.stdin)["account"])') == 0 ]]
[[ $(rpc z_getnewaccount | python3 -c 'import json,sys; print(json.load(sys.stdin)["account"])') == 1 ]]
ua0=$(rpc z_getaddressforaccount 0 '["orchard"]' | python3 -c 'import json,sys; print(json.load(sys.stdin)["address"])')
ua1=$(rpc z_getaddressforaccount 1 '["orchard"]' | python3 -c 'import json,sys; print(json.load(sys.stdin)["address"])')

op0=$(rpc z_sendmany "${sources[0]}" "[{\"address\":\"$ua0\",\"amount\":6.24985}]" 1 0.00015 AllowRevealedSenders)
op1=$(rpc z_sendmany "${sources[1]}" "[{\"address\":\"$ua1\",\"amount\":6.24985}]" 1 0.00015 AllowRevealedSenders)
deposit0=$(wait_op "$op0")
deposit1=$(wait_op "$op1")
deposit_block=$(rpc generate 1 | python3 -c 'import json,sys; print(json.load(sys.stdin)[0])')
rpc getblock "$deposit_block" | python3 -c '
import json,sys
block=json.load(sys.stdin)
assert block["height"] == 103
assert set(sys.argv[1:]) <= set(block["tx"])
' "$deposit0" "$deposit1"
[[ $(rpc getblockchaininfo | python3 -c 'import json,sys; x=json.load(sys.stdin); print(next(p["chainValueZat"] for p in x["valuePools"] if p["id"] == "orchard"))') == 1249970000 ]]
wait_account_balance 0 624985000
wait_account_balance 1 624985000

spend_op=$(rpc z_sendmany "$ua0" "[{\"address\":\"$ua1\",\"amount\":1.0}]" 1 0.00015)
spend=$(wait_op "$spend_op")
spend_block=$(rpc generate 1 | python3 -c 'import json,sys; print(json.load(sys.stdin)[0])')
rpc getblock "$spend_block" | python3 -c '
import json,sys
block=json.load(sys.stdin)
assert block["height"] == 104
assert sys.argv[1] in block["tx"]
' "$spend"
[[ $(rpc getblockchaininfo | python3 -c 'import json,sys; x=json.load(sys.stdin); print(next(p["chainValueZat"] for p in x["valuePools"] if p["id"] == "orchard"))') == 1249955000 ]]
wait_account_balance 0 524970000
wait_account_balance 1 724985000

printf 'Historical node ordinary baseline passed in %s\n' "$data_dir"
printf 'Deposits: %s %s in block 103 %s\n' "$deposit0" "$deposit1" "$deposit_block"
printf 'Ordinary spend: %s in block 104 %s\n' "$spend" "$spend_block"
printf 'Orchard pool: 1249970000 -> 1249955000 zatoshis\n'
