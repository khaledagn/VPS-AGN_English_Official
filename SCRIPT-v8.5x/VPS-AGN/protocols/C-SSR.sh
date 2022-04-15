#!/bin/bash
#25/01/2021
clear
clear
msg -bar
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
SCPfrm="/etc/ger-frm" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
BARRA1="\e[0;31m--------------------------------------------------------------------\e[0m"
SCPinst="/etc/ger-inst" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
sh_ver="1.0.26"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
ssr_folder="/usr/local/shadowsocksr"
config_file="${ssr_folder}/config.json"
config_user_file="${ssr_folder}/user-config.json"
config_user_api_file="${ssr_folder}/userapiconfig.py"
config_user_mudb_file="${ssr_folder}/mudb.json"
ssr_log_file="${ssr_folder}/ssserver.log"
Libsodiumr_file="/usr/local/lib/libsodium.so"
Libsodiumr_ver_backup="1.0.16"
Server_Speeder_file="/serverspeeder/bin/serverSpeeder.sh"
LotServer_file="/appex/bin/serverSpeeder.sh"
BBR_file="${file}/bbr.sh"
jq_file="${ssr_folder}/jq"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[ INFORMATION ]${Font_color_suffix}"
Error="${Red_font_prefix}[# ERROR #]${Font_color_suffix}"
Tip="${Green_font_prefix}[ NOTE ]${Font_color_suffix}"
Separator_1="——————————————————————————————"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} The current account is not ROOT (does not have ROOT permission), cannot continue the operation, please ${Green_background_prefix} sudo su ${Font_color_suffix} come to ROOT (I will ask you to enter the password of the current account after execution)" && exit 1
}
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_pid(){
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
}
check_crontab(){
	[[ ! -e "/usr/bin/crontab" ]] && echo -e "${Error}Crontab dependency missing, Please try to install manually CentOS: yum install crond -y , Debian/Ubuntu: apt-get install cron -y !" && exit 1
}
SSR_installation_status(){
	[[ ! -e ${ssr_folder} ]] && echo -e "${Error}\nShadowsocksR Folder not found, please check\n$(msg -bar)" && exit 1
}
Server_Speeder_installation_status(){
	[[ ! -e ${Server_Speeder_file} ]] && echo -e "${Error}Not installed (Server Speeder), Please check!" && exit 1
}
LotServer_installation_status(){
	[[ ! -e ${LotServer_file} ]] && echo -e "${Error}LotServer not installed, please check!" && exit 1
}
BBR_installation_status(){
	if [[ ! -e ${BBR_file} ]]; then
		echo -e "${Error} I did not find the BBR script, start downloading ..."
		cd "${file}"
		if ! wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/bbr.sh; then
			echo -e "${Error}bbr script download!" && exit 1
		else
			echo -e "${Info} BBR script download completed!"
			chmod +x bbr.sh
		fi
	fi
}
#Establecer reglas de firewall
Add_iptables(){
	if [[ ! -z "${ssr_port}" ]]; then
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ssr_port} -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ssr_port} -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ssr_port} -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport ${ssr_port} -j ACCEPT
	fi
}
Del_iptables(){
	if [[ ! -z "${port}" ]]; then
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
		iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	fi
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
	else
		iptables-save > /etc/iptables.up.rules
		ip6tables-save > /etc/ip6tables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
		chkconfig --level 2345 iptables on
		chkconfig --level 2345 ip6tables on
	else
		iptables-save > /etc/iptables.up.rules
		ip6tables-save > /etc/ip6tables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules\n/sbin/ip6tables-restore < /etc/ip6tables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
#Leer la informaci�n de configuraci�n
Get_IP(){
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP"
			fi
		fi
	fi
}
Get_User_info(){
	Get_user_port=$1
	user_info_get=$(python mujson_mgr.py -l -p "${Get_user_port}")
	match_info=$(echo "${user_info_get}"|grep -w "### user ")
	if [[ -z "${match_info}" ]]; then
		echo -e "${Error}The acquisition of user information failed ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	fi
	user_name=$(echo "${user_info_get}"|grep -w "user :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	port=$(echo "${user_info_get}"|grep -w "port :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	password=$(echo "${user_info_get}"|grep -w "passwd :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	method=$(echo "${user_info_get}"|grep -w "method :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	protocol=$(echo "${user_info_get}"|grep -w "protocol :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	protocol_param=$(echo "${user_info_get}"|grep -w "protocol_param :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	[[ -z ${protocol_param} ]] && protocol_param="0(Unlimited)"
msg -bar
	obfs=$(echo "${user_info_get}"|grep -w "obfs :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	#transfer_enable=$(echo "${user_info_get}"|grep -w "transfer_enable :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}'|awk -F "ytes" '{print $1}'|sed 's/KB/ KB/;s/MB/ MB/;s/GB/ GB/;s/TB/ TB/;s/PB/ PB/')
	#u=$(echo "${user_info_get}"|grep -w "u :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
	#d=$(echo "${user_info_get}"|grep -w "d :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
	forbidden_port=$(echo "${user_info_get}"|grep -w "Puerto prohibido :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
	[[ -z ${forbidden_port} ]] && forbidden_port="allow all"
msg -bar
	speed_limit_per_con=$(echo "${user_info_get}"|grep -w "speed_limit_per_con :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	speed_limit_per_user=$(echo "${user_info_get}"|grep -w "speed_limit_per_user :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	Get_User_transfer "${port}"
}
Get_User_transfer(){
	transfer_port=$1
	#echo "transfer_port=${transfer_port}"
	all_port=$(${jq_file} '.[]|.port' ${config_user_mudb_file})
	#echo "all_port=${all_port}"
	port_num=$(echo "${all_port}"|grep -nw "${transfer_port}"|awk -F ":" '{print $1}')
	#echo "port_num=${port_num}"
	port_num_1=$(expr ${port_num} - 1)
	#echo "port_num_1=${port_num_1}"
	transfer_enable_1=$(${jq_file} ".[${port_num_1}].transfer_enable" ${config_user_mudb_file})
	#echo "transfer_enable_1=${transfer_enable_1}"
	u_1=$(${jq_file} ".[${port_num_1}].u" ${config_user_mudb_file})
	#echo "u_1=${u_1}"
	d_1=$(${jq_file} ".[${port_num_1}].d" ${config_user_mudb_file})
	#echo "d_1=${d_1}"
	transfer_enable_Used_2_1=$(expr ${u_1} + ${d_1})
	#echo "transfer_enable_Used_2_1=${transfer_enable_Used_2_1}"
	transfer_enable_Used_1=$(expr ${transfer_enable_1} - ${transfer_enable_Used_2_1})
	#echo "transfer_enable_Used_1=${transfer_enable_Used_1}"
	
	
	if [[ ${transfer_enable_1} -lt 1024 ]]; then
		transfer_enable="${transfer_enable_1} B"
	elif [[ ${transfer_enable_1} -lt 1048576 ]]; then
		transfer_enable=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_1}'/'1024'}')
		transfer_enable="${transfer_enable} KB"
	elif [[ ${transfer_enable_1} -lt 1073741824 ]]; then
		transfer_enable=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_1}'/'1048576'}')
		transfer_enable="${transfer_enable} MB"
	elif [[ ${transfer_enable_1} -lt 1099511627776 ]]; then
		transfer_enable=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_1}'/'1073741824'}')
		transfer_enable="${transfer_enable} GB"
	elif [[ ${transfer_enable_1} -lt 1125899906842624 ]]; then
		transfer_enable=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_1}'/'1099511627776'}')
		transfer_enable="${transfer_enable} TB"
	fi
	#echo "transfer_enable=${transfer_enable}"
	if [[ ${u_1} -lt 1024 ]]; then
		u="${u_1} B"
	elif [[ ${u_1} -lt 1048576 ]]; then
		u=$(awk 'BEGIN{printf "%.2f\n",'${u_1}'/'1024'}')
		u="${u} KB"
	elif [[ ${u_1} -lt 1073741824 ]]; then
		u=$(awk 'BEGIN{printf "%.2f\n",'${u_1}'/'1048576'}')
		u="${u} MB"
	elif [[ ${u_1} -lt 1099511627776 ]]; then
		u=$(awk 'BEGIN{printf "%.2f\n",'${u_1}'/'1073741824'}')
		u="${u} GB"
	elif [[ ${u_1} -lt 1125899906842624 ]]; then
		u=$(awk 'BEGIN{printf "%.2f\n",'${u_1}'/'1099511627776'}')
		u="${u} TB"
	fi
	#echo "u=${u}"
	if [[ ${d_1} -lt 1024 ]]; then
		d="${d_1} B"
	elif [[ ${d_1} -lt 1048576 ]]; then
		d=$(awk 'BEGIN{printf "%.2f\n",'${d_1}'/'1024'}')
		d="${d} KB"
	elif [[ ${d_1} -lt 1073741824 ]]; then
		d=$(awk 'BEGIN{printf "%.2f\n",'${d_1}'/'1048576'}')
		d="${d} MB"
	elif [[ ${d_1} -lt 1099511627776 ]]; then
		d=$(awk 'BEGIN{printf "%.2f\n",'${d_1}'/'1073741824'}')
		d="${d} GB"
	elif [[ ${d_1} -lt 1125899906842624 ]]; then
		d=$(awk 'BEGIN{printf "%.2f\n",'${d_1}'/'1099511627776'}')
		d="${d} TB"
	fi
	#echo "d=${d}"
	if [[ ${transfer_enable_Used_1} -lt 1024 ]]; then
		transfer_enable_Used="${transfer_enable_Used_1} B"
	elif [[ ${transfer_enable_Used_1} -lt 1048576 ]]; then
		transfer_enable_Used=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_1}'/'1024'}')
		transfer_enable_Used="${transfer_enable_Used} KB"
	elif [[ ${transfer_enable_Used_1} -lt 1073741824 ]]; then
		transfer_enable_Used=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_1}'/'1048576'}')
		transfer_enable_Used="${transfer_enable_Used} MB"
	elif [[ ${transfer_enable_Used_1} -lt 1099511627776 ]]; then
		transfer_enable_Used=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_1}'/'1073741824'}')
		transfer_enable_Used="${transfer_enable_Used} GB"
	elif [[ ${transfer_enable_Used_1} -lt 1125899906842624 ]]; then
		transfer_enable_Used=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_1}'/'1099511627776'}')
		transfer_enable_Used="${transfer_enable_Used} TB"
	fi
	#echo "transfer_enable_Used=${transfer_enable_Used}"
	if [[ ${transfer_enable_Used_2_1} -lt 1024 ]]; then
		transfer_enable_Used_2="${transfer_enable_Used_2_1} B"
	elif [[ ${transfer_enable_Used_2_1} -lt 1048576 ]]; then
		transfer_enable_Used_2=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_2_1}'/'1024'}')
		transfer_enable_Used_2="${transfer_enable_Used_2} KB"
	elif [[ ${transfer_enable_Used_2_1} -lt 1073741824 ]]; then
		transfer_enable_Used_2=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_2_1}'/'1048576'}')
		transfer_enable_Used_2="${transfer_enable_Used_2} MB"
	elif [[ ${transfer_enable_Used_2_1} -lt 1099511627776 ]]; then
		transfer_enable_Used_2=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_2_1}'/'1073741824'}')
		transfer_enable_Used_2="${transfer_enable_Used_2} GB"
	elif [[ ${transfer_enable_Used_2_1} -lt 1125899906842624 ]]; then
		transfer_enable_Used_2=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_2_1}'/'1099511627776'}')
		transfer_enable_Used_2="${transfer_enable_Used_2} TB"
	fi
	#echo "transfer_enable_Used_2=${transfer_enable_Used_2}"
}
urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}
ss_link_qr(){
	SSbase64=$(urlsafe_base64 "${method}:${password}@${ip}:${port}")
	SSurl="ss://${SSbase64}"
	SSQRcode="http://www.codigos-qr.com/qr/php/qr_img.php?d=${SSurl}"
	ss_link=" SS    Link :\n ${Green_font_prefix}${SSurl}${Font_color_suffix} \n SS QR code:\n ${Green_font_prefix}${SSQRcode}${Font_color_suffix}"
}
ssr_link_qr(){
	SSRprotocol=$(echo ${protocol} | sed 's/_compatible//g')
	SSRobfs=$(echo ${obfs} | sed 's/_compatible//g')
	SSRPWDbase64=$(urlsafe_base64 "${password}")
	SSRbase64=$(urlsafe_base64 "${ip}:${port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}")
	SSRurl="ssr://${SSRbase64}"
	SSRQRcode="http://www.codigos-qr.com/qr/php/qr_img.php?d=${SSRurl}"
	ssr_link=" SSR   Link :\n ${Red_font_prefix}${SSRurl}${Font_color_suffix} \n SSR QR code:\n ${Red_font_prefix}${SSRQRcode}${Font_color_suffix}"
}
ss_ssr_determine(){
	protocol_suffix=`echo ${protocol} | awk -F "_" '{print $NF}'`
	obfs_suffix=`echo ${obfs} | awk -F "_" '{print $NF}'`
	if [[ ${protocol} = "origin" ]]; then
		if [[ ${obfs} = "plain" ]]; then
			ss_link_qr
			ssr_link=""
		else
			if [[ ${obfs_suffix} != "compatible" ]]; then
				ss_link=""
			else
				ss_link_qr
			fi
		fi
	else
		if [[ ${protocol_suffix} != "compatible" ]]; then
			ss_link=""
		else
			if [[ ${obfs_suffix} != "compatible" ]]; then
				if [[ ${obfs_suffix} = "plain" ]]; then
					ss_link_qr
				else
					ss_link=""
				fi
			else
				ss_link_qr
			fi
		fi
	fi
	ssr_link_qr
}
# Display configuration information
View_User(){
clear
	SSR_installation_status
	List_port_user
	while true
	do
		echo -e "Enter user port to view full account\ninformation"
msg -bar
		stty erase '^H' && read -p "(Default: cancel):" View_user_port
		[[ -z "${View_user_port}" ]] && echo -e "Cancelled ...\n$(msg -bar)" && exit 1
		View_user=$(cat "${config_user_mudb_file}"|grep '"port": '"${View_user_port}"',')
		if [[ ! -z ${View_user} ]]; then
			Get_User_info "${View_user_port}"
			View_User_info
			break
		else
			echo -e "${Error} Please enter the correct port!"
		fi
	done
#read -p "Enter to continue" enter
}
View_User_info(){
	ip=$(cat ${config_user_api_file}|grep "SERVER_PUB_ADDR = "|awk -F "[']" '{print $2}')
	[[ -z "${ip}" ]] && Get_IP
	ss_ssr_determine
	clear 
	echo -e " User [{user_name}] Account info:"
msg -bar
    echo -e " PANEL VPS-AGN By @KhaledAGN"
	
	echo -e " IP : ${Green_font_prefix}${ip}${Font_color_suffix}"

	echo -e " Port : ${Green_font_prefix}${port}${Font_color_suffix}"

	echo -e " Password : ${Green_font_prefix}${password}${Font_color_suffix}"

	echo -e " Encryption : ${Green_font_prefix}${method}${Font_color_suffix}"

	echo -e " Protocol : ${Red_font_prefix}${protocol}${Font_color_suffix}"

	echo -e " Obfs : ${Red_font_prefix}${obfs}${Font_color_suffix}"

	echo -e " Device limit: ${Green_font_prefix}${protocol_param}${Font_color_suffix}"

	echo -e " Single thread speed: ${Green_font_prefix}${speed_limit_per_con} KB/S${Font_color_suffix}"

	echo -e " Maximum User Speed: ${Green_font_prefix}${speed_limit_per_user} KB/S${Font_color_suffix}"

	echo -e " Forbidden Ports: ${Green_font_prefix}${forbidden_port} ${Font_color_suffix}"

	echo -e " Consumption of your Data:\n Carga: ${Green_font_prefix}${u}${Font_color_suffix} + Download: ${Green_font_prefix}${d}${Font_color_suffix} = ${Green_font_prefix}${transfer_enable_Used_2}${Font_color_suffix}"
	
         echo -e " Remaining traffic: ${Green_font_prefix}${transfer_enable_Used} ${Font_color_suffix}"
msg -bar
	echo -e " Total User Traffic: ${Green_font_prefix}${transfer_enable} ${Font_color_suffix}"
msg -bar
	echo -e "${ss_link}"
msg -bar
	echo -e "${ssr_link}"
msg -bar
	echo -e " ${Green_font_prefix} Nota: ${Font_color_suffix}
 In the browser, open the QR code link, you can\n see the QR code image."
msg -bar
}
#Configuracion de la informacion de configuracion
Set_config_user(){
msg -bar
	echo -ne "\e[92m 1) Enter a name for the user you want to Configure\n (Do not repeat, or it will be marked incorrectly!)\n"
msg -bar
	stty erase '^H' && read -p "(Default: VPS-AGN):" ssr_user
	[[ -z "${ssr_user}" ]] && ssr_user="VPS-AGN"
	echo && echo -e "	Username : ${Green_font_prefix}${ssr_user}${Font_color_suffix}" && echo
}
Set_config_port(){
msg -bar
	while true
	do
	echo -e "\e[92m 2) Please enter a Port for the User "
msg -bar
	stty erase '^H' && read -p "(Default: 2525):" ssr_port
	[[ -z "$ssr_port" ]] && ssr_port="2525"
	expr ${ssr_port} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_port} -ge 1 ]] && [[ ${ssr_port} -le 65535 ]]; then
			echo && echo -e "	Port : ${Green_font_prefix}${ssr_port}${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Please enter the correct number (1-65535)"
		fi
	else
		echo -e "${Error} Please enter the correct number (1-65535)"
	fi
	done
}
Set_config_password(){
msg -bar
	echo -e "\e[92m 3) Please enter a password for the User"
msg -bar
	stty erase '^H' && read -p "(Default: VPS-AGN):" ssr_password
	[[ -z "${ssr_password}" ]] && ssr_password="VPS-AGN"
	echo && echo -e "	Password : ${Green_font_prefix}${ssr_password}${Font_color_suffix}" && echo
}
Set_config_method(){
msg -bar
	echo -e "\e[92m 4) Select type of Encryption for the User\e[0m
$(msg -bar)
 ${Green_font_prefix} 1.${Font_color_suffix} Ninguno
 ${Green_font_prefix} 2.${Font_color_suffix} rc4
 ${Green_font_prefix} 3.${Font_color_suffix} rc4-md5
 ${Green_font_prefix} 4.${Font_color_suffix} rc4-md5-6
 ${Green_font_prefix} 5.${Font_color_suffix} aes-128-ctr
 ${Green_font_prefix} 6.${Font_color_suffix} aes-192-ctr
 ${Green_font_prefix} 7.${Font_color_suffix} aes-256-ctr
 ${Green_font_prefix} 8.${Font_color_suffix} aes-128-cfb
 ${Green_font_prefix} 9.${Font_color_suffix} aes-192-cfb
 ${Green_font_prefix}10.${Font_color_suffix} aes-256-cfb
 ${Green_font_prefix}11.${Font_color_suffix} aes-128-cfb8
 ${Green_font_prefix}12.${Font_color_suffix} aes-192-cfb8
 ${Green_font_prefix}13.${Font_color_suffix} aes-256-cfb8
 ${Green_font_prefix}14.${Font_color_suffix} salsa20
 ${Green_font_prefix}15.${Font_color_suffix} chacha20
 ${Green_font_prefix}16.${Font_color_suffix} chacha20-ietf
 
 ${Red_font_prefix}17.${Font_color_suffix} xsalsa20
 ${Red_font_prefix}18.${Font_color_suffix} xchacha20
$(msg -bar)
 ${Tip} Para salsa20/chacha20-*:\n Please install libsodium:\n Option 4 in main menu SSRR"
msg -bar
	stty erase '^H' && read -p "(Default: 16. chacha20-ietf):" ssr_method
msg -bar
	[[ -z "${ssr_method}" ]] && ssr_method="16"
	if [[ ${ssr_method} == "1" ]]; then
		ssr_method="Ninguno"
	elif [[ ${ssr_method} == "2" ]]; then
		ssr_method="rc4"
	elif [[ ${ssr_method} == "3" ]]; then
		ssr_method="rc4-md5"
	elif [[ ${ssr_method} == "4" ]]; then
		ssr_method="rc4-md5-6"
	elif [[ ${ssr_method} == "5" ]]; then
		ssr_method="aes-128-ctr"
	elif [[ ${ssr_method} == "6" ]]; then
		ssr_method="aes-192-ctr"
	elif [[ ${ssr_method} == "7" ]]; then
		ssr_method="aes-256-ctr"
	elif [[ ${ssr_method} == "8" ]]; then
		ssr_method="aes-128-cfb"
	elif [[ ${ssr_method} == "9" ]]; then
		ssr_method="aes-192-cfb"
	elif [[ ${ssr_method} == "10" ]]; then
		ssr_method="aes-256-cfb"
	elif [[ ${ssr_method} == "11" ]]; then
		ssr_method="aes-128-cfb8"
	elif [[ ${ssr_method} == "12" ]]; then
		ssr_method="aes-192-cfb8"
	elif [[ ${ssr_method} == "13" ]]; then
		ssr_method="aes-256-cfb8"
	elif [[ ${ssr_method} == "14" ]]; then
		ssr_method="salsa20"
	elif [[ ${ssr_method} == "15" ]]; then
		ssr_method="chacha20"
	elif [[ ${ssr_method} == "16" ]]; then
		ssr_method="chacha20-ietf"
	elif [[ ${ssr_method} == "17" ]]; then
		ssr_method="xsalsa20"
	elif [[ ${ssr_method} == "18" ]]; then
		ssr_method="xchacha20"
	else
		ssr_method="aes-256-cfb"
	fi
	echo && echo -e "	Encryption: ${Green_font_prefix}${ssr_method}${Font_color_suffix}" && echo
}
Set_config_protocol(){
msg -bar
	echo -e "\e[92m 5) Please select a Protocol
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix} origin
 ${Green_font_prefix}2.${Font_color_suffix} auth_sha1_v4
 ${Green_font_prefix}3.${Font_color_suffix} auth_aes128_md5
 ${Green_font_prefix}4.${Font_color_suffix} auth_aes128_sha1
 ${Green_font_prefix}5.${Font_color_suffix} auth_chain_a
 ${Green_font_prefix}6.${Font_color_suffix} auth_chain_b

 ${Red_font_prefix}7.${Font_color_suffix} auth_chain_c
 ${Red_font_prefix}8.${Font_color_suffix} auth_chain_d
 ${Red_font_prefix}9.${Font_color_suffix} auth_chain_e
 ${Red_font_prefix}10.${Font_color_suffix} auth_chain_f
