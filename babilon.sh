#/bin/bash
babway="$HOME/go/bin"
invento="$HOME/faucet/babnodes.txt"
target="$1"
while read line 
    do
        [[ -z "$line" ]] && break
        name="$(echo "$line" | cut -d ' ' -f1)"
        TOKEN="$(echo "$line" | cut -d ' ' -f2)"
        wallet="$(echo "$line" | cut -d ' ' -f3)"
        date --date='TZ="Europe/Moscow"'
        curl  https://discord.com/api/v10/channels/1075371070493831259/messages -X POST -H "Content-Type: application/json" -H "Authorization: $TOKEN" -d '{"content": "!faucet '"$wallet"'"}'
        sleep 3
    done < "$invento"

sleep 1200

while read line1
    do
        [[ -z "$line1" ]] && break
        wallet1="$(echo "$line1" | cut -d ' ' -f3)"
        date --date='TZ="Europe/Moscow"'
        "$babway"/babylond tx bank send "$wallet1" "$target" 99990ubbn --fee-payer "$wallet1" --node https://babylon-testnet-rpc.polkachu.com:443 --fees 10ubbn -y
        sleep 1
    done < "$invento"
