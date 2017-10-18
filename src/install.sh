#!/bin/bash
if [ ! -d "/home/nw-backup" ]
then
	echo -e "\e[1m Creating working user... (please provide sudo access)\e[0m"
	sudo adduser nw-backup
	sudo mkdir /home/nw-backup
	sudo chown nw-backup:nw-backup /home/nw-backup
	sudo chmod 777 /home/nw-backup
fi

su -l nw-backup
cd /home/nw-backup

if [ ! -d "groups" ]
then
  mkdir groups && chmod 777 groups
fi

wget https://raw.githubusercontent.com/newestapps/backup-agent/master/src/nw-backup.sh
chmod 777 nw-backup.sh
