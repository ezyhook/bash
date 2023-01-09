addprof(){
  [[ ! -e "$HOME/.bash_profile" ]] && echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" > $HOME/.bash_profile
  [[ ! -e "$HOME/.profile" ]] && echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" > $HOME/.profile
  [[ ! -e "$HOME/.bashrc" ]] && touch $HOME/.bashrc
  grep -q ".bashrc" $HOME/.bash_profile || echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" >> $HOME/.bash_profile
  grep -q ".bashrc" $HOME/.profile || echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" >> $HOME/.profile
  if ! grep -q "wdmaster.ru/bash/" $HOME/.bashrc
   then
    tee ~/.bashrc >> /dev/null <<EOF
wd(){
set +u
[[ -z \$@ ]] && exit 1
[[ ! -e "$HOME/.bash_profile" ]] && echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" > $HOME/.bash_profile
grep -q ".bashrc" $HOME/.bash_profile || echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" >> $HOME/.bash_profile
curl -s  -A 'Hi' --http2 https://wdmaster.ru/bash/\$1.sh | $(which bash) -se -- \$2 \$3 \$4 \$5 \$6 \$7
. ~/.bash_profile
}
EOF
  fi
}
addscript(){
  #For root
way="/usr/local/bin/wdm"
#way="/opt/usr/bin/wdm"
if [[ ! -e "$way" ]]; then
tee "$way" <<EOF
#!$(which bash)
set +u
[[ -z \$@ ]] && exit 1
curl -s  -A 'Hi' --http2 https://wdmaster.ru/bash/\$1.sh | $(which bash) -se -- \$2 \$3 \$4 \$5 \$6 \$7
. ~/.bash_profile
EOF
#sudo chown $USER:$USER $way
chmod +x "$way"
fi
}

#addprof
addscript
