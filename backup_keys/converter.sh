#!/bin/bash


echo Введите имя файла : 
read filo

printf "[" > tempfile.tmp

while read LINE; 
do

	if [[ "$LINE" == *"CardNo"* ]] ; then
               
		Card=$(echo "$LINE" | cut -d '=' -f 2)
		printf "{\"CardNo\":\"$Card\"," >> tempfile.tmp
		#echo "$Card"
	fi

        if [[ "$LINE" == *"UserID"* ]] ; then

                UserID=$(echo "$LINE" | cut -d '=' -f 2)
                printf "\"UserID\":\"$UserID\"," >> tempfile.tmp
		#echo "$UserID"
        fi

        if [[ "$LINE" == *"UserName"* ]] ; then

                Name=$(echo "$LINE" | cut -d '=' -f 2)
                printf "\"UserName\":\"$Name\",\"VTOPosition\":\"\",\"CardType\":0,\"CardStatus\":0}," >> tempfile.tmp
		#echo "$Name"
        fi

done < $filo

sed -i '$ s/.$//'  ./tempfile.tmp
printf "]" >> tempfile.tmp
cat tempfile.tmp | tr -d '\r' > $filo.cadb
#mv ./tempfile.tmp ./$filo.cadb
