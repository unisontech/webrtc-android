# webrtc-android

This is a bunch of shell/scala scripts that is meant to download and build webrtc artifacts for Android and deploy them as Maven repo.
Currently, destination of deployment is set to submodule *repo* of this git repository. Submodule *repo* itself faces the orphan branch *repo* that is meant to hold webrtc binary artifacts.

## before start

Currently webrtc build for Android is only supported on Linux. (unless something changes here http://www.webrtc.org/native-code/android). 

Also you'll need java 7 installed and environmental variable `JAVA_HOME` pointing to the place of it's location.

As part of deployment process is performed via scala script, you'll need scala 2.10 or later installed and included to your `PATH`.

After cloning this project run 
```
git submodule update --init
```
to initialize submodule *repo* and be sure that it faces to branch repo by calling
```
cd repo
git checkout repo
``` 
After that everything should be rerady to start.

## Step-by-step build

One may want to perform some additional steps, like switching to latest release version or run tests before deploying the artifacts. For this goal building process was divided into three steps.

#### 1. Download
To download webrtc source code run
```
./download.sh
```
This will perform sync with https://chromium.googlesource.com/external/webrtc.git that may take a lot of time. After sync process is over, you will have *src* folder that includes all souces needed for webrtc build. It will be checked out to the release version pointed out in *release-version* file. At this point one may call **(standing in _src/_)**
```
git branch -r
```
to get the list of awailable releases. In order to switch your branch to desirable release, edit the *release-version* file to point on desirable release version and re-run *download.sh* script. This time it should be mush faster!

####2. Build
To build webrtc artifacts run
```
./build.sh
```
This will perform build *libjingle_peerconnection.jar* and *libjingle_peerconnection_so.so* binaries that are necessary for integration webrtc into your Android project. If you can't find *libjingle_peerconnection_so.so* it's because of lately it is hidden within *AppRTCDemo* and is located in it's subdirectory `AppRTCDemo/libs/<arch>/libjingle_peerconnection_so.so`.
Both *libjingle_peerconnection.jar* and *AppRTCDemo* are built in Debug and Release modes and for arm and x86 architectures. Release versions of *libjingle_peerconnection_so.so* will be stripped to be more lightweight. *AppRTCDemo* can be considered as reference android project to test current webrtc version performance. 

(TODO: webrtc has it's own testset that can be built and ran on different devices, but they are not built by script currently)

####3. Deploy
To create and deploy maven repo with newly built webrtc binaries run
```
./deploy.sh
```
This will extract *libjingle_peerconnection.jar* and *libjingle_peerconnection_so.so* for both architectures, deploy them as local maven repository into *repo* submodule and push it back into Git.

## All-in-one build

If you are not intend to make any changes and just run the cycle download-build-deploy for current fixed webrtc release version, it is easier to run
```
/.build-webrtc.sh
```
that will perform all previously pointed steps together. As a result you will have new commit to this repository with newly built webrtc binaries placed into *repo* submodule.
