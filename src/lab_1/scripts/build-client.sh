#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$BASH_SOURCE")")
ROOT_DIR=${SCRIPT_DIR%/*}
CLIENT_BUILD_DIR=$ROOT_DIR/dist/app
ENV_CONFIGURATION=

clientBuildFile=$ROOT_DIR/dist/client-app.zip

if [ -e "$clientBuildFile" ]; then
  rm "$clientBuildFile"
  echo "$clientBuildFile was removed."
fi

parent_path=$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  pwd -P
)

if [[ "$1" = 'production' ]]; then
  ENV_CONFIGURATION='production'
fi

cd $ROOT_DIR/shop-angular-cloudfront && npm i && npm run build -- --configuration=$ENV_CONFIGURATION --output-path=$CLIENT_BUILD_DIR

echo "Client app was built with $ENV_CONFIGURATION configuration."

zip -r $clientBuildFile $CLIENT_BUILD_DIR/*
