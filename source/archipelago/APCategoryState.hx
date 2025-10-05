package archipelago;

import yutautil.GenericProgressSubstate;

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

        super(menuOptions, false, false, true, false, false, false);

        // Initialize locks array - "Items" is locked based on hasPocketLens.
        menuLocks = [false, false, false, false, !archipelago.APItem.hasPocketLens, false, false];
        specialOptions = [];

        var opFunc = function() {
            MusicBeatState.switchState(new options.OptionsState());
        };

        var quitFunc = function() {
            trace('QUIT FUNCTION CALLED - User selected quit or automatic quit triggered');

            // Create progress tasks for graceful shutdown
            var tasks = [
                GenericProgressSubstate.createTask("Disconnecting from Archipelago server...", function(results) {
                    // Just telling the game we're disconnecting to avoid reconnection attempts.
                    gameState.isPurposefullyDisconnected = true;
                    return "disconnect_initiated";
                }, true), // throwOnError: true for proper disconnection
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
                }, true), // throwOnError: true for critical save operation

                GenericProgressSubstate.createTask("Cleaning up temporary weeks...", function(results) {
                    try {
                        archipelago.APGameState.forceCleanupTemporaryWeeks();
                        trace('Temporary weeks cleaned up successfully');
                        return "cleanup_success";
                    } catch (e) {
                        trace('Error cleaning up temporary weeks: ' + e);
                        return "cleanup_error";
                    }
                }, false), // Don't throw on error - this is less critical

                GenericProgressSubstate.createTask("Clearing AP Items and data...", function(results) {
                    try {
                        archipelago.APItem.cleanupAllAPData();
                        trace('AP Items and data cleaned up successfully');
                        return "apitem_cleanup_success";
                    } catch (e) {
                        trace('Error cleaning up AP Items and data: ' + e);
                        return "apitem_cleanup_error";
                    }
                }, false), // Don't throw on error - continue even if cleanup fails

                GenericProgressSubstate.createTask("Disconnecting from Archipelago server...", function(results) {
                    try {
                        if (AP != null) {
                            if (gameState != null) {
                                gameState.disconnectAP();
                            } else {
                                AP.disconnect_socket();
                            }
                            trace('Successfully disconnected from Archipelago server');
                            return "disconnect_success";
                        } else {
                            trace('AP client was null, no disconnection needed');
                            return "disconnect_skipped";
                        }
                    } catch (e) {
                        trace('Error disconnecting AP: ' + e);
                        throw e;
                    }
                }, true), // throwOnError: true for proper disconnection

                GenericProgressSubstate.createTask("Nullifying all AP references...", function(results) {
                    try {
                        // Clean up all static references to apGame and client

                        // APEntryState references
                        archipelago.APEntryState.inArchipelagoMode = false;
                        if (archipelago.APEntryState.apGame != null) {
                            archipelago.APEntryState.apGame = null;
                        }
                        if (archipelago.APEntryState.ap != null) {
                            archipelago.APEntryState.ap = null;
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

                        // APStyledEntryState references
                        if (archipelago.APStyledEntryState.apGame != null) {
                            archipelago.APStyledEntryState.apGame = null;
                        }
                        if (archipelago.APStyledEntryState.ap != null) {
                            archipelago.APStyledEntryState.ap = null;
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
                        AP = null;
                        gameState = null;

                        trace('All Archipelago references nullified successfully');
                        return "nullify_success";
                    } catch (e) {
                        trace('Error nullifying Archipelago references: ' + e);
                        return "nullify_error";
                    }
                }, false) // Don't throw - we want to continue even if this fails
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
                        archipelago.APEntryState.inArchipelagoMode = false;
                        archipelago.APEntryState.apGame = null;
                        archipelago.APEntryState.ap = null;
                        archipelago.APInfo.apGame = null;
                        archipelago.APInfo.ap = null;
                        archipelago.APInfo.inMinigame = archipelago.APInfo.APMinigame.None;
                        archipelago.APPlayState.apGame = null;
                        archipelago.APStyledEntryState.apGame = null;
                        archipelago.APStyledEntryState.ap = null;
                        // archipelago.APGameState.instance?.updateSaveData();
                        archipelago.APGameState.instance = null;
                        AP = null;
                        gameState = null;
                        managers.FreeplayManager.instance = null;
                        managers.APFreeplayManager.cleanup();

                        // Clean up AP Items and data
                        archipelago.APItem.cleanupAllAPData();

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
                    // Cancel callback - user canceled the shutdown
                    trace('User canceled the shutdown process');
                    // Stay in the current state
                }, true // Normally, you should not be able to cancel quitting.
            );

            openSubState(progressDialog);
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
        // Enhanced cleanup function for emergency exit
        var cleanupFunc = function() {
            trace("Emergency cleanup: Disconnecting and nullifying all AP references...");

            // Try to save data if possible
            try {
                if (gameState != null) {
                    gameState.updateSaveData();
                }
                APGameState.instance?.updateSaveData();
            } catch (e) {
                trace('Error saving data during emergency cleanup: ' + e);
            }

            // Disconnect if possible
            try {
                if (AP != null) {
                    AP.disconnect_socket();
                    AP = null;
                }
            } catch (e) {
                trace('Error disconnecting during emergency cleanup: ' + e);
            }

            // Nullify all static references
            try {
                archipelago.APEntryState.inArchipelagoMode = false;
                archipelago.APEntryState.apGame = null;
                archipelago.APEntryState.ap = null;
                archipelago.APInfo.apGame = null;
                archipelago.APInfo.ap = null;
                archipelago.APPlayState.apGame = null;
                archipelago.APStyledEntryState.apGame = null;
                archipelago.APStyledEntryState.ap = null;
                archipelago.APGameState.instance = null;
                managers.FreeplayManager.instance = null;
                managers.APFreeplayManager.cleanup();

                // Clean up AP Items and data
                archipelago.APItem.cleanupAllAPData();
            } catch (e) {
                trace('Error nullifying references during emergency cleanup: ' + e);
            }

            // Clean up local references
            gameState = null;
        };

        if (!states.ExitState.cleanupFunctions.contains(cleanupFunc)) {
            states.ExitState.addExitCallback(cleanupFunc);
        }
        if (!states.ExitState.cleanupFunctions.contains(quitFunc)) {
            states.ExitState.addExitCallback(quitFunc);
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
