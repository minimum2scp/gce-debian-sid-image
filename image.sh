#! /bin/sh

set -e
#set -x

image_project=$(jq -r '.project_id' packer-vars.json)
image_family=$(jq -r '.builders[0].image_family' packer-template.json)

help (){
  echo "Usage: ${0##*/} [list|build|deprecate]"
  exit 1
}

list (){
  gcloud compute images list --project ${image_project} --filter "family = ${image_family}" --show-deprecated
}

build (){
  packer build -var-file=packer-vars.json packer-template.json
}

deprecate (){
  latest_image_name=$(gcloud compute images describe-from-family ${image_family} --project ${image_project} --format json | jq -r '.name')
  echo "Latest Image: ${latest_image_name}"

  old_images=$(gcloud compute images list --project ${image_project} --filter "family = ${image_family} AND -name = ${latest_image_name}" --format json | jq -r '.[]|.name')

  if [ -z "${old_images}" ]; then
    echo "No old images."
  else
    for i in ${old_images}; do
      echo "Deprecate old image ${i} ..."
      gcloud compute images deprecate --project ${image_project} ${i} --state DEPRECATED --replacement ${latest_image_name}
      echo ""
    done
  fi
}

case "$1" in
  list)        list;;
  build)       build;;
  deprecate)   deprecate;;
  *)           help;;
esac


