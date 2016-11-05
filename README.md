# gce-debian-sid-image
Debian sid image for Google Compute Engine

## Prerequisites

 * [Packer](https://www.packer.io/)
 * [Google Cloud SDK](https://cloud.google.com/sdk/)
 * [jq](https://stedolan.github.io/jq/)

## Build image

```shell
cp packer-vars.json.example packer-vars.json
editor packer-vars.json
./image.sh build
```

