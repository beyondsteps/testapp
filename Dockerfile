FROM registry.redhat.io/jboss-eap-7/eap74-openjdk11-openshift-rhel8
COPY test.war /opt/eap/standalone/deployment/
USER 185
CMD ["/bin/bash", "-c", "/opt/eap/bin/openshift-launch.sh"]



