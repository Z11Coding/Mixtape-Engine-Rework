package yutautil;

import backend.ClientPrefs;
import backend.Language;
import flixel.util.typeLimit.OneOfTwo;
import haxe.Http;
import haxe.Json;
import sys.io.File;

/**
 * Runic Language Support for Mixtape Engine
 * Implements the Tunic Font IPA System
 *
 * The Tunic font renders IPA (International Phonetic Alphabet) phonemes as geometric glyphs.
 * This class converts English text to IPA, then formats it as CV (Consonant-Vowel) syllables
 * for the Tunic font to render.
 *
 * When "runic" language is selected in options:
 * - Fonts are mapped to tunic.otf
 * - Text is converted to IPA and formatted for the font
 * - Falls back to translation file or phonetic approximation for unknown words
 *
 * Font usage: https://github.com/dirdam/fonts/tree/main/tunic
 * IPA System: https://github.com/aryanpingle/Runic
 */
class Runic
{
	/**
	 * Asynchronously loaded IPA Dictionary
	 * Tries: assets/translations/shared/data/ipa_dict.json → GitHub → fallback
	 * Uses AResult/ASync pattern similar to APItem.challengePlaylist
	 */
	private static var ipaDictionary:AResult<Map<String, String>> =
	cast new ASync<Dynamic>(function() {
		// Try loading from local JSON first
		try
		{
			#if sys
			var filePath = 'assets/translations/shared/data/ipa_dict.json';
			if (sys.FileSystem.exists(filePath))
			{
				var content = File.getContent(filePath);
				var parsed = Json.parse(content);

				if (Std.isOfType(parsed, haxe.ds.StringMap) || Std.isOfType(parsed, Dynamic))
				{
					trace("[Runic] Successfully loaded IPA dictionary from local file");
					return cast parsed;
				}
			}
			#end
		}
		catch (e:Dynamic)
		{
			trace("[Runic] Failed to load local ipa_dict.json: " + Std.string(e));
		}

		// Local load failed, try GitHub
		var http = new Http("https://github.com/aryanpingle/Runic/raw/refs/heads/master/public/ipa_dict.json");
		var result:Map<String, String> = null;
		var httpComplete = false;

		http.onData = function(data:String):Void
		{
			try
			{
				var parsed = Json.parse(data);

				if (Std.isOfType(parsed, haxe.ds.StringMap) || Std.isOfType(parsed, Dynamic))
				{
					result = cast parsed;
					trace("[Runic] Successfully loaded IPA dictionary from GitHub");
				}
			}
			catch (e:Dynamic)
			{
				trace("[Runic] Failed to parse GitHub ipa_dict.json: " + Std.string(e));
			}

			httpComplete = true;
		};

		http.onError = function(msg:String):Void
		{
			trace("[Runic] Failed to load GitHub ipa_dict.json: " + msg);
			httpComplete = true;
		};

		try
		{
			http.request(false);
		}
		catch (e:Dynamic)
		{
			trace("[Runic] HTTP request failed: " + Std.string(e));
		}

		// Wait for HTTP request to complete
		var timeout = 0;
		while (!httpComplete && timeout < 100)
		{
			Sys.sleep(50);
			timeout++;
		}

		// If GitHub load succeeded, return it
		if (result != null)
			return result;

		// Fall back to hardcoded dictionary
		trace("[Runic] Using fallback IPA dictionary");
		return [
			// Common words
			"a" => "ə",
			"about" => "əˈbaʊt",
			"after" => "ˈæftər",
			"all" => "ɔːl",
			"also" => "ˈɔːlsoʊ",
			"and" => "ənd",
			"another" => "əˈnʌðər",
			"any" => "ˈɛni",
			"are" => "ɑːr",
			"as" => "əz",
			"at" => "æt",
			"be" => "bi",
			"because" => "bɪˈkɔːz",
			"been" => "bɪn",
			"before" => "bɪˈfɔːr",
			"being" => "ˈbiːɪŋ",
			"both" => "boʊθ",
			"but" => "bʌt",
			"by" => "baɪ",
			"can" => "kæn",
			"come" => "kʌm",
			"day" => "deɪ",
			"did" => "dɪd",
			"do" => "duː",
			"does" => "dʌz",
			"done" => "dʌn",
			"each" => "iːtʃ",
			"even" => "ˈiːvən",
			"every" => "ˈɛvri",
			"fact" => "fækt",
			"feel" => "fiːl",
			"first" => "fɜːrst",
			"for" => "fɔːr",
			"from" => "frʌm",
			"get" => "ɡɛt",
			"give" => "ɡɪv",
			"go" => "ɡoʊ",
			"going" => "ˈɡoʊɪŋ",
			"good" => "ɡʊd",
			"got" => "ɡɑːt",
			"had" => "hæd",
			"has" => "hæz",
			"have" => "hæv",
			"he" => "hi",
			"head" => "hɛd",
			"hear" => "hɪr",
			"hello" => "həˈloʊ",
			"help" => "hɛlp",
			"her" => "hɜːr",
			"here" => "hɪr",
			"high" => "haɪ",
			"him" => "hɪm",
			"his" => "hɪz",
			"how" => "haʊ",
			"i" => "aɪ",
			"if" => "ɪf",
			"in" => "ɪn",
			"into" => "ˈɪntu",
			"is" => "ɪz",
			"it" => "ɪt",
			"its" => "ɪts",
			"just" => "dʒʌst",
			"keep" => "kiːp",
			"know" => "noʊ",
			"left" => "lɛft",
			"let" => "lɛt",
			"life" => "laɪf",
			"like" => "laɪk",
			"long" => "lɔːŋ",
			"look" => "lʊk",
			"made" => "meɪd",
			"make" => "meɪk",
			"many" => "ˈmɛni",
			"me" => "mi",
			"mean" => "miːn",
			"might" => "maɪt",
			"more" => "mɔːr",
			"most" => "moʊst",
			"my" => "maɪ",
			"name" => "neɪm",
			"need" => "niːd",
			"never" => "ˈnɛvər",
			"new" => "njuː",
			"next" => "nɛkst",
			"no" => "noʊ",
			"not" => "nɑːt",
			"now" => "naʊ",
			"of" => "ʌv",
			"off" => "ɔːf",
			"old" => "oʊld",
			"on" => "ɑːn",
			"once" => "wʌns",
			"only" => "ˈoʊnli",
			"open" => "ˈoʊpən",
			"or" => "ɔːr",
			"other" => "ˈʌðər",
			"our" => "ˈaʊər",
			"out" => "aʊt",
			"over" => "ˈoʊvər",
			"own" => "oʊn",
			"page" => "peɪdʒ",
			"part" => "pɑːrt",
			"people" => "ˈpiːpəl",
			"place" => "pleɪs",
			"play" => "pleɪ",
			"right" => "raɪt",
			"said" => "sɛd",
			"same" => "seɪm",
			"say" => "seɪ",
			"see" => "siː",
			"seem" => "siːm",
			"set" => "sɛt",
			"she" => "ʃi",
			"side" => "saɪd",
			"some" => "sʌm",
			"something" => "ˈsʌmθɪŋ",
			"sound" => "saʊnd",
			"speak" => "spiːk",
			"stand" => "stænd",
			"start" => "stɑːrt",
			"stay" => "steɪ",
			"still" => "stɪl",
			"such" => "sʌtʃ",
			"take" => "teɪk",
			"talk" => "tɔːk",
			"tell" => "tɛl",
			"than" => "ðæn",
			"thank" => "θæŋk",
			"that" => "ðæt",
			"the" => "ðə",
			"their" => "ðɛər",
			"them" => "ðɛm",
			"then" => "ðɛn",
			"there" => "ðɛər",
			"these" => "ðiːz",
			"they" => "ðeɪ",
			"thing" => "θɪŋ",
			"think" => "θɪŋk",
			"this" => "ðɪs",
			"those" => "ðoʊz",
			"thought" => "θɔːt",
			"three" => "θriː",
			"through" => "θruː",
			"time" => "taɪm",
			"to" => "tu",
			"too" => "tuː",
			"took" => "tʊk",
			"tree" => "triː",
			"true" => "truː",
			"try" => "traɪ",
			"turn" => "tɜːrn",
			"two" => "tuː",
			"under" => "ˈʌndər",
			"understand" => "ˌʌndərˈstænd",
			"us" => "ʌs",
			"used" => "juːzd",
			"very" => "ˈvɛri",
			"wait" => "weɪt",
			"want" => "wɑːnt",
			"was" => "wʌz",
			"way" => "weɪ",
			"we" => "wi",
			"well" => "wɛl",
			"went" => "wɛnt",
			"were" => "wɜːr",
			"what" => "wʌt",
			"when" => "wɛn",
			"where" => "wɛər",
			"which" => "wɪtʃ",
			"while" => "waɪl",
			"who" => "huː",
			"why" => "waɪ",
			"will" => "wɪl",
			"with" => "wɪð",
			"word" => "wɜːrd",
			"world" => "wɜːrld",
			"would" => "wʊd",
			"write" => "raɪt",
			"written" => "ˈrɪtən",
			"yes" => "jɛs",
			"you" => "juː",
			"young" => "jʌŋ",
			"your" => "jɔːr",
		];
	})();



