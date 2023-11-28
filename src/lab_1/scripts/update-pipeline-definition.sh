#!/bin/bash

DEFAULT_FILE=pipeline.json
DATE=$(date +"%Y%m%d")
OUTPUT_FILE="pipeline-${DATE}.json"
DEFAULT_BUILD_CONFIGURATION=
DEFAULT_BRANCH=develop
DEFAULT_OWNER=boale
DEFAULT_REPO=shop-angular-cloudfront
DEFAULT_POLL_FOR_SOURCE_CHANGES=no

set -e # stop on first error

type jq > /dev/null 2>&1
exitCode=$?

if [ "$exitCode" -ne 0 ]; then
  printf "  ${red}'jq' not found! (json parser)\n${end}"
  printf "    Ubuntu Installation: sudo apt install jq\n"
  printf "    Redhat Installation: sudo yum install jq\n"
  exit 1
fi

showInstruction() {
  echo "Script and create a new one (e.g. pipeline-{date-of-creation}.json) with the following changes:
          The metadata property is removed.
          The value of the pipeline’s version property is incremented by 1."
  echo
  echo "Syntax: ./update-pipeline-definition.sh [command]"
  echo
  echo "List of available commands:"
  echo
  echo "filename    Should be passed as the first argument to the script."
  echo
  echo "--branch    The Branch property in the Source action’s configuration is set to a value from
                      the script’s parameter/flag --branch. The default value is main.  "
  echo
  echo "--owner     The Owner property in the Source action’s configuration is set to a value from the script’s parameter/flag --owner.
                      (Assume that it is a GitHub owner/account name of a repository you’re going to use within the pipeline)."
  echo
  echo "--poll-for-source-changes   The PollForSourceChanges property in the Source action’s configuration is set to a value from the script’s
                                      parameter/flag --poll-for-source-changes. (Assume that it is a property that activates and deactivates
                                      the automatic pipeline execution when source code is changed). The default value is false."
  echo
  echo "--configuration     The EnvironmentVariables properties in each action are filled with a stringified JSON object containing the
                              BUILD_CONFIGURATION value from the --configuration parameter flag."
  echo
  echo "Example usage: ./update-pipeline-definition.sh ./pipeline.json --configuration production --owner boale --branch feat/cicd-lab --poll-for-source-changes true"
}

if [[ "$1" == "--help" && ! -f $1 ]]; then
  showInstruction
fi

validateProperties() {
  if [ -z "$1" ]; then
    echo "Error: Argument is empty!"
    exit 1
  else
    if ! jq -e '.pipeline' "$1" > /dev/null 2>&1; then
      echo "Pipeline property does not exist"
      exit 1
    else
      if ! jq -e '.pipeline.version' "$1" > /dev/null 2>&1; then
        echo "Pipeline version property does not exist"
        exit 1
      fi
    fi

    if ! jq -e '.metadata' "$1" > /dev/null 2>&1; then
      echo "Metadata property does not exist"
      exit 1
    fi

    if ! jq -e '.pipeline.stages[]' "$1" > /dev/null 2>&1; then
      echo "Stages does not exist"
      exit 1

      if ! jq -e '.pipeline.stages[] | select(.name=="Source")' "$1" > /dev/null 2>&1; then
        echo "Source in Stages does not exist"
        exit 1
      fi

      if ! jq -e '.pipeline.stages[] | select(.name=="QualityGate")' "$1" > /dev/null 2>&1; then
        echo "QualityGate in Stages does not exist"
        exit 1
      fi

      if ! jq -e '.pipeline.stages[] | select(.name=="Build")' "$1" > /dev/null 2>&1; then
        echo "QualityGate in Stages does not exist"
        exit 1
      fi
    fi
  fi

}

promptData() {
  read -e -p "Please, enter pipeline name: " -i "$DEFAULT_FILE" FILE
  if [ ! -f $FILE ]; then
    echo "${FILE} doesn't exist."
    exit 1
  else
    validateProperties $FILE
  fi

  read -e -p "Please, enter BUILD_CONFIGURATION: " -i "$DEFAULT_BUILD_CONFIGURATION" BUILD_CONFIGURATION

  read -e -p "Enter a GitHub owner/account: " -i "$DEFAULT_OWNER" OWNER

  read -e -p "Enter a GitHub repository name: " -i "$DEFAULT_REPO" REPO

  read -e -p "Enter a GitHub branch name: " -i "$DEFAULT_BRANCH" BRANCH

  read -e -p "Do you want the pipeline to poll for changes (yes/no)?: " -i "$DEFAULT_POLL_FOR_SOURCE_CHANGES" POLL_FOR_SOURCE_CHANGES

  if [[ $pollForSourceChanges == 'no' ]]; then
    pollForSourceChanges=false
  else
    pollForSourceChanges=true
  fi
}

promptData

result=$(jq "del(.metadata) | .pipeline.version += 1" $FILE)

echo $result | jq > $OUTPUT_FILE

if ! [ -z "$BRANCH" ]; then
  jq '.pipeline.stages[0].actions[0].configuration.Branch = '\"${BRANCH}\"'' "${OUTPUT_FILE}" > "tmp.json" && mv "tmp.json" "${OUTPUT_FILE}"
fi

if ! [ -z "$OWNER" ]; then
  jq '.pipeline.stages[0].actions[0].configuration.Owner = '\"${OWNER}\"'' "${OUTPUT_FILE}" > "tmp.json" && mv "tmp.json" "${OUTPUT_FILE}"
fi

if ! [ -z "$POLL_FOR_SOURCE_CHANGES" ]; then
  jq '.pipeline.stages[0].actions[0].configuration.PollForSourceChanges = '\"${POLL_FOR_SOURCE_CHANGES}\"'' "${OUTPUT_FILE}" > "tmp.json" && mv "tmp.json" "${OUTPUT_FILE}"
fi

if ! [ -z "$REPO" ]; then
  jq '.pipeline.stages[0].actions[0].configuration.Repo = '\"${REPO}\"'' "${OUTPUT_FILE}" > "tmp.json" && mv "tmp.json" "${OUTPUT_FILE}"
fi

if ! [ -z "$BUILD_CONFIGURATION" ]; then
  jq '.pipeline.stages |= map( if .name == "QualityGate" or .name == "Build" then ( .actions[].configuration.EnvironmentVariables |= (fromjson | map(if .name == "BUILD_CONFIGURATION" then .value = '\"${BUILD_CONFIGURATION}\"' else . end) | tostring) ) else . end )' "${OUTPUT_FILE}" > "tmp.json" && mv "tmp.json" "${OUTPUT_FILE}"
fi

echo 'Changes saved!'
