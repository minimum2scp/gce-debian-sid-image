packer {
  required_plugins {
    # https://www.packer.io/docs/builders/googlecompute
    googlecompute = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variables {
  machine_type      = "e2-medium"
  project_id        = ""
  skip_create_image = false
}

locals {
  expected_source_image = "debian-12-bookworm-v20230912"
  image_family          = "debian-sid"
  image_name            = "${local.image_family}-v${formatdate("YYYYMMDD-hhmmss", timestamp())}"
}

source "googlecompute" "debian-12" {
  disk_size         = 10
  image_description = "Debian sid (source image: ${local.expected_source_image})"
  image_family      = "${local.image_family}"
  image_name        = "${local.image_name}"
  machine_type      = "${var.machine_type}"
  metadata = {
    block-project-ssh-keys = "TRUE"
  }
  preemptible             = true
  project_id              = "${var.project_id}"
  skip_create_image       = var.skip_create_image
  source_image_family     = "debian-12"
  source_image_project_id = ["debian-cloud"]
  ssh_username            = "packer"
  zone                    = "us-west1-a"
}

build {
  sources = ["source.googlecompute.debian-12"]

  provisioner "shell" {
    inline = [
      "expected_image=${local.expected_source_image}",
      "actual_image=$(basename $(curl -sS -H Metadata-Flavor:Google http://metadata.google.internal/computeMetadata/v1/instance/image))",
      "if [ $${expected_image} != $${actual_image} ]; then",
      "  echo \"ERROR: image is updated\"",
      "  echo \"  expected: $${expected_image}\"",
      "  echo \"  got:      $${actual_image}\"",
      "  exit 1",
      "fi"
    ]
  }

  provisioner "file" {
    destination = "/tmp"
    source      = "scripts"
  }

  provisioner "shell" {
    inline = [
      "sudo cp -a /etc/chrony/chrony.conf /var/tmp/chrony.conf.google",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends etckeeper",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y --purge chrony unattended-upgrades",
    ]
  }

  provisioner "file" {
    destination = "/tmp/sources.list"
    source      = "sources.list"
  }

  provisioner "shell" {
    inline = [
      "sudo install -m 644 -o root -g root /tmp/sources.list /etc/apt/sources.list",
      "sudo DEBIAN_FRONTEND=noninteractive etckeeper commit 'apt: updated to sid'",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y --no-install-recommends --auto-remove --purge",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y chrony",
      "sudo cp -a /var/tmp/chrony.conf.google /etc/chrony/chrony.conf",
      "if sudo etckeeper unclean; then sudo etckeeper commit 'chrony: copied original chrony.conf from debian-12 image family'; fi",
    ]
  }

  provisioner "shell" {
    inline            = ["python3 /tmp/scripts/mk-manifest.py"]
  }

  provisioner "file" {
    destination = "manifest/packages.jsonl"
    direction   = "download"
    source      = "/tmp/packages.jsonl"
  }

  provisioner "file" {
    destination = "manifest/packages.txt"
    direction   = "download"
    source      = "/tmp/packages.txt"
  }
}
