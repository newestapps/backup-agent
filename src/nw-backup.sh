#!/bin/bash
clear;

if [ ! -d "/home/nw-backup" ]
then
	echo -e "\e[1m Creating working user... (please provide sudo access)\e[0m"
	sudo adduser nw-backup
	sudo mkdir /home/nw-backup
	sudo chown nw-backup:nw-backup /home/nw-backup
	sudo chmod 777 /home/nw-backup
fi

NWB_KEY="KkH67cBjb2s8QeQQng498ynqan9HFBcQJsRTK2kkkDAeiYyCZ8" # Just a password for our Mysql Specific user
NWB_HOME=/home/nw-backup/
NWB_CREDENTIALS_FILE=${NWB_HOME}.mysql-crendetials
NWB_GROUPS_DIR=${NWB_HOME}groups/
AWS_BUCKET_NAME='newestapps'
S3_STORAGE="s3://${AWS_BUCKET_NAME}/backups/"

awsInstallLoc=`command -v aws`
if [ ! -n "$awsInstallLoc" ]
then
        echo ''
        echo -e "\e[31;1m /!\ AWS CLI is not installed /!\ \e[0m"
        echo ''
        exit
fi

if [ ! -f "${NWB_HOME}.nw-config" ]
then
	echo -e "\e[0;30;43m                    AWS CLI Config                    \e[0m"
	echo -ne "\e[0;30;43m  \e[0;1m Key ID: \e[0m"; read AWS_ACCESS_KEY_ID;
	echo -ne "\e[0;30;43m  \e[0;1m Access Key: \e[0m"; read AWS_SECRET_ACCESS_KEY;
	echo -ne "\e[0;30;43m  \e[0;1m Default Region: \e[0m"; read AWS_DEFAULT_REGION;
	echo -e "\e[0;30;43m                                                      \e[0m"

        echo -e "\e[32m   - AWS Credentials saved to NWB config file"

	echo "export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID >> ${NWB_HOME}.nw-config
	echo "export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY >> ${NWB_HOME}.nw-config
	echo "export AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION >> ${NWB_HOME}.nw-config

fi

source "${NWB_HOME}.nw-config"

if [ ! -n "$AWS_ACCESS_KEY_ID" ]
then
        echo ''
        echo -e "\e[31;1m /!\ AWS_ACCESS_KEY_ID not defined /!\ \e[0m"
        echo ''
        exit
fi

if [ ! -n "$AWS_SECRET_ACCESS_KEY" ]
then
        echo ''
        echo -e "\e[31;1m /!\ AWS_SECRET_ACCESS_KEY not defined /!\ \e[0m"
        echo ''
        exit
fi


if [ ! -n "$AWS_DEFAULT_REGION" ]
then
        echo ''
        echo -e "\e[31;1m /!\ AWS_DEFAULT_REGION not defined /!\ \e[0m"
        echo ''
        exit
fi


echo -ne "\033[0;1m"
echo "                                                       "
echo -e " _   _                      \033[31;1m  _ \033[0;1m                       "
echo -e "| \\ | | ___\033[31;1m__      _____  ___| |_ \033[0;1m__ _ _ __  _ __  ___ "
echo -e "|  \\| |/ _ \033[31;1m\\ \\ /\\ / / _ \\/ __| __\033[0;1m/ _\` | '_ \\| '_ \\/ __|"
echo -e "| |\\  |  __/\033[31;1m\\ V  V /  __/\\__ \\ |\033[0;1m| (_| | |_) | |_) \\__ \\"
echo -e "|_| \\_|\\___| \033[31;1m\\_/\\_/ \\___||___/\\__\033[0;1m\\__,_| .__/| .__/|___/"
echo "                                      |_|   |_|        "
echo -e "\033[0;1m"
echo -e "     	   Newestapps Backup Agent - v2.0                   "
echo -e "\033[0;1m"
echo -e "\033[0m"

