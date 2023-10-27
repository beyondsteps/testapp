FROM registry.redhat.io/jboss-eap-7/eap74-openjdk11-openshift-rhel8

USER root
COPY test.war /opt/eap/standalone/deployment/
RUN chown -R jboss:root $JBOSS_HOME && chmod -R ug+rwX $JBOSS_HOME

USER jboss
CMD ["/bin/bash", "-c", "/opt/eap/bin/openshift-launch.sh"]



