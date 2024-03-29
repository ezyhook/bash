#/bin/bash
babway="$HOME/go/bin"
invento="$HOME/faucet/babnodes.txt"
target="$1"


while read line1
    do
        [[ -z "$line1" ]] && break
        wallet1="$(echo "$line1" | cut -d ' ' -f3)"
        echo $("$babway"/babylond q bank balances "$wallet1" --output json --node https://babylon-testnet-rpc.polkachu.com:443)
    done < "$invento"
