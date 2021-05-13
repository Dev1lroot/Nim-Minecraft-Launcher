import os, osproc, system, json, rdstdin, sequtils, strutils, httpclient, nigui

type
  User* = ref object of RootObj
    uuid*: string
    username*: string
    accessToken*: string
  Client* = ref object of RootObj
    path*: string
    version*: string
    memory*: int

app.init()
  
var window = newWindow()

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
    echo "COLLECTING CLIENT VERSION MANIFEST"
    var json = parseJson(readFile(getVersionConfigPath(client.path, client.version)))
    echo "COLLECTING CLIENT VERSION CLASSPATH"
    var cp = collectClasspath(client.path, client.version, json["inheritsFrom"].getStr())

    var args: seq[string]
    args.add "-Xms1024M"
    args.add "-Xmx" & $client.memory & "M"
    args.add "-Djava.library.path="&client.path&"/natives"
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

    echo "STARTING MINECRAFT"
    discard execProcess("java "&args.join(" "))

proc authClient(username,password,version: string, memory: int) =
  var httpc = newHttpClient()

  var result = httpc.getContent("https://yourcheckserver.net/api/launcher.php?username="&username);
  echo result;
  var data = parseJson(result);

  var client = Client(
    path: $getCurrentDir(), 
    version: version,
    memory: memory
  )

  var user = User(
    uuid: data["uuid"].getStr(), 
    username: username, 
    accessToken: data["token"].getStr())
  sleep(1000);
  if dirExists("versions/" & version & "/natives"):
    try:
      startClient(client, user)
    except:
      window.alert("Unable to start Minecraft Client " & version)
  else:
    window.alert("Unable to find native binary lwjgl.dll")

proc getVersions(): seq[string] =
  var kek: seq[string]
  for version in walkDir("versions/"):
    kek.add version.path.replace("versions\\","")
  return kek

proc runInterface() =
  var container = newLayoutContainer(Layout_Vertical)
  container.padding = 16
  container.xAlign = XAlign_Center
  window.add(container)
  
  var panel_select = newLayoutContainer(Layout_Horizontal)
  panel_select.frame = newFrame("Version")
  panel_select.padding = 4
  panel_select.widthMode = WidthMode_Expand
  container.add(panel_select)
  
  var select_version = newComboBox(getVersions())
  panel_select.add(select_version)
  var select_memory = newComboBox(@["512","1024","2048","4096","8192","16256"])
  panel_select.add(select_memory)
  
  var panel_auth = newLayoutContainer(Layout_Horizontal)
  panel_auth.frame = newFrame("Login")
  panel_auth.padding = 4
  container.add(panel_auth)

  var input_username = newTextBox("")
  panel_auth.add(input_username)

  var input_password = newTextBox("")
  panel_auth.add(input_password)

  var auth = newButton("Login")
  panel_auth.add(auth)


  auth.onClick = proc(event: ClickEvent) =
    authClient(input_username.text,input_password.text,select_version.value,parseInt(select_memory.value))
  
  window.height = 240
  window.show()
  
  app.run()

runInterface()
