FROM registry.redhat.io/jboss-eap-7/eap74-openjdk11-openshift-rhel8

USER root
COPY test.war /opt/eap/standalone/deployments/
RUN chown -R 185:root $JBOSS_HOME && chmod -R ug+rwX $JBOSS_HOME
RUN chown -R 755 185:root $JBOSS_HOME/standalone/deployments


USER 185
CMD ["/bin/bash", "-c", "/opt/eap/bin/openshift-launch.sh"]