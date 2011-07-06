#!/bin/bash

ROOT=$PWD/..
BACKUP_FOLDER=$ROOT/backup

export RAILS_ENV=staging

SUFFIX=`date +%Y%m%d-%H%M`
DB_USER=database_dumper
DB_NAME=befchina-staging

echo "PostgreSQl Version  = `psql --version`"
echo "PostgreSQL Dumper Version = `pg_dump --version`"

pushd $ROOT
  if [ ! -d $BACKUP_FOLDER ]; then mkdir $BACKUP_FOLDER; fi
  echo "Backup database"
  pg_dump -U ${DB_USER} -W ${DB_NAME} > $BACKUP_FOLDER/${DB_NAME}-${SUFFIX}.sql
  echo "Backup files"
  tar -czf $BACKUP_FOLDER/${DB_NAME}-${SUFFIX}-files.tgz $ROOT/files/* $ROOT/public/images/user_avatars/* 

popd
