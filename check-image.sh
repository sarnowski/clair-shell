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

# try v1
top_layer=$(curl "https://$registry/v2/$team/$artifact/manifests/$version" | jq -r '.fsLayers[].blobSum' 2>/dev/null | grep -v 'a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4' | head -n 1)
# try v2
[ -z "$top_layer" ] && top_layer=$(curl "https://$registry/v2/$team/$artifact/manifests/$version" | jq -r '.layers[].digest' 2>/dev/null | grep -v 'a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4' | tail -n 1)

if [ -z "$top_layer" ]; then
    echo "cannot determine top layer" >&2
    exit 4
fi

curl "$clair_url/v1/layers/$top_layer?vulnerabilities" | jq -ca '.Layer.Features[]?' | while read feature; do
    echo "$feature" | jq -ca '.Vulnerabilities?[]?' | while read vulnerability; do
        name=$(echo $feature | jq -r '.Name')
        version=$(echo $feature | jq -r '.Version')
        cve=$(echo $vulnerability | jq -r '.Name')
        link=$(echo $vulnerability | jq -r '.Link')

        fixed=$(echo $vulnerability | jq -r '.FixedBy?')
        if [ "$fixed" = "null" ]; then
            fixed="no fix available"
            text="0"
        else
            fixed="fixed in $fixed"
            text="1"
        fi

        severity=$(echo $vulnerability | jq -r '.Severity')
        color=30
        if [ "$severity" = "High" ] || [ "$severity" = "Critical" ]; then
            color="31"
        fi

        echo "\033[${text};${color}m[$severity] $name $version: $fixed  ($cve, $link)\033[0;0m"
    done
done
