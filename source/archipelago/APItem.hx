package archipelago;

import haxe.ds.StringMap;

typedef Condition = {
    var checkFn:Void->Bool;
    var type:ConditionType;
}

enum ConditionType {
    Everywhere;
    PlayState;
    Freeplay;
}

class ConditionHelper {
    public static inline function create(check:Void->Bool, type:ConditionType):Condition {
        return { checkFn: check, type: type };
    }

    public static inline function check(condition:Condition):Bool {
        return condition.checkFn();
    }
    public static var Everywhere = ConditionHelper.create(function():Bool { return true; }, ConditionType.Everywhere);
    public static var PlayState = ConditionHelper.create(function():Bool { return Std.is(FlxG.state, states.PlayState); }, ConditionType.PlayState);
    public static var Freeplay = ConditionHelper.create(function():Bool { return Std.is(FlxG.state, states.FreeplayState); }, ConditionType.Freeplay);
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

        if (APEntryState.gonnaRunSync && this.toSync) {
            allItems.push(this); trace('Item to sync: ${this.name}');
        } else if (!APEntryState.gonnaRunSync) {
            allItems.push(this); trace('Item: ${this.name}');
        }
   
    }

    public static function popup(desc:String):Void {
        archipelago.ArchPopup.startPopupCustom("AP Item!", desc, "archColor", function() {
            FlxG.sound.playMusic(Paths.sound('secret'));
    });}

    public static function createItemByName(name:String):APItem {
        switch (name) {
            case "Blue Balls Curse":
                return new APItem(name, ConditionHelper.Everywhere, function() {
                    // Check if shields are available
                    if (shields > 0) {
                        shields--;
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
                return new APItem(name, ConditionHelper.Everywhere, function() TransitionState.fakeTransition({transitionType:"transparent close"}), true, false);
            case "Ticket":
                return new APItem(name, ConditionHelper.Everywhere, function() {popup("You got a ticket!");
                    archipelago.APInfo.ticketCount++;}   
                );
            case "SvC Effect":
                return new APItem(name, ConditionHelper.PlayState, function() trace("SvC Effect triggered!"));
            case "Ghost Chat":
                return new APItem(name, ConditionHelper.PlayState, function() trace("Ghost Chat triggered!"));
            case "Shield":
                return new APItem(name, ConditionHelper.Everywhere, function() {
                    shields++;
                    trace("Shield acquired! Current shields: " + shields);
                    popup("You got a shield!");
                });
            case "Max HP Up":
                return new APItem(name, ConditionHelper.Everywhere, function() {
                    maxHPUp++;
                    trace("Max HP increased! Current max HP: " + maxHPUp);
                    popup("You got a max HP up!");
                });
            case "Tutorial Trap":
                return new APItem(name, ConditionHelper.PlayState, function() trace("Tutorial Trap triggered!"), true);
            default:
                throw "Unknown item name: " + name;
        }
        }

    public function trigger():Void {
        trace("Triggering item: " + this.name);
        trace("Is exception: " + this.isException);
        trace("Condition type: " + this.condition.type);
        trace("Condition check result: " + this.condition.checkFn());

        if (!this.isException && this.condition.type != ConditionType.Everywhere && this.condition.checkFn()) {
            trace("Setting active item to: " + this.name);
            APItem.activeItem = this;
        } else {
            trace("Active item not set due to condition, exception rules, or being an Everywhere item.");
        }

        if (this.condition.checkFn()) {
            trace("Condition passed, executing onTrigger for item: " + this.name);
            onTrigger();
        } else {
            trace("Condition failed, onTrigger not executed for item: " + this.name);
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
            if (item.condition.checkFn()) {
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