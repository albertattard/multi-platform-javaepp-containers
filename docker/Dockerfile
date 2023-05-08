FROM container-registry.oracle.com/os/oraclelinux:9 AS base
WORKDIR /opt


FROM base AS base-arm64
COPY ./docker/binaries/jdk-8u371-perf-linux-aarch64.tar.gz jdk-8u371-perf-linux-aarch64.tar.gz
RUN tar xvfz jdk-8u371-perf-linux-aarch64.tar.gz \
    && rm jdk-8u371-perf-linux-aarch64.tar.gz \
    && mv jdk1.8.0_371 jdk


FROM base AS base-amd64
COPY ./docker/binaries/jdk-8u371-perf-linux-x64.tar.gz jdk-8u371-perf-linux-x64.tar.gz
RUN tar xvfz jdk-8u371-perf-linux-x64.tar.gz \
    && rm jdk-8u371-perf-linux-x64.tar.gz \
    && mv jdk1.8.0_371 jdk


FROM base-${TARGETARCH}
WORKDIR /opt/app
ENV JAVA_HOME "/opt/jdk"
ENV PATH "${PATH}:${JAVA_HOME}/bin"

COPY ./build/libs .

ENTRYPOINT ["java", "-classpath", "./*", "demo.Main"]
