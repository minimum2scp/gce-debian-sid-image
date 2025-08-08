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
  expected_source_image = "debian-12-bookworm-v20250709"
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

  provisioner "shell" {
    inline = [
      "sha256sum -c << EOS",
      "1918052cfce2c404000c4d5dd9e4d5508cb5396c6abdc91a5cd9c93e10e4a40f  /etc/apt/mirrors/debian-security.list",
      "19690961457aafed526efdea57f8bcc562c0e9f1d051981dac80e703cee6444f  /etc/apt/mirrors/debian.list",
      "8e03753c5b9417ce801b5f747736f2cb8b6e7c02c4cf0f5142591ad93d2563f5  /etc/apt/sources.list",
      "28330d6e47de49f8a52460fa4dcd30ba06474689340e8cfd9cabb697a2669b19  /etc/apt/sources.list.d/debian.sources",
      "261e40fc093a2aca99c6140b7598b8c145e23ede80f26e933511863600dd89eb  /etc/apt/sources.list.d/google-cloud.list",
      "EOS"
    ]
  }

  provisioner "file" {
    destination = "/tmp"
    source      = "scripts"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends etckeeper",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y --purge unattended-upgrades",
    ]
  }

  provisioner "file" {
    destination = "/tmp/debian.sources"
    source      = "debian.sources"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo install -m 644 -o root -g root /tmp/debian.sources /etc/apt/sources.list.d/debian.sources",
      "sudo DEBIAN_FRONTEND=noninteractive etckeeper commit 'apt: updated to sid'",
      "sudo apt-get update",
      "sudo apt-mark hold linux-image-cloud-amd64",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y --no-install-recommends --auto-remove --purge",
      "sudo apt-mark unhold linux-image-cloud-amd64",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y --no-install-recommends --auto-remove --purge",
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
