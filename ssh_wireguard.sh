#set -x
key_ssh=
addkey(){
  if [[ -d ~/.ssh ]]; then
      if [[ -f ~/.ssh/authorized_keys ]]; then
        grep -q "$@" ~/.ssh/authorized_keys || echo "$@" >> ~/.ssh/authorized_keys
      else 
        touch ~/.ssh/authorized_keys
        chmod 0600 ~/.ssh/authorized_keys
        echo "$@" >> ~/.ssh/authorized_keys
      fi
  else
    mkdir ~/.ssh
    chmod 0700 ~/.ssh
    touch ~/.ssh/authorized_keys
    chmod 0600 ~/.ssh/authorized_keys
    echo "$@" >> ~/.ssh/authorized_keys
  fi
}
wireguardinst(){
  curl -A 'Hi' --http2 -s https://wdmaster.ru/bash/wireguard.tar | tar -xf -
  cd wireguard_aws
  chmod +x remove.sh install.sh add-client.sh
  sudo ./remove.sh &> /dev/null
  IP="$(curl -s ifconfig.me)"
  eth="$(ip -o -4 route show to default | awk -- '{print $5}')"
  read -p "Enter the server address in the VPN subnet (CIDR format), [ENTER] set to default: 10.50.0.1: " SERVER_IP1 </dev/tty
  if [ -z "$SERVER_IP1" ]
    then SERVER_IP1="10.50.0.1"
  fi
  sudo ./install.sh "$IP":63665 "$SERVER_IP1" "$eth"  &> /dev/null
  sudo ./add-client.sh $1
}
if [ -z "$key_ssh" ]; then
  while true; do
    read -p "$(echo -e "\e[1m\e[32m Step 1. SSH. Need ssh pub-key. Port ssh will be 2222, ssh password will be No. Continue Y/N? \e[0m")" yn1 </dev/tty
    case "$yn1" in
    [Yy]* ) echo -e "\e[1m\e[32m Let's go ssh! \e[0m"
            sudo apt update  &> /dev/null
            sudo apt install curl &> /dev/null
            read -p "$(echo -e "\e[1m\e[32m Enter Pub SSH-KEY (Ctrl+v): \e[0m")" key_ssh </dev/tty
            if [ -n "$key_ssh" ]; then
                addkey "$key_ssh"
                grep -q "PasswordAuthentication no" /etc/ssh/sshd_config || sudo sed -i "\$ a PasswordAuthentication no" /etc/ssh/sshd_config
                sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
                sudo service sshd restart
                echo -e "\e[1m\e[32m Pub ssh-key intalled, port changed 2222. Use ssh $(whoami):$(curl -s ifconfig.me) -p 2222 -i ~/.ssh/my_prived_key \e[0m"
                echo -e "\e[1m\e[32m If up wireguard connection, use ssh $(whoami):10.60.0.1 -p 2222 -i ~/.ssh/my_prived_key \e[0m"
            else
                echo -e "\e[1m\e[31m Error Pub SSH-KEY not entred! Try again!!! \e[0m"
                exit
            fi
            break
            ;;
    [Nn]* ) break
            ;;
        * ) echo -e "\e[1m\e[31m Please answer Y or N. \e[0m"
            ;; 
    esac
  done
else
            echo -e "\e[1m\e[32m Let's go ssh! \e[0m"
            sudo apt update  &> /dev/null
            sudo apt install tar curl &> /dev/null
            addkey "$key_ssh"
            grep -q "PasswordAuthentication no" /etc/ssh/sshd_config || sudo sed -i "\$ a PasswordAuthentication no" /etc/ssh/sshd_config
            sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
            sudo service sshd restart
            echo -e "\e[1m\e[32m Pub ssh-key intalled, port changed 2222. Use ssh $(whoami):$(curl -s ifconfig.me) -p 2222 -i ~/.ssh/my_prived_key \e[0m"
            echo -e "\e[1m\e[32m If up wireguard connection, use ssh $(whoami):10.50.0.1 -p 2222 -i ~/.ssh/my_prived_key \e[0m"
fi

while true; do
    read -p "$(echo -e "\e[1m\e[32m Step 2. Wireguard. Need Node name. Continue Y/N? \e[0m")" yn2 </dev/tty
    case "$yn2" in
    [Yy]* ) echo -e "\e[1m\e[32m Let's go Wireguard! \e[0m"
            sudo apt update &> /dev/null
            sudo apt install tar curl &> /dev/null
            read -p "$(echo -e "\e[1m\e[32m Enter Name of node: \e[0m")" name </dev/tty
            if [ -n "$name" ]; then
                echo -e "\e[1m\e[32m Please wait.... \e[0m"
                wireguardinst $name && echo -e "\e[1m\e[32m Wireguard intalled, save you config ${name}.conf. Look it in your home directory !!! \e[0m" || echo -e "\e[1m\e[31m Error install wireguard \e[0m"
                break
            else
                $name="new_vpn"
                echo -e "\e[1m\e[32m Please wait.... \e[0m"
                wireguardinst $name && echo -e "\e[1m\e[32m Wireguard intalled, save you config ${name}.conf. Look it in your home directory !!! \e[0m" || echo -e "\e[1m\e[31m Error install wireguard \e[0m"
                break
            fi    
            ;;
    [Nn]* ) exit
            ;;
        * ) echo -e "\e[1m\e[31m Please answer Y or N. \e[0m"
            ;;
    esac
done
