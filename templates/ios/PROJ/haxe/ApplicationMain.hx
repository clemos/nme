#if (!macro || !haxe3)
import nme.Assets;


class ApplicationMain
{
   
   public static function main()
   {
      nme.AssetData.create();

      nme.Lib.setPackage("::APP_COMPANY::", "::APP_FILE::", "::APP_PACKAGE::", "::APP_VERSION::");
      ::if (sslCaCert != "")::
      nme.net.URLLoader.initialize(nme.installer.Assets.getResourceName("::sslCaCert::"));
      ::end::
      
      nme.display.Stage.shouldRotateInterface = function(orientation:Int):Bool
      {
         ::if (WIN_ORIENTATION == "portrait")::
         if (orientation == nme.display.Stage.OrientationPortrait || orientation == nme.display.Stage.OrientationPortraitUpsideDown)
         {
            return true;
         }
         return false;
         ::elseif (WIN_ORIENTATION == "landscape")::
         if (orientation == nme.display.Stage.OrientationLandscapeLeft || orientation == nme.display.Stage.OrientationLandscapeRight)
         {
            return true;
         }
         return false;
         ::else::
         return true;
         ::end::
      }
      
      nme.Lib.create(function()
         {
            //if (::WIN_WIDTH:: == 0 && ::WIN_HEIGHT:: == 0)
            //{
               nme.Lib.current.stage.align = nme.display.StageAlign.TOP_LEFT;
               nme.Lib.current.stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
            //}
            
            nme.Lib.current.loaderInfo = nme.display.LoaderInfo.create (null);
            
            //nme.Lib.current.stage.addEventListener (nme.events.Event.RESIZE, initialize);
            initialize ();
         },
         ::WIN_WIDTH::, ::WIN_HEIGHT::,
         ::WIN_FPS::,
         ::WIN_BACKGROUND::,
         (::WIN_HARDWARE:: ? nme.Lib.HARDWARE : 0) |
         (::WIN_ALLOW_SHADERS:: ? nme.Lib.ALLOW_SHADERS : 0) |
         (::WIN_REQUIRE_SHADERS:: ? nme.Lib.REQUIRE_SHADERS : 0) |
         (::WIN_DEPTH_BUFFER:: ? nme.Lib.DEPTH_BUFFER : 0) |
         (::WIN_STENCIL_BUFFER:: ? nme.Lib.STENCIL_BUFFER : 0) |
         (::WIN_RESIZABLE:: ? nme.Lib.RESIZABLE : 0) |
         (::WIN_ANTIALIASING:: == 4 ? nme.Lib.HW_AA_HIRES : 0) |
         (::WIN_ANTIALIASING:: == 2 ? nme.Lib.HW_AA : 0),
         "::APP_TITLE::"
      );
      
   }
   
   
   private static function initialize ():Void
   {
      //nme.Lib.current.stage.removeEventListener (nme.events.Event.RESIZE, initialize);
      
      var hasMain = false;
      
      for (methodName in Type.getClassFields(::APP_MAIN::))
      {
         if (methodName == "main")
         {
            hasMain = true;
            break;
         }
      }
      
      if (hasMain)
      {
         Reflect.callMethod (::APP_MAIN::, Reflect.field (::APP_MAIN::, "main"), []);
      }
      else
      {
         nme.Lib.current.addChild(cast (Type.createInstance(DocumentClass, []), nme.display.DisplayObject));   
      }
   }
   
}


#if haxe3 @:build(DocumentClass.build()) #end
class DocumentClass extends ::APP_MAIN:: { }

#else

import haxe.macro.Context;
import haxe.macro.Expr;

class DocumentClass {
   
   macro public static function build ():Array<Field> {
      var classType = Context.getLocalClass().get();
      var searchTypes = classType;
      while (searchTypes.superClass != null) {
         if (searchTypes.pack.length == 2 && searchTypes.pack[1] == "display" && searchTypes.name == "DisplayObject") {
            var fields = Context.getBuildFields();
            var method = macro {
               return nme.Lib.current.stage;
            }
            fields.push ({ name: "get_stage", access: [ APrivate, AOverride ], kind: FFun({ args: [], expr: method, params: [], ret: macro :nme.display.Stage }), pos: Context.currentPos() });
            return fields;
         }
         searchTypes = searchTypes.superClass.t.get();
      }
      return null;
   }
   
}
#end
