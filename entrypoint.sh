#!/bin/bash

set -e

# Install netlify globally before NVM to prevent EACCESS issues
npm i -g netlify-cli

# Save its exec path to run later
NETLIFY_CLI=$(which netlify)

NETLIFY_AUTH_TOKEN=$1
NETLIFY_SITE_ID=$2
NETLIFY_DEPLOY_TO_PROD=$3
BUILD_DIRECTORY=$4
FUNCTIONS_DIRECTORY=$5
INSTALL_COMMAND=$6
BUILD_COMMAND=$7
DEPLOY_ALIAS=$8

# Install node from NVM to honor .nvmrc files
if [[ -n "$node_version" ]] || [[ -e ".nvmrc" ]]; then
	echo "Installing NVM"
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	if which node > /dev/null; then
		INSTALLED_NODE=$(node --version)
	fi

	if [[ -n "$node_version" ]]; then
		echo "Installing Node from node_version"
		nvm install "$node_version"
	elif [[ -e ".nvmrc" ]]; then
		NVMRC_NODE=$(cat .nvmrc)
		if [[ "$INSTALLED_NODE" == "$NVMRC_NODE" ]]; then
			echo "Installed node and nvmrc node are the same, using installed version"
			nvm use
		else
			echo "Installing Node from .nvmrc"
			nvm use
			nvm install
		fi
	fi
fi


# Install dependencies
if [[ -n "$INSTALL_COMMAND" ]]; then
	eval "$INSTALL_COMMAND"
elif [[ -f yarn.lock ]]; then
	yarn
else
	npm i
fi

# Build project
eval "${BUILD_COMMAND:-'npm run build'}"

# Export token to use with netlify's cli
export NETLIFY_SITE_ID="$NETLIFY_SITE_ID"
export NETLIFY_AUTH_TOKEN="$NETLIFY_AUTH_TOKEN"

COMMAND="$NETLIFY_CLI deploy --dir=$BUILD_DIRECTORY --functions=$FUNCTIONS_DIRECTORY --message=\"$INPUT_NETLIFY_DEPLOY_MESSAGE\""

if [[ $NETLIFY_DEPLOY_TO_PROD == "true" ]]
then
	COMMAND+=" --prod"
elif [[ -n $DEPLOY_ALIAS ]]
then
	COMMAND+=" --alias $DEPLOY_ALIAS"
fi

# Deploy with netlify
OUTPUT=$(sh -c "$COMMAND")

NETLIFY_OUTPUT=$("$OUTPUT")
NETLIFY_PREVIEW_URL=$(echo "$OUTPUT" | grep -Eo '(http|https)://[a-zA-Z0-9./?=_-]*(--)[a-zA-Z0-9./?=_-]*') #Unique key: --
NETLIFY_LOGS_URL=$(echo "$OUTPUT" | grep -Eo '(http|https)://app.netlify.com/[a-zA-Z0-9./?=_-]*') #Unique key: app.netlify.com
NETLIFY_LIVE_URL=$(echo "$OUTPUT" | grep -Eo '(http|https)://[a-zA-Z0-9./?=_-]*' | grep -Eov "netlify.com") #Unique key: don't containr -- and app.netlify.com

echo "::set-output name=NETLIFY_OUTPUT::$NETLIFY_OUTPUT"
echo "::set-output name=NETLIFY_PREVIEW_URL::$NETLIFY_PREVIEW_URL"
echo "::set-output name=NETLIFY_LOGS_URL::$NETLIFY_LOGS_URL"
echo "::set-output name=NETLIFY_LIVE_URL::$NETLIFY_LIVE_URL"
