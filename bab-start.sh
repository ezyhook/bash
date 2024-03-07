tee /etc/cron.d/faucet <<EOF
* */1 * * * root date >> $HOME/faucet/faucet.log;curl -sL https://raw.githubusercontent.com/ezyhook/bash/main/babilon.sh | /bin/bash -s -- >> $HOME/faucet/faucet.log
EOF
