#!/bin/bash
if [ ! -d "/home/nw-backup" ]
then
	echo -e "\033[1m Creating working user... (please provide sudo access)\e[0m"
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

## Check dependencies

hasZipInstalled=`command -v zip`
hasUnzipInstalled=`command -v unzip`
hasAwsCliInstalled=`command -v aws`

if [ ! -n "$hasZipInstalled" ]
then
  echo -e "\033[31;1m /!\ ZIP is not installed /!\ \033[0m"
  exit
fi

if [ ! -n "$hasUnzipInstalled" ]
then
  echo -e "\033[31;1m /!\ UNZIP is not installed /!\ \033[0m"
  exit
fi

if [ ! -n "$hasAwsCliInstalled" ]
then
  echo -e "\033[31;1m /!\ AWS CLI is not installed /!\ \033[0m"
  exit
fi

wget https://raw.githubusercontent.com/newestapps/backup-agent/master/src/nw-backup.sh -q
chmod 777 nw-backup.sh

echo -e "\033[1m Ready to go! \033[0m"
