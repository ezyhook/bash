#/bin/bash

invento="$HOME/faucet/babnodes.txt"
while read line 
    do
        name="$(echo "$line" | cut -d ' ' -f1)"
        TOKEN="$(echo "$line" | cut -d ' ' -f2)"
        wallet="$(echo "$line" | cut -d ' ' -f3)"
        curl  https://discord.com/api/v10/channels/1075371070493831259/messages -X POST -H "Content-Type: application/json" -H "Authorization: $TOKEN" -d '{"content": "!faucet '"$wallet"'"}'
        sleep 1
    done < "$invento"
