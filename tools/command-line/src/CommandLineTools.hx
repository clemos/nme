package;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.io.Path;
import haxe.rtti.Meta;
import platforms.AndroidPlatform;
import platforms.FlashPlatform;
import platforms.IOSPlatform;
import platforms.IOSView;
import platforms.AndroidView;
import platforms.Platform;
import platforms.LinuxPlatform;
import platforms.MacPlatform;
import platforms.WindowsPlatform;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
import NMEProject;

class CommandLineTools 
{
   public static var nme:String;

   private static var additionalArguments:Array<String>;
   private static var command:String;
   private static var debug:Bool;
   private static var words:Array<String>;
   private static var traceEnabled:Bool;
   private static var host = PlatformHelper.hostPlatform;
   private static var nmeVersion:String;

   private static function buildProject(project:NMEProject) 
   {
      loadProject(project);

      var platform:Platform = null;

      LogHelper.info("", "Using target platform: " + project.target);

      switch(project.target) 
      {
         case Platform.ANDROID:
            platform = new AndroidPlatform(project);

         case Platform.IOSVIEW:
            platform = new IOSView(project);

         case Platform.ANDROIDVIEW:
            platform = new AndroidView(project);

         case Platform.IOS:
            platform = new IOSPlatform(project);

         case Platform.WINDOWS:
            platform = new WindowsPlatform(project);

         case Platform.MAC:
            platform = new MacPlatform(project);

         case Platform.LINUX:
            platform = new LinuxPlatform(project);

         case Platform.FLASH:
            platform = new FlashPlatform(project);
      }

      if (platform != null) 
      {
         var command = project.command.toLowerCase();

         if (command == "display") 
         {
            platform.display();
         }

         if (command == "clean" || project.targetFlags.exists("clean")) 
         {
            LogHelper.info("", "\nRunning command: CLEAN");
            platform.clean();
         }

         if (command == "update" || command == "build" || command == "test") 
         {
            LogHelper.info("", "\nRunning command: UPDATE");
            platform.update();
         }

         if (command == "build" || command == "test") 
         {
            LogHelper.info("", "\nRunning command: BUILD");
            platform.build();
         }

         if (command == "install" || command == "run" || command == "test") 
         {
            LogHelper.info("", "\nRunning command: INSTALL");
            platform.install();
         }

         if (command == "run" || command == "rerun" || command == "test") 
         {
            LogHelper.info("", "\nRunning command: RUN");
            platform.run(additionalArguments);
         }

         if (command == "test" || command == "trace") 
         {
            if (traceEnabled || command == "trace") 
            {
               LogHelper.info("", "\nRunning command: TRACE");
               platform.trace();
            }
         }
      }
   }

