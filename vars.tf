variable "gcloud-project" {
  description = "Name of GCloud project to spin up the bastion host"
  default = "sai-research"
}

variable "gcloud-region" {
  description = "Region of the GCloud project"
  default = "us-west1"
}


variable "gcloud-zone" {
  description = "Zone of the GCloud project"
  default = "us-west1-a"
}


variable "instance-size" {
  description = "Size of the bastion host"
  default = "n1-standard-4"
}

variable "number-of-users" {
  description = "Number of users to create on the bastion host"
  default = "2"
}

variable "serviceaccount-id" {
  description = "id of the users to create" // id for the service accounts
  default ="acl-test-dec5-"
}


variable "user-password" {
  description = "Standard password for the users to create on the bastion host"
  default = "dynatrace"
}
