#!/bin/bash
 
###################################################
##   Script backup datebases 
##   Tùy chỉnh: DarkTuan
##   URL: https://cuuvanlongsutien.xyz
##   Cập nhật: 3/1/2020 cập nhật cơ sở dữ liệu + thông báo gửi mail khi backup xong
##   
###################################################
 
export PATH=/bin:/usr/bin:/usr/local/bin:/usr/sbin:
TODAY=`date +"%d%b%Y"`
################################################################
################## Cập nhật biến giá trị ########################
 
DB_BACKUP_PATH='/var/backups/databases'
MYSQL_HOST='localhost'
MYSQL_PORT='3306'
MYSQL_USER='darktuan'
MYSQL_PASSWORD='@Dangtuan12'
DATABASE_NAME='wordpress'
BACKUP_RETAIN_DAYS=5   ## Số ngày lưu tại server
 
#################################################################
echo "Tien hanh backup database - ${DATABASE_NAME}"


mysqldump -h ${MYSQL_HOST} \
		  -P ${MYSQL_PORT} \
		  -u ${MYSQL_USER} \
		  -p${MYSQL_PASSWORD} \
		  ${DATABASE_NAME} | gzip > ${DB_BACKUP_PATH}/${DATABASE_NAME}-${TODAY}.sql.gz

if [ $? -eq 0 ]; then
  echo "Backup thanh cong" 
  echo "Subject: ${TODAY} - Backup databases định kỳ thành công" | ssmtp bdt.tuan@gmail.com
else
  echo "Backup loi"
    echo "Subject: ${TODAY} - BACKUP ERROR" | ssmtp bdt.tuan@gmail.com
  exit 1
fi
##### Xoa ban sao luu sau {BACKUP_RETAIN_DAYS} ngay #####

DBDELDATE=`date +"%d%b%Y" --date="${BACKUP_RETAIN_DAYS} days ago"`

if [ ! -z ${DB_BACKUP_PATH} ]; then
      cd ${DB_BACKUP_PATH}
      if [ ! -z ${DBDELDATE} ] && [ -d ${DBDELDATE} ]; then
            rm -rf ${DBDELDATE}
      fi
fi
