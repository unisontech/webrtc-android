#!/bin/bash

fail() {
    echo "*** webrtc build failed"
    exit 1
}

pushToGit() {
    REVISION=`grep -Po '(?<==)[^\"]+' release-version`
    pushd repo    
    git add --all
    git commit -m "webrtc revision: $REVISION"
    git push origin master || fail
    popd
}

pushd repo
git pull origin repo
popd

./deploy_webrtc.scala

pushToGit
