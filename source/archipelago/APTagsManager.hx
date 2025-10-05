package archipelago;

import helder.Set;
import yutautil.TypeUtils.OneOrMore;

/**
 * APTagsManager - A utility class for managing Archipelago client tags
 *
 * Provides a clean interface for adding, removing, and setting tags on an AP client
 * without having to manually manage arrays and call client methods directly.
 *
 * Usage Examples:
 *
 * // Access via client
 * var client = new Client(uuid, game, uri);
 *
 * // Set all tags at once
 * client.tagsManager.set(['AP', 'Testing', 'DeathLink']);
 *
 * // Add individual or multiple tags
 * client.tagsManager.add('MyCustomTag');              // Add single tag
 * client.tagsManager.add(['Tag1', 'Tag2', 'Tag3']);   // Add multiple tags
 * client.tagsManager.enableDeathLink();               // Convenience method
 * client.tagsManager.enableTrapLink();
 *
 * // Remove individual or multiple tags
 * client.tagsManager.remove('DeathLink');             // Remove single tag
 * client.tagsManager.remove(['OldTag1', 'OldTag2']);  // Remove multiple tags
 * client.tagsManager.disableDeathLink();              // Convenience method
 *
 * // Check for tags
 * if (client.tagsManager.hasDeathLink()) {
 *     trace('Death Link is enabled');
 * }
 *
 * // Check multiple tags at once
 * if (client.tagsManager.hasAny(['DeathLink', 'TrapLink'])) {
 *     trace('At least one link type is enabled');
 * }
 *
 * if (client.tagsManager.hasAll(['AP', 'Testing'])) {
 *     trace('All required tags present');
 * }
 *
 * // Toggle tags
 * var wasAdded = client.tagsManager.toggle('SomeTag');
 *
 * // Get current tags (read-only)
 * var currentTags = client.tagsManager.tags;
 * trace('Current tags: ${currentTags.join(", ")}');
 */
class APTagsManager {
    private var client:Client;
    private var _tags:Array<String>;

    /**
     * Initialize the tags manager with a reference to the client
     * @param client The AP client to manage tags for
     */
    public function new(client:Client) {
        this.client = client;
        this._tags = client.tags != null ? client.tags.copy() : [];
        trace('APTagsManager initialized with ${_tags.length} existing tags');
        trace('Existing tags: ${_tags.join(", ")}');
    }

    /**
     * Get the current tags as a copy (read-only)
     */
    public var tags(get, never):Array<String>;
    private function get_tags():Array<String> {
        return _tags.copy();
    }

    /**
     * Set all tags to the provided array
     * This replaces all existing tags with the new ones
     * @param newTags Array of tag strings to set
     */
    public function set(newTags:Array<String>):Void {
        if (newTags == null) newTags = [];

        _tags = newTags.copy();

        // Remove duplicates and trim whitespace


        syncToClient();
        trace('APTagsManager: Set tags to: ${_tags.join(", ")}');
    }

    /**
     * Add one or more tags if they don't already exist
     * @param tags Either a single tag string or an array of tag strings
     * @return Number of tags that were actually added (excludes duplicates)
     */
    public function add(tags:OneOrMore<String>):Int {
        var tagsToAdd = tags.toArray();
        var addedCount = 0;

        for (tag in tagsToAdd) {
            if (tag == null || tag.trim() == "") {
                trace('APTagsManager: Cannot add null or empty tag');
                continue;
            }

            tag = tag.trim();

            if (_tags.indexOf(tag) == -1) {
                _tags.push(tag);
                addedCount++;
                trace('APTagsManager: Added tag: $tag');
            } else {
                trace('APTagsManager: Tag already exists: $tag');
            }
        }

        if (addedCount > 0) {
            syncToClient();
            trace('APTagsManager: Added $addedCount new tags total');
        }

        return addedCount;
    }

    /**
     * Remove one or more tags if they exist
     * @param tags Either a single tag string or an array of tag strings
     * @return Number of tags that were actually removed
     */
    public function remove(tags:OneOrMore<String>):Int {
        var tagsToRemove = tags.toArray();
        var removedCount = 0;

        for (tag in tagsToRemove) {
            if (tag == null || tag.trim() == "") {
                trace('APTagsManager: Cannot remove null or empty tag');
                continue;
            }

            tag = tag.trim();

            var index = _tags.indexOf(tag);
            if (index != -1) {
                _tags.splice(index, 1);
                removedCount++;
                trace('APTagsManager: Removed tag: $tag');
            } else {
                trace('APTagsManager: Tag not found for removal: $tag');
            }
        }

        if (removedCount > 0) {
            syncToClient();
            trace('APTagsManager: Removed $removedCount tags total');
        }

        return removedCount;
    }

