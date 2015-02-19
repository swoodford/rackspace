#!/bin/bash
# Use Rackspace Account Credentials to get API Token

# Set Required Variables
ACCOUNTNUM="Your Rackspace Account Number"
USERNAME="Your Rackspace Username"
APIKEY="Your Rackspace API Key"
REGION="Your Default Rackspace Region"

if [ "$ACCOUNTNUM" = "Your Rackspace Account Number" ]; then
	tput setaf 1; echo "Failed to setup credentials in set-credentials.sh!" && tput sgr0
	exit 1
else
	# Get Token
	export TENANT="$ACCOUNTNUM"
	export TOKEN=$(curl -sX POST https://identity.api.rackspacecloud.com/v2.0/tokens \
		-H "Content-Type: application/json" \
		-d '{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"'"$USERNAME"'", "apiKey":"'"$APIKEY"'"}}}' \
		| python -m json.tool | grep -m 1 id | cut -d '"' -f 4)
	export $REGION
fi

# echo $TENANT
# echo $TOKEN
