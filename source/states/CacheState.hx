package states;
#if sys
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.system.FlxSound;
import lime.app.Application;
import flixel.FlxState;
import flixel.FlxSubState;
import openfl.display.BitmapData;
import backend.GPUBitmap;
import backend.ImageCache;
import options.CacheSettings;
import flixel.ui.FlxBar;
import openfl.system.System;
#if windows
import backend.Discord.DiscordClient;
#end
import openfl.utils.Assets;
import haxe.Exception;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
#if cpp
import sys.FileSystem;
import sys.io.File;
#end
import sys.io.Process;
import backend.JSONCache;
import objects.VideoSprite;

using StringTools;

class CacheState extends MusicBeatState
{
	public var cacheNeeded:Bool = false;
	public static var didPreCache:Bool = false;
	public static var bitmapData:Map<String, FlxGraphic>;
	var images:Array<String> = [];
	var music:Array<String> = [];
	var json:Array<String> = [];
	var videos:Array<String> = [];
	var modImages:Array<String> = [];
	var modMusic:Array<String> = [];
	var modVideos:Array<String> = [];
	

	var boolshit = true;
	var daMods:Array<String> = [];
	var pathList:Array<String> = 
	[
		"", "characters", "dialogue", "pauseAlt", "pixelUI", "weeb", 
		"achievements", "credits", "icons", "loading", "mainmenu", "menubackgrounds", 
		"menucharacters", "menudifficulties", "storymenu", "pixelUI/noteskins", "cursor", 
		"editors", "effects", "globalIcons", "HUD", "mechanics", "noteColorMenu", "noteskins", 
		"pause", "soundtray", "stages"
	]; //keep it here just in case
	
	var shitz:FlxText;
	var totalthing = [];
	var curThing:String;
	var menuBG:FlxSprite;
	var cacheStart:Bool = false;
	var startCachingModImages:Bool = false;
	var startCachingSoundsAndMusic:Bool = false;
	var startCachingSoundsAndMusicMods:Bool = false;
	var songsCached:Bool;
	var graphicsCached:Bool;
	var startCachingVideos:Bool;
	var startCachingVideoMods:Bool;
    var startCachingGraphics:Bool = false;
	var musicCached:Bool;
	var modImagesCached:Bool;
	var gameCached:Bool = false;
	var dontBother:Bool = false;
	var totalToDo:Int = 0;
	var modImI:Int = 0;
	var gfxI:Int = 0;
	var sNmI:Int = 0;
	var sNmmI:Int = 0;
	var gfxV:Int = 0;
	var gfxMV:Int = 0;
	var allowMusic:Bool = false;
	var pause:Bool = false;
	var loadingWhat:FlxText;
	var loadingBar:FlxBar;
	var loadingBox:FlxSprite;
	var loadingWhatMini:FlxText;
	var loadingBoxMini:FlxSprite;
	public static var cacheInit:Bool = false;
	var currentLoaded:Int = 0;
	var loadTotal:Int = 0;
	

	public static var newDest:FlxState;

