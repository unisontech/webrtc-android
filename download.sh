#!/bin/bash

fail() {
    echo "*** webrtc build failed"
    exit 1
}

set_environment() {
    export JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64'
    export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 lbjingle_java=1 ibjingle_objc=0 OS=android"
    export GYP_GENERATORS="ninja"
    export GYP_CROSSCOMPILE=1
    export MACH=`uname -m`
    export RELEASE_VERSION=`grep -Po '(?<==)[^\"]+' release-version`
}

sync_source() {
    echo "-- downloading sources webrtc"
    export GYP_DEFINES="$GYP_DEFINES java_home=$JAVA_HOME"
    pushd src || fail
    gclient sync --force || fail
    gclient runhooks --force || fail
    popd
}

prerequisites() {
    export PATH=`pwd`/depot_tools:"$PATH"
    which gclient >/dev/null
    if [ $? -ne 0 ]; 
    then
	   git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git || fail
	   export PATH=`pwd`/depot_tools:"$PATH"
    fi
    set_environment
    gclient sync --with_branch_heads || fail
    pushd src
    git checkout -b release_$RELEASE_VERSION refs/remotes/branch-heads/$RELEASE_VERSION
    source ./build/android/envsetup.sh
    popd

    src/setup_links.py --force || fail
}

prerequisites

sync_source 




