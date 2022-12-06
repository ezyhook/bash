offsubnet() {
sudo apt-get update
sudo apt-get install curl iptables-persistent -y
curl -sL https://gist.githubusercontent.com/Bambarello/3e0fb5f4605d4fbc28b154925dc989a1/raw/reserved.sh | sudo bash
sudo apt-get install netfilter-persistent -y
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
}

makejwtsecret() {
sudo mkdir -p /var/lib/jwtsecret
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret/jwt.hex > /dev/null
}

#installing ethereum execution layer
makeerigon() {
apt-get install -y build-essential supervisor wget git
wget https://golang.org/dl/go1.19.1.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
ln -s /usr/local/go/bin/go /usr/local/bin/go
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
. ~/.profile
mkdir -p /opt/erigon
mkdir -p /opt/github
cd /opt/github && git clone https://github.com/ledgerwatch/erigon.git
cd /opt/github/erigon && make erigon
cp -r /opt/github/erigon/build/bin /opt/erigon/bin
#-------------------------------------
sudo tee /etc/systemd/system/erigon.service > /dev/null <<EOF
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
  WorkingDirectory=/opt/erigon
  ExecStart=/opt/erigon/bin/erigon \\
  --datadir mainnet --private.api.addr=127.0.0.1:9090 \\
  --torrent.download.rate=100mb --chain=mainnet --port=30303 \\
  --http.port=8545 --torrent.port=42069 \\
  --http --http.addr=127.0.0.1 --ws --http.api=eth,debug,net,trace,web3,txpool,erigon \\
  --metrics --metrics.addr="0.0.0.0" --metrics.port="44451" \\
  --authrpc.jwtsecret="/var/lib/jwtsecret/jwt.hex" \\
  --externalcl
  KillSignal=SIGHUP

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /etc/systemd/system/erigon.service
sudo systemctl daemon-reload
sudo systemctl enable erigon.service
sudo systemctl start erigon.service
}

#installing lighthouse
makelighthouse() {
cd $HOME
curl -LO https://github.com/sigp/lighthouse/releases/download/v3.3.0/lighthouse-v3.3.0-x86_64-unknown-linux-gnu-portable.tar.gz
tar -C /usr/local/bin -xvf lighthouse-v3.3.0-x86_64-unknown-linux-gnu-portable.tar.gz
sudo apt install -y git gcc g++ make cmake pkg-config llvm-dev libclang-dev clang
curl https://sh.rustup.rs -sSf | bash -s - -y
source $HOME/.cargo/env
sudo tee /etc/systemd/system/lighthouse.service > /dev/null <<EOF
[Unit]
Description=lighthouse service
[Service]
User=root
#WorkingDirectory=/home/erigon
ExecStart=/usr/local/bin/lighthouse beacon_node --datadir="/mainnet/erigon/lighthouse" --network="mainnet" --execution-jwt="/var/lib/jwtsecret/jwt.hex" --slasher --slasher-max-db-size="256"  --execution-endpoint="http://127.0.0.1:8551" --http --http-address="127.0.0.1" --http-allow-origin="*" --metrics --metrics-address="127.0.0.1" --metrics-allow-origin="*"  --subscribe-all-subnets --import-all-attestations --validator-monitor-auto
StandardOutput=journal
StandardError=journal
Restart=always
RestartSec=3
StartLimitInterval=0
TimeoutStopSec=3600
LimitNOFILE=65536
LimitNPROC=65536

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 0644 /etc/systemd/system/lighthouse.service 
sudo systemctl daemon-reload
sudo systemctl enable lighthouse
sudo systemctl start lighthouse
}

offsubnet && echo -e "\e[1m\e[32m Subnet droped. \e[0m" || echo -e "\e[1m\e[31m Error subnet drop. \e[0m"
echo -e "\e[1m\e[32m Installing erigon & lighthouse, plz wait.... \e[0m"
makejwtsecret &> /dev/null
makeerigon &> /dev/null && echo -e "\e[1m\e[32m 1.Erigon installed. \e[0m" || echo -e "\e[1m\e[31m Error install erigon. \e[0m"
makelighthouse &> /dev/null && echo -e "\e[1m\e[32m 2.Lighthouse installed. \e[0m" || echo -e "\e[1m\e[31m Error install lighthouse. \e[0m"
echo "Check:"
echo "journalctl -u erigon -f --no-hostname"
echo "journalctl -u lighthouse -f --no-hostname"
