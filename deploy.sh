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

set_environment_for_arm() {
    set_environment
    export GYP_DEFINES="$GYP_DEFINES OS=android"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_arm"
    export STRIP="$ANDROID_NDK/toolchains/arm-linux-androideabi-4.6/prebuilt/linux-$MACH/arm-linux-androideabi/bin/strip"
}

set_environment_for_x86() {
   set_environment
   export GYP_DEFINES="$GYP_DEFINES OS=android target_arch=ia32"
   export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_x86"
   export STRIP="$ANDROID_NDK/toolchains/x86-4.6/prebuilt/linux-$MACH/bin/i686-linux-android-strip"
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

git clone git@github.com:unisontech/webrtc-repo.git mavenrepo

make

pushToGit