   private static function createTemplate() 
   {
      if (words.length > 0) 
      {
         if (words[0] == "project") 
         {
            var id = [ "com", "example", "project" ];

            if (words.length > 1) 
            {
               var name = words[1];
               id = name.split(".");

               if (id.length < 3) 
               {
                  id = [ "com", "example" ].concat(id);
               }
            }

            var company = "Company Name";

            if (words.length > 2) 
            {
               company = words[2];
            }

            var context:Dynamic = { };

            var title = id[id.length - 1];
            title = title.substr(0, 1).toUpperCase() + title.substr(1);

            var packageName = id.join(".").toLowerCase();

            context.title = title;
            context.packageName = packageName;
            context.version = "1.0.0";
            context.company = company;
            context.file = StringTools.replace(title, " ", "");


            /*
            for(define in userDefines.keys()) 
            {
               Reflect.setField(context, define, userDefines.get(define));
            }
            */

            PathHelper.mkdir(title);
            FileHelper.recursiveCopyTemplate([ nme + "/templates/default" ], "project", title, context);

            if (FileSystem.exists(title + "/Project.hxproj")) 
            {
               FileSystem.rename(title + "/Project.hxproj", title + "/" + title + ".hxproj");
            }

         } else if (words[0] == "extension") 
         {
            var title = "Extension";

            if (words.length > 1) 
            {
               title = words[1];
            }

            var file = StringTools.replace(title, " ", "");
            var extension = StringTools.replace(file, "-", "_");
            var className = extension.substr(0, 1).toUpperCase() + extension.substr(1);

            var context:Dynamic = { };
            context.file = file;
            context.extension = extension;
            context.className = className;
            context.extensionLowerCase = extension.toLowerCase();
            context.extensionUpperCase = extension.toUpperCase();

            PathHelper.mkdir(title);
            FileHelper.recursiveCopyTemplate([ nme + "/templates" ], "extension", title, context);

            if (FileSystem.exists(title + "/Extension.hx")) 
            {
               FileSystem.rename(title + "/Extension.hx", title + "/" + className + ".hx");
            }

            if (FileSystem.exists(title + "/project/common/Extension.cpp")) 
            {
               FileSystem.rename(title + "/project/common/Extension.cpp", title + "/project/common/" + file + ".cpp");
            }

            if (FileSystem.exists(title + "/project/include/Extension.h")) 
            {
               FileSystem.rename(title + "/project/include/Extension.h", title + "/project/include/" + file + ".h");
            }
         }
         else
         {
            var sampleName = words[0];

            if (FileSystem.exists(nme + "/samples/" + sampleName)) 
            {
               PathHelper.mkdir(sampleName);
               FileHelper.recursiveCopy(nme + "/samples/" + sampleName, Sys.getCwd() + "/" + sampleName);
            }
            else
            {
               LogHelper.error("Could not find sample project \"" + sampleName + "\"");
            }
         }
      }
      else
      {
         Sys.println("You must specify 'project' or a sample name when using the 'create' command.");
         Sys.println("");
         Sys.println("Usage: ");
         Sys.println("");
         Sys.println(" nme create project \"com.package.name\" \"Company Name\"");
         Sys.println(" nme create extension \"ExtensionName\"");
         Sys.println(" nme create SampleName");
         Sys.println("");
         Sys.println("");
         Sys.println("Available samples:");
         Sys.println("");

         for(name in FileSystem.readDirectory(nme + "/samples")) 
         {
            if (FileSystem.isDirectory(nme + "/samples/" + name)) 
            {
               Sys.println(" - " + name);
            }
         }
      }
   }

   private static function document():Void 
   {
   }

   private static function displayHelp():Void 
   {
      displayInfo();

      Sys.println("");
      Sys.println(" Usage : nme help");
      Sys.println(" Usage : nme [clean|update|build|run|test|display] <project>(target) [options]");
      Sys.println(" Usage : nme create project <package> [options]");
      Sys.println(" Usage : nme create <sample>");
      Sys.println(" Usage : nme rebuild <extension>(targets)");
      Sys.println("");
      Sys.println(" Commands : ");
      Sys.println("");
      Sys.println("  help : Show this information");
      Sys.println("  clean : Remove the target build directory if it exists");
      Sys.println("  update : Copy assets for the specified project/target");
      Sys.println("  build : Compile and package for the specified project/target");
      Sys.println("  run : Install and run for the specified project/target");
      Sys.println("  test : Update, build and run in one command");
      Sys.println("  display : Display information for the specified project/target");
      Sys.println("  create : Create a new project or extension using templates");
      Sys.println("");
      Sys.println(" Targets : ");
      Sys.println("");
      Sys.println("  cpp         : Create applications, for host system (linux,mac,windows)");
      Sys.println("  android     : Create Google Android applications");
      Sys.println("  ios         : Create Apple iOS applications");
      Sys.println("  androidview : Create library files for inclusion in Google Android applications");
      Sys.println("  iosview     : Create library files for inclusion in Apple iOS applications");
      Sys.println("  flash       : Create SWF applications for Adobe Flash Player");
      Sys.println("  neko        : Create application for rapid testing on host system");
      Sys.println("");
      Sys.println(" Options : ");
      Sys.println("");
      Sys.println("  -D : Specify a define to use when processing other commands");
      Sys.println("  -debug : Use debug configuration instead of release");
      Sys.println("  -megatrace : Add maximum debugging");
      Sys.println("  -verbose : Print additional information(when available)");
      Sys.println("  -clean : Add a \"clean\" action before running the current command");
      Sys.println("  -xml : Generate XML type information, useful for documentation");
      Sys.println("  [windows|mac|linux] -neko : Build with Neko instead of C++");
      Sys.println("  [linux] -64 : Compile for 64-bit instead of 32-bit");
      Sys.println("  [android] -arm7 : Compile for arm-7a and arm5");
      Sys.println("  [android] -arm7-only : Compile for arm-7a for testing");
      Sys.println("  [ios] -simulator : Build/test for the device simulator");
      Sys.println("  [ios] -simulator -ipad : Build/test for the iPad Simulator");
      Sys.println("  (run|test) -args a0 a1 ... : Pass remaining arguments to executable");
   }

