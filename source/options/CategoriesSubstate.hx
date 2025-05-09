package options;

class CategoriesSubstate extends LightBaseOptionsMenu
{
	public function new()
    {
        title = 'Category Settings.';
        rpcTitle = 'Category Settings'; // for Discord Rich Presence

        var option:Option = new Option('Show Mods as Categories',
            "Show mods as categories in the Categories menu.", 
            'showMods',
            BOOL);
        option.onChange = function actuallyChangeFucker()
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        addOption(option);

        super();
    }

    override function destroy() {
        ClientPrefs.saveSettings();
        super.destroy();
    }
}
    