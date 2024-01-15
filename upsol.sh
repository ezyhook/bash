{
set -eu
set +f
set -o pipefail

service_file="/etc/systemd/system/solana.service"
time_const=400
limit=3600
soldir="/root/.local/share/solana/install/active_release/bin"

if grep -q "mainnet" /root/.config/solana/cli/config.yml;
then
      serv_file="https://wdmaster.ru/bash/1main_solana.service.sh"
      API_URL="https://api.mainnet-beta.solana.com"
      echo "Found cluster MAINNET"
      cluster="main"
else
      serv_file="https://wdmaster.ru/bash/1test_solana.service.sh";
      API_URL="https://api.testnet.solana.com"
      echo "Found cluster TESTNET"
      cluster="test"
fi

status(){
      echo -e '\n\e[42m Checking Solana status: \e[0m\n' && sleep 10
      if [[ `systemctl status solana | grep active` =~ "running" ]]; then
            echo -e "\e[1m\e[32m solana catchup /root/solana/validator-keypair.json --our-localhost --follow --log \e[0m"
            echo -e "\e[1m\e[32m journalctl -u solana -f \e[0m"
            echo -e "\e[1m\e[32m Installation successful, status 'active' node is RUNNING 🟢! \e[0m" && exit 0
      else
            echo -e "\e[31m Your solana.service not correctly 🔴\e[0m" && exit 1
      fi
}

syssolana(){
      curl -s -A 'Hi' -o /etc/systemd/system/solana.service $serv_file
      sed -i '/no-snapshot-fetch/s/^#//' /etc/systemd/system/solana.service
	chmod 0644 /etc/systemd/system/solana.service
	systemctl daemon-reload
}

checktime (){
      key="$1"
      slot=$(curl --silent $API_URL -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getEpochInfo"}')
      cluster_slot=$(echo "$slot" | jq '.result.slotIndex')
      end_slot=$(echo "$slot" | jq '.result.slotsInEpoch')
      _slots=$(curl --silent -X POST $API_URL -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0", "id":1, "method":"getLeaderSchedule", "params":[{"identity":"'${key}'"}]}')
      next_slots=$(echo "$_slots" | jq '.result."'"$key"'"' | jq '.[]' | awk -v var=${cluster_slot} '$1>=var' | sed -n '5~4 p')
      current_slot=$(echo "$_slots" | jq '.result."'"$key"'"' | jq '.[]' | awk -v var=${cluster_slot} '$1>=var' | head -n1)
      left_slot="$(( $current_slot - $cluster_slot ))"
      secs_end_epoh="$(( ("$end_slot" - "$cluster_slot") * "$time_const"/1000 ))";
      secs="$(( $left_slot * $time_const/1000 ))"
      if (($secs > $limit)) && (($secs_end_epoh > $limit))
      then
          echo true "$secs"
      elif (($secs < 0)) && (($secs_end_epoh > $limit))
      then
          echo true "$secs"
      else
          echo false "$secs"
      fi
}

echo "Update params:"
if [[ $# -ge 1 ]]
then
      version=""
      snap=""
      noservice=""
      yes=""
      for arg in "$@"
      do
            case $arg in  
            [0-9]*.[0-9]*.[0-9]*) version=$arg; echo "🟢 Solana version: $version"
                  ;;
            -s) snap=$arg; echo "🟢 Snapshot: true"
                  ;;
            --full) snap=$arg; echo "🟢 Full Snapshot: true"
                  ;;
            --nos) noservice=$arg; echo "🔴 Update service: false"
                  ;;
            -y) yes=$arg
                  ;;
            *) echo "🔴 $arg -Incorrect parametr"; exit 1
                  ;;
            esac
      done

      [[ -z "$version" ]] && echo "🔴 Error: No version" && exit 1
      [[ -z "$snap" ]] && { snap=0; echo "🔴 Snapshot: false"; }
      [[ -z "$noservice" ]] && echo "🟢 Update service: true"


      if [[ -z "$yes" ]]
      then
            while true; do
                  read -p "$(echo -e "\e[1m\e[32m Are you ready update to $version ? Y/N? \e[0m")" ready </dev/tty
                  case "$ready" in
                        [Yy]* ) 
                              echo -e "\e[1m\e[32m Let's go!\e[0m"
                              [[ -z "$noservice" ]] && syssolana $serv_file
                              break;;
                        [Nn]* ) 
                              exit;;
                        * ) 
                              echo -e "\e[1m\e[31m Please answer Y or N. \e[0m";;
                  esac
            done
      fi
      read check sec1 < <(checktime $("$soldir"/solana address -ul --keypair /root/solana/validator-keypair.json))
      if [[ "$check" = true ]]
      then
            echo "Time to next slot: $sec1 s"
      else  
            if [[ -z "$yes" ]]
            then
                  echo "Interval low for restart, try after $sec1 s"
                  while true; do
                        read -p "$(echo -e "\e[1m\e[32m Continue ? Y/N? \e[0m")" ready1 </dev/tty
                        case "$ready1" in
                              [Yy]* ) echo -e "\e[1m\e[32m ok \e[0m"
                                    break;;
                              [Nn]* ) exit;;
                              * ) echo -e "\e[1m\e[31m Please answer Y or N. \e[0m";;
                        esac
                  done
            fi
      fi

      solana-install init "$version" && echo "Version "$version" ready for restart"
      echo "Start triming.." && fstrim -av
      
      if [[ "$snap" = "-s" ]]
      then
            case $cluster in
            main) echo "Downloading mainnet snapshot.."
                  #wget --trust-server-names --content-on-error --retry-on-http-error=413 http://145.40.67.83:80/incremental-snapshot.tar.bz2 -P /root/solana/validator-ledger;
                  wget --trust-server-names --content-on-error --retry-on-http-error=413 $API_URL/incremental-snapshot.tar.bz2 -P /root/solana/validator-ledger;
            ;;
            test) echo "Downloading testnet snapshot.."  
                  #wget --trust-server-names --content-on-error --retry-on-http-error=413 http://139.178.68.207:80/incremental-snapshot.tar.bz2 -P /root/solana/validator-ledger;
                  wget --trust-server-names --content-on-error --retry-on-http-error=413 $API_URL/incremental-snapshot.tar.bz2 -P /root/solana/validator-ledger;
            ;;
            esac
      elif [[ "$snap" = "--full" ]]
      then
            case $cluster in
            main) echo "Downloading FULL mainnet snapshot.."
                  #wget --trust-server-names --content-on-error --retry-on-http-error=413 http://145.40.67.83:80/snapshot.tar.bz2 -P /root/solana/validator-ledger;
                  #wget --trust-server-names --content-on-error --retry-on-http-error=413 http://145.40.67.83:80/incremental-snapshot.tar.bz2 -P /root/solana/validator-ledger;
                  wget --trust-server-names --content-on-error --retry-on-http-error=413 $API_URL/snapshot.tar.bz2 -P /root/solana/validator-ledger;
                  sleep 30;
                  wget --trust-server-names --content-on-error --retry-on-http-error=413 $API_URL/incremental-snapshot.tar.bz2 -P /root/solana/validator-ledger;
            ;;
            test) echo "Downloading FULL testnet snapshot.."  
                  wget --trust-server-names --content-on-error --retry-on-http-error=413 http://139.178.68.207:80/snapshot.tar.bz2 -P /root/solana/validator-ledger;
                  sleep 16;
                  wget --trust-server-names --content-on-error --retry-on-http-error=413 http://139.178.68.207:80/incremental-snapshot.tar.bz2 -P /root/solana/validator-ledger;
                  #wget --trust-server-names --content-on-error --retry-on-http-error=413 $API_URL/snapshot.tar.bz2 -P /root/solana/validator-ledger;
                  #sleep 10;
                  #wget --trust-server-names --content-on-error --retry-on-http-error=413 $API_URL/incremental-snapshot.tar.bz2 -P /root/solana/validator-ledger;
            ;;
            esac
      fi
      grep -q "#no-snapshot-fetch" $service_file && { sed -i '/no-snapshot-fetch/s/^#//' $service_file && systemctl daemon-reload; }
      systemctl restart solana && echo "Solana restarted."
      grep -q "no-snapshot-fetch" $service_file && { sed -i '/no-snapshot-fetch/s/^/#/' $service_file && systemctl daemon-reload; }
      status
else
      echo "Usege: upsol 1.16.17 [-s|--full] [-nos]"; exit
fi
}