   private static function displayInfo(showHint:Bool = false):Void 
   {
      Sys.println(" _____________");
      Sys.println("|             |");
      Sys.println("|__  _  __  __|");
      Sys.println("|  \\| \\/  ||__|");
      Sys.println("|\\  \\  \\ /||__|");
      Sys.println("|_|\\_|\\/|_||__|");
      Sys.println("|             |");
      Sys.println("|_____________|");
      Sys.println("");
      Sys.println("NME Command-Line Tools(" + nmeVersion + " @ '" + nme + "')");

      if (showHint) 
      {
         //if (!FileSystem.exits(
         Sys.println("Use \"nme help\" for more commands");
      }
   }

   private static function findProjectFile(path:String):String 
   {
      if (FileSystem.exists(PathHelper.combine(path, "Project.hx"))) 
      {
         return PathHelper.combine(path, "Project.hx");

      } else if (FileSystem.exists(PathHelper.combine(path, "project.nmml"))) 
      {
         return PathHelper.combine(path, "project.nmml");

      } else if (FileSystem.exists(PathHelper.combine(path, "project.xml"))) 
      {
         return PathHelper.combine(path, "project.xml");
      }
      else
      {
         var files = FileSystem.readDirectory(path);
         var matches = [];

         for(file in files) 
         {
            var path = PathHelper.combine(path, file);

            if (FileSystem.exists(path) && !FileSystem.isDirectory(path)) 
            {
               if ((Path.extension(file) == "nmml" && file != "include.nmml") || Path.extension(file) == "hx") 
               {
                  matches.push(path);
               }
            }
         }

         if (matches.length > 0) 
         {
            return matches[0];
         }
      }

      return "";
   }

   private static function generate():Void 
   {
   }

   private static function getBuildNumber(project:NMEProject, increment:Bool = true):Void 
   {
      if (project.app.buildNumber == "1") 
      {
         var versionFile = PathHelper.combine(project.app.path, ".build");
         var version = 1;

         PathHelper.mkdir(project.app.path);

         if (FileSystem.exists(versionFile)) 
         {
            var previousVersion = Std.parseInt(File.getBytes(versionFile).toString());

            if (previousVersion != null) 
            {
               version = previousVersion;

               if (increment) 
               {
                  version ++;
               }
            }
         }

         project.app.buildNumber = Std.string(version);

         try 
         {
            var output = File.write(versionFile, false);
            output.writeString(Std.string(version));
            output.close();

         } catch(e:Dynamic) {}
      }
   }

   public static function getHXCPPConfig(project:NMEProject) : Void
   {
      var environment = Sys.environment();
      var config = "";

      if (environment.exists("HXCPP_CONFIG")) 
      {
         config = environment.get("HXCPP_CONFIG");
      }
      else
      {
         var home = "";

         if (environment.exists("HOME")) 
         {
            home = environment.get("HOME");

         } else if (environment.exists("USERPROFILE")) 
         {
            home = environment.get("USERPROFILE");
         }
         else
         {
            LogHelper.warn("HXCPP config might be missing(Environment has no \"HOME\" variable)");

            return null;
         }

         config = home + "/.hxcpp_config.xml";

         if (host == Platform.WINDOWS) 
         {
            config = config.split("/").join("\\");
         }
      }

      if (FileSystem.exists(config)) 
      {
         LogHelper.info("", "Reading HXCPP config: " + config);

         new NMMLParser(project,config);
      }
      else
      {
         LogHelper.warn("", "Could not read HXCPP config: " + config);
      }
   }

   private static function getVersion():String 
   {
      var data = haxe.Json.parse(File.getContent(nme + "/haxelib.json"));
      return data.version;
   }

   #if (neko && haxe_210)
   public static function __init__ () 
   {
      // Fix for library search paths
      var path = PathHelper.getHaxelib(new Haxelib("nme")) + "ndll/";

      switch(PlatformHelper.hostPlatform) 
      {
         case WINDOWS:

            untyped $loader.path = $array(path + "Windows/", $loader.path);

         case MAC:

            untyped $loader.path = $array(path + "Mac/", $loader.path);

         case LINUX:

            var arguments = Sys.args();
            var raspberryPi = false;

            for(argument in arguments) 
            {
               if (argument == "-rpi") raspberryPi = true;
            }

            if (raspberryPi) 
            {
               untyped $loader.path = $array(path + "RPi/", $loader.path);

            } else if (PlatformHelper.hostArchitecture == Architecture.X64) 
            {
               untyped $loader.path = $array(path + "Linux64/", $loader.path);
            }
            else
            {
               untyped $loader.path = $array(path + "Linux/", $loader.path);
            }

         default:
      }
   }
   #end

