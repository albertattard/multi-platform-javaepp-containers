# Try Me!

Unless otherwise stated, all commands shown here as to be executed from within
this directory (the same directory where the `TRYME.md` file is).

This example creates a public container registry in OCI, and push the image to
this container registry. You don't have to use OCI and any container registry
will do.

## Prerequisites

- Terraform v1.4.6 or newer is required

  ```shell
  $ terraform --version
  Terraform v1.4.6
  on darwin_arm64
  + provider registry.terraform.io/hashicorp/oci v4.119.0
  ```

  You may have other providers installed together with
  [the OCI provider](https://registry.terraform.io/providers/hashicorp/oci/latest).

  Terraform can be installed using
  [brew](https://formulae.brew.sh/formula/terraform).

  ```shell
  $ brew install terraform
  ```

- `jq` command-line JSON processor

  This is used to extract some information from JSON responses.

  ```shell
  $ jq --version
  jq-1.6
  ```

  `jq` can be installed through brew.

  ```shell
  $ brew install jq
  ```

- Container runtime, such as [docker](https://formulae.brew.sh/formula/docker)
  (not docker desktop)

  ```shell
  $ docker --version
   Docker version 23.0.5, build bc4487a59e
  ```

  Docker can be installed through brew

  ```shell
  $ brew install docker
  ```

  [Colima](https://formulae.brew.sh/formula/colima) is used as the container
  runtime (replacement for docker desktop).

  ```shell
  $ colima version
  colima version 0.5.4
  git commit: feef4176f56a7dea487d43689317a9d7fe9de27e
  ```

  Colima can be installed through brew

  ```shell
  $ brew install colima
  ```

  This will take a several minutes are it needs to install many things.

  Start colima with 8GB of memory.

  ```shell
  $ colima start --cpu 2 --memory 8
  ```

  Test the setup, by running any image (such as the
  [hello-world](https://hub.docker.com/_/hello-world/))

  ```shell
  $ docker run hello-world:latest
  ```

  Install the [docker buildx plugin](https://github.com/docker/buildx) to
  support multi-platform container images.

  ```shell
  $ brew install docker-buildx
  $ mkdir -p ~/.docker/cli-plugins
  $ ln -sfn /opt/homebrew/opt/docker-buildx/bin/docker-buildx ~/.docker/cli-plugins/docker-buildx
  $ docker buildx install
  $ docker buildx version
  github.com/docker/buildx v0.10.4 c513d34049e499c53468deac6c4267ee72948f02
  ```

- OCI user API Keys configured.

  If you like to follow along and push the container image to a container
  registry hosted in OCI, then you need to have an OCI account and configure the
  API keys locally.

## Useful commands

- Create the application JAR file

  ```shell
  $ ./gradlew clean package
  ```

  (_Optional_) The build process will produce one artefact.

  ```shell
  $ tree './build/libs'
  ./build/libs
  └── app.jar
  ```

- Run the application (on host machine)

  ```shell
  $ java -classpath './build/libs/*' demo.Main
  Java version:    1.8.0_371
  OS Architecture: aarch64
  ```

- Run the application (using containers)

  Build the docker image (without builder)

  ```shell
  $ ./gradlew clean package
  $ docker build \
    --file docker/Dockerfile \
    --tag multi-platform-containers \
    --load \
    .
  ```

  Build the docker image (with builder)

  ```shell
  $ docker build \
    --file docker/Dockerfile-with-builder \
    --tag multi-platform-containers \
    --load \
    .
  ```

  Run the docker image

  ```shell
  $ docker run \
    --name multi-platform-containers \
    --rm \
    multi-platform-containers
  Java version:    1.8.0_371
  OS Architecture: aarch64
  ```

- Create the OCI resources

  Create the `terraform.tfvars` file and provide the necessarily values. You can
  use the following template and plug in your values.

  ```terraform
  region         = "xxxxxx"
  tenancy_id     = "ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  compartment_id = "ocid1.compartment.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  freeform_tags = {
    "used-by"  = "Albert Attard (albert.attard@oracle.com)"
    "group-id" = "A unique string, such as a UUID, used to link all the resources together"
  }
  defined_tags = {}
  push_docker_images_identity = {
    name  = "albert.attard",
    email = "albert.attard@somewhere.com"
  }
  ```

  Initialize terraform

  ```shell
  $ terraform -chdir=terraform init
  ```

  (_Optional_) Format the terraform files

   ```shell
   $ terraform -chdir=terraform fmt
   ```

  (_Optional_) List the required changes

  ```shell
  $ terraform -chdir=terraform plan
  ```

  Create the OCI resources and build the multi-platform container image

  ```shell
  $ terraform -chdir=terraform apply
  ```

  Takes a couple of minutes to complete, as many things will be happening. The
  container image is created and pushed to the repository created in OCI. Once
  ready, the container image tag is printed.

  ```
  ...
  Outputs:

  repository_tag = "iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:latest"
  ```

  You can print the container image tag if needed.

  ```shell
  $ terraform -chdir=terraform output -json | jq --raw-output '.repository_tag.value'
  ```

- Inspect the container image

  ```shell
  $ docker buildx imagetools \
    inspect iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:latest
  ```

  Alternatively, you can combine the `docker buildx imagetools inspect` command
  with the terraform output

  ```shell
  $ docker buildx imagetools \
    inspect $(terraform -chdir=terraform output -json | jq --raw-output '.repository_tag.value')
  ```

  ```
  Name:      iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:latest
  MediaType: application/vnd.oci.image.index.v1+json
  Digest:    sha256:870e5bd6d83a718a17c460fc9b25741295b581c0f321ffe9371ef827c35121a8

  Manifests:
    Name:        iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:latest@sha256:3c8669dd275f8dd556c33b1b75890b21d690a5c3bd32879a6a92090a3bccca71
    MediaType:   application/vnd.oci.image.manifest.v1+json
    Platform:    linux/amd64

    Name:        iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:latest@sha256:bde47574310fcca1b29122d592dee291674540fc6083a0b03debfae9d2ef9ed9
    MediaType:   application/vnd.oci.image.manifest.v1+json
    Platform:    linux/arm64
  ...
  ```

  Run the application

  ```shell
  $ docker run \
    --name multi-platform-containers \
    --rm \
    iad.ocir.io/xxxxxxxxxxxx/epp_multi_platform_containers:latest
  ```

  Alternatively, you can combine the `docker run` command with the terraform
  output

  ```shell
  $ docker run \
    --name multi-platform-containers \
    --rm \
    $(terraform -chdir=terraform output -json | jq --raw-output '.repository_tag.value')
  ```

- (_Optional_) Delete the resources

  ```shell
  $ terraform -chdir=terraform destroy
  ```

  **Avoid incurring unnecessary costs by removing all resources**.
