#/bin/bash
babway="$HOME/go/bin"
invento="$HOME/faucet/babnodes.txt"
target="$1"
while read line 
    do
        name="$(echo "$line" | cut -d ' ' -f1)"
        TOKEN="$(echo "$line" | cut -d ' ' -f2)"
        wallet="$(echo "$line" | cut -d ' ' -f3)"
        curl  https://discord.com/api/v10/channels/1075371070493831259/messages -X POST -H "Content-Type: application/json" -H "Authorization: $TOKEN" -d '{"content": "!faucet '"$wallet"'"}'
        sleep 1
    done < "$invento"

sleep 900

while read line1
    do
        wallet1="$(echo "$line1" | cut -d ' ' -f3)"
        "$babway"/babylond tx bank send "$wallet1" "$target" 99990ubbn --fee-payer "$wallet1" --node https://rpc.testnet3.babylonchain.io:443 --fees 10ubbn -y
        sleep 1
    done < "$invento"
