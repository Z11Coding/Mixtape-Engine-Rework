package backend;
import objects.Note;
class COD
{
    public static var deathVar:String;
    public static var missDeath:String;
	public static var missDeath2:String;
    public static var rDeath:String;
	public static var ukTxt:String;
	public static var COD:String;
	public static var scriptCOD:String;
	public static var custom:String;

	public static function initCOD():Void
	{
		deathVar = "Cause of death: ";
    	missDeath = "Missed a note at 0 health.";
		missDeath2 = "Missed a note.";
		rDeath = "Pressed R.";
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
					COD = missDeath;
				case "miss":
					COD = missDeath2;
				case "r":
					COD = rDeath;
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
}