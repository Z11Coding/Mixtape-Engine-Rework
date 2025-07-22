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
        menuItems = [];
        super(['All', 'Hinted', 'Unlocked', 'Unplayed', 'Options', 'Quit'], false, false, true, false, false);
        menuLocks = [false, false, false, false, false, false];
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

        // Ensure specialOptions are set correctly for 'Options' and 'Quit'
        for (i in 0...menuItems.length) {
            if (menuItems[i] == 'Options') {
            specialOptions[i] = opFunc;
            } else if (menuItems[i] == 'Quit') {
            specialOptions[i] = quitFunc;
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
        super.update(elapsed);
        AP.poll();
    }
}