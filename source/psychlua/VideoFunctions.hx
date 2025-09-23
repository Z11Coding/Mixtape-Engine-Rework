package psychlua;

import objects.SyncedVideoSprite;
import objects.VideoSprite;
import substates.GameOverSubstate;

class VideoFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "setGameOverVideo", function(name:String = null) {
			if (name != null) GameOverSubstate.instance.setGameOverVideo(name);
			else trace('No argument for game over video!');
		});

		Lua_helper.add_callback(lua, 'makeVideoSprite', function(tag:String, videoFile:String, ?x:Float, ?y:Float, ?camera:String = 'game', ?shouldLoop:Bool = false, ?playOnLoad:Bool = true, ?isCutscene:Bool = false, ?addBehind:String = 'none') {
			if (MusicBeatState.getVariables().exists(tag + '_video') || MusicBeatState.getVariables().exists(tag))
			{
				PlayState.instance.addTextToDebug('makeVideoSprite: This tag is not available! Use a different tag.', FlxColor.RED);
				return;
			}

			if (!FileSystem.exists(Paths.video(videoFile)))
			{
				PlayState.instance.addTextToDebug('makeVideoSprite: The video file "' + videoFile + '" cannot be found!', FlxColor.RED);
				return;
			}

			var videoCutscene:VideoSprite = null;
			#if VIDEOS_ALLOWED
			PlayState.instance.inCutscene = isCutscene;
			PlayState.instance.canPause = !isCutscene;

			var foundFile:Bool = false;
			var fileName:String = Paths.video(videoFile);

			#if sys
			if (FileSystem.exists(fileName))
			#else
			if (OpenFlAssets.exists(fileName))
			#end
			foundFile = true;

			if (foundFile)
			{
				videoCutscene = new VideoSprite(fileName, !isCutscene, false, shouldLoop);
				if(!isCutscene) videoCutscene.videoSprite.bitmap.rate = PlayState.instance.playbackRate;

				// Finish callback
				if (isCutscene)
				{
					function onVideoEnd()
					{
						videoCutscene = null;
						PlayState.instance.canPause = true;
						PlayState.instance.inCutscene = false;
						if(PlayState.instance.endingSong)
							PlayState.instance.endSong();
						else
							PlayState.instance.startCountdown();
					}
					videoCutscene.finishCallback = onVideoEnd;
					videoCutscene.onSkip = onVideoEnd;
				}
				videoCutscene.camera = LuaUtils.cameraFromString(camera);
				videoCutscene.x = x;
				videoCutscene.y = y;
				if (substates.GameOverSubstate.instance != null && PlayState.instance.isDead) substates.GameOverSubstate.instance.add(videoCutscene);
				else {
					switch(addBehind.toLowerCase()){
						case "bf" | "boyfriend": PlayState.instance.addBehindBF(videoCutscene);
						case "gf" | "girlfriend": PlayState.instance.addBehindGF(videoCutscene);
						case "dad" | "opponent": PlayState.instance.addBehindDad(videoCutscene);
						case "hud": PlayState.instance.addBehindHUD(videoCutscene);
						default: PlayState.instance.add(videoCutscene);
					}
				}

				if (playOnLoad) videoCutscene.play();
			}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			else PlayState.instance.addTextToDebug("Video not found: " + fileName, FlxColor.RED);
			#else
			else FlxG.log.error("Video not found: " + fileName);
			#end
			#else
			FlxG.log.warn('Platform not supported!');
			#end
			MusicBeatState.getVariables().set(tag + '_video', videoCutscene);
			MusicBeatState.getVariables().set(tag, videoCutscene);
		});

		Lua_helper.add_callback(lua, 'makeSyncedVideoSprite', function(tag:String, videoFile:String, ?x:Float = 0, ?y:Float = 0, ?syncOffset:Float = 0, ?canSkip:Bool = false, ?shouldLoop:Bool = false, ?addBehind:String = 'none') {
			if (MusicBeatState.getVariables().exists(tag + '_synced_video') || MusicBeatState.getVariables().exists(tag))
			{
				PlayState.instance.addTextToDebug('makeSyncedVideoSprite: This tag is not available! Use a different tag.', FlxColor.RED);
				return;
			}

			#if VIDEOS_ALLOWED
			var syncedVideo = PlayState.instance.makeSyncedVideoSprite(videoFile, x, y, syncOffset, canSkip, shouldLoop, addBehind);
			if (syncedVideo != null) {
				MusicBeatState.getVariables().set(tag + '_synced_video', syncedVideo);
				MusicBeatState.getVariables().set(tag, syncedVideo);
			}
			#else
			FlxG.log.warn('Platform not supported!');
			#end
		});

		Lua_helper.add_callback(lua, 'queueSyncedVideoSprite', function(tag:String, videoFile:String, startTime:Float, ?x:Float = 0, ?y:Float = 0, ?syncOffset:Float = 0, ?canSkip:Bool = false, ?shouldLoop:Bool = false, ?addBehind:String = 'none') {
			if (MusicBeatState.getVariables().exists(tag + '_synced_video') || MusicBeatState.getVariables().exists(tag))
			{
				PlayState.instance.addTextToDebug('queueSyncedVideoSprite: This tag is not available! Use a different tag.', FlxColor.RED);
				return;
			}

			#if VIDEOS_ALLOWED
			var syncedVideo = PlayState.instance.queueSyncedVideoSprite(videoFile, startTime, x, y, syncOffset, canSkip, shouldLoop, addBehind);
			if (syncedVideo != null) {
				MusicBeatState.getVariables().set(tag + '_synced_video', syncedVideo);
				MusicBeatState.getVariables().set(tag, syncedVideo);
			}
			#else
			FlxG.log.warn('Platform not supported!');
			#end
		});

		Lua_helper.add_callback(lua, 'pauseSyncedVideo', function(tag:String) {
			var video = MusicBeatState.getVariables().get(tag + '_synced_video');
			if (video != null && Std.isOfType(video, SyncedVideoSprite)) {
				cast(video, SyncedVideoSprite).pause();
			}
		});

		Lua_helper.add_callback(lua, 'resumeSyncedVideo', function(tag:String) {
			var video = MusicBeatState.getVariables().get(tag + '_synced_video');
			if (video != null && Std.isOfType(video, SyncedVideoSprite)) {
				cast(video, SyncedVideoSprite).resume();
			}
		});

		Lua_helper.add_callback(lua, 'stopSyncedVideo', function(tag:String) {
			var video = MusicBeatState.getVariables().get(tag + '_synced_video');
			if (video != null && Std.isOfType(video, SyncedVideoSprite)) {
				cast(video, SyncedVideoSprite).stop();
			}
		});
	}
}
