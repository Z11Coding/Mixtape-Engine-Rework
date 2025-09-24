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
                if (this.AP != null) {
                    trace('Successfully connected to Archipelago server on attempt: ' + (attempts + 1));
                    break;
                }
            } catch (e) {
                trace('Failed to connect to Archipelago server, retrying... Attempt: ' + (++attempts) + ' Error: ' + e);
                if (attempts >= 20) {
                    trace('All connection attempts failed. Falling back to passed AP client.');
                    this.AP = AP; // Use the passed AP client as fallback
                    break;
                }
                Sys.sleep(0.1);
            }
        }

        // Final check - if we still don't have a connection, something is very wrong
        if (this.AP == null) {
            trace('CRITICAL: No AP connection available. This will cause issues.');
            // Don't switch to ExitState immediately - let the parent class handle it
        }
        // Static menu with "Items" option moved after "Unplayed" and before "Options"
        var menuOptions = ['All', 'Hinted', 'Unlocked', 'Unplayed', 'Items', 'Options', 'Quit'];

        super(menuOptions, false, false, true, false, false);

        // Initialize locks array - "Items" is locked based on hasPocketLens.
        menuLocks = [false, false, false, false, !archipelago.APItem.hasPocketLens, false, false];
        specialOptions = [];

        var opFunc = function() {
            MusicBeatState.switchState(new options.OptionsState());
        };

        var quitFunc = function() {
            trace('QUIT FUNCTION CALLED - User selected quit or automatic quit triggered');
            try{
                if (AP != null) {
                    AP.disconnect_socket();
                } else {
                    trace('AP client was null when trying to disconnect');
                }
            }
            catch(e){
                trace('Error disconnecting AP: ' + e);
            }
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
        if (APEntryState.gonnaRunSync && APEntryState.inArchipelagoMode && APEntryState.apGame != null) {
            try {
                var apClient = APEntryState.apGame.info();
                if (apClient != null) {
                    apClient.Sync();
                } else {
                    trace('Warning: AP client is null, skipping sync');
                }
            } catch (e) {
                trace('Error during AP sync: ' + e);
            }
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

        // Null check before polling
        if (AP != null) {
            try {
                AP.poll();
            } catch (e) {
                trace('Error during AP polling: ' + e);
                // Don't crash the game, just log the error
            }
        } else {
            trace('Warning: AP client is null, skipping poll');
        }
    }
}
