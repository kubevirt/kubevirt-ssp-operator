#!/bin/bash

set -e
# careful about NOT use -x here

if [ -z "$QUAY_BOT_PASS" ] || [ -z "$QUAY_BOT_USER" ]; then
	echo "missing QUAY_BOT_{USER,PASS} env vars"
	exit 1
fi

echo "$QUAY_BOT_PASS" | docker login -u="$QUAY_BOT_USER" --password-stdin quay.io
for IMAGE in $*; do
	docker push $IMAGE
done
docker logout quay.io
