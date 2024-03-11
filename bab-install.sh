wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin" >> $HOME/.bashrc
echo "export PATH=$PATH:/usr/local/go/bin" >> $HOME/.bash_profile
cd "$HOME"
git clone https://github.com/babylonchain/babylon.git
cd babylon
git checkout v0.8.3
make install
~/go/bin/babylond init NODENAME --chain-id bbn-test-3
~/go/bin/babylond config set client chain-id bbn-test-3
~/go/bin/babylond config set client keyring-backend test
