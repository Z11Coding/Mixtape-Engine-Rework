package options;

class ChartEditorSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Chart Editor Settings';
		rpcTitle = 'Chart Editor Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Autosave',
			'If checked, the Chart Editor will autosave.',
			'autosaveCharts',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('AutoSave Interval',
			'Interval for chart editor autosaves (in minutes).',
			'autosaveInterval',
			'float',
			5.0);
		option.scrollSpeed = 5;
		option.minValue = 1;
		option.maxValue = 30;
		option.changeValue = 1;
		option.displayFormat = '%v Minutes';
		addOption(option);

		super();
	}
}