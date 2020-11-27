import os, system, json, rdstdin, sequtils, strutils

let path = $getCurrentDir()

let username = "Dev1lroot"
let version = "1.12.2-forge1.12.2-14.23.5.2847"

proc getAssetIndex(mc_version: string): string =
  if(existsFile(path&"/assets/indexes/"&mc_version&".json")):
    return mc_version
  else:
    return mc_version.split(".")[0]&"."&mc_version.split(".")[1]

proc getVersionConfigPath(version: string): string =
  return path&"/versions/"&version&"/"&version&".json"

proc getLibraryClasspath(lib: string): string =
  return path&"/libraries/"&lib.split(":")[0].replace(".","/")&"/"&lib.split(":")[1]&"/"&lib.split(":")[2]&"/" 

proc getLibraries(config: string): seq[string] =
  var libs: seq[string]
  var json = parseJson(readFile(config))
  for lib in json["libraries"]:
    var classpath = getLibraryClasspath(lib["name"].getStr())
    try:
      if lib["clientreq"].getBool() == true:
        for file in walkDir(classpath):
          echo file.path
          libs.add file.path
    except:
      for file in walkDir(classpath):
        echo file.path
        libs.add file.path
  return libs

proc collectClasspath(fg_version, mc_version: string): string =
  echo "LOADING FORGE CLASSPATH"
  var fg_libs = getLibraries(getVersionConfigPath(fg_version))
  
  echo "LOADING GAME CLASSPATH"
  var mc_libs = getLibraries(getVersionConfigPath(mc_version))
  
  var gm_libs = concat(fg_libs, mc_libs)
  return gm_libs.join(";")&";"&path&"/versions/"&mc_version&"/"&mc_version&".jar";

proc startClient() =
  if(existsFile(getVersionConfigPath(version))):
    let path = $getCurrentDir()

    var json = parseJson(readFile(getVersionConfigPath(version)))
  
    var cp = collectClasspath(version, json["inheritsFrom"].getStr())

    var args: seq[string]
    args.add "-Xms1024M"
    args.add "-Xmx1024M"
    args.add "-Djava.library.path="&path&"/versions/"&json["jar"].getStr()&"/natives"
    args.add "-cp "&cp
    args.add "net.minecraft.launchwrapper.Launch"
    args.add "--width 854"
    args.add "--height 480"
    args.add "--username "&username
    args.add "--uuid N/A"
    args.add "--accessToken N/A"
    args.add "--userType mojang"
    args.add "--version "&version
    args.add "--gameDir "&path
    args.add "--assetsDir "&path&"/assets"
    args.add "--assetIndex "&getAssetIndex(json["inheritsFrom"].getStr())
    args.add "--tweakClass net.minecraftforge.fml.common.launcher.FMLTweaker"
    args.add "--versionType Forge"
    discard execShellCmd("java "&args.join(" "))

startClient()
