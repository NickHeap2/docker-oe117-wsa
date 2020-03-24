# wsa install using install files
FROM oe117-setup:0.1 AS wsa_install

# install expect
RUN yum -y install expect && \
    yum clean all && \
    rm -rf /var/cache/yum

# copy our expect script
COPY conf/expect.exp /tmp

# #do a background progress install with our response.ini
# COPY conf/response.ini /install/openedge/
# RUN /install/openedge/proinst -b /install/openedge/response.ini -l silentinstall.log

# run our expect script
RUN export TERM=xterm && \
    chmod +x /tmp/expect.exp && \
    /tmp/expect.exp

#we need to delete the license file here

###############################################

# actual wsa server image
# start with tomcat image
FROM tomcat:8.5.51-jdk11-openjdk
#FROM tomcat:8.5.51-jdk13-openjdk-oracle

# copy openedge files in
COPY --from=wsa_install /usr/dlc/ /usr/dlc/

# set defaults
ENV DLC=/usr/dlc \
    WEBSERVICE_NAME=wsa1 \
    WEBSERVICE_PORT=8080 \
    WEBSERVICE_HOST=localhost \
    APPSERVER_HOST=localhost \
    APPSERVER_PORT=25000 \
    APPSERVER_PROTOCOL=AppserverDC \
    LOGGING_LEVEL="2" \
    LOG_ENTRY_TYPES="WSADefault"
RUN mkdir /usr/wrk/

# add default apps in and then wsa app from dlc
RUN cp -r webapps.dist/manager/ webapps/manager && \
    cp -r webapps.dist/docs webapps/docs && \
    cp -r webapps.dist/examples webapps/examples && \
    cp -r webapps.dist/host-manager webapps/host-manager && \
    cp -r webapps.dist/ROOT webapps/ROOT && \
    cp -r /usr/dlc/servlets/wsa /usr/local/tomcat/webapps/wsa

# copy the openedge files using OE_TC script
# disable ip restrictions on manager apps
# add valid user
# RUN ln -s /usr/local/openjdk-11 /usr/dlc/jdk && \
#     sed -i "s/versionString = '/versionString = '1.6/" /usr/dlc/bin/OE_TC && \
#     sed -i "s/$myconfig = &promptUser/$myconfig = 'Yes'; #/" /usr/dlc/bin/OE_TC && \
#     sed -i "s/$myTcInstallDir = <STDIN>/$myTcInstallDir = '\/usr\/local\/tomcat'/" /usr/dlc/bin/OE_TC && \
#     /usr/dlc/bin/OE_TC && \
#     sed -i "s/allowAiaCmds=0/allowAiaCmds=1/" /usr/dlc/properties/ubroker.properties && \
#     sed -i "s/webAppEnabled=0/webAppEnabled=1/" /usr/dlc/properties/ubroker.properties && \

 RUN sed -i "s|allowAiaCmds=0|allowAiaCmds=1|" /usr/dlc/properties/ubroker.properties \
  && sed -i "s|webAppEnabled=0|webAppEnabled=1|" /usr/dlc/properties/ubroker.properties \
  && sed -i "s|<Valve|<!--<Valve|g; s|1\" />|1\" /> -->|g" webapps/manager/META-INF/context.xml \
  && sed -i "s|<Valve|<!--<Valve|g; s|1\" />|1\" /> -->|g" webapps/host-manager/META-INF/context.xml \
  && sed -i "s|</tomcat-users>|<role rolename=\"tomcat\"/><role rolename=\"admin-gui\"/><role rolename=\"manager-gui\"/></tomcat-users>|" conf/tomcat-users.xml \
  && sed -i "s|</tomcat-users>|<role rolename=\"PSCAdmin\"/><role rolename=\"PSCOper\"/></tomcat-users>|" conf/tomcat-users.xml \
  && sed -i "s|</tomcat-users>|<user username=\"admin\" password=\"password\" roles=\"tomcat,admin-gui,manager-gui\"/></tomcat-users>|" conf/tomcat-users.xml \
  && sed -i "s|</tomcat-users>|<user username=\"restmgr\" password=\"password\" roles=\"PSCAdmin,PSCOper\"/></tomcat-users>|" conf/tomcat-users.xml

LABEL maintainer="Nick Heap (nickheap@gmail.com)" \
 version="0.1" \
 description="WSA Tomcat Image for OpenEdge 11.7.2" \
 oeversion="11.7.2"

# create directory for proxies
RUN mkdir -p /var/lib/openedge/proxies

# use our own script command which will start tomcat etc
COPY scripts/start.sh /usr/local/sbin/
CMD ["/usr/local/sbin/start.sh"]
