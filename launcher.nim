import os, system, json, rdstdin, sequtils, strutils

let path = $getCurrentDir()

let username = "Dev1lroot"
let version = "1.12.2-forge1.12.2-14.23.5.2847" #version folder name in /versions

let vm_args = "-Xms1024M -Xmx1024M -Djava.library.path=I:/.minecraft/versions/1.12.2/natives" #lwjgl64.dll location
let auth = "--username "&username&" --uuid N/A --accessToken N/A --userType mojang" #use username only or setup your identity manually

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

if(existsFile(getVersionConfigPath(version))):
  var file = readFile(getVersionConfigPath(version))
  var json = parseJson(file)

  echo "LOADING FORGE CLASSPATH"
  var fg_libs = getLibraries(getVersionConfigPath(version))

  echo "LOADING GAME CLASSPATH"
  var mc_libs = getLibraries(getVersionConfigPath(json["inheritsFrom"].getStr()))

  echo "LOADING GAME"
  var gm_libs = concat(fg_libs, mc_libs)
  var cp = gm_libs.join(";")
  cp &= ";"&path&"/versions/"&json["jar"].getStr()&"/"&json["jar"].getStr()&".jar";
  discard execShellCmd("java "&vm_args&" -cp "&cp&" net.minecraft.launchwrapper.Launch --width 854 --height 480 "&auth&" --version "&version&" --gameDir "&path&" --assetsDir "&path&"/assets --assetIndex "&getAssetIndex(json["inheritsFrom"].getStr())&" --tweakClass net.minecraftforge.fml.common.launcher.FMLTweaker --versionType Forge")
