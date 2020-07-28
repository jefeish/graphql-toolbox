#! /bin/bash

# -----------------------------------------------------------------------------
# Mini script to demo 'pagination' with GraphQL queries.
#
# This script takes a GrapQL query file as it's input. 
# This demo is not query agnostic, due to the fact that the
# 'pagingInfo' path depends on the specific query.
# -----------------------------------------------------------------------------

# your GitHub Token
TOKEN=$1
API="https://ghe.io/api/graphql"
# remove '\n' from query file, make it a one-liner
QUERY=`tr -d '\n' < $2`
# next paging index
CURSOR="null"
# Individual page results
PAGE=""
# 'jq' path to find paging information
PAGEINFO=".data.organizations.pageInfo"

output=""

# -----------------------------------------------------------------------------
# Function to invoke the graphQL query, repeatedly, with different cursor offset
# -----------------------------------------------------------------------------
function getPage() 
{
    # format the original query string to fit the 'curl' command
    tmp1=`echo "$2" | sed 's/\"/\\\"/g' | sed 's/query/{"query": "/g'`'"}'

    # write the 'query data' input to a tmp file, easier to process and to debug
    if [[ "$1" != "null" ]]; then
        tmp2=`echo "$tmp1" | sed "s/after: null/after: $1/g"`
        echo "$tmp2" > out
    else
        echo "$tmp1" > out
    fi 

    # make the GraphQL call
    PAGE=`curl -s -X POST -H "Authorization: bearer $TOKEN" -d @out $API`
    # comment that line for some debug info 
    rm -f out
}

# Keep paging as long as there is more. Note: the 'pageInfo' path might need 
# adjustment depending on the query.
while true; do
  getPage "$CURSOR" "$QUERY"
  >&2 echo -n "."
  output=$(echo "$output" "$PAGE")
  hasNextPage=$(echo "$PAGE" | jq -r $PAGEINFO.hasNextPage)

  if [ "$hasNextPage" = "true" ]; then
    CURSOR='\\"'$(echo "$PAGE" | jq -r $PAGEINFO.endCursor)'\\"'
  else
    break
  fi
  # sleep - to not hit the server too hard
  sleep 2
done

# pretty print and concat the result 
echo "$output" | jq . -M