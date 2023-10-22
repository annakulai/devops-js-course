#!/bin/bash

FILENAME=users.db
FILEDIR=src/module_4/task-2/data
DB_FILE_PATH=$FILEDIR/$FILENAME

# The script must check the existence of the users.db file
# (for all commands accept $ db.sh or $ db.sh help ones)
if [[ "$1" != "help" && "$1" != "" && ! -f $DB_FILE_PATH ]]; then
  read -r -p "${FILENAME} does not exist. Do you want to create it? [Y/n] " answer

  answer=${answer,,}

  if [[ "$answer" =~ ^(yes|y)$ ]]; then
    touch $FILENAME
    echo "File ${FILENAME} is created."
  else
    echo "File ${FILENAME} must be created to continue. Try again." >&2
    return 1
  fi
fi

validateLatinLetters() {
  if [[ $1 =~ ^[A-Za-z_]+$ ]]; then return 0; else return 1; fi
}

add() {
  read -p "Enter user name: " username

  validateLatinLetters $username
  if [[ "$?" == 1 ]]; then
    echo "Name must have only latin letters. Try again."
    return 1
  fi

  read -p "Enter user role: " role

  validateLatinLetters $role
  if [[ "$?" == 1 ]]; then
    echo "Role must have only latin letters. Try again."
    return 1
  fi

  echo "${username}, ${role}" >> $DB_FILE_PATH
  echo "User is added."
}

function backup {
  backupFileName=$(date +'%Y-%m-%d-%H-%M-%S')-users.db.backup

  cp $DB_FILE_PATH $FILEDIR/$backupFileName

  echo "Backup is created."
}

function restore {
  latestBackupFile=$(ls $FILEDIR*-$FILENAME.backup | tail -n 1)

  if [[ ! -f $latestBackupFile ]]; then
    echo "No backup file found."
    exit 1
  fi

  cp -f $latestBackupFile $DB_FILE_PATH

  echo "Backup is restored."
}

function find {
  read -p "Enter user name for search: " username

  validateLatinLetters $username
  if [[ "$?" == 1 ]]; then
    echo "Name must have only latin letters. Try again."
    return 1
  fi

  awk -F, -v x=$username '$1 ~ x' $DB_FILE_PATH

  if [[ "$?" == 1 ]]; then
    echo "User not found."
    return 1
  fi
}

inverseParam="$2"
function list {
  inverseParam=${inverseParam:2}

  if [[ $inverseParam == "inverse" ]]; then
    cat -n $DB_FILE_PATH | tac
  else
    cat -n $DB_FILE_PATH
  fi
}

help() {
  echo "Manages users in db. It accepts a single parameter with a command name."
  echo
  echo "Syntax: db.sh [command]"
  echo
  echo "List of available commands:"
  echo
  echo "add       Adds a new line to the users.db. The script must prompt a user to type the username 
                    of a new entity. After entering the username, the user must be prompted to type a role."
  echo "backup    Creates a new file, named %date%-users.db.backup which is a copy of current users.db"
  echo "restore   Takes the last created backup file and replaces users.db with it. 
                    If there are no backups - script should print: “No backup file found”"
  echo "find      Prompts the user to type a username, then prints username and role if such exists in users.db. 
                    If there is no user with the selected username, the script must print: “User not found”. 
                    If there is more than one user with such a username, print all found entries."
  echo "list      Prints contents of users.db in format: N. username, role
                    where N – a line number of an actual record
                    Accepts an additional optional parameter inverse which allows to get
                    result in an opposite order – from bottom to top"
}

case $1 in
  add) add ;;
  backup) backup ;;
  restore) restore ;;
  find) find ;;
  list) list ;;
  help | '' | *) help ;;
esac
