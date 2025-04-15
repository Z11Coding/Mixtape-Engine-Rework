package archipelago;

import backend.window.PlatformUtil;
import haxe.ds.StringMap;

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
            if (Std.is(FlxG.state, states.FreeplayState)) {
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
    public static inline function PlayState():Condition { 
        return ConditionHelper.create(function(item:APItem):Bool { return Std.is(FlxG.state, states.PlayState) && (states.PlayState.instance.startingSong || (item.isException && !states.PlayState.instance.endingSong && backend.TransitionState.currenttransition == null)); }, ConditionType.PlayState); 
    }
    public static inline function Freeplay():Condition { 
        return ConditionHelper.create(function(item:APItem):Bool { return Std.is(FlxG.state, states.FreeplayState); }, ConditionType.Freeplay); 
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



class APItem {
    public var name:String;
    public var condition:Condition;
    public var onTrigger:Void->Void;
    public var isException:Bool;
    public static var allowedToTrigger(get, never):Bool;

    static function get_allowedToTrigger():Bool {
        return true;
    }
    public static var activeItem:APItem;
    public static var shields:Int = 0;
    public static var maxHPUp:Int = 0;

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

    public static function createItemByName(name:String):APItem {
        switch (name) {
            case "Blue Balls Curse":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
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
                }, false, false);
            case "Fake Transition":
                return new APItem(name, ConditionHelper.Special(), function() TransitionState.fakeTransition({transitionType:"transparent close"}), true, false);
            case "Ticket":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    archipelago.APInfo.ticketCount++;
                    if (!archipelago.APGameState.instance.info().casualSync)
                    popup(archipelago.APInfo.ticketCount > archipelago.APInfo.ticketWinCount ? "Not that you needed it..." : archipelago.APInfo.ticketCount == archipelago.APInfo.ticketWinCount ? "You have all you need!" : "One step closer...", "You got a ticket!");
                }, true, true);
            case "SvC Effect":
                return new APItem(name, ConditionHelper.PlayState(), function() {
                    popup('Effect: ${APPlayState.instance.effectArray[APPlayState.instance.curEffect]}', "APItem: SvC Effect", true);
                    APPlayState.instance.doEffect(APPlayState.instance.effectArray[APPlayState.instance.curEffect]);
                }, true, false);
            case "Ghost Chat":
                return new APItem(name, ConditionHelper.PlayState(), function() {
                    popup('May the chat be merciful on you...', "APItem: Ghost Chat", true);
                    APPlayState.instance.triggerGhostChat();
                }, true, false);
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
            case "Tutorial Trap":
                return new APItem(name, ConditionHelper.PlayState(), function() {
                    // Wait for PlayState's startedCountdown to become active
                    haxe.Timer.delay(function checkCountdown() {
                        var playState:archipelago.APPlayState = cast states.PlayState.instance;
                        if (playState != null && playState.startedCountdown) {
                            popup('Go relearn the basics', "APItem: Tutorial Trap");
                            APPlayState.instance.doEffect('songSwitch');
                            if (APItem.activeItem !=null) 
                                allItems.push(APItem.activeItem);
                            activeItem = new APItem("Tutorial Trap", ConditionHelper.PlayState(), function() {
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
                }, true, false);
            case "Chart Modifier Trap":
                return new APChartModifier();
            default:
                throw "Unknown item name: " + name;
        }
    }
    
    public function trigger():Void {
        if ((this != APItem.activeItem) || this.triggered ) {
            return; // Only the active item can trigger unless it's an exception
        }

        // trace("Triggering item: " + this.name + "\n" + "Condition: " + this.condition.type + "\n" + "Triggered: " + this.triggered);
        // var index = allItems.getItems().indexOf(this);
        // if (index != -1) {
        //     // trace("Item is in allItems at index: " + index);
        // }
        // if (APItem.activeItem == this) {
        //     // trace("Item is the activeItem.");
        // }

        // trace(APItem.activeItem?.name + " is the active item.");

        if (this.isException && (APItem.activeItem == null || APItem.activeItem.name != this.name)) {
            // Push the current active item back into the queue
            if (APItem.activeItem != null) {
                allItems.unshift(APItem.activeItem);
            }
            // Swap out the active item for the exception
            APItem.activeItem = this;
            allItems.remove(this);
        }

        // Trace if it is allowed to trigger, and what conditions are considered, and what they are.
        // trace("Allowed to trigger: " + APItem.allowedToTrigger);
        // trace("Trigger components: " + (APItem.activeItem == null) + " " + (APItem.activeItem?.isException) + " " + (APItem.activeItem?.name == this.name));

        // Check conditions before triggering
        if (this.condition.checkFn(this) && APItem.allowedToTrigger) {
            if (this.condition.extraConditions != null) {
                for (extraCondition in this.condition.extraConditions) {
                    if (!extraCondition(this)) {
                        return; // Exit if any extra condition fails
                    }
                }
            }

            trace("Triggering item: " + this.name + "\n" + "Condition: " + this.condition.type + "\n" + "Triggered: " + this.triggered);

            // Trigger the item without removing it from the queue
            this.onTrigger();
            this.triggered = true;         }
    }

    public static function createItems():Void {
        var itemNames:Array<String> = [
            "Blue Balls Curse",
            "Fake Transition",
            "Ticket",
            "SvC Effect",
            "Ghost Chat",
            "Shield",
            "Max HP Up",
            "Tutorial Trap"
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
    }
    public static function checkAndTrigger(items:Array<APItem>):Void {
        // Put the next item into the activeItems, if it isn't already filled by something.

        if (activeItem?.isException && activeItem?.triggered) {
            // If the active item is an exception and has been triggered, remove it from the list
            activeItem = null;
        }

        activeItem?.trigger();

        if (activeItem == null) {
            for (item in items) {
                if (item != null) {
                    item.trigger();
                }
            }
        }
}



}

class APChartModifier extends APItem {
    public var chartModifier:String;

    public function new(?chartModifier:String) {
        var modifiers = chartModifier != null ? [chartModifier] : ["Random", "RandomBasic", "RandomComplex", "Flip", "Pain", "ManiaConverter", "Stairs", "Wave", "Trills", "Amalgam"];
        if (yutautil.AprilFools.allowAF) {
            modifiers.push("SpeedRando");
        }
        do { // Until ManiaConverter is fixed, reroll if selected.
            this.chartModifier = modifiers[Std.random(modifiers.length)];
        } while (this.chartModifier == "ManiaConverter"); // Reroll if ManiaConverter is selected

        super("Chart Modifier Trap (" + this.chartModifier + ")", ConditionHelper.PlayState(), function() {
            ClientPrefs.data.gameplaySettings.set("chartModifier", this.chartModifier);
            APItem.popup("Chart Modifier Trap (" + this.chartModifier + ")");
            if (archipelago.APPlayState.instance?.startingSong) {
                MusicBeatState.switchState(new states.PlayState()); // Don't ask why I had to do this. - Yuta
            }
        }, false, false);
    }

    public static function restoreFromSave(modifier:String):Void {
        new APChartModifier(modifier);
    }
}
class APrilFools extends APItem {
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
                    var randomItem = ["Blue Balls Curse", "Fake Transition", "Ticket", "SvC Effect", "Ghost Chat", "Shield", "Max HP Up", "Tutorial Trap"];
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
                    if (Std.is(FlxG.state, states.FreeplayState)) {
                        var freeplayState:states.FreeplayState = cast FlxG.state;
                        var songList = freeplayState.songList;
                        if (songList.length == 0) {
                            archipelago.APItem.popup("No songs available to switch!", "April Fools!");
                            return;
                        } else {
                            var randomSong:Int = FlxG.random.int(0, songList.length-1);
                            switch (songList[randomSong].songName)
                            {
                                case 'Small Argument' | 'Beat Battle 2':
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
