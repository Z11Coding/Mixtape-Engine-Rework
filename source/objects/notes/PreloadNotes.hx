package objects.notes;

typedef PreloadNotes =
{
  var strumTime:Float;
  var lane:Int;
  var sustainLength:Float;
  var noteType:String;
  var mustPress:Bool;
  var gfNote:Bool;
  var animSuffix:String;
  var multSpeed:Float;
  var extraData:Dynamic;
  var holdType:SustainPart;
  var isNotePool:Bool;
  var noteSplashTexture:String;
  var createdFrom:Dynamic;
  var prevNote:Note;
  var isSustainNote:Bool;
  var sustainLength:Float;
}
