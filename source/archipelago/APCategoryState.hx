package archipelago;

using yutautil.CollectionUtils;

class APCategoryState extends states.CategoryState {

    public var AP:archipelago.Client;
    public var gameState:archipelago.APGameState;


    public function new(gameState:archipelago.APGameState, ?AP:archipelago.Client) {
        this.gameState = gameState;
        var attempts = 0;
        while (attempts < 20) {
            try {
            this.AP = gameState.info();
            break;
            } catch (e) {
                trace('Failed to connect to Archipelago server, retrying... Attempt: ' + (++attempts));
            Sys.sleep(0.1);
            }
        }
        // Static menu with "Items" option moved after "Unplayed" and before "Options"
        var menuOptions = ['All', 'Hinted', 'Unlocked', 'Unplayed', 'Items', 'Options', 'Quit'];

        super(menuOptions, false, false, true, false, false);

        // Initialize locks array - "Items" is locked based on hasPocketLens (now at index 4)
        menuLocks = [false, false, false, false, !archipelago.APItem.hasPocketLens, false, false];
        specialOptions = [];

        var opFunc = function() {
            MusicBeatState.switchState(new options.OptionsState());
        };

        var quitFunc = function() {
            try{AP.disconnect_socket();}
            catch(e){}
            states.ExitState.addExitCallback(function() {
                var restartProcess = new Process("Mixtape.exe", ["APDisconnectError", "restart"]);
            });
            FlxG.switchState(new states.ExitState());
        };

        var itemsFunc = function() {
            MusicBeatState.switchState(new APItemsViewerState(gameState, AP));
        };

        rightOption = null;

        // Set up specialOptions for each menu item
        for (i in 0...menuItems.length) {
            if (menuItems[i] == 'Items') {
                specialOptions[i] = itemsFunc;
            } else if (menuItems[i] == 'Options') {
                specialOptions[i] = opFunc;
            } else if (menuItems[i] == 'Quit') {
                specialOptions[i] = quitFunc;
            } else {
                specialOptions[i] = null;
            }
        }

        // this.specialOptions.pushMulti([opFunc, quitFunc]);
        var cleanupFunc = function() {
            if (AP != null){
            APGameState.instance?.updateSaveData();
            trace("Properly disconnecting from server before exiting...");
            AP.disconnect_socket();
            }
            AP = null;
        };

        if (!states.ExitState.cleanupFunctions.contains(cleanupFunc)) {
            states.ExitState.addExitCallback(cleanupFunc);
        }
    }

    override function create()
    {
        super.create();
        if (APEntryState.gonnaRunSync && APEntryState.inArchipelagoMode) {
			APEntryState.apGame.info().Sync();
		}
    }

    var shopItem:FlxSprite;
    override function update(elapsed:Float)
    {
        // If Legacy Lua settings are being edited, switch to Legacy Lua version
        if (options.legacylua.LegacyLuaSettingsState.inLegacyLuaSettingsMode) {
            FlxG.switchState(new options.legacylua.LegacyLuaCategoryState());
            return;
        }

        super.update(elapsed);
        AP.poll();
    }
}
