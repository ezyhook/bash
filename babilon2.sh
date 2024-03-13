#/bin/bash
babway="$HOME/go/bin"
invento="$HOME/faucet/babnodes.txt"

test=$(~/go/bin/babylond q bank balances bbn15r3s8knp272jzfq004e0hyae0qj8p595x0ml8q --output json --node https://babylon-testnet-rpc.polkachu.com:443 | jq .balances[])
if [[ -n "$test" ]]
then
    bal=$(echo "$test" | jq .amount | tr -d \");
    if [[ "$bal" -gt 100000 ]]
    then
        start_time=$(date +%s)
        while read line
        do
            [[ -z "$line" ]] && break
            name="$(echo "$line" | cut -d ' ' -f1)"
            TOKEN="$(echo "$line" | cut -d ' ' -f2)"
            wallet="$(echo "$line" | cut -d ' ' -f3)"
            date --utc -d "+3 hours"
            curl  https://discord.com/api/v10/channels/1075371070493831259/messages -X POST -H "Content-Type: application/json" -H "Authorization: $TOKEN" -d '{"content": "!faucet '"$wallet"'"}'
            sleep 1
        done < "$invento"
        end_time=$(date +%s)
        proc_time=$(($end_time - $start_time))
        sleep $((21660 - $proc_time))
    fi
fi
