package states;
import backend.GitHubAPI.GitHubAsset;
import backend.GitHubAPI.GitHubRelease;
import backend.GitHubAPI;
import backend.util.JSEZip;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import haxe.Http;
import haxe.zip.Compress;
import haxe.zip.Entry;
import haxe.zip.Reader;
import haxe.zip.Uncompress;
import haxe.zip.Writer;
import lime.app.Application;
import lime.app.Event;
import lime.utils.Bytes;
import openfl.display.BlendMode;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import substates.Prompt;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

class UpdateState extends MusicBeatState
{
	// Static variables to store selected release info from ReleaseSelectionState
	public static var selectedRelease:GitHubRelease = null;
	public static var selectedAsset:GitHubAsset = null;
	var progressText:FlxText;
	var progBar_bg:FlxSprite;
	var progressBar:FlxBar;
	var entire_progress:Float = 0; // 0 to 100;
	var download_info:FlxText;

	var downloadedSize:Float = 0;
	var content:String = "";
	var maxFileSize:Float = 0;

	var zip:URLLoader;
	var text:FlxText;

	var currentTask:String = "download_update"; // download_update,install_update

	var loadingL:FlxSprite;
	var w = 775;
    var h = 550;

	var listoSongs:Array<String> = [
		'Breakfast',
		'Tea Time',
		'Celebration',
		'Drippy Genesis',
		'Reglitch',
		'False Memory',
		'Funky Genesis',
		'Late Night Cafe',
		'Late Night Jersey',
		'Silly Little Sample Song'
	];

	var gradientBar:FlxSprite;
	var bg:FlxSprite;
	var checker:FlxBackdrop;

