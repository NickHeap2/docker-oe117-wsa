#!/bin/bash

set -e

LOG_FILES="/usr/local/tomcat/logs/catalina.out /usr/wrk/${WEBSERVICE_NAME}.wsa.log"
touch ${LOG_FILES}

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

# move webservice
mv /usr/local/tomcat/webapps/wsa/wsa1 /usr/local/tomcat/webapps/wsa/${WEBSERVICE_NAME}
# repoint wsdls
sed -i "s|localhost:8080/wsa/wsa1|${WEBSERVICE_HOST}:${WEBSERVICE_PORT}/wsa/${WEBSERVICE_NAME}|g" /usr/local/tomcat/webapps/wsa/${WEBSERVICE_NAME}/*.wsdl
# repoint appserver
sed -i "s|<appServiceProtocol>Appserver</appServiceProtocol>|<appServiceProtocol>${APPSERVER_PROTOCOL}</appServiceProtocol>|g" /usr/local/tomcat/webapps/wsa/${WEBSERVICE_NAME}/*.props
sed -i "s|<appServiceHost>localhost</appServiceHost>|<appServiceHost>${APPSERVER_HOST}</appServiceHost>|g" /usr/local/tomcat/webapps/wsa/${WEBSERVICE_NAME}/*.props
sed -i "s|<appServicePort>5162</appServicePort>|<appServicePort>${APPSERVER_PORT}</appServicePort>|g" /usr/local/tomcat/webapps/wsa/${WEBSERVICE_NAME}/*.props
sed -i "s|<serviceLoggingLevel>2</serviceLoggingLevel>|<serviceLoggingLevel>${LOGGING_LEVEL}</serviceLoggingLevel>|g" /usr/local/tomcat/webapps/wsa/${WEBSERVICE_NAME}/*.props
sed -i "s|<serviceLoggingEntryTypes>WSADefault</serviceLoggingEntryTypes>|<serviceLoggingEntryTypes>${LOG_ENTRY_TYPES}</serviceLoggingEntryTypes>|g" /usr/local/tomcat/webapps/wsa/${WEBSERVICE_NAME}/*.props

# start tomcat
export CATALINA_PID=/usr/local/tomcat/logs/pid.txt
echo "Starting tomcat..."
/usr/local/tomcat/bin/catalina.sh start
TOMCAT_PID=`cat /usr/local/tomcat/logs/pid.txt`

echo "Tomcat running as pid: ${CATALINA_PID}"

# keep tailing log file until tomcat process exits
tail --lines=1000 --pid=${TOMCAT_PID} -f ${LOG_FILES} & wait ${!}

# things didn't go well
exit 1
