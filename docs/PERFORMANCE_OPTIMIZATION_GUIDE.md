# Mixtape Engine Performance Optimization Guide

## Critical Performance Issues and Solutions

### 1. Input System Optimization

#### Problem: Sustain Note Lag
The current input system has several performance bottlenecks:
- Array operations (`keysPressed.contains()`, `keysPressed.push()`) every frame
- Multiple playfield iterations per input
- Excessive script callbacks
- Unnecessary Conductor.songPosition manipulation

#### Solution: Optimized Input System

**File: `source/states/PlayState.hx` - Replace keyPressed function:**

```haxe
// Optimize keysPressed array operations
private static var keysPressedSet:Map<Int, Bool> = new Map(); // Use Map instead of Array

private function keyPressed(key:Int, player:Int = -1)
{
    if(cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;
    if (strumsBlocked[key]) return;

    // Early script callback optimization - only call if scripts exist
    if (luaArray.length > 0 || hscriptArray.length > 0) {
        var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
        if(ret == LuaUtils.Function_Stop) return;
    }

    // Store original conductor position ONCE
    var lastTime:Float = Conductor.songPosition;
    if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

    var hitNotes:Array<Note> = [];
    var controlledFields:Array<PlayField> = [];

    // Pre-filter controlled fields to avoid repeated checks
    for (field in playfields.members) {
        if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed)
            continue;
        controlledFields.push(field);
    }

    // Process all controlled fields
    for (field in controlledFields) {
        field.keysPressed[key] = true;

        if (endingSong) continue;

        var note:Note = null;

        // Optimize script callback - only call if scripts exist and return early if stopped
        if (luaArray.length > 0 || hscriptArray.length > 0) {
            var ret:Dynamic = callOnScripts("onFieldInput", [field, key, hitNotes]);
            if (ret == LuaUtils.Function_Stop) {
                note = null;
            } else if (ret is Note) {
                note = ret;
            } else {
                note = field.input(key);
            }
        } else {
            note = field.input(key);
        }

        if (note == null) {
            var spr:StrumNote = field.strumNotes[key];
            if (spr != null) {
                spr.playAnim('pressed');
                spr.resetAnim = 0;
            }
        } else {
            hitNotes.push(note);
        }
    }

    // Handle ghost tapping
    if (hitNotes.length == 0) {
        for (field in controlledFields) {
            if (luaArray.length > 0 || hscriptArray.length > 0) {
                callOnScripts('onGhostTap', [key, field]);
            }

            if (!ClientPrefs.data.ghostTapping)
                noteMissPress(key, field);
        }
    }

    // Optimize keysPressed tracking with Map
    keysPressedSet[key] = true;

    // Restore conductor position ONCE
    Conductor.songPosition = lastTime;

    // Final script callback - only if scripts exist
    if (luaArray.length > 0 || hscriptArray.length > 0) {
        callOnScripts('onKeyPress', [key]);
    }
}
```

**File: `source/states/PlayState.hx` - Optimize keysCheck function:**

```haxe
// Cache the parsed arrays to avoid recreating them every frame
private static var _cachedHoldArray:Array<Bool> = [];
private static var _cachedPressArray:Array<Bool> = [];
private static var _cachedReleaseArray:Array<Bool> = [];

private function keysCheck():Void
{
    if (ClientPrefs.data.inputSystem == 'Native-old') {
        // Reuse arrays instead of creating new ones
        var holdArray = _cachedHoldArray;
        var pressArray = _cachedPressArray;
        var releaseArray = _cachedReleaseArray;

        // Clear and resize arrays efficiently
        holdArray.splice(0, holdArray.length);
        pressArray.splice(0, pressArray.length);
        releaseArray.splice(0, releaseArray.length);

        var keyArrayLength = keysArray[mania].length;
        holdArray.resize(keyArrayLength);
        pressArray.resize(keyArrayLength);
        releaseArray.resize(keyArrayLength);

        // Use direct indexing instead of push
        for (i in 0...keyArrayLength) {
            var key = keysArray[mania][i];
            holdArray[i] = controls.pressed(key);
            pressArray[i] = controls.justPressed(key);
            releaseArray[i] = controls.justReleased(key);
        }

        // Optimize controller input handling
        if(controls.controllerMode) {
            for (i in 0...pressArray.length) {
                if(pressArray[i] && strumsBlocked[i] != true) {
                    keyPressed(i);
                }
            }
        }

        // Optimize hold checking
        if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic) {
            var hasHoldInput = false;
            for (hold in holdArray) {
                if (hold) {
                    hasHoldInput = true;
                    break;
                }
            }

            if (!hasHoldInput && !endingSong) {
                playerDance();
            }
            #if ACHIEVEMENTS_ALLOWED
            else if (hasHoldInput) {
                checkForAchievement(['oversinging']);
            }
            #end
        }

        // Optimize release handling
        if((controls.controllerMode || strumsBlocked.contains(true))) {
            for (i in 0...releaseArray.length) {
                if(releaseArray[i] || strumsBlocked[i] == true) {
                    keyReleased(i);
                }
            }
        }
    } else {
        // Existing alternative input system code...
        var parsedHoldArray:Array<Bool> = parseKeys();
        pressedGameplayKeys = parsedHoldArray;

        if (startedCountdown && !boyfriend.stunned && generatedMusic) {
            notes.forEachAlive(function(daNote:Note) {
                if (parsedHoldArray.contains(true) && !endingSong) {
                    #if ACHIEVEMENTS_ALLOWED
                    checkForAchievement(['oversinging']);
                    #end
                }
            });
        }
    }
}
```

