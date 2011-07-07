DB_USER=befdata-prod
DB_NAME=staging_befchina

APP_ROOT=/var/www/staging/china
PATH_TO_BACKUP=/var/www/production/backups

echo "Backup of production database and files..."
/var/www/production/china/ext/database-and-file-backup.sh



echo "Importing Database to staging environment ..."
dropdb ${DB_NAME}
createdb ${DB_NAME}
psql -f ${PATH_TO_BACKUP}/production_befchina-`date +%Y%m%d-`*.sql ${DB_NAME}

echo "untaring files to staging environment ..."
cd $APP_ROOT
tar xfvz ${PATH_TO_BACKUP}/production_befchina-`date +%Y%m%d-`*-files.tgz
