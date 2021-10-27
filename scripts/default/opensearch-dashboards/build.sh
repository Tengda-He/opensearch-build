#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.

set -ex

function usage() {
    echo "Usage: $0 [args]"
    echo ""
    echo "Arguments:"
    echo -e "-v VERSION\t[Required] OpenSearch version."
    echo -e "-s SNAPSHOT\t[Optional] Build a snapshot, default is 'false'."
    echo -e "-p PLATFORM\t[Optional] Platform, ignored."
    echo -e "-a ARCHITECTURE\t[Optional] Build architecture, ignored."
    echo -e "-o OUTPUT\t[Optional] Output path, default is 'artifacts'."
    echo -e "-h help"
}

function load_opensearch_dashboards_from_cache() {
    if [ ! -d ../OpenSearch-Dashboards ]; then
        echo "No OpenSearch-Dashboards folder found, try to load from cache"
        if [ -d ~/.cache/opensearch-project/$VERSION/OpenSearch-Dashboards/ ]; then
            echo "Copy OpenSearch-Dashboards from cache"
            cp -r ~/.cache/opensearch-project/$VERSION/OpenSearch-Dashboards/ ../
        else
            echo "No correct version OpenSearch-Dashboards found from cache, 
                please run: ./build.sh manifests/1.1.0/opensearch-dashboards-1.1.0.yml --component=OpenSearch-Dashboards"
            exit 1
        fi
    fi
}

while getopts ":h:v:s:o:p:a:" arg; do
    case $arg in
        h)
            usage
            exit 1
            ;;
        v)
            VERSION=$OPTARG
            ;;
        s)
            SNAPSHOT=$OPTARG
            ;;
        o)
            OUTPUT=$OPTARG
            ;;
        p)
            PLATFORM=$OPTARG
            ;;
        a)
            ARCHITECTURE=$OPTARG
            ;;
        :)
            echo "Error: -${OPTARG} requires an argument"
            usage
            exit 1
            ;;
        ?)
            echo "Invalid option: -${arg}"
            exit 1
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo "Error: You must specify the OpenSearch Dashboards version"
    usage
    exit 1
fi

[ -z "$OUTPUT" ] && OUTPUT=artifacts

mkdir -p $OUTPUT/plugins
PLUGIN_NAME=$(basename "$PWD")
# TODO: [CLEANUP] Needed OpenSearch Dashboards git repo to build the required modules for plugins
# This makes it so there is a dependency on having Dashboards pulled already.
load_opensearch_dashboards_from_cache
cp -r ../$PLUGIN_NAME/ ../OpenSearch-Dashboards/plugins
echo "BUILD MODULES FOR $PLUGIN_NAME"
(cd ../OpenSearch-Dashboards && yarn osd bootstrap)
echo "BUILD RELEASE ZIP FOR $PLUGIN_NAME"
(cd ../OpenSearch-Dashboards/plugins/$PLUGIN_NAME && yarn plugin-helpers build)
echo "COPY $PLUGIN_NAME.zip"
cp -r ../OpenSearch-Dashboards/plugins/$PLUGIN_NAME/build/$PLUGIN_NAME-$VERSION.zip $OUTPUT/plugins/
rm -rf ../OpenSearch-Dashboards/plugins/$PLUGIN_NAME