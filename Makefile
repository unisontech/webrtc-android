REVISION:=`grep -Po '(?<=@)[^\"]+' .gclient`
POM_PATH:=poms/

.PHONY: all clean

all: repo

clean:
	@rm -Rf ${CURDIR}/mavenrepo

repo:
	@echo ${CURDIR}/mavenrepo
	@mvn deploy:deploy-file -Dversion=${REVISION} -DpomFile=${POM_PATH}/libjingle_peerconnection_so.pom.xml -Dfile=src/out_arm/Release/libjingle_peerconnection_so.so -Durl=file://${CURDIR}/mavenrepo -DcreateChecksum=true -Dclassifier=armeabi
	@mvn deploy:deploy-file -Dversion=${REVISION} -DpomFile=${POM_PATH}/libjingle_peerconnection.pom.xml -Dfile=src/out_arm/Release/libjingle_peerconnection.jar -Durl=file://${CURDIR}/mavenrepo -DcreateChecksum=true
	@mvn deploy:deploy-file -Dversion=${REVISION} -DpomFile=${POM_PATH}/libjingle_peerconnection_so.pom.xml -Dfile=src/out_x86/Release/libjingle_peerconnection_so.so -Durl=file://${CURDIR}/mavenrepo -DcreateChecksum=true -Dclassifier=x86
