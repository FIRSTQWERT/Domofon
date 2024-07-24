#!/bin/bash

source ./backup_basip.sh

source ./backup_beward.sh

source ./backup_trueip.sh

printf "\n ================ END OF BACKUP SCRIPT ================\n"

tail -23 $log_file
