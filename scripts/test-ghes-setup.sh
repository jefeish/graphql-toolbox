#! /bin/bash

OAUTHTOKEN="bba369e24b668ac530f2d956c2859194740f90b6"
API_ENDPOINT="https://18.237.16.190/api/v3"
OWNER="jefeish"
ORG="demo-org"
REPO="foobar"

for i in {1..2}
do
    REST_CALL="${API_ENDPOINT}/orgs/${ORG}/memberships/user-${i}"
    curl -k -v -X PUT -H "Authorization: token $OAUTHTOKEN" -d "{ \"role\": \member\" }" ${REST_CALL}
done
