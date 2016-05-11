#!/bin/sh

if [ -z "$5" ]; then
    echo "Usage: $0 <clair-url> <registry> <team> <artifact> <version> [user:password]" >&2
    exit 1
fi

clair_url=$1
registry=$2
team=$3
artifact=$4
version=$5
auth=$6

[ ! -z "$auth" ] && auth="-u '$auth'"

alias curl="curl -s $auth"

schema="$(curl "https://$registry/v2/$team/$artifact/manifests/$version" | jq -r '.schemaVersion')"
if [ -z "$schema" ]; then
    echo "Invalid arguments." >&2
    exit 2
fi
if [ "s$schema" != "s1" ] && [ "s$schema" != "s2" ]; then
    echo "Schema '$schema' not supported." >&2
    exit 3
fi

# a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4 is the 0-byte layer of only metadata, no need to look at it

if [ "s$schema" = "s1" ]; then
    layers=$(curl "https://$registry/v2/$team/$artifact/manifests/$version" | jq -r '.fsLayers[].blobSum' | grep -v 'a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4' | tac)
else
    layers=$(curl "https://$registry/v2/$team/$artifact/manifests/$version" | jq -r '.layers[].digest' | grep -v 'a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4')
fi
parent=
for layer in $layers; do
    echo -n "Sending layer '$layer' with parent '$parent' to Clair...   "
    curl -X POST -d '{"Layer": {"Name": "'$layer'", "ParentName": "'$parent'", "Path": "'https://$registry/v2/$team/$artifact/blobs/$layer'", "Format": "Docker"}}' -H 'Content-Type: application/json' $clair_url/v1/layers >/dev/null
    if [ $? -ne 0 ]; then
        echo "FAILED"
        exit 4
    fi

    parent=$layer
    echo "done"
done