	/**
	 * IPA vowels for CV syllable detection
	 * These are recognized IPA vowel symbols
	 */
	private static var IPA_VOWELS:Map<String, Bool> = [
		"a" => true, "æ" => true, "ə" => true, "ɛ" => true, "i" => true, "ɪ" => true,
		"o" => true, "ɔ" => true, "u" => true, "ʊ" => true, "ʌ" => true, "ɑ" => true,
		"aɪ" => true, "aʊ" => true, "eɪ" => true, "oʊ" => true, "ɔɪ" => true,
		"ɛə" => true, "ɪə" => true, "ʊə" => true, "ɑː" => true, "ɛː" => true,
		"iː" => true, "oː" => true, "uː" => true, "ɜː" => true, "ɔː" => true,
	];

	/**
	 * Convert a single English word to IPA phonemes
	 * Uses loaded dictionary first, then falls back to phonetic approximation
	 *
	 * @param word The English word to convert
	 * @return The IPA phonetic representation
	 */
	public static function englishToIPA(word:String):String
	{
		if (word == null || word.length == 0)
			return "";

		var lowerWord = word.toLowerCase().trim();

		// Get the loaded dictionary (or fallback if still loading)
		var dict = ipaDictionary.get();

		// Check loaded dictionary first
		if (dict.exists(lowerWord))
			return dict.get(lowerWord);

		// Fallback: phonetic approximation
		return approximateIPA(lowerWord);
	}

