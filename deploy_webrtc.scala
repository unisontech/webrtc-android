#!/bin/sh
exec scala "$0" "$@"
!#

import java.io.File
import scala.io.Source

object DeployWebrtc {
  import scala.sys.process._

  val groupId = "com.google.webrtc"
  val name = "webrtc"
  val repo:File = new File("repo")


def stripWebrtcRevision:Seq[String] = for {
    line <- Source.fromFile("release-version").getLines().toSeq
    if line.contains("version=")
  } yield line.substring(line.lastIndexOf('=') + 1)


  lazy val extractDiff = "svn" :: "diff" :: "src/" :: Nil

  def exitWithError(status: Int, e: Throwable) = {
    System.err.println(e.getMessage)
    sys.exit(status)
  }


  def main(args: Array[String]):Unit = try {
    val webrtcVersion:String = args.applyOrElse(0, stripWebrtcRevision)

    /*val patchDeployResult = withTmpFileOfExt("patch")(patchFile => {
      if ((extractDiff #> patchFile).! > 0) {
        throw new IllegalStateException("Failed to extract diff")
      }
      deployArtifact(patchFile, "libjingle_peerconnection_patch", "patch", webrtcVersion, None)
    })*/

    val deployResults = for {
      (artifactPath, classifier) <- Seq(
        "src/out_arm/Release/libjingle_peerconnection.jar"   -> None,
        "src/out_arm/Release/AppRTCDemo/libs/armeabi-v7a/libjingle_peerconnection_so.so" -> Some("armeabi"),
        "src/out_x86/Release/AppRTCDemo/libs/x86/libjingle_peerconnection_so.so" -> Some("x86")
      )
    } yield deployArtifact(new File(artifactPath), webrtcVersion, classifier)

    val totalReturnCode = deployResults.reduce(_ + _) /*+ patchDeployResult*/
    if (totalReturnCode > 0) {
      throw new IllegalStateException("Some operation finished with error")
    }
  } catch {
    case e:IllegalArgumentException => exitWithError(1, e)
    case e:IllegalStateException => exitWithError(2, e)
    case any:Throwable => exitWithError(255, any)
  }


  def deployArtifact(file:File, version: String, classifier:Option[String] = None):Int = {
    val fileName = file.getName
    val ext = fileName.substring(fileName.lastIndexOf('.') + 1)
    val baseName = fileName.substring(0, fileName.lastIndexOf('.'))
    deployArtifact(file, baseName, ext, version, classifier)
  }

  def deployArtifact(file:File, artifactName:String, packaging:String,
                     version: String, classifier:Option[String]):Int = if (file.isFile) {
    def generatePomTo = MVN.generatePom(groupId, name, artifactName, version, packaging)(_)
    def deployUsingPomFile = MVN.deployFileWithPom(file, classifier)(_)
    def deploy(tmpFile:File) = deployUsingPomFile(generatePomTo(tmpFile))

    withTmpFileOfExt("pom")(deploy)
  } else {
    throw new IllegalStateException(s"File ${file.getAbsolutePath} does not exists or is directory")
  }


  def withTmpFile[T](f:(File)=>T):T = withTmpFileImpl[T](None, f)

  def withTmpFileOfExt[T](ext:String)(f:(File) => T):T = withTmpFileImpl(Some(ext), f)

  private def withTmpFileImpl[T](ext: Option[String], f:(File) => T):T = {
    val tmpFile = File.createTempFile("tmpfile", ext.orNull)
    try {
      f(tmpFile)
    } finally {
      tmpFile.delete()
    }
  }



  object MVN {
    def deployFileWithPom(file:File, classifier:Option[String] = None)(pom:File) = {
      deployFileWithPomCmd(file, pom, classifier).!
    }

    private def deployFileWithPomCmd(file:File, pom:File, classifier:Option[String] = None) = {
      lazy val classifierArgs = for {
        classifierValue <- classifier
      } yield Map("classifier" -> classifierValue)


      lazy val argsMap = Map[String,String](
        "pomFile" -> pom.getAbsolutePath,
        "file" -> file.getAbsolutePath,
        "url" -> s"file://${repo.getAbsolutePath}",
        "createChecksum" -> "true"
      ) ++ classifierArgs.getOrElse(Map())

      val deployArgs:List[String] = argsMap.map{
        case (key:String, value:String) => s"-D$key=$value"
      }.toList

      "mvn" :: "deploy:deploy-file" :: deployArgs
    }

    def generatePom(org:String, name:String, artifactName: String, version:String, packaging:String)(file:File) = {
      scala.xml.XML.save(file.getAbsolutePath, pomWithArgs(org, name, artifactName, version, packaging), "UTF-8", xmlDecl = true)
      file
    }

    private def pomWithArgs(org:String, name:String, artifactName: String, version:String, packaging:String) =
      <project xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>
        <groupId>{org}</groupId>
        <artifactId>{artifactName}</artifactId>
        <packaging>{packaging}</packaging>
        <version>{version}</version>
        <name>{name}</name>
      </project>
  }
}
