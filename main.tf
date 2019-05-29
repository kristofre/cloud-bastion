/*
   BASTION HOST generation
*/

// Configure the Google Cloud provider
provider "google" {
  // see here how to get this file
  // https://console.cloud.google.com/apis/credentials/serviceaccountkey 
  credentials = "${file("sai-research-a5aa3362e25a-key.json")}"

  project = "${var.gcloud-project}"
  region  = "${var.gcloud-region}"
}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
  byte_length = 8
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
  name         = "acl-bastion-${random_id.instance_id.hex}"
  machine_type = "${var.instance-size}"
  zone         = "${var.gcloud-zone}"

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-1804-lts" // OS version
      size  = "40"                      // size of the disk in GB
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
      nat_ip = "${google_compute_address.static.address}"
    }
  }

  metadata {
    sshKeys = "acl:${file("./key.pub")}"
  }

  /* Startup script to make sure everything is installed
        - git
        - hub
        - docker
        - oc
        - kubectl
        - gcloud (comes by default with this instance)
        - istioctl
        - node8
        - npm
        - nano
      */
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "echo \"installing helpers...\" ",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      "sudo apt-get update",
      "echo \"installing git...\"",
      "sudo apt-get install git -y",
      "echo \"installing jq...\"",
      "sudo apt-get install jq -y",
      "echo \"installing hub...\"",
      "sudo wget https://github.com/github/hub/releases/download/v2.6.0/hub-linux-amd64-2.6.0.tgz",
      "tar -xzf hub-linux-amd64-2.6.0.tgz",
      "sudo cp hub-linux-amd64-2.6.0/bin/hub /bin/",
      "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get install docker-ce -y",
      "sudo wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz",
      "sudo tar xzvf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz",
      "sudo cp openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc /bin/",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "echo \"deb https://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y kubectl",
      "sudo wget https://github.com/istio/istio/releases/download/1.0.4/istio-1.0.4-linux.tar.gz",
      "sudo tar xzvf istio-1.0.4-linux.tar.gz",
      "sudo cp istio-1.0.4/bin/istioctl /bin/",
      "sudo apt-get install nodejs -y",
      "sudo apt-get install npm -y",
      "sudo apt-get install nano vim -y"
    ]
  }

  provisioner "local-exec" {
    command = "../scripts/createGcloudServiceAccounts.sh ${var.serviceaccount-id} ${var.number-of-users} ${var.gcloud-project}"
  }

  provisioner "file" {
    source      = "../scripts"
    destination = "~"

    connection {
      user        = "acl"
      private_key = "${file("./key")}"
    }
  }

  provisioner "file" {
    source      = "./gcloud-keys"
    destination = "~"

    connection {
      user        = "acl"
      private_key = "${file("./key")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp -r ~/scripts/skel/. /etc/skel/",
      "sudo chmod +x ~/scripts/createUsers.sh",
      "sudo ~/scripts/createUsers.sh ${var.number-of-users} ${var.user-password}",
      "sudo chmod +x ~/scripts/configureGcloud.sh",
      "sudo ~/scripts/configureGcloud.sh ${var.number-of-users} ${var.user-password} ${var.gcloud-zone} ${var.gcloud-project}",
    ]
  }

  connection {
    user        = "acl"
    private_key = "${file("./key")}"
  }
}

output "ip" {
  value = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
}
