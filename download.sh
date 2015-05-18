#!/bin/bash

fail() {
    echo "*** webrtc build failed"
    exit 1
}

set_environment() {
    export JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64'
    export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=0"
    export GYP_GENERATORS="ninja"
    export GYP_CROSSCOMPILE=1
    export MACH=`uname -m`
}

sync_source() {
    echo "-- downloading sources webrtc"
    pushd trunk || fail
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
    gclient sync || fail
    pushd trunk
    source ./build/android/envsetup.sh
    popd
    rm -rf mavenrepo
    rm -rf repo
    rm -rf webrtc_pom

    trunk/setup_links.py --force || fail
}

prerequisites

sync_source 




