#!/usr/bin/env bash

# Ensure the script is called with a NameID parameter
if [ -z "$1" ]; then
  echo "Usage: $0 <NameID>"
  exit 1
fi

# Assign the NameID parameter
NAME_ID="$1"

# Lambda URL (replace with your actual URL from terraform output saml_api_endpoint)
readonly WORKER_BASE_URL="https://xxx.ap-southeast-2.amazonaws.com"

# Print the redirect URL
echo "${WORKER_BASE_URL}?nameID=${NAME_ID}" | pbcopy
