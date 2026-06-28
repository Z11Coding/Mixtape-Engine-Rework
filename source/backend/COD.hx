package backend;
import objects.Note;
class COD
{
	public static var deathVar:String = "Cause of death: ";
  public static var ukTxt:String;
	public static var COD:String;
	public static var scriptCOD:String;
	public static var custom:String;

	public static function initCOD():Void
	{
		ukTxt = "Unknown.";
		scriptCOD = "???";
		COD = "???";
		custom = "???";
	}

	public static function setPresetCOD(?note:Note, ?reason:String) // Backwards Compat
	{
		if (scriptCOD != "???")
			COD = scriptCOD;
		else if (note != null && note.cod != "???")
			COD = note.cod;
		else
		{
			switch (reason)
			{
				case "miss0":
					COD = "Missed a note at 0 health.";
				case "miss":
					COD = "Missed a note.";
				case "r":
					COD = "Pressed R.";
				case "badNote":
					COD = "Hit a Hurt Note.";
				case "custom":
					COD = custom;
				default:
					COD = ukTxt;
			}
		}
	}

	public static function setCOD(?o:Dynamic, ?reason:String) // Backwards Compat
	{
		COD = reason == null ? ukTxt : reason;
	}

	public static function getCOD():String
		return deathVar+"\n[pause:0.5]"+COD;

	public static function getCODNoPause():String
		return deathVar+"\n"+COD;

	public static function getCODNoVar():String
		return COD;

	public static function resetCOD():Void
	{
		COD = "???";
	}
}
