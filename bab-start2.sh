tee /etc/cron.d/faucet <<EOF
*/1 * * * * root curl -sL https://raw.githubusercontent.com/ezyhook/bash/main/babilon2.sh | /bin/bash -s -- >> $HOME/faucet/faucet.log
45 */6 * * * root curl -sL https://raw.githubusercontent.com/ezyhook/bash/main/bab-resend.sh | /bin/bash -s -- $1
EOF
