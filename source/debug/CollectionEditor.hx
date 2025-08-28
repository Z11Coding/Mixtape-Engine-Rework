package debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

/**
 * Specialized editor for arrays and maps
 */
class CollectionEditor extends FlxSubState {
    private var backgroundPanel:FlxSprite;
    private var titleText:FlxText;
    private var itemList:FlxTypedGroup<FlxText>;
    private var buttonList:FlxTypedGroup<FlxButton>;
    private var scrollOffset:Int = 0;
    private var maxVisibleItems:Int = 15;

    private var collection:Dynamic;
    private var collectionType:String; // "array" or "map"
    private var parentObject:Dynamic;
    private var propertyName:String;
    private var onClose:Void->Void;

    public function new(collection:Dynamic, collectionType:String, parentObject:Dynamic, propertyName:String, ?onClose:Void->Void) {
        this.collection = collection;
        this.collectionType = collectionType;
        this.parentObject = parentObject;
        this.propertyName = propertyName;
        this.onClose = onClose;
        super();
    }

    override public function create():Void {
        super.create();

        // Create semi-transparent background
        backgroundPanel = new FlxSprite(50, 50);
        backgroundPanel.makeGraphic(FlxG.width - 100, FlxG.height - 100, FlxColor.fromRGB(0, 0, 0, 200));
        add(backgroundPanel);

        // Create title
        titleText = new FlxText(60, 60, FlxG.width - 120, 'Editing ${collectionType}: ${propertyName}', 16);
        titleText.color = FlxColor.WHITE;
        add(titleText);

        // Create item list group
        itemList = new FlxTypedGroup<FlxText>();
        add(itemList);

        // Create button list group
        buttonList = new FlxTypedGroup<FlxButton>();
        add(buttonList);

        updateDisplay();
    }

    private function updateDisplay():Void {
        // Clear existing items
        itemList.clear();
        buttonList.clear();

        var yPos:Float = 90;
        var items:Array<Dynamic> = [];
        var keys:Array<String> = [];

        // Get items based on collection type
        if (collectionType == "array") {
            var arr:Array<Dynamic> = cast collection;
            for (i in 0...arr.length) {
                items.push(arr[i]);
                keys.push(Std.string(i));
            }
        } else if (collectionType == "map") {
            var map:Map<Dynamic, Dynamic> = cast collection;
            for (key in map.keys()) {
                items.push(map.get(key));
                keys.push(Std.string(key));
            }
        }

        // Add close button
        var closeButton = new FlxButton(FlxG.width - 120, 60, "Close", function() {
            if (onClose != null) onClose();
            close();
        });
        closeButton.color = FlxColor.RED;
        buttonList.add(closeButton);

        // Add new item button
        var addButton = new FlxButton(60, yPos, "Add Item", function() {
            addNewItem();
        });
        addButton.color = FlxColor.GREEN;
        buttonList.add(addButton);
        yPos += 30;

        // Show items with scroll
        for (i in scrollOffset...Std.int(Math.min(items.length, scrollOffset + maxVisibleItems))) {
            var key = keys[i];
            var value = items[i];
            var valueStr = getValueString(value);

            // Item display
            var itemText = new FlxText(60, yPos, 400, '${key}: ${valueStr}', 12);
            itemText.color = FlxColor.WHITE;
            itemList.add(itemText);

            // Edit button
            var editButton = new FlxButton(470, yPos, "Edit", function() {
                editItem(key, value);
            });
            editButton.scale.set(0.8, 0.8);
            editButton.updateHitbox();
            buttonList.add(editButton);

            // Delete button
            var deleteButton = new FlxButton(520, yPos, "Del", function() {
                deleteItem(key);
            });
            deleteButton.color = FlxColor.ORANGE;
            deleteButton.scale.set(0.8, 0.8);
            deleteButton.updateHitbox();
            buttonList.add(deleteButton);

            yPos += 25;
        }

        // Scroll indicators
        if (scrollOffset > 0) {
            var upText = new FlxText(FlxG.width - 150, 100, 80, "↑ More above", 12);
            upText.color = FlxColor.CYAN;
            itemList.add(upText);
        }

        if (scrollOffset + maxVisibleItems < items.length) {
            var downText = new FlxText(FlxG.width - 150, FlxG.height - 120, 80, "↓ More below", 12);
            downText.color = FlxColor.CYAN;
            itemList.add(downText);
        }
    }