   static function loadProject(project:NMEProject)
   {
      LogHelper.info("", "Loading project...");

      var projectFile = "";
      var targetName = "";

      if (words.length == 2) 
      {
         if (FileSystem.exists(words[0])) 
         {
            if (FileSystem.isDirectory(words[0])) 
               projectFile = findProjectFile(words[0]);
            else
               projectFile = words[0];
         }
         targetName = words[1].toLowerCase();
      }
      else
      {
         projectFile = findProjectFile(Sys.getCwd());
         targetName = words[0].toLowerCase();
      }


      if (projectFile == "") 
      {
         LogHelper.error("You must have a \"project.nmml\" file or specify another valid project file when using the '" + command + "' command");
         return null;
      }
      else
         LogHelper.info("", "Using project file: " + projectFile);

      project.haxedefs.set("nme_install_tool", 1);
      project.haxedefs.set("nme_ver", nmeVersion);
      project.haxedefs.set("nme" + nmeVersion.split(".")[0], 1);

      project.setTarget(targetName);

      getHXCPPConfig(project);

      if (host == Platform.WINDOWS) 
      {
         if (project.environment.exists("JAVA_HOME")) 
            Sys.putEnv("JAVA_HOME", project.environment.get("JAVA_HOME"));

         if (Sys.getEnv("JAVA_HOME") != null) 
         {
            var javaPath = PathHelper.combine(Sys.getEnv("JAVA_HOME"), "bin");

            if (host == Platform.WINDOWS) 
               Sys.putEnv("PATH", javaPath + ";" + Sys.getEnv("PATH"));
            else
               Sys.putEnv("PATH", javaPath + ":" + Sys.getEnv("PATH"));
         }
      }

      project.templatePaths.push( nme + "/templates" );

      try { Sys.setCwd(Path.directory(projectFile)); } catch(e:Dynamic) {}

      if (Path.extension(projectFile) == "nmml" || Path.extension(projectFile) == "xml") 
      {
         new NMMLParser(project,Path.withoutDirectory(projectFile));
      }
      else
      {
         LogHelper.error("You must have a \"project.nmml\" file or specify another NME project file when using the '" + command + "' command");
         return null;
      }

      // Better way to do this?
      switch(project.target) 
      {
         case Platform.ANDROID, Platform.IOS,
              Platform.IOSVIEW, Platform.ANDROIDVIEW:

            getBuildNumber(project);

         default:
      }

      return project;
   }

   private static function resolveClass(name:String):Class<Dynamic> 
   {
      if (name.toLowerCase().indexOf("project") > -1) 
      {
         return NMEProject;
      }
      else
      {
         return Type.resolveClass(name);
      }
   }

   public static function main():Void 
   {
      var project = new NMEProject( );

      traceEnabled = true;
      additionalArguments = new Array<String>();

      command = "";

      words = new Array<String>();


      // Haxelib bug
      for(hackDir in ["Linux","Linux64", Sys.systemName(), Sys.systemName()+"64" ])
      {
         try
         {
            if (FileSystem.exists("ndll") && !FileSystem.exists("ndll/" + hackDir) )
                FileSystem.createDirectory("ndll/" + hackDir);
         }
         catch(e:Dynamic) { }
      }


      processArguments(project);

      nmeVersion = getVersion();

      if (LogHelper.verbose) 
      {
         displayInfo();
         Sys.println("");
      }

      switch(command) 
      {
         case "":
            displayInfo(true);

         case "help":
            displayHelp();

         case "document":
            document();

         case "generate":
            generate();

         case "create":
            createTemplate();

         case "clean", "update", "display", "build", "run", "rerun", "install", "uninstall", "trace", "test":

            if (words.length < 1 || words.length > 2) 
            {
               LogHelper.error("Incorrect number of arguments for command '" + command + "'");
               return;
            }

            buildProject(project);

         case "installer", "copy-if-newer":

            // deprecated?
         default:

            LogHelper.error("'" + command + "' is not a valid command");
      }
   }

