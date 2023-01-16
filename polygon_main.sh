makejwtsecret() {
sudo mkdir -p /var/lib/jwtsecret_polygon
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret_polygon/jwt.hex > /dev/null
}

#installing ethereum execution layer
makeerigon() {
apt-get install -y build-essential supervisor wget git

if (! command -V go &> /dev/null); then
wget https://golang.org/dl/go1.19.1.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
rm go1.19.1.linux-amd64.tar.gz
ln -s /usr/local/go/bin/go /usr/local/bin/go
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
. ~/.profile
fi
mkdir -p /opt/erigon_polygon/github
mkdir -p /opt/erigon_polygon/polygon
mkdir -p /opt/erigon_polygon/bin
#wget https://github.com/ledgerwatch/erigon/releases/download/v2.30.0/erigon_2.30.0_linux_amd64.tar.gz -O - | tar xzf - -C /opt/erigon_polygon/bin
#chmod +x /opt/erigon_polygon/bin/erigon
#rm erigon_2.30.0_linux_amd64.tar.gz

cd /opt/erigon_polygon/github && git clone https://github.com/maticnetwork/erigon.git
cd /opt/erigon_polygon/github/erigon && make erigon
cp -r /opt/erigon_polygon/github/erigon/build/bin /opt/erigon_polygon/bin
chmod +x /opt/erigon_polygon/bin/erigon
#-------------------------------------

if [[ ! -f "/etc/systemd/system/erigon_polygon.service" ]]; then
sudo tee /etc/systemd/system/erigon_polygon.service > /dev/null <<EOF
[Unit]
Description="Polygon Erigon service"
After=network.target
[Service]
Type=simple
Restart=always
RestartSec=3
TimeoutStopSec=600
User=root
LimitNOFILE=200000
WorkingDirectory=/opt/erigon_polygon
ExecStart=/opt/erigon_polygon/bin/erigon \\
--chain=bor-mainnet \\
--bor.heimdall="https://heimdall.api.matic.network" \\
--datadir="/opt/erigon_polygon/polygon" \\
--private.api.addr="127.0.0.1:49090" \\
--port=40303 \\
--authrpc.port=48551 \\
--torrent.port=42069 \\
--torrent.upload.rate="512mb" \\
--torrent.download.rate="512mb" \\
--http.corsdomain="*" \\
--http.vhosts="*" \\
--http.port=48545 \\
--http.api="eth,debug,net,trace,web3,erigon,bor" \\
--http.addr=0.0.0.0 \\
--snapshots true \\
--authrpc.jwtsecret="/var/lib/jwtsecret_polygon/jwt.hex"
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /etc/systemd/system/erigon_polygon.service
sudo systemctl daemon-reload
sudo systemctl enable erigon_polygon.service
sudo systemctl start erigon_polygon.service
fi
}

restorall() {
    systemctl stop erigon_polygon.service
    systemctl disable erigon_polygon.service
    rm /etc/systemd/system/erigon_polygon.service
    rm -rf /opt/erigon_polygon
}

[[ $1 == "-r" ]] && restorall && exit 1

[[ -f "/var/lib/jwtsecret_polygon/jwt.hex" ]] ||  makejwtsecret
makeerigon && echo -e "\e[1m\e[32m Erigon installed. \e[0m" || echo -e "\e[1m\e[31m Error install erigon. \e[0m"
echo "Check:"
echo "sudo systemctl status erigon_polygon"
echo "journalctl -u erigon_polygon -f"
