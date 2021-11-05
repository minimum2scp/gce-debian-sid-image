
variable "expected_source_image" {
  type    = string
  default = "debian-11-bullseye-v20211105"
}

variable "project_id" {
  type    = string
  default = ""
}
# The "legacy_isotime" function has been provided for backwards compatability, but we recommend switching to the timestamp and formatdate functions.

source "googlecompute" "autogenerated_1" {
  disk_size         = 10
  image_description = "Debian sid (source image: ${var.source_image})"
  image_family      = "debian-sid"
  image_name        = "debian-sid-v${legacy_isotime("20060102-150405")}"
  machine_type      = "e2-micro"
  metadata = {
    block-project-ssh-keys = "TRUE"
  }
  preemptible             = true
  project_id              = "${var.project_id}"
  source_image_family     = "debian-11"
  source_image_project_id = "debian-cloud"
  ssh_username            = "packer"
  zone                    = "us-west1-a"
}

build {
  sources = ["source.googlecompute.autogenerated_1"]

  provisioner "shell" {
    inline = ["expected_image=${var.expected_source_image}", "actual_image=$(basename $(curl -sS -H Metadata-Flavor:Google http://metadata.google.internal/computeMetadata/v1/instance/image))", "if [ $${expected_image} != $${actual_image} ]; then", "  echo \"ERROR: image is updated\"", "  echo \"  expected: $${expected_image}\"", "  echo \"  got:      $${actual_image}\"", "  exit 1", "fi"]
  }

  provisioner "file" {
    destination = "/tmp"
    source      = "scripts"
  }

  provisioner "shell" {
    expect_disconnect = false
    inline            = ["sudo cp -a /etc/chrony/chrony.conf /var/tmp/chrony.conf.google", "sudo apt-get update", "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends etckeeper", "sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y --purge chrony unattended-upgrades"]
  }

  provisioner "file" {
    destination = "/tmp/sources.list"
    source      = "sources.list"
  }

  provisioner "shell" {
    expect_disconnect = false
    inline            = ["sudo install -m 644 -o root -g root /tmp/sources.list /etc/apt/sources.list", "sudo DEBIAN_FRONTEND=noninteractive etckeeper commit 'apt: updated to sid'", "sudo apt-get update", "sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y --no-install-recommends --auto-remove --purge", "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y chrony", "sudo cp -a /var/tmp/chrony.conf.google /etc/chrony/chrony.conf", "if sudo etckeeper unclean; then sudo etckeeper commit 'chrony: copied original chrony.conf from debian-11 image family'; fi"]
  }

  provisioner "shell" {
    expect_disconnect = false
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