# webrtc-android
This is "WebRTC for Android" set of scripts that is meant to download and build webrtc artifacts for Android and deploy them as Maven repo.
Currently, destination of deployment is set to directory **_repo_**.

## Before start

Currently webrtc build for Android is only supported on Linux. (unless something changes here http://www.webrtc.org/native-code/android). 

Also you'll need java 7 installed and environmental variable `JAVA_HOME` pointing to the place of it's location.

After cloning this project you may want to point exact commit from webrtc repository (https://chromium.googlesource.com/external/webrtc.git/) to checkout with. Just enter it into **_revision_** file and script will checkout to it after sources sync ended.

## Build

To build webrtc artifacts run
```
./build-webrtc.sh
```
This will look for previously downloaded webrtc sources. If none will be found, script will perform full sync with https://chromium.googlesource.com/external/webrtc.git/ repository. This may take over an hour, plaese be patient and **do not interrupt this step**. Otherwise you'll better to remove *src/* directory and start from the scratch. After sources syncing, script will checkout to the commit pointed in **_revision_** file and build *libjingle_peerconnection.jar* and *libjingle_peerconnection_so.so* binaries that are necessary for integration webrtc into your Android project. Both *libjingle_peerconnection.jar* and *libjingle_peerconnection_so.so* are built in Debug and Release modes and for arm and x86 architectures. Release versions of *libjingle_peerconnection_so.so* will be stripped to be more lightweight.

(TODO: webrtc has it's own testset that can be built and ran on different devices, but they are not built by script currently)

#### Deploy

When building process is over script will deploy *libjingle_peerconnection.jar* as local maven repository into **_repo_** directory. At this point it will check for *.diff* file that describes local changes that were made after patches were applied. If there were no local changes made, script will stop and remind you to apply the patches. If this happen, you will need to apply patches and re-run the script.
Patches made for previous builds may be found into **_ patches/ _** directory.

Once patches were applied, script will build `aar` artifact with *libjingle_peerconnection_so.so* inside and *libjingle_peerconnection.jar* attached as dependency. It will also be deployed as local maven repository into **_repo_** submodule.

As a result you will have new maven artifacts set with newly built webrtc binaries placed into **_repo_** directory.
