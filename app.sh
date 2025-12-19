#!/bin/sh
set -x
while true; do
	# Fetch a recent price from Binance.
	price=$(curl -s "https://www.binance.com/api/v3/ticker/price?symbol=${TICKER}" | jq '(.price | tonumber) * 1000000 | trunc')
	if [ -z "$price" ]; then
		sleep 15
		continue
	fi
    echo "Fetched price: $price"
	# Format calldata to call submitObservation(uint128) method with the price.
	price_u128=$(printf '%064x' ${price})
	method="dae1ee1f" # Keccak4("submitObservation(uint128)")
	data="${method}${price_u128}"

	# Submit it to the Sapphire contract.
	curl -s \
		--json '{"encrypt": false, "tx": {"kind": "eth", "data": {"gas_limit": 200000, "to": "'${CONTRACT_ADDRESS}'", "value": "0", "data": "'${data}'"}}}' \
		--unix-socket /run/rofl-appd.sock \
  		http://localhost/rofl/v1/tx/sign-submit >/dev/null
    echo "Submitted price to contract ${CONTRACT_ADDRESS}"
  	# Sleep for a while.
	sleep 60
done
