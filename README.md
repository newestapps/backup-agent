# Newestapps Backup Agent

A tool to add to a cronjob, that makes dump of your database and every file or directory you want on your server, zip them, and save in your AWS S3 Storage.

## Dependencies

- AWS Cli ( see [AWS Cli installation instructions](http://docs.aws.amazon.com/cli/latest/userguide/installing.html))
- Zip support
- Unzip support
- A mysql user (see section "Mysql Configuration")

Your AWS CLI should be already configured with `aws configure`, but, in the first launch of *nw-backup.sh* script it'll prompt for your AWS S3 credentials, and save it, to a different file. So, the backup agent can use a different credential just for S3 Storage.

## Installation

Run the install script in your server, to create the right user and initial folders.

```
wget https://raw.githubusercontent.com/newestapps/backup-agent/master/src/install.sh -q -O - | bash
```

This will create a user called `nw-backup` and his home folder is */home/nw-backup*.

To create backup strategies, just go to the directory `/home/nw-backup/groups`, and create a new folder with the desired name (everything inside this directory will be in the final backup file in your s3 storage), it'll be used for all backup process, including the database name ( see in *Configuration* section, to learn how to change the database name for dump, and other configs )

 *Note:* You can create symbolic links to your files and directories in your server, the final backup will get all this real files (not only the symlink)

## Mysql Configuration

We only need a user with sufficient permissions in your mysql server. Create the user below:

```sql
CREATE USER 'nw_backup'@'localhost' IDENTIFIED BY 'KkH67cBjb2s8QeQQng498ynqan9HFBcQJsRTK2kkkDAeiYyCZ8';
GRANT SELECT,SHOW VIEW,TRIGGER,LOCK TABLES,RELOAD,FILE ON *.* to 'nw_backup'@'localhost';
FLUSH PRIVILEGES;
```

This statements will create a user called `nw_backup` with limited access via *localhost*, with a generic password, privileges only to perform dumps of your databases, and access to all databases in your server (of course, you can change it, and apply your own rules and privileges, but, the name of the user must me `nw_backup` and the password, if you want to change, you have to change also in the `nw-backup.sh` file, and look for *NWB_KEY*)

## Configuration

For each group, you can provide some different configs, like, other database name for a group. To do this, follow the steps:

1. Create a new file inside your group directory (like /home/nw-backup/groups/myGroup), called `config.nw` (this file will be ignored in your final backup file)
2. Open the editor of your preference and add the desired specific config (like variables.  ex.  "NAME=VALUE")

Currently, are only available this configs for individual groups:

| Config | Meaning |
|-------|---------|
| `_NWB_DATABASE_NAME` | Define here the name of your database, it'll be the name of your dump file also |
| `_NWB_DATABASE_SUFFIX` | A suffix for the filename of your database's dump sql, you can add here some expression, like the current year and month, to keep a monthly backup of your database's dump |