	public override function create() {
		super.create();

		// Check if we have a selected release and asset
		if (selectedRelease == null || selectedAsset == null) {
			trace("No release selected, going back to release selection");
			FlxG.switchState(new ReleaseSelectionState());
			return;
		}

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Updating the Engine", null);
		#end

		FlxG.autoPause = false;

		FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(listoSongs[FlxG.random.int(0, 10)])), 0);
		FlxG.sound.music.pitch = 1;

		FlxG.sound.music.fadeIn(4, 0, 0.7);

		bg = new FlxSprite(-80).loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.color = 0xff270138;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x55AE59E4, 0xAAFFA319], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		add(gradientBar);
		gradientBar.scrollFactor.set(0, 0);

		checker = new FlxBackdrop(Paths.image('loading_screen/bgpattern'), XY, Std.int(0.2), Std.int(0.2));
		checker.blend = BlendMode.LAYER;
		add(checker);
		checker.scrollFactor.set(0, 0.07);

		text = new FlxText(0, 0, 0, "Downloading: " + selectedRelease.name, 18);
		text.setFormat(Paths.font('funkin.ttf'), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		text.screenCenter(X);
		text.y = 290;
		add(text);

		loadingL = new FlxSprite(337.60, 27.30).loadGraphic(Paths.image("loading_screen/loading"));
		loadingL.antialiasing = true;
        loadingL.screenCenter(X);
        add(loadingL);

        var loading = new FlxSprite().loadGraphic(Paths.image("loading_screen/updating"));
        loading.scale.set(0.85, 0.85);
        loading.updateHitbox();
        loading.y = FlxG.height - (loading.height * 1.15);
        loading.screenCenter(X);
        loading.antialiasing = true;
        add(loading);

		progBar_bg = new FlxSprite(FlxG.width / 2, text.y + 50).makeGraphic(500, 20, FlxColor.BLACK);
		add(progBar_bg);
		progBar_bg.x -= 250;
		progressBar = new FlxBar(progBar_bg.x + 5, progBar_bg.y + 5, LEFT_TO_RIGHT, Std.int(progBar_bg.width - 10), Std.int(progBar_bg.height - 10), this,
			"entire_progress", 0, 100);
		progressBar.numDivisions = 3000;
		progressBar.createFilledBar(0xFF4E2796, 0xFFFF7300);
		add(progressBar);

		progressText = new FlxText(progressBar.x, progressBar.y - 20, 0, "0%", 16);
		progressText.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(progressText);

		download_info = new FlxText(progressBar.x + progBar_bg.width, progressBar.y + progBar_bg.height, 0, "0B / 0B", 16);
		download_info.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(download_info);

		zip = new URLLoader();
		zip.dataFormat = BINARY;
		zip.addEventListener(ProgressEvent.PROGRESS, onDownloadProgress);
		zip.addEventListener(openfl.events.Event.COMPLETE, onDownloadComplete);

		prepareUpdate();
		startDownload();
	}

	var t:Float = 0;
	var lastVare:Float = 0;
	var lastTrackedBytes:Float = 0;
	var lastTime:Float = 0;
	var time:Float = 0;
	var speed:Float = 0;
	var downloadTime:Float = 0;
	var currentFile:String = "";
	public override function update(elapsed:Float) {
		t += elapsed; // for speed calculations
		checker.x -= 0.45 / (ClientPrefs.data.framerate / 60);
		checker.y -= 0.16 / (ClientPrefs.data.framerate / 60);
		loadingL.angle = Math.sin(t / 10) * 10;

		switch (currentTask)
		{
			case "download_update":
				time += elapsed;
				if (time > 1)
				{
					speed = downloadedSize - lastTrackedBytes;
					lastTime = time;
					lastTrackedBytes = downloadedSize;
					time = 0;

					// Divide file size by data speed to obtain download time.
					downloadTime = ((maxFileSize-downloadedSize) / (speed));
				}

				if (downloadedSize != lastVare)
				{
					lastVare = downloadedSize;
					download_info.text = convert_size(Std.int(downloadedSize)) + " / " + convert_size(Std.int(maxFileSize));
					download_info.x = (progBar_bg.x + progBar_bg.width) - download_info.width;

					entire_progress = (downloadedSize / maxFileSize) * 100;
				}

				progressText.text = FlxMath.roundDecimal(entire_progress, 2) + "%" + " - " + convert_size(Std.int(speed)) + "/s" + " - "
					+ convert_time(downloadTime) + " remaining";
			case "install_update":
				entire_progress = (downloadedSize / maxFileSize) * 100;
				progressText.text = FlxMath.roundDecimal(entire_progress, 2) + "%";
				download_info.text = currentFile;
				download_info.x = (progBar_bg.x + progBar_bg.width) - download_info.width;
		}

		super.update(elapsed);
	}

	inline function getPlatform():String
	{
		#if windows
		return 'windows';
		#elseif mac
		return 'macOS';
		#elseif linux
		return 'linux';
		#elseif android
		return 'android';
		/*
		#elseif ios
		return 'iOS';
		*/
		#else
		return '';
		#end
	}

	function prepareUpdate()
	{
		trace("preparing update...");
		trace("checking if update folder exists...");

		if (!FileSystem.exists("./update/"))
		{
			trace("update folder not found, creating the directory...");
			FileSystem.createDirectory("./update");
			FileSystem.createDirectory("./update/temp/");
			FileSystem.createDirectory("./update/raw/");
		}
		else
		{
			trace("update folder found");
		}
	}

	var httpHandler:Http;

	public function startDownload()
	{
		trace("starting download process...");
		trace("downloading: " + selectedAsset.name);
		trace("download url: " + selectedAsset.browser_download_url);

		zip.load(new URLRequest(selectedAsset.browser_download_url));
	}

	public function requestUrl(url:String):String
	{
		httpHandler = new Http(url);
		var r = null;
		httpHandler.onData = function(d)
		{
			r = d;
		}
		httpHandler.onError = function(e)
		{
			trace("error while downloading file, error: " + e);
		}
		httpHandler.request(false);
		return r;
	}

	function convert_size(bytes:Int)
	{
		// public static String readableFileSize(long size) {
		//	if(size <= 0) return "0";
		//	final String[] units = new String[] { "B", "kB", "MB", "GB", "TB" };
		//	int digitGroups = (int) (Math.log10(size)/Math.log10(1024));
		//	return new DecimalFormat("#,##0.#").format(size/Math.pow(1024, digitGroups)) + " " + units[digitGroups];
		// }
		if (bytes == 0)
		{
			return "0B";
		}

		var size_name:Array<String> = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
		var digit:Int = Std.int(Math.log(bytes) / Math.log(1024));
		return FlxMath.roundDecimal(bytes / Math.pow(1024, digit), 2) + " " + size_name[digit];
	}

	function convert_time(time:Float)
	{
		var seconds = Std.int(time % 60);
		var minutes = Std.int((time / 60) % 60);
		var hours = Std.int((time / (60 * 60)) % 24);

		var secStr:String = (seconds < 10) ? "0" + seconds : Std.string(seconds);
		var minStr:String = (minutes < 10) ? "0" + minutes : Std.string(minutes);
		var hoeStr:String = (hours < 10) ? "0" + hours : Std.string(hours);

		return hoeStr + ':' + minStr + ':' + secStr;
	}

	function onDownloadProgress(result:ProgressEvent)
	{
		downloadedSize = result.bytesLoaded;
		maxFileSize = result.bytesTotal;
	}

	function onDownloadComplete(result:openfl.events.Event)
	{
		var path:String = './update/temp/'; // JS Engine ' + TitleState.onlineVer + ".zip";

		if (!FileSystem.exists(path))
		{
			FileSystem.createDirectory(path);
		}

		if (!FileSystem.exists("./update/raw/"))
		{
			FileSystem.createDirectory("./update/raw/");
		}

		var fileBytes:Bytes = cast(zip.data, ByteArray);
		text.text = "Update downloaded successfully, saving update file...";
		text.screenCenter(X);
		File.saveBytes(path + selectedAsset.name, fileBytes);
		text.text = "Unpacking update file...";
		text.screenCenter(X);
		JSEZip.unzip(path + selectedAsset.name, "./update/raw/");
		text.text = "Update has finished! The update will be installed shortly..";
		text.screenCenter(X);

		FlxG.sound.play(Paths.sound('confirmMenu'));

		new FlxTimer().start(3, function(e:FlxTimer)
		{
			installUpdate("./update/raw/");
		});
	}

	function installUpdate(updateFolder:String)
	{
		CoolUtil.updateTheEngine();
	}

}
