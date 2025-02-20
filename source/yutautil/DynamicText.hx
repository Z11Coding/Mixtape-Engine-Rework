package utils;

import flixel.text.FlxText;
import flixel.FlxG;

class DynamicText extends FlxText {
    private var originalText:String;
    private var preserveType:Bool;

    public function new(X:Float, Y:Float, Width:Int, Text:String, PreserveType:Bool = false) {
        super(X, Y, Width, Text);
        this.originalText = Text;
        this.preserveType = PreserveType;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        this.text = getRandomizedText();
    }

    private function getRandomizedText():String {
        var randomizedText:String = '';
        for (i in 0...originalText.length) {
            var char = originalText.charAt(i);
            if (preserveType) {
                if (isLetter(char)) {
                    randomizedText += getRandomLetter();
                } else if (isNumber(char)) {
                    randomizedText += getRandomNumber();
                } else if (isSymbol(char)) {
                    randomizedText += getRandomSymbol();
                }
            } else {
                randomizedText += getRandomCharacter();
            }
        }
        return randomizedText;
    }

    private function isLetter(char:String):Bool {
        return char >= 'A' && char <= 'Z' || char >= 'a' && char <= 'z';
    }

    private function isNumber(char:String):Bool {
        return char >= '0' && char <= '9';
    }

    private function isSymbol(char:String):Bool {
        return !isLetter(char) && !isNumber(char);
    }

    private function getRandomLetter():String {
        var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
        return letters.charAt(FlxG.random.int(0, letters.length - 1));
    }

    private function getRandomNumber():String {
        var numbers = "0123456789";
        return numbers.charAt(FlxG.random.int(0, numbers.length - 1));
    }

    private function getRandomSymbol():String {
        var symbols = "!@#$%^&*()-_=+[]{}|;:'\",.<>?/`~";
        return symbols.charAt(FlxG.random.int(0, symbols.length - 1));
    }

    private function getRandomCharacter():String {
        var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{}|;:'\",.<>?/`~";
        return characters.charAt(FlxG.random.int(0, characters.length - 1));
    }
}