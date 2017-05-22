#!/usr/bin/env bash

BUCKET_NAME=$1

TIMESTAMP=$(date +%F_%T | tr ':' '-')
TEMP_FILE=$(mktemp tmp.XXXXXXXXXX)
S3_FILE="s3://$BUCKET_NAME/postgres/$TIMESTAMP.sql"

docker-compose exec db pg_dumpall -l postgres -U postgres > $TEMP_FILE
s3cmd put $TEMP_FILE $S3_FILE
rm "$TEMP_FILE"