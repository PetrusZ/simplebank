#!/bin/bash
set -eu
set -o pipefail

DB_SOURCE=postgresql://local:local_secret07@home.codeplayer.org:15432/simple_bank_local?sslmode=disable
REDIS_ADDRESS=redis-master.codeplayer.org:6379
REDIS_DB=1
TAG=local

ORIG_DB_SOURCE=`grep DB_URL= Makefile | awk -F '=' '{print $2FS$3}'`
ORIG_REDIS_ADDRESS=`grep REDIS_ADDRESS= app.env | awk -F '=' '{print $2$3}'`
ORIG_REDIS_DB=`grep REDIS_DB= app.env | awk -F '=' '{print $2$3}'`
ORIG_TAG=`grep image: k8s/deployment.yaml | awk -F ':' '{print $3}'`

# Change config
changeConfig() {
    gsed -i "s#DB_URL=.*#DB_URL=${DB_SOURCE}#" Makefile
    gsed -i "s#DB_SOURCE=.*#DB_SOURCE=${DB_SOURCE}#" app.env
    gsed -i "s#REDIS_ADDRESS=.*#REDIS_ADDRESS=${REDIS_ADDRESS}#" app.env
    gsed -i "s#REDIS_DB=.*#REDIS_DB=${REDIS_DB}#" app.env
    gsed -i "s#ENVIRONMENT=.*#ENVIRONMENT=production#" app.env
    gsed -i "s#image: patrickz07/simple-bank:.*#image: patrickz07/simple-bank:${TAG}#" k8s/deployment.yaml
}

# Restore config
restoreConfig() {
    gsed -i "s#DB_URL=.*#DB_URL=${ORIG_DB_SOURCE}#" Makefile
    gsed -i "s#DB_SOURCE=.*#DB_SOURCE=${ORIG_DB_SOURCE}#" app.env
    gsed -i "s#REDIS_ADDRESS=.*#REDIS_ADDRESS=${ORIG_REDIS_ADDRESS}#" app.env
    gsed -i "s#REDIS_DB=.*#REDIS_DB=${ORIG_REDIS_DB}#" app.env
    gsed -i "s#ENVIRONMENT=.*#ENVIRONMENT=development#" app.env
    gsed -i "s#image: patrickz07/simple-bank:.*#image: patrickz07/simple-bank:${ORIG_TAG}#" k8s/deployment.yaml
}

changeConfig
trap restoreConfig EXIT

# CI
make migrateup
make test

# CD
## Build image
REGISTRY=patrickz07
REPOSITORY=simple-bank
IMAGE_TAG=`git rev-parse HEAD`
docker buildx build --push --platform linux/amd64,linux/arm64 -t $REGISTRY/$REPOSITORY:$IMAGE_TAG -t $REGISTRY/$REPOSITORY:local .

## Deploy to k8s
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl rollout restart deployment simple-bank-api-deployment --namespace=simplebank-petrusz