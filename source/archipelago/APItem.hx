package archipelago;

import haxe.ds.StringMap;

typedef Condition = {
    var checkFn:APItem->Bool;
    var type:ConditionType;
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
        return item.condition.checkFn(item);
    }

    public static inline function Everywhere():Condition { 
        return ConditionHelper.create(function(item:APItem):Bool { return true; }, ConditionType.Everywhere); 
    }
    public static inline function PlayState():Condition { 
        return ConditionHelper.create(function(item:APItem):Bool { return Std.is(FlxG.state, states.PlayState) && (!states.PlayState.instance.startingSong || item.isException); }, ConditionType.PlayState); 
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
        return activeItem == null || activeItem.isException;
    }
    public static var activeItem:APItem;
    public static var shields:Int = 0;
    public static var maxHPUp:Int = 0;

    private var toSync:Bool = true;

    public static var nonSongItemCounts:Map<String, Int> = new Map<String, Int>();




    private static var allItems:ActiveArray = new ActiveArray([]);

    public function new(name:String, condition:Condition, onTrigger:Void->Void, isException:Bool = false, toSync:Bool = true) {
        this.name = name;
        this.condition = condition;
        this.onTrigger = onTrigger;
        this.isException = isException;
        this.toSync = toSync;

        if (this.condition.type == Everywhere) {
            this.isException = true;
        }

        allItems.push(this);
    }

    public static function popup(desc:String):Void {
        if (!APGameState.haventranyet) {
            archipelago.ArchPopup.startPopupCustom("AP Item!", desc, "archColor", function() {
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
                        ArchPopup.startPopupCustom("Death Avoided!", 'Shields left: $shields', "archWhite");
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
                return new APItem(name, ConditionHelper.Everywhere(), function() TransitionState.fakeTransition({transitionType:"transparent close"}), true, false);
            case "Ticket":
                return new APItem(name, ConditionHelper.Everywhere(), function() {popup("You got a ticket!");
                    archipelago.APInfo.ticketCount++;
                }, true, true);
            case "SvC Effect":
                return new APItem(name, ConditionHelper.PlayState(), function() APPlayState.instance.doEffect(APPlayState.instance.effectArray[APPlayState.instance.curEffect]), true, false);
            case "Ghost Chat":
                return new APItem(name, ConditionHelper.PlayState(), function() APPlayState.instance.triggerGhostChat(), true, false);
            case "Shield":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    shields++;
                    trace("Shield acquired! Current shields: " + shields);
                    popup("You got a shield!");
                }, true, true);
            case "Max HP Up":
                return new APItem(name, ConditionHelper.Everywhere(), function() {
                    maxHPUp++;
                    trace("Max HP increased! Current max HP: " + maxHPUp);
                    popup("You got a max HP up!");
                }, true, true);
            case "Tutorial Trap":
                return new APItem(name, ConditionHelper.PlayState(), function() {
                    // Wait for PlayState's startedCountdown to become active
                    haxe.Timer.delay(function checkCountdown() {
                        var playState:archipelago.APPlayState = cast states.PlayState.instance;
                        if (playState != null && playState.startedCountdown) {
                            APPlayState.instance.doEffect('songSwitch');
                        } else {
                            // Retry after a short delay if countdown hasn't started
                            haxe.Timer.delay(checkCountdown, 100);
                        }
                    }, 100);
                }, true, false);
            default:
                throw "Unknown item name: " + name;
        }
        }

    public function trigger():Void {
        trace('is Gonna Run Sync: ${APGameState.isSync}');
        if (APInfo.ap.firstSync && this.toSync) {
            trace("RUNNING FIRST SYNC!");
            trace("Triggering item: " + this.name);
            trace("Is exception: " + this.isException);
            trace("Condition type: " + this.condition.type);
            trace("Condition check result: " + this.condition.checkFn(this));

            if (!this.isException && this.condition.type != ConditionType.Everywhere && this.condition.checkFn(this)) {
                trace("Setting active item to: " + this.name);
                APItem.activeItem = this;
            } else {
                trace("Active item not set due to condition, exception rules, or being an Everywhere item.");
            }

            if (this.condition.checkFn(this)) {
                trace("Condition passed, executing onTrigger for item: " + this.name);
                onTrigger();
            } else {
                trace("Condition failed, onTrigger not executed for item: " + this.name);
            }
        } else if (!APInfo.ap.firstSync) {
            trace("RUNNING NORMAL SYNC!");
            trace("Triggering item: " + this.name);
            trace("Is exception: " + this.isException);
            trace("Condition type: " + this.condition.type);
            trace("Condition check result: " + this.condition.checkFn(this));

            if (!this.isException && this.condition.type != ConditionType.Everywhere && this.condition.checkFn(this)) {
                trace("Setting active item to: " + this.name);
                APItem.activeItem = this;
            } else {
                trace("Active item not set due to condition, exception rules, or being an Everywhere item.");
            }

            if (this.condition.checkFn(this)) {
                trace("Condition passed, executing onTrigger for item: " + this.name);
                onTrigger();
            } else {
                trace("Condition failed, onTrigger not executed for item: " + this.name);
            }
        }

        trace("Removing item from allItems: " + this.name);
        allItems.remove(this);
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
        var triggered:Bool = false;

        for (item in items) {
            if (!allowedToTrigger && !item.isException) {
                continue;
            }
            if (item.condition.checkFn(item)) {
                if (!triggered || item.isException) {
                    item.trigger();
                    if (!item.isException) {
                        triggered = true;
                    }
                }
            }
        }
    }
}