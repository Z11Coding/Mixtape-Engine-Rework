package archipelago;

import flixel.FlxG;

typedef APItemConditionRunner = {
    var item:APItem;
    var update:APItem->Bool;
}

class APItemManager {
    private static var pendingItems:Array<APItem> = [];
    private static var activeBlockingItem:APItem = null;
    private static var activeEffects:Map<String, APItem> = new Map<String, APItem>();
    private static var activeSongEffects:Array<APItem> = [];
    private static var conditionRunners:Array<APItemConditionRunner> = [];

    public static function getActiveItem():APItem {
        return activeBlockingItem;
    }

    public static function setActiveItem(item:APItem):APItem {
        activeBlockingItem = item;
        return item;
    }

    public static function getActiveEffects():Map<String, APItem> {
        return activeEffects;
    }

    public static function getActiveSongEffects():Array<APItem> {
        return activeSongEffects;
    }

    public static function getPendingItems():Array<APItem> {
        return pendingItems.copy();
    }

    public static function enqueue(item:APItem):Void {
        if (item == null || pendingItems.indexOf(item) != -1) {
            return;
        }
        pendingItems.push(item);
    }

    public static function requeueFront(item:APItem):Void {
        if (item == null) {
            return;
        }
        removePendingItem(item);
        pendingItems.unshift(item);
    }

    public static function registerItem(item:APItem, activeOnly:Bool):Void {
        if (item == null) {
            return;
        }

        if (!activeOnly) {
            enqueue(item);
            doCheck();
            return;
        }

        if (activeBlockingItem == null || activeBlockingItem.isException || activeBlockingItem.name == "Tutorial Trap") {
            if (activeBlockingItem != null) {
                requeueFront(activeBlockingItem);
            }
            activeBlockingItem = item;
        } else {
            enqueue(item);
        }
        doCheck();
    }

    public static function removePendingItem(item:APItem):Void {
        if (item == null) {
            return;
        }

        var index = pendingItems.indexOf(item);
        if (index != -1) {
            pendingItems.splice(index, 1);
        }
    }

    public static function hasActiveSongEffect(item:APItem):Bool {
        return item != null && activeSongEffects.indexOf(item) != -1;
    }

    public static function hasSongFamilyConflict(item:APItem):Bool {
        if (item == null) {
            return false;
        }

        for (activeItem in activeSongEffects) {
            if (activeItem == null || activeItem == item) {
                continue;
            }
            if (activeItem.isTrap == item.isTrap) {
                return true;
            }
        }
        return false;
    }

    public static function canActivateSongEffect(item:APItem):Bool {
        return !hasSongFamilyConflict(item) || hasActiveSongEffect(item);
    }

    public static function registerActiveSongEffect(item:APItem):Void {
        if (item == null || hasActiveSongEffect(item)) {
            return;
        }
        activeSongEffects.push(item);
    }

    public static function registerActiveEffect(item:APItem):Void {
        if (item == null) {
            return;
        }
        activeEffects.set(item.name, item);
    }

    public static function addConditionRunner(item:APItem, update:APItem->Bool):Void {
        if (item == null || update == null) {
            return;
        }
        conditionRunners.push({item: item, update: update});
    }

    public static function removeConditionRunner(item:APItem):Void {
        if (item == null) {
            return;
        }

        conditionRunners = conditionRunners.filter(function(entry) {
            return entry.item != item;
        });
    }

    public static function completeTriggeredItem(item:APItem):Void {
        if (item == null) {
            return;
        }

        var isSongItem = item.condition.type == ConditionType.PlayState && item.condition.playStateType == Song;
        if (isSongItem) {
            registerActiveSongEffect(item);
        }
        removePendingItem(item);
        if (activeBlockingItem == item) {
            activeBlockingItem = null;
        }
    }

    private static function updateConditionRunners():Void {
        if (conditionRunners.length == 0) {
            return;
        }

        var remaining:Array<APItemConditionRunner> = [];
        for (entry in conditionRunners) {
            if (entry == null || entry.item == null || entry.update == null) {
                continue;
            }
            if (entry.update(entry.item)) {
                remaining.push(entry);
            }
        }
        conditionRunners = remaining;
    }

    private static function normalizeSongEffectsForState():Void {
        if (Std.is(FlxG.state, states.PlayState)) {
            return;
        }

        for (item in activeSongEffects) {
            if (item != null) {
                item.triggered = false;
            }
        }

        if (activeBlockingItem != null && hasActiveSongEffect(activeBlockingItem)) {
            activeBlockingItem = null;
        }
    }

    public static function doCheck():Void {
        normalizeSongEffectsForState();
        updateConditionRunners();

        if (activeBlockingItem?.isException == true && activeBlockingItem?.triggered == true) {
            activeBlockingItem = null;
        }

        for (item in activeSongEffects) {
            if (item != null && !item.triggered) {
                item.trigger();
            }
        }

        if (activeBlockingItem != null && !activeBlockingItem.triggered) {
            activeBlockingItem.trigger();
            if (activeBlockingItem != null && activeBlockingItem.triggered) {
                activeBlockingItem = null;
            }
        }

        if (activeBlockingItem != null) {
            return;
        }

        for (item in pendingItems.copy()) {
            if (item == null) {
                continue;
            }

            var wasTriggered = item.triggered;
            item.trigger();
            if (!wasTriggered && item.triggered && !item.isException) {
                break;
            }
        }
    }

    public static function clearActiveEffects():Void {
        activeEffects.clear();
        for (item in activeSongEffects) {
            if (item != null) {
                item.triggered = false;
            }
        }
        activeSongEffects = [];
        conditionRunners = [];
    }

    public static function onSongEnd():Void {
        clearActiveEffects();
    }

    public static function onLeavePlayState():Void {
        clearActiveEffects();
        if (activeBlockingItem != null && activeBlockingItem.condition.type == ConditionType.PlayState) {
            activeBlockingItem = null;
        }
    }

    public static function restoreTrackedItem(item:APItem, asEffect:Bool, asSong:Bool):Void {
        if (item == null) {
            return;
        }

        if (asEffect) {
            registerActiveEffect(item);
        }
        if (asSong) {
            registerActiveSongEffect(item);
        }
        if (asEffect || asSong) {
            removePendingItem(item);
            item.triggered = true;
        }
    }

    public static function getActiveEffectNames():Array<String> {
        return [for (name in activeEffects.keys()) name];
    }

    public static function getActiveSongEffectNames():Array<String> {
        return activeSongEffects.filter(function(item) return item != null).map(function(item) return item.name);
    }

    public static function hasActiveItemNamed(name:String):Bool {
        if (name == null) {
            return false;
        }

        if (activeBlockingItem != null && activeBlockingItem.name == name) {
            return true;
        }

        if (activeEffects.exists(name)) {
            return true;
        }

        for (item in activeSongEffects) {
            if (item != null && item.name == name) {
                return true;
            }
        }

        return false;
    }

    public static function cleanupAllAPData():Void {
        activeBlockingItem = null;

        for (item in pendingItems) {
            if (item != null) {
                item.triggered = true;
                item.onTrigger = function() {};
            }
        }

        pendingItems = [];
        activeEffects.clear();
        activeSongEffects = [];
        conditionRunners = [];
    }
}