	/**
	 * Check if IPA dictionary is ready for use
	 */
	public static function isIPADictionaryReady():Bool
	{
		return ipaDictionary.isReady;
	}

	/**
	 * Queue a callback to execute when IPA dictionary finishes loading
	 * If already loaded, executes immediately
	 *
	 * @param callback Function to execute when dictionary is ready
	 */
	public static function onIPADictionaryReady(callback:Map<String, String>->Void):Void
	{
		if (ipaDictionary.isReady)
		{
			callback(ipaDictionary.get());
			return;
		}

		// AResult will handle callback execution once ready
		ipaDictionary.onReady(callback);
	}

	/**
	 * Approximate IPA for unknown words using simple rules
	 * This is a basic fallback when word is not in dictionary
	 *
	 * @param word The word to approximate
	 * @return Approximate IPA representation
	 */
	private static function approximateIPA(word:String):String
	{
		// Very basic approximation - just spell it out
		// In production, you'd want a more sophisticated phonetic engine
		var result = "";
		for (i in 0...word.length)
		{
			var char = word.charAt(i);
			switch(char)
			{
				case "a": result += "æ";
				case "e": result += "ɛ";
				case "i": result += "ɪ";
				case "o": result += "ɔ";
				case "u": result += "ʌ";
				case "y": result += "aɪ";
				case "c": result += "k";
				case "q": result += "kw";
				default: result += char;
			}
		}
		return result;
	}

	/**
	 * Format IPA phonemes as CV (Consonant-Vowel) syllables for the Tunic font
	 * The Tunic font expects CV pairs formatted as strings
	 *
	 * Examples:
	 * - "hɛ" + "loʊ" = "he lou" (for "hello")
	 * - "æ" (vowel start) = "cæ" (add 'c' for empty consonant)
	 *
	 * @param ipaText The IPA phoneme string
	 * @return Formatted string for Tunic font rendering
	 */
	public static function formatForTunicFont(ipaText:String):String
	{
		if (ipaText == null || ipaText.length == 0)
			return "";

		var result = "";
		var i = 0;

		while (i < ipaText.length)
		{
			// Skip spaces
			if (ipaText.charAt(i) == " ")
			{
				result += " ";
				i++;
				continue;
			}

			// Skip stress marks
			if (ipaText.charAt(i) == "ˈ" || ipaText.charAt(i) == "ˌ")
			{
				i++;
				continue;
			}

			var syllable = "";

			// Try to extract CV pair
			// Look ahead for vowel
			var vowelStart = i;
			var foundVowel = false;

			while (vowelStart < ipaText.length)
			{
				var char = ipaText.charAt(vowelStart);
				if (char == " " || char == "ˈ" || char == "ˌ")
				{
					vowelStart++;
					continue;
				}

				// Check if this starts a vowel sequence
				if (isVowelStart(ipaText, vowelStart))
				{
					foundVowel = true;
					break;
				}

				vowelStart++;
			}

			if (foundVowel)
			{
				// Extract consonants before vowel
				var consonants = ipaText.substring(i, vowelStart).trim();

				// Extract vowel
				var vowelLength = getVowelLength(ipaText, vowelStart);
				var vowel = ipaText.substring(vowelStart, vowelStart + vowelLength);

				// Format as CV
				if (consonants.length == 0)
				{
					// Vowel start - add 'c' for empty consonant
					syllable = "c" + vowel;
				}
				else
				{
					syllable = consonants + vowel;
				}

				result += syllable + " ";
				i = vowelStart + vowelLength;
			}
			else
			{
				// No vowel found, just add remaining as single character
				result += ipaText.charAt(i);
				i++;
			}
		}

		return result.trim();
	}

