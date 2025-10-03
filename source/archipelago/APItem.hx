package archipelago;

import archipelago.TrapLinkFunctions;
import archipelago.traps.TrapGameManager;
import backend.WeekData;
import backend.window.PlatformUtil;
import cutscenes.DialogueBoxPsych;
import flixel.addons.display.FlxRuntimeShader;
import flixel.util.FlxDestroyUtil;
import haxe.ds.StringMap;
import openfl.filters.ShaderFilter;
import yutautil.GenericProgressSubstate;

typedef Condition = {
    var checkFn:APItem->Bool;
    var type:ConditionType;
    var ?extraConditions:Array<APItem->Bool>;
}

enum ConditionType {
    Everywhere;
    PlayState;
    Freeplay;
}

class ConditionHelper {
    private static inline function create(check:APItem->Bool, type:ConditionType):Condition {
        return { checkFn: check, type: type };
    }

    public static inline function check(item:APItem):Bool {
        return item.condition.checkFn(item) && (item.condition.extraConditions == null || item.condition.extraConditions.map(function(fn) { return fn(item); }).contains(false) == false);
    }

    public static inline function Special():Condition {
        return ConditionHelper.create(function(item:APItem):Bool {
            if (Std.is(FlxG.state, FreeplayManager.getFreeplay())) {
                return true; // Acts like Everywhere in Freeplay
            } else if (Std.is(FlxG.state, states.PlayState)) {
                return PlayState().checkFn(item);
            }
            return false; // Default to false for other states
        }, ConditionType.Everywhere);
    }

    public static inline function Everywhere():Condition {
        return ConditionHelper.create(function(item:APItem):Bool { return true; }, ConditionType.Everywhere);
    }
    public static inline function PlayState(?oneAtATime:Bool = false):Condition {
        return ConditionHelper.create(function(item:APItem):Bool {
            if (!Std.is(FlxG.state, states.PlayState)) return false;
            var playState = states.PlayState.instance;
            if (playState == null) return false;

            // Don't allow activation if song has ended, transitioning, or in ranking substate
            if (playState.endingSong || playState.transitioning || backend.TransitionState.currenttransition != null) return false;

            // Check if we're in a substate that should block activation
            if (playState.subState != null && Std.is(playState.subState, substates.RankingSubstate)) return false;

            return playState.startingSong || (item.isException && playState.startedCountdown);
        }, ConditionType.PlayState);
    }
    public static inline function Freeplay():Condition {
        return ConditionHelper.create(function(item:APItem):Bool { return Std.is(FlxG.state, FreeplayManager.getFreeplay()); }, ConditionType.Freeplay);
    }
}

class ActiveArray {
    private var items:Array<APItem>;

    public function new(items:Array<APItem>) {
        this.items = items;
    }

    public function getItems():Array<APItem> {
        return items;
    }

    public function push(item:APItem):Void {
        items.push(item);
        checkAndTrigger();
    }

    public function pop():APItem {
        var item = items.pop();
        return item;
    }

    public function shift():APItem {
        var item = items.shift();
        return item;
    }

    public function unshift(item:APItem):Void {
        items.unshift(item);
        checkAndTrigger();
    }

    public function remove(item:APItem):Bool {
        var index = items.indexOf(item);
        if (index == -1) {
            return false;
        }
        items.splice(index, 1);
        return true;
    }

    public inline function checkAndTrigger():Void {
        APItem.checkAndTrigger(items);
    }
}

typedef CustomModItem = {
    name:String,
    ?mod:String,
    ?onTrigger:Void->Void,
    count:Int,
    ?condition:Condition
}

class APItem {
    public var name:String;
    public var condition:Condition;
    public var onTrigger:Void->Void;
    public var isException:Bool;
    public static var allowedToTrigger(get, never):Bool;
    public var fromTrapLink:Bool = false; // Used for traps that are sent from TrapLink.
    public var isTrap:Bool = false;

    static function get_allowedToTrigger():Bool {
        return true;
    }
    public static var activeItem:APItem;
    public static var shields:Int = 0;
    public static var maxHPUp:Int = 0;
    public static var hasPocketLens:Bool = false;
    public static var hasDashMechanic:Bool = false;
    public static var overloadHP:Int = 0; // Adds extra health which can go over the max HP.
    public static var extaLives:Int = 0; // Used for the "Extralives" item.
    public static var pendingDamage:Float = 0.0; // Damage that will be applied when conditions are met
    public static var extraItemInventory:Array<CustomModItem> = [];

    public static var unoColorsUnlocked:Array<{name:String, color_code:String}> = [];

    public static var unknownSongs:Bool = false; // If true, songs are unknown.

    private var toSync:Bool = true;
    public var triggered:Bool = false;

    public static var nonSongItemCounts:Map<String, Int> = new Map<String, Int>();




    private static var allItems:ActiveArray = new ActiveArray([]);

    public function new(name:String, condition:Condition, onTrigger:Void->Void, isException:Bool = false, toSync:Bool = false, ?activeOnly:Bool = false) {
        this.name = name;
        this.condition = condition;
        this.onTrigger = onTrigger;
        this.isException = isException;
        this.toSync = toSync;
        // If trap, make it so.
        this.isTrap = (this is APTrap);

        if (this.condition.type == Everywhere) {
            this.isException = true;
        }

        this.toSync = false;
        if (!activeOnly)
        allItems.push(this); else
        if (activeItem == null || activeItem.isException || activeItem.name == "Tutorial Trap") {
            activeItem != null ? allItems.unshift(activeItem) : null;
            activeItem = this;
        } else {
            allItems.push(this);
        }
    }

    public static function getItems():Array<APItem> {
        return allItems.getItems().copy();
    }

    public static function popup(desc:String, ?title:String, ?isWhite:Bool = false):Void {
        if (!APGameState.haventranyet) {
            archipelago.ArchPopup.startPopupCustom(title != null ? title : "AP Item!", desc, isWhite ? "archWhite" : "archColor", function() {
            FlxG.sound.playMusic(Paths.sound('secret'));});
        }
    }

    public function toString():String {
        return "APItem: " + this.name;
    }

