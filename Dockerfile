FROM registry.redhat.io/jboss-eap-7/eap74-openjdk11-openshift-rhel8

USER 185
COPY test.war /opt/eap/standalone/deployment/
RUN chown -R jboss:root /opt/eap/standalone/deployments
CMD ["/bin/bash", "-c", "/opt/eap/bin/openshift-launch.sh"]



