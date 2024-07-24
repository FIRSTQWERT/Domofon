#!/bin/bash

user=admin
password=admin
otvet_file=./res/ip_list
nets_file=nets.txt
log_file=./res/log
backup_dir=./backup/$(date '+%Y_%m_%d_%H%M')
password_file=./passwords.txt
number_of_connection=0





touch $log_file
> $otvet_file
mkdir $backup_dir


for file in /backup/likegeeks/*
do
if [ -d "$file" ]
then
echo "$file is a directory"
elif [ -f "$file" ]
then
echo "$file is a file"
fi
done






while read LINE; do

#if [[ "$LINE" == *"#"* ]] ; then
#LINE=$(cut -d '#' -f 2)
#backup_dir_addr=$backup_dir/$LINE
#mkdir $backup_dir_addr


        if [[ "$LINE" == *"172"* ]] ; then
                Result=$(echo "$LINE" | cut -d '.' -f 1,2,3)
                for (( i=1; i <= 254; i++ ))
                do
                current_ip=$(echo "$Result.$i")
                echo "Trying connect to $current_ip"
                result_curl=$(curl --connect-timeout 3 --anyauth -X GET -u $user:$password "http://$current_ip/cgi-bin/configManager.cgi?action=getConfig&name=DeviceInfo.Serial" )

                        if [[ "$result_curl" == *"VTO"* ]] ; then
                        echo "Connection to $current_ip sucsess"
                        ((number_of_connection++))
                        echo "$current_ip:$result_curl" >> $otvet_file
                        curl --anyauth -X GET -u $user:$password "http://$current_ip/cgi-bin/recordFinder.cgi?action=find&name=AccessControlCard" > $backup_dir/$current_ip.bkp
                        fi

                        if [[ "$result_curl" == *"Invalid Authority"* ]] ; then
                        echo "Invalid Authority"
                                while read LINE; do
                                        result_curl=$(curl --connect-timeout 3 --anyauth -X GET -u $user:$LINE "http://$current_ip/cgi-bin/configManager.cgi?action=getConfig&name=DeviceInfo.Serial" )
                                        echo "Trying new password = $LINE"

                                        if [[ "$result_curl" == *"VTO"* ]] ; then
                                                echo "New password = $LINE Matches!!!"
                                                ((number_of_connection++))
                                                echo "$current_ip:$result_curl" >> $otvet_file
                                                curl --anyauth -X GET -u $user:$LINE "http://$current_ip/cgi-bin/recordFinder.cgi?action=find&name=AccessControlCard" > $backup_dir/$current_ip.bkp
                                        break;
                                        fi

                                done < $password_file
                        fi
                done
        fi

done < $nets_file
echo "Found $number_of_connection panels"