    /**
     * Check if a tag exists
     * @param tag The tag to check for
     * @return true if the tag exists
     */
    public function has(tag:String):Bool {
        if (tag == null || tag.trim() == "") return false;
        return _tags.indexOf(tag.trim()) != -1;
    }

    /**
     * Check if any of the provided tags exist
     * @param tags Either a single tag or array of tags to check for
     * @return true if at least one tag exists
     */
    public function hasAny(tags:OneOrMore<String>):Bool {
        var tagsToCheck = tags.toArray();
        if (tagsToCheck.length == 0) return false;

        for (tag in tagsToCheck) {
            if (has(tag)) return true;
        }
        return false;
    }

    /**
     * Check if all of the provided tags exist
     * @param tags Either a single tag or array of tags to check for
     * @return true if all tags exist
     */
    public function hasAll(tags:OneOrMore<String>):Bool {
        var tagsToCheck = tags.toArray();
        if (tagsToCheck.length == 0) return true;

        for (tag in tagsToCheck) {
            if (!has(tag)) return false;
        }
        return true;
    }

    /**
     * Clear all tags
     */
    public function clear():Void {
        _tags = [];
        syncToClient();
        trace('APTagsManager: Cleared all tags');
    }

    /**
     * Get the number of tags
     */
    public var count(get, never):Int;
    private function get_count():Int {
        return _tags.length;
    }

    /**
     * Toggle a tag (add if not present, remove if present)
     * @param tag The tag to toggle
     * @return true if the tag was added, false if it was removed
     */
    public function toggle(tag:String):Bool {
        if (has(tag)) {
            remove(tag);
            return false;
        } else {
            add(tag);
            return true;
        }
    }

    /**
     * Convenient methods for common AP tags
     */
    public function enableDeathLink():Bool {
        return add('DeathLink') > 0;
    }

    public function disableDeathLink():Bool {
        return remove('DeathLink') > 0;
    }

    public function enableTrapLink():Bool {
        return add('TrapLink') > 0;
    }

    public function disableTrapLink():Bool {
        return remove('TrapLink') > 0;
    }

    public function hasDeathLink():Bool {
        return has('DeathLink');
    }

    public function hasTrapLink():Bool {
        return has('TrapLink');
    }

    /**
     * Sync the internal tags array to the client
     * This is called automatically by other methods, but can be called manually if needed
     */
    public function syncToClient():Void {
        if (client != null) {
            client.set_tags(_tags.copy());
            trace('APTagsManager: Synced ${_tags.length} tags to client');
        } else {
            trace('APTagsManager: Warning - Client is null, cannot sync tags');
        }
    }

    // public function emergencySync():Void {
    //     // Only sync if tags differ between manager and client
    //     if (client != null) {
    //         var clientTags = client.tags != null ? client.tags : [];
    //         var tagsMatch = _tags.length == clientTags.length && _tags.map(function(tag, i) return tag == clientTags[i]);
    //         if (!tagsMatch) {
    //             syncToClient();
    //             trace('APTagsManager: Emergency sync performed (tags differed)');
    //         } else {
    //             trace('APTagsManager: Emergency sync skipped (tags already match)');
    //         }
    //     } else {
    //         trace('APTagsManager: Emergency sync failed (client is null)');
    //     }
    // }

    /**
     * Sync from the client to update internal state
     * Call this if the client's tags were modified externally
     */
    public function syncFromClient():Void {
        if (client != null && client.tags != null) {
            _tags = client.tags.copy();
            trace('APTagsManager: Synced ${_tags.length} tags from client');
        } else {
            trace('APTagsManager: Warning - Client or client tags are null, cannot sync from client');
        }
    }

    /**
     * Get a string representation of the current tags
     */
    public function toString():String {
        return 'APTagsManager[${_tags.join(", ")}]';
    }

    /**
     * Create a tags manager with default AP tags
     * @param client The client to manage
     * @return A new APTagsManager with default tags set
     */
    public static function createWithDefaults(client:Client):APTagsManager {
        var manager = new APTagsManager(client);
        manager.set(['AP', 'Testing']);
        return manager;
    }

    /**
     * Create a tags manager and preserve existing client tags
     * @param client The client to manage
     * @return A new APTagsManager with existing tags preserved
     */
    public static function createFromExisting(client:Client):APTagsManager {
        var manager = new APTagsManager(client);
        manager.syncFromClient();
        return manager;
    }
}
