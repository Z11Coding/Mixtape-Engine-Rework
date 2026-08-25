package backend;

#if ARCHIPELAGO_ALLOWED
import archipelago.APEntryState;
#end

import flixel.FlxSubState;

@:autoBuild(yutautil.StatePick.addToDatabase(MusicBeatSubstate))
class MusicBeatSubstate extends FlxSubState
{
	public static var instance:MusicBeatSubstate;

	public function new()
	{
		instance = this;
		//controls.isInSubstate = true;
		super();
	}

	// Mega Manager Refrences for easy access in substates
	public var conductor:RConductor = MegaManager.conductor;
	public var playfield:PlayfieldManager = MegaManager.playfield;
	public var mcm:CharacterManager = MegaManager.charaManager;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	override function update(elapsed:Float)
	{
		// Update trace management system (frame-based limiting and threading)
		backend.modules.TraceManager.update();

		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;

		#if ARCHIPELAGO_ALLOWED
		// Essential Archipelago function - APItem checking
		if (archipelago.APInfo.inArchipelagoMode)
			archipelago.APItem.doCheck();
		#end

		// Handle debug keys (essential for development and debugging)
		debug.DebugManager.handleDebugKeys();

		super.update(elapsed);

		#if ARCHIPELAGO_ALLOWED
		// Essential Archipelago polling
		if (APInfo.apGame != null && APInfo.inArchipelagoMode)
			APInfo.apGame.info()?.poll();
		#end
	}
}
