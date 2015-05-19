VERSION:=`grep -Po '(?<==)[^\"]+' release-version`
POM_PATH:=poms/

.PHONY: repo

all: repo

clean:
	@rm -Rf ${CURDIR}/mavenrepo

repo:
	@echo ${CURDIR}/mavenrepo
	@mvn deploy:deploy-file -Dversion=${VERSION} -DpomFile=${POM_PATH}/libjingle_peerconnection_so.pom.xml -Dfile=src/out_arm/Release/AppRTCDemo/libs/armeabi-v7a/libjingle_peerconnection_so.so -Durl=file://${CURDIR}/mavenrepo -DcreateChecksum=true -Dclassifier=armeabi
	@mvn deploy:deploy-file -Dversion=${VERSION} -DpomFile=${POM_PATH}/libjingle_peerconnection.pom.xml -Dfile=src/out_arm/Release/libjingle_peerconnection.jar -Durl=file://${CURDIR}/mavenrepo -DcreateChecksum=true
	@mvn deploy:deploy-file -Dversion=${VERSION} -DpomFile=${POM_PATH}/libjingle_peerconnection_so.pom.xml -Dfile=src/out_x86/Release/AppRTCDemo/libs/x86/libjingle_peerconnection_so.so -Durl=file://${CURDIR}/mavenrepo -DcreateChecksum=true -Dclassifier=x86