$(msg -bar)
 ${Tip}\n If you select serial protocol auth_chain_ *:\n It is recommended to set the encryption method to none"
msg -bar
	stty erase '^H' && read -p "(Predterminaed: 1. origin):" ssr_protocol
msg -bar
	[[ -z "${ssr_protocol}" ]] && ssr_protocol="1"
	if [[ ${ssr_protocol} == "1" ]]; then
		ssr_protocol="origin"
	elif [[ ${ssr_protocol} == "2" ]]; then
		ssr_protocol="auth_sha1_v4"
	elif [[ ${ssr_protocol} == "3" ]]; then
		ssr_protocol="auth_aes128_md5"
	elif [[ ${ssr_protocol} == "4" ]]; then
		ssr_protocol="auth_aes128_sha1"
	elif [[ ${ssr_protocol} == "5" ]]; then
		ssr_protocol="auth_chain_a"
	elif [[ ${ssr_protocol} == "6" ]]; then
		ssr_protocol="auth_chain_b"
	elif [[ ${ssr_protocol} == "7" ]]; then
		ssr_protocol="auth_chain_c"
	elif [[ ${ssr_protocol} == "8" ]]; then
		ssr_protocol="auth_chain_d"
	elif [[ ${ssr_protocol} == "9" ]]; then
		ssr_protocol="auth_chain_e"
	elif [[ ${ssr_protocol} == "10" ]]; then
		ssr_protocol="auth_chain_f"
	else
		ssr_protocol="origin"
	fi
	echo && echo -e "	Protocol : ${Green_font_prefix}${ssr_protocol}${Font_color_suffix}" && echo
	if [[ ${ssr_protocol} != "origin" ]]; then
		if [[ ${ssr_protocol} == "auth_sha1_v4" ]]; then
			stty erase '^H' && read -p "Set protocol plug-in to compatible mode(_compatible)?[Y/n]" ssr_protocol_yn
			[[ -z "${ssr_protocol_yn}" ]] && ssr_protocol_yn="y"
			[[ $ssr_protocol_yn == [Yy] ]] && ssr_protocol=${ssr_protocol}"_compatible"
			echo
		fi
	fi
}
Set_config_obfs(){
msg -bar
	echo -e "\e[92m 6) Please select the OBFS method
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix} plain
 ${Green_font_prefix}2.${Font_color_suffix} http_simple
 ${Green_font_prefix}3.${Font_color_suffix} http_post
 ${Green_font_prefix}4.${Font_color_suffix} random_head
 ${Green_font_prefix}5.${Font_color_suffix} tls1.2_ticket_auth
