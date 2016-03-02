#!/bin/bash

revision=`cat revision`

fail() {
    echo "*** webrtc build failed"
    exit 1
}

set_environment() {
    export JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64'
    export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=0 OS=android"
    export GYP_GENERATORS="ninja"
    export GYP_CROSSCOMPILE=1
    export MACH=`uname -m`
    export RELEASE_VERSION=`grep -Po '(?<==)[^\"]+' release-version`
}

set_environment_for_arm() {
    set_environment
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_arm"
    export STRIP="$ANDROID_NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-$MACH/arm-linux-androideabi/bin/strip"
}

set_environment_for_x86() {
   set_environment
   export GYP_DEFINES="$GYP_DEFINES target_arch=ia32"
   export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_x86"
   export STRIP="$ANDROID_NDK/toolchains/x86-4.8/prebuilt/linux-$MACH/bin/i686-linux-android-strip"
}

prerequisites() {
    git pull || fail
    if [ -d "depot_tools" ]; then
        echo "depot exists"
    else
        git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git || fail
    fi
    export PATH=`pwd`/depot_tools:"$PATH"
    if [ -d "src" ]; then
        gclient sync || fail
        echo "src exists. Fetch updates"
        pushd src || fail
        git stash save || fail
        rm -r out_arm
        rm -r out_x86
        echo "patches stashed"
        git fetch || fail
        echo "updates fetched"
        popd
    else
        echo "src not found. Fetch all sources"
        fetch webrtc_android || fail
    fi
    pushd src || fail
    git checkout $1
    git stash pop || fail
    echo "patches unstashed"
    . build/android/envsetup.sh
    python webrtc/build/gyp_webrtc
    popd
}

build() {
    echo "-- building webrtc/$1"
    set_environment_for_$1
    pushd src || fail
    python webrtc/build/gyp_webrtc
    ninja -C out_$1/Debug libjingle_peerconnection_so libjingle_peerconnection_java || fail
    ninja -C out_$1/Release libjingle_peerconnection_so libjingle_peerconnection_java || fail
    $STRIP -s out_$1/Release/lib/libjingle_peerconnection_so.so || fail
    pushd out_$1/Release || fail
    popd
    popd
    echo "-- webrtc/$1 has been successfully built"
}

init_mvn_repo() {
    if [ -d "repo" ]; then
        echo "repo exists"
    else
        mkdir repo || fail
    fi
}

cleanDiff() {
    if [ -f "patches/$1.diff" ]; then
        echo "previous diff for revision $1 found"
        rm -f patches/$1.diff
    else
        echo "no diff for revision $1 found."
    fi
}

checkForPatch() {
    if [ -f "patches/$1.diff" ]; then
        echo "diff for revision $1 found"
    else
        echo "no diff for revision $1 found. Have you applied patches?"
        fail
    fi
}

build_aar() {
    pushd aar-project || fail
    echo "arr build for rev: $1"
    ./gradlew -Prevision=$1 build
    popd
}


echo "Building revision: $revision"

prerequisites $revision

build arm
build x86

init_mvn_repo

cleanDiff $revision

make -B repo

checkForPatch $revision

build_aar $revision

make -B aar
