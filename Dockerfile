FROM registry.redhat.io/jboss-eap-7/eap74-openjdk11-openshift-rhel8

USER root
COPY test.war /opt/eap/standalone/deployments/

RUN chown -R 185:root /opt/eap/standalone/deployments

USER 185
CMD ["/bin/bash", "-c", "/opt/eap/bin/openshift-launch.sh"]s