	/**
	 * Check if position in string starts a vowel sequence
	 */
	private static function isVowelStart(text:String, pos:Int):Bool
	{
		if (pos >= text.length)
			return false;

		var char = text.charAt(pos);

		// Single vowel check
		if (IPA_VOWELS.exists(char))
			return true;

		// Check for diphthongs (two-char vowels)
		if (pos + 1 < text.length)
		{
			var twoChar = text.substring(pos, pos + 2);
			if (IPA_VOWELS.exists(twoChar))
				return true;
		}

		// Check for vowel + ː (length marker)
		if (char == "ː" && pos > 0)
		{
			var prev = text.charAt(pos - 1);
			if (IPA_VOWELS.exists(prev))
				return true;
		}

		return false;
	}

	/**
	 * Get the length of a vowel sequence starting at position
	 */
	private static function getVowelLength(text:String, pos:Int):Int
	{
		var length = 0;
		var i = pos;

		while (i < text.length)
		{
			var char = text.charAt(i);

			// Stop at consonants, spaces, or stress marks
			if (char == " " || char == "ˈ" || char == "ˌ")
				break;

			// Check if still part of vowel
			if (i > pos && char != "ː" && !IPA_VOWELS.exists(char))
				break;

			length++;
			i++;
		}

		return Math.max(1, length).toNum();
	}

	/**
	 * Full pipeline: English text → IPA → Tunic font format
	 *
	 * @param text English text to convert
	 * @return Text formatted for Tunic font rendering
	 */
	public static function englishToTunic(text:String):String
	{
		if (text == null || text.length == 0)
			return text;

		var words = text.split(" ");
		var result = [];

		for (word in words)
		{
			if (word.length == 0)
				continue;

			var ipa = englishToIPA(word);
			var formatted = formatForTunicFont(ipa);

			if (formatted.length > 0)
				result.push(formatted);
		}

		return result.join(" ");
	}

	/**
	 * Gets the appropriate font based on language selection
	 * Maps standard fonts to tunic.otf when Runic is active
	 *
	 * @param fontName The requested font name
	 * @return The actual font to use (tunic.otf for Runic, otherwise original)
	 */
	public static function getFontForLanguage(fontName:String):String
	{
		if (!isRunicActive())
			return fontName;

		// Map common fonts to tunic.otf for Runic
		switch(fontName.toLowerCase())
		{
			case "fridaynightfunkin.ttf":
				return "tunic.otf";
			case "vcr.ttf":
				return "tunic.otf";
			case "pixel.otf":
				return "tunic.otf";
			default:
				return fontName;
		}
	}

	/**
	 * Checks if Runic language is currently active
	 *
	 * @return True if Runic language is selected
	 */
	public static function isRunicActive():Bool
	{
		return ClientPrefs.data.language == "runic";
	}

	/**
	 * Gets translated text with Runic conversion
	 * Checks Language system first, then converts via IPA
	 *
	 * @param key The translation key to look up
	 * @param defaultPhrase The default English phrase
	 * @return Tunic font-formatted text
	 */
	public static function getRunicPhrase(key:String, ?defaultPhrase:String):String
	{
		// Try to get from language file first
		var translated:String = Language.getPhrase(key, null);

		if (translated != null && translated != key)
		{
			// Found in translation file - assume it's pre-formatted for Tunic
			return translated;
		}

		// Convert default phrase via IPA
		if (defaultPhrase != null)
		{
			return englishToTunic(defaultPhrase);
		}

		// Last resort: convert key itself
		return englishToTunic(key);
	}

	/**
	 * Batch convert English words to Tunic format
	 *
	 * @param words Array of English words
	 * @return Array of Tunic-formatted text
	 */
	public static function wordsToTunic(words:Array<String>):Array<String>
	{
		if (words == null)
			return null;

		var result = [];
		for (word in words)
		{
			result.push(englishToTunic(word));
		}
		return result;
	}
}
