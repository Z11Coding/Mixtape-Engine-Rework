package archipelago;

class APCategoryState extends states.CategoryState {

    public var AP:archipelago.Client;
    public var gameState:archipelago.APGameState;


    public function new(gameState:archipelago.APGameState, ap:Client) {
        this.gameState = gameState;
        this.AP = gameState.info();
        menuItems = [];
        super(['All', /*'Hinted', 'Unlocked', For a later version*/ 'Unplayed', 'Options', 'Quit'], false, false, true, false, false);
        menuLocks = [false, false, false, false];
        specialOptions = [null, null, null, null];

        var opFunc = function() {
            MusicBeatState.switchState(new options.OptionsState());
        };

        var quitFunc = function() {
            AP.disconnect_socket();
            MusicBeatState.switchState(new archipelago.APEntryState());
        };
        specialOptions.push(opFunc);

        this.specialOptions.pushMulti([opFunc, quitFunc]);

        states.ExitState.addExitCallback(function() {
            if (AP != null){
                trace("Properly disconnecting from server before exiting...");
            AP.disconnect_socket();}
        });
    }

    override function update(elapsed:Float)
    {
        AP.poll();
        
        super.update(elapsed);
    }
}