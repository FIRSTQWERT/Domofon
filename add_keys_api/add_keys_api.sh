#!/bin/bash

echo " <=====================Добавлятор ключей 3000=====================>"
read -e -i admin -p " ==> Введите логин: " user
read -e -i admin -p " ==> Введите пароль: " password
read -e -i keys.txt -p " ==> Введите имя файла ключей: " filo
read -p " ==> Введите адрес панели. Для вездехода используйте маску * (Пример 172.26.14.*): " ip_addr
echo " Варианты API-запроса:"
echo " [1] Beward DKS850174 'http://$ip_addr/cgi-bin/rfid_cgi?action=add&Key=$key'"
echo " [2] Beward DKS15198 'http://$ip_addr/cgi-bin/mifare_cgi?action=add&Key=$key&Type=1'"
echo " [3] True-IP TI-2400 'http://$ip_addr/cgi-bin/recordUpdater.cgi?action=insert&name=AccessControlCard&CardName=123&CardNo=$key&UserID=vezdehod&CardStatus=0&CardType=0'"
echo " [4] BAS-IP 'http://$ip_addr/api/v1/access/identifier'"
read -e -i 1 -p " ==> Выберите вариант API-запроса: " panel_type

cat $filo | tr -s '\n' > tempfile #Удаляет пустые строки

if [[ "$ip_addr" =~ [*] ]]; then
	apartment_n="9999" #Номер квартиры вездехода 9999
	read -e -i 2 -p " ==> Обнаружен вездеход, введите стартовый адрес: " vezde_start
	read -e -i 254 -p " ==> Обнаружен вездеход, введите конечный адрес: " vezde_end
	ip_addr=$(echo $ip_addr | cut -d . -f 1-3) #Отрезаем последний октет после точки
else
	read -e -i 0 -p " ==> Номер квартиры: " apartment_n
	vezde_start=$(echo $ip_addr | cut -d . -f 4) #Отрезаем первые три октета
	vezde_end=$vezde_start
	ip_addr=$(echo $ip_addr | cut -d . -f 1-3)
fi

printf " Запуск скрипта "
date +"%H:%M %d/%m/%Y"

for ((; vezde_start <= vezde_end ; vezde_start++)) do

	while read LINE; do

		key=$(echo $LINE | awk '{print $1}');
		printf " Панель $ip_addr.$vezde_start Ключ: $key Результат: "

		if [[ "$panel_type" == "1" ]]; then
			curl --connect-timeout 2 --max-time 5 -X GET -u $user:$password "http://$ip_addr.$vezde_start/cgi-bin/rfid_cgi?action=add&Key=$key&Apartment=$apartment_n"

		elif [[ "$panel_type" == "2" ]]; then
			curl --connect-timeout 2 --max-time 5 -X GET -u $user:$password "http://$ip_addr.$vezde_start/cgi-bin/mifare_cgi?action=add&Key=$key&Apartment=$apartment_n&Type=1"

		elif [[ "$panel_type" == "3" ]]; then
			curl --connect-timeout 2 --max-time 5 -X GET --anyauth -u $user:$password "http://$ip_addr.$vezde_start/cgi-bin/recordUpdater.cgi?action=insert&name=AccessControlCard&CardName=0&CardNo=$key&UserID=$apartment_n&UserName=$apartment_n&CardStatus=0&CardType=0"

		elif [[ "$panel_type" == "4" ]]; then
			key=$(echo $key | sed 's/^\(..\)/\1\-/' | sed 's/^\(.....\)/\1\-/' | sed 's/^\(........\)/\1\-/') #Костыль =)
			md5_password=$(echo -n $password | md5sum | awk '{print $1}')
                	token=$(curl -s --max-time 6 --connect-timeout 3 --anyauth -X GET "http://$ip_addr.$vezde_start/api/v1/login?username=admin&password=$md5_password" | grep -o '"token":"[^"]*' | grep -o '[^"]*$')

 			if [[ $token ]]; then
	               		data="{\"identifier_owner\": {\"name\": \"$apartment_n\",\"type\": \"owner\"},\"identifier_type\": \"card\",\"identifier_number\": \"$key\",\"lock\": \"all\"}"
				curl --max-time 6 --connect-timeout 3 -s -L -X POST "http://$ip_addr.$vezde_start/api/v1/access/identifier" -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer $token" --data "$data"
			else printf "Could not connect "

			fi

			printf "\n"	
		
		else echo "Некорректный API-запрос"

		fi

	done < tempfile

done

cat tempfile > $filo
printf " Завершение работы скрипта "
date +"%H:%M %d/%m/%Y"
printf " <================================================================>\n"
