#!/bin/bash

ROOT=$PWD/../..
BACKUP_FOLDER=$ROOT/backup

export RAILS_ENV=staging
export RUBYOPT=

SUFFIX=`date +%Y%m%d-%H%M`
DB_USER=seifarth
DB_NAME=befchina-staging

echo "Used Ruby = `which ruby`"

pushd $ROOT
  echo "Backup database"
  if [ ! -d $BACKUP_FOLDER ]; then mkdir $BACKUP_FOLDER; fi

  pg_dump -U ${DB_USER} --password ${DB_NAME} > $BACKUP_FOLDER/${DB_NAME}-${SUFFIX}.sql
  tar -czf $BACKUP_FOLDER/${DB_NAME}-${SUFFIX}-files.tgz $ROOT/files/*

popd
