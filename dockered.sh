#!/usr/bin/env bash

BASE_URL="${1}"

[[ -z $BASE_URL ]] && echo "Usage: ${0} https://registry.example.com/v2/" && exit 1

pull() {

    local REGISTRY="${BASE_URL#*//}"
    REGISTRY="${REGISTRY%/v2/}"
    FULL="${REGISTRY}/${FULL_NAME}"

    docker pull "${FULL}"

    TAR_NAME="${FULL##*/}"
    TAR_NAME="${TAR_NAME/:/_}"

    docker save -o "${TAR_NAME}.tar" "${FULL}"

    mkdir "${TAR_NAME}"
    tar -xf "${TAR_NAME}.tar" -C "${TAR_NAME}"

    CONTAINER_ID="$(docker create ${FULL})"
    docker cp "${CONTAINER_ID}:/" "./${TAR_NAME}-rootfs"

    rm -rf "${TAR_NAME}.tar" "${TAR_NAME}"

}

tag() {

    while read -r TAG; do
        FULL_NAME="${IMAGE}:${TAG}"
        pull $FULL_NAME
    done < <(curl -s "${BASE_URL}${IMAGE}/tags/list" |jq -cr '.tags[-1]')

}

while read -r IMAGE; do
    tag "${IMAGE}"
done < <(curl -s "${BASE_URL}_catalog" |jq -cr '.repositories[]')
