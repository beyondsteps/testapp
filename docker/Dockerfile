FROM bastion.ocp.pentalink.mw:5000/jboss-eap-7/eap74-openjdk11-openshift-rhel8:7.4.10-3

USER root

ADD oracle /opt/eap/modules/system/layers/base/com/oracle
ADD openshift-launch.sh /opt/eap/bin/
ADD standalone.conf /opt/eap/bin/
ADD configuration /opt/eap/standalone/configuration/
ADD app /opt/eap/app/

RUN chown -R jboss:root /opt/eap/modules/system/layers/base/com && \
chown -R jboss:root /opt/eap/app && \
rm -rf /opt/eap/docs/examples && rm -rf /opt/eap/welcome-content

RUN chown jboss:root /opt/eap/bin/openshift-launch.sh && \
chmod +x /opt/eap/bin/openshift-launch.sh &&\
chown jboss:root /opt/eap/standalone/configuration/mgmt-users.properties && \
chown jboss:root /opt/eap/standalone/configuration/mgmt-groups.properties && \
chown jboss:root /opt/eap/bin/standalone.conf && \
chown jboss:root /opt/eap/standalone/configuration/standalone-openshift.xml

####################################
# TRANManager #
####################################

RUN mkdir -p /log/tranmgr/logs/proc/libtran && mkdir -p /sw/tranmgr && \
mkdir -p /sw/tranmgr/agt/dat
ADD tran_agent_ver2.tar.gz /sw/tranmgr

RUN ln -s /log/tranmgr/logs /sw/tranmgr/agt/logs && chown -R jboss:root /sw && chown -R jboss:root /log && chmod -R 777 /log/tranmgr/logs && chmod 777 /sw/tranmgr


####################################
# Jennifer #
####################################

RUN mkdir /sw/jennifer && mkdir -p /log/jennifer
ADD agent.java.tar /sw/jennifer
ADD jennifer.conf /sw/jennifer/agent.java/conf

RUN chown -R jboss:root /sw/jennifer && chown -R jboss:root /sw/jennifer/agent.java && chown -R jboss:root /log/jennifer
RUN chmod 755 /log/jennifer && chmod -R 755 /sw/jennifer/agent.java/ext

####################################

USER 185

# jboss user env for TRANManager
ENV TRAN_HOME=/sw/tranmgr \
    TRAN_AGT_HOME=/sw/tranmgr/agt \
    TRAN_LOG_HOME=/sw/tranmgr/agt/logs \
    TRAN_AGT_CFG_FILE=/sw/tranmgr/agt/config/agt.cfg 

CMD ["/bin/bash", "-c", "/sw/tranmgr/agt/bin/tran_agent.sh start; /opt/eap/bin/openshift-launch.sh"]

