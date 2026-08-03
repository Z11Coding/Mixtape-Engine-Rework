package states;

import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import yutautil.gamebanana.GameBananaAPI;
import yutautil.gamebanana.GameBananaCompatibility;
import yutautil.gamebanana.GameBananaHelper;
import yutautil.gamebanana.GameBananaRegistry;
import yutautil.gamebanana.GameBananaTypes;

class GameBananaToolsTestState extends MusicBeatState {
	private var inputMode:Int = 0; // 0 = search, 1 = link/id
	private var inputBuffer:String = "psych engine";
	private var searchResults:Array<GameBananaModData> = [];
	private var selectedSearchIndex:Int = 0;
	private var currentMod:Null<GameBananaModData> = null;
	private var currentTrees:Array<GameBananaFileData> = [];
	private var currentCompatibility:Null<GameBananaCompatibilityResult> = null;
	private var registry:GameBananaRegistryData;

	private var titleText:FlxText;
	private var modeText:FlxText;
	private var inputText:FlxText;
	private var statusText:FlxText;
	private var resultText:FlxText;
	private var listText:FlxText;
	private var helpText:FlxText;

	override function create() {
		super.create();

		registry = GameBananaRegistry.getRegistry();

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(16, 20, 30));
		add(bg);

		titleText = new FlxText(24, 20, FlxG.width - 48, "GameBanana Tools Test State", 28);
		titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT);
		add(titleText);

		modeText = new FlxText(24, 64, FlxG.width - 48, "", 16);
		modeText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.CYAN, LEFT);
		add(modeText);

		inputText = new FlxText(24, 88, FlxG.width - 48, "", 16);
		inputText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(inputText);

		statusText = new FlxText(24, 116, FlxG.width - 48, "Ready", 14);
		statusText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.YELLOW, LEFT);
		add(statusText);

		listText = new FlxText(24, 146, FlxG.width - 48, "", 14);
		listText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.LIME, LEFT);
		add(listText);

		resultText = new FlxText(24, 280, FlxG.width - 48, "", 14);
		resultText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		add(resultText);

		helpText = new FlxText(24, FlxG.height - 80, FlxG.width - 48,
			"TAB toggle mode | ENTER run search/resolve | F5 load selected result\nUP/DOWN select result | BACKSPACE delete | DELETE clear | ESC back to debug menu", 12);
		helpText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, LEFT);
		add(helpText);

		refreshHeader();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.BACK) {
			MusicBeatState.switchState(new DebugStateMenu());
			return;
		}

		if (FlxG.keys.justPressed.TAB) {
			inputMode = (inputMode + 1) % 2;
			refreshHeader();
		}

		if (FlxG.keys.justPressed.DELETE) {
			inputBuffer = "";
			searchResults = [];
			currentMod = null;
			currentTrees = [];
			currentCompatibility = null;
			statusText.text = "Cleared";
			refreshHeader();
			refreshList();
			refreshReport();
		}

		if (FlxG.keys.justPressed.BACKSPACE) {
			if (inputBuffer.length > 0) {
				inputBuffer = inputBuffer.substr(0, inputBuffer.length - 1);
				refreshHeader();
			}
		}

		if (controls.UI_UP_P && searchResults.length > 0) {
			selectedSearchIndex--;
			if (selectedSearchIndex < 0) selectedSearchIndex = searchResults.length - 1;
			refreshList();
		}

		if (controls.UI_DOWN_P && searchResults.length > 0) {
			selectedSearchIndex++;
			if (selectedSearchIndex >= searchResults.length) selectedSearchIndex = 0;
			refreshList();
		}

		if (controls.ACCEPT) {
			runAction();
		}

		if (FlxG.keys.justPressed.F5) {
			loadSelectedSearchResult();
		}

		handleTextInput();
	}

	private function runAction():Void {
		if (inputBuffer.trim().length == 0) {
			statusText.text = "Input is empty";
			return;
		}

		if (inputMode == 0) {
			statusText.text = "Searching GameBanana mods...";
			var result = GameBananaHelper.searchModsByQuery(inputBuffer);
			searchResults = result.items;
			selectedSearchIndex = 0;
			statusText.text = 'Search done. ${searchResults.length} FNF mod(s) found. ' + result.warning;
			refreshList();
			if (searchResults.length > 0) {
				loadMod(searchResults[0]);
			}
		} else {
			statusText.text = "Resolving link/id...";
			var mod = GameBananaHelper.resolveModInput(inputBuffer);
			if (mod == null) {
				statusText.text = "Could not resolve GameBanana mod from input";
				return;
			}
			var validationError = GameBananaAPI.validateFNFMod(mod);
			if (validationError != null) {
				statusText.text = validationError;
				currentMod = null;
				currentCompatibility = null;
				refreshReport();
				return;
			}
			loadMod(mod);
		}
	}

	private function loadSelectedSearchResult():Void {
		if (searchResults.length == 0) return;
		if (selectedSearchIndex < 0 || selectedSearchIndex >= searchResults.length) return;
		loadMod(searchResults[selectedSearchIndex]);
	}

	private function loadMod(mod:GameBananaModData):Void {
		statusText.text = 'Loading mod details: ${mod.name}';
		currentMod = mod;
		currentTrees = GameBananaHelper.getFileTreesForMod(mod, 3);
		currentCompatibility = GameBananaCompatibility.analyze(mod, currentTrees, registry);
		statusText.text = 'Loaded ${mod.name}. File trees loaded: ${currentTrees.length}';
		refreshReport();
	}

	private function refreshHeader():Void {
		var modeName = inputMode == 0 ? "Search Mode" : "Link/ID Mode";
		modeText.text = 'Mode: $modeName';
		inputText.text = 'Input: ' + inputBuffer;
	}

	private function refreshList():Void {
		if (searchResults.length == 0) {
			listText.text = "Search results: none";
			return;
		}

		var rows:Array<String> = ["Search results:"];
		var max = searchResults.length > 6 ? 6 : searchResults.length;
		for (i in 0...max) {
			var item = searchResults[i];
			var marker = i == selectedSearchIndex ? ">" : " ";
			rows.push('$marker ${i + 1}. ${item.name} [${item.id}] (${item.downloads} downloads)');
		}
		listText.text = rows.join("\n");
	}

	private function refreshReport():Void {
		if (currentMod == null) {
			resultText.text = "No mod loaded";
			return;
		}

		var mod = currentMod;
		var lines:Array<String> = [];
		lines.push('Mod: ${mod.name}');
		lines.push('ID: ${mod.id}');
		lines.push('Game: ${mod.gameName}');
		lines.push('Category: ${mod.categoryName} (#${mod.categoryId})');
		lines.push('Profile: ${mod.profileUrl}');
		lines.push('Direct Download: ${mod.directDownloadUrl}');
		lines.push('Preview Image: ${mod.previewImageUrl}');
		lines.push('Screenshots: ${mod.screenshots.length}');
		lines.push('Files: ${mod.files.length}');

		if (mod.files.length > 0) {
			lines.push('Top File: ${mod.files[0].fileName} (${mod.files[0].downloadCount} dl)');
		}

		if (currentCompatibility != null) {
			lines.push('Compatibility Verdict: ' + Type.enumConstructor(currentCompatibility.verdict));
			for (reason in currentCompatibility.reasons) {
				lines.push('- ' + reason);
			}
			if (currentCompatibility.setupRequiredEntry != null) {
				lines.push('Setup Required: ' + currentCompatibility.setupRequiredEntry.description);
			}
		}

		if (currentTrees.length > 0) {
			lines.push('Loaded archive trees: ' + currentTrees.length);
			for (tree in currentTrees) {
				lines.push('* File #' + tree.id + ' has ' + tree.flattenedFileList.length + ' entries');
			}
		}

		resultText.text = lines.join("\n");
	}

	private function handleTextInput():Void {
		var oldLength = inputBuffer.length;

		if (FlxG.keys.justPressed.A) inputBuffer += "a";
		else if (FlxG.keys.justPressed.B) inputBuffer += "b";
		else if (FlxG.keys.justPressed.C) inputBuffer += "c";
		else if (FlxG.keys.justPressed.D) inputBuffer += "d";
		else if (FlxG.keys.justPressed.E) inputBuffer += "e";
		else if (FlxG.keys.justPressed.F) inputBuffer += "f";
		else if (FlxG.keys.justPressed.G) inputBuffer += "g";
		else if (FlxG.keys.justPressed.H) inputBuffer += "h";
		else if (FlxG.keys.justPressed.I) inputBuffer += "i";
		else if (FlxG.keys.justPressed.J) inputBuffer += "j";
		else if (FlxG.keys.justPressed.K) inputBuffer += "k";
		else if (FlxG.keys.justPressed.L) inputBuffer += "l";
		else if (FlxG.keys.justPressed.M) inputBuffer += "m";
		else if (FlxG.keys.justPressed.N) inputBuffer += "n";
		else if (FlxG.keys.justPressed.O) inputBuffer += "o";
		else if (FlxG.keys.justPressed.P) inputBuffer += "p";
		else if (FlxG.keys.justPressed.Q) inputBuffer += "q";
		else if (FlxG.keys.justPressed.R) inputBuffer += "r";
		else if (FlxG.keys.justPressed.S) inputBuffer += "s";
		else if (FlxG.keys.justPressed.T) inputBuffer += "t";
		else if (FlxG.keys.justPressed.U) inputBuffer += "u";
		else if (FlxG.keys.justPressed.V) inputBuffer += "v";
		else if (FlxG.keys.justPressed.W) inputBuffer += "w";
		else if (FlxG.keys.justPressed.X) inputBuffer += "x";
		else if (FlxG.keys.justPressed.Y) inputBuffer += "y";
		else if (FlxG.keys.justPressed.Z) inputBuffer += "z";
		else if (FlxG.keys.justPressed.SPACE) inputBuffer += " ";
		else if (FlxG.keys.justPressed.SLASH) inputBuffer += "/";
		else if (FlxG.keys.justPressed.PERIOD) inputBuffer += ".";
		else if (FlxG.keys.justPressed.MINUS) inputBuffer += "-";
		else if (FlxG.keys.justPressed.QUOTE) inputBuffer += "'";
		else if (FlxG.keys.justPressed.ONE) inputBuffer += "1";
		else if (FlxG.keys.justPressed.TWO) inputBuffer += "2";
		else if (FlxG.keys.justPressed.THREE) inputBuffer += "3";
		else if (FlxG.keys.justPressed.FOUR) inputBuffer += "4";
		else if (FlxG.keys.justPressed.FIVE) inputBuffer += "5";
		else if (FlxG.keys.justPressed.SIX) inputBuffer += "6";
		else if (FlxG.keys.justPressed.SEVEN) inputBuffer += "7";
		else if (FlxG.keys.justPressed.EIGHT) inputBuffer += "8";
		else if (FlxG.keys.justPressed.NINE) inputBuffer += "9";
		else if (FlxG.keys.justPressed.ZERO) inputBuffer += "0";

		if (oldLength != inputBuffer.length) {
			refreshHeader();
		}
	}
}