$(msg -bar)
  If you choose tls1.2_ticket_auth, then the client can\n  elegir tls1.2_ticket_fastauth!"
msg -bar
	stty erase '^H' && read -p "(Default: 5. tls1.2_ticket_auth):" ssr_obfs
	[[ -z "${ssr_obfs}" ]] && ssr_obfs="5"
	if [[ ${ssr_obfs} == "1" ]]; then
		ssr_obfs="plain"
	elif [[ ${ssr_obfs} == "2" ]]; then
		ssr_obfs="http_simple"
	elif [[ ${ssr_obfs} == "3" ]]; then
		ssr_obfs="http_post"
	elif [[ ${ssr_obfs} == "4" ]]; then
		ssr_obfs="random_head"
	elif [[ ${ssr_obfs} == "5" ]]; then
		ssr_obfs="tls1.2_ticket_auth"
	else
		ssr_obfs="tls1.2_ticket_auth"
	fi
	echo && echo -e "	obfs : ${Green_font_prefix}${ssr_obfs}${Font_color_suffix}" && echo
	msg -bar
	if [[ ${ssr_obfs} != "plain" ]]; then
			stty erase '^H' && read -p "Configure Compatible mode (To use SS)? [y/n]: " ssr_obfs_yn
			[[ -z "${ssr_obfs_yn}" ]] && ssr_obfs_yn="y"
			[[ $ssr_obfs_yn == [Yy] ]] && ssr_obfs=${ssr_obfs}"_compatible"
	fi
}
Set_config_protocol_param(){
msg -bar
	while true
	do
	echo -e "\e[92m 7) Limit Number of Simultaneous Devices\n  ${Green_font_prefix} auth_*The series is not compatible with the original version. ${Font_color_suffix}"
msg -bar
	echo -e "${Tip} Device number limit:\n It is the number of clients that will use the account\n the recommended minimum 2."
msg -bar
	stty erase '^H' && read -p "(Default: Unlimited):" ssr_protocol_param
	[[ -z "$ssr_protocol_param" ]] && ssr_protocol_param="" && echo && break
	expr ${ssr_protocol_param} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_protocol_param} -ge 1 ]] && [[ ${ssr_protocol_param} -le 9999 ]]; then
			echo && echo -e "	Device limit: ${Green_font_prefix}${ssr_protocol_param}${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Please enter the correct number (1-9999)"
		fi
	else
		echo -e "${Error} Please enter the correct number (1-9999)"
	fi
	done
}
Set_config_speed_limit_per_con(){
msg -bar
	while true
	do
	echo -e "\e[92m 8) Enter a Speed ​​Limit x Thread (in KB/S)"
msg -bar
	stty erase '^H' && read -p "(Default: Unlimited):" ssr_speed_limit_per_con
msg -bar
	[[ -z "$ssr_speed_limit_per_con" ]] && ssr_speed_limit_per_con=0 && echo && break
	expr ${ssr_speed_limit_per_con} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_speed_limit_per_con} -ge 1 ]] && [[ ${ssr_speed_limit_per_con} -le 131072 ]]; then
			echo && echo -e "	Velocidad de Subproceso Unico: ${Green_font_prefix}${ssr_speed_limit_per_con} KB/S${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Please enter the correct number (1-131072)"
		fi
	else
		echo -e "${Error} Please enter the correct number (1-131072)"
	fi
	done
}
Set_config_speed_limit_per_user(){
msg -bar
	while true
	do
	echo -e "\e[92m 9) Enter a Maximum Speed ​​Limit (in KB/S)"
msg -bar
	echo -e "${Tip} Maximum Port Speed ​​Limit :\n It is the maximum speed that the User will go."
msg -bar
	stty erase '^H' && read -p "(Default: Unlimited):" ssr_speed_limit_per_user
	[[ -z "$ssr_speed_limit_per_user" ]] && ssr_speed_limit_per_user=0 && echo && break
	expr ${ssr_speed_limit_per_user} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_speed_limit_per_user} -ge 1 ]] && [[ ${ssr_speed_limit_per_user} -le 131072 ]]; then
			echo && echo -e "	Maximum User Speed : ${Green_font_prefix}${ssr_speed_limit_per_user} KB/S${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Please enter the correct number (1-131072)"
		fi
	else
		echo -e "${Error} Please enter the correct number (1-131072)"
	fi
	done
}
Set_config_transfer(){
msg -bar
	while true
	do
	echo -e "\e[92m 10) Enter Total Amount of Data for User\n (in GB, 1-838868 GB)"
msg -bar
	stty erase '^H' && read -p "(Default: Unlimited):" ssr_transfer
	[[ -z "$ssr_transfer" ]] && ssr_transfer="838868" && echo && break
	expr ${ssr_transfer} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_transfer} -ge 1 ]] && [[ ${ssr_transfer} -le 838868 ]]; then
			echo && echo -e "	Total Traffic For The User: ${Green_font_prefix}${ssr_transfer} GB${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Please enter the correct number (1-838868)"
		fi
	else
		echo -e "${Error} Please enter the correct number (1-838868)"
	fi
	done
}
Set_config_forbid(){
msg -bar
	echo "BAN PORTS"
msg -bar
	echo -e "${Tip} Forbidden Portss:\n For example, if you do not allow access to port 25,\n users will not be able to access mail port 25\n through the SSR proxy. If 80,443 is disabled,\n users will not be able to access\n http/https sites normally."
msg -bar
	stty erase '^H' && read -p "(Default: allow all):" ssr_forbid
	[[ -z "${ssr_forbid}" ]] && ssr_forbid=""
	echo && echo -e "	Forbidden port: ${Green_font_prefix}${ssr_forbid}${Font_color_suffix}" && echo
}
Set_config_enable(){
	user_total=$(expr ${user_total} - 1)
	for((integer = 0; integer <= ${user_total}; integer++))
	do
		echo -e "integer=${integer}"
		port_jq=$(${jq_file} ".[${integer}].port" "${config_user_mudb_file}")
		echo -e "port_jq=${port_jq}"
		if [[ "${ssr_port}" == "${port_jq}" ]]; then
			enable=$(${jq_file} ".[${integer}].enable" "${config_user_mudb_file}")
			echo -e "enable=${enable}"
			[[ "${enable}" == "null" ]] && echo -e "${Error} Get the current port [${ssr_port}] State disabled failed!" && exit 1
			ssr_port_num=$(cat "${config_user_mudb_file}"|grep -n '"puerto": '${ssr_port}','|awk -F ":" '{print $1}')
			echo -e "ssr_port_num=${ssr_port_num}"
			[[ "${ssr_port_num}" == "null" ]] && echo -e "${Error}Get the current port [${ssr_port}] Number of failed rows!" && exit 1
			ssr_enable_num=$(expr ${ssr_port_num} - 5)
			echo -e "ssr_enable_num=${ssr_enable_num}"
			break
		fi
	done
	if [[ "${enable}" == "1" ]]; then
		echo -e "Port [${ssr_port}] The account status is: ${Green_font_prefix}Enabled ${Font_color_suffix} , Switch to ${Red_font_prefix}Disabled${Font_color_suffix} ?[Y/n]"
		stty erase '^H' && read -p "(Default: Y):" ssr_enable_yn
		[[ -z "${ssr_enable_yn}" ]] && ssr_enable_yn="y"
		if [[ "${ssr_enable_yn}" == [Yy] ]]; then
			ssr_enable="0"
		else
			echo -e "Cancelled...\n$(msg -bar)" && exit 0
		fi
	elif [[ "${enable}" == "0" ]]; then
		echo -e "Port [${ssr_port}] The account status:${Green_font_prefix}Enabled ${Font_color_suffix} , Switch to ${Red_font_prefix}Disabled${Font_color_suffix} ?[Y/n]"
		stty erase '^H' && read -p "(Default: Y):" ssr_enable_yn
		[[ -z "${ssr_enable_yn}" ]] && ssr_enable_yn = "y"
		if [[ "${ssr_enable_yn}" == [Yy] ]]; then
			ssr_enable="1"
		else
			echo "Cancelling ..." && exit 0
		fi
	else
		echo -e "${Error} The current disabled state of Port is abnormal.[${enable}] !" && exit 1
	fi
}
Set_user_api_server_pub_addr(){
	addr=$1
	if [[ "${addr}" == "Modify" ]]; then
		server_pub_addr=$(cat ${config_user_api_file}|grep "SERVER_PUB_ADDR = "|awk -F "[']" '{print $2}')
		if [[ -z ${server_pub_addr} ]]; then
			echo -e "${Error} Obtained server IP or domain name failed!" && exit 1
		else
			echo -e "${Info} The currently configured server IP or domain name is ${Green_font_prefix}${server_pub_addr}${Font_color_suffix}"
		fi
	fi
	echo "Enter the server IP or domain name to be displayed in the user settings (when the server has multiple IPs, you can specify the IP or domain name to be displayed in the user settings)"
msg -bar
	stty erase '^H' && read -p "(Default:Automatic detection of external IP network):" ssr_server_pub_addr
	if [[ -z "${ssr_server_pub_addr}" ]]; then
		Get_IP
		if [[ ${ip} == "VPS_IP" ]]; then
			while true
			do
			stty erase '^H' && read -p "${Error} Automatic detection of external network IP failed, please manually enter server IP or domain name" ssr_server_pub_addr
			if [[ -z "$ssr_server_pub_addr" ]]; then
				echo -e "${Error}It cant be empty!"
			else
				break
			fi
			done
		else
			ssr_server_pub_addr="${ip}"
		fi
	fi
	echo && msg -bar && echo -e "	IP or domain name: ${Green_font_prefix}${ssr_server_pub_addr}${Font_color_suffix}" && msg -bar && echo
}
Set_config_all(){
	lal=$1
	if [[ "${lal}" == "Modify" ]]; then
		Set_config_password
		Set_config_method
		Set_config_protocol
		Set_config_obfs
		Set_config_protocol_param
		Set_config_speed_limit_per_con
		Set_config_speed_limit_per_user
		Set_config_transfer
		Set_config_forbid
	else
		Set_config_user
		Set_config_port
		Set_config_password
		Set_config_method
		Set_config_protocol
		Set_config_obfs
		Set_config_protocol_param
		Set_config_speed_limit_per_con
		Set_config_speed_limit_per_user
		Set_config_transfer
		Set_config_forbid
	fi
}
#Modificar la informaci�n de configuraci�n
Modify_config_password(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -k "${ssr_password}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Failed to modify the user's password ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} The user's password was changed successfully ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Puede tardar unos 10 segundos aplicar la ultima configuracion)"
	fi
}
Modify_config_method(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -m "${ssr_method}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Modification of the user's encryption method failed ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} User encryption mode ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Note: The most recent configuration may take up to 10 seconds.)"
	fi
}
Modify_config_protocol(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -O "${ssr_protocol}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} User protocol modification failed ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} User agreement modification successful ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Note: the most recent configuration may take about 10 seconds)"
	fi
}
Modify_config_obfs(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -o "${ssr_obfs}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Modification of user confusion failed ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} User confusion modification success ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Note: The application of the last configuration may take about 10 seconds)"
	fi
}
Modify_config_protocol_param(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -G "${ssr_protocol_param}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Failed to modify user protocol parameter (number of devices limit) ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} User negotiation parameters (number of limit devices) modified correctly ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Note: It may take approximately 10 seconds to apply the latest settings.)"
	fi
}
Modify_config_speed_limit_per_con(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -s "${ssr_speed_limit_per_con}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Failed to modify the speed of a single thread ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Single thread speed modification successful ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Note: It may take approximately 10 seconds to apply the latest settings.)"
	fi
}
Modify_config_speed_limit_per_user(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -S "${ssr_speed_limit_per_user}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} User Port the modification of the total speed limit failed ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} User Port total speed limit modified successfully ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Note: the most recent configuration may take about 10 seconds)"
	fi
}
Modify_config_connect_verbose_info(){
	sed -i 's/"connect_verbose_info": '"$(echo ${connect_verbose_info})"',/"connect_verbose_info": '"$(echo ${ssr_connect_verbose_info})"',/g' ${config_user_file}
}
Modify_config_transfer(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -t "${ssr_transfer}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Total User Traffic modification failed ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Total User Traffic ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Note: the most recent configuration may take about 10 seconds)"
	fi
}
Modify_config_forbid(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -f "${ssr_forbid}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} The modification of the prohibited port by the user has failed ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} The Forbidden Portss by the user were successfully modified ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Note: It may take approximately 10 seconds to apply the latest settings.)"
	fi
}
Modify_config_enable(){
	sed -i "${ssr_enable_num}"'s/"enable": '"$(echo ${enable})"',/"enable": '"$(echo ${ssr_enable})"',/' ${config_user_mudb_file}
}
Modify_user_api_server_pub_addr(){
	sed -i "s/SERVER_PUB_ADDR = '${server_pub_addr}'/SERVER_PUB_ADDR = '${ssr_server_pub_addr}'/" ${config_user_api_file}
}
Modify_config_all(){
	Modify_config_password
	Modify_config_method
	Modify_config_protocol
	Modify_config_obfs
	Modify_config_protocol_param
	Modify_config_speed_limit_per_con
	Modify_config_speed_limit_per_user
	Modify_config_transfer
	Modify_config_forbid
}
Check_python(){
	python_ver=`python -h`
	if [[ -z ${python_ver} ]]; then
		echo -e "${Info} I don't install python, start installing ..."
		if [[ ${release} == "centos" ]]; then
			yum install -y python
		else
			apt-get install -y python
		fi
	fi
}
Centos_yum(){
	yum update
	cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
	if [[ $? = 0 ]]; then
		yum install -y vim unzip crond net-tools git
	else
		yum install -y vim unzip crond git
	fi
}
Debian_apt(){
	apt-get update
	apt-get install -y vim unzip cron git net-tools
}
#Descargar ShadowsocksR
Download_SSR(){
	cd "/usr/local"
	# wget -N --no-check-certificate "https://github.com/ToyoDAdoubi/shadowsocksr/archive/manyuser.zip"
	#git config --global http.sslVerify false
	git clone -b akkariiin/master https://github.com/shadowsocksrr/shadowsocksr.git
	[[ ! -e ${ssr_folder} ]] && echo -e "${Error} ShadowsocksR server download failed!" && exit 1
	# [[ ! -e "manyuser.zip" ]] && echo -e "${Error} Fallo la descarga del paquete de compresion lateral ShadowsocksR !" && rm -rf manyuser.zip && exit 1
	# unzip "manyuser.zip"
	# [[ ! -e "/usr/local/shadowsocksr-manyuser/" ]] && echo -e "${Error} Fallo la descompresi�n del servidor ShadowsocksR !" && rm -rf manyuser.zip && exit 1
	# mv "/usr/local/shadowsocksr-manyuser/" "/usr/local/shadowsocksr/"
	# [[ ! -e "/usr/local/shadowsocksr/" ]] && echo -e "${Error} Fallo el cambio de nombre del servidor ShadowsocksR!" && rm -rf manyuser.zip && rm -rf "/usr/local/shadowsocksr-manyuser/" && exit 1
	# rm -rf manyuser.zip
	cd "shadowsocksr"
	cp "${ssr_folder}/config.json" "${config_user_file}"
	cp "${ssr_folder}/mysql.json" "${ssr_folder}/usermysql.json"
	cp "${ssr_folder}/apiconfig.py" "${config_user_api_file}"
	[[ ! -e ${config_user_api_file} ]] && echo -e "${Error} ShadowsocksR server apiconfig.py replication failed!" && exit 1
	sed -i "s/API_INTERFACE = 'sspanelv2'/API_INTERFACE = 'mudbjson'/" ${config_user_api_file}
	server_pub_addr="127.0.0.1"
	Modify_user_api_server_pub_addr
	#sed -i "s/SERVER_PUB_ADDR = '127.0.0.1'/SERVER_PUB_ADDR = '${ip}'/" ${config_user_api_file}
	sed -i 's/ \/\/ only works under multi-user mode//g' "${config_user_file}"
	echo -e "${Info} ShadowsocksR server download complete!"
}
Service_SSR(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ssrmu_centos -O /etc/init.d/ssrmu; then
			echo -e "${Error} ShadowsocksR Service Management Script Download Failed!" && exit 1
		fi
		chmod +x /etc/init.d/ssrmu
		chkconfig --add ssrmu
		chkconfig ssrmu on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ssrmu_debian -O /etc/init.d/ssrmu; then
			echo -e "${Error} ShadowsocksR service management script download failed!" && exit 1
		fi
		chmod +x /etc/init.d/ssrmu
		update-rc.d -f ssrmu defaults
	fi
	echo -e "${Info} ShadowsocksR Service Management Script Download Download!"
}
#Instalar el analizador JQ
JQ_install(){
	if [[ ! -e ${jq_file} ]]; then
		cd "${ssr_folder}"
		if [[ ${bit} = "x86_64" ]]; then
			# mv "jq-linux64" "jq"
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" -O ${jq_file}
		else
			# mv "jq-linux32" "jq"
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux32" -O ${jq_file}
		fi
		[[ ! -e ${jq_file} ]] && echo -e "${Error} JQ parser, please!" && exit 1
		chmod +x ${jq_file}
		echo -e "${Info} JQ parser installation is complete, continue..." 
	else
		echo -e "${Info} JQ parser is installed, continue..."
	fi
}
#Instalacion
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		Centos_yum
	else
		Debian_apt
	fi
	[[ ! -e "/usr/bin/unzip" ]] && echo -e "${Error} Installation dependent unzip (compressed package) failed, mostly problem, please check!" && exit 1
	Check_python
	#echo "nameserver 8.8.8.8" > /etc/resolv.conf
	#echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	if [[ ${release} == "centos" ]]; then
		/etc/init.d/crond restart
	else
		/etc/init.d/cron restart
	fi
}
Install_SSR(){
clear
	check_root
	msg -bar
	[[ -e ${ssr_folder} ]] && echo -e "${Error}\nShadowsocksR folder has been created, please check\n(if installation fails, uninstall first) !\n$(msg -bar)" && exit 1 
	echo -e "${Info}\nBegin ShadowsocksR account setup..."
msg -bar
	Set_user_api_server_pub_addr
	Set_config_all
	echo -e "${Info} Start installing/configuring ShadowsocksR dependencies ..."
	Installation_dependency
	echo -e "${Info} Start Download / Install ShadowsocksR File ..."
	Download_SSR
	echo -e "${Info} Start Download / Install ShadowsocksR Service Script(init)..."
	Service_SSR
	echo -e "${Info} Start Download / Install JSNO Parser JQ ..."
	JQ_install
	echo -e "${Info} Start adding initial user ..."
	Add_port_user "install"
	echo -e "${Info} Start configuring the iptables firewall ..."
	Set_iptables
	echo -e "${Info} Start adding iptables firewall rules ..."
	Add_iptables
	echo -e "${Info} Start saving iptables firewall rules ..."
	Save_iptables
	echo -e "${Info} All steps to start ShadowsocksR service ..."
	Start_SSR
	Get_User_info "${ssr_port}"
	View_User_info

}
Update_SSR(){
	SSR_installation_status
	# echo -e "Debido a que el beb� roto actualiza el servidor ShadowsocksR, entonces."
	cd ${ssr_folder}
	git pull
	Restart_SSR

}
Uninstall_SSR(){
	[[ ! -e ${ssr_folder} ]] && echo -e "${Error} ShadowsocksR is not installed, please check!\n$(msg -bar)" && exit 1
	echo "Uninstall ShadowsocksR [y/n]"
msg -bar 
	stty erase '^H' && read -p "(Default: n):" unyn
msg -bar
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z "${PID}" ]] && kill -9 ${PID}
		user_info=$(python mujson_mgr.py -l)
		user_total=$(echo "${user_info}"|wc -l)
		if [[ ! -z ${user_info} ]]; then
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
				Del_iptables
			done
		fi
		if [[ ${release} = "centos" ]]; then
			chkconfig --del ssrmu
		else
			update-rc.d -f ssrmu remove
		fi
		rm -rf ${ssr_folder} && rm -rf /etc/init.d/ssrmu
		echo && echo " ShadowsocksR uninstall completed!" && echo
	else
		echo && echo "uninstall canceled ..." && echo
	fi

}
Check_Libsodium_ver(){
	echo -e "${Info} Descargando la ultima version de libsodium"
	#Libsodiumr_ver=$(wget -qO- "https://github.com/jedisct1/libsodium/tags"|grep "/jedisct1/libsodium/releases/tag/"|head -1|sed -r 's/.*tag\/(.+)\">.*/\1/')
	Libsodiumr_ver=1.0.17
	[[ -z ${Libsodiumr_ver} ]] && Libsodiumr_ver=${Libsodiumr_ver_backup}
	echo -e "${Info} The latest version of libsodium is ${Green_font_prefix}${Libsodiumr_ver}${Font_color_suffix} !"
}
Install_Libsodium(){
	if [[ -e ${Libsodiumr_file} ]]; then
		echo -e "${Error} libsodium already installed, do you want to update?[y/N]"
		stty erase '^H' && read -p "(Default: n):" yn
		[[ -z ${yn} ]] && yn="n"
		if [[ ${yn} == [Nn] ]]; then
			echo -e "Cancelled ...\n$(msg -bar)" && exit 1
		fi
	else
		echo -e "${Info} libsodium not installed, installation started ..."
	fi
	Check_Libsodium_ver
	if [[ ${release} == "centos" ]]; then
		yum -y actualizacion
		echo -e "${Info} Installation depends on ..."
		yum -y groupinstall "Development tools"
		echo -e "${Info} Download ..."
		wget  --no-check-certificate -N "https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz"
		echo -e "${Info} Decompress ..."
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz && cd libsodium-${Libsodiumr_ver}
		echo -e "${Info} Compile and install ..."
		./configure --disable-maintainer-mode && make -j2 && make install
		echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	else
		apt-get update
		echo -e "${Info} Installation depends on ..."
		apt-get install -y build-essential
		echo -e "${Info} Download ..."
		wget  --no-check-certificate -N "https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz"
		echo -e "${Info} Decompress ..."
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz && cd libsodium-${Libsodiumr_ver}
		echo -e "${Info} Compile and install ..."
		./configure --disable-maintainer-mode && make -j2 && make install
	fi
	ldconfig
	cd .. && rm -rf libsodium-${Libsodiumr_ver}.tar.gz && rm -rf libsodium-${Libsodiumr_ver}
	[[ ! -e ${Libsodiumr_file} ]] && echo -e "${Error} libsodium installation failed!" && exit 1
	echo && echo -e "${Info} libsodium installation success!" && echo
msg -bar
}
#Mostrar informaci�n de conexi�n
debian_View_user_connection_info(){
	format_1=$1
	user_info=$(python mujson_mgr.py -l)
	user_total=$(echo "${user_info}"|wc -l)
	[[ -z ${user_info} ]] && echo -e "${Error} not found, please check!" && exit 1
	IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
	user_list_all=""
	for((integer = 1; integer <= ${user_total}; integer++))
	do
		user_port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
		user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep ":${user_port} " |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u`
		if [[ -z ${user_IP_1} ]]; then
			user_IP_total="0"
		else
			user_IP_total=`echo -e "${user_IP_1}"|wc -l`
			if [[ ${format_1} == "IP_address" ]]; then
				get_IP_address
			else
				user_IP=`echo -e "\n${user_IP_1}"`
			fi
		fi
		user_list_all=${user_list_all}"Port: ${Green_font_prefix}"${user_port}"${Font_color_suffix}, The total number of linked IPs: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}, Current linked IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		user_IP=""
	done
	echo -e "Total number of users: ${Green_background_prefix} "${user_total}" ${Font_color_suffix} Total number of linked IPs: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix}\n"
	echo -e "${user_list_all}"
msg -bar 
}
centos_View_user_connection_info(){
	format_1=$1
	user_info=$(python mujson_mgr.py -l)
	user_total=$(echo "${user_info}"|wc -l)
	[[ -z ${user_info} ]] && echo -e "${Error} Not found, please check!" && exit 1
	IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |wc -l`
	user_list_all=""
	for((integer = 1; integer <= ${user_total}; integer++))
	do
		user_port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
		user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep ":${user_port} "|grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u`
		if [[ -z ${user_IP_1} ]]; then
			user_IP_total="0"
		else
			user_IP_total=`echo -e "${user_IP_1}"|wc -l`
			if [[ ${format_1} == "IP_address" ]]; then
				get_IP_address
			else
				user_IP=`echo -e "\n${user_IP_1}"`
			fi
		fi
		user_list_all=${user_list_all}"Port: ${Green_font_prefix}"${user_port}"${Font_color_suffix}, The total number of linked IPs: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}, Current linked IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		user_IP=""
	done
	echo -e "The total number of users: ${Green_background_prefix} "${user_total}" ${Font_color_suffix} The total number of linked IPs: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix} "
	echo -e "${user_list_all}"
}
View_user_connection_info(){
clear
	SSR_installation_status
	msg -bar
	 echo -e "Select the format to display :
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix} Show IP 

 ${Green_font_prefix}2.${Font_color_suffix} Show IP + Resolve DNS Name"
msg -bar
	stty erase '^H' && read -p "(Default: 1):" ssr_connection_info
msg -bar
	[[ -z "${ssr_connection_info}" ]] && ssr_connection_info="1"
	if [[ ${ssr_connection_info} == "1" ]]; then
		View_user_connection_info_1 ""
	elif [[ ${ssr_connection_info} == "2" ]]; then
		echo -e "${Tip} Detect IP (ipip.net) may take more time if there are many IPs"
msg -bar
		View_user_connection_info_1 "IP_address"
	else
		echo -e "${Error} Enter the correct number(1-2)" && exit 1
	fi
}
View_user_connection_info_1(){
	format=$1
	if [[ ${release} = "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? = 0 ]]; then
			debian_View_user_connection_info "$format"
		else
			centos_View_user_connection_info "$format"
		fi
	else
		debian_View_user_connection_info "$format"
	fi
}
get_IP_address(){
	#echo "user_IP_1=${user_IP_1}"
	if [[ ! -z ${user_IP_1} ]]; then
	#echo "user_IP_total=${user_IP_total}"
		for((integer_1 = ${user_IP_total}; integer_1 >= 1; integer_1--))
		do
			IP=`echo "${user_IP_1}" |sed -n "$integer_1"p`
			#echo "IP=${IP}"
			IP_address=`wget -qO- -t1 -T2 http://freeapi.ipip.net/${IP}|sed 's/\"//g;s/,//g;s/\[//g;s/\]//g'`
			#echo "IP_address=${IP_address}"
			user_IP="${user_IP}\n${IP}(${IP_address})"
			#echo "user_IP=${user_IP}"
			sleep 1s
		done
	fi
}
#Modificar la configuraci�n del usuario
Modify_port(){
msg -bar
	List_port_user
	while true
	do
		echo -e "Please enter the user (Port) that has to be modified" 
msg -bar
		stty erase '^H' && read -p "(Default: Cancel):" ssr_port
		[[ -z "${ssr_port}" ]] && echo -e "Cancelled ...\n$(msg -bar)" && exit 1
		Modify_user=$(cat "${config_user_mudb_file}"|grep '"port": '"${ssr_port}"',')
		if [[ ! -z ${Modify_user} ]]; then
			break
		else
			echo -e "${Error} Port Enter the correct port!"
		fi
	done
}
Modify_Config(){
clear
	SSR_installation_status
	echo && echo -e "    ###¿What do you want to do??###Mod By @KhaledAGN
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix}  Add and Configure User
 ${Green_font_prefix}2.${Font_color_suffix}  Delete User Settings
