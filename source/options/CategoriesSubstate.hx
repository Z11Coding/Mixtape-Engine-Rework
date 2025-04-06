package options;

import objects.AttachedText;
import objects.CheckboxThingie;
import options.GameplayChangersSubstate.GameplayOption;

import archipelago.APEntryState;
import objects.AttachedText;
import objects.CheckboxThingie;
import objects.Note;

import options.Option.OptionType;

class CategoriesSubstate extends MusicBeatSubstate
{
	private var curSelected:Int = 0;
	private var optionsArray:Array<Dynamic> = [];

    private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;


	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var curOption(get, never):GameplayOption;
	function get_curOption() return optionsArray[curSelected];

    function getOptions()
    {
        var option:GameplayOption = new GameplayOption('Show Mods as Categories', 'showMods', BOOL, false);

        option.setValue(ClientPrefs.data.showMods);

        // option.description = 'Show mods as categories in the mod menu.';

        option.onChange = function actuallyChangeFucker()
        {
            ClientPrefs.data.showMods = option.getValue();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }; // Because for some unknonw reason, this isn't changing it automatically...


        optionsArray.push(option);
    }

	public function getOptionByName(name:String)
        {
            for(i in optionsArray)
            {
                var opt:GameplayOption = i;
                if (opt.name == name)
                    return opt;
            }
            return null;
        }
    
        public function new()
        {
            super();
            
            var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
            bg.alpha = 0.6;
            add(bg);
    
            // avoids lagspikes while scrolling through menus!
            grpOptions = new FlxTypedGroup<Alphabet>();
            add(grpOptions);
    
            grpTexts = new FlxTypedGroup<AttachedText>();
            add(grpTexts);
    
            checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
            add(checkboxGroup);
            
            getOptions();
    
            for (i in 0...optionsArray.length)
            {
                var optionText:Alphabet = new Alphabet(150, 360, optionsArray[i].name, true);
                optionText.isMenuItem = true;
                optionText.setScale(0.8);
                optionText.targetY = i;
                grpOptions.add(optionText);
    
                if(optionsArray[i].type == BOOL)
                {
                    optionText.x += 60;
                    optionText.startPosition.x += 60;
                    optionText.snapToPosition();
                    var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
                    checkbox.sprTracker = optionText;
                    checkbox.offsetX -= 20;
                    checkbox.offsetY = -52;
                    checkbox.ID = i;
                    checkboxGroup.add(checkbox);
                }
                else
                {
                    optionText.snapToPosition();
                    var valueText:AttachedText = new AttachedText(Std.string(optionsArray[i].getValue()), optionText.width + 40, 0, true, 0.8);
                    valueText.sprTracker = optionText;
                    valueText.copyAlpha = true;
                    valueText.ID = i;
                    grpTexts.add(valueText);
                    optionsArray[i].setChild(valueText);
                }
                updateTextFrom(optionsArray[i]);
            }
    
            changeSelection();
            reloadCheckboxes();
        }
    
