#!/bin/bash

echo "Checking the status of the urbanos artifacts for this project...."

curl -fL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: token $ACCESS_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    'https://api.github.com/repos/UrbanOS-Public/ubi-trino/actions/artifacts' # | jq '.artifacts[] | {name, expired, size_in_bytes}'

