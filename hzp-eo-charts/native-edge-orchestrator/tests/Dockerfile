#
# Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.
#
ARG ARTIFACTORY_URL=${ARTIFACTORY_URL:-"isgedge.artifactory.cec.lab.emc.com/isgedge-docker-virtual"}

FROM ${ARTIFACTORY_URL}/dockerhub/alpine:latest AS certs
FROM ${ARTIFACTORY_URL}/dockerhub/maven:3.8.3-openjdk-17 as build


# Set jenkins user for CICD
ARG USER
ARG PASSWORD
ARG UNAME=jenkins
ARG UID=303203133
ARG GID=303200513
RUN groupadd -g $GID -o $UNAME
RUN useradd --no-log-init -m -u $UID -g $GID -o -s /bin/bash $UNAME
RUN chown -R $UID:$GID /home/${UNAME}
ENV HOME /home/${UNAME}
RUN mkdir /tests
RUN chown -R $UID:$GID /tests


USER root

#Build tests
WORKDIR /tests

COPY settings.xml /root/.m2/settings.xml
RUN sed -i "s/USER/${USER}/g" /root/.m2/settings.xml
RUN sed -i "s/PASSWORD/${PASSWORD}/g" /root/.m2/settings.xml
COPY src src
COPY pom.xml .
COPY test-suites test-suites
COPY --from=certs /usr/local/share/ca-certificates/dellca2018-bundle.crt /home/jenkins/dellca2018-bundle.crt
RUN keytool -importcert -keystore /usr/java/openjdk-17/lib/security/cacerts -storepass changeit -file /home/jenkins/dellca2018-bundle.crt -alias "dell-ca" -noprompt

RUN mvn clean install -q -DskipTests -DfullJar=true

RUN curl -LO https://dl.k8s.io/release/v1.27.4/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl

FROM ${ARTIFACTORY_URL}/openjdk:17-alpine3.14 as java_runtime

RUN jlink \
    --add-modules java.naming,jdk.unsupported,java.base,java.management,java.instrument,java.sql,java.sql.rowset,java.desktop,java.security.jgss,jdk.security.auth,jdk.jshell,jdk.crypto.ec,java.security.sasl,jdk.crypto.cryptoki,java.xml.crypto,jdk.jartool \
    --verbose \
    --strip-java-debug-attributes \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output /javaruntime

FROM ${ARTIFACTORY_URL}/hzp/alpine:3.18.3
ARG _JAVA_OPTIONS
ENV _JAVA_OPTIONS=${_JAVA_OPTIONS}

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"
COPY --from=java_runtime /javaruntime $JAVA_HOME
WORKDIR /tests
COPY --from=build /tests/target/tests.jar .
COPY --from=build /tests/test-suites test-suites
