#!/bin/sh

set -eu

cd ..

# -----------------------------------------------------------------------------

REPO_PATH="$(pwd)/../../.."
VERSION=$(cat "$REPO_PATH/source/mastering/version")

# -----------------------------------------------------------------------------

stamp() {
    sed "s/^VERSION=0\.0\.0\$/VERSION=$VERSION/" "$1" | sponge "$1"
}

get_output_file_name() {
    echo "adhoc-file-signer-$VERSION-$1"
}

# -----------------------------------------------------------------------------

pack_client() {
    mkdir .obj/client

    cp "$REPO_PATH/source/client/adhoc-sign-tool" .obj/client
    cp "$REPO_PATH/source/client"/*.bat .obj/client
    cp "$REPO_PATH/source/client"/*.md .obj/client
    cp "$REPO_PATH/LICENSE" .obj/client
    cp "$REPO_PATH/docs/ABOUT" .obj/client

    chmod +x .obj/client/adhoc-sign-tool

    stamp .obj/client/adhoc-sign-tool

    output_file_name="$(get_output_file_name client).tar.gz"

    echo "$output_file_name:"
    cd .obj/client
    tar czvf "../../output/$output_file_name" -- * | sed 's_^_  adding: _'
    cd ../..
}

pack_server() {
    cp -r "$REPO_PATH/source/server" .obj
    find .obj/server -type f -name justfile -exec rm {} +
    find .obj/server -type f -name '*.code-workspace' -exec rm {} +

    cp "$REPO_PATH/LICENSE" .obj/server
    cp "$REPO_PATH/docs/ABOUT" .obj/server

    find .obj/server -type f -name '*.sh' -exec chmod +x {} +
    chmod +x .obj/server/bin/adhoc-sign-server .obj/server/usr/bin/signtool

    stamp .obj/server/bin/adhoc-sign-server
    stamp .obj/server/lib/sign-file.sh

    output_file_name="$(get_output_file_name server).tar.gz"

    echo "$output_file_name:"
    cd .obj/server
    tar czvf "../../output/$output_file_name" -- * | sed 's_^_  adding: _'
    cd ../..
}

# -----------------------------------------------------------------------------

pack_client
pack_server

# -----------------------------------------------------------------------------

cd output

echo "Calculating checksums..."
sha256sum -b -- * | tr '*' ' ' >SHA256SUMS
