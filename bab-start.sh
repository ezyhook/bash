tee /etc/cron.d/faucet <<EOF
* */6 * * * root date >> $HOME/faucet/faucet.log;curl -sL https://raw.githubusercontent.com/ezyhook/bash/main/babilon.sh | /bin/bash -s -- $1 >> $HOME/faucet/faucet.log
45 */3 * * * root curl -sL https://raw.githubusercontent.com/ezyhook/bash/main/bab-resend.sh | /bin/bash -s -- $1
EOF
