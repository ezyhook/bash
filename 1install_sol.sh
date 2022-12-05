#!/bin/bash
set -eu
set +f
set -o pipefail
exitcode="exit 1"
restor_all(){
while true; do
read -p "$(echo -e "\e[1m\e[32m Are you want REMOVE all and restor back?. Restor Y/N? \e[0m")" restor </dev/tty
    case "$restor" in
    [Yy]* ) echo -e "\e[1m\e[32m Let's go restor all back! \e[0m"
            systemctl stop solana.service
            systemctl stop solana-sys-tuner.service
            systemctl disable solana.service &> /dev/null
            systemctl disable solana-sys-tuner.service &> /dev/null
            [[ -d "/root/solana" ]] && rm -rf /root/solana
            [[ -e "/etc/systemd/system/solana.service" ]] && rm /etc/systemd/system/solana.service 
            [[ -e "/etc/systemd/system/solana-sys-tuner.service" ]] && rm /etc/systemd/system/solana-sys-tuner.service
            [[ -d "/root/.local/share/solana" ]] && rm -rf /root/.local/share/solana
            [[ -d "/root/.config/solana" ]] && rm -rf /root/.config/solana
            rm ~/validator-keypair.json ~/vote-account-keypair.json
            systemctl daemon-reload
            (($ram1==1)) && umount /mnt/solana-accounts && rm -rf /mnt/solana-accounts
            (($ram1==1)) && swapoff -a && rm /swapfile && sed -i 's/\/swapfile swap swap defaults 0 0//' /etc/fstab && sed -i '/swap/s/^#//' /etc/fstab && swapon -a
            sed -i '/solana/d' /root/.profile
            sed -i '/solana/d' /root/.bash_profile
            sed -i '/export ram1/d' /root/.profile
            sed -i '/export ram1/d' /root/.bash_profile
            echo "Solana removed."
            "$exitcode";;
    [Nn]* ) "$exitcode";;
        * ) echo -e "\e[1m\e[31m Please answer Y or N. \e[0m";;
    esac
done	    
}
dockerinstall(){
  apt update && apt install lsb-release gnupg ca-certificates git jq unzip wget curl libssl-dev smartmontools -y
  #install docker
  if ! command -v docker &> /dev/null
    then
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update
      sudo apt-get install docker-ce docker-ce-cli containerd.io -y
  fi
  #install docker-compose
  [[ ! -d "/root/.docker/cli-plugins/" ]] && mkdir -p "$HOME"/.docker/cli-plugins
  url1="$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r ".assets[] | select(.name | test(\"docker-compose-linux-x86_64\")) | .browser_download_url" | head -1)"
  curl -sL -o "$HOME"/.docker/cli-plugins/docker-compose "$url1"
  sudo chmod +x "$HOME"/.docker/cli-plugins/docker-compose
}
inst(){
	curl -sSf https://raw.githubusercontent.com/solana-labs/solana/v$1/install/solana-install-init.sh | sh -s - $1
	echo "export PATH=/root/.local/share/solana/install/active_release/bin:\$PATH" >> /root/.profile
	echo "export PATH=/root/.local/share/solana/install/active_release/bin:\$PATH" >> /root/.bash_profile
	sudo sysctl -w vm.max_map_count=1000000
	sudo sysctl -a | grep vm.max_map_count
	mkdir /root/solana
}
config(){
  soldir="/root/.local/share/solana/install/active_release/bin"
	"$soldir"/solana config set --url https://api.testnet.solana.com --keypair /root/solana/validator-keypair.json || { echo "Config promlem" && "$exitcode"; }
	cp ./validator-keypair.json /root/solana/validator-keypair.json || { echo "No key validator-keypair.json" && "$exitcode"; }
	cp ./vote-account-keypair.json /root/solana/vote-account-keypair.json || { echo "No key vote-account-keypair.json" && "$exitcode"; }
}
systune(){
	tee /etc/systemd/system/solana-sys-tuner.service > /dev/null <<EOF
[Unit]
Description=Solana sys-tuner
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/root/.local/share/solana/install/active_release/bin/solana-sys-tuner --user root

[Install]
WantedBy=multi-user.target
EOF
	chmod 0644 /etc/systemd/system/solana-sys-tuner.service
	systemctl daemon-reload
	systemctl enable solana-sys-tuner.service 
}
syssolana(){
	tee /etc/systemd/system/solana.service > /dev/null <<EOF
[Unit]
Description=Solana TdS node
After=network.target
StartLimitIntervalSec=0
After=sys-tuner-solana.service
[Service]
Type=simple
Restart=always
RestartSec=1
LimitNOFILE=1524000
Environment="SOLANA_METRICS_CONFIG=host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"
ExecStart=/root/.local/share/solana/install/active_release/bin/solana-validator \\
--entrypoint entrypoint.testnet.solana.com:8001 \\
--entrypoint entrypoint2.testnet.solana.com:8001 \\
--entrypoint entrypoint3.testnet.solana.com:8001 \\
--known-validator 5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on \\
--known-validator dDzy5SR3AXdYWVqbDEkVFdvSPCtS9ihF5kJkHCtXoFs \\
--known-validator Ft5fbkqNa76vnsjYNwjDZUXoTWpP7VYm3mtsaQckQADN \\
--known-validator eoKpUABi59aT4rR9HGS3LcMecfut9x7zJyodWWP43YQ \\
--known-validator 9QxCLckBiJc783jnMvXZubK4wH86Eqqvashtrwvcsgkv \\
--expected-genesis-hash 4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY \\
--wal-recovery-mode skip_any_corrupted_record \\
--limit-ledger-size 50000000 \\
--identity /root/solana/validator-keypair.json \\
--vote-account /root/solana/vote-account-keypair.json \\
--ledger /root/solana/validator-ledger \\
--log - \\
--maximum-local-snapshot-age 3000 \\
--snapshot-interval-slots 1000 \\
--dynamic-port-range 8000-8020 \\
#--accounts /mnt/solana-accounts/acc \\
#--gossip-port 8001 \\
--only-known-rpc \\
--no-snapshot-fetch \\
--full-rpc-api \\
--private-rpc \\
--rpc-port 8899
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
[Install]
WantedBy=multi-user.target
EOF
	chmod 0644 /etc/systemd/system/solana.service
	systemctl daemon-reload
	systemctl enable solana.service
}
downsnap(){
docker pull c29r3/solana-snapshot-finder:latest; \
sudo docker run -it --rm \
-v ~/solana/validator-ledger:/solana/snapshot \
--user $(id -u):$(id -g) \
c29r3/solana-snapshot-finder:latest \
--max_download_speed 192 \
--snapshot_path /solana/snapshot \
-r http://api.testnet.solana.com
}
makeramdisk(){
  mkdir /mnt/solana-accounts
  echo "tmpfs /mnt/solana-accounts tmpfs rw,size=30G,user=root 0 0" >> /etc/fstab
  mkdir /mnt/solana-accounts/acc
  swapoff -a
  sed -i '/swap/s/^/#/' /etc/fstab
  dd if=/dev/zero of=/swapfile bs=1MiB count=61KiB && chmod 0600 /swapfile 
  echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
  mkswap /swapfile
  swapon -a
  mount /mnt/solana-accounts/
  sed -i '/accounts/s/^#//' /etc/systemd/system/solana.service
  systemctl daemon-reload
}
restartsol(){
	systemctl restart solana-sys-tuner.service && systemctl restart solana
    #restor_all
    #echo "The end!"
}

(command -V solana &> /dev/null) && restor_all
[ "$(whoami)" == "root" ] && echo -e "\e[1m\e[32m root -ok \e[0m" || { echo -e "\e[1m\e[31m Sorry $(whoami), this script only for ROOT! \e[0m" && "$exitcode"; }
if [[ ! -e "validator-keypair.json" || ! -e "vote-account-keypair.json" ]]; then
echo "*******************************************************************************************************************************************"
echo -e "\e[1m\e[32m Insert the TEXT of the validator-keypad key, then vote-account-keypad. Make sure there are NO spaces and extra characters. Are you ready? \e[0m"
echo "*******************************************************************************************************************************************"
while true; do
    read -p "$(echo -e "\e[1m\e[32m Are you ready? Y/N? \e[0m")" ready </dev/tty
    case "$ready" in
        [Yy]* ) echo -e "\e[1m\e[32m Let's go! Insert or check validator-keypair \e[0m" && sleep 3
                nano validator-keypair.json
                echo -e "\e[1m\e[32m Let's go! Insert or check vote-account-keypair \e[0m" && sleep 3
                nano vote-account-keypair.json
                break;;
        [Nn]* ) "$exitcode";;
            * ) echo -e "\e[1m\e[31m Please answer Y or N. \e[0m";;
    esac
done
fi

[[ -f "validator-keypair.json" && -s "validator-keypair.json" ]] && echo -e "\e[1m\e[32m validator-keypair.json - ok \e[0m" || { echo -e "\e[1m\e[31m validator-keypair.json - not found key, good bay my friend \e[0m" && "$exitcode"; }
[[ -f "vote-account-keypair.json" && -s "vote-account-keypair.json" ]] && echo -e "\e[1m\e[32m vote-account-keypair.json -ok \e[0m" || { echo -e "\e[1m\e[31m vote-account-keypair.json - no found key, good bay my friend \e[0m" && "$exitcode"; }

while true; do
    read -p "$(echo -e "\e[1m\e[32m The testing was successful. Continue Y/N? \e[0m")" yn </dev/tty
    case "$yn" in
        [Yy]* ) echo -e "\e[1m\e[32m Let's go! \e[0m"; break;;
        [Nn]* ) "$exitcode";;
            * ) echo -e "\e[1m\e[31m Please answer Y or N. \e[0m";;
    esac
done

echo -e "\e[1m\e[32m Enter version of SOLANA \e[0m"
read -p "Version: v" ver1

while true; do
    read -p "$(echo -e "\e[1m\e[32m Install Ramdisk 30G and Swap 60G Y/N? \e[0m")" ynr </dev/tty
    case "$ynr" in
        [Yy]* ) ram1=1; echo -e "\e[1m\e[32m Ramdisk and swap - yes \e[0m"; echo "export ram1=1" >> /root/.bash_profile; break;;
        [Nn]* ) ram1=0; echo -e "\e[1m\e[32m Ramdisk and swap - no \e[0m"; echo "export ram1=0" >> /root/.bash_profile; break;;
            * ) echo -e "\e[1m\e[31m Please answer Y or N. \e[0m";;
    esac
done

echo -e "\e[1m\e[32m Lets start... \e[0m" && sleep 1
#Docker
echo -e "\e[1m\e[32m Check and installing Docker... \e[0m" && sleep 1
dockerinstall &> /dev/null
#Solana
echo -e -n "\e[1m\e[32m Dowloading Solana v${ver1}.. \e[0m" && { inst $ver1 &> /dev/null && echo -e "\e[1m\e[32m - Solana installed. \e[0m" && sleep 1 || { echo -e "\e[1m\e[31m - Error install solana \e[0m" && restor_all; } ; }
config && echo -e "\e[1m\e[32m Solana configured \e[0m" && sleep 1 || { echo -e "\e[1m\e[31m Error configuration \e[0m" && restor_all; }
#Systune service
systune &> /dev/null && echo -e "\e[1m\e[32m Sys-tune installed. \e[0m" && sleep 1 || { echo -e "\e[1m\e[31m Error install sys-tune \e[0m" && restor_all; }
#Solana service
syssolana &> /dev/null && echo -e "\e[1m\e[32m Solana-service installed. \e[0m" && sleep 1 || { echo -e "\e[1m\e[31m Error install solana-service \e[0m" && restor_all; }
#Ramdisk and swap
echo -e -n "\e[1m\e[32m Installing ramdisk and swap pls whait... \e[0m"
(($ram1==0)) && echo -e "\e[1m\e[32m Ramdisk and swap - not installed \e[0m" || { makeramdisk &> /dev/null && echo -e "\e[1m\e[32m Ramdisk and swap installed. \e[0m" && sleep 1 || { echo -e "\e[1m\e[31m Error install ramdisk and swap \e[0m" && restor_all; } ; }
#Downloading snapshot
echo -e -n "\e[1m\e[32m Downloading snapshot pls whait... \e[0m"
downsnap &> /dev/null && echo -e "\e[1m\e[32m Snapshot downloaded. \e[0m" && sleep 1 || { echo -e "\e[1m\e[31m Error download snapshot \e[0m" && restor_all; }
#Restart
restartsol && echo -e "\e[1m\e[32m Solana restarted. \e[0m" && sleep 1 || { echo -e "\e[1m\e[31m Error restart \e[0m" && restor_all; }
echo "==================================================="
#Status solana
echo -e '\n\e[42m Checking Solana status: \e[0m\n' && sleep 1
if [[ `systemctl status solana | grep active` =~ "running" ]]; then
    echo -e "\e[1m\e[32m solana catchup /root/solana/validator-keypair.json --our-localhost --follow --log \e[0m"
    sed -i '/no-snapshot-fetch/s/^/#/' /etc/systemd/system/solana.service && systemctl daemon-reload
    echo -e "\e[1m\e[32m Installation successful, status 'active' node is ranning. \e[0m" && "$exitcode"
else
  echo -e "Your Solana Node \e[31mwas not installed correctly\e[39m, please reinstall." && restor_all
fi
