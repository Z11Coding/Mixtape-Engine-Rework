package states.menus;

import states.menus.*;
import flixel.FlxState;

class MenuTracker {
    public static var curMainMenu:String = 'psych';
    public static var mainMenuState:Class<FlxState> = states.menus.MainMenuState;
    public static final psychEngineJSVersion:String = '1.42.0';
	public static final psychEngineVersion:String = '1.0.2h';
    public static final micedEngineVersion:String = '2.0.3';
    public static final fridayVersion:String = '0.2.7-Git + 0.2.8-NG';
    public static final mixtapeEngineVersion:String = '2.0.0';

    public static function updateMenu(menu:String) { //TODO: Expand what this does
        switch (menu:String)
        {
            case 'main':
                mainMenuState = states.menus.MainMenuState;
            case 'psych':
                mainMenuState = states.menus.PsychMenuState;
            case 'mixtape':
                mainMenuState = states.menus.MixtapeMenuState;
            case 'miced up':
                mainMenuState = states.menus.MicdUpMenuState;
        }
    }
}