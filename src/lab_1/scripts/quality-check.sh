#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$BASH_SOURCE")")
ROOT_DIR=${SCRIPT_DIR%/*}
CLIENT_BUILD_DIR=$ROOT_DIR/dist/app
red=$'\e[31;41m'
end=$'\e[0m'

cd "${CLIENT_BUILD_DIR}" || exit

npm run lint
lint_stage=$?

npm run test
test_stage=$?

npm audit
audit_stage=$?

if [ $lint_stage -ne 0 ]; then
  echo "${red} Lint errors found ${end}"
fi

if [ $test_stage -ne 0 ]; then
  echo "${red} Unit tests failed ${end}"
fi

if [ $audit_stage -ne 0 ]; then
  echo "${red} Audit failed! ${end}"
fi
