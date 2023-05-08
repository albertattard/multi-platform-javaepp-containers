# Create a multi-platform Java SE Subscription Enterprise Performance Pack container image <!-- omit in toc -->

Every Java release brings with it numerous improvements, such
[JEP 254: Compact Strings](https://openjdk.org/jeps/254) in Java 9 and
[JEP 377: ZGC: A Scalable Low-Latency Garbage Collector (Production)](https://openjdk.org/jeps/377)
in Java 15 to name two. These improvements are only available to the newer
releases of Java. User who cannot migrate to newer versions of Java cannot
benefit from these improvements.

The
[Java SE Subscription Enterprise Performance Pack (EPP)](https://docs.oracle.com/en/java/java-components/enterprise-performance-pack/epp-user-guide/overview.html)
brings the improvements available to Java 17 to the Java 8 family of
applications. Java EPP is intended to be a drop-in replacement for any Java 8
backend application. Customers who have adopted Java EPP saw considerable gains
in the form of reduced garbage collection time, lower memory footprint, and
better throughput.

Container images are a common way to package, distribute, and run modern
applications. Developers package their code with all its dependencies into a
container image and distribute it over container registries, such as the
[Oracle Container Registry](https://container-registry.oracle.com/), to become
directly accessible to the container hosting environment at runtime. The users
of the container image do not have to worry about how to configure the
application or what version of Java to be used, as everything is encapsulated
inside the container image.

In this article we will see how to create a multi-platform Java EPP container
image that can run on both the _amd64_ and the _arm64_ architectures. The ARM
architecture, such as the
[Ampere A1](https://www.oracle.com/cloud/compute/arm/), is gaining popularity as
these tend to provide a very good price to performance ratio. When you package
your application as a multi-platform Java EPP container image, you can run the
same Java application on different architectures, enabling you to move the
workload to the architecture that is right for you, possible saving you money in
the process.

This article comprises six sections, as listed below, each building on the
previous one.

- [Prerequisites](#prerequisites)
- [Download the Java EPP binaries](#download-the-java-epp-binaries)
- [Create the application JAR files](#create-the-application-jar-files)
- [Create a multi-stage and multi-platform `Dockerfile`](#create-a-multi-stage-and-multi-platform-dockerfile)
- [Build and publish the multi-platform container image](#build-and-publish-the-multi-platform-container-image)
- [Final Thoughts](#final-thoughts)

The article assumes that the reader knows how to package a Java application into
a JAR file (or a set of JAR files) and is familiar with containers. With that
being said, let's dive in.

## Prerequisites

To try the examples showed here, you need the following

1. An [Oracle account](https://profile.oracle.com/myprofile/account/create-account.jspx)
   to download the Java EPP binaries under the
   [OTN license](https://www.oracle.com/downloads/licenses/standard-license.html)
   or an
   [Oracle Java SE Subscription](https://www.oracle.com/java/technologies/javase-subscription-overview.html).
2. A docker compatible build tool that support the creation of multi-platform
   container images, such as the
   [buildx and BuildKit](https://docs.docker.com/build/architecture/) used by
   this example.
3. A container registry where to push the container image. This example uses
   [a custom container registry created in OCI](https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryoverview.htm),
   but any container registry will do.

## Download the Java EPP binaries

You can download the Java EPP binaries from the following places.

- [Java Downloads page](https://www.oracle.com/java/technologies/downloads/#jepp)
- [My Oracle Support page](https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=201621627509132&id=1439822.2&_adf.ctrl-state=1dbnsc6heg_52)

You should download the `.tar.gz` file for each architecture (_amd64_ and
_arm64_) and place them in a directory called `binaries`. The following `tree`
command prints the contents of the `./binaries` directory, required by the
subsequent sections.

```shell
$ tree './binaries'
```

Note that the Java EPP binaries have a distinctive `-perf` in their file name.

```
./binaries
├── jdk-8u371-perf-linux-aarch64.tar.gz
└── jdk-8u371-perf-linux-x64.tar.gz
```

Do not extract these binary files as these will be copied into the container
images and extracted during the container image creation.

## Create the application JAR files

You can create the application JAR file using your preferred build tool, be it
[Gradle](https://gradle.org/), [Maven](https://maven.apache.org/),
[Ant](https://ant.apache.org/), or any other tool. You can package the
application as either a single fat JAR file or as multiple JAR files.

Different build tools create the JAR file (and copy the dependencies) in
different output directories. For example, Gradle uses the `./build/libs`
directory while Maven uses the `./target` directory as their respective output
directories. In order to be build tool agnostic, the article assumes that all
application JAR files are in the `./jars` directory.

The article also assumes that the application main class is in package `demo`
and we will start the application using the command:

```shell
$ java -classpath './jars/*' demo.Main
```

## Create a multi-stage and multi-platform `Dockerfile`

The _Intel x86_ and _AMD64_ were the two leading architectures. The _ARM64_
started gaining popularity in the recent years and has become major player, as
it provides attractive price to performance pricing ratio in the cloud. To
simplify adoption of a technology across different architectures, many container
images are built with multi-platform support, like the
`container-registry.oracle.com/java/jdk-no-fee-term:17.0.7-oraclelinux8`
container image.

[Docker](https://www.docker.com/) simplified the multi-platform support through
its new [buildx plugin](https://github.com/docker/buildx) by using the
[`--platform`](https://docs.docker.com/engine/reference/commandline/buildx_build/#platform)
option. Users of our container image can point to the same tag and docker will
then choose the right container image for their architecture. For example, the
JDK 17 container image has multi-platform support and this container image is
available for both the _amd64_ and _arm64_ architectures.

```shell
$ docker buildx imagetools \
  inspect container-registry.oracle.com/java/jdk-no-fee-term:17.0.7-oraclelinux8
```

The
[inspect](https://docs.docker.com/engine/reference/commandline/buildx_inspect/)
option prints all supported architecture for this tag.

```
Name:      container-registry.oracle.com/java/jdk-no-fee-term:17.0.7-oraclelinux8
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:6eb6accdd2afb3118d6487b358a928ec9c6d3fb9abd30107c9f15d0e05634e18

Manifests:
  Name:      container-registry.oracle.com/java/jdk-no-fee-term:17.0.7-oraclelinux8@sha256:d93847cfa8a7e66ea7fea7b6aaf12b225e5e4c9fdef3a6a3544c8ce3aaa79acc
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/arm64

  Name:      container-registry.oracle.com/java/jdk-no-fee-term:17.0.7-oraclelinux8@sha256:ff56f1ff813ff71e5bbe2804e1eedd3cd42983e87e3b5ff8caf8a62da6bf9027
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/amd64
```

To support both _amd64_ and the _arm64_ architectures, we will use multi-stage
docker builds where we define an intermediate stage for each architecture. This
is analogous to polymorphism, where docker will then use the right stage
depending of the target architecture.

The Oracle Linux 9 (`container-registry.oracle.com/os/oraclelinux:9`) will be
used as the base image, but you can choose any 64 bit Linux distribution. Before
choosing a Linux distribution as the OS of your container image, you should
verify that it supports both _amd64_ and the _arm64_ architectures as otherwise
the example shown in this article will not work. Furthermore, Java EPP only runs
on Linux 64 OS, therefore other OS families cannot be considered.

```shell
$ docker buildx imagetools \
  inspect container-registry.oracle.com/os/oraclelinux:9

Name:      container-registry.oracle.com/os/oraclelinux:9
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:cb6b8aabba3e2e509e24d6b7db49840a0501898bff0127dbc10d8fd74e91f99c

Manifests:
  Name:      container-registry.oracle.com/os/oraclelinux:9@sha256:ddd0ebbbdc396588b7f7d348fc9e17a35da53cf09aa942974369de1874b0189e
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/amd64

  Name:      container-registry.oracle.com/os/oraclelinux:9@sha256:652c6f02f36444b999b84346e0cb788e62143de9c8ba76fcaf838135ee282a72
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/arm64
```

The `Dockerfile` that we will use comprises four stages. We will build this file
one stage at a time, describing each stage as we go along. Please feel free to
skip ahead to see the final example.

1. Create the base stage that contains just the OS

   ```Dockerfile
   FROM container-registry.oracle.com/os/oraclelinux:9 AS base
   WORKDIR /opt
   ```

   The container image build tool is smart enough to use the correct container
   image based on the architecture. For example, when building the container
   image for the _amd64_ architecture, the _amd64_ version of the OS is used.

2. Add a stage for the _arm64_ architecture that extends the base OS stage

   In this stage we will carry out only the configuration needed by the _arm64_
   architecture. Copy the _arm64_ Java EPP binary
   (`./binaries/jdk-8u371-perf-linux-aarch64.tar.gz`) and extract it into the
   `/opt/jdk` directory.

   ```Dockerfile
   FROM base AS base-arm64
   COPY ./binaries/jdk-8u371-perf-linux-aarch64.tar.gz jdk-8u371-perf-linux-aarch64.tar.gz
   RUN tar xvfz jdk-8u371-perf-linux-aarch64.tar.gz \
       && rm jdk-8u371-perf-linux-aarch64.tar.gz \
       && mv jdk1.8.0_371 jdk
   ```

   You should update the path if you have saved the
   `jdk-8u371-perf-linux-aarch64.tar.gz` binary file elsewhere.

   Note that the stage name, `base-arm64`, contains the architecture name in it.
   The stage name will play a role later on as the container image build tool
   will pick this stage only when building the _arm64_ variant of this container
   image.

   The `Dockerfile` now contains two stages.

   ```Dockerfile
   FROM container-registry.oracle.com/os/oraclelinux:9 AS base
   WORKDIR /opt


   FROM base AS base-arm64
   COPY ./binaries/jdk-8u371-perf-linux-aarch64.tar.gz jdk-8u371-perf-linux-aarch64.tar.gz
   RUN tar xvfz jdk-8u371-perf-linux-aarch64.tar.gz \
       && rm jdk-8u371-perf-linux-aarch64.tar.gz \
       && mv jdk1.8.0_371 jdk
   ```

3. Add a stage for the _amd64_ architecture that extends the base OS stage

   This is similar to the previous stage, but it has two key differences. This
   stage is named `base-amd64` and it uses the _amd64_ Java EPP binary
   (`./binaries/jdk-8u371-perf-linux-aarch64.tar.gz`) instead.

   ```Dockerfile
   FROM base AS base-amd64
   COPY ./binaries/jdk-8u371-perf-linux-x64.tar.gz jdk-8u371-perf-linux-x64.tar.gz
   RUN tar xvfz jdk-8u371-perf-linux-x64.tar.gz \
       && rm jdk-8u371-perf-linux-x64.tar.gz \
       && mv jdk1.8.0_371 jdk
   ```

   In both stages, Java EPP is extracted into the `/opt/jdk` directory. While
   this is not a must, extracting both versions into the same directory path
   simplifies the subsequent stages as these can assume that Java is found under
   the `/opt/jdk` directory.

   The `Dockerfile` now has three stages.

   ```Dockerfile
   FROM container-registry.oracle.com/os/oraclelinux:9 AS base
   WORKDIR /opt


   FROM base AS base-arm64
   COPY ./binaries/jdk-8u371-perf-linux-aarch64.tar.gz jdk-8u371-perf-linux-aarch64.tar.gz
   RUN tar xvfz jdk-8u371-perf-linux-aarch64.tar.gz \
       && rm jdk-8u371-perf-linux-aarch64.tar.gz \
       && mv jdk1.8.0_371 jdk


   FROM base AS base-amd64
   COPY ./binaries/jdk-8u371-perf-linux-x64.tar.gz jdk-8u371-perf-linux-x64.tar.gz
   RUN tar xvfz jdk-8u371-perf-linux-x64.tar.gz \
       && rm jdk-8u371-perf-linux-x64.tar.gz \
       && mv jdk1.8.0_371 jdk
   ```

   Up to now we have a generic multi-platform container image that uses Java
   EPP. Please note that the `JAVA_HOME` environment variable is not yet set and
   the `java` executable file is not on the `PATH`. This is configured in the
   following stage.

   An alternative approach is to insert another stage between this stage and the
   next stage where we define the `JAVA_HOME` environment variable and put the
   `java` executable file on the `PATH`.

4. Create the final stage that extends one of the previous stages, based on the
   architecture

   The docker buildx plugin provides
   [several platform arguments (`ARG`s) in the global scope](https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope),
   such as `TARGETARCH`. Please keep in mind that these are only available when
   using the docker buildx plugin.

   The argument `TARGETARCH` contains the name of target architecture, such as
   `amd64` and `arm64`. This can be used to extend the correct image.

   ```Dockerfile
   FROM base-${TARGETARCH}
   ```

   When building a container image for the _amd64_ architecture, the above
   instruction evaluates to

   ```Dockerfile
   FROM base-amd64
   ```

   A similar evaluation happens when building a container image for the _arm64_
   architecture.

   The rest of the stage is fairly standard.

   ```Dockerfile
   FROM base-${TARGETARCH}
   WORKDIR /opt/app
   ENV JAVA_HOME "/opt/jdk"
   ENV PATH "${PATH}:${JAVA_HOME}/bin"

   COPY ./jars .

   ENTRYPOINT ["java", "-classpath", "./*", "demo.Main"]
   ```

The `Dockerfile` now has all fours stages.

```Dockerfile
FROM container-registry.oracle.com/os/oraclelinux:9 AS base
WORKDIR /opt


FROM base AS base-arm64
COPY ./binaries/jdk-8u371-perf-linux-aarch64.tar.gz jdk-8u371-perf-linux-aarch64.tar.gz
RUN tar xvfz jdk-8u371-perf-linux-aarch64.tar.gz \
    && rm jdk-8u371-perf-linux-aarch64.tar.gz \
    && mv jdk1.8.0_371 jdk


FROM base AS base-amd64
COPY ./binaries/jdk-8u371-perf-linux-x64.tar.gz jdk-8u371-perf-linux-x64.tar.gz
RUN tar xvfz jdk-8u371-perf-linux-x64.tar.gz \
    && rm jdk-8u371-perf-linux-x64.tar.gz \
    && mv jdk1.8.0_371 jdk


FROM base-${TARGETARCH}
WORKDIR /opt/app
ENV JAVA_HOME "/opt/jdk"
ENV PATH "${PATH}:${JAVA_HOME}/bin"

COPY ./jars .

ENTRYPOINT ["java", "-classpath", "./*", "demo.Main"]
```

We can proceed to building this container image.

## Build and publish the multi-platform container image

As mentioned in the [prerequisites section](#prerequisites), two things are
needed to build multi-platform container images.

1. A buildx context that supports the _amd64_ and _arm64_ architectures
2. A container registry where the image will be published

First, you should verify the existence of a buildx context that supports both
the _amd64_ and _arm64_ architectures. You can list all available using the
[`docker buildx ls`](https://docs.docker.com/engine/reference/commandline/buildx_ls/)
command:

```shell
$ docker buildx ls

NAME/NODE                 DRIVER/ENDPOINT                           STATUS  BUILDKIT PLATFORMS
...
multi-platform-builder *  docker-container
  multi-platform-builder0 unix:///~/.colima/docker.sock running v0.11.5  linux/arm64, linux/amd64, linux/amd64/v2
...
```

If a context is not available, you can create one that supports both
`linux/arm64` and `linux/amd64` using the
[docker buildx create](https://docs.docker.com/engine/reference/commandline/buildx_create/)
command:

```shell
$ docker buildx create \
  --name multi-platform-builder \
  --driver docker-container \
  --bootstrap
```

Set the new context as the current build context using the
[`docker buildx use`](https://docs.docker.com/engine/reference/commandline/buildx_use/)
command:

```shell
$ docker buildx use multi-platform-builder
```

The
[`--load`](https://docs.docker.com/engine/reference/commandline/buildx_build/#load)
option creates the container image in the local registry. Unfortunately, the
`--load` option cannot be used together with the `--platform` option when
multiple platforms are specified. Therefore, we need a container registry to
push this container image to, using the
[`--push`](https://docs.docker.com/engine/reference/commandline/buildx_build/#push)
option instead. Create the container registry where the image will be published,
if you don't have access to one already.

Finally, build the container image targeting both `linux/amd64` and
`linux/arm64` platforms and push it to your container registry using the
[`docker build`](https://docs.docker.com/engine/reference/commandline/buildx_build/)
command:

```shell
$ docker build \
  --platform linux/amd64,linux/arm64 \
  --tag iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:1.0.0 \
  --push
  .
```

The container image is tagged with the semantic version: `1.0.0`.

Inspect the newly created container image and verify that both the _amd64_ and
the _arm64_ architectures are supported:

```shell
$ docker buildx imagetools \
  inspect iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:1.0.0

Name:      iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:1.0.0
MediaType: application/vnd.oci.image.index.v1+json
Digest:    sha256:870e5bd6d83a718a17c460fc9b25741295b581c0f321ffe9371ef827c35121a8

Manifests:
  Name:        iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:1.0.0@sha256:3c8669dd275f8dd556c33b1b75890b21d690a5c3bd32879a6a92090a3bccca71
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    linux/amd64

  Name:        iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:1.0.0@sha256:bde47574310fcca1b29122d592dee291674540fc6083a0b03debfae9d2ef9ed9
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    linux/arm64
...
```

Once you published the container image, you can run it:

```shell
$ docker run iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:1.0.0
```

## Final Thoughts

This article combines the Java EPP together with multi-platform container images
to enable delivery of high performing Java 8 applications using modern
distribution channels. This approach enables you to run you Java 8 applications
with the Java 17 benefits using Java EPP. Furthermore, by using the
multi-platform container images, you can move your workloads to different
architectures, enabling cost cutting.

We hope that you find this useful.

**References**

- [Java EPP User Guide](https://docs.oracle.com/en/java/java-components/enterprise-performance-pack/epp-user-guide/index.html)
- [Inside.java article](https://inside.java/)
- [Instructions of how to try this example](./TRYME.md)
