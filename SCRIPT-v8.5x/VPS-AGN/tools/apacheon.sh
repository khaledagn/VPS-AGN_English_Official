#!/bin/bash
#26/01/2021
clear
clear
declare -A cor=([0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m")
SCPdir="/etc/VPS-AGN" && [[ ! -d ${SCPdir} ]] && exit 1
SCPusr="${SCPdir}/controller" && [[ ! -d ${SCPusr} ]] && mkdir ${SCPusr}
SCPfrm="${SCPdir}/tools" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
SCPinst="${SCPdir}/protocols" && [[ ! -d ${SCPfrm} ]] && mkdir ${SCPfrm}
fun_ip() {
	MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
	MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
	[[ "$MEU_IP" != "$MEU_IP2" ]] && echo "$MEU_IP2" || echo "$MEU_IP"
}
IP="$(fun_ip)"
msg -bar
msg -tit
echo -e "\033[1;96m           File Manager FTP VPS•AGN"
msg -bar
echo -e "${cor[4]} [1] >${cor[3]} $(fun_trans "Place File Online")"
echo -e "${cor[4]} [2] >${cor[3]} $(fun_trans "Online File Remover")"
echo -e "${cor[4]} [3] >${cor[3]} $(fun_trans "View Online File Links")"
msg -bar
while [[ ${arquivoonlineadm} != @([1-3]) ]]; do
	read -p "[1-3]: " arquivoonlineadm
	tput cuu1 && tput dl1
done
case ${arquivoonlineadm} in
3)
	[[ -z $(ls /var/www/html) ]] && echo -e "$barra" || {
		for my_arqs in $(ls /var/www/html); do
			[[ "$my_arqs" = "index.html" ]] && continue
			[[ "$my_arqs" = "index.php" ]] && continue
			[[ -d "$my_arqs" ]] && continue
			echo -e "\033[1;31m[$my_arqs] \033[1;36mhttp://$IP:81/$my_arqs\033[0m"
		done
		msg -bar
	}
	;;
2)
	i=1
	[[ -z $(ls /var/www/html) ]] && echo -e "$barra" || {
		for my_arqs in $(ls /var/www/html); do
			[[ "$my_arqs" = "index.html" ]] && continue
			[[ "$my_arqs" = "index.php" ]] && continue
			[[ -d "$my_arqs" ]] && continue
			select_arc[$i]="$my_arqs"
			echo -e "${cor[2]}[$i] > ${cor[3]}$my_arqs - \033[1;36mhttp://$IP:81/$my_arqs\033[0m"
			let i++
		done
		msg -bar
		echo -e "${cor[5]}$(fun_trans "Select the file you want to delete")"
		msg -bar
		while [[ -z ${select_arc[$slct]} ]]; do
			read -p " [1-$i]: " slct
			tput cuu1 && tput dl1
		done
		arquivo_move="${select_arc[$slct]}"
		[[ -d /var/www/html ]] && [[ -e /var/www/html/$arquivo_move ]] && rm -rf /var/www/html/$arquivo_move >/dev/null 2>&1
		[[ -e /var/www/$arquivo_move ]] && rm -rf /var/www/$arquivo_move >/dev/null 2>&1
		echo -e "${cor[5]}$(fun_trans "Success!")"
		msg -bar
	}
	;;
1)
	i="1"
	[[ -z $(ls $HOME) ]] && echo -e "$barra" || {
		for my_arqs in $(ls $HOME); do
			[[ -d "$my_arqs" ]] && continue
			select_arc[$i]="$my_arqs"
			echo -e "${cor[2]} [$i] > ${cor[3]}$my_arqs"
			let i++
		done
		i=$(($i - 1))
		msg -bar
		echo -e "${cor[5]}$(fun_trans "Select the file")"
		msg -bar
		while [[ -z ${select_arc[$slct]} ]]; do
			read -p " [1-$i]: " slct
			tput cuu1 && tput dl1
		done
		arquivo_move="${select_arc[$slct]}"
		[ ! -d /var ] && mkdir /var
		[ ! -d /var/www ] && mkdir /var/www
		[ ! -d /var/www/html ] && mkdir /var/www/html
		[ ! -e /var/www/html/index.html ] && touch /var/www/html/index.html
		[ ! -e /var/www/index.html ] && touch /var/www/index.html
		chmod -R 755 /var/www
		cp $HOME/$arquivo_move /var/www/$arquivo_move
		cp $HOME/$arquivo_move /var/www/html/$arquivo_move
		echo -e "\033[1;36m http://$IP:81/$arquivo_move\033[0m"
		msg -bar
		echo -e "${cor[5]}$(fun_trans "Success!")"
		msg -bar
	}
	;;
esac
