package states.stages;

import backend.BaseStage;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import sys.FileSystem;

class NotITG extends BaseStage
{
	var bgSprite:FlxSprite;

	override function create()
	{
		// Set default black background color
		camGame.bgColor = 0xFF000000;

		// Set default zoom
		defaultCamZoom = 0.9;

		// Trying to load the background of the StepMania chart
		loadStepManiaBackground();
	}

	function loadStepManiaBackground():Void
	{
		#if sys
    //TODO: Make this a thing
		var customPath = ""://states.PlayState.customAudioPath;
		if (customPath == null || (!customPath.contains('/sm/') && !customPath.contains('sm/')))
			return;

		// customPath has format: ./sm/modname/
		// We need to determine if it is standard StepMania or NotITG

		var bgPath:String = null;

		// Try loading from lua/bg.png first (NotITG)
		var notitgBgPath = customPath + 'lua/bg.png';
		if (FileSystem.exists(notitgBgPath))
		{
			bgPath = notitgBgPath;
			trace('Loading NotITG background from: ' + bgPath);
		}
		else
		{
			// Find *-bg.png files (Standard StepMania)
			var files = FileSystem.readDirectory(customPath);
			for (file in files)
			{
				if (file.toLowerCase().endsWith('-bg.png'))
				{
					bgPath = customPath + file;
					trace('Loading StepMania background from: ' + bgPath);
					break;
				}
			}
		}

		// If we find a background, load it
		if (bgPath != null && FileSystem.exists(bgPath))
		{
			try
			{
				var bitmapData = openfl.display.BitmapData.fromFile(bgPath);
				if (bitmapData != null)
				{
					bgSprite = new FlxSprite();
					bgSprite.loadGraphic(bitmapData);
					bgSprite.antialiasing = true;

					// Scale to cover entire screen while maintaining aspect ratio
					var scaleX = FlxG.width / bgSprite.width;
					var scaleY = FlxG.height / bgSprite.height;
					var scale = Math.max(scaleX, scaleY);

					bgSprite.scale.set(scale, scale);
					bgSprite.updateHitbox();
					bgSprite.screenCenter();
					bgSprite.scrollFactor.set(0, 0);

					// Add to camHUD to be behind everything
					bgSprite.cameras = [PlayState.instance.camHUD];

					trace('Background loaded successfully: ${bgSprite.width}x${bgSprite.height}');
				}
				else
				{
					trace('Failed to load bitmap data from: ' + bgPath);
				}
			}
			catch (e:Dynamic)
			{
				trace('Error loading background: ' + e);
			}
		}
		else
		{
			trace('No background found for StepMania chart');
		}
		#end
	}

	override function createPost()
	{
		// Add the background to the beginning of the stage so that it is behind everything
		if (bgSprite != null)
		{
			// Insert at the beginning so it is behind everything
			PlayState.instance.insert(0, bgSprite);
		}
		else
		{
			// Si no hay background, mantener fondo negro
			camGame.bgColor = 0xFF000000;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
