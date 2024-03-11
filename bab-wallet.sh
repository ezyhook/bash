#/bin/bash
keys="$HOME/faucet/keys.txt"
nodes="$HOME/faucet/nodes.txt"
tmpfile="$HOME/faucet/tmp"
invento="$HOME/faucet/babnodes.txt"
babway="$HOME/go/bin"

while read l
    do
        l1="$(echo "$l" | cut -d ':' -f1)"
        l2="$(echo "$l" | cut -d ':' -f$1)"
        echo "$l1 $l2" >> "$tmpfile"
    done < "$nodes"

while read line 
    do
        [[ -z "$line" ]] && break
        name="$(echo "$line" | cut -d ' ' -f1)"
        json=$($babway/babylond keys add $name --output json)
        echo "$json" >> $keys
        address=$(echo $json | jq '.address' | tr -d \")
        sed -i '/^'"$name"'/ s/$/ '"$address"'/' "$tmpfile"
    done < "$tmpfile"

cat "$tmpfile" >> "$invento"
rm "$tmpfile"
