# !/bin/bash
# 27/01/2021
clear
clear
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )
SCPdir="/etc/VPS-AGN" && [[ ! -d ${SCPdir} ]] && exit 1
SCPusr="${SCPdir}/controller" && [[ ! -d ${SCPusr} ]] && mkdir ${SCPusr}
SCPfrm="${SCPdir}/tools" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
SCPinst="${SCPdir}/protocols" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
dnsnetflix () {
echo "nameserver $dnsp" > /etc/resolv.conf
#echo "nameserver 8.8.8.8" >> /etc/resolv.conf
/etc/init.d/ssrmu stop &>/dev/null
/etc/init.d/ssrmu start &>/dev/null
/etc/init.d/shadowsocks-r stop &>/dev/null
/etc/init.d/shadowsocks-r start &>/dev/null
msg -bar2
echo -e "${cor[4]}  DNS SUCCESSFULLY ADDED"
} 
clear
msg -bar2
msg -tit
echo -e "\033[1;93m     PERSONAL DNS AGGREGATE By @USA1_BOT "
msg -bar2
echo -e "\033[1;39m This function will allow you to watch Netflix with your VPS"
msg -bar2
echo -e "\033[1;91m ¡ They will only be useful if you registered your IP in the BOT!"
echo -e "\033[1;39m In APPS like HTTP Injector,KPN Rev,HTTP CUSTOM etc."
echo -e "\033[1;39m They must be added in the application to use these DNS."
echo -e "\033[1;39m In APPS like SS,SSR,V2RAY you don't need to add them."
msg -bar2
echo -e "\033[1;93m Remember to choose between 1 DNS either USA, BR, MX, CL \n according to the BOT given to you."
echo ""
echo -e "\033[1;97m Enter your DNS to use: \033[0;91m"; read -p "   "  dnsp
echo ""
msg -bar2
read -p " Are you sure to continue??  [ s | n ]: " dnsnetflix   
[[ "$dnsnetflix" = "s" || "$dnsnetflix" = "S" ]] && dnsnetflix
msg -bar2