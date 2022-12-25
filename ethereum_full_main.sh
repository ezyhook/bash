makejwtsecret() {
sudo mkdir -p /var/lib/jwtsecret_eth
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret_eth/jwt.hex > /dev/null
}

#installing ethereum execution layer
makeerigon() {
apt-get install -y build-essential supervisor wget git

if (! command -V go &> /dev/null); then
    wget https://golang.org/dl/go1.19.1.linux-amd64.tar.gz | tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
    ln -s /usr/local/go/bin/go /usr/local/bin/go
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
    . ~/.profile
fi

if [[ ! -e "/opt/erigon_eth/ethereum/bin/erigon" ]]; then
    mkdir -p /opt/erigon_eth/github
    mkdir -p /opt/erigon_eth/ethereum
    cd /opt/erigon_eth/github && git clone https://github.com/ledgerwatch/erigon.git
    cd /opt/erigon_eth/github/erigon && make erigon
    cp -r /opt/erigon_eth/github/erigon/build/bin /opt/erigon_eth/ethereum/bin
fi
#-------------------------------------
tee /etc/systemd/system/erigon_eth.service > /dev/null <<EOF
[Unit]
Description="Erigon service"
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=3
TimeoutStopSec=600
User=root
LimitNOFILE=200000
WorkingDirectory=/opt/erigon_eth/ethereum
ExecStart=/opt/erigon_eth/ethereum/bin/erigon \\
--datadir mainnet --private.api.addr=127.0.0.1:9090 \\
--torrent.download.rate=100mb --chain=mainnet --port=30303 \\
--http.port=8545 --torrent.port=42069 \\
--http --http.addr=0.0.0.0 --ws --http.api=eth,debug,net,trace,web3,txpool,erigon \\
--metrics --metrics.addr="0.0.0.0" --metrics.port="44451" \\
--authrpc.jwtsecret="/var/lib/jwtsecret_eth/jwt.hex" \\
--externalcl
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/erigon_eth.service
systemctl daemon-reload
systemctl enable erigon_eth.service
systemctl start erigon_eth.service
}

#installing lighthouse
makelighthouse() {
cd $HOME
if [[ ! -e "/usr/local/bin/lighthouse" ]]; then
    wget https://github.com/sigp/lighthouse/releases/download/v3.3.0/lighthouse-v3.3.0-x86_64-unknown-linux-gnu-portable.tar.gz | tar -C /usr/local/bin -xvf lighthouse-v3.3.0-x86_64-unknown-linux-gnu-portable.tar.gz
fi
apt install -y git gcc g++ make cmake pkg-config llvm-dev libclang-dev clang
curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
tee /etc/systemd/system/lighthouse.service > /dev/null <<EOF
[Unit]
Description=lighthouse service
[Service]
User=root
#WorkingDirectory=/home/erigon
ExecStart=/usr/local/bin/lighthouse beacon_node --datadir="/opt/lighthouse_eth" --network="mainnet" --execution-jwt="/var/lib/jwtsecret_eth/jwt.hex" --slasher --slasher-max-db-size="256"  --execution-endpoint="http://127.0.0.1:8551" --http --http-address="127.0.0.1" --http-allow-origin="*" --metrics --metrics-address="127.0.0.1" --metrics-allow-origin="*"  --subscribe-all-subnets --import-all-attestations --validator-monitor-auto
StandardOutput=journal
StandardError=journal
Restart=always
RestartSec=3
StartLimitInterval=0
TimeoutStopSec=3600
LimitNOFILE=65536
LimitNPROC=65536
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 /etc/systemd/system/lighthouse.service 
systemctl daemon-reload
systemctl enable lighthouse
systemctl start lighthouse
}
restorall() {
    systemctl stop erigon_eth.service
    systemctl stop lighthouse
    systemctl disable erigon_eth.service
    systemctl disable lighthouse
    rm /etc/systemd/system/erigon_eth.service
    rm /etc/systemd/system/lighthouse.service
    rm -rf /opt/erigon_eth
    rm -rf /opt/lighthouse_eth
    rm /usr/local/bin/lighthouse
}

[[ $1 == "-r" ]] && restorall && exit 1

makejwtsecret &> /dev/null
makeerigon &> /dev/null && echo -e "\e[1m\e[32m Erigon installed. \e[0m" || echo -e "\e[1m\e[31m Error install erigon. \e[0m"
makelighthouse &> /dev/null && echo -e "\e[1m\e[32m Lighthouse installed. \e[0m" || echo -e "\e[1m\e[31m Error install lighthouse. \e[0m"
echo "Check:"
echo "journalctl -u erigon_eth -f --no-hostname"
echo "journalctl -u lighthouse -f --no-hostname"
