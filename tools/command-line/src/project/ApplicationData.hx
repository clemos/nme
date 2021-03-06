
class ApplicationData
{
   // Name of generated application file/directory
   public var file:String;

   // Haxe main class
   public var main:String;
   public var preloader:String;

   // Build directory base
   public var path:String;

   // The build package name - this is the android process name
   // Should have at least 3 parts, like a.b.c
   public var packageName:String;
   // Shows up in title bar
   public var title:String;

   // Version display string
   public var version:String;
   // Unique app store build number
   public var buildNumber:String;
   public var company:String;
   public var companyID:String;
   public var description:String;
   public var url:String;
   // Target versionm
   public var swfVersion:Float;


   public function new()
   {
      file = "MyApplication";

      title = "MyApplication";
      description = "";
      packageName = "com.example.myapp";
      version = "1.0.0";
      company = "Example, Inc.";
      buildNumber = "1";
      companyID = "";

      main = "Main";
      path = "bin";
      preloader = "NMEPreloader";
      swfVersion = 11;
      url = "";
   }
}
