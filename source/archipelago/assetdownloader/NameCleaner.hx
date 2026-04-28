package archipelago.assetdownloader;

/**
 * Cleans item and game names for consistent file matching.
 * Removes special characters and normalizes to lowercase.
 */
class NameCleaner
{
	public function new() {}

	/**
	 * Cleans a name by removing special characters and converting to lowercase
	 */
	public function cleanName(name:String):String
	{
		if (name == null || name.length == 0)
			return "";

		var cleaned = name.toLowerCase();

		// Characters to remove
		var charsToIgnore = [" ", "_", ":", "'", "<", ">"];

		for (char in charsToIgnore)
		{
			cleaned = StringTools.replace(cleaned, char, "");
		}

		return cleaned;
	}
}