	override function create()
	{
		trace('ngl pretty cool');


		if (!cacheInit && (FlxG.save.data.musicPreload2 == null || FlxG.save.data.graphicsPreload2 == null || FlxG.save.data.videoPreload2 == null)) {
			cacheInit = true;
			pause = true;
			allowMusic = false;
			FlxG.switchState(new CacheSettings());
		}

		//Cursor.cursorMode = Cross;
		FlxTransitionableState.skipNextTransOut = false;
		newDest = new What();
		//FlxG.sound.play(Paths.music('celebration'));
		for (folder in Mods.getModDirectories())
		{
			if(!Mods.ignoreModFolders.contains(folder))
			{
				daMods.push(folder);
			}
		}
		
		if((FlxG.save.data.musicPreload2 != null && ClientPrefs.data.musicPreload2 == false)
			|| (FlxG.save.data.graphicsPreload2 != null && ClientPrefs.data.graphicsPreload2 == false)
				|| (FlxG.save.data.videoPreload2 != null && ClientPrefs.data.videoPreload2 == false)) {
				FlxG.switchState(new What());
				dontBother = true;
				allowMusic = false;
		}	
		else 
		{
			allowMusic = true;
			dontBother = false;
			didPreCache = true;
		}

		menuBG = new FlxSprite().loadGraphic(Paths.image('loading/' + FlxG.random.int(0, 16, [3])));
		menuBG.screenCenter();
		add(menuBG);



		#if cpp
		if (ClientPrefs.data.graphicsPreload2)
		{
			var cache:Array<String> = [];
			cache = cache.concat(Paths.crawlDirectoryOG("assets", ".png", images));
			cache = cache.concat(Paths.crawlDirectoryOG("mods", ".png", modImages));

			if (ClientPrefs.data.saveCache) {
				ImageCache.loadCache();
			}


			for (image in cache) {
				if (ImageCache.exists(image)) {
					if (images.indexOf(image) != -1) {
						images.splice(images.indexOf(image), 1);
					} else if (modImages.indexOf(image) != -1) {
						modImages.splice(modImages.indexOf(image), 1);
					}
				}
			}
		}

		if (ClientPrefs.data.musicPreload2)
		{
			Paths.crawlDirectoryOG("assets", ".ogg", music);
			Paths.crawlDirectoryOG("mods", ".ogg", modMusic);
		}

		if (ClientPrefs.data.videoPreload2)
		{
			Paths.crawlDirectoryOG("assets", ".mp4", videos);
			Paths.crawlDirectoryOG("mods", ".mp4", modVideos);
		}

		var jsonCache = function() {
			Paths.crawlDirectory("assets", ".json", json);
			Paths.crawlDirectory("mods", ".json", json);
			
			for (json in json)
			{
				JSONCache.addToCache(json);
			}
			return true;
		}

		jsonCache();

		//trace(JSONCache.charts());


		#end


		loadTotal = images.length + modImages.length + music.length + modMusic.length + videos.length + modVideos.length;
		//trace("Files: " + "Images: " + images + "Images(Mod): " + modImages + "Music: " + music + "Music(Mod): " + modMusic);
		//trace(loadTotal + " files to load");
		
		trace(loadTotal);
		if(loadTotal > 0){
			loadingBar = new FlxBar(0, 605, LEFT_TO_RIGHT, 600, 24, this, 'currentLoaded', 0, loadTotal);
			loadingBar.createGradientBar([0xFF333333, 0xFFFFFFFF], [0xFF7233D8, 0xFFD89033]);
			loadingBar.screenCenter(X);
			loadingBar.visible = false;
			add(loadingBar);
		}

		loadingWhat = new FlxText(FlxG.width/2 - 500, 0, 0, "Press ENTER to see cache options\nLoading will being soon", 24);
		loadingWhat.setFormat(Paths.font("DS-DIGIB.TTF"), 50, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		loadingWhat.screenCenter(XY);

		loadingWhatMini = new FlxText(loadingWhat.x, loadingWhat.y+285, 0, "Currently Loading: Music", 24);
		loadingWhatMini.setFormat(Paths.font("DS-DIGIB.TTF"), 50, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		loadingWhatMini.setGraphicSize(Std.int(loadingWhatMini.width) * 0.5);
		loadingWhatMini.screenCenter(X);

		loadingBox = new FlxSprite(FlxG.width/2 - 500, 0).makeGraphic(Std.int(loadingWhat.width), Std.int(loadingWhat.height), FlxColor.BLACK);
		loadingBox.screenCenter(XY);
		loadingBox.alpha = 0.5;

		add(loadingBox);
		add(loadingWhat);
		add(loadingWhatMini);

		if(!cacheStart){
			#if web
			new FlxTimer().start(3, function(tmr:FlxTimer)
			{
				modImagesCached = true;
				graphicsCached = true;
				songsCached = true;
			});
			#else
			new FlxTimer().start(3, function(tmr:FlxTimer)
			{
				cacheStart = true;
				cache();
			});
			#end
		}

		if(ClientPrefs.data.graphicsPreload2){
			GPUBitmap.disposeAll(); //cuz we moved to a pack without the undertale or origins and i didnt wanna complain about it cuz i know they were causing issues so i was being
			ImageCache.cache.clear();
		}
		else{
			modImagesCached = true;
			graphicsCached = true;
		}

		if(ClientPrefs.data.musicPreload2){
			Assets.cache.clear("music");
		}
		else{
			songsCached = true;
		}

		totalToDo = totalthing.length;

		if (allowMusic && !cacheInit) FlxG.sound.playMusic(Paths.music('greetings'), 1, true);

		super.create();
	}

	function openPreloadSettings(){
        #if desktop
        FlxG.sound.play(Paths.sound('cancelMenu'));
        FlxG.switchState(new CacheSettings());
        #end
    }

	var move:Bool = false;
	override function update(elapsed) 
	{
		if (!dontBother && pause)
		{
			loadingBox.width = Std.int(loadingWhat.width);
			loadingBox.height = Std.int(loadingWhat.height);
			if (currentLoaded == loadTotal) gameCached = true;

			//if (!ClientPrefs.data.graphicsPreload2 && !ClientPrefs.data.musicPreload2) gameCached = true;

			if (loadingWhat.text == "Loading: null") 
			{
				gameCached = true; //I love null checking
			}

			if (!cacheStart && FlxG.keys.justPressed.ESCAPE)
			{
				System.gc();
				FlxG.switchState(newDest); 
			}

			if(menuBG.alpha == 0){
				System.gc();
				if (ClientPrefs.data.saveCache) {
					ImageCache.saveCache();
				}
				FlxG.sound.music.time = 0;
				if (ClientPrefs.data.cacheCharts) {
					var charts:Array<String> = Paths.crawlDirectory("assets/shared/data", ".json");
					PlayState.cachingSongs = charts;
					PlayState.CacheMode = true;
					trace("Charts: " + charts);
					trace("Caching charts...");
					FlxG.switchState(new PlayState());
				}
				else {
					FlxG.switchState(newDest);
				}
			}

			if(!gameCached)
			{
				loadingWhat.text = 'Loading...\n(${loadingBar.percent}% // $currentLoaded out of $loadTotal)';
				loadingWhat.screenCenter();
			}

			if(gameCached && menuBG.alpha == 1){
				FlxTween.tween(FlxG.camera, {zoom: 0}, 1, {ease: FlxEase.sineOut});
				FlxTween.tween(FlxG.camera, {angle: 360}, 1, {ease: FlxEase.sineOut});
				FlxTween.tween(menuBG, {alpha: 0}, 1, {ease: FlxEase.sineInOut});
				loadingWhat.text = "Done!";
				loadingWhat.screenCenter(XY);
				loadingWhatMini.text = "Done!";
				loadingWhatMini.screenCenter(X);
				if(loadingBar != null){
					FlxTween.tween(loadingBar, {alpha: 0}, 0.3);
				}
				if (ClientPrefs.data.saveCache) {
				menuBG.updateHitbox();
				FlxG.sound.music.fadeOut(1, 0);
				loadingWhat.text = "Saving cache...";
				loadingWhat.screenCenter(XY);
				loadingWhatMini.text = "Saving cache...";
				loadingWhatMini.screenCenter(X);

				ImageCache.saveCache();
				}
			}

			if(!cacheStart){
				if(FlxG.keys.justPressed.ANY){
					openPreloadSettings();
				}
			}
		
			if(startCachingGraphics){
				if(gfxI >= images.length){
					trace("Graphics cached");
					startCachingGraphics = false;
					startCachingSoundsAndMusicMods = true;
					graphicsCached = true;
				}
				else{
					loadingWhatMini.text = images[gfxI];
					loadingWhatMini.screenCenter(X);
					loadingWhat.screenCenter(XY);
					if(CoolUtil.exists(images[gfxI])){
						if(!ImageCache.exists(images[gfxI])){
							ImageCache.add(images[gfxI]);
						}
					}
					else{
						trace("Image: File at " + images[gfxI] + " not found, skipping cache.");
					}
					gfxI++;
					currentLoaded++;
				}
			}

			if(startCachingModImages){
				if(modImI >= modImages.length){
					trace("Mod Graphics cached");
					startCachingModImages = false;
					startCachingVideos = true;
					modImagesCached = true;
				}
				else{
					loadingWhatMini.text = modImages[gfxI];
					loadingWhatMini.screenCenter(X);
					loadingWhat.screenCenter(XY);
					for (i in daMods){
						for (ii in pathList){
							loadingWhatMini.text = modImages[modImI];
							loadingWhatMini.screenCenter(X);
							if (CoolUtil.exists(Paths.file2(StringTools.replace(modImages[modImI], '.png', ''), '$i/images/$ii', "png", "mods"))){
								if(!ImageCache.exists(Paths.file2(StringTools.replace(modImages[modImI], '.png', ''), '$i/images/$ii', "png", "mods"))){
									ImageCache.add(Paths.file2(StringTools.replace(modImages[modImI], '.png', ''), '$i/images/$ii', "png", "mods"));
								}
							}
						}
					}
					modImI++;
					currentLoaded++;
				}
			}

			if(startCachingVideos){
				if(gfxV >= videos.length){
					trace("Videos cached");
					startCachingVideos = false;
					startCachingVideoMods = true;
					graphicsCached = true;
				}
				else{
					loadingWhatMini.text = videos[gfxV];
					loadingWhatMini.screenCenter(X);
					loadingWhat.screenCenter(XY);
					if(CoolUtil.exists(videos[gfxV])){
						var a = StringTools.replace(videos[gfxV], '.mp4', '');
						a = StringTools.replace(a, 'assets/videos/', '');
						preloadVideo(StringTools.replace(a, '.mp4', ''));
					}
					else{
						trace("Video: File at " + videos[gfxV] + " not found, skipping cache.");
					}
					gfxV++;
					currentLoaded++;
				}
			}

			if(startCachingVideoMods){
				if(gfxMV >= modVideos.length){
					trace("Mod Videos cached");
					startCachingVideoMods = false;
				}
				else{
					for (i in daMods){
						for (ii in pathList){
							loadingWhatMini.text = modVideos[gfxMV];
							loadingWhatMini.screenCenter(X);
							loadingWhat.screenCenter(XY);
							if (CoolUtil.exists(Paths.file2(StringTools.replace(modVideos[gfxMV], '.mp4', ''), '$i/videos/$ii', "mp4", "mods"))){
								preloadVideo(StringTools.replace(modVideos[gfxMV], '.mp4', ''));
							}
							else{
								trace("Video: File at " + modVideos[gfxMV] + " not found, skipping cache.");
							}
						}
					}
					gfxMV++;
					currentLoaded++;
				}
			}

			if(startCachingSoundsAndMusicMods){
				if(sNmmI >= modMusic.length){
					trace("Mods Music and Sounds cached");
					startCachingSoundsAndMusicMods = false;
					startCachingModImages = true;
				}
				else{
					loadingWhatMini.text = modMusic[sNmmI];
					loadingWhatMini.screenCenter(X);
					loadingWhat.screenCenter(XY);
					if(CoolUtil.exists(modMusic[sNmmI])){
						if(CoolUtil.exists(Paths.cacheInst(modMusic[sNmmI]))){
							FlxG.sound.cache(Paths.cacheInst(modMusic[sNmmI]));
						}
						if(CoolUtil.exists(Paths.cacheVoices(modMusic[sNmmI]))){
							FlxG.sound.cache(Paths.cacheVoices(modMusic[sNmmI]));
						}
						if(CoolUtil.exists(Paths.cacheSound(modMusic[sNmmI]))){
							FlxG.sound.cache(Paths.cacheSound(modMusic[sNmmI]));
						}
						if(CoolUtil.exists(Paths.cacheMusic(modMusic[sNmmI]))) {
							FlxG.sound.cache(Paths.cacheMusic(modMusic[sNmmI]));
						}
					}
					else{
						trace("Music/Sound: File at " + modMusic[sNmmI] + " not found, skipping cache.");
					}
					sNmmI++;
					currentLoaded++;
				}
			}

			if(startCachingSoundsAndMusic){
				if(sNmI >= music.length){
					trace("Music and Sounds cached");
					startCachingSoundsAndMusic = false;
					startCachingGraphics = true;
				}
				else{
					loadingWhatMini.text = music[sNmI];
					loadingWhatMini.screenCenter(X);
					loadingWhat.screenCenter(XY);
					if(CoolUtil.exists(music[sNmI])){
						if(CoolUtil.exists(Paths.cacheInst(music[sNmI]))){
							FlxG.sound.cache(Paths.cacheInst(music[sNmI]));
						}
						if(CoolUtil.exists(Paths.cacheVoices(music[sNmI]))){
							FlxG.sound.cache(Paths.cacheVoices(music[sNmI]));
						}
						if(CoolUtil.exists(Paths.cacheSound(music[sNmI]))){
							FlxG.sound.cache(Paths.cacheSound(music[sNmI]));
						}
						if(CoolUtil.exists(Paths.cacheMusic(music[sNmI]))) {
							FlxG.sound.cache(Paths.cacheMusic(music[sNmI]));
						}
					}
					else{
						trace("Music/Sound: File at " + music[sNmI] + " not found, skipping cache.");
					}
					sNmI++;
					currentLoaded++;
				}
			}
		}
		
		super.update(elapsed);
	}

	public var videoCutscene:VideoSprite = null;
	function preloadVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);
		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			var cutscene:VideoSprite = new VideoSprite(fileName, true, true, false);
			add(cutscene);
			return cutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else
			trace("Video not found: " + fileName);
		#else
		else
			trace("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	function cache()
	{
		if(loadingBar != null){
            loadingBar.visible = true;
        }

		#if sys
		startCachingSoundsAndMusic = true;
		#end
	}

	function preloadMusic(){
        for(x in music){
			if(CoolUtil.exists(Paths.cacheInst(x))){
                FlxG.sound.cache(Paths.cacheInst(x));
            }
			if(CoolUtil.exists(Paths.cacheVoices(x))){
                FlxG.sound.cache(Paths.cacheVoices(x));
            }
			if(CoolUtil.exists(Paths.cacheSound(x))){
                FlxG.sound.cache(Paths.cacheSound(x));
            }
            if(CoolUtil.exists(Paths.cacheMusic(x))) {
                FlxG.sound.cache(Paths.cacheMusic(x));
            }
			//loadingWhat.text = 'Loading: ' + x;
			currentLoaded++;
        }

		for(x in modMusic){
            if(CoolUtil.exists(Paths.cacheInst(x))){
                FlxG.sound.cache(Paths.cacheInst(x));
            }
			if(CoolUtil.exists(Paths.cacheVoices(x))){
                FlxG.sound.cache(Paths.cacheVoices(x));
            }
			if(CoolUtil.exists(Paths.cacheSound(x))){
                FlxG.sound.cache(Paths.cacheSound(x));
            }
            if(CoolUtil.exists(Paths.cacheMusic(x))) {
                FlxG.sound.cache(Paths.cacheMusic(x));
            }
			//loadingWhat.text = 'Loading: ' + x;
			currentLoaded++;
        }
		loadingWhat.screenCenter(XY);
        //FlxG.sound.play(Paths.sound("tick"), 1);
        songsCached = true;
    }
}
#else
import flixel.FlxG;
import flixel.FlxState;
using StringTools;
class CacheState extends MusicBeatState
{
	public static var newDest:FlxState;
	override function create()
	{
		Paths.clearStoredMemory();
		Main.dumpCache();

		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end

		ClientPrefs.loadPrefs();
		super.create();
		newDest = new What();
		trace('simply be better');
		FlxG.switchState(newDest);
	}
}
#end