   private static function processArguments(project:NMEProject):Void 
   {
      var arguments = Sys.args();

      nme = PathHelper.getHaxelib(new Haxelib("nme"));

      var lastCharacter = nme.substr( -1, 1);
      if (lastCharacter == "/" || lastCharacter == "\\") 
         nme = nme.substr(0, -1);

      if (arguments.length > 0) 
      {
         // When the command-line tools are called from haxelib, 
         // the last argument is the project directory and the
         // path to NME is the current working directory 
         var lastArgument = "";
         for(i in 0...arguments.length) 
         {
            lastArgument = arguments.pop();
            if (lastArgument.length > 0) break;
         }

         lastArgument = new Path(lastArgument).toString();
         if (((StringTools.endsWith(lastArgument, "/") && lastArgument != "/") ||
               StringTools.endsWith(lastArgument, "\\")) &&
               !StringTools.endsWith(lastArgument, ":\\")) 
            lastArgument = lastArgument.substr(0, lastArgument.length - 1);

         if (FileSystem.exists(lastArgument) && FileSystem.isDirectory(lastArgument)) 
            Sys.setCwd(lastArgument);
      }

      var catchArguments = false;
      var catchHaxeFlag = false;

      for(argument in arguments) 
      {
         var equals = argument.indexOf("=");

         if (catchHaxeFlag) 
         {
            project.haxeflags.push(argument);
            catchHaxeFlag = false;
         }
         else if (catchArguments) 
            additionalArguments.push(argument);
         else if (equals > 0) 
         {
            var argValue = argument.substr(equals + 1);
            // if quotes remain on the argValue we need to strip them off
            // otherwise the compiler really dislikes the result!
            var r = ~/^['"](.*)['"]$/;
            if (r.match(argValue)) 
               argValue = r.matched(1);

            if (argument.substr(0, 2) == "-D") 
               project.haxedefs.set(argument.substr(2, equals - 2), argValue);
            else if (argument.substr(0, 2) == "--") 
            {
               // this won't work because it assumes there is only ever one of these.
               //projectDefines.set(argument.substr(2, equals - 2), argValue);
               var field = argument.substr(2, equals - 2);

               if (field == "haxedef") 
                  project.haxedefs.set(argValue,"1");
               else if (field == "haxeflag") 
                  project.haxeflags.push(argValue);
               else if (field == "macro") 
                  project.macros.push(StringTools.replace(argument, "macro=", "macro "));
               else if (field == "haxelib") 
               {
                  var name = argValue;
                  var version = "";

                  if (name.indexOf(":") > -1) 
                  {
                     version = name.substr(name.indexOf(":") + 1);
                     name = name.substr(0, name.indexOf(":"));
                  }

                  project.haxelibs.push(new Haxelib(name, version));
               }
               else if (field == "source" || field=="cp" ) 
                  project.classPaths.push(argValue);
               else
                  project.localDefines.set(field, argValue);
            }
            else
               project.haxedefs.set(argument.substr(0, equals), argValue);

         }
         else if (argument.substr(0, 4) == "-arm") 
         {
            var name = argument.substr(1).toUpperCase();
            var value = Type.createEnum(Architecture, name);

            if (value != null) 
               project.architectures.push(value);
         }
         else if (argument == "-64") 
            project.architectures.push(Architecture.X64);
         else if (argument == "-32") 
            project.architectures.push(Architecture.X86);
         else if (argument.substr(0, 2) == "-D") 
            project.haxedefs.set(argument.substr(2), "");
         else if (argument.substr(0, 2) == "-l") 
            project.includePaths.push(argument.substr(2));
         else if (argument == "-v" || argument == "-verbose") 
         {
            project.haxeflags.push("-v");
            LogHelper.verbose = true;
         }
         else if (argument == "-args") 
            catchArguments = true;
         else if (argument == "-notrace") 
            traceEnabled = false;
         else if (argument == "-debug") 
            debug = true;
         else if (argument == "-megatrace") 
            project.megaTrace = project.debug = debug = true;
         else if (command.length == 0) 
            command = argument;
         else if (argument.substr(0, 1) == "-") 
         {
            if (argument.substr(1, 1) == "-") 
            {
               project.haxeflags.push(argument);
               if (argument == "--remap" || argument == "--connect") 
                  catchHaxeFlag = true;
            }
            else
               project.targetFlags.set(argument.substr(1), "");
         }
         else
         {
            words.push(argument);
         }
      }

      project.setCommand(command);
   }
}