————————— Modify User Settings ————
 ${Green_font_prefix}3.${Font_color_suffix}  Modify User Password
 ${Green_font_prefix}4.${Font_color_suffix}  Modify the encryption method
 ${Green_font_prefix}5.${Font_color_suffix}  Modify the Protocol
 ${Green_font_prefix}6.${Font_color_suffix}  Modify Obfuscation
 ${Green_font_prefix}7.${Font_color_suffix}  Modify Device Limit
 ${Green_font_prefix}8.${Font_color_suffix}  Modify the Speed ​​Limit of a single Thread
 ${Green_font_prefix}9.${Font_color_suffix}  Modify Total User Speed ​​limit
 ${Green_font_prefix}10.${Font_color_suffix} Modify Total User Traffic
 ${Green_font_prefix}11.${Font_color_suffix} Modify the user's Forbidden Ports
 ${Green_font_prefix}12.${Font_color_suffix} Modify Full Settings
————————— Other Settings —————————
 ${Green_font_prefix}13.${Font_color_suffix} Modify the IP or domain name that\n is displayed in the user's profile
$(msg -bar)
 ${Tip} The username and port of the user\n cannot be modified. If you need to modify them, use\n the script to manually modify the function !"
msg -bar
	stty erase '^H' && read -p "(Default: Cancel):" ssr_modify
	[[ -z "${ssr_modify}" ]] && echo -e "Cancelled ...\n$(msg -bar)" && exit 1
	if [[ ${ssr_modify} == "1" ]]; then
		Add_port_user
	elif [[ ${ssr_modify} == "2" ]]; then
		Del_port_user
	elif [[ ${ssr_modify} == "3" ]]; then
		Modify_port
		Set_config_password
		Modify_config_password
	elif [[ ${ssr_modify} == "4" ]]; then
		Modify_port
		Set_config_method
		Modify_config_method
	elif [[ ${ssr_modify} == "5" ]]; then
		Modify_port
		Set_config_protocol
		Modify_config_protocol
	elif [[ ${ssr_modify} == "6" ]]; then
		Modify_port
		Set_config_obfs
		Modify_config_obfs
	elif [[ ${ssr_modify} == "7" ]]; then
		Modify_port
		Set_config_protocol_param
		Modify_config_protocol_param
	elif [[ ${ssr_modify} == "8" ]]; then
		Modify_port
		Set_config_speed_limit_per_con
		Modify_config_speed_limit_per_con
	elif [[ ${ssr_modify} == "9" ]]; then
		Modify_port
		Set_config_speed_limit_per_user
		Modify_config_speed_limit_per_user
	elif [[ ${ssr_modify} == "10" ]]; then
		Modify_port
		Set_config_transfer
		Modify_config_transfer
	elif [[ ${ssr_modify} == "11" ]]; then
		Modify_port
		Set_config_forbid
		Modify_config_forbid
	elif [[ ${ssr_modify} == "12" ]]; then
		Modify_port
		Set_config_all "Modify"
		Modify_config_all
	elif [[ ${ssr_modify} == "13" ]]; then
		Set_user_api_server_pub_addr "Modify"
		Modify_user_api_server_pub_addr
	else
		echo -e "${Error} Enter the correct number(1-13)" && exit 1
	fi

}
List_port_user(){
	user_info=$(python mujson_mgr.py -l)
	user_total=$(echo "${user_info}"|wc -l)
	[[ -z ${user_info} ]] && echo -e "${Error} I did not find the user, please check again!" && exit 1
	user_list_all=""
	for((integer = 1; integer <= ${user_total}; integer++))
	do
		user_port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
		user_username=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $2}'|sed 's/\[//g;s/\]//g')
		Get_User_transfer "${user_port}"
		
		user_list_all=${user_list_all}"Username: ${Green_font_prefix} "${user_username}"${Font_color_suffix}\nPort: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\nTraffic Usage (Used + Remaining = Total):\n ${Green_font_prefix}${transfer_enable_Used_2}${Font_color_suffix} + ${Green_font_prefix}${transfer_enable_Used}${Font_color_suffix} = ${Green_font_prefix}${transfer_enable}${Font_color_suffix}\n--------------------------------------------\n "
	done
	echo && echo -e "===== The total number of users ===== ${Green_background_prefix} "${user_total}" ${Font_color_suffix}\n--------------------------------------------"
	echo -e ${user_list_all}
}
Add_port_user(){
clear
	lalal=$1
	if [[ "$lalal" == "install" ]]; then
		match_add=$(python mujson_mgr.py -a -u "${ssr_user}" -p "${ssr_port}" -k "${ssr_password}" -m "${ssr_method}" -O "${ssr_protocol}" -G "${ssr_protocol_param}" -o "${ssr_obfs}" -s "${ssr_speed_limit_per_con}" -S "${ssr_speed_limit_per_user}" -t "${ssr_transfer}" -f "${ssr_forbid}"|grep -w "add user info")
	else
		while true
		do
			Set_config_all
			match_port=$(python mujson_mgr.py -l|grep -w "port ${ssr_port}$")
			[[ ! -z "${match_port}" ]] && echo -e "${Error} The port [${ssr_port}] It already exists, don't add it again !" && exit 1
			match_username=$(python mujson_mgr.py -l|grep -w "Usuario \[${ssr_user}]")
			[[ ! -z "${match_username}" ]] && echo -e "${Error} Username [${ssr_user}] It already exists, don't add it again !" && exit 1
			match_add=$(python mujson_mgr.py -a -u "${ssr_user}" -p "${ssr_port}" -k "${ssr_password}" -m "${ssr_method}" -O "${ssr_protocol}" -G "${ssr_protocol_param}" -o "${ssr_obfs}" -s "${ssr_speed_limit_per_con}" -S "${ssr_speed_limit_per_user}" -t "${ssr_transfer}" -f "${ssr_forbid}"|grep -w "add user info")
			if [[ -z "${match_add}" ]]; then
				echo -e "${Error} User could not be added ${Green_font_prefix}[Username: ${ssr_user} , port: ${ssr_port}]${Font_color_suffix} "
				break
			else
				Add_iptables
				Save_iptables
				msg -bar
				echo -e "${Info} User added successfully\n ${Green_font_prefix}[Username: ${ssr_user} , Port: ${ssr_port}]${Font_color_suffix} "
				echo
				stty erase '^H' && read -p "Continue to add another User?[y/n]:" addyn
				[[ -z ${addyn} ]] && addyn="y"
				if [[ ${addyn} == [Nn] ]]; then
					Get_User_info "${ssr_port}"
					View_User_info
					break
				else
					echo -e "${Info} Continue adding user settings ..."
				fi
			fi
		done
	fi
}
Del_port_user(){

	List_port_user
	while true
	do
		msg -bar
		echo -e "Please enter the user port to be removed"
		stty erase '^H' && read -p "(Default: Cancel):" del_user_port
		msg -bar
		[[ -z "${del_user_port}" ]] && echo -e "Cancelled ...\n$(msg -bar)" && exit 1
		del_user=$(cat "${config_user_mudb_file}"|grep '"port": '"${del_user_port}"',')
		if [[ ! -z ${del_user} ]]; then
			port=${del_user_port}
			match_del=$(python mujson_mgr.py -d -p "${del_user_port}"|grep -w "delete user ")
			if [[ -z "${match_del}" ]]; then
				echo -e "${Error} User deletion failed ${Green_font_prefix}[Puerto: ${del_user_port}]${Font_color_suffix} "
			else
				Del_iptables
				Save_iptables
				echo -e "${Info} Successfully deleted user ${Green_font_prefix}[Puerto: ${del_user_port}]${Font_color_suffix} "
			fi
			break
		else
			echo -e "${Error} Please enter the correct port !"
		fi
	done
	msg -bar
}
Manually_Modify_Config(){
clear
msg -bar
	SSR_installation_status
	nano ${config_user_mudb_file}
	echo "If I restart ShadowsocksR now?[Y/n]" && echo
msg -bar
	stty erase '^H' && read -p "(Default: y):" yn
	[[ -z ${yn} ]] && yn="y"
	if [[ ${yn} == [Yy] ]]; then
		Restart_SSR
	fi

}
Clear_transfer(){
clear
msg -bar
	SSR_installation_status
	 echo -e "What do you want to do?
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix}  Delete traffic from a single user
 ${Green_font_prefix}2.${Font_color_suffix}  Delete all user traffic (irreparable)
 ${Green_font_prefix}3.${Font_color_suffix}  All user traffic is cleared on startup
 ${Green_font_prefix}4.${Font_color_suffix}  Stop timing all user traffic
 ${Green_font_prefix}5.${Font_color_suffix}  Modify the synchronization of all user traffic"
