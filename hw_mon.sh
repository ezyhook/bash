#set -x

BOT_TOKEN="$1"
CHAT_ID_ALARM="$2"
CHAT_ID_HARDINFO="$2"
HOST_NAME="$3"
INFO_ALARM1="Critical Parametr!"
#IP="$(curl -s ifconfig.me)"
IP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')

MAX_CPU_PERC=99
MAX_DISK_PERC=100
MAX_RAM_PERC=98
MAX_SWAP_PERC=98
MAX_RAMDISK_PERC=98
MON_PROC="xmrig kdevtmpfsi kinsing dbused perfcc"

export LC_NUMERIC="en_US.UTF-8"
CPU=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
SYSTEM_LOAD=$(cat /proc/loadavg | awk '{print $2}') # load avg за 5 мин.
POTOK_LOAD=$(grep processor /proc/cpuinfo | wc -l)

RAM_TEMP=$(free -g | awk '{print $2,$3}' | awk 'NR==2 {print; exit}')
RAM_TOTAL=$(echo "$RAM_TEMP" | awk '{print $1}')
RAM_USED=$(echo "$RAM_TEMP" | awk '{print $2}')
RAM_PERC=$(bc <<< "scale=2; $RAM_USED/$RAM_TOTAL*100" | grep -oE "[0-9]*" | awk 'NR==1 {print; exit}')

SWAP_TEMP=$(free -g | awk '{print $2,$3}' | awk 'NR==3 {print; exit}')
SWAP_TOTAL=$(echo "$SWAP_TEMP" | awk '{print $1}')
SWAP_USED=$(echo "$SWAP_TEMP" | awk '{print $2}')
SWAP_PERC=$(echo "scale=2; $SWAP_USED/$SWAP_TOTAL*100" | bc | grep -oE "[0-9]*" | awk 'NR==1 {print; exit}')

DISK_TEMP=$(df -h / | awk '{print $2,$3,$5}'| awk 'NR==2 {print; exit}')
DISK_TOTAL=$(echo "$DISK_TEMP" | awk '{print $1}')
DISK_USED=$(echo "$DISK_TEMP" | awk '{print $2}')
DISK_PERC=$(echo "$DISK_TEMP" | awk '{print $3}')

USED_RAM=""$RAM_USED"G/"$RAM_TOTAL"G ~ "$RAM_PERC"%"
USED_SWAP=""$SWAP_USED"G/"$SWAP_TOTAL"G ~ "$SWAP_PERC"%"
USED_DISK=""$DISK_USED"/"$DISK_TOTAL" ~ "$DISK_PERC"" 


lookmainer(){
    for i in $@
      do
        if [[ $(pgrep -c $i) -gt 0 ]]; then
            arr_proc+=("$i")
        fi
    done
    if [[ ${#arr_proc[@]} -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}
killminers(){
    for j in $@
      do
        proc_file=$(pgrep $j | while read pid; do readlink -f /proc/$pid/exe; done)
        pkill -9 -f $j
        rm "$proc_file"
    done
    rm -rf /tmp/*
}


if (( $(bc <<< "$RAM_PERC >= $MAX_RAM_PERC") )) || (( $(bc <<< "$CPU >= $MAX_CPU_PERC") )) || (( $(bc <<< "$SWAP_PERC >= $MAX_SWAP_PERC") )) || (( $(bc <<< "${DISK_PERC::-1} >= $MAX_DISK_PERC") ))
then
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_ALARM"'","text":"<b>'🔴"$HOST_NAME":"$INFO_ALARM1"'</b>'"\n[$IP]"'<code>
CPU  >>> ['"$CPU"']
RAM  >>> ['"$USED_RAM"']
Disk >>> ['"$USED_DISK"']
SWAP >>> ['"$USED_SWAP"']</code>","parse_mode": "html"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
fi

if lookmainer $MON_PROC
then
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_ALARM"'","text":"<b>'🔴"$HOST_NAME":"$INFO_ALARM1"'</b>'"\n[$IP]"'<code>
🔴 Killed '"${#arr_proc[@]}"' miners: '"${arr_proc[@]}"'</code>","parse_mode": "html"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
killminers "${arr_proc[@]}"
fi

#if (( $(echo "$(date +%M) < 5" | bc -l) ))
#then
#curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_HARDINFO"'","text":"<b>'🟢"$HOST_NAME"'</b>'"\n[$IP]"'<code>
#Used_CPU >> ['"$CPU"']
#Proc_LA  >> ['"$SYSTEM_LOAD"'] max:'"$POTOK_LOAD"'
#Ram  >> ['"$USED_RAM"'] 
#Swap >> ['"$USED_SWAP"'] 
#Disk >> ['"$USED_DISK"']</code>",  "parse_mode": "html"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
#fi

#set +x
