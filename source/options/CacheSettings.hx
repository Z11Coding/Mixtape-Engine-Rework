package options;

class CacheSettings extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Cache Settings.';
		rpcTitle = 'Cache Settings'; // for Discord Rich Presence

		var option:Option = new Option('Cache Graphics', // even tho only one person asked, it here
			"If checked, The Graphics Will Be Cached.", 'graphicsPreload2', 'bool');
		addOption(option);

		var option:Option = new Option('Cache Music', // even tho only one person asked, it here
			"If checked, The Music Will Be Cached.", 'musicPreload2', 'bool');
		addOption(option); // now shut up before i put you in my basement

		var option:Option = new Option('Experimental Caching',
			"If checked, Experimental Caching Will Be Enabled. Allows saving the Cache to the next session.", 'experimentalCaching', 'bool', null, FlxG.resetState);
		addOption(option);
		option.onChange = FlxG.resetState;

		var experimentalCachingEnabled:Bool = ClientPrefs.data.experimentalCaching;
		var saveCacheOption:Option = new Option('Save Cache',
			'If checked, the Cache will be saved for later plays.', 'saveCache', 'bool');
		var cacheChartsOption:Option = new Option('Cache Charts',
		'If checked, Charts will be added to the Cache.', 'cacheCharts', 'bool');

		if (experimentalCachingEnabled) {
			addOption(saveCacheOption);
			addOption(cacheChartsOption);
		} else {
			removeOption(saveCacheOption);
			ClientPrefs.data.saveCache = false;
			removeOption(cacheChartsOption);
			ClientPrefs.data.cacheCharts = false;
		}

		super();
	}

	override public function update(e:Float):Void {
		super.update(e);

		}	}