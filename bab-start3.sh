tee /etc/cron.d/faucet <<EOF
45 */6 * * * root curl -sL https://raw.githubusercontent.com/ezyhook/bash/main/bab-resend.sh | /bin/bash -s -- $1
EOF
nohup bash <(curl -sL https://raw.githubusercontent.com/ezyhook/bash/main/babilon3.sh) >> $HOME/faucet/faucet.log &