### 2. Memory Leak Prevention

#### Problem: Progressive Memory Accumulation
Extended use causes increasing lag due to:
- Uncleaned note references in sustain chains
- Script objects not being properly disposed
- Tween/Timer accumulation
- Event listeners not being removed

#### Solution: Enhanced Memory Management

**File: `source/states/PlayState.hx` - Enhanced destroy function:**

```haxe
override function destroy() {
    // Clear all note references first to prevent circular references
    if (notes != null) {
        notes.forEachAlive(function(note:Note) {
            if (note != null) {
                // Clear sustain note chains properly
                if (note.tail != null) {
                    for (tailNote in note.tail) {
                        if (tailNote != null) {
                            tailNote.parent = null;
                        }
                    }
                    note.tail = [];
                }
                if (note.unhitTail != null) {
                    note.unhitTail = [];
                }
                note.parent = null;
            }
        });
        notes.clear();
        notes = null;
    }

    // Clear all playfield references
    if (playfields != null) {
        playfields.forEachAlive(function(field:PlayField) {
            if (field != null) {
                field.noteField.clear();
                field.strumNotes.clear();
            }
        });
        playfields.clear();
        playfields = null;
    }

    // Force clear all tweens and timers before script cleanup
    FlxTween.globalManager.clear();
    FlxTimer.globalManager.clear();

    // Enhanced script cleanup with proper disposal
    #if LUA_ALLOWED
    if (luaArray != null && luaArray.length > 0) {
        for (lua in luaArray) {
            if (lua != null) {
                try {
                    lua.call('onDestroy', []);
                    lua.stop();
                } catch (e:Dynamic) {
                    trace('Error destroying Lua script: $e');
                }
            }
        }
        luaArray = [];
        luaArray = null;
    }

    if (legacyLuaArray != null && legacyLuaArray.length > 0) {
        for (lua in legacyLuaArray) {
            if (lua != null) {
                try {
                    lua.call('onDestroy', []);
                    lua.stop();
                } catch (e:Dynamic) {
                    trace('Error destroying legacy Lua script: $e');
                }
            }
        }
        legacyLuaArray = [];
        legacyLuaArray = null;
    }

    if (FunkinLua.customFunctions != null) {
        FunkinLua.customFunctions.clear();
    }
    #end

    #if HSCRIPT_ALLOWED
    if (hscriptArray != null && hscriptArray.length > 0) {
        for (script in hscriptArray) {
            if(script != null) {
                try {
                    if(script.exists('onDestroy')) script.call('onDestroy');
                    script.destroy();
                } catch (e:Dynamic) {
                    trace('Error destroying HScript: $e');
                }
            }
        }
        hscriptArray = [];
        hscriptArray = null;
    }
    #end

    // Clear input tracking
    keysPressedSet.clear();
    keysPressed = [];

    // Enhanced video cleanup
    #if VIDEOS_ALLOWED
    if(videoCutscene != null) {
        videoCutscene.destroy();
        videoCutscene = null;
    }

    for (video in syncedVideos) {
        if (video != null) {
            video.destroy();
        }
    }
    syncedVideos = [];
    queuedSyncedVideos = [];
    #end

    // Remove ALL event listeners
    if (FlxG.stage != null) {
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
        FlxG.stage.removeEventListener(MouseEvent.MOUSE_DOWN, leftMousePress);
        FlxG.stage.removeEventListener(MouseEvent.MOUSE_UP, leftMouseRelease);
        FlxG.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMousePress);
        FlxG.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, rightMouseRelease);
    }

    // Clear camera filters
    if (FlxG.camera != null) {
        FlxG.camera.setFilters([]);
    }

    // Reset audio properties
    #if FLX_PITCH
    if (FlxG.sound.music != null) {
        FlxG.sound.music.pitch = 1;
    }
    #end
    FlxG.animationTimeScale = 1;

    // Clear static references
    Note.globalRgbShaders = [];
    backend.NoteTypesConfig.clearNoteTypesData();
    NoteSplash.configs.clear();

    // Thread cleanup
    if (threadPool != null) {
        threadPool.shutdown();
        threadPool = null;
    }
    if (mutex != null) {
        mutex = null;
    }

    // Enhanced NotePool cleanup
    if (ClientPrefs.data.useExperimentalNotePool) {
        NotePoolManager.forceCleanup();
        trace("Experimental NotePool system cleaned up aggressively");
    }

    // Clear mod mechanics
    if (mechanicsMod != null) {
        mechanicsMod.luckMechanicDestroy();
        mechanicsMod = null;
    }

    // Clear all arrays and references
    moveStrumSections = null;
    variables = null;
    keysArray = null;

    // Reset state variables
    mania = 3;
    instance = null;
    endingSong = true;

    // Call parent destroy LAST
    super.destroy();

    // Force garbage collection hint
    #if cpp
    cpp.vm.Gc.run(true);
    #end
}
```