msg -bar
	stty erase '^H' && read -p "(Default:Cancel):" ssr_modify
	[[ -z "${ssr_modify}" ]] && echo "Cancelled ..." && exit 1
	if [[ ${ssr_modify} == "1" ]]; then
		Clear_transfer_one
	elif [[ ${ssr_modify} == "2" ]]; then
msg -bar
		echo "Are you sure you want to delete all user traffic?[y/n]" && echo
msg -bar
		stty erase '^H' && read -p "(Default: n):" yn
		[[ -z ${yn} ]] && yn="n"
		if [[ ${yn} == [Yy] ]]; then
			Clear_transfer_all
		else
			echo "Cancel ..."
		fi
	elif [[ ${ssr_modify} == "3" ]]; then
		check_crontab
		Set_crontab
		Clear_transfer_all_cron_start
	elif [[ ${ssr_modify} == "4" ]]; then
		check_crontab
		Clear_transfer_all_cron_stop
	elif [[ ${ssr_modify} == "5" ]]; then
		check_crontab
		Clear_transfer_all_cron_modify
	else
		echo -e "${Error} please number of (1-5)" && exit 1
	fi

}
Clear_transfer_one(){
	List_port_user
	while true
	do
	    msg -bar
		echo -e "Please enter user port to clear used traffic"
		stty erase '^H' && read -p "(Default: Cancel):" Clear_transfer_user_port
		[[ -z "${Clear_transfer_user_port}" ]] && echo -e "Cancelled ...\n$(msg -bar)" && exit 1
		Clear_transfer_user=$(cat "${config_user_mudb_file}"|grep '"port": '"${Clear_transfer_user_port}"',')
		if [[ ! -z ${Clear_transfer_user} ]]; then
			match_clear=$(python mujson_mgr.py -c -p "${Clear_transfer_user_port}"|grep -w "clear user ")
			if [[ -z "${match_clear}" ]]; then
				echo -e "${Error} The user was unable to use traffic compensation ${Green_font_prefix}[Puerto: ${Clear_transfer_user_port}]${Font_color_suffix} "
			else
				echo -e "${Info} User has successfully removed traffic using zero. ${Green_font_prefix}[Puerto: ${Clear_transfer_user_port}]${Font_color_suffix} "
			fi
			break
		else
			echo -e "${Error} Please enter the correct port !"
		fi
	done
}
Clear_transfer_all(){
clear
	cd "${ssr_folder}"
	user_info=$(python mujson_mgr.py -l)
	user_total=$(echo "${user_info}"|wc -l)
	[[ -z ${user_info} ]] && echo -e "${Error} not found, please check!" && exit 1
	for((integer = 1; integer <= ${user_total}; integer++))
	do
		user_port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
		match_clear=$(python mujson_mgr.py -c -p "${user_port}"|grep -w "clear user ")
		if [[ -z "${match_clear}" ]]; then
			echo -e "${Error} The user has used the traffic deleted failed ${Green_font_prefix}[Port: ${user_port}]${Font_color_suffix} "
		else
			echo -e "${Info} User has used traffic to delete successfully ${Green_font_prefix}[Port: ${user_port}]${Font_color_suffix} "
		fi
	done
	echo -e "${Info} All user traffic is deleted!"
}
Clear_transfer_all_cron_start(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrmu.sh/d" "$file/crontab.bak"
	echo -e "\n${Crontab_time} /bin/bash $file/ssrmu.sh clearall" >> "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrmu.sh")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Timing of all user traffic deleted. !" && exit 1
	else
		echo -e "${Info} Scheduling all successful clear start times!"
	fi
}
Clear_transfer_all_cron_stop(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrmu.sh/d" "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrmu.sh")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Timed All user traffic has been cleared Stopping Failed!" && exit 1
	else
		echo -e "${Info} Timing All Clear and Stopped Successfully!!"
	fi
}
Clear_transfer_all_cron_modify(){
	Set_crontab
	Clear_transfer_all_cron_stop
	Clear_transfer_all_cron_start
}
Set_crontab(){
clear

		echo -e "Please enter the flow time interval
 === Format ===
 * * * * * Month * * * * *
 ${Green_font_prefix} 0 2 1 * * ${Font_color_suffix} Rep 1st, 2:00, sure, used traffic.
$(msg -bar)
 ${Green_font_prefix} 0 2 15 * * ${Font_color_suffix} Representative The 1 2} represents the 15 2:00 minutes Flow used point cleared 0 minutes Clear flow used.