    private function getValueString(value:Dynamic):String {
        if (value == null) return "null";

        switch (Type.typeof(value)) {
            case TBool: return Std.string(value);
            case TInt: return Std.string(value);
            case TFloat: return Std.string(value);
            case TClass(String): return '"${value}"';
            case TClass(Array):
                var arr:Array<Dynamic> = cast value;
                return 'Array[${arr.length}]';
            case TObject: return "Object{}";
            case TClass(c):
                var className = Type.getClassName(c);
                return className.split('.').pop();
            default: return Std.string(value);
        }
    }

    private function addNewItem():Void {
        if (collectionType == "array") {
            var arr:Array<Dynamic> = cast collection;
            arr.push(null); // Add null item
            updateDisplay();
            trace('Added new item to array at index ${arr.length - 1}');
        } else if (collectionType == "map") {
            // For maps, we need a key - use simple string key
            var map:Map<Dynamic, Dynamic> = cast collection;
            var newKey = "newKey" + Date.now().getTime();
            map.set(newKey, null);
            updateDisplay();
            trace('Added new item to map with key: ${newKey}');
        }
    }

    private function editItem(key:String, currentValue:Dynamic):Void {
        // Simple value editing - cycle through common values for now
        var newValue:Dynamic = currentValue;

        switch (Type.typeof(currentValue)) {
            case TBool:
                newValue = !cast(currentValue, Bool);
            case TInt:
                var intVal:Int = cast currentValue;
                newValue = intVal + 1; // Increment by 1
            case TFloat:
                var floatVal:Float = cast currentValue;
                newValue = floatVal + 0.1; // Increment by 0.1
            case TClass(String):
                newValue = cast(currentValue, String) + "_edited";
            case TNull:
                newValue = 0; // Set to default value
            default:
                trace('Cannot edit value of type: ${Type.typeof(currentValue)}');
                return;
        }

        // Update the collection
        if (collectionType == "array") {
            var arr:Array<Dynamic> = cast collection;
            var index = Std.parseInt(key);
            if (index != null && index >= 0 && index < arr.length) {
                arr[index] = newValue;
            }
        } else if (collectionType == "map") {
            var map:Map<Dynamic, Dynamic> = cast collection;
            map.set(key, newValue);
        }

        updateDisplay();
        trace('Changed ${key} from ${currentValue} to ${newValue}');
    }

    private function deleteItem(key:String):Void {
        if (collectionType == "array") {
            var arr:Array<Dynamic> = cast collection;
            var index = Std.parseInt(key);
            if (index != null && index >= 0 && index < arr.length) {
                arr.splice(index, 1);
            }
        } else if (collectionType == "map") {
            var map:Map<Dynamic, Dynamic> = cast collection;
            map.remove(key);
        }

        updateDisplay();
        trace('Deleted item: ${key}');
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Handle input
        if (FlxG.keys.justPressed.ESCAPE) {
            if (onClose != null) onClose();
            close();
        }

        if (FlxG.keys.justPressed.UP) {
            scrollOffset = Std.int(Math.max(0, scrollOffset - 1));
            updateDisplay();
        }

        if (FlxG.keys.justPressed.DOWN) {
            var totalItems = collectionType == "array" ?
                cast(collection, Array<Dynamic>).length :
                Lambda.count(cast(collection, Map<Dynamic, Dynamic>));
            scrollOffset = Std.int(Math.min(totalItems - maxVisibleItems, scrollOffset + 1));
            updateDisplay();
        }
    }
}
