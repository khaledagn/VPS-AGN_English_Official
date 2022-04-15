#!/bin/bash
#25/01/2021
clear
clear
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )
SCPdir="/etc/VPS-AGN"
SCPfrm="${SCPdir}/herramientas" && [[ ! -d ${SCPfrm} ]] && exit
SCPinst="${SCPdir}/protocolos"&& [[ ! -d ${SCPinst} ]] && exit
mportas () {
unset portas
portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
while read port; do
var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
[[ "$(echo -e $portas|grep "$var1 $var2")" ]] || portas+="$var1 $var2\n"
done <<< "$portas_var"
i=1
echo -e "$portas"
}
fun_ip () {
MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MEU_IP" != "$MEU_IP2" ]] && IP="$MEU_IP2" || IP="$MEU_IP"
}
fun_eth () {
eth=$(ifconfig | grep -v inet6 | grep -v lo | grep -v 127.0.0.1 | grep "encap:Ethernet" | awk '{print $1}')
    [[ $eth != "" ]] && {
    msg -bar
    echo -e "${cor[3]} $(fun_trans ${id} "Apply System To Enhance SSH Packets?")"
    echo -e "${cor[3]} $(fun_trans ${id} "Option For Advanced Users")"
    msg -bar
    read -p " [S/N]: " -e -i n sshsn
           [[ "$sshsn" = @(s|S|y|Y) ]] && {
           echo -e "${cor[1]} $(fun_trans ${id} "Fix packet problems in SSH...")"
           echo -e " $(fun_trans ${id} "What is the RX Rate")"
           echo -ne "[ 1 - 999999999 ]: "; read rx
           [[ "$rx" = "" ]] && rx="999999999"
           echo -e " $(fun_trans ${id} "What is the TX Rate")"
           echo -ne "[ 1 - 999999999 ]: "; read tx
           [[ "$tx" = "" ]] && tx="999999999"
           apt-get install ethtool -y > /dev/null 2>&1
           ethtool -G $eth rx $rx tx $tx > /dev/null 2>&1
           }
     msg -bar
     }
}
fun_bar () {
comando="$1"
 _=$(
$comando > /dev/null 2>&1
) & > /dev/null
pid=$!
while [[ -d /proc/$pid ]]; do
echo -ne " \033[1;33m["
   for((i=0; i<10; i++)); do
   echo -ne "\033[1;31m##"
   sleep 0.2
   done
echo -ne "\033[1;33m]"
sleep 1s
echo
tput cuu1
tput dl1
done
echo -e " \033[1;33m[\033[1;31m####################\033[1;33m] - \033[1;32m100%\033[0m"
sleep 1s
}
fun_shadowsocks () {
[[ -e /etc/shadowsocks-r/config.json ]] && {
[[ $(ps ax|grep /etc/shadowsocks-r|grep -v grep|awk '{print $1}') != "" ]] && kill -9 $(ps ax|grep /etc/shadowsocks-r|grep -v grep|awk '{print $1}') > /dev/null 2>&1 && ss-server -c /etc/shadowsocks-r/config.json -d stop > /dev/null 2>&1
echo -e "\033[1;33m $(fun_trans ${id} "SHADOWSOCKS R STOPPED")"
msg -bar
rm -rf /etc/shadowsocks-r/config.json
return 0
}
msg -bar
msg -tit
echo -e "${cor[3]}    SHADOWSOCK-R + (obfs)INSTALLER By @KhaledAGN"
msg -bar
echo -e "${cor[1]} Choose the desired option."
msg -bar
echo "1).- INSTALL SHADOWSOCK-R"
echo "2).- UNINSTALL SHADOWSOCK-R"
msg -bar
echo -n "Enter only the number according to your answer: "
read opcao
case $opcao in
1)
msg -bar
wget --no-check-certificate -O Instalador-Shadowsocks-R.sh https://raw.githubusercontent.com/khaledagn/VPS-AGN_English_Official/master/LINKS-LIBRARIES/Instalador-Shadowsocks-R.sh > /dev/null 2>&1
chmod +x Instalador-Shadowsocks-R.sh
./Instalador-Shadowsocks-R.sh 2>&1 

;;
2)
msg -bar
echo -e "\033[1;93m  Uninstall  ..."
msg -bar
wget --no-check-certificate -O Instalador-Shadowsocks-R.sh https://raw.githubusercontent.com/khaledagn/VPS-AGN_English_Official/master/LINKS-LIBRARIES/Instalador-Shadowsocks-R.sh > /dev/null 2>&1
chmod +x Instalador-Shadowsocks-R.sh
./Instalador-Shadowsocks-R.sh uninstall
rm -rf Instalador-Shadowsocks-R.sh
msg -bar
sleep 3
exit
;;
esac
value=$(ps ax |grep /etc/shadowsocks-r|grep -v grep)
[[ $value != "" ]] && value="\033[1;32mSTARTED SUCCESSFULLY" || value="\033[1;31mERROR"
msg -bar
echo -e "${value}"
msg -bar
return 0
}
fun_shadowsocks
rm -rf Instalador-Shadowsocks-R.sh