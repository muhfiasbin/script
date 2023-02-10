#!/bin/bash

CLUSTER="enceladus"
PROJECT="default"

# Get Container List in LXD Cluster
CONTAINERS=($(lxc list enceladus: --columns n --format csv --project default status=running | grep -v "^db*"))
for CONTAINER in "${CONTAINERS[@]}"
do
  printf "Execute in ${CONTAINER}\n"
  # Check if MariaDB installed
  REQUIRED_PKG="mariadb-server"
  if lxc exec ${CLUSTER}:${CONTAINER} --project ${PROJECT} -- dpkg --get-selections | grep -q "^$REQUIRED_PKG[[:space:]]*install$" >/dev/null; then
    DBLISTFILE=/tmp/DatabasesToDump.txt
    #lxc exec enceladus:web-dsai --project default -- mysql -ANe "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('mysql','information_schema','performance_schema');" > ${DBLISTFILE}

    # Get DB Name from Container
    lxc exec ${CLUSTER}:${CONTAINER} --project ${PROJECT} -- mysql -ANe "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('sys','mysql','information_schema','performance_schema');" > ${DBLISTFILE}
    # Then put it on DBLIST Variable
    DBLIST=""
    for DB in $(cat ${DBLISTFILE})
    do
      DBLIST="${DBLIST} ${DB}"
    done

    if [[ -z "${DBLIST}" ]]; then
      printf "Empty\n"
    else
      printf "${DBLIST}\n"
    fi
  fi
done
