#!/bin/bash
set -euo pipefail

cd ${0%/*}/coffee-shop

trap cleanup EXIT

function cleanup() {
  docker stop coffee-shop coffee-shop-db barista &> /dev/null || true
}


cleanup

docker run -d --rm \
  --name coffee-shop-db \
  --network dkrnet \
  -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:9.5

docker run -d --rm \
  --name barista \
  --network dkrnet \
  -p 8002:8080 \
  rodolpheche/wiremock:2.6.0


# coffee-shop

docker build -f Dockerfile.dev -t tmp-builder .

# wait for db startup
sleep 5

docker run -d --rm \
  --name coffee-shop \
  --network dkrnet \
  -p 8001:8080 \
  -p 5005:5005 \
  -v /home/sebastian/.m2/:/root/.m2/ \
  tmp-builder

# wait for app startup
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://localhost:8001/health)" != "200" ]]; do
  sleep 2;
done

mvn compile quarkus:remote-dev -Dquarkus.live-reload.url=http://localhost:8001 -Dquarkus.live-reload.password=123
