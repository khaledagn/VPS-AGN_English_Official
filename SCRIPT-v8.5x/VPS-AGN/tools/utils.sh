#!/bin/bash
#27/01/2021
clear
clear
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )
SCPdir="/etc/VPS-AGN" && [[ ! -d ${SCPdir} ]] && exit 1
SCPusr="${SCPdir}/controller" && [[ ! -d ${SCPusr} ]] && mkdir ${SCPusr}
SCPfrm="${SCPdir}/tools" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
SCPinst="${SCPdir}/protocols" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
RAM () {
sudo sync
sudo sysctl -w vm.drop_caches=3 > /dev/null 2>&1
msg -ama "   Ram Cleaned Successfully!"
}
TCPspeed () {
if [[ `grep -c "^#ADM" /etc/sysctl.conf` -eq 0 ]]; then
#INSTALA
msg -ama "$(fun_trans "TCP Speed ​​Not Activated, Want to Activate Now")?"
msg -bar
while [[ ${resposta} != @(s|S|n|N|y|Y) ]]; do
read -p " [Y/N]: " -e -i s resposta
tput cuu1 && tput dl1
done
[[ "$resposta" = @(s|S|y|Y) ]] && {
echo "#ADM" >> /etc/sysctl.conf
echo "net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_slow_start_after_idle = 0" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf > /dev/null 2>&1
msg -ama "$(fun_trans "TCP Active with success")!"
} || msg -ama "$(fun_trans "Cancelled")!"
 else
#REMOVE
msg -ama "$(fun_trans "TCP Speed ​​is already activated, you want to stop now")?"
msg -bar
while [[ ${resposta} != @(s|S|n|N|y|Y) ]]; do
read -p " [Y/N]: " -e -i s resposta
tput cuu1 && tput dl1
done
[[ "$resposta" = @(s|S|y|Y) ]] && {
grep -v "^#ADM
net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_slow_start_after_idle = 0" /etc/sysctl.conf > /tmp/syscl && mv -f /tmp/syscl /etc/sysctl.conf
sysctl -p /etc/sysctl.conf > /dev/null 2>&1
msg -ama "$(fun_trans "TCP Stopped Successfully")!"
} || msg -ama "$(fun_trans "Cancelled")!"
fi
}
SquidCACHE () {
msg -ama "$(fun_trans "Squid Cache, Apply cache in Squid")"
msg -ama "$(fun_trans "Improves squid speed")"
msg -bar
if [ -e /etc/squid/squid.conf ]; then
squid_var="/etc/squid/squid.conf"
elif [ -e /etc/squid3/squid.conf ]; then
squid_var="/etc/squid3/squid.conf"
else
msg -ama "$(fun_trans "Your system does not have a squid")!" && return 1
fi
teste_cache="#CACHE DO SQUID"
if [[ `grep -c "^$teste_cache" $squid_var` -gt 0 ]]; then
  [[ -e ${squid_var}.bakk ]] && {
  msg -ama "$(fun_trans "Cache squid identified, deleting")!"
  mv -f ${squid_var}.bakk $squid_var
  msg -ama "$(fun_trans "Cache squid Removed")!"
  service squid restart > /dev/null 2>&1 &
  service squid3 restart > /dev/null 2>&1 &
  return 0
  }
fi
msg -ama "$(fun_trans "Applying Cache Squid")!"
msg -bar
_tmp="#CACHE DO SQUID\ncache_mem 200 MB\nmaximum_object_size_in_memory 32 KB\nmaximum_object_size 1024 MB\nminimum_object_size 0 KB\ncache_swap_low 90\ncache_swap_high 95"
[[ "$squid_var" = "/etc/squid/squid.conf" ]] && _tmp+="\ncache_dir ufs /var/spool/squid 100 16 256\naccess_log /var/log/squid/access.log squid" || _tmp+="\ncache_dir ufs /var/spool/squid3 100 16 256\naccess_log /var/log/squid3/access.log squid"
while read s_squid; do
[[ "$s_squid" != "cache deny all" ]] && _tmp+="\n${s_squid}"
done < $squid_var
cp ${squid_var} ${squid_var}.bakk
echo -e "${_tmp}" > $squid_var
msg -ama "$(fun_trans "Cache Applied Successfully")!"
service squid restart > /dev/null 2>&1 &
service squid3 restart > /dev/null 2>&1 &
}
timemx () {
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/America/Merida /etc/localtime
echo -e " $(fun_trans "LOCAL MX DATE APPLIED!")"
}
resetiptables () {
echo -e "Restarting Ipetables please wait"
iptables -F && iptables -X && iptables -t nat -F && iptables -t nat -X && iptables -t mangle -F && iptables -t mangle -X && iptables -t raw -F && iptables -t raw -X && iptables -t security -F && iptables -t security -X && iptables -P INPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables -P OUTPUT ACCEPT
echo -e "iptables restarted successfully"
}
packobs () {
msg -ama "Finding Outdated Packages"
dpkg -l | grep -i ^rc
msg -ama "Cleaning Obsolete Packages"
dpkg -l |grep -i ^rc | cut -d " " -f 3 | xargs dpkg --purge
msg -ama "Wipe Completed"
}


on="\033[1;32m[ON]" && off="\033[1;31m[OFF]"
[[ $(ps x | grep badvpn | grep -v grep | awk '{print $1}') ]] && badvpn=$on || badvpn=$off
[[ `grep -c "^#ADM" /etc/sysctl.conf` -eq 0 ]] && tcp=$off || tcp=$on
if [ -e /etc/squid/squid.conf ]; then
[[ `grep -c "^#CACHE DO SQUID" /etc/squid/squid.conf` -gt 0 ]] && squid=$on || squid=$off
elif [ -e /etc/squid3/squid.conf ]; then
[[ `grep -c "^#CACHE DO SQUID" /etc/squid3/squid.conf` -gt 0 ]] && squid=$on || squid=$off
fi
msg -bar
msg -tit
msg -ama "                BASIC OPTIMIZERS "
msg -bar
echo -ne "\033[1;32m [1] > " && msg -azu "TCP-SPEED $tcp"
echo -ne "\033[1;32m [2] > " && msg -azu "CACHE FOR SQUID $squid"
echo -ne "\033[1;32m [3] > " && msg -azu "REFRESH RAM"
echo -ne "\033[1;32m [4] > " && msg -azu "CLEAN OUT-OBSOLETE PACKAGES"
echo -ne "\033[1;32m [5] > " && msg -azu "$(fun_trans "RESET IPTABLES")"
echo -ne "$(msg -bar)\n\033[1;32m [0] > " && msg -bra "\e[97m\033[1;41m RETURN \033[1;37m"
msg -bar
while [[ ${arquivoonlineadm} != @(0|[1-5]) ]]; do
read -p "[0-5]: " arquivoonlineadm
tput cuu1 && tput dl1
done
case $arquivoonlineadm in
1)TCPspeed;;
2)SquidCACHE;;
3)RAM;;
4)packobs;;
5)resetiptables;;
0)exit;;
esac
msg -bar