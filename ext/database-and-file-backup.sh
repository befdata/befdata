#!/bin/bash

ROOT=/var/www/production/china
BACKUP_FOLDER=$ROOT/../backups

export RAILS_ENV=production

SUFFIX=`date +%Y%m%d-%H%M`
DB_USER=befdata-prod
DB_NAME=production_befchina

echo "PostgreSQl Version  = `psql --version`"
echo "PostgreSQL Dumper Version = `pg_dump --version`"

pushd $ROOT
  if [ ! -d $BACKUP_FOLDER ]; then mkdir $BACKUP_FOLDER; fi
  echo "Backup database"
  pg_dump -U ${DB_USER} ${DB_NAME} > $BACKUP_FOLDER/${DB_NAME}-${SUFFIX}.sql
  echo "Backup files"
  cd $ROOT
  tar -czf $BACKUP_FOLDER/${DB_NAME}-${SUFFIX}-files.tgz files/* public/images/user_avatars/* 

popd
