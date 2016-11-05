# gce-debian-sid-image
Debian sid image for Google Compute Engine

## Prerequisites

 * Google Cloud SDK
 * jq

## Build image

```shell
cp packer-vars.json.example packer-vars.json
editor packer-vars.json
./image.sh build
```