if [ ! -d "${NWB_HOME}.temp-backup" ]
then
	mkdir "${NWB_HOME}.temp-backup" && chmod 777 "${NWB_HOME}.temp-backup"
fi

if [ ! -d "${NWB_GROUPS_DIR}" ]
then
	mkdir "${NWB_GROUPS_DIR}" && chmod 777 "${NWB_GROUPS_DIR}"
fi

## Creates the mysql credentials file
if [ ! -f "${NWB_CREDENTIALS_FILE}" ]
then
	echo "[client]" > ${NWB_CREDENTIALS_FILE}
	echo "user=nw_backup" >> ${NWB_CREDENTIALS_FILE}
	echo "password=${NWB_KEY}" >> ${NWB_CREDENTIALS_FILE}
fi

## Database Backups
for group in `ls ${NWB_GROUPS_DIR}`
do
	echo -e "\e[31;1m>>> Backing up data from group \e[33m\"${group}\"\e[0m";

	if [ ! -d "${NWB_HOME}.temp-backup/${group}" ]
	then
		echo -e "\e[34m   - Creating group temp backup directory \e[0m"
		mkdir "${NWB_HOME}.temp-backup/${group}"
		chmod 777 "${NWB_HOME}.temp-backup/${group}"
	else
		echo -e "\e[34m   - Using \""${NWB_HOME}.temp-backup/${group}"\" as the temp backup directory \e[0m"
	fi

	_NWB_DATABASE_NAME=$group
	_NWB_DATABASE_SUFFIX=''
	if [ -f "${NWB_GROUPS_DIR}${group}/config.nw" ]
	then
		source "${NWB_GROUPS_DIR}${group}/config.nw"
	fi

	echo -e "\e[34m   - Use \"${_NWB_DATABASE_NAME}\" as database name \e[0m"

	dumpMysqlFile=${NWB_HOME}.temp-backup/${group}/dump-${_NWB_DATABASE_NAME}${_NWB_DATABASE_SUFFIX}.sql
	mysqldump --defaults-extra-file=${NWB_CREDENTIALS_FILE} ${_NWB_DATABASE_NAME} > $dumpMysqlFile | sed -e '$!d' 2>&1

	if [ -f "$dumpMysqlFile" ]
	then
		echo -e "\e[32m   - Mysql database successfully saved!"
	else
		echo -e "\e[31m   - Error on trying to dump your database data!"
	fi

	cd ${NWB_GROUPS_DIR}${group}
	zip -r ${NWB_HOME}.temp-backup/${group}/${group}.zip ./* -x *config.nw
        echo -e "\e[34m   - Zip file: ${NWB_HOME}.temp-backup/${group}/${group}.zip \e[0m"
	cd -

	cd ${NWB_HOME}.temp-backup/${group}/
	zip -ur ${NWB_HOME}.temp-backup/${group}/${group}.zip ./dump-${_NWB_DATABASE_NAME}${_NWB_DATABASE_SUFFIX}.sql
	cd -

	unzip -l ${NWB_HOME}.temp-backup/${group}/${group}.zip > ${NWB_HOME}.temp-backup/${group}/ziplist-${group}.txt

        echo -e "\e[34m   - Uploading backup data do AWS S3 Storage \e[0m"

	aws s3 cp ${NWB_HOME}.temp-backup/${group}/${group}.zip ${S3_STORAGE}${group}/ --storage-class=STANDARD_IA
	aws s3 cp ${NWB_HOME}.temp-backup/${group}/ziplist-${group}.txt ${S3_STORAGE}${group}/ --storage-class=STANDARD_IA

        echo -e "\e[34m   - Removing local backups \e[0m"

	rm -f ${NWB_HOME}.temp-backup/${group}/${group}.zip
	rm -f ${NWB_HOME}.temp-backup/${group}/ziplist-${group}.txt
	rm -f $dumpMysqlFile

        echo -e "\e[32m   - Backup finalisado"

	echo ''

done
