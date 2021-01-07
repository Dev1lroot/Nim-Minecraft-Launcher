import os, system, json, rdstdin, sequtils, strutils

type
  User* = ref object of RootObj
    uuid*: string
    username*: string
    accessToken*: string
  Client* = ref object of RootObj
    path*: string
    version*: string

proc getAssetIndex(path, mc_version: string): string =
  if(fileExists(path&"/assets/indexes/"&mc_version&".json")):
    return mc_version
  else:
    return mc_version.split(".")[0]&"."&mc_version.split(".")[1]

proc getVersionConfigPath(path, version: string): string =
  return path&"/versions/"&version&"/"&version&".json"

proc getLibraryClasspath(path, lib: string): string =
  return path&"/libraries/"&lib.split(":")[0].replace(".","/")&"/"&lib.split(":")[1]&"/"&lib.split(":")[2]&"/" 

proc getLibraries(path, config: string): seq[string] =
  var libs: seq[string]
  var json = parseJson(readFile(config))
  for lib in json["libraries"]:
    var classpath = getLibraryClasspath(path, lib["name"].getStr())
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

proc collectClasspath(path, fg_version, mc_version: string): string =
  echo "LOADING FORGE CLASSPATH"
  var fg_libs = getLibraries(path, getVersionConfigPath(path, fg_version))
  
  echo "LOADING GAME CLASSPATH"
  var mc_libs = getLibraries(path, getVersionConfigPath(path, mc_version))
  
  var gm_libs = concat(fg_libs, mc_libs)
  return gm_libs.join(";")&";"&path&"/versions/"&mc_version&"/"&mc_version&".jar";

proc startClient(client: Client, user: User) =
  if(fileExists(getVersionConfigPath(client.path, client.version))):

    var json = parseJson(readFile(getVersionConfigPath(client.path, client.version)))
    var cp = collectClasspath(client.path, client.version, json["inheritsFrom"].getStr())

    var args: seq[string]
    args.add "-Xms1024M"
    args.add "-Xmx1024M"
    args.add "-Djava.library.path="&client.path&"/versions/"&json["jar"].getStr()&"/natives"
    args.add "-cp "&cp
    args.add "net.minecraft.launchwrapper.Launch"
    args.add "--width 854"
    args.add "--height 480"
    args.add "--username "&user.username
    args.add "--uuid "&user.uuid
    args.add "--accessToken "&user.accessToken
    args.add "--userType mojang"
    args.add "--version "&client.version
    args.add "--gameDir "&client.path
    args.add "--assetsDir "&client.path&"/assets"
    args.add "--assetIndex "&getAssetIndex(client.path, json["inheritsFrom"].getStr())
    args.add "--tweakClass net.minecraftforge.fml.common.launcher.FMLTweaker"
    args.add "--versionType Forge"
    discard execShellCmd("java "&args.join(" "))

var client = Client(
  path: $getCurrentDir(), 
  version: "1.12.2-forge1.12.2-14.23.5.2847")

var user = User(
  uuid: "N/A", 
  username: "Dev1lroot", 
  accessToken: "N/A")

startClient(client, user)