### 3. Additional Performance Optimizations

#### Sustain Note Processing Optimization

**File: `source/states/PlayState.hx` - Optimize sustain note creation:**

```haxe
// Cache sustain note properties to avoid repeated calculations
private static var _sustainNoteCache:Map<String, Dynamic> = new Map();

// In note generation (around line 3906):
var sustainNote:Note = null;

// Create cache key for sustain properties
var cacheKey = '${swagNote.noteData}_${swagNote.noteType}_${gottaHitNote}';
var cachedProps = _sustainNoteCache.get(cacheKey);

if (cachedProps == null) {
    // First time creating this type of sustain note, cache properties
    cachedProps = {
        noteData: swagNote.noteData,
        noteType: swagNote.noteType,
        mustPress: gottaHitNote,
        gfNote: swagNote.gfNote,
        exNote: swagNote.exNote,
        animSuffix: swagNote.animSuffix,
        multSpeed: swagNote.multSpeed
    };
    _sustainNoteCache.set(cacheKey, cachedProps);
}

// Use pooled or create new sustain note
sustainNote = ClientPrefs.data.useExperimentalNotePool ?
    NotePoolManager.getSustainNote(sustainTime, swagNote.noteData, cachedProps.noteType) :
    new Note(sustainTime, swagNote.noteData, null, false, cachedProps.noteType);

// Apply cached properties efficiently
sustainNote.mustPress = cachedProps.mustPress;
sustainNote.gfNote = cachedProps.gfNote;
sustainNote.exNote = cachedProps.exNote;
sustainNote.animSuffix = cachedProps.animSuffix;
sustainNote.noteIndex = swagNote.noteIndex;

if (sustainNote.multSpeed != cachedProps.multSpeed) {
    sustainNote.multSpeed = cachedProps.multSpeed;
}
```

#### Script Callback Optimization

**File: `source/states/PlayState.hx` - Optimize script calls:**

```haxe
// Add script existence checks to avoid unnecessary function calls
private var hasLuaScripts:Bool = false;
private var hasHScripts:Bool = false;

// Update these flags when scripts are added/removed
private function updateScriptFlags():Void {
    hasLuaScripts = (luaArray != null && luaArray.length > 0);
    hasHScripts = (hscriptArray != null && hscriptArray.length > 0);
}

// Modified callOnScripts function with early exit
public function callOnScripts(funcName:String, args:Array<Dynamic> = null):Dynamic {
    if (!hasLuaScripts && !hasHScripts) {
        return LuaUtils.Function_Continue; // Early exit if no scripts
    }

    // Rest of callOnScripts implementation...
}
```

### 4. Memory Monitoring and Debugging

Add memory monitoring to detect leaks early:

**File: `source/states/PlayState.hx` - Add memory monitoring:**

```haxe
// Add to create() function
#if debug
private var memoryMonitor:FlxText;
private var lastMemoryCheck:Float = 0;

private function initMemoryMonitor():Void {
    memoryMonitor = new FlxText(10, FlxG.height - 60, 300, "", 12);
    memoryMonitor.scrollFactor.set();
    add(memoryMonitor);
}

// Add to update() function
private function updateMemoryMonitor(elapsed:Float):Void {
    lastMemoryCheck += elapsed;
    if (lastMemoryCheck >= 1.0) { // Check every second
        lastMemoryCheck = 0;

        #if cpp
        var memUsage = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
        var memReserved = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED);

        memoryMonitor.text = 'Memory: ${Math.round(memUsage / 1024 / 1024)}MB / ${Math.round(memReserved / 1024 / 1024)}MB';

        // Warning if memory usage is high
        if (memUsage > 500 * 1024 * 1024) { // 500MB warning
            memoryMonitor.color = FlxColor.RED;
            trace('WARNING: High memory usage detected: ${Math.round(memUsage / 1024 / 1024)}MB');
        } else {
            memoryMonitor.color = FlxColor.WHITE;
        }
        #end
    }
}
#end
```

## Implementation Priority

1. **Immediate (Critical)**: Input system optimization
2. **High Priority**: Enhanced destroy() function
3. **Medium Priority**: Sustain note optimization
4. **Long-term**: Memory monitoring and debugging tools

## Testing and Validation

After implementing these changes:

1. Test with high BPM songs with many sustains
2. Monitor memory usage during extended play sessions
3. Test with multiple mods loaded
4. Verify script callbacks still work correctly
5. Test both pooled and non-pooled note systems

These optimizations should significantly reduce input lag and prevent memory accumulation during extended play sessions.
