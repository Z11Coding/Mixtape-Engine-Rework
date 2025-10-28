package yutautil;

import flixel.FlxBasic;
import flixel.FlxState;
import flixel.util.FlxDestroyUtil;

/**
 * SafeManagedState - A minimal version of ManagedState that's designed to not interfere
 * with recycling systems and other sensitive memory operations.
 *
 * This version provides basic cleanup without the aggressive asset tracking that can
 * cause issues with FlxSpriteGroup recycling and similar systems.
 */
class SafeManagedState extends FlxState {

    private var isDestroying:Bool = false;
    private var endOfLifeTriggered:Bool = false;

    public function new() {
        super();
    }

    override public function destroy():Void {
        if (!isDestroying) {
            isDestroying = true;
            performSafeCleanup();
        }
        super.destroy();
    }

    /**
     * EndOfLife - Safe cleanup that won't interfere with recycling
     */
    public function EndOfLife():Void {
        if (endOfLifeTriggered) return;

        endOfLifeTriggered = true;
        trace('SafeManagedState: EndOfLife triggered - performing safe cleanup');

        performSafeCleanup();

        // Clear members safely without aggressive asset cleanup
        if (members != null) {
            var membersToRemove = members.copy();
            for (member in membersToRemove) {
                if (member != null) {
                    try {
                        remove(member);
                        // Only destroy if it's not part of a recycling system
                        if (!isLikelyRecycled(member)) {
                            member.destroy();
                        }
                    } catch (e:Dynamic) {
                        trace('SafeManagedState: Error during safe cleanup: $e');
                    }
                }
            }
            members.splice(0, members.length);
        }

        // Force garbage collection if available
        #if cpp
        try {
            yutautil.MemoryHelper.clearMemoryStored();
        } catch (e:Dynamic) {
            trace('SafeManagedState: Error during garbage collection: $e');
        }
        #end

        trace('SafeManagedState: EndOfLife cleanup completed');
    }

    /**
     * Safe cleanup without aggressive asset inspection
     */
    private function performSafeCleanup():Void {
        trace('SafeManagedState: Starting safe cleanup');

        // Just clear members without deep asset inspection
        if (members != null) {
            for (member in members.copy()) {
                if (member != null && !isLikelyRecycled(member)) {
                    try {
                        remove(member);
                    } catch (e:Dynamic) {
                        trace('SafeManagedState: Error removing member: $e');
                    }
                }
            }
        }

        trace('SafeManagedState: Safe cleanup completed');
    }

    /**
     * Check if an object is likely part of a recycling system
     */
    private function isLikelyRecycled(object:FlxBasic):Bool {
        if (object == null) return false;

        try {
            var className = Type.getClassName(Type.getClass(object));
            if (className != null) {
                // Check for commonly recycled types
                if (className.indexOf("AlphaCharacter") != -1 ||
                    className.indexOf("Note") != -1 ||
                    className.indexOf("StrumNote") != -1) {
                    return true;
                }

                // Check if it has a parent that suggests recycling
                var parent = Reflect.field(object, "parent");
                if (parent != null) {
                    var parentClass = Type.getClassName(Type.getClass(parent));
                    if (parentClass != null && (
                        parentClass.indexOf("SpriteGroup") != -1 ||
                        parentClass.indexOf("Alphabet") != -1
                    )) {
                        return true;
                    }
                }
            }
        } catch (e:Dynamic) {
            // If we can't determine, assume it might be recycled for safety
            return true;
        }

        return false;
    }

    /**
     * Get basic statistics
     */
    public function getStats():SafeManagedStateStats {
        return {
            currentMembers: members != null ? members.length : 0,
            isDestroying: isDestroying,
            endOfLifeTriggered: endOfLifeTriggered
        };
    }
}

/**
 * Statistics structure for SafeManagedState
 */
typedef SafeManagedStateStats = {
    currentMembers:Int,
    isDestroying:Bool,
    endOfLifeTriggered:Bool
}
