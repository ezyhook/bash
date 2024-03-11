#/bin/bash
babway="$HOME/go/bin"
invento="$HOME/faucet/babnodes.txt"
target="$1"

while read line1
    do
        [[ -z "$line1" ]] && break
        wallet1="$(echo "$line1" | cut -d ' ' -f3)"
        test=$(~/go/bin/babylond q bank balances $wallet1 --output json --node https://babylon-testnet-rpc.polkachu.com:443 | jq .balances[])
        [[ -n "$test" ]] && { bal=$(echo "$test" | jq .amount | tr -d \");
            amo=$(($bal - 10));
            "$babway"/babylond tx bank send "$wallet1" "$target" ${amo}ubbn --fee-payer "$wallet1" --node https://babylon-testnet-rpc.polkachu.com:443 --fees 10ubbn -y &> /dev/null;
            echo "$wallet1 - resend ${amo}ubbn"; }
    done < "$invento"
