#!/bin/bash

fail() {
    echo "*** webrtc build failed"
    exit 1
}

set_environment() {
    export JAVA_HOME='/usr/lib/jvm/java-7-openjdk-amd64'
    export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_java=1 libjingle_objc=0 OS=android"
    export GYP_GENERATORS="ninja"
    export GYP_CROSSCOMPILE=1
    export MACH=`uname -m`
    export RELEASE_VERSION=`grep -Po '(?<==)[^\"]+' release-version`
}

set_environment_for_arm() {
    set_environment
    export GYP_DEFINES="$GYP_DEFINES OS=android"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_arm"
    export STRIP="$ANDROID_NDK/toolchains/arm-linux-androideabi-4.6/prebuilt/linux-$MACH/arm-linux-androideabi/bin/strip"
    export ABI="armeabi-v7a"
}

set_environment_for_x86() {
   set_environment
   export GYP_DEFINES="$GYP_DEFINES OS=android target_arch=ia32"
   export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_x86"
   export STRIP="$ANDROID_NDK/toolchains/x86-4.6/prebuilt/linux-$MACH/bin/i686-linux-android-strip"
   export ABI="x86"
}

build() {
    echo "-- building webrtc/$1"
	rm ./.gclient_entries
    src/setup_links.py --force || fail
    pushd src || fail
    set_environment_for_$1 || fail
    gclient sync --force || fail
    gclient runhooks --force || fail
    ninja -C out_$1/Debug AppRTCDemo libjingle_peerconnection.jar || fail
    ninja -C out_$1/Release AppRTCDemo libjingle_peerconnection.jar || fail
    $STRIP -s out_$1/Release/AppRTCDemo/libs/$ABI/libjingle_peerconnection_so.so || fail
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
    set_environment
    gclient sync --with_branch_heads || fail
    pushd src 
    git checkout -b release_$RELEASE_VERSION refs/remotes/branch-heads/$RELEASE_VERSION
    source ./build/android/envsetup.sh
    popd
}

pushToGit() {
    REVISION=`grep -Po '(?<==)[^\"]+' release-version`
    pushd repo    
    git add --all
    git commit -m "webrtc revision: $REVISION"
    #git push origin master || fail
    popd
}

prerequisites

build arm
build x86

pushd repo
git pull origin repo
popd

make

pushToGit



