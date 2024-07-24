#!/bin/bash

user=admin
basip_file=basip_ip.txt
log_file=./res/log
backup_dir=./backup/BASIP/$(date '+%Y_%m_%d_%H%M')
number_of_connection=0
panels_in_list=0

printf " === BAS-IP backup Start time " | tee -a  $log_file
date | tee -a  $log_file

mkdir $backup_dir

while read LINE; do
	password=123
        printf " Trying connect to $LINE "
	token=$(curl -s --max-time 30 --connect-timeout 10 --anyauth  -X GET "http://$LINE/api/v1/login?username=admin&password=$password") # | grep -o '"token":"[^"]*' | grep -o '[^"]*$')

	if [[ "$token" == *"error"* ]] ; then

                printf "Wrong password! Trying another password "
                password=456
                token=$(curl -s --max-time 30 --connect-timeout 10 --anyauth  -X GET "http://$LINE/api/v1/login?username=admin&password=$password" | grep -o '"token":"[^"]*' | grep -o '[^"]*$')

	else
		token=$(echo $token | grep -o '"token":"[^"]*' | grep -o '[^"]*$')
	fi

	if [[ $token ]] ; then

		printf "Token: $token "
        	((number_of_connection++))
		curl --max-time 300 --connect-timeout 10 -s -L -X GET "http://$LINE/api/v1/system/settings/tables" -H "Accept: application/json" -H "Authorization: Bearer $token" > $backup_dir/$LINE.zip
                curl --max-time 300 --connect-timeout 10 -s -L -X GET "http://$LINE/api/v1/system/settings/backup/all" -H "Accept: application/json" -H "Authorization: Bearer $token" > $backup_dir/$LINE.general.zip
		printf "OK\n"

	else
		printf "Could not connect!!!\n"
	fi

	((panels_in_list++))

done < $basip_file

printf "\n***Found $number_of_connection BAS-IP panels of $panels_in_list total***\n" | tee -a $log_file
printf " Backup save to $backup_dir \n" | tee -a  $log_file
printf " End on " >> $log_file
date >> $log_file
printf "\n=======================================================\n" >> $log_file
