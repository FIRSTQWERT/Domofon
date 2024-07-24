#!/bin/bash

user=admin
password=admin
password_beward=admin
otvet_file=./res/ip_list_$(date '+%Y_%m_%d_%H%M')
nets_file=nets.txt
log_file=./res/log
backup_dir=./backup/TRUE_IP/$(date '+%Y_%m_%d_%H%M')
password_file=./passwords.txt
number_of_connection=0

printf " TRUE-IP backup start time " >> $log_file
date >> $log_file

> $otvet_file
mkdir $backup_dir

while read LINE; do

        if [[ "$LINE" == *"172"* ]] ; then
                Result=$(echo "$LINE" | cut -d '.' -f 1,2,3)
                for (( i=2; i <= 254; i++ ))
                do
                current_ip=$(echo "$Result.$i")
                printf "Trying connect to $current_ip \n"
                result_curl=$(curl -s --max-time 120 --connect-timeout 3 --anyauth -X GET -u $user:$password "http://$current_ip/cgi-bin/configManager.cgi?action=getConfig&name=DeviceInfo.Serial" )

                        if [[ "$result_curl" == *"VTO"* ]] ; then
                        	printf "Connection to $current_ip sucsess\n"
                        	((number_of_connection++))
                                curl -s --max-time 120 --connect-timeout 3  --anyauth -X GET -u $user:$password "http://$current_ip/cgi-bin/recordFinder.cgi?action=find&name=AccessControlCard" > $backup_dir/$current_ip.bkp
                        fi

                        if [[ "$result_curl" == *"Invalid Authority"* || "$result_curl" == *"Unautorized"* ]] ; then
                        printf "Invalid Authority\n"
                                while read LINE; do
                                        result_curl=$(curl -s --max-time 120 --connect-timeout 3 --anyauth -X GET -u $user:$LINE "http://$current_ip/cgi-bin/configManager.cgi?action=getConfig&name=DeviceInfo.Serial" )
                                        printf "Trying new password = $LINE \n"

                                        if [[ "$result_curl" == *"VTO"* ]] ; then
                                                printf "New password = $LINE Matches!!! \n"
                                                ((number_of_connection++))
                                                printf "$current_ip:$result_curl\n" >> $otvet_file
                                                curl -s --max-time 120 --connect-timeout 3  --anyauth -X GET -u $user:$LINE "http://$current_ip/cgi-bin/recordFinder.cgi?action=find&name=AccessControlCard" > $backup_dir/$current_ip.bkp
                                        break;
                                        fi

                                done < $password_file
                        fi
                done
        fi

done < $nets_file

printf "\n***Found $number_of_connection panels***\n" | tee -a $otvet_file $log_file
printf " Backup save to $backup_dir \n" | tee -a $otvet_file $log_file
printf " End on " >> $log_file
date >> $log_file
printf "\n=======================================================\n" >> $log_file
