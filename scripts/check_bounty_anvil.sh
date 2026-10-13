#!/usr/bin/env bash
set -euo pipefail

port=${ANVIL_PORT:-18549}
rpc="http://127.0.0.1:$port"
funder=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
reviewer=0x70997970c51812dc3a010c7d01b50e0d17dc79c8
claimant=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc
stranger=0x90f79bf6eb2c4f870365e785982e1f101e93b906
manifest=0x0000000000000000000000000000000000000000000000000000000000000001
journal=0x0000000000000000000000000000000000000000000000000000000000000002
report=0x0000000000000000000000000000000000000000000000000000000000000003

anvil --silent --host 127.0.0.1 --port "$port" \
  --mnemonic 'test test test test test test test test test test test junk' &
anvil_pid=$!
trap 'kill "$anvil_pid" 2>/dev/null || true' EXIT

for _ in {1..50}; do
  if cast block-number --rpc-url "$rpc" >/dev/null 2>&1; then break; fi
  sleep 0.1
done
cast block-number --rpc-url "$rpc" >/dev/null

deploy() {
  forge create --broadcast --json --unlocked --from "$funder" --rpc-url "$rpc" \
    --value 0.001ether contracts/HistoricalOrchardBounty.sol:HistoricalOrchardBounty \
    --constructor-args "$reviewer" "$manifest" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["deployedTo"])'
}

payout_bounty=$(deploy)
refund_bounty=$(deploy)
[[ $(cast balance --rpc-url "$rpc" "$payout_bounty") == 1000000000000000 ]]
[[ $(cast balance --rpc-url "$rpc" "$refund_bounty") == 1000000000000000 ]]

claim_id=$(cast call --rpc-url "$rpc" --from "$claimant" "$payout_bounty" \
  'submit(bytes32,bytes32)(bytes32)' "$journal" "$report")
cast send --rpc-url "$rpc" --unlocked --from "$claimant" "$payout_bounty" \
  'submit(bytes32,bytes32)' "$journal" "$report" >/dev/null
if cast send --rpc-url "$rpc" --unlocked --from "$stranger" "$payout_bounty" \
    'approve(bytes32)' "$claim_id" >/dev/null 2>&1; then
  echo 'unauthorized approval unexpectedly succeeded' >&2
  exit 1
fi
cast send --rpc-url "$rpc" --unlocked --from "$reviewer" "$payout_bounty" \
  'approve(bytes32)' "$claim_id" >/dev/null
claimant_before=$(cast balance --rpc-url "$rpc" "$claimant")
withdraw_receipt=$(cast send --rpc-url "$rpc" --unlocked --from "$claimant" \
  "$payout_bounty" 'withdraw()' --json)
claimant_after=$(cast balance --rpc-url "$rpc" "$claimant")
python3 -c '
import json, sys
receipt = json.load(sys.stdin)
fee = int(receipt["gasUsed"], 16) * int(receipt["effectiveGasPrice"], 16)
assert int(sys.argv[2]) + fee - int(sys.argv[1]) == 10**15
' "$claimant_before" "$claimant_after" <<< "$withdraw_receipt"
[[ $(cast balance --rpc-url "$rpc" "$payout_bounty") == 0 ]]
[[ $(cast call --rpc-url "$rpc" "$payout_bounty" 'paid()(bool)') == true ]]
if cast send --rpc-url "$rpc" --unlocked --from "$claimant" "$payout_bounty" \
    'withdraw()' >/dev/null 2>&1; then
  echo 'duplicate withdrawal unexpectedly succeeded' >&2
  exit 1
fi

cast rpc --rpc-url "$rpc" evm_increaseTime 604801 >/dev/null
cast rpc --rpc-url "$rpc" evm_mine >/dev/null
if cast send --rpc-url "$rpc" --unlocked --from "$claimant" "$refund_bounty" \
    'submit(bytes32,bytes32)' "$journal" "$report" >/dev/null 2>&1; then
  echo 'late claim unexpectedly succeeded' >&2
  exit 1
fi
cast send --rpc-url "$rpc" --unlocked --from "$funder" "$refund_bounty" \
  'refund()' >/dev/null
[[ $(cast balance --rpc-url "$rpc" "$refund_bounty") == 0 ]]
[[ $(cast call --rpc-url "$rpc" "$refund_bounty" 'refunded()(bool)') == true ]]

printf 'Anvil escrow payout and refund passed on %s\n' "$rpc"
