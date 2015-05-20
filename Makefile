REVISION:=$(shell git --git-dir=src/.git  rev-parse HEAD)
$(shell git --git-dir=src/.git --work-tree src diff > patches/${REVISION}.diff)

POM_PATH:=poms/

.PHONY: all clean

repo: makepoms mavenrepo

clean:

mavenrepo:
	@echo ${CURDIR}/repo
	@mvn deploy:deploy-file -Dversion=${REVISION} -DpomFile=${POM_PATH}/libjingle_peerconnection_so.pom.xml -Dfile=src/out_arm/Release/lib/libjingle_peerconnection_so.so -Durl=file://${CURDIR}/repo -DcreateChecksum=true -Dclassifier=armeabi
	@mvn deploy:deploy-file -Dversion=${REVISION} -DpomFile=${POM_PATH}/libjingle_peerconnection.pom.xml -Dfile=src/out_arm/Release/libjingle_peerconnection.jar -Durl=file://${CURDIR}/repo -DcreateChecksum=true
	@mvn deploy:deploy-file -Dversion=${REVISION} -DpomFile=${POM_PATH}/libjingle_peerconnection_so.pom.xml -Dfile=src/out_x86/Release/lib/libjingle_peerconnection_so.so -Durl=file://${CURDIR}/repo -DcreateChecksum=true -Dclassifier=x86
	@mvn deploy:deploy-file -Dversion=${REVISION} -DpomFile=${POM_PATH}/libjingle_peerconnection_patch.pom.xml -Dfile=patches/${REVISION}.diff -Durl=file://${CURDIR}/repo -D createChecksum=true

makepoms:
	 sed -e 's/$${version}/${REVISION}/'  poms/libjingle_peerconnection.pom.xml.tmpl > poms/libjingle_peerconnection.pom.xml
	 sed -e 's/$${version}/${REVISION}/'  poms/libjingle_peerconnection_so.pom.xml.tmpl > poms/libjingle_peerconnection_so.pom.xml
	 sed -e 's/$${version}/${REVISION}/'  poms/libjingle_peerconnection_patch.pom.xml.tmpl > poms/libjingle_peerconnection_patch.pom.xml
	
aar:
	sed -e 's/$${version}/${REVISION}/'  poms/libjingle_peerconnection_aar.pom.xml.tmpl > poms/libjingle_peerconnection_aar.pom.xml
	@mvn deploy:deploy-file -Dversion=${REVISION} -DpomFile=${POM_PATH}/libjingle_peerconnection_aar.pom.xml -Dfile=aar-project/build/outputs/aar/aar-project-release.aar -Durl=file://${CURDIR}/repo -DcreateChecksum=true
