#!/usr/bin/env bash

usage() {
    echo "Usage: ${0} -u https://registry.example.com/v2/"
}

[[ $OPTIND -eq 1 ]] && usage; exit 1

while getopts ":hu:" opt; do
    case "${opt}" in
        h)
            usage
            exit 0
            ;;
        u) 
            BASE_URI="${OPTARG}"
            ;;
        :)
            echo "Option -${OPTARG} takes an argument"
            exit 1
            ;;
        ?)
            echo "Unrecognized option: -${OPTARG}"
            exit 1
            ;;
    esac
done

pull() {

    local REGISTRY="${BASE_URI#*//}"
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
    done < <(curl -s "${BASE_URI}${IMAGE}/tags/list" |jq -cr '.tags[-1]')

}



while read -r IMAGE; do
    tag "${IMAGE}"
done < <(curl -s "${BASE_URI}_catalog" |jq -cr '.repositories[]')
