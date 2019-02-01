#!/bin/sh

REDIS_HOST="${REDIS_HOST:-vmq-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"
BACKUP_PATH="${BACKUP_PATH:-/tmp}"
PUSHGATEWAY_JOB=${PUSHGATEWAY_JOB:-vmq-redis-backup}

if [ -z "${AWS_BUCKET}" ]
then
	echo "Error! 'AWS_BUCKET' environment variable must be defined"
	exit 1
fi

if [ -z "${AWS_ACCESS_KEY_ID}" ]
then
	echo "Error! 'AWS_ACCESS_KEY_ID' environment variable must be defined"
	exit 1
fi

if [ -z "${AWS_SECRET_ACCESS_KEY}" ]
then
	echo "Error! 'AWS_SECRET_ACCESS_KEY' environment variable must be defined"
	exit 1
fi

startSeconds=$(date +%s)

currentDate=$(date +%Y-%m-%d_%H-%M-%S)
backupFilename="vmq-redis-dump-${currentDate}.rdb"

echo "Creating backup .."

if redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} --rdb "${BACKUP_PATH}/${backupFilename}"
then
	echo "Backup successfully created"
else
	echo "Backup creation failed!"
	exit 1
fi

backupSize=$(stat -c %s "${BACKUP_PATH}/${backupFilename}")

if [ ${backupSize} -eq 0 ]
then
	echo "Error! Backup file is empty"
	exit 1
fi

echo "Uploading backup to S3 .."

if aws s3 cp "${BACKUP_PATH}/${backupFilename}" s3://${AWS_BUCKET}
then
	echo "Backup successfully uploaded"
else
	echo "Backup upload failed!"
	exit 1
fi

backupDuration=$(( $(date +%s) - startSeconds ))

echo "Publishing metrics .."

if [ -z "${PUSHGATEWAY_HOST}" ]
then
	echo "Warning, 'PUSHGATEWAY_HOST' environment variable not defined, metrics cannot be published"
	exit 0
fi

cat <<EOF | curl --silent --data-binary @- ${PUSHGATEWAY_HOST}/metrics/job/${PUSHGATEWAY_JOB}
# HELP backup_db outcome of the backup database job (0=failed, 1=success).
# TYPE backup_db gauge
backup_db{label="${REDIS_HOST}"} 1
# HELP backup_duration_seconds_total duration of the script execution in seconds.
# TYPE backup_duration_seconds_total gauge
backup_duration_seconds_total{label="${REDIS_HOST}"} ${backupDuration}
# HELP backup_size size of backup in bytes.
# TYPE backup_size gauge
backup_size_bytes{label="${REDIS_HOST}"} ${backupSize}
# HELP backup_created_date_seconds created date in seconds.
# TYPE backup_created_date_seconds gauge
backup_created_date_seconds{label="${REDIS_HOST}"} ${startSeconds}
EOF

if [ ${?} -eq 0 ]
then
	echo "Metrics successfully published"
else
	echo "Metrics publish failed!"
fi
