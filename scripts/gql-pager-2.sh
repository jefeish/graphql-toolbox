#! /bin/bash
# set -x
# -----------------------------------------------------------------------------
# Mini script to demo 'pagination' with GraphQL queries.
#
# This script takes a GrapQL query file as it's input. 
# This demo is not query agnostic, due to the fact that the
# 'pagingInfo' path depends on the specific query.
# -----------------------------------------------------------------------------

# your GitHub Token
TOKEN=$1
API="https://api.github.com/graphql"
# API="https://ghe.io/api/graphql"


# -----------------------------------------------------------------------------
# Function to invoke the graphQL query, repeatedly, with different cursor offset
# -----------------------------------------------------------------------------
function getPage() 
{
  # strip the 'query' string
  tmp1=`echo "$2" | sed 's/\"/\\\"/g' | sed 's/query/{"query": "/g'`'"}'

  if [[ "$1" != "null" ]]; then
      tmp2=`echo "$tmp1" | sed "s/after: null/after: $1/g"`
      echo "$tmp2" > out
  else
      echo "$tmp1" > out
  fi 

  # make the GraphQL call
  PAGE=`curl -s -X POST -H "Authorization: bearer $TOKEN" -d @out $API`
  # comment that line for some debug info 
  # rm -f out
}

# -----------------------------------------------------------------------------

# get me a list of all the organizations (paging) as one json
# parameters: none
function getOrgs()
{
  output=""
  CURSOR="null"
  # remove '\n' from query file, make it a one-liner
  QUERY=`tr -d '\n' < get-orgs.gql`
  # 'jq' path to find paging information
  PAGEINFO=".data.organizations.pageInfo"
  
  # Keep paging as long as there is more. Note: the 'pageInfo' path might need 
  # adjustment depending on the query.
  while true; do
    getPage "$CURSOR" "$QUERY"
    data=`echo $PAGE | jq .data.organizations.nodes | sed 's/\[//g ; s/\]//g'` 
    output=$(echo "$output", "$data")
    hasNextPage=$(echo "$PAGE" | jq -r $PAGEINFO.hasNextPage)

    if [ "$hasNextPage" = "true" ]; then
      CURSOR='\\"'$(echo "$PAGE" | jq -r $PAGEINFO.endCursor)'\\"'
    else
      break
    fi
    
    sleep 1
  done

  result='['$(echo "$output" | sed 's/^,//g ')']'
  echo $result | jq -S
}

# -----------------------------------------------------------------------------

# get me a list of all the Repos in an Org
# parameters: none
function getOrgRepos()
{
  ORG=$1
  output=""
  CURSOR="null"
  # remove '\n' from query file, make it a one-liner
  QUERY=`tr -d '\n' < org-repos.gql`
  QUERY=`echo $QUERY | sed "s/login: null/login: \"${ORG}\"/g"`
  # 'jq' path to find paging information
  PAGEINFO=".data.organization.repositories.pageInfo"

  # Keep paging as long as there is more. Note: the 'pageInfo' path might need 
  # adjustment depending on the query.
  while true; do
    getPage "$CURSOR" "$QUERY"
    data=`echo $PAGE | jq .data.organization.repositories.nodes | sed 's/\[//g ; s/\]//g'` 
    output=$(echo "$output", "$data")
    hasNextPage=$(echo "$PAGE" | jq -r $PAGEINFO.hasNextPage)

    if [ "$hasNextPage" = "true" ]; then
      CURSOR='\\"'$(echo "$PAGE" | jq -r $PAGEINFO.endCursor)'\\"'
    else
      break
    fi

    sleep 1
  done

  result='['$(echo "$output" | sed 's/^,//g ')']'
  echo "$result"
}

# -----------------------------------------------------------------------------

# get me a list of all the Collaborators in a Repo and their Permission
function getRepoCollaboratorsPermission()
{
  ORG=$1
  REPO=$2
  output=""
  CURSOR="null"
  # remove '\n' from query file, make it a one-liner
  QUERY=`tr -d '\n' < org-repo.gql`
  QUERY=`echo $QUERY | sed "s/login: null/login: \"${ORG}\"/g"`
  QUERY=`echo $QUERY | sed "s/name: null/name: \"${REPO}\"/g"`
  # 'jq' path to find paging information
  PAGEINFO=".data.organization.repository.collaborators.pageInfo"

  # Keep paging as long as there is more. Note: the 'pageInfo' path might need 
  # adjustment depending on the query.
  while true; do
    getPage "$CURSOR" "$QUERY"
    data=`echo $PAGE | jq -r \
      '.data.organization.repository |
      { nameWithOwner: .nameWithOwner, edges: .collaborators.edges[]?} | 
      [.nameWithOwner, .edges.node.name, .edges.node.login, .edges.node.email, .edges.permission] |
      @csv'`

    if [ "$data" != "" ] && ["$output" == ""]; then
      output=$(echo "$output \n $data")
    else
      output=$(echo "$data")  
    fi

    hasNextPage=$(echo "$PAGE" | jq -r $PAGEINFO.hasNextPage)

    if [ "$hasNextPage" = "true" ]; then
      CURSOR='\\"'$(echo "$PAGE" | jq -r $PAGEINFO.endCursor)'\\"'
    else
      break
    fi
    
    sleep 1
  done

  echo "$output"
}

# -----------------------------------------------------------------------------

# this one combines the other functions to something useful
function theBigOne()
{
  # ALL_ORGS=$(getOrgs)
  # orgs=$(echo ${ALL_ORGS} | jq -r -c '.[].name')
  # echo "ALL_ORGS: >$ALL_ORGS< ALL_ORGS"
  # echo "ORGS: >$orgs< ORGS"

  orgs="github"

  for org in $orgs
  do
    ALL_REPOS=$(getOrgRepos $org)
    # echo "ORG: >$org< --- ALL_REPOS: >$ALL_REPOS<"

    repos=$(echo ${ALL_REPOS} | jq -r -c '.[].name')
    
    if [ "$repos" != "" ]; then
      for repo in $repos
      do 
        All_ORG_REPOS_PERM=$(getRepoCollaboratorsPermission ${org} ${repo})
        echo "${All_ORG_REPOS_PERM}" >> result.csv
      done
    fi
  done

}

theBigOne

# FIX
# additional '\n' after every page (100)
# blank lines between repos (switching from one to next repo)