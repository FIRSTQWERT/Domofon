#!/bin/bash

user=admin
password=admin
ip_file=beward.txt
log_file=./res/log
backup_dir=./backup/BEWARD/$(date '+%Y_%m_%d_%H%M')
number_of_connection=0
panels_in_list=0

printf " === Beward backup Start time " | tee -a  $log_file
date | tee -a  $log_file

mkdir $backup_dir

while read LINE; do
        printf " Trying connect to $LINE "
        model=$(curl --max-time 30 --connect-timeout 10 -s -X GET --anyauth -u $user:$password "http://$LINE/cgi-bin/systeminfo_cgi?action=get")


        if [[ "$model" == *"DKS850174"* ]] ; then

                printf "DKS850174 "
                ((number_of_connection++))
		
		curl --max-time 120 --connect-timeout 10 -s -X GET --anyauth -u $user:$password "http://$LINE/cgi-bin/rfid_cgi?action=list" > $backup_dir/$LINE.keys
                curl --max-time 120 --connect-timeout 10 -s -X GET --anyauth -u $user:$password "http://$LINE/cgi-bin/apartment_cgi?action=list" > $backup_dir/$LINE.flats
		curl --max-time 120 --connect-timeout 10 -s -X GET --anyauth -u $user:$password "http://$LINE/cgi-bin/intercom_cgi?action=get" > $backup_dir/$LINE.code	
		printf "OK\n"

        elif [[ "$model" == *"DKS151"* ]] ; then
                printf "DKS151XX "
		((number_of_connection++))
                curl --max-time 120 --connect-timeout 10 -s -X GET --anyauth -u $user:$password "http://$LINE/cgi-bin/apartment_cgi?action=list" > $backup_dir/$LINE.flats
		curl --max-time 120 --connect-timeout 10 -s -X GET --anyauth -u $user:$password "http://$LINE/cgi-bin/mifare_cgi?action=list" > $backup_dir/$LINE.keys.zip
                curl --max-time 120 --connect-timeout 10 -s -X GET --anyauth -u $user:$password "http://$LINE/cgi-bin/intercom_cgi?action=get" > $backup_dir/$LINE.code
		printf "OK\n"

	else
		printf "ERROR\n"

        fi

        ((panels_in_list++))

done < $ip_file

printf "\n***Found $number_of_connection BEWARD panels of $panels_in_list total***\n" | tee -a $log_file
printf " Backup save to $backup_dir \n" | tee -a $log_file
printf " End on " >> $log_file
date >> $log_file
printf "\n=======================================================\n" >> $log_file

