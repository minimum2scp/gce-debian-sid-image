# gce-debian-sid-image
Debian sid image for Google Compute Engine

## Prerequisites

 * [Packer](https://www.packer.io/)
 * [Google Cloud SDK](https://cloud.google.com/sdk/)
 * [jq](https://stedolan.github.io/jq/)

## Build image

```shell
cp packer-template.auto.pkrvars.hcl.example packer-template.auto.pkrvars.hcl
editor packer-template.auto.pkrvars.hcl
./image.sh build
```

