ARG PROMETHEUS_VERSION=0.20.0
ARG TRINO_VERSION=453

FROM registry.access.redhat.com/ubi9/ubi:latest as downloader

ARG PROMETHEUS_VERSION
ARG TRINO_VERSION
ARG SERVER_LOCATION="https://repo1.maven.org/maven2/io/trino/trino-server/${TRINO_VERSION}/trino-server-${TRINO_VERSION}.tar.gz"
ARG CLIENT_LOCATION="https://repo1.maven.org/maven2/io/trino/trino-cli/${TRINO_VERSION}/trino-cli-${TRINO_VERSION}-executable.jar"
ARG PROMETHEUS_JMX_EXPORTER_LOCATION="https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${PROMETHEUS_VERSION}/jmx_prometheus_javaagent-${PROMETHEUS_VERSION}.jar"
ARG WORK_DIR="/tmp"

RUN curl -L ${SERVER_LOCATION} | tar -zxf - -C ${WORK_DIR}
RUN \
curl -o ${WORK_DIR}/trino-cli-${TRINO_VERSION}-executable.jar ${CLIENT_LOCATION} && \
chmod +x ${WORK_DIR}/trino-cli-${TRINO_VERSION}-executable.jar
RUN \
curl -o ${WORK_DIR}/jmx_prometheus_javaagent-${PROMETHEUS_VERSION}.jar ${PROMETHEUS_JMX_EXPORTER_LOCATION} && \
chmod +x ${WORK_DIR}/jmx_prometheus_javaagent-${PROMETHEUS_VERSION}.jar

COPY bin ${WORK_DIR}/trino-server-${TRINO_VERSION}
COPY default ${WORK_DIR}/

###########################
# Remove unwanted plugins
RUN rm -rf ${WORK_DIR}/trino-server-${TRINO_VERSION}/plugin/{phoenix5,redshift,pinot}

###########################

# Final container image:
FROM registry.access.redhat.com/ubi9/ubi:latest

LABEL io.k8s.display-name="OpenShift Trino" \
      io.k8s.description="This is an image used by Cost Management to install and run Trino." \
      summary="This is an image used by Cost Management to install and run Trino." \
      io.openshift.tags="openshift" \
      maintainer="<cost-mgmt@redhat.com>"

RUN yum -y update && yum clean all

#ENV DISTRIBUTION_NAME=rhel

RUN touch /etc/yum.repos.d/adoptium.repo

RUN \
   echo '[Adoptium]' >> /etc/yum.repos.d/adoptium.repo; \
   echo 'name=Adoptium' >> /etc/yum.repos.d/adoptium.repo; \
   echo "baseurl=https://packages.adoptium.net/artifactory/rpm/${DISTRIBUTION_NAME:-$(. /etc/os-release; echo $ID)}/\$releasever/\$basearch" >> /etc/yum.repos.d/adoptium.repo; \
   echo 'enabled=1' >> /etc/yum.repos.d/adoptium.repo; \
   echo 'gpgcheck=1' >> /etc/yum.repos.d/adoptium.repo; \
   echo 'gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public' >> /etc/yum.repos.d/adoptium.repo

RUN \
    # symlink the python3 installed in the container
    ln -s /usr/libexec/platform-python /usr/bin/python && \
    set -xeu && \
    INSTALL_PKGS="temurin-22-jdk less jq" && \
    yum install -y $INSTALL_PKGS --setopt=tsflags=nodocs --setopt=install_weak_deps=False && \
    yum clean all && \
    rm -rf /var/cache/yum

# add user and directories
RUN \
    groupadd trino --gid 1000 && \
    useradd trino --uid 1000 --gid 1000 && \
    mkdir -p /usr/lib/trino /data/trino/{data,logs,spill} && \
    chown -R "trino:trino" /usr/lib/trino /data/trino

ENV JAVA_HOME=/usr/lib/jvm/temurin-22-jdk \
    TRINO_HOME=/etc/trino \
    TRINO_HISTORY_FILE=/data/trino/.trino_history

# https://docs.oracle.com/javase/7/docs/technotes/guides/net/properties.html
# Java caches dns results forever, don't cache dns results forever:
RUN touch $JAVA_HOME/lib/security/java.security && \
    chown 1000:0 $JAVA_HOME/lib/security/java.security && \
    chmod g+rw $JAVA_HOME/lib/security/java.security && \
    sed -i '/networkaddress.cache.ttl/d' $JAVA_HOME/lib/security/java.security && \
    sed -i '/networkaddress.cache.negative.ttl/d' $JAVA_HOME/lib/security/java.security && \
    echo 'networkaddress.cache.ttl=0' >> $JAVA_HOME/lib/security/java.security && \
    echo 'networkaddress.cache.negative.ttl=0' >> $JAVA_HOME/lib/security/java.security

RUN chown -R 1000:0 ${HOME} /etc/passwd $(readlink -f ${JAVA_HOME}/lib/security/cacerts) && \
    chmod -R 774 /etc/passwd $(readlink -f ${JAVA_HOME}/lib/security/cacerts) && \
    chmod -R 775 ${HOME}

ARG PROMETHEUS_VERSION
ARG TRINO_VERSION
COPY --from=downloader /tmp/jmx_prometheus_javaagent-${PROMETHEUS_VERSION}.jar /usr/lib/trino/jmx_exporter.jar
COPY --from=downloader /tmp/trino-cli-${TRINO_VERSION}-executable.jar /usr/bin/trino
COPY --from=downloader --chown=trino:trino /tmp/trino-server-${TRINO_VERSION} /usr/lib/trino
COPY --chown=trino:trino default/etc $TRINO_HOME

EXPOSE 8080
USER trino:trino
ENV LANG en_US.UTF-8
CMD ["/usr/lib/trino/run-trino"]
