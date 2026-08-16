package archipelago;

import yutautil.GenericProgressSubstate;

using yutautil.CollectionUtils;

/**
 * Error state displayed when AP connection fails or loses connection during gameplay.
 * Fades out music and displays error message, then performs graceful shutdown.
 */
class APConnectionErrorState extends backend.MusicBeatState
{
	private var gameState:archipelago.APGameState;
	private var musicFadeComplete:Bool = false;

	public function new(?gameState:archipelago.APGameState)
	{
		super();
		this.gameState = gameState;
	}

	override function create()
	{
		super.create();

		// Fade out the music over 2 seconds if it exists
		if (FlxG.sound.music != null)
		{
			FlxTween.tween(FlxG.sound.music, {volume: 0}, 2.0, {
				onComplete: function(tween:FlxTween) {
					musicFadeComplete = true;
					showErrorDialog();
				}
			});
		}
		else
		{
			musicFadeComplete = true;
			showErrorDialog();
		}
	}

	private function showErrorDialog()
	{
		var errorMsg = "An internal error occurred within the Archipelago session.\n\n"
			+ "The session has been terminated to prevent further issues.\n\n"
			+ "Please try again.";

		var infoSubstate = new archipelago.substates.InfoPanelSubstate(
			"Archipelago Session Error",
			errorMsg,
			0xFF220000, // red background
			function() {
				performShutdown();
			}
		);

		openSubState(infoSubstate);
	}

	private function performShutdown()
	{
		// Create the same shutdown tasks as in APCategoryState quitFunc
		var tasks = [
			GenericProgressSubstate.createTask("Disconnecting from Archipelago server...", function(results) {
				// Just telling the game we're disconnecting to avoid reconnection attempts.
				if (gameState != null)
					gameState.isPurposefullyDisconnected = true;
				return "disconnect_initiated";
			}, true),
			GenericProgressSubstate.createTask("Saving game data...", function(results) {
				try {
					if (gameState != null) {
						gameState.updateSaveData();
						trace('Game data saved successfully');
						return "save_success";
					} else {
						trace('No game state to save');
						return "save_skipped";
					}
				} catch (e) {
					trace('Error saving game data: ' + e);
					throw e;
				}
			}, true),

			GenericProgressSubstate.createTask("Cleaning up temporary weeks...", function(results) {
				try {
					archipelago.APGameState.forceCleanupTemporaryWeeks();
					trace('Temporary weeks cleaned up successfully');
					return "cleanup_success";
				} catch (e) {
					trace('Error cleaning up temporary weeks: ' + e);
					return "cleanup_error";
				}
			}, false),

			GenericProgressSubstate.createTask("Clearing AP Items and data...", function(results) {
				try {
					archipelago.APItem.cleanupAllAPData();
					trace('AP Items and data cleaned up successfully');
					return "apitem_cleanup_success";
				} catch (e) {
					trace('Error cleaning up AP Items and data: ' + e);
					return "apitem_cleanup_error";
				}
			}, false),

			GenericProgressSubstate.createTask("Clearing AP playlists...", function(results) {
				try {
					archipelago.APPlaylistState.apPlaylists = [];
					trace('AP playlists cleared successfully');
					return "playlists_cleanup_success";
				} catch (e) {
					trace('Error clearing AP playlists: ' + e);
					return "playlists_cleanup_error";
				}
			}, false),

			GenericProgressSubstate.createTask("Disconnecting from Archipelago server...", function(results) {
				try {
					if (gameState != null) {
						gameState.disconnectAP();
					}
					trace('Successfully disconnected from Archipelago server');
					return "disconnect_success";
				} catch (e) {
					trace('Error disconnecting AP: ' + e);
					throw e;
				}
			}, true),

			GenericProgressSubstate.createTask("Nullifying all AP references...", function(results) {
				try {
					// Clean up all static references to apGame and client

					// APInfo references
					archipelago.APInfo.inArchipelagoMode = false;
					if (archipelago.APInfo.apGame != null) {
						archipelago.APInfo.apGame = null;
					}
					if (archipelago.APInfo.ap != null) {
						archipelago.APInfo.ap = null;
					}

					// APInfo references
					if (archipelago.APInfo.apGame != null) {
						archipelago.APInfo.apGame = null;
					}
					if (archipelago.APInfo.ap != null) {
						archipelago.APInfo.ap = null;
					}

					archipelago.APInfo.inMinigame = archipelago.APInfo.APMinigame.None;

					// APPlayState references
					if (archipelago.APPlayState.apGame != null) {
						archipelago.APPlayState.apGame = null;
					}


					// APGameState instance reference
					if (archipelago.APGameState.instance != null) {
						archipelago.APGameState.instance = null;
					}

					// AP Freeplay references
					if (managers.FreeplayManager.instance is APFreeplayManager) {
						managers.FreeplayManager.instance = null;
						managers.APFreeplayManager.cleanup();
					}

					// Clean up local references in this state
					gameState = null;

					trace('All Archipelago references nullified successfully');
					return "nullify_success";
				} catch (e) {
					trace('Error nullifying Archipelago references: ' + e);
					return "nullify_error";
				}
			}, false)
		];

		var progressDialog = new GenericProgressSubstate(
			"Exiting Archipelago Mode",
			tasks,
			function(results) {
				// Success callback - all tasks completed successfully
				trace('All shutdown tasks completed successfully. Results: ' + results);
				FlxG.switchState(new states.MainMenuState());
			},
			function(error, shouldThrow) {
				// Error callback - something went wrong
				trace('Error during shutdown process: ' + error);

				// Ensure emergency cleanup happens even on error
				try {
					archipelago.APInfo.inArchipelagoMode = false;
					archipelago.APInfo.apGame = null;
					archipelago.APInfo.ap = null;
					archipelago.APInfo.apGame = null;
					archipelago.APInfo.ap = null;
					archipelago.APInfo.inMinigame = archipelago.APInfo.APMinigame.None;
					archipelago.APPlayState.apGame = null;
					archipelago.APGameState.instance = null;
					gameState = null;
					managers.FreeplayManager.instance = null;
					managers.APFreeplayManager.cleanup();

					// Clean up AP Items and data
					archipelago.APItem.cleanupAllAPData();

					// Clear AP playlists
					archipelago.APPlaylistState.apPlaylists = [];

					trace('Emergency cleanup completed during error handling');
				} catch (cleanupError) {
					trace('Error during emergency cleanup: ' + cleanupError);
				}

				if (shouldThrow) {
					// Critical error occurred, fall back to exit state
					trace('Critical error occurred, falling back to exit state');
					states.ExitState.addExitCallback(function() {
						var restartProcess = new Process("Mixtape.exe", ["APDisconnectError", "restart"]);
					});
					MusicBeatState.switchState(new states.ExitState());
				} else {
					// Non-critical error, try to continue to main menu
					trace('Non-critical error, attempting to continue to main menu');
					MusicBeatState.switchState(new states.MainMenuState());
				}
			},
			function() {
				// Cancel callback - user canceled the shutdown (shouldn't happen with no cancel button)
				trace('Shutdown process was cancelled');
			},
			true // Cannot cancel quitting
		);

		openSubState(progressDialog);
	}
}
