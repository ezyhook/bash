#/bin/bash
keys="$HOME/faucet/keys.txt"
nodes="$HOME/faucet/nodes.txt"
invento="$HOME/faucet/babnodes.txt"
babway="$HOME/go/bin"

while read l
    do
        l1="$(echo "$l" | cut -d ':' -f1)"
        l2="$(echo "$l" | cut -d ':' -f5)"
        echo "$l1 $l2" >> "$invento"
    done < "$nodes"

while read line 
    do
        [[ -z "$line" ]] && break
        name="$(echo "$line" | cut -d ' ' -f1)"
        json=$($babway/babylond keys add $name --output json)
        echo "$json" >> $keys
        address=$(echo $json | jq '.address' | tr -d \")
        sed -i '/^'"$name"'/ s/$/ '"$address"'/' "$invento"
    done < "$invento"
