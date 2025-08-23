package backend.ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import backend.Paths;
import backend.ui.PsychUISlider;
import backend.ui.PsychUIInputText;
import backend.ui.PsychUIEventHandler;
import games.uno.backend.UnoCard.UnoColor;

/**
 * PsychUIColorPicker - A simplified color picker component for PsychUI
 * Allows picking colors with RGB sliders and hex input
 */
class PsychUIColorPicker extends FlxSpriteGroup
{
    public static final CHANGE_EVENT = "colorpicker_change";
    
    // Visual components
    public var bg:FlxSprite;
    public var colorPreview:FlxSprite;
    public var labelText:FlxText;
    
    // RGB Sliders
    public var redSlider:PsychUISlider;
    public var greenSlider:PsychUISlider;
    public var blueSlider:PsychUISlider;
    
    // Input field for hex
    public var hexInput:PsychUIInputText;
    
    // Letter input for UNO color
    public var letterInput:PsychUIInputText;
    
    // Current color values
    public var currentColor(default, set):FlxColor = FlxColor.WHITE;
    public var currentUnoColor:UnoColor;
    
    // Callbacks
    public var onColorChange:UnoColor->Void;
    public var broadcastColorEvent:Bool = true;
    
    // Layout constants
    private static inline var PREVIEW_SIZE:Int = 40;
    
    public function new(x:Float = 0, y:Float = 0, ?initialColor:UnoColor = null)
    {
        super(x, y);
        
        setupVisuals();
        setupSliders();
        setupInputs();
        
        if (initialColor != null)
            setFromUnoColor(initialColor);
        else
            setFromUnoColor(UnoColor.CUSTOM(FlxColor.RED, "R"));
    }
    
    private function setupVisuals():Void
    {
        // Background
        bg = new FlxSprite().makeGraphic(160, 180, FlxColor.fromRGBFloat(0.2, 0.2, 0.2, 0.8));
        add(bg);
        
        // Color preview
        colorPreview = new FlxSprite(10, 10).makeGraphic(PREVIEW_SIZE, PREVIEW_SIZE, FlxColor.WHITE);
        add(colorPreview);
        
        // Label
        labelText = new FlxText(60, 15, 90, "Color Picker", 10);
        labelText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, LEFT);
        add(labelText);
    }
    
    private function setupSliders():Void
    {
        var sliderY = 60;
        
        redSlider = new PsychUISlider(10, sliderY, function(v:Float) {
            updateFromRGB();
        }, 255, 0, 255, 130, FlxColor.RED, FlxColor.WHITE);
        redSlider.decimals = 0;
        redSlider.label = "R:";
        add(redSlider);
        
        greenSlider = new PsychUISlider(10, sliderY + 25, function(v:Float) {
            updateFromRGB();
        }, 255, 0, 255, 130, FlxColor.GREEN, FlxColor.WHITE);
        greenSlider.decimals = 0;
        greenSlider.label = "G:";
        add(greenSlider);
        
        blueSlider = new PsychUISlider(10, sliderY + 50, function(v:Float) {
            updateFromRGB();
        }, 255, 0, 255, 130, FlxColor.BLUE, FlxColor.WHITE);
        blueSlider.decimals = 0;
        blueSlider.label = "B:";
        add(blueSlider);
    }
    
    private function setupInputs():Void
    {
        var inputY = 150;
        
        // Hex input
        var hexLabel = new FlxText(10, inputY, 30, "Hex:", 8);
        hexLabel.setFormat(Paths.font("vcr.ttf"), 8, FlxColor.WHITE, LEFT);
        add(hexLabel);
        
        hexInput = new PsychUIInputText(45, inputY - 2, 60, "FF0000", 8);
        hexInput.onChange = function(text:String, action:String) {
            updateFromHex();
        };
        add(hexInput);
        
        // Letter input for UNO color
        var letterLabel = new FlxText(110, inputY, 30, "Letter:", 8);
        letterLabel.setFormat(Paths.font("vcr.ttf"), 8, FlxColor.WHITE, LEFT);
        add(letterLabel);
        
        letterInput = new PsychUIInputText(135, inputY - 2, 20, "R", 8);
        letterInput.onChange = function(text:String, action:String) {
            updateLetter();
        };
        add(letterInput);
    }
    
    private function updateFromRGB():Void
    {
        var r = Std.int(redSlider.value);
        var g = Std.int(greenSlider.value);
        var b = Std.int(blueSlider.value);
        
        currentColor = FlxColor.fromRGB(r, g, b);
        updateHexInput();
        updateColorPreview();
        notifyColorChange();
    }
    
    private function updateFromHex():Void
    {
        try
        {
            var hexText = hexInput.text;
            if (!hexText.startsWith("#"))
                hexText = "#" + hexText;
            
            currentColor = FlxColor.fromString(hexText);
            updateRGBSliders();
            updateColorPreview();
            notifyColorChange();
        }
        catch (e:Dynamic)
        {
            // Invalid hex input, revert to current color
            updateHexInput();
        }
    }
    
    private function updateLetter():Void
    {
        if (letterInput.text.length > 0)
        {
            notifyColorChange();
        }
    }
    
    private function updateRGBSliders():Void
    {
        redSlider.value = currentColor.red;
        greenSlider.value = currentColor.green;
        blueSlider.value = currentColor.blue;
    }
    
    private function updateHexInput():Void
    {
        hexInput.text = currentColor.toHexString().substr(2); // Remove "0x" prefix
    }
    
    private function updateColorPreview():Void
    {
        colorPreview.color = currentColor;
    }
    
    private function notifyColorChange():Void
    {
        // Create UnoColor with current color and letter
        var letter = letterInput.text.length > 0 ? letterInput.text.charAt(0).toUpperCase() : "X";
        currentUnoColor = UnoColor.CUSTOM(currentColor, letter);
        
        if (onColorChange != null)
            onColorChange(currentUnoColor);
            
        if (broadcastColorEvent)
            PsychUIEventHandler.event(CHANGE_EVENT, this);
    }
    
    public function setFromUnoColor(unoColor:UnoColor):Void
    {
        switch(unoColor)
        {
            case CUSTOM(color, letter):
                currentColor = color;
                letterInput.text = letter;
            case RED:
                currentColor = FlxColor.RED;
                letterInput.text = "R";
            case BLUE:
                currentColor = FlxColor.BLUE;
                letterInput.text = "B";
            case GREEN:
                currentColor = FlxColor.GREEN;
                letterInput.text = "G";
            case YELLOW:
                currentColor = FlxColor.YELLOW;
                letterInput.text = "Y";
            case WILD:
                currentColor = FlxColor.BLACK;
                letterInput.text = "W";
        }
        
        currentUnoColor = unoColor;
        
        // Update all UI elements
        updateRGBSliders();
        updateHexInput();
        updateColorPreview();
    }
    
    function set_currentColor(color:FlxColor):FlxColor
    {
        currentColor = color;
        updateColorPreview();
        return color;
    }
}
