#!/bin/bash

set -e

LOG_FILES="/usr/local/tomcat/logs/catalina.out /usr/wrk/${WEBSERVICE_NAME}.wsa.log"

signal_handler() {

    echo "Stopping container"

    echo "Stopping tomcat..."
    /usr/local/tomcat/bin/catalina.sh stop

    # graceful shutdown so exit with 0
    exit 0
}
# trap TERM and call the handler to cleanup processes
trap 'signal_handler' SIGTERM SIGINT

# change name of service, change url and increase logging
sed -i "s|wsa1|${WEBSERVICE_NAME}|g" /usr/local/tomcat/webapps/wsa/WEB-INF/web.xml
# replace values in ubroker.properties file
sed -i "s|wsa1|${WEBSERVICE_NAME}|g;\
s|wsaUrl=http://localhost:80/wsa/${WEBSERVICE_NAME}|wsaUrl=http://${WEBSERVICE_HOST}:${WEBSERVICE_PORT}/wsa/${WEBSERVICE_NAME}|g;\
s|loggingLevel=2|loggingLevel=${LOGGING_LEVEL}|g;\
s|logEntryTypes=WSADefault|logEntryTypes=${LOG_ENTRY_TYPES}|g" /usr/dlc/properties/ubroker.properties

# start tomcat 
echo "Starting tomcat..."
/usr/local/tomcat/bin/catalina.sh start
TOMCAT_PID=`cat /usr/local/tomcat/logs/pid.txt`

# start the admin server
echo "Starting admin server..."
/usr/dlc/bin/proadsv -start

RETRIES=0
while true
do
  if [ "${RETRIES}" -gt 10 ]
  then
    echo "$(date +%F_%T) ERROR: AdminServer didn't start so exiting."
    tail /usr/wrk/admserv.log
    exit 1
  fi

  if /usr/dlc/bin/proadsv -query; then
    break;
  fi

  sleep 1
  RETRIES=$((RETRIES+1))
done

# set defaults
echo password | /usr/dlc/bin/wsaman -i ${WEBSERVICE_NAME} -webserverauth restmgr -setdefaults -prop appServiceHost -value ${APPSERVER_HOST}
echo password | /usr/dlc/bin/wsaman -i ${WEBSERVICE_NAME} -webserverauth restmgr -setdefaults -prop appServicePort -value ${APPSERVER_PORT}
echo password | /usr/dlc/bin/wsaman -i ${WEBSERVICE_NAME} -webserverauth restmgr -setdefaults -prop appServiceProtocol -value ${APPSERVER_PROTOCOL}
echo password | /usr/dlc/bin/wsaman -i ${WEBSERVICE_NAME} -webserverauth restmgr -setdefaults -prop serviceLoggingLevel -value ${LOGGING_LEVEL}
echo password | /usr/dlc/bin/wsaman -i ${WEBSERVICE_NAME} -webserverauth restmgr -setdefaults -prop serviceLoggingEntryTypes -value ${LOG_ENTRY_TYPES}

# deploy web services
for f in /var/lib/openedge/proxies/*.wsm ; do
  servicename=`echo ${f} | awk -F"." '{print $1}' | awk -F"/" '{print $NF}'`
  echo "Deploying ${servicename}..."
  echo password | /usr/dlc/bin/wsaman -i ${WEBSERVICE_NAME} -webserverauth restmgr -deploy -wsm ${f}
  echo password | /usr/dlc/bin/wsaman -i ${WEBSERVICE_NAME} -webserverauth restmgr -enable -appname ${servicename}
done

# stop the admin server
echo "Stopping admin server..."
/usr/dlc/bin/proadsv -stop

echo "Tomcat running as pid: ${CATALINA_PID}"

# keep tailing log file until tomcat process exits
tail --lines=1000 --pid=${TOMCAT_PID} -f ${LOG_FILES} & wait ${!}

# things didn't go well
exit 1