$(msg -bar)
 ${Green_font_prefix} 0 2 */7 * * ${Font_color_suffix} Rep 7 days 2: 0 minutes clear used traffic.
$(msg -bar)
 ${Green_font_prefix} 0 2 * * 0 ${Font_color_suffix} Represents every Sunday (7) to clear the traffic used.
$(msg -bar)
 ${Green_font_prefix} 0 2 * * 3 ${Font_color_suffix} Representative (3) Traffic flow used clear"
msg -bar
	stty erase '^H' && read -p "(Default: 0 2 1 * * 1 of each month 2:00):" Crontab_time
	[[ -z "${Crontab_time}" ]] && Crontab_time="0 2 1 * *"
}
Start_SSR(){
clear
	SSR_installation_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} ShadowsocksR is running!" && exit 1
	/etc/init.d/ssrmu start

}
Stop_SSR(){
clear
	SSR_installation_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} ShadowsocksR is not working!" && exit 1
	/etc/init.d/ssrmu stop

}
Restart_SSR(){
clear
	SSR_installation_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/ssrmu stop
	/etc/init.d/ssrmu start

}
View_Log(){
	SSR_installation_status
	[[ ! -e ${ssr_log_file} ]] && echo -e "${Error} ShadowsocksR Registry does not exist!" && exit 1
	echo && echo -e "${Tip} Press ${Red_font_prefix}Ctrl+C ${Font_color_suffix} Termination Registry " && echo
	tail -f ${ssr_log_file}

}
#Afilado
Configure_Server_Speeder(){
clear
msg -bar
	echo && echo -e "What are you going to do
${BARRA1}
 ${Green_font_prefix}1.${Font_color_suffix} sharp speed
$(msg -bar)
 ${Green_font_prefix}2.${Font_color_suffix} sharp speed
————————
 ${Green_font_prefix}3.${Font_color_suffix} sharp speed
$(msg -bar)
 ${Green_font_prefix}4.${Font_color_suffix} sharp speed
$(msg -bar)
 ${Green_font_prefix}5.${Font_color_suffix} restart sharp speed
$(msg -bar)
 ${Green_font_prefix}6.${Font_color_suffix} acute condition
 $(msg -bar)
 Note: Sharp and LotServer cannot be installed/started at the same time"
msg -bar
	stty erase '^H' && read -p "(Default: Cancel):" server_speeder_num
	[[ -z "${server_speeder_num}" ]] && echo "Cancelled ..." && exit 1
	if [[ ${server_speeder_num} == "1" ]]; then
		Install_ServerSpeeder
	elif [[ ${server_speeder_num} == "2" ]]; then
		Server_Speeder_installation_status
		Uninstall_ServerSpeeder
	elif [[ ${server_speeder_num} == "3" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} start
		${Server_Speeder_file} status
	elif [[ ${server_speeder_num} == "4" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} stop
	elif [[ ${server_speeder_num} == "5" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} restart
		${Server_Speeder_file} status
	elif [[ ${server_speeder_num} == "6" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} status
	else
		echo -e "${Error} please number(1-6)" && exit 1
	fi
}
Install_ServerSpeeder(){
	[[ -e ${Server_Speeder_file} ]] && echo -e "${Error} Server Speeder is installed!" && exit 1
	#Prestamo de la version feliz de 91yun.rog
	wget --no-check-certificate -qO /tmp/serverspeeder.sh https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder.sh
	[[ ! -e "/tmp/serverspeeder.sh" ]] && echo -e "${Error} Loan of the happy version of 91yun.rog!" && exit 1
	bash /tmp/serverspeeder.sh
	sleep 2s
	PID=`ps -ef |grep -v grep |grep "serverspeeder" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		rm -rf /tmp/serverspeeder.sh
		rm -rf /tmp/91yunserverspeeder
		rm -rf /tmp/91yunserverspeeder.tar.gz
		echo -e "${Info} Speeder server installation is completed!" && exit 1
	else
		echo -e "${Error} Server Speeder installation failed!" && exit 1
	fi
}
Uninstall_ServerSpeeder(){
clear
msg -bar
	echo "yes to uninstall Speed ​​??Speed ​​??(Server Speeder)[y/N]" && echo
msg -bar
	stty erase '^H' && read -p "(Default: n):" unyn
	[[ -z ${unyn} ]] && echo && echo "Cancelled ..." && exit 1
	if [[ ${unyn} == [Yy] ]]; then
		chattr -i /serverspeeder/etc/apx*
		/serverspeeder/bin/serverSpeeder.sh uninstall -f
		echo && echo "Server Speeder Complete Uninstall!" && echo
	fi
}
# LotServer
Configure_LotServer(){
clear
msg -bar
	echo && echo -e "What are you going to do?
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix} Install LotServer
$(msg -bar)
 ${Green_font_prefix}2.${Font_color_suffix} Uninstall LotServer
————————
 ${Green_font_prefix}3.${Font_color_suffix} Start LotServer
$(msg -bar)
 ${Green_font_prefix}4.${Font_color_suffix} Stop LotServer
$(msg -bar)
 ${Green_font_prefix}5.${Font_color_suffix} Restart LotServer
$(msg -bar)
 ${Green_font_prefix}6.${Font_color_suffix} Check LotServer Status
${BARRA1}
 
 Note: Sharp and LotServer cannot be installed/started at the same time"
msg -bar

	stty erase '^H' && read -p "(Default: Cancel):" lotserver_num
	[[ -z "${lotserver_num}" ]] && echo "Cancelled ..." && exit 1
	if [[ ${lotserver_num} == "1" ]]; then
		Install_LotServer
	elif [[ ${lotserver_num} == "2" ]]; then
		LotServer_installation_status
		Uninstall_LotServer
	elif [[ ${lotserver_num} == "3" ]]; then
		LotServer_installation_status
		${LotServer_file} start
		${LotServer_file} status
	elif [[ ${lotserver_num} == "4" ]]; then
		LotServer_installation_status
		${LotServer_file} stop
	elif [[ ${lotserver_num} == "5" ]]; then
		LotServer_installation_status
		${LotServer_file} restart
		${LotServer_file} status
	elif [[ ${lotserver_num} == "6" ]]; then
		LotServer_installation_status
		${LotServer_file} status
	else
		echo -e "${Error} please number(1-6)" && exit 1
	fi
}
Install_LotServer(){
	[[ -e ${LotServer_file} ]] && echo -e "${Error} LotServer is installed!" && exit 1
	#Github: https://github.com/0oVicero0/serverSpeeder_Install
	wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh"
	[[ ! -e "/tmp/appex.sh" ]] && echo -e "${Error} LotServer installation script download failed!" && exit 1
	bash /tmp/appex.sh 'install'
	sleep 2s
	PID=`ps -ef |grep -v grep |grep "appex" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		echo -e "${Info} LotServer installation is completed!" && exit 1
	else
		echo -e "${Error} LotServer installation failed!" && exit 1
	fi
}
Uninstall_LotServer(){
clear
msg -bar
	echo "Uninstall To uninstall LotServer[y/N]" && echo
msg -bar
	stty erase '^H' && read -p "(Default: n):" unyn
msg -bar
	[[ -z ${unyn} ]] && echo && echo "Cancelled ..." && exit 1
	if [[ ${unyn} == [Yy] ]]; then
		wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh" && bash /tmp/appex.sh 'uninstall'
		echo && echo "LotServer uninstall is complete!" && echo
	fi
}
# BBR
Configure_BBR(){
clear
msg -bar
 echo -e "  What are you going to do?
$(msg -bar)	
 ${Green_font_prefix}1.${Font_color_suffix} Install BBR
————————
${Green_font_prefix}2.${Font_color_suffix} Start BBR
${Green_font_prefix}3.${Font_color_suffix} Stop to BBR
${Green_font_prefix}4.${Font_color_suffix} Check the status of BBR"
msg -bar
echo -e "${Green_font_prefix} [Please pay attention before installation] ${Font_color_suffix}
$(msg -bar)
1. Open BBR, replace, there is a replacement error (after reboot)
2. This script is only compatible with Debian / Ubuntu replacement kernels. OpenVZ and Docker do not support kernel replacement.
3. Debian replace kernel process [Do you want to finish uninstall kernel], select ${Green_font_prefix} NO ${Font_color_suffix}"
	stty erase '^H' && read -p "(Default: Cancel):" bbr_num
msg -bar
	[[ -z "${bbr_num}" ]] && echo -e "Cancelled ...\n$(msg -bar)" && exit 1
	if [[ ${bbr_num} == "1" ]]; then
		Install_BBR
	elif [[ ${bbr_num} == "2" ]]; then
		Start_BBR
	elif [[ ${bbr_num} == "3" ]]; then
		Stop_BBR
	elif [[ ${bbr_num} == "4" ]]; then
		Status_BBR
	else
		echo -e "${Error} please number (1-4)" && exit 1
	fi
}
Install_BBR(){
	[[ ${release} = "centos" ]] && echo -e "${Error} This CentOS system installation script. BBR !" && exit 1
	BBR_installation_status
	bash "${BBR_file}"
}
Start_BBR(){
	BBR_installation_status
	bash "${BBR_file}" start
}
Stop_BBR(){
	BBR_installation_status
	bash "${BBR_file}" stop
}
Status_BBR(){
	BBR_installation_status
	bash "${BBR_file}" status
}
BackUP_ssrr(){
clear
msg -bar
msg -ama "$(fun_trans "SS-SSRR BACKUP TOOL -BETA")"
msg -bar
msg -azu "CREATING BACKUP" "RESTORING BACKUP"
msg -bar
rm -rf /root/mudb.json > /dev/null 2>&1
cp /usr/local/shadowsocksr/mudb.json /root/mudb.json > /dev/null 2>&1
msg -azu "$(fun_trans "Procedure Done Successfully, Saved in:")"
echo -e "\033[1;31mBACKUP > [\033[1;32m/root/mudb.json\033[1;31m]"
msg -bar
}
RestaurarBackUp_ssrr(){
clear
msg -bar
msg -ama "$(fun_trans "SS-SSRR -BETA RESTORATION TOOL")"
msg -bar
msg -azu "Remember to have at least one account already created"
msg -azu "Copy the mudb.json file to the /root folder"
read -p "     ►► Press enter to continue ◄◄"
msg -bar
msg -azu "$(fun_trans "Procedure Done Successfully")"
read -p "  ►► Press enter to Restart SSRR Panel ◄◄"
msg -bar
mv /root/mudb.json /usr/local/shadowsocksr/mudb.json
Restart_SSR
msg -bar
}

# Otros
Other_functions(){
clear
msg -bar
	echo && echo -e "  what are you going to do?
$(msg -bar)
  ${Green_font_prefix}1.${Font_color_suffix} Configure BBR
  ${Green_font_prefix}2.${Font_color_suffix} Setup speed (ServerSpeeder)
  ${Green_font_prefix}3.${Font_color_suffix} Configure LotServer (Rising Parent)
  ${Tip} Sharp / LotServer / BBR no es compatible con OpenVZ!
  ${Tip} Speed ​​and LotServer cannot coexist!
————————————
  ${Green_font_prefix}4.${Font_color_suffix} BT/PT/SPAM lock key (iptables)
  ${Green_font_prefix}5.${Font_color_suffix} BT/PT/SPAM unlock key (iptables)
————————————
  ${Green_font_prefix}6.${Font_color_suffix} Change ShadowsocksR log output mode
  —— low or verbose mode..
  ${Green_font_prefix}7.${Font_color_suffix} Monitor ShadowsocksR server execution status
  —— NOTE: This function is suitable for the SSR server to end regular processes. Once this function is enabled, it will be detected every minute. When the process does not exist, the SSR server starts automatically.
———————————— 
 ${Green_font_prefix}8.${Font_color_suffix} Backup SSRR
 ${Green_font_prefix}9.${Font_color_suffix} Restore Backup" && echo
msg -bar
	stty erase '^H' && read -p "(Default: cancel):" other_num
	[[ -z "${other_num}" ]] && echo -e "Cancelled ...\n$(msg -bar)" && exit 1
	if [[ ${other_num} == "1" ]]; then
		Configure_BBR
	elif [[ ${other_num} == "2" ]]; then
		Configure_Server_Speeder
	elif [[ ${other_num} == "3" ]]; then
		Configure_LotServer
	elif [[ ${other_num} == "4" ]]; then
		BanBTPTSPAM
	elif [[ ${other_num} == "5" ]]; then
		UnBanBTPTSPAM
	elif [[ ${other_num} == "6" ]]; then
		Set_config_connect_verbose_info
	elif [[ ${other_num} == "7" ]]; then
		Set_crontab_monitor_ssr
	elif [[ ${other_num} == "8" ]]; then
		BackUP_ssrr
	elif [[ ${other_num} == "9" ]]; then
		RestaurarBackUp_ssrr
	else
		echo -e "${Error} please number [1-9]" && exit 1
	fi

}
#Prohibido�BT PT SPAM
BanBTPTSPAM(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ban_iptables.sh && chmod +x ban_iptables.sh && bash ban_iptables.sh banall
	rm -rf ban_iptables.sh
}
#Desbloquear BT PT SPAM
UnBanBTPTSPAM(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ban_iptables.sh && chmod +x ban_iptables.sh && bash ban_iptables.sh unbanall
	rm -rf ban_iptables.sh
}
Set_config_connect_verbose_info(){
clear
msg -bar
	SSR_installation_status
	[[ ! -e ${jq_file} ]] && echo -e "${Error} JQ parser No, please check!" && exit 1
	connect_verbose_info=`${jq_file} '.connect_verbose_info' ${config_user_file}`
	if [[ ${connect_verbose_info} = "0" ]]; then
		echo && echo -e "Modo de registro actual: ${Green_font_prefix}Error log in simple mode${Font_color_suffix}"
msg -bar
		echo -e "yes to change to ${Green_font_prefix}Verbose mode (connection log, error log)${Font_color_suffix}？[y/N]"
msg -bar
		stty erase '^H' && read -p "(Default: n):" connect_verbose_info_ny
		[[ -z "${connect_verbose_info_ny}" ]] && connect_verbose_info_ny="n"
		if [[ ${connect_verbose_info_ny} == [Yy] ]]; then
			ssr_connect_verbose_info="1"
			Modify_config_connect_verbose_info
			Restart_SSR
		else
			echo && echo "	Cancelled ..." && echo
		fi
	else
		echo && echo -e "Current Registry mode: ${Green_font_prefix}Verbose mode (connection connection + error log)${Font_color_suffix}"
msg -bar
		echo -e "yes to change to ${Green_font_prefix}simple mode ${Font_color_suffix}?[y/N]"
		stty erase '^H' && read -p "(Default: n):" connect_verbose_info_ny
		[[ -z "${connect_verbose_info_ny}" ]] && connect_verbose_info_ny="n"
		if [[ ${connect_verbose_info_ny} == [Yy] ]]; then
			ssr_connect_verbose_info="0"
			Modify_config_connect_verbose_info
			Restart_SSR
		else
			echo && echo "	Cancelled ..." && echo
		fi
	fi
}
Set_crontab_monitor_ssr(){
clear
msg -bar
	SSR_installation_status
	crontab_monitor_ssr_status=$(crontab -l|grep "ssrmu.sh monitor")
	if [[ -z "${crontab_monitor_ssr_status}" ]]; then
		echo && echo -e "Current monitoring mode: ${Green_font_prefix}not monitored${Font_color_suffix}"
msg -bar
		echo -e "ok to open ${Green_font_prefix}ShadowsocksR server running health monitoring${Font_color_suffix} Function? (When the process R side SSR R)[Y/n]"
msg -bar
		stty erase '^H' && read -p "(Default: y):" crontab_monitor_ssr_status_ny
		[[ -z "${crontab_monitor_ssr_status_ny}" ]] && crontab_monitor_ssr_status_ny="y"
		if [[ ${crontab_monitor_ssr_status_ny} == [Yy] ]]; then
			crontab_monitor_ssr_cron_start
		else
			echo && echo "	Cancelled ..." && echo
		fi
	else
		echo && echo -e "Current monitoring mode: ${Green_font_prefix}Opened${Font_color_suffix}"
msg -bar
		echo -e "ok to erase ${Green_font_prefix}ShadowsocksR server running health monitoring${Font_color_suffix} Function? (process SSR server)[y/N]"
msg -bar
		stty erase '^H' && read -p "(Default: n):" crontab_monitor_ssr_status_ny
		[[ -z "${crontab_monitor_ssr_status_ny}" ]] && crontab_monitor_ssr_status_ny="n"
		if [[ ${crontab_monitor_ssr_status_ny} == [Yy] ]]; then
			crontab_monitor_ssr_cron_stop
		else
			echo && echo "	Cancelled ..." && echo
		fi
	fi
}
crontab_monitor_ssr(){
	SSR_installation_status
	check_pid
	if [[ -z ${PID} ]]; then
		echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Detected that the ShadowsocksR server is not started, start..." | tee -a ${ssr_log_file}
		/etc/init.d/ssrmu start
		sleep 1s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Failed to start ShadowsocksR server..." | tee -a ${ssr_log_file} && exit 1
		else
			echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] ShadowsocksR server startup start..." | tee -a ${ssr_log_file} && exit 1
		fi
	else
		echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] The ShadowsocksR server process is running normally..." exit 0
	fi
}
crontab_monitor_ssr_cron_start(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrmu.sh monitor/d" "$file/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file/ssrmu.sh monitor" >> "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrmu.sh monitor")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} ShadowsocksR server startup failed!" && exit 1
	else
		echo -e "${Info} ShadowsocksR server is running health monitoring successfully!"
	fi
}
crontab_monitor_ssr_cron_stop(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrmu.sh monitor/d" "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrmu.sh monitor")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Failed to stop ShadowsocksR server!" && exit 1
	else
		echo -e "${Info} ShadowsocksR server execution status monitoring stops correctly!"
	fi
}
Update_Shell(){
clear
msg -bar
	echo -e "The current version [ ${sh_ver} ], Start detecting the latest version ..."
	sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/hybtoy/ssrrmu/master/ssrrmu.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/hybtoy/ssrrmu/master/ssrrmu.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} latest detected version !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "discover new version[ ${sh_new_ver} ], It's updated?[Y/n]"
msg -bar
		stty erase '^H' && read -p "(Default: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			cd "${file}"
			if [[ $sh_new_type == "github" ]]; then
				wget -N --no-check-certificate https://raw.githubusercontent.com/hybtoy/ssrrmu/master/ssrrmu.sh && chmod +x ssrrmu.sh
			fi
			echo -e "The script has been updated to the latest version.[ ${sh_new_ver} ] !"
		else
			echo && echo "	Cancelled ..." && echo
		fi
	else
		echo -e "It is currently the latest version.[ ${sh_new_ver} ] !"
	fi
	exit 0

}
# Mostrar el estado del menu
menu_status(){
msg -bar
	if [[ -e ${ssr_folder} ]]; then
		check_pid
		if [[ ! -z "${PID}" ]]; then
			 echo -e "         VPS-AGN By @KhaledAGN\n Actual state: ${Green_font_prefix}installed${Font_color_suffix} and ${Green_font_prefix}Initiated${Font_color_suffix}"
		else
			echo -e " Actual state: ${Green_font_prefix}installed${Font_color_suffix} but ${Red_font_prefix}did not start${Font_color_suffix}"
		fi
		cd "${ssr_folder}"
	else
		echo -e " Actual state: ${Red_font_prefix}Not installed${Font_color_suffix}"
	fi
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} the script is not compatible with the current system ${release} !" && exit 1
action=$1
if [[ "${action}" == "clearall" ]]; then
	Clear_transfer_all
elif [[ "${action}" == "monitor" ]]; then
	crontab_monitor_ssr
else

echo -e "$(msg -tit) " 
echo -e "        ShadowSock-R Controller  ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
$(msg -bar)
  ${Green_font_prefix}1.${Font_color_suffix} Install ShadowsocksR 
  ${Green_font_prefix}2.${Font_color_suffix} Update ShadowsocksR
  ${Green_font_prefix}3.${Font_color_suffix} Uninstall ShadowsocksR
  ${Green_font_prefix}4.${Font_color_suffix} Install libsodium (chacha20)
—————————————
  ${Green_font_prefix}5.${Font_color_suffix} Check account information
  ${Green_font_prefix}6.${Font_color_suffix} Show connection information 
  ${Green_font_prefix}7.${Font_color_suffix} Add/Modify/Delete user settings  
  ${Green_font_prefix}8.${Font_color_suffix} Manually modify user settings
  ${Green_font_prefix}9.${Font_color_suffix} Delete used traffic  
——————————————
 ${Green_font_prefix}10.${Font_color_suffix} Start ShadowsocksR
 ${Green_font_prefix}11.${Font_color_suffix} Stop ShadowsocksR
 ${Green_font_prefix}12.${Font_color_suffix} Restart ShadowsocksR
 ${Green_font_prefix}13.${Font_color_suffix} Check ShadowsocksR Registry
—————————————
 ${Green_font_prefix}14.${Font_color_suffix} Other Features
 ${Green_font_prefix}15.${Font_color_suffix} Update Script 
$(msg -bar)
 ${Green_font_prefix}16.${Font_color_suffix}${Red_font_prefix} EXIT"
	
	menu_status
	msg -bar
    stty erase '^H' && read -p "Please select an option [1-16]:" num
	msg -bar
case "$num" in
	1)
	Install_SSR
	;;
	2)
	Update_SSR
	;;
	3)
	Uninstall_SSR
	;;
	4)
	Install_Libsodium
	;;
	5)
	View_User
	;;
	6)
	View_user_connection_info
	;;
	7)
	Modify_Config
	;;
	8)
	Manually_Modify_Config
	;;
	9)
	Clear_transfer
	;;
	10)
	Start_SSR
	;;
	11)
	Stop_SSR
	;;
	12)
	Restart_SSR
	;;
	13)
	View_Log
	;;
	14)
	Other_functions
	;;
	15)
	Update_Shell
	;;
     16)
     exit 1
      ;;
	*)
	echo -e "${Error} Please use numbers from [1-16]"
	msg -bar
	;;
esac
fi