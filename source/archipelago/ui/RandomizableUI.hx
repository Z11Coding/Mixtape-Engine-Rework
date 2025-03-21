package archipelago.ui;

import backend.ui.*;
import flixel.group.FlxGroup;
import flixel.text.FlxText;

typedef RandomizableOption = flixel.util.typeLimit.OneOfThree<RandomizableDropDownMenu, RandomizableCheckBox, RandomizableSlider>;

class RandomizableDropDownMenu extends PsychUIDropDownMenu {
    public var randomCheckbox:PsychUICheckBox;

    public function new(x:Int, y:Int, options:Array<String>, callback:(Int, String)->Void) {
        super(x, y, options, callback);
    }

    public function attachRandomCheckbox(tab_group:FlxSpriteGroup, label:String, objX:Int, objY:Int, onRandomChange:Void->Void) {
        randomCheckbox = new PsychUICheckBox(objX + 150, objY, "Random", 100, function() {
            this.alpha = randomCheckbox.checked ? 0.5 : 1; // Make transparent if random is selected
            onRandomChange();
        });
        randomCheckbox.checked = false;
        tab_group.add(new FlxText(randomCheckbox.x, randomCheckbox.y - 15, 120, label + " Random:"));
        tab_group.add(randomCheckbox);
    }
}

class RandomizableCheckBox extends PsychUICheckBox {
    public var randomCheckbox:PsychUICheckBox;

    public function new(x:Int, y:Int, label:String, width:Int, callback:Void->Void) {
        super(x, y, label, width, callback);
    }

    public function attachRandomCheckbox(tab_group:FlxSpriteGroup, label:String, objX:Int, objY:Int, onRandomChange:Void->Void) {
        randomCheckbox = new PsychUICheckBox(objX + 150, objY, "Random", 100, function() {
            this.alpha = randomCheckbox.checked ? 0.5 : 1; // Make transparent if random is selected
            onRandomChange();
        });
        randomCheckbox.checked = false;
        tab_group.add(new FlxText(randomCheckbox.x, randomCheckbox.y - 15, 120, label + " Random:"));
        tab_group.add(randomCheckbox);
    }
}

class RandomizableSlider extends PsychUISlider {
    public var randomCheckbox:PsychUICheckBox;

    public function new(x:Int, y:Int, callback:Dynamic->Void) {
        super(x, y, callback);
    }

    public function attachRandomCheckbox(tab_group:FlxSpriteGroup, label:String, objX:Int, objY:Int, onRandomChange:Void->Void) {
        randomCheckbox = new PsychUICheckBox(objX + 150, objY, "Random", 100, function() {
            this.alpha = randomCheckbox.checked ? 0.5 : 1; // Make transparent if random is selected
            onRandomChange();
        });
        randomCheckbox.checked = false;
        tab_group.add(new FlxText(randomCheckbox.x, randomCheckbox.y - 15, 120, label + " Random:"));
        tab_group.add(randomCheckbox);
    }
}
