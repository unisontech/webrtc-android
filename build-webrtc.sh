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
}

set_environment_for_arm() {
    set_environment
    export GYP_DEFINES="$GYP_DEFINES OS=android"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_arm"
    export STRIP="$ANDROID_NDK/toolchains/arm-linux-androideabi-4.6/prebuilt/linux-x86/arm-linux-androideabi/bin/strip"
}

set_environment_for_x86() {
   set_environment
   export GYP_DEFINES="$GYP_DEFINES OS=android target_arch=ia32"
   export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_x86"
   export STRIP="$ANDROID_NDK/toolchains/x86-4.6/prebuilt/linux-x86/bin/i686-linux-android-strip"
}

build() {
    echo "-- building webrtc/$1"
    pushd trunk || fail
    set_environment_for_$1 || fail
    ./setup_links.py --force || fail
    gclient sync --force || fail
    gclient runhooks --force || fail
    ninja -C out_$1/Debug libjingle_peerconnection_so libjingle_peerconnection.jar || fail
    ninja -C out_$1/Release libjingle_peerconnection_so libjingle_peerconnection.jar || fail
    $STRIP -s out_$1/Release/libjingle_peerconnection_so.so || fail
    pushd out_$1/Release || fail
    popd
    popd
    echo "-- webrtc/$1 has been sucessfully built"
}

prerequisites() {
    export PATH=`pwd`/depot_tools:"$PATH"
    which gclient >/dev/null
    if [ $? -ne 0 ]; 
    then
	   git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git || fail
	   export PATH=`pwd`/depot_tools:"$PATH"
    fi
    gclient sync --nohooks || fail
    pushd trunk
    source ./build/android/envsetup.sh
    popd
    rm -rf mavenrepo
    rm -rf repo
    rm -rf webrtc_pom
}

pushToGit() {
    REVISION=`grep -Po '(?<=@)[^\"]+' .gclient`
    pushd mavenrepo    
    git add repo/*
    git commit -m "webrtc revision: $REVISION"
    git push origin master || fail
    popd
}

prerequisites

build arm
build x86

git clone git@github.com:unisontech/webrtc-repo.git mavenrepo

make

pushToGit



