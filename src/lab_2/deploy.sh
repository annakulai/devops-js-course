#!/bin/bash

SSH_ALIAS='ubuntu'
COURSE_DIR="$HOME/Desktop/bash/devops-js-course"
BACKEND_DIR_HOST="$COURSE_DIR/nestjs-rest-api"
BACKEND_DIR_REMOTE='/var/app/nestjs-rest-api'
FRONTEND_DIR_HOST="$COURSE_DIR/shop-react-redux-cloudfront"
FRONTEND_DIR_REMOTE='/var/www/shop-react-redux-cloudfront'
NGINX_DIR_HOST='/usr/local/etc/nginx/conf'
NGINX_DIR_REMOTE='/etc/nginx/sites-available'
NGINX_CONFIG="devops-js-app"

build_app() {
  rm -Rf $2
  cd $1
  npm run install
  npm run build
}

copy_to_remote_frontend() {
  scp -Crq $FRONTEND_DIR_HOST/dist/* $SSH_ALIAS:$FRONTEND_DIR_REMOTE
}

copy_to_remote_backend() {
  rsync -a -e ssh --exclude="node_modules" $1/* ${SSH_ALIAS}:$2
  ssh -t $SSH_ALIAS "cd $BACKEND_REMOTE_DIR && npm run build"
}

check_create_directory() {
  if ssh $SSH_ALIAS "[ ! -d $1 ]"; then
    ssh -t $SSH_ALIAS "sudo mkdir -p $1 && sudo chown -R sshuser: $1"
  fi
  ssh $SSH_ALIAS "sudo -S rm -r $1/*"
}

copy_nginx_conf() {
  scp $NGINX_DIR_HOST/$NGINX_CONFIG $SSH_ALIAS:$NGINX_DIR_REMOTE/$NGINX_CONFIG
}

# Check and create directories if not exists
check_create_directory $BACKEND_DIR_REMOTE
check_create_directory $FRONTEND_DIR_REMOTE

# Build applications
build_app $BACKEND_DIR_HOST nestjs-rest-api
build_app $FRONTEND_DIR_HOST shop-react-redux-cloudfront

# Copy build files and configs to remote server
copy_to_remote_backend $BACKEND_DIR_HOST $BACKEND_DIR_REMOTE
copy_to_remote_frontend $FRONTEND_DIR_HOST $FRONTEND_DIR_REMOTE
copy_nginx_conf

sudo nginx -s reload

echo "Deployment completed successfully."
