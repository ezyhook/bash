#/bin/bash
babway="$HOME/go/bin"
invento="$HOME/faucet/babnodes.txt"
target="$1"


while read line1
    do
        wallet1="$(echo "$line1" | cut -d ' ' -f3)"
        echo $("$babway"/babylond q bank balances "$wallet1" --output json --node https://rpc.testnet3.babylonchain.io:443)
    done < "$invento"