    static var frozenInput:Int = 0;
    public static function createItemByName(name:String):APItem {
        switch (name) {
            case "Blue Balls Curse":
                return new APTrap(name, ConditionHelper.Everywhere(), function() {
                    // Check if shields are available
                    if (shields > 0) {
                        shields--;
                        popup('Shields left: $shields', "Death Avoided!", true);
                        return; // Do nothing else if shields are consumed
                    }

                    // Ensure we are in APPlayState
                    if (!Std.is(FlxG.state, archipelago.APPlayState)) {
                        // Switch to APPlayState if not already there
                        FlxG.switchState(new archipelago.APPlayState());
                    }

                    // Wait for PlayState's startedCountdown to become active
                    haxe.Timer.delay(function checkCountdown() {
                        var playState:archipelago.APPlayState = cast states.PlayState.instance;
                        if (playState != null && playState.startedCountdown) {
                            // Call the die() function once the countdown has started
                            // HOW AND WHY DOES THIS WORK THE WAY IT DOES???? - Yuta
                            // Welcome back old friend - Z11
                            backend.COD.COD.COD = "Killed by Blue Balls Curse.";
                            archipelago.APPlayState.deathByBlueBalls = true;
                            playState.die();
                        } else {
                            // Retry after a short delay if countdown hasn't started
                            haxe.Timer.delay(checkCountdown, 100);
                        }
                    }, 100);
                }, false, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });
            case "Fake Transition":
                return new APTrap(name, ConditionHelper.Special(), function() TransitionState.fakeTransition({transitionType:"transparent close"}), true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });
            case "Ticket":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    archipelago.APInfo.ticketCount++;
                    if (!archipelago.APGameState.instance.info().casualSync)
                    popup(archipelago.APInfo.ticketCount > archipelago.APInfo.ticketWinCount ? "Not that you needed it..." : archipelago.APInfo.ticketCount == archipelago.APInfo.ticketWinCount ? "You have all you need!" : "One step closer...", "You got a ticket!");
                }, true, true);
            case "SvC Effect":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('Effect: ${APPlayState.instance.effectArray[APPlayState.instance.curEffect]}', "APItem: SvC Effect", true);
                    APPlayState.instance.doEffect(APPlayState.instance.effectArray[APPlayState.instance.curEffect]);
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });
            case "Ghost Chat":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('May the chat be merciful on you...', "APItem: Ghost Chat", true);
                    APPlayState.instance.triggerGhostChat();
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });
            case "Pong Challenge":
                return new APTrap(name, ConditionHelper.Everywhere(), function() {
                    popup('Ok but can you beat the Pong Master?', "APItem: Pong Challenge", true);
                    if (MusicBeatState.getState() == APPlayState.instance) {
                        APPlayState.instance.paused = true;
                        APPlayState.instance.canResync = false;
                        FlxG.camera.followLerp = 0;
                        LoadingState.noteCache = [];
                        states.PlayState.curChart = [];
                        MusicBeatState.allowNuke = true;
                    }
                    FlxG.switchState(new archipelago.traps.games.APPongTrapState(MusicBeatState.getState()));
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });
            case "Math Problem Trap":
                return new APTrap(name, ConditionHelper.Everywhere(), function() {
                    // Initialize pending damage system if not already done
                    initializePendingDamageSystem();

                    // Generate random math problem
                    var num1 = FlxG.random.int(1, 20);
                    var num2 = FlxG.random.int(1, 20);
                    var operation = FlxG.random.getObject(['+', '-', '*']);
                    var correctAnswer:Int;
                    var problemText:String;

                    switch(operation) {
                        case '+':
                            correctAnswer = num1 + num2;
                            problemText = '$num1 + $num2 = ?';
                        case '-':
                            correctAnswer = num1 - num2;
                            problemText = '$num1 - $num2 = ?';
                        case '*':
                            correctAnswer = num1 * num2;
                            problemText = '$num1 × $num2 = ?';
                        default:
                            correctAnswer = num1 + num2;
                            problemText = '$num1 + $num2 = ?';
                    }

                    popup('Solve this math problem or take damage!', 'Math Problem Trap');

                    // Create and open math problem substate
                    var mathSubstate = new APMathProblemSubstate(problemText, correctAnswer, function(success:Bool) {
                        if (!success) {
                            // Add pending damage that will be applied later
                            var damageAmount = FlxG.random.float(0.2, 0.8); // Random damage between 0.2-0.8
                            pendingDamage += damageAmount;
                            popup('Wrong answer! You will take ${Math.round(damageAmount * 100)/100} damage.', 'Math Problem Failed!');
                        } else {
                            popup('Correct! No damage taken.', 'Math Problem Solved!');
                        }
                        // Apply pending damage will be handled automatically by the update system
                    });

                    states.PlayState.instance.canPause = false;
                    FlxG.state.openSubState(mathSubstate);
                }, true, false).funcAndReturn(function(t:APItem) {
                    t.isTrap = true;
                });
            case "UNO Challenge":
                return new APTrap(name, ConditionHelper.Everywhere().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return archipelago.APInfo.inMinigame == archipelago.APInfo.APMinigame.None;
                    });
                }), function() {
                    popup('Win the round to survive!', "APItem: UNO Challenge", true);
                    if (MusicBeatState.getState() == APPlayState.instance) {
                        APPlayState.instance.paused = true;
                        APPlayState.instance.canResync = false;
                        FlxG.camera.followLerp = 0;
                        LoadingState.noteCache = [];
                        states.PlayState.curChart = [];
                        MusicBeatState.allowNuke = true;
                        archipelago.APInfo.inMinigame = archipelago.APInfo.APMinigame.Uno;
                    }
                    FlxG.switchState(new archipelago.traps.games.APUnoTrapState(MusicBeatState.getState()));
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });
            case "Shield":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    shields++;
                    trace("Shield acquired! Current shields: " + shields);
                    popup('Shields Left: $shields', "You got a shield!");
                }, true, true);
            case "Max HP Up":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    maxHPUp++;
                    trace("Max HP increased! Current max HP: " + maxHPUp);
                    popup('Current Max HP: +$maxHPUp', "You got a max HP up!");
                    if (APPlayState.APInstance() != null) {
                        APPlayState.APInstance().MaxHP += 0.5;
                    }
                }, true, true);
            case 'Max HP Down':
                return new APTrap(name, ConditionHelper.Everywhere(), function() {
                    maxHPUp--;
                    trace("Max HP decreased! Current max HP: " + maxHPUp);
                    popup('Current Max HP: +$maxHPUp', "You lost Max HP!");
                    if (APPlayState.APInstance() != null) {
                        APPlayState.APInstance().MaxHP = APPlayState.APInstance().MaxHP - 0.5;
                        if (APPlayState.APInstance().health > APPlayState.APInstance().MaxHP) {
                            APPlayState.APInstance().health = APPlayState.APInstance().MaxHP;
                        }
                    }
                }, true, true).funcAndReturn(function(t:APItem) {
                    t.isTrap = true;
                });
            case "Extra Life":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    APPlayState.livecount++;
                    if (APPlayState.APInstance() != null) {
                        states.PlayState.instance.lives = archipelago.APPlayState.livecount+1;
                        if (APPlayState.livecount > 1) {
                            states.PlayState.instance.hearts.visible = true;
                            states.PlayState.instance.hearts.clear();
                            for (i in 1...states.PlayState.instance.lives)
                            {
                                var heartSprite:FlxSprite = new FlxSprite(states.PlayState.instance.healthBar.width + 5 + (40 * i), 20);
                                heartSprite.frames = Paths.getSparrowAtlas('mechanics/general/heartUI');
                                heartSprite.antialiasing = false;
                                heartSprite.updateHitbox();
                                heartSprite.y = states.PlayState.instance.healthBar.y + states.PlayState.instance.healthBar.height + 10;
                                heartSprite.scrollFactor.set();
                                heartSprite.animation.addByPrefix('Idle', "Hearts", 24, true);
                                heartSprite.ID = i;
                                if (ClientPrefs.data.downScroll)
                                    heartSprite.y = states.PlayState.instance.healthBar.y - heartSprite.height - 10;
                                heartSprite.animation.play('Idle');
                                states.PlayState.instance.hearts.add(heartSprite);
                            }
                        }
                    }
                    trace("Extra life acquired! Current extra lives: " + APPlayState.livecount);
                    popup('Extra Lives Left: ${APPlayState.livecount}', "You got an extra life!");
                }, true, true);
            case "Tutorial Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    // Wait for PlayState's startedCountdown to become active
                    haxe.Timer.delay(function checkCountdown() {
                        var playState:archipelago.APPlayState = cast states.PlayState.instance;
                        if (playState != null && playState.startedCountdown) {
                            popup('Go relearn the basics', "APItem: Tutorial Trap");
                            APPlayState.instance.doEffect('songSwitch');
                            if (APItem.activeItem !=null)
                                allItems.push(APItem.activeItem);
                            activeItem = new APTrap("Tutorial Trap", ConditionHelper.PlayState(), function() {
                                popup('Go relearn the basics', "APItem: Tutorial Trap");
                                APPlayState.instance.doEffect('songSwitch');
                                APPlayState.instance.playfields.forEach(function(pf) {
                                    pf.autoPlayed = true;
                                });
                            }, false, false, true);
                        } else {
                            // Retry after a short delay if countdown hasn't started
                            haxe.Timer.delay(checkCountdown, 100);
                        }
                    }, 100);
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });
            case "Chart Modifier Trap":
                return new APChartModifier().funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Pocket Lens":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    hasPocketLens = true;
                    trace("Pocket Lens acquired! Player can now view AP items.");
                    popup('You can now view your AP items and stats!', "You got a Pocket Lens!");

                    // If currently in APCategoryState, reset it to refresh with new data
                    if (Std.is(FlxG.state, archipelago.APCategoryState)) {
                        FlxG.resetState();
                    }
                }, true, true);

            case "PONG Dash Mechanic":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    trace("PONG Dash Mechanic acquired! You can now dash in pong :)");
                    popup('You can now dash in pong!', "You got the Dash Mechanic!");
                    hasDashMechanic = true;
                }, true, true);

            case "UNO Color Filler":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    popup('You got an UNO color!', "You got an UNO Color Filler!");
                    // Get a random color from APInfo's SlotData that isn't already unlocked.
                    var availableColors = APInfo.slotData.unoColorsUsed.filter(function(c) {
                        return !unoColorsUnlocked.arrayContainsObject(c);
                    });
                    if (availableColors.length > 0) {
                        var color = FlxG.random.getObject(availableColors);
                        unoColorsUnlocked.push(color);
                        popup('You got the color ${color.name}!', "You got an UNO Color!");
                        trace('UNO Color acquired: ${color.name} (${color.color_code})');
                    } else {
                        popup('You already have all available colors!', "UNO Color Filler");
                    }

                }, true, true);

            case "Song Switch Trap":
                return new APItem(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true && FlxG.save.data.manualOverride == false;
                    });
                }), function() {
                    popup('I don\'t like this song. Lets play something else.', "APItem: Song Switch Trap", true);
                    /*if (FlxG.random.bool(50)) {
                        trace('MANUAL OVERRIDE: ' + FlxG.save.data.manualOverride);

                    } else {
                        trace('MANUAL OVERRIDE: ' + FlxG.save.data.manualOverride);
                        if (!FlxG.save.data.manualOverride) {
                            FlxG.save.data.manualOverride = true;
                            FlxG.save.data.storyWeek = states.PlayState.storyWeek;
                            FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
                            FlxG.save.data.difficulties = Difficulty.list; // just in case
                            FlxG.save.data.SONG = states.PlayState.SONG;
                            FlxG.save.data.storyDifficulty = states.PlayState.storyDifficulty;
                            FlxG.save.data.songPos = FlxG.sound.music.time;
                            FlxG.save.flush();

                            var freeplayState = cast FreeplayManager.getFreeplay();
                            var theManager = freeplayState.instance.fpManager;
                            var pickedSong = FlxG.random.int(0, Std.int(theManager.songList.length-1));
                            var song = theManager.songList[pickedSong];
                            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[song.week]);
                            Mods.currentModDirectory = song.folder;
                            states.PlayState.storyWeek = song.week;
                            Difficulty.loadFromWeek(leWeek);
                            MusicBeatState.switchSong(song.songName, Difficulty.list.length, "FlxG");
                        }
                    }*/
                    if (!FlxG.save.data.manualOverride) {
                        FlxG.save.data.manualOverride = true;
                        FlxG.save.data.storyWeek = states.PlayState.storyWeek;
                        FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
                        FlxG.save.data.difficulties = Difficulty.list; // just in case
                        FlxG.save.data.SONG = states.PlayState.SONG;
                        FlxG.save.data.storyDifficulty = states.PlayState.storyDifficulty;
                        FlxG.save.data.songPos = FlxG.sound.music.time;
                        FlxG.save.flush();

                        var specialSongList = ['Rise', 'Zeventeen', /*'Pack-A-Punch', 'Driller',*/ 'Test Field', 'Rawr', /*'Fightback',*/ 'Funky Fanta', /*'Tag And Seek', 'Testimony', 'Fangirl Frenzy', 'Slowdown'*/];
                        var curSong = FlxG.random.int(0, specialSongList.length-1);
                        switch (specialSongList[curSong])
                        {
                            case 'Small Argument' | 'Beat Battle 2' | 'GeoStar' | 'Zeventeen' | 'Tag And Seek' | 'Rawr':
                                Difficulty.list = ['Hard'];
                            case 'Rise' | 'Test Field':
                                Difficulty.list = ['Normal'];
                            case "Beat Battle":
                                Difficulty.list = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
                            default:
                                Difficulty.list = Difficulty.defaultList.copy();
                        }
                        states.PlayState.SONG = backend.Song.loadFromJson(backend.Highscore.formatSong(specialSongList[curSong], Difficulty.list.length-1), Paths.formatToSongPath(specialSongList[curSong]));
                        states.PlayState.storyWeek = -1;
                        Mods.currentModDirectory = '';
                        states.PlayState.storyDifficulty = Difficulty.list.length-1;

                        if (Std.is(FlxG.state, APPlayState)) {
                            MusicBeatState.resetState();
                        } else {
                            FlxG.switchState(new APPlayState());
                        }
                    }
                }, true, true);

            case "Opponent Mode Trap":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('Freaky Friday! Now YOU\'RE the opponent!', 'Opponent Mode Trap');
                    states.PlayState.instance.opponentmode = true;
                    states.PlayState.instance.playerField.isPlayer = !states.PlayState.instance.opponentmode && !states.PlayState.playAsGF || states.PlayState.instance.bothMode;
                    states.PlayState.instance.playerField.autoPlayed = states.PlayState.instance.opponentmode || states.PlayState.instance.cpuControlled || states.PlayState.playAsGF;
                    states.PlayState.instance.playerField.noteHitCallback = states.PlayState.instance.opponentmode ? states.PlayState.instance.opponentNoteHit : states.PlayState.instance.goodNoteHit;
                    states.PlayState.instance.dadField.isPlayer = states.PlayState.instance.opponentmode && !states.PlayState.playAsGF || states.PlayState.instance.bothMode;
                    states.PlayState.instance.dadField.autoPlayed = (!states.PlayState.instance.opponentmode || (states.PlayState.instance.opponentmode && states.PlayState.instance.cpuControlled) || states.PlayState.playAsGF) || states.PlayState.instance.bothMode && states.PlayState.instance.cpuControlled;
                    states.PlayState.instance.dadField.noteHitCallback = states.PlayState.instance.opponentmode ? states.PlayState.instance.goodNoteHit : states.PlayState.instance.opponentNoteHit;
                    FlxG.sound.play(Paths.sound("streamervschat/randomize"), 1);
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Both Play Trap":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('Ever wanted to play both strums at once?\nNow you have to!', 'Both Play Trap');
                    states.PlayState.instance.bothMode = true;
                    states.PlayState.instance.playerField.isPlayer = !states.PlayState.instance.opponentmode && !states.PlayState.playAsGF || states.PlayState.instance.bothMode;
                    states.PlayState.instance.playerField.autoPlayed = states.PlayState.instance.opponentmode || states.PlayState.instance.cpuControlled || states.PlayState.playAsGF;
                    states.PlayState.instance.playerField.noteHitCallback = states.PlayState.instance.opponentmode ? states.PlayState.instance.opponentNoteHit : states.PlayState.instance.goodNoteHit;
                    states.PlayState.instance.dadField.isPlayer = states.PlayState.instance.opponentmode && !states.PlayState.playAsGF || states.PlayState.instance.bothMode;
                    states.PlayState.instance.dadField.autoPlayed = (!states.PlayState.instance.opponentmode || (states.PlayState.instance.opponentmode && states.PlayState.instance.cpuControlled) || states.PlayState.playAsGF) || states.PlayState.instance.bothMode && states.PlayState.instance.cpuControlled;
                    states.PlayState.instance.dadField.noteHitCallback = states.PlayState.instance.opponentmode ? states.PlayState.instance.goodNoteHit : states.PlayState.instance.opponentNoteHit;
                    FlxG.sound.play(Paths.sound("streamervschat/randomize"), 1);
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Resistance Trap":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('Oh god no here she comes', "Resistance Trap", true);
                    APPlayState.instance.startResisting();
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Nothing":
                popup('...For now...', "APItem: Nothing");
                return null;

            case "Ghost":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    states.PlayState.instance?.modManager.setValue('sudden', 1);
                    popup('Suddenly, Notes.', "TrapLink: Ghost Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "My Turn! Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    APPlayState.instance.bothMode = true;
                    APPlayState.instance.playerField.isPlayer = APPlayState.instance.bothMode;
                    APPlayState.instance.playerField.autoPlayed = false;
                    APPlayState.instance.playerField.noteHitCallback = APPlayState.instance.goodNoteHit;
                    APPlayState.instance.dadField.isPlayer = APPlayState.instance.bothMode;
                    APPlayState.instance.dadField.autoPlayed = false;
                    APPlayState.instance.dadField.noteHitCallback = APPlayState.instance.opponentNoteHit;
                    popup('Now you have to play BOTH sides!', "TrapLink: My Turn! Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Paralyze Trap":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {

                    APPlayState.instance.boyfriend.stunned = true;
                    new FlxTimer().start(FlxG.random.int(2, 5), function(tmr:FlxTimer)
                    {
                        APPlayState.instance.boyfriend.stunned = false;
                    });
                    popup('You\'ve been Paralyzed!', "TrapLink: Paralyze Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Phone Trap" | "Literature Trap":
                return new APTrap(name, ConditionHelper.Everywhere(), function() {
                    APPlayState.instance.inCutscene = true;
                    APPlayState.instance.pausePlayState();
                    backend.MusicBeatState.revokeControls = (name == 'Phone Trap');
                    var psychDialogue:DialogueBoxPsych;
                    psychDialogue = new DialogueBoxPsych(DialogueBoxPsych.parseDialogue(Paths.json('apthings/dialogue/' + FlxG.random.int(0, 10))));
                    psychDialogue.scrollFactor.set();
                    psychDialogue.autoScroller = (name == 'Phone Trap');
                    psychDialogue.finishThing = function() {
                        APPlayState.instance.resumePlayState();
                        APPlayState.instance.inCutscene = false;
                        backend.MusicBeatState.revokeControls = false;
                        FlxG.state.remove(psychDialogue);
                        psychDialogue = null;
                    }
                    FlxG.state.add(psychDialogue);
                    popup('I hope you like reading...', 'TrapLink: $name');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Home Trap": //Literally just Tutorial Trap
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    // Wait for PlayState's startedCountdown to become active
                    haxe.Timer.delay(function checkCountdown() {
                        var playState:archipelago.APPlayState = cast states.PlayState.instance;
                        if (playState != null && playState.startedCountdown) {
                            popup('Go relearn the basics', "TrapLink: Home Trap");
                            APPlayState.instance.doEffect('songSwitch');
                            if (APItem.activeItem !=null)
                                allItems.push(APItem.activeItem);
                            activeItem = new APTrap("Tutorial Trap", ConditionHelper.PlayState(), function() {
                                popup('Go relearn the basics', "TrapLink: Home Trap");
                                APPlayState.instance.doEffect('songSwitch');
                                APPlayState.instance.playfields.forEach(function(pf) {
                                    pf.autoPlayed = true;
                                    pf.inControl = false;
                                });
                            }, false, false, true);
                        } else {
                            // Retry after a short delay if countdown hasn't started
                            haxe.Timer.delay(checkCountdown, 100);
                        }
                    }, 100);
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case 'Ice Trap':
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('Effect: Ice Notes', "TrapLink: Ice Trap", true);
                    APPlayState.instance.doEffect('icebutmoreagressive');
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Freeze Trap" | "Frozen Trap" | "Bubble Trap":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('You\'re Frozen Solid!', 'TrapLink: $name', true);
                    FlxG.sound.play(Paths.sound('streamervschat/freeze'));
                    frozenInput++;
                    for (sprite in APPlayState.instance.playerField.strumNotes)
                    {
                        sprite.color = 0x0073b5;
                    };
                    APPlayState.instance.boyfriend.color = 0x0073b5;
                    APPlayState.instance.isFrozen = true;
                    new FlxTimer().start(2, function(timer)
                    {
                        frozenInput--;
                        if (frozenInput <= 0)
                        {
                            for (sprite in APPlayState.instance.playerField.strumNotes)
                            {
                                sprite.color = 0xffffff;
                            };
                            APPlayState.instance.boyfriend.color = 0xffffff;
                            APPlayState.instance.isFrozen = false;
                            APPlayState.instance.boyfriend.stunned = false;
                        }
                        FlxDestroyUtil.destroy(timer);
                    });
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

                //Spawns a huge amount of notes randomly
            case "Army Trap" | "Police Trap" | "Buyon Trap" | "OmoTrap":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    APPlayState.instance.doEffect('insanespam');
                    popup('WATCH OUT!', 'TrapLink: $name');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Damage Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    var okayden:Array<Int> = [];
                    for (i in 0...64) {
                        okayden.push(i);
                    }

                    if (FlxG.random.bool(18)) {
                        var explosion = new FlxSprite().loadGraphic(Paths.image("streamervschat/explosion"), true, 256, 256);
                        explosion.animation.add("boom", okayden, 60, false);
                        explosion.animation.finishCallback = function(name) {
                            explosion.visible = false;
                            APPlayState.instance.remove(explosion);
                            explosion.kill();
                        };
                        //explosion.cameras = [APPlayState.instance.camHUD];
                        explosion.animation.play("boom", true);
                        explosion.x = APPlayState.instance.boyfriend.x + APPlayState.instance.boyfriend.width / 2 - explosion.width / 2;
                        explosion.y = APPlayState.instance.boyfriend.y + APPlayState.instance.boyfriend.height / 2 - explosion.height / 2;
                        APPlayState.instance.add(explosion);
                        APPlayState.instance.boyfriend.animation.play('hurt', true);
                        APPlayState.instance.boyfriend.specialAnim = true;
                    } else {
                        var explosion = new FlxSprite().loadGraphic(Paths.image("streamervschat/explosion"), true, 256, 256);
                        explosion.animation.add("boom", okayden, 60, false);
                        explosion.animation.finishCallback = function(name) {
                            explosion.visible = false;
                            APPlayState.instance.remove(explosion);
                            explosion.kill();
                        };
                        explosion.setGraphicSize(Std.int(explosion.width * 5));
                        //explosion.cameras = [APPlayState.instance.camHUD];
                        explosion.animation.play("boom", true);
                        explosion.x = APPlayState.instance.boyfriend.x + APPlayState.instance.boyfriend.width / 2 - explosion.width / 2;
                        explosion.y = APPlayState.instance.boyfriend.y + APPlayState.instance.boyfriend.height / 2 - explosion.height / 2;
                        APPlayState.instance.add(explosion);
                        APPlayState.instance.boyfriend.animation.play('hurt', true);
                        APPlayState.instance.boyfriend.specialAnim = true;
                        APPlayState.instance.health -= 0.4;
                    }
                    popup('That looked like it hurt', "TrapLink: Damage Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Chaos Control Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    APPlayState.instance.doEffect('freeze');
                    popup('CHAOS! CONTROL!', "TrapLink: Chaos Control Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Confuse Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    APPlayState.instance.doEffect('cover');
                    popup('What\'s going on here?', "TrapLink: Confuse Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Eject Ability":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    APPlayState.instance.doEffect('permasever');
                    popup('Eh, you weren\'t using that strum anyways.', "TrapLink: Eject Ability");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Test if this works
            case "Deisometric Trap" | "Camera Rotate Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('Can you tilt your screen? I can\'t see...', 'TrapLink: $name');
                    var pers:shaders.PerspectiveShader;
                    pers = new shaders.PerspectiveShader();
                    for (cam in FlxG.cameras.list)
                        cam.filters = [new ShaderFilter(pers)];
                    flixel.tweens.FlxTween.num(pers.xrot, 0.45, 1, function(value:Float) {
                        pers.xrot = value;
                    });
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Test if this works
            case "Push Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('You go bye bye now :)', "TrapLink: Push Trap");
                    TrapLinkFunctions.bfPosition = [APPlayState.instance.boyfriend.x ,APPlayState.instance.boyfriend.y];
                    TrapLinkFunctions.doCarCrash(true);
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Whoops! Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    APPlayState.instance.bfAscend = true;
                    popup('ooo whats this button do?', "TrapLink: Whoops! Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Test if this works
            case "Input Sequence Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('Imma hit you with a QTE just cause.', "TrapLink: Input Sequence Trap");
                    TrapLinkFunctions.doBushwakThings();
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Pokemon Trivia Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('What is the following word:', "TrapLink: Pokemon Trivia Trap");
                    TrapLinkFunctions.startUnown();
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Make the note hit bf after hitting it and stun him for 2 seconds
            case "Thwimp Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    // popup('Hey that note looks loose', "TrapLink: Thwimp Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Make the notes play in-game, and make BF and his notes tiny
            case "Tiny Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('Aww, he\'s so small', "TrapLink: Tiny Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Zoom Trap":
                return new APTrap(name, ConditionHelper.Special(), function() {
                    popup('ZOOM!', "TrapLink: Zoom Trap");
                    for (cam in FlxG.cameras.list) {
                        cam.zoom += 5;
                    } // 3 seconds.
                    new FlxTimer().start(3, function(timer:FlxTimer) {
                        for (cam in FlxG.cameras.list) {
                            cam.zoom -= 5;
                        }
                        FlxDestroyUtil.destroy(timer);
                    });
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            // case "Fake Loading Bar":
            //     return new APTrap(name, ConditionHelper.Everywhere(), function() {
            //         popup('Preparing nonsense...', "TrapLink: Fake Loading Bar");

            //         // Array of ridiculous fake loading tasks
            //         var absurdTasks:Array<String> = [
            //             "Calibrating funk levels",
            //             "Downloading more RAM",
            //             "Teaching notes to dance",
            //             "Optimizing boyfriend's microphone",
            //             "Buffering dad's disapproval",
            //             "Loading girlfriend's attention span",
            //             "Synchronizing arrow keys with reality",
            //             "Defragmenting chart difficulty",
            //             "Installing better singing voice",
            //             "Updating boyfriend's confidence",
            //             "Compiling sick beats",
            //             "Initializing rhythm sensors",
            //             "Calculating perfect combo multiplier",
            //             "Loading next week's drama",
            //             "Preparing speakers for maximum volume",
            //             "Organizing note colors by importance",
            //             "Training AI to miss intentionally",
            //             "Downloading girlfriend's patience",
            //             "Calibrating dad's anger levels",
            //             "Loading backstory nobody asked for",
            //             "Optimizing funky fresh algorithms",
            //             "Buffering epic guitar solos",
            //             "Installing anti-lag lag",
            //             "Synchronizing beats with heartbeat",
            //             "Preparing for inevitable game over"
            //         ];

            //         // Randomly select 3-7 absurd tasks
            //         var numTasks = FlxG.random.int(3, 7);
            //         var selectedTasks:Array<String> = [];

            //         for (i in 0...numTasks) {
            //             var randomTask = FlxG.random.getObject(absurdTasks);
            //             selectedTasks.push(randomTask);
            //             absurdTasks.remove(randomTask);
            //         }

            //         // Create fake progress tasks with the correct structure
            //         var progressTasks:Array<yutautil.GenericProgressSubstate.ProgressTask> = [];
            //         for (task in selectedTasks) {
            //             progressTasks.push({
            //                 name: task,
            //                 func: function(args:Array<Dynamic>):Dynamic {
            //                     // Do absolutely nothing productive
            //                     trace('Fake loading: $task');
            //                     // Simulate some "work" with a random delay
            //                     haxe.Timer.delay(function() {
            //                         trace('Fake task completed: $task');
            //                     }, Std.int(FlxG.random.float(500, 2000)));
            //                     return null;
            //                 },
            //                 throwOnError: false
            //             });
            //         }

            //         // Add a final "completion" task
            //         progressTasks.push({
            //             name: "Realizing this was all pointless",
            //             func: function(args:Array<Dynamic>):Dynamic {
            //                 trace("Fake loading complete - accomplished absolutely nothing!");
            //                 return null;
            //             },
            //             throwOnError: false
            //         });

            //         // Show the fake loading dialog with the correct constructor
            //         var progressSubstate = new GenericProgressSubstate(
            //             "System Update Required",
            //             progressTasks,
            //             function(results:Array<Dynamic>) {
            //                 // On completion - show another popup about the meaningless process
            //                 haxe.Timer.delay(function() {
            //                     popup('Update complete! Nothing changed.', "System Update");
            //                 }, 100);
            //             }
            //         );

            //         FlxG.state.openSubState(progressSubstate);
            //     }, true, true).funcAndReturn(function(t:APItem) {
            //         // Set it as a trap.
            //         t.isTrap = true;
            //     });

            //TODO: Make an image of a speaker fly and hit bf
            case "Bonk Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('WATCH OUT!', "TrapLink: Bonk Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Make bf bald
            case "Bald Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('BALD. BALD. BALD. BALD.', "TrapLink: Bald Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Grab the QT Mania Saws
            case "Bomb" | "TNT Barrel Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('WATCH OUT!', 'TrapLink: $name');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Move the strums the direction the note is hit
            case "Controller Drift Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('Bro I think there\'s something wrong with your strums', 'TrapLink: Controller Drift Trap');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: This converts into the Resistance Trap
            case "Timer Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('YOU MUST RESIST IT', 'TrapLink: Timer Trap');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Test this
            case "Jump Trap" | "Spring Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('Don\'t break your neck...', 'TrapLink: $name');
                    var tramp:Trampoline = new Trampoline();
                    if (APPlayState.instance != null) APPlayState.instance.addBehindBF(tramp);
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Posession Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    APPlayState.instance.opponentmode = true;
                    APPlayState.instance.playerField.isPlayer = !APPlayState.instance.opponentmode;
                    APPlayState.instance.playerField.autoPlayed = APPlayState.instance.opponentmode;
                    APPlayState.instance.playerField.noteHitCallback = APPlayState.instance.opponentmode ? APPlayState.instance.opponentNoteHit : APPlayState.instance.goodNoteHit;
                    APPlayState.instance.dadField.isPlayer = APPlayState.instance.opponentmode;
                    APPlayState.instance.dadField.autoPlayed = !APPlayState.instance.opponentmode;
                    APPlayState.instance.dadField.noteHitCallback = APPlayState.instance.opponentmode ? APPlayState.instance.goodNoteHit : APPlayState.instance.opponentNoteHit;
                    popup('You\'re the opponent now!', 'TrapLink: Posession Trap');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: converts into a less limited Song Switch Trap
            case "Animal Bonus Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('We\'re gonna go someplace SPECIAL!', 'TrapLink: Animal Bonus Trap');
                    var specialSongList = ['Rise', 'Zeventeen', /*'Pack-A-Punch', 'Driller',*/ 'Test Field', 'Rawr', /*'Fightback',*/ 'Funky Fanta', /*'Tag And Seek', 'Testimony', 'Fangirl Frenzy', 'Slowdown'*/];
                    FlxTween.num(APPlayState.instance.playbackRate, 0, 0.5, {
                        onComplete: function(e) {
                            APPlayState.instance.paused = false;
                            FlxG.sound.play(Paths.sound('streamervschat/itcomes'), 1, false, null, true, function() {
                                trace('MANUAL OVERRIDE: ' + FlxG.save.data.manualOverride);
                                if (!FlxG.save.data.manualOverride) {
                                    FlxG.save.data.manualOverride = true;
                                    FlxG.save.data.storyWeek = states.PlayState.storyWeek;
                                    FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
                                    FlxG.save.data.difficulties = Difficulty.list; // just in case
                                    FlxG.save.data.SONG = states.PlayState.SONG;
                                    FlxG.save.data.storyDifficulty = states.PlayState.storyDifficulty;
                                    FlxG.save.data.songPos = FlxG.sound.music.time;
                                    FlxG.save.flush();

                                    var curSong = FlxG.random.int(0, specialSongList.length-1);
                                    switch (specialSongList[curSong])
                                    {
                                        case 'Small Argument' | 'Beat Battle 2' | 'GeoStar' | 'Zeventeen' | 'Tag And Seek' | 'Rawr':
                                            Difficulty.list = ['Hard'];
                                        case 'Rise' | 'Test Field':
                                            Difficulty.list = ['Normal'];
                                        case "Beat Battle":
                                            Difficulty.list = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
                                        default:
                                            Difficulty.list = Difficulty.defaultList.copy();
                                    }
                                    states.PlayState.SONG = backend.Song.loadFromJson(backend.Highscore.formatSong(specialSongList[curSong], Difficulty.list.length-1), Paths.formatToSongPath(specialSongList[curSong]));
                                    states.PlayState.storyWeek = -1;
                                    Mods.currentModDirectory = '';
                                    states.PlayState.storyDifficulty = Difficulty.list.length-1;

                                    if (Std.is(FlxG.state, APPlayState)) {
                                        MusicBeatState.resetState();
                                    } else {
                                        FlxG.switchState(new APPlayState());
                                    }
                                }
                            });
                        }
                    }, function(t) {
                        APPlayState.instance.playbackRate = t;
                    });
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: make the player randomly miss with a hiccup sound effect
            case "Hiccup Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('Someone\'s got a bad case of hiccups!', 'TrapLink: Hiccup Trap');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: make the opponent stums use a different set of keybinds from the normal ones
            case "Gooey Bag":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    APPlayState.instance.opponentmode = true;
                    APPlayState.instance.playerField.isPlayer = !APPlayState.instance.opponentmode;
                    APPlayState.instance.playerField.autoPlayed = APPlayState.instance.opponentmode;
                    APPlayState.instance.playerField.noteHitCallback = APPlayState.instance.opponentmode ? APPlayState.instance.opponentNoteHit : APPlayState.instance.goodNoteHit;
                    APPlayState.instance.dadField.isPlayer = APPlayState.instance.opponentmode;
                    APPlayState.instance.dadField.autoPlayed = !APPlayState.instance.opponentmode;
                    APPlayState.instance.dadField.noteHitCallback = APPlayState.instance.opponentmode ? APPlayState.instance.goodNoteHit : APPlayState.instance.opponentNoteHit;
                    popup('Two-Player Mode Activated!', 'TrapLink: Gooey Bag');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: make the player dodge the TF2 Coconut or lose a chunk of HP
            case "Nut Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('Cocnut Attack!', 'TrapLink: Nut Trap');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: Grab the "Find Luigi" script. No i'm not kidding
            case "Pokemon Count Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('One Minute to Find Luigi!', 'TrapLink: Pokemon Count Trap');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Poison Trap" | "Poison Mushroom":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('Food Poisoning my beloved', 'TrapLink: Poison Trap');
                    APPlayState.instance.doEffect('poisonbutworse');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Confound Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('FLASHBANG OUT', 'TrapLink: Confound Trap');
                    APPlayState.instance.doEffect('strongflashbang');
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            //TODO: "And then, we FUCKED" -Boyfriend Fnf
            case "Exposition Trap":
                return new APTrap(name, ConditionHelper.Everywhere(), function() {
                    APPlayState.instance.inCutscene = true;
                    APPlayState.instance.paused = true;
                    backend.MusicBeatState.revokeControls = true;
                    var psychDialogue:DialogueBoxPsych;
                    psychDialogue = new DialogueBoxPsych(DialogueBoxPsych.parseDialogue(Paths.json('apthings/dialogue/bffunnymomments')));
                    psychDialogue.scrollFactor.set();
                    psychDialogue.autoScroller = true;
                    psychDialogue.autoScrollerTimer = 30;
                    psychDialogue.finishThing = function() {
                        APPlayState.instance.paused = false;
                        APPlayState.instance.inCutscene = false;
                        backend.MusicBeatState.revokeControls = false;
                        FlxG.state.remove(psychDialogue);
                        psychDialogue = null;
                    }
                    psychDialogue.screenCenter();
                    FlxG.state.add(psychDialogue);
                    popup('And then what happened?', "TrapLink: Exposition Trap");
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Fast Trap":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('GOTTA GO FAST!', 'TrapLink: Fast Trap');
                    APPlayState.instance.lerpSongSpeed(FlxG.random.float(1.25, 4), 1);
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Slow Trap" | "Slowness Trap":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('Slow down there, buddy', 'TrapLink: Slow Trap');
                    APPlayState.instance.lerpSongSpeed(FlxG.random.float(0.25, 0.75), 1);
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Double Damage":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('Double the damage! Double the fun!', 'TrapLink: Double Damage');
                    APPlayState.instance.healthLoss = 2;
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Instant Crystal Trap" | "One Hit KO":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('Be careful! You miss, you die!', 'TrapLink: $name');
                    APPlayState.instance.instakillOnMiss = true;
                    new FlxTimer().start(30, function(tmr:FlxTimer)
                    {
                        APPlayState.instance.instakillOnMiss = false;
                    });
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Mirror Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('A world from a different perspective.', 'TrapLink: Mirror Trap');
                    APPlayState.instance.camGame.flashSprite.scaleX *= -1;
		            APPlayState.instance.camHUD.flashSprite.scaleX *= -1;
                    new FlxTimer().start(30, function(tmr:FlxTimer)
                    {
                        APPlayState.instance.camGame.flashSprite.scaleX *= 1;
		                APPlayState.instance.camHUD.flashSprite.scaleX *= 1;
                    });
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Pixellation Trap":
                return new APTrap(name, ConditionHelper.PlayState(), function() {
                    popup('Man your Wifi SUCKS!', 'TrapLink: Pixellation Trap');
                    ClientPrefs.data.ultratrashMode = true;
                    // Clear all cached graphics when trash mode is toggled
                    // This ensures that the compression setting takes effect immediately
                    Paths.clearStoredMemory();
                    Paths.clearUnusedMemory();
                    Paths.freeGraphicsFromMemory();
                    trace('Graphics cleared due to Trash Mode toggle. New setting: ${ClientPrefs.data.trashMode}');
                    MusicBeatState.resetState();
                    new FlxTimer().start(120, function(tmr:FlxTimer)
                    {
                        ClientPrefs.data.ultratrashMode = false;
                        // Clear all cached graphics when trash mode is toggled
                        // This ensures that the compression setting takes effect immediately
                        Paths.clearStoredMemory();
                        Paths.clearUnusedMemory();
                        Paths.freeGraphicsFromMemory();
                        trace('Graphics cleared due to Trash Mode toggle. New setting: ${ClientPrefs.data.trashMode}');
                        MusicBeatState.resetState();
                    });
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Swap Trap":
                return new APTrap(name, ConditionHelper.PlayState().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return states.PlayState.instance?.startedSong == true;
                    });
                }), function() {
                    popup('I\'m bored. Play a different song.', 'TrapLink: Swap Trap');
                    if (!FlxG.save.data.manualOverride) {
                        FlxG.save.data.manualOverride = true;
                        FlxG.save.data.storyWeek = states.PlayState.storyWeek;
                        FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
                        FlxG.save.data.difficulties = Difficulty.list; // just in case
                        FlxG.save.data.SONG = states.PlayState.SONG;
                        FlxG.save.data.storyDifficulty = states.PlayState.storyDifficulty;
                        FlxG.save.data.songPos = FlxG.sound.music.time;
                        FlxG.save.flush();

                        var freeplayState = cast FreeplayManager.getFreeplay();
                        var theManager = freeplayState.instance.fpManager;
                        var pickedSong = FlxG.random.int(0, Std.int(theManager.songList.length-1));
                        var song = theManager.songList[pickedSong];
                        var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[song.week]);
                        Mods.currentModDirectory = song.folder;
                        states.PlayState.storyWeek = song.week;
                        Difficulty.loadFromWeek(leWeek);
                        MusicBeatState.switchSong(song.songName, Difficulty.list.length, "FlxG");
                    }
                }, true, true).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            case "Ultimate Confusion Trap":
                return new APTrap(name, ConditionHelper.Everywhere(), function() {
                    unknownSongs = true;
                    popup('Huh? Where am I?', "Ultimate Confusion Trap");

                    // Set a timer to revert after 5 minutes (300000 milliseconds)
                    haxe.Timer.delay(function() {
                        unknownSongs = false;
                        popup('The confusion has worn off!', "Clarity Restored");

                        // Reload freeplay to refresh the display
                        if (APEntryState.inArchipelagoMode) {
                            if (states.freeplay.FreeplayState.instance != null)
                                states.freeplay.FreeplayState.instance.reloadSongs(true);
                            if (states.freeplay.OsuFreeplayState.instance != null)
                                @:privateAccess states.freeplay.OsuFreeplayState.instance.loadSongArray(false);
                        }
                    }, 300000); // 5 minutes = 300000 milliseconds

                    // Reload freeplay immediately to show the confusion
                    if (APEntryState.inArchipelagoMode) {
                        if (states.freeplay.FreeplayState.instance != null)
                            states.freeplay.FreeplayState.instance.reloadSongs(true);
                        if (states.freeplay.OsuFreeplayState.instance != null)
                            @:privateAccess states.freeplay.OsuFreeplayState.instance.loadSongArray(false);
                    }
                }, true, false).funcAndReturn(function(t:APItem) {
                    // Set it as a trap.
                    t.isTrap = true;
                });

            default:
                throw "Unknown item name: " + name;
        }
    }

    public function trigger():Void {
        if (this.triggered) {
            return; // Prevent multiple triggers
        }

        // Ensure non-exception items wait until activeItem is null
        if (!this.isException && APItem.activeItem != null) {
            return; // Exit if activeItem is still in use
        }

        // Additional safety check for PlayState-specific items
        if (this.condition.type == ConditionType.PlayState && Std.is(FlxG.state, states.PlayState)) {
            var playState = states.PlayState.instance;
            if (playState != null && (playState.endingSong || playState.transitioning ||
                backend.TransitionState.currenttransition != null ||
                (playState.subState != null && Std.is(playState.subState, substates.RankingSubstate)))) {
                trace("Blocking item trigger due to inappropriate PlayState condition: " + this.name);
                return; // Don't trigger during song end, transitions, or ranking
            }
        }

        // Check conditions before triggering
        if (this.condition.checkFn(this) && APItem.allowedToTrigger) {
            if (this.condition.extraConditions != null) {
                for (extraCondition in this.condition.extraConditions) {
                    if (!extraCondition(this)) {
                        return; // Exit if any extra condition fails
                    }
                }
            }

            if (!this.isException)
            activeItem = this;
            allItems.remove(this); // Remove the item from the queue

            trace("Triggering item: " + this.name + "\n" + "Condition: " + this.condition.type + "\n" + "Triggered: " + this.triggered + "\n" + "Is Trap: " + this.isTrap + "\n" + "From Trap Link: " + this.fromTrapLink);

            // Trigger the item without removing it from the queue
            this.onTrigger();
            this.triggered = true;
            if (!this.fromTrapLink && (this.isTrap || this is APTrap) && ClientPrefs.data.traplink) {
                trace("Sending trap link for: " + this.name);
                this.sendTrapLink();
            }
        }
    }

    public function sendTrapLink():Void {
        if (this.isTrap && !this.fromTrapLink) {
            var trapName = this.name;
            if (this is APChartModifier) {
                trapName = "Chart Modifier Trap (" + cast (this, APChartModifier).chartModifier + ")";
            }
            trace("Sending trap link for: " + trapName);
            // Send the trap link to the server
            archipelago.APInfo.ap.Bounce({time: haxe.Timer.stamp(), source: archipelago.APInfo.ap.slot, trap_name: trapName}, null, null, ["TrapLink"]);
        }
    }

    public static function createItems():Void {
        // Initialize the pending damage system
        initializePendingDamageSystem();

        var itemNames:Array<String> = [
            "Blue Balls Curse",
            "Fake Transition",
            "Ticket",
            "SvC Effect",
            "Ghost Chat",
            "Shield",
            "Max HP Up",
            "Tutorial Trap",
            "Song Switch Trap",
            "Opponent Mode Trap",
            "Both Play Trap",
            "Resistance Trap",
            "UNO Challenge",
            "Pong Challenge",
            "Math Problem Trap",
            "Pocket Lens",
            "Nothing"
        ];
        for (name in itemNames) {
            createItemByName(name);
        }
    }

    public static function grabNewItems(items:Array<String>):Array<APItem> {
        var newItems:Array<APItem> = [];
        for (name in items) {
            newItems.push(createItemByName(name));
        }
        return newItems;
    }

    public static function createCustomItem(name:String, condition:Condition, onTrigger:Void->Void, isException:Bool = false):APItem {
        return new APItem(name, condition, onTrigger, isException);
    }

    public static function doCheck():Void {
        allItems.checkAndTrigger();
        applyPendingDamage();
    }
    public static function checkAndTrigger(items:Array<APItem>):Void {
        // Put the next item into the activeItems, if it isn't already filled by something.

        if (activeItem?.isException && activeItem?.triggered) {
            // If the active item is an exception and has been triggered, remove it from the list
            activeItem = null;
        }

        // trace(activeItem?.name + " is the active item.");

        activeItem?.trigger();

        if (activeItem == null) {
            for (item in items) {
                if (item != null) {
                    item.trigger();
                }
            }
        }
    }

    /**
     * Apply any pending damage to the player if conditions are met
     */
    public static function applyPendingDamage():Void {
        if (pendingDamage <= 0) return;

        // Check if we're in APPlayState and can apply damage
        if (Std.is(FlxG.state, archipelago.APPlayState)) {
            var playState = cast(FlxG.state, archipelago.APPlayState);
            if (playState != null && playState.startedCountdown && !playState.endingSong && !playState.paused) {
                // Check if shields are available
                if (shields > 0 && pendingDamage >= 0.15) { // Only use shields for significant damage
                    shields--;
                    popup('Shield absorbed ${Math.round(pendingDamage * 100)/100} damage! Shields left: $shields', "Shield Used!", true);
                    trace('Shield absorbed pending damage: $pendingDamage. Shields left: $shields');
                    pendingDamage = 0;
                    return;
                }

                // Apply the damage
                var oldHealth = playState.health;
                playState.health -= pendingDamage;
                trace('Applied pending damage: $pendingDamage. Health: $oldHealth -> ${playState.health}');

                // Visual feedback
                if (playState.boyfriend != null && pendingDamage > 0.1) {
                    playState.boyfriend.animation.play('hurt', true);
                    playState.boyfriend.specialAnim = true;
                }

                // Show damage popup if significant
                if (pendingDamage >= 0.1) {
                    popup('Took ${Math.round(pendingDamage * 100)/100} damage!', "Damage Applied!", true);
                }

                // Clear pending damage
                pendingDamage = 0;
            }
        }
    }

    /**
     * Initialize the pending damage system by adding it to APPlayState updateFunctions
     */
    public static function initializePendingDamageSystem():Void {
        // Check if already initialized to avoid duplicates
        var alreadyExists = false;
        for (func in archipelago.APPlayState.updateFunctions) {
            if (Reflect.compareMethods(func.func, applyPendingDamage)) {
                alreadyExists = true;
                break;
            }
        }

        if (!alreadyExists) {
            archipelago.APPlayState.updateFunctions.push({
                func: applyPendingDamage,
                keepOnRestart: true
            });
        }
    }

    /**
     * Comprehensive cleanup of all AP-related data and systems
     * Called when quitting AP mode to prevent issues with non-AP games
     */
    public static function cleanupAllAPData():Void {
        trace('APItem.cleanupAllAPData() - Starting comprehensive cleanup...');

        // Clear active items using an iter task for safety
        // Clear the activeItem reference
        activeItem = null;

        // Clear all items from the ActiveArray
        if (allItems != null) {
            var items = allItems.getItems();
            for (item in items) {
            if (item != null) {
                // Mark item as triggered to prevent any further actions
                item.triggered = true;
                // Clear the item's trigger function to prevent accidental calls
                item.onTrigger = function() {};
            }
            }
            // Clear the items array completely
            for (item in 0...allItems.getItems().length) {
                trace('Removing item from allItems: ' + allItems.pop());
            }
            allItems = new ActiveArray([]);
        }

        trace('Active items cleared successfully');
        // Reset all static variables to default values
        shields = 0;
        maxHPUp = 0;
        hasPocketLens = false;
        hasDashMechanic = false;
        overloadHP = 0;
        extaLives = 0;
        pendingDamage = 0.0;
        frozenInput = 0;
        unknownSongs = false;
        unoColorsUnlocked = [];

        // Clear inventory and item counts
        extraItemInventory = [];
        nonSongItemCounts.clear();

        // Clear APPlayState updateFunctions that contain APItem references
        try {
            if (archipelago.APPlayState.updateFunctions != null) {
                // Remove pending damage function and any other APItem-related functions
                var functionsToRemove = [];
                for (func in archipelago.APPlayState.updateFunctions) {
                    if (func != null && (Reflect.compareMethods(func.func, applyPendingDamage))) {
                        functionsToRemove.push(func);
                    }
                }

                for (func in functionsToRemove) {
                    archipelago.APPlayState.updateFunctions.remove(func);
                }
            }
        } catch (e) {
            trace('Error cleaning up APPlayState updateFunctions: $e');
        }

        // Clear any pending Pong trap queues
        try {
            APPongTrap.clearQueue();
        } catch (e) {
            trace('Error clearing Pong trap queue: $e');
        }

        // Reset April Fools state
        try {
            // Use reflection to access private static variables if needed
            var aprilFoolsClass = Type.resolveClass('archipelago.APItem.APrilFools');
            if (aprilFoolsClass != null) {
                // Reset static variables via reflection if accessible
                Reflect.setField(aprilFoolsClass, 'initialized', false);
                if (Reflect.hasField(aprilFoolsClass, 'options')) {
                    var options = Reflect.field(aprilFoolsClass, 'options');
                    if (options != null && Reflect.hasField(options, 'clear')) {
                        Reflect.callMethod(options, Reflect.field(options, 'clear'), []);
                    }
                }
            }
        } catch (e) {
            trace('Error cleaning up April Fools data: $e');
        }

        // Put Chart Modifier back to normal
        try {
            ClientPrefs.data.gameplaySettings.set("chartModifier", "None");
            ClientPrefs.data.gameplaySettings.set("convertMania", 4-1);
        } catch (e) {
            trace('Error resetting Chart Modifier: $e');
        }

        trace('APItem comprehensive cleanup completed');
    }

}

class APChartModifier extends APTrap {
    public var chartModifier:String;

    public function new(?chartModifier:String) {
        var modifiers = chartModifier != null ? [chartModifier] : ["Random", "RandomBasic", "RandomComplex", "Flip", "Pain", "ManiaConverter", "Stairs", "Wave", "Trills", "Amalgam"];
        if (yutautil.AprilFools.allowAF) {
            modifiers.push("SpeedRando");
        }

        this.chartModifier = modifiers[Std.random(modifiers.length)];
        this.chartModifier = (this.chartModifier == "ManiaConverter" &&
            ((states.PlayState.mania > 3) ||
             (states.PlayState.SONG != null && states.PlayState.SONG.mania != null && states.PlayState.SONG.mania > 3)))
            ? "4K Only" : this.chartModifier;

        super("Chart Modifier Trap (" + this.chartModifier + ")", ConditionHelper.PlayState(), function() {
            ClientPrefs.data.gameplaySettings.set("chartModifier", this.chartModifier);
            if (this.chartModifier == 'ManiaConverter') // Random between 4 and 8.
                ClientPrefs.data.gameplaySettings.set("convertMania", 4 + Std.random(5));
            APItem.popup("Chart Modifier Trap (" + this.chartModifier + ")");
            if (archipelago.APPlayState.instance?.startingSong) {
                MusicBeatState.switchState(new states.PlayState()); // Don't ask why I had to do this. - Yuta
            }
        }, false, false);
    }

    public static function restoreFromSave(modifier:String):APChartModifier {
        return new APChartModifier(modifier);
    }
}

class APPongTrap extends APTrap {
    public var difficulty:Int; // 1-5, higher = harder
    private static var activeTrapState:archipelago.traps.games.APPongTrapState = null;
    private static var difficultyQueue:Array<Int> = [];

    public function new(?difficulty:Int = null) {
        // If no difficulty specified, use random 1-3 (reasonable range)
        this.difficulty = difficulty != null ? difficulty : (1 + Std.random(3));

        super("Pong Challenge (" + getDifficultyName(this.difficulty) + ")", ConditionHelper.Everywhere().funcAndReturn(function(c) {
                    c.extraConditions = [];
                    c.extraConditions.push(function(e) {
                        return archipelago.APInfo.inMinigame == archipelago.APInfo.APMinigame.None;
                    });
                }), function() {
            // If already in a pong trap, queue this difficulty
            if (activeTrapState != null) {
                difficultyQueue.push(this.difficulty);
                APItem.popup("Pong Challenge (" + getDifficultyName(this.difficulty) + ") queued! " + difficultyQueue.length + " in queue.");
                return;
            }

            // Launch the pong trap with this difficulty
            var currentState = FlxG.state;
            if (Std.isOfType(currentState, MusicBeatState)) {
                var previousState = cast(currentState, MusicBeatState);
                activeTrapState = new archipelago.traps.games.APPongTrapState(previousState, this.difficulty);
                archipelago.APInfo.inMinigame = archipelago.APInfo.APMinigame.Pong;
                MusicBeatState.switchState(activeTrapState);
                APItem.popup("Pong Challenge (" + getDifficultyName(this.difficulty) + ") activated!");
            }
        }, false, false);
    }

    private function getDifficultyName(diff:Int):String {
        return getTrapDifficultyName(diff);
    }

    private static function getTrapDifficultyName(diff:Int):String {
        return switch(diff) {
            case 1: "Easy";
            case 2: "Normal";
            case 3: "Hard";
            case 4: "Expert";
            case 5: "Nightmare";
            default: "Unknown";
        }
    }

    public static function onTrapStateExit():Void {
        activeTrapState = null;

        // Process next difficulty in queue if any
        if (difficultyQueue.length > 0) {
            var nextDifficulty = difficultyQueue.shift();
            // Launch the next trap directly after a short delay
            new flixel.util.FlxTimer().start(0.5, function(timer) {
                var currentState = FlxG.state;
                if (Std.isOfType(currentState, MusicBeatState)) {
                    var previousState = cast(currentState, MusicBeatState);
                    activeTrapState = new archipelago.traps.games.APPongTrapState(previousState, nextDifficulty);
                    MusicBeatState.switchState(activeTrapState);
                    APItem.popup("Pong Challenge (" + getTrapDifficultyName(nextDifficulty) + ") activated from queue!");
                }
            });
        }
    }

    public static function clearQueue():Void {
        difficultyQueue = [];
    }

    public static function restoreFromSave(difficulty:Int):APPongTrap {
        return new APPongTrap(difficulty);
    }
}

class APTrap extends APItem {
    public function new(name:String, condition:Condition, onTrigger:Void->Void, isException:Bool = false, toSync:Bool = false, ?activeOnly:Bool = false) {
        this.isTrap = true; // Automatically set as trap
        super(name, condition, onTrigger, isException, toSync, activeOnly);
        this.isTrap = true; // Automatically set as trap... again. Just to be sure.
    }
}

class APrilFools extends APTrap {
    private static var options:Map<Int, Void->Void> = new Map();
    private static var initialized:Bool = false;


    static function initializeOptions():Void {
        options = [
            0 => function() {
                APItem.createCustomItem("April Fools - Nothing", ConditionHelper.Everywhere(), function() {
                    archipelago.APItem.popup("April Fools! Nothing happened this time.", "April Fools!");
                });
            },
            1 => function() {
                APItem.createCustomItem("April Fools - Random Item", ConditionHelper.Everywhere(), function() {
                    var randomItem = ["Blue Balls Curse", "Fake Transition", "SvC Effect", "Ghost Chat", "Shield", "Max HP Up", "Tutorial Trap"];
                    var chosenItem = randomItem[Std.random(randomItem.length)];
                    archipelago.APItem.createItemByName(chosenItem);
                });
            },
            2 => function() {
                APItem.createCustomItem("April Fools - No Heal", ConditionHelper.PlayState(), function() {
                    if (Std.is(FlxG.state, states.PlayState)) {
                        var playState:states.PlayState = cast FlxG.state;
                        playState.noHeal = true;
                        archipelago.APItem.popup("Healing disabled! Good luck!", "April Fools!");
                    }
                });
            },
            3 => function() {
                APItem.createCustomItem("April Fools - Fake Transition", ConditionHelper.Everywhere(), function() {
                    var transitionType = Std.random(2) == 0 ? "fallSequential" : "fallRandom";
                    TransitionState.fakeTransition({ transitionType: transitionType });
                    archipelago.APItem.popup("I hope you don't mind playing again!", "April Fools!");
                });
            },
            4 => function() {
                APItem.createCustomItem("April Fools - Random Song", ConditionHelper.Freeplay(), function() {
                    if (Std.is(FlxG.state, FreeplayManager.getFreeplay())) {
                        var freeplayState = cast FlxG.state;
                        var songList = freeplayState.fpManager.songList;
                        if (songList.length == 0) {
                            archipelago.APItem.popup("No songs available to switch!", "April Fools!");
                            return;
                        } else {
                            var randomSong:Int = FlxG.random.int(0, songList.length-1);
                            switch (songList[randomSong].songName)
                            {
                                case 'Small Argument' | 'Beat Battle 2' | 'GeoStar':
                                    Difficulty.list = ['Hard'];
                                case "Beat Battle":
                                    Difficulty.list = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
                                default:
                                    Difficulty.loadFromWeek(backend.WeekData.weeksLoaded.get(backend.WeekData.weeksList[songList[randomSong].week]));
                            }
                            var randomDiff:Int = FlxG.random.int(0, Difficulty.list.length-1);
                            var songLowercase:String = Paths.formatToSongPath(songList[randomSong].songName);
                            var poop:String = backend.Highscore.formatSong(songLowercase, randomDiff);
                            backend.Song.loadFromJson(poop, songLowercase);
                            states.PlayState.isStoryMode = false;
                            states.PlayState.storyDifficulty = randomDiff;
                            LoadingState.prepareToSong();
                            LoadingState.loadAndSwitchState(APEntryState.inArchipelagoMode ? new archipelago.APPlayState() : new states.PlayState());
                        }
                    }
                });
            },
            5 => function() {
                APItem.createCustomItem("April Fools - Health/MaxHP", ConditionHelper.PlayState(), function() {
                    if (Std.is(FlxG.state, states.PlayState)) {
                        var playState:states.PlayState = cast FlxG.state;
                        if (Std.random(2) == 0) {
                            var tween = flixel.tweens.FlxTween.num(playState.health, 0, 1, function(value:Float) {
                                playState.health = value;
                            });
                            archipelago.APItem.popup("Your health is now 0!", "April Fools!");
                        } else {
                            var tween = flixel.tweens.FlxTween.num(playState.MaxHP, 0, 1, function(value:Float) {
                                playState.MaxHP = value;
                            });
                            archipelago.APItem.popup("Your MaxHP is now 0!", "April Fools!");
                        }
                    }
                });
            },
            6 => function() {
                APItem.createCustomItem("April Fools - Screen Flip", ConditionHelper.PlayState(), function() {
                    if (Std.is(FlxG.state, states.PlayState)) {
                        var playState:states.PlayState = cast FlxG.state;
                        var randomChance = Std.random(100);
                        var targetAngle = 180;

                        if (randomChance < 10) { // 10% chance to overflip or underflip
                            targetAngle = 180 + (Std.random(3) - 1) * 360;
                        } else if (randomChance < 20) { // 10% chance to invert the screen
                            targetAngle = 0;
                        }

                        flixel.FlxG.camera.angle = 0;
                        flixel.tweens.FlxTween.num(0, targetAngle, 1, function(value:Float) {
                            flixel.FlxG.camera.angle = value;
                        });
                        archipelago.APItem.popup("The screen is flipped!", "April Fools!");
                    }
                });
            },
            8 => function() {
                APItem.createCustomItem("April Fools - BF Disappearing Act", ConditionHelper.PlayState(), function() {
                    if (Std.is(FlxG.state, archipelago.APPlayState)) {
                        var playState:archipelago.APPlayState = cast FlxG.state;

                        APItem.popup("BF is disappearing!", "April Fools!");
                        APItem.popup("Press ENTER to make him reappear!", "WARNING");

                        var bfDisappearFn = {
                            func: function() {
                                if (playState.boyfriend != null) {
                                    if (FlxG.keys.justPressed.ENTER) {
                                        playState.boyfriend.alpha = 1;
                                        return;
                                    }
                                    playState.boyfriend.alpha -= 0.01;
                                    if (playState.boyfriend.alpha <= 0) {
                                        try {
                                            FlxG.sound.pause();
                                        } catch (e:Dynamic) {
                                            trace("Error pausing sound: " + e);
                                        }
                                        try {
                                            FlxG.sound.music.pause();
                                        } catch (e:Dynamic) {
                                            trace("Error pausing music: " + e);
                                        }
                                        playState.paused = true;
                                        backend.COD.COD.COD = "Ceased to exist...";
                                        playState.die();
                                        for (camera in FlxG.cameras.list) {
                                            flixel.tweens.FlxTween.num(camera.alpha, 0, 0.001, function(value:Float) {
                                                camera.alpha = value;
                                                try {
                                                    FlxG.sound.pause();
                                                } catch (e:Dynamic) {
                                                    trace("Error pausing sound: " + e);
                                                }
                                                try {
                                                    FlxG.sound.music.pause();
                                                } catch (e:Dynamic) {
                                                    trace("Error pausing music: " + e);
                                                }
                                            });
                                        }
                                    }
                                }
                            },
                            keepOnRestart: true
                        };

                        if (!APPlayState.updateFunctions.map(function(obj) return Reflect.compareMethods(obj.func, bfDisappearFn.func)).contains(true)) {
                            APPlayState.updateFunctions.push(bfDisappearFn);
                        } else {
                            APPlayState.updateFunctions.remove(bfDisappearFn);
                            APPlayState.updateFunctions.push(bfDisappearFn);
                        }
                    }
                });
            },
            #if windows
            7 => function() {
                APItem.createCustomItem("April Fools - Windows Notification", ConditionHelper.Everywhere(), function() {
                    var creepyMessages = [
                        "I can see you...",
                        "Did you hear that?",
                        "Don't look behind you.",
                        "Your time is running out.",
                        "Is someone watching?",
                        "Check your surroundings.",
                        "What was that noise?",
                        "Are you alone?",
                        "Something feels off.",
                        "Why is it so quiet?"
                    ];

                    var funnyMessages = [
                        "Your computer is now self-aware. Just kidding!",
                        "Why did the programmer quit? They didn't get arrays.",
                        "404: Your luck not found.",
                        "Did you just press a button? Bold move.",
                        "Your keyboard is plotting against you.",
                        "Congratulations! You've won absolutely nothing!",
                        "This is not a bug, it's a feature.",
                        "Your mouse just moved on its own. Or did it?",
                        "Don't worry, the code is 100% bug-free. Maybe.",
                        "Fun fact: This message is completely pointless.",
                        "Your screen is now 10% brighter. Just kidding!",
                        "Did you know? This message is wasting your time.",
                        "Your CPU is laughing at you right now.",
                        "Error 42: Life, the universe, and everything.",
                        "Your RAM just said 'hi'.",
                        "This is a test. Or is it?",
                        "Your GPU wants a vacation.",
                        "Z11 is watching you.",
                        "Yuta is watching you.",
                        "Yuta is always watching.",
                        "Z11 is always watching.",
                        "Yuta and Z11 are always watching.",
                        "Yuta and Z11 are always watching you.",
                        "Yuta and Z11 are always watching you play.",
                        "Yuta and Z11 are always watching you play this game.",
                        "The void is coming."
                    ];

                    var randomMessage = Std.random(100) < 20 // 20% chance for creepy messages
                        ? creepyMessages[Std.random(creepyMessages.length)]
                        : funnyMessages[Std.random(funnyMessages.length)];
                    if (!PlatformUtil.sendWindowsNotification("Archipelago", randomMessage)) {
                        APItem.popup(randomMessage, "Archipelago", true);
                    }
                });
            }
            #end
        ];
    }

    // public override function trigger():Void {
    //     if (triggered) {
    //         return; // Prevent multiple triggers
    //     }
    //     triggered = true; // Set triggered to true to prevent multiple triggers
    //     super.trigger();
    //     //trace("April Fools item triggered.");
    // }

        public function new() {
            super("April Fools", ConditionHelper.Special(), function() {
                // trace("April Fools item triggered.");
                if (!initialized) {
                    initialized = true;
                    trace("Initializing options for April Fools.");
                    initializeOptions();
                    APItem.popup("Something odd is brewing.", "Archipelago", true);
                }

                var optionss:Int = 0;
                for (o in options.keys()) {
                    optionss++;
                }

                var randomChoice = Std.random(optionss);
                // trace("Random choice selected: " + randomChoice);
                var action = options.get(randomChoice);
                if (action != null) {
                    // trace("Executing action for choice: " + randomChoice);
                    action();
                    APItem.popup("Something happened...", "Archipelago", true);
                } else {
                    // trace("No action found for choice: " + randomChoice);
                }
            }, false, false);
        }
    }
