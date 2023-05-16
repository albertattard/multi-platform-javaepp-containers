terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.0.0"
    }
  }
}

provider "oci" {
  region = var.region
}

data "oci_identity_compartment" "this" {
  id = var.compartment_id
}

resource "oci_identity_user" "push_docker_images" {
  description    = "Demo Push Docker Images User"
  compartment_id = var.tenancy_id
  name           = var.push_docker_images_identity.name
  email          = var.push_docker_images_identity.email

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags

  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_identity_auth_token" "push_docker_images" {
  description = "Demo Push Docker Images Auth Token"
  user_id     = oci_identity_user.push_docker_images.id
}

resource "oci_identity_group" "push_docker_images" {
  description    = "Demo Push Docker Images Identiry Group"
  compartment_id = var.tenancy_id
  name           = "push_docker_images"

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags

  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_identity_user_group_membership" "push_docker_images" {
  group_id = oci_identity_group.push_docker_images.id
  user_id  = oci_identity_user.push_docker_images.id
}

resource "oci_identity_policy" "push_docker_images" {
  description    = "Demo allow push docker images to container repository"
  compartment_id = var.compartment_id
  name           = "demo_push_docker_images"
  statements     = ["Allow group ${oci_identity_group.push_docker_images.name} to manage repos in compartment ${data.oci_identity_compartment.this.name}"]
  version_date   = "2023-04-27"

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags

  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_artifacts_container_repository" "this" {
  compartment_id = var.compartment_id
  display_name   = "epp_multi_platform_containers"
  is_immutable   = false
  is_public      = true

  readme {
    content = <<EOT
      # Multi-Platform Containers

      A **temporary** repository used as part of the EPP Multi-Platform
      Containers demonstration and is deleted afterwards.
    EOT
    format  = "text/markdown"
  }
}

locals {
  repository_ocid = split(".", oci_artifacts_container_repository.this.id)
  image_url       = "${local.repository_ocid[3]}.ocir.io/${local.repository_ocid[5]}/${oci_artifacts_container_repository.this.display_name}:latest"
}

resource "time_sleep" "wait_for_user_and_container_repository" {
  depends_on = [
    oci_identity_user_group_membership.push_docker_images,
    oci_identity_policy.push_docker_images,
    oci_artifacts_container_repository.this
  ]

  create_duration = "30s"
}

resource "null_resource" "build_and_push_container_image" {
  depends_on = [time_sleep.wait_for_user_and_container_repository]

  provisioner "local-exec" {
    command = <<EOT
      echo "${oci_identity_auth_token.push_docker_images.token}" | docker login --username "${local.repository_ocid[5]}/${oci_identity_user.push_docker_images.name}" --password-stdin "${local.repository_ocid[3]}.ocir.io"
      docker buildx use multi-platform-builder
      docker build --file ../docker/Dockerfile-with-builder --platform linux/amd64,linux/arm64 --tag ${local.image_url} --push ../
    EOT
  }
}

output "repository_tag" {
  description = "The repository/image tag"
  value       = local.image_url
}
