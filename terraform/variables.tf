variable "region" {
  type        = string
  description = "The OCI region where the resources will be created"
}

variable "tenancy_id" {
  type        = string
  description = "The Tenancy OCID where the resources will be created"
}

variable "compartment_id" {
  type        = string
  description = "The compartment OCID where the resources will be placed"
}

variable "freeform_tags" {
  type        = map(string)
  description = "The freeform tags that will be applied to all resources"
}

variable "defined_tags" {
  type        = map(string)
  description = "The defined tags that will be applied to all resources"
}

variable "push_docker_images_identity" {
  type = object({
    name  = string,
    email = string
  })
  description = <<EOT
    push_docker_images_identity = {
      name: "The username that will be used to push the image to the registry"
      email: "The user email address that will be used to push the image to the registry"
    }
  EOT
}