        var nextAccept:Int = 5;
        var holdTime:Float = 0;
        var holdValue:Float = 0;
        override function update(elapsed:Float)
        {
            if (controls.UI_UP_P)
                changeSelection(-1);
    
            if (controls.UI_DOWN_P)
                changeSelection(1);
    
            if (controls.BACK)
            {
                close();
                ClientPrefs.saveSettings();
                FlxG.sound.play(Paths.sound('cancelMenu'));
            }
    
            if(nextAccept <= 0)
            {
                var usesCheckbox:Bool = (curOption.type == BOOL);
                if(usesCheckbox)
                {
                    if(controls.ACCEPT)
                    {
                        FlxG.sound.play(Paths.sound('scrollMenu'));
                        curOption.setValue((curOption.getValue() == true) ? false : true);
                        curOption.change();
                        reloadCheckboxes();
                    }
                }
                else
                {
                    if(controls.UI_LEFT || controls.UI_RIGHT)
                    {
                        var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
                        if(holdTime > 0.5 || pressed)
                        {
                            if(pressed)
                            {
                                var add:Dynamic = null;
                                if(curOption.type != STRING)
                                    add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
    
                                switch(curOption.type)
                                {
                                    case INT, FLOAT, PERCENT:
                                        holdValue = curOption.getValue() + add;
                                        if(holdValue < curOption.minValue) holdValue = curOption.minValue;
                                        else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
    
                                        switch(curOption.type)
                                        {
                                            case INT:
                                                holdValue = Math.round(holdValue);
                                                curOption.setValue(holdValue);
    
                                            case FLOAT, PERCENT:
                                                holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
                                                curOption.setValue(holdValue);
    
                                            default:
                                        }
    
                                    case STRING:
                                        var num:Int = curOption.curOption; //lol
                                        if(controls.UI_LEFT_P) --num;
                                        else num++;
    
                                        if(num < 0)
                                            num = curOption.options.length - 1;
                                        else if(num >= curOption.options.length)
                                            num = 0;
    
                                        curOption.curOption = num;
                                        curOption.setValue(curOption.options[num]); //lol
                                        
                                        if (curOption.name == "Scroll Type")
                                        {
                                            var oOption:GameplayOption = getOptionByName("Scroll Speed");
                                            if (oOption != null)
                                            {
                                                if (curOption.getValue() == "constant")
                                                {
                                                    oOption.displayFormat = "%v";
                                                    oOption.maxValue = 6;
                                                }
                                                else
                                                {
                                                    oOption.displayFormat = "%vX";
                                                    oOption.maxValue = 3;
                                                    if(oOption.getValue() > 3) oOption.setValue(3);
                                                }
                                                updateTextFrom(oOption);
                                            }
                                        }
                                        //trace(curOption.options[num]);
    
                                    default:
                                }
                                updateTextFrom(curOption);
                                curOption.change();
                                FlxG.sound.play(Paths.sound('scrollMenu'));
                            }
                            else if(curOption.type != STRING)
                            {
                                holdValue = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));
    
                                switch(curOption.type)
                                {
                                    case INT:
                                        curOption.setValue(Math.round(holdValue));
                                    
                                    case FLOAT, PERCENT:
                                        var blah:Float = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.changeValue - (holdValue % curOption.changeValue)));
                                        curOption.setValue(FlxMath.roundDecimal(blah, curOption.decimals));
    
                                    default:
                                }
                                updateTextFrom(curOption);
                                curOption.change();
                            }
                        }
    
                        if(curOption.type != STRING)
                            holdTime += elapsed;
                    }
                    else if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
                        clearHold();
                }
    
                if(controls.RESET)
                {
                    for (i in 0...optionsArray.length)
                    {
                        var leOption:GameplayOption = optionsArray[i];
                        leOption.setValue(leOption.defaultValue);
                        if(leOption.type != BOOL)
                        {
                            if(leOption.type == STRING)
                                leOption.curOption = leOption.options.indexOf(leOption.getValue());
    
                            updateTextFrom(leOption);
                        }
    
                        if(leOption.name == 'Scroll Speed')
                        {
                            leOption.displayFormat = "%vX";
                            leOption.maxValue = 3;
                            if(leOption.getValue() > 3)
                                leOption.setValue(3);
    
                            updateTextFrom(leOption);
                        }
                        leOption.change();
                    }
                    FlxG.sound.play(Paths.sound('cancelMenu'));
                    reloadCheckboxes();
                }
            }
    
            if(nextAccept > 0) {
                nextAccept -= 1;
            }
            super.update(elapsed);
        }
    
        function updateTextFrom(option:GameplayOption) {
            var text:String = option.displayFormat;
            var val:Dynamic = option.getValue();
            if(option.type == PERCENT) val *= 100;
            var def:Dynamic = option.defaultValue;
            option.text = text.replace('%v', val).replace('%d', def);
        }
    
        function clearHold()
        {
            if(holdTime > 0.5)
                FlxG.sound.play(Paths.sound('scrollMenu'));
    
            holdTime = 0;
        }
        
        function changeSelection(change:Int = 0)
        {
            curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);
            for (num => item in grpOptions.members)
            {
                item.targetY = num - curSelected;
                item.alpha = 0.6;
                if (item.targetY == 0)
                    item.alpha = 1;
            }
            for (text in grpTexts)
            {
                text.alpha = 0.6;
                if(text.ID == curSelected)
                    text.alpha = 1;
            }
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
    
        function reloadCheckboxes() {
            for (checkbox in checkboxGroup) {
                checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
            }
        }
    }
    