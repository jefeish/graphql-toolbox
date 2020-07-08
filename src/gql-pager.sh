#!/bin/bash
# requires `bash, `jq` and `curl`
# set your credentials and org name below
# 
# This script paginates the GraphQL API to get all users. It does not check for rate limits
# but sleeps 10 seconds after every call to try to avoid hitting a rate limit.
CREDENTIALS=USERNAME:TOKEN
ORG=YOUR-ORG

CURSOR=null

function getPage(data, cursor) {
curl -s  -X POST -H  -H "Content-Type: application/json"  -d '{ "query": "{ organization(login: \"'$ORG'\") { samlIdentityProvider { externalIdentities(first: 100, after: '$1') { pageInfo { endCursor startCursor hasNextPage } edges { cursor node { samlIdentity { nameId } scimIdentity { username } user { login } } } } } } }" }'  https://api.github.com/graphql
}

output=""
while true; do
  page=$(getPage "$CURSOR" "$data")
  output=$(echo "$output" "$page")
  hasNextPage=$(echo "$page" | jq .data.organization.samlIdentityProvider.externalIdentities.pageInfo.hasNextPage)
  if [ "$hasNextPage" = "true" ]; then
    CURSOR='\"'$(echo "$page" | jq -r .data.organization.samlIdentityProvider.externalIdentities.pageInfo.endCursor)'\"'
  else
    break
  fi
  sleep 10
done

echo "$output" | jq . -C