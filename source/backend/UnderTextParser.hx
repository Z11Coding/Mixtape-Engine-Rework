package backend;

import openfl.utils.ObjectPool;
import flixel.addons.text.FlxTypeText;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;

abstract Char(String) {
    public inline function get_char():String {
        return this;
    }
    public function new(char:String) {
        this = char;
        if (char.length > 1) {
            throw "Char must be a single character.";
        }
    }
}

// enum TextOperator {
//     NewLine = '\n',
//     Tab = '\t',
//     CarriageReturn = '\r'
// };

class UnderTextParser extends FlxTypeText {
    private var speed:Float;
    private var defaultSpeed:Float;
    private var pauseDuration:Float;
    private var _formattingLocations:Map<Int, Void->Void>;
    public var isTyping:Bool = false;
    public var autoskip:Bool = false;
    public var nextMenu:String = '';
    public var typingSound:FlxSound;
    public var soundOnChars:Map<String, FlxSound>;
    public var soundlessChars:Array<String> = [' ', '\n', '\t', '\r'];

    public function new(X:Float, Y:Float, Width:Int, Text:String, Size:Int = 8, EmbeddedFont:Bool = true, Speed:Float = 0.05) {
        super(X, Y, Width, "", Size, EmbeddedFont);
        this._finalText = processText(Text);
        this.defaultSpeed = Speed;
        this.speed = Speed;
        this.pauseDuration = 0;
        soundOnChars = new Map<String, FlxSound>();
    }

    public function doSkip()
    {
        skip();
    }

    override public function update(elapsed:Float):Void {
        //if (_waiting || paused) return;
        if (sounds != null) sounds = [];
        useDefaultSound = false;

        for (char in soundOnChars.keys()) {
            if (char.length > 1) {
                throw "soundOnChar key must be a single character.";
            }
        }

        for (char in soundlessChars) {
            if (char.length > 1) {
                throw "soundlessChars element must be a single character.";
            }
        }

        if (typingSound != null)
            if (sounds.indexOf(typingSound) == -1)
                sounds.push(typingSound);



        for (index in _formattingLocations.keys()) {
            if (_length == index) {
                var value:Void->Void = _formattingLocations.get(index);
                value();
            }
        }

        // for (sound in sounds)
        // {
        //     if (sound != null && sound.playing && _finalText.charAt(_length) == ' ')
        //     {
        //         sound.pause();
        //     }
        // }

        for (sound in soundOnChars.keys())
        {
            if (soundOnChars.get(sound) != null && _finalText.charAt(_length).toLowerCase() == sound)
            {
                soundOnChars.get(sound).play();
            }
            else {
                if (typingSound != null) typingSound.play();
            }
        }

        for (i in 0...soundlessChars.length)
        {
            if (soundlessChars != null && _finalText.charAt(_length) == soundlessChars[i])
            {
                soundOnChars.mapT(sound -> sound.pause());
                if (typingSound != null) typingSound.pause();
            }
        }

        delay = speed;  

        if (pauseDuration > 0) {
            pauseDuration -= elapsed;
            paused = true;
            return;
        }

        if (pauseDuration <= 0) {
            paused = false;
            pauseDuration = 0;
        }

        if (_length < _finalText.length && _typing) {
            _timer += elapsed;
        }

        if (_length > 0 && _erasing) {
            _timer += elapsed;
        }

        isTyping = _typing;

        if ((_typing || _erasing) && !paused) {
            if (_typing && _timer >= speed) {
                _length += Std.int(_timer / speed);
                if (_length > _finalText.length) _length = _finalText.length;
                _timer = 0;
            }

            if (_erasing && _timer >= speed) {
                _length -= Std.int(_timer / speed);
                if (_length < 0) _length = 0;
                _timer = 0;
            }

            if ((_typing && _timer >= speed) || (_erasing && _timer >= speed)) {
                _timer = 0;
            }
        }

        super.update(elapsed);
    }

    private function processText(text:String):String {
        var formattingLocations:Map<Int, Void->Void> = new Map<Int, Void->Void>();
        var result:String = "";
        var i:Int = 0;
        var offset:Int = 0; // to keep track of the offset caused by tag removal
        nextMenu = '';
        autoskip = false;
    
        while (i < text.length) {
            if (text.charAt(i) == '[') {
                var endTag:Int = text.indexOf(']', i);
                if (endTag != -1) {
                    var tag:String = text.substring(i, endTag + 1);
                    var splitResult = PatternSplitter.splitWithPattern(tag);
                    if (splitResult.brackets == '[]') {
                        var parts:Array<String> = splitResult.partsArray;
                        switch (parts[0]) {
                            case 'slow':
                                var slowSpeed:Float = Std.parseFloat(parts[2]);
                                if (!Math.isNaN(slowSpeed)) {
                                    formattingLocations.set(result.length, function() {
                                        speed = defaultSpeed + slowSpeed;
                                    });
                                }
                            case 'fast':
                                var fastSpeed:Float = Std.parseFloat(parts[2]);
                                if (!Math.isNaN(fastSpeed)) {
                                    formattingLocations.set(result.length, function() {
                                        if ((defaultSpeed - fastSpeed) > 0) speed = defaultSpeed - fastSpeed;
                                        else trace('Your speed is too fast!');
                                    });
                                }
                            case 'set':
                                var setSpeed:Float = Std.parseFloat(parts[2]);
                                if (!Math.isNaN(setSpeed)) {
                                    formattingLocations.set(result.length, function() {
                                        speed = setSpeed;
                                    });
                                }
                            case 'pause':
                                var pDuration:Float = Std.parseFloat(parts[2]);
                                if (!Math.isNaN(pDuration)) {
                                    formattingLocations.set(result.length, function() {
                                        pauseDuration = pDuration;
                                        _length++;
                                    });
                                }
                            case 'sfx':
                                var daSound:String = parts[2];
                                if (daSound != '') {
                                    formattingLocations.set(result.length, function() {
                                        FlxG.sound.play(Paths.sound(daSound));
                                    });
                                }
                            case 'username':
                                var backup:String = parts[2];
                                if (backup != '') {
                                    formattingLocations.set(result.length, function() {
                                        if (ClientPrefs.data.username) result += Sys.environment()["USERNAME"];
                                        else result += backup;
                                    });
                                }
                            case 'color':
                                var daColor:String = parts[2];
                                if (daColor != '') {
                                    formattingLocations.set(result.length, function() {
                                        color = FlxColor.fromString('#$daColor');
                                    });
                                }
                            case 'pitch':
                                var daPitch:Float = Std.parseFloat(parts[2]);
                                if (!Math.isNaN(daPitch)) {
                                    formattingLocations.set(result.length, function() {
                                        FlxG.sound.music.pitch = daPitch;
                                    });
                                }
                            case 'tpitch':
                                var daPitch:Float = Std.parseFloat(parts[2]);
                                if (!Math.isNaN(daPitch)) {
                                    formattingLocations.set(result.length, function() {
                                        FlxTween.num(FlxG.sound.music.pitch, daPitch, 2, {ease: FlxEase.expoOut}, function(num)
                                        {
                                            FlxG.sound.music.pitch = num;
                                        });
                                    });
                                }
                            case 'mpause':
                                formattingLocations.set(result.length, function() {
                                    FlxG.sound.music.pause();
                                });
                            case 'mplay':
                                formattingLocations.set(result.length, function() {
                                    FlxG.sound.music.play();
                                });
                            case 'playS':
                                var daSong:String = parts[2];
                                if (daSong != '') {
                                    formattingLocations.set(result.length, function() {
                                        FlxG.sound.playMusic(Paths.music(daSong));
                                    });
                                }
                            case 'instant':
                                formattingLocations.set(result.length, function() {
                                    skip();
                                });
                            case 'next':
                                formattingLocations.set(result.length, function() {
                                    autoskip = true;
                                });
                            case 'reset':
                                formattingLocations.set(result.length, function() {
                                    speed = defaultSpeed;
                                    pauseDuration = 0;
                                });
                            case 'nextmenu':
                                var daMenu:String = parts[2];
                                if (daMenu != '') {
                                    formattingLocations.set(result.length, function() {
                                        nextMenu = daMenu;
                                    });
                                }
                            default:
                                trace("Unknown tag: " + parts[0]);
                        }
                        i = endTag + 1;
                        continue;
                    }
                }
            }
            result += text.charAt(i);
            i++;
        }
    
        // Update the remaining indices in formattingLocations
        var updatedLocations:Map<Int, Void->Void> = new Map<Int, Void->Void>();
        for (index in formattingLocations.keys()) {
            var newIndex:Int = index - offset;
            var value:Void->Void = formattingLocations.get(index);
            updatedLocations.set(newIndex, value);
        }
        formattingLocations = updatedLocations;
    
        _formattingLocations = formattingLocations;
        return result;
    }

    public function addSoundOnChar(char:String, sound:FlxSound):Void {
        soundOnChars.set(char, sound);
    }

    public override function resetText(text:String):Void {
        _finalText = processText(text);
        super.resetText(_finalText);
    }

    private function reactFunction():Void {
        // Code to react when typedText reaches the specified location
    }
}

class PatternSplitter {
    public static function splitWithPattern(input:String):Dynamic {
        var partsArray:Array<String> = [];
        var brackets:String = '';

        // Regular expression to match the pattern [tag:value]
        var pattern:EReg = ~/^\[(\w+):(\w+(\.\w+)?)\]$/;

        if (pattern.match(input)) {
            var tag:String = pattern.matched(1);
            var value:String = pattern.matched(2);

            trace(tag);
            trace(value);

            partsArray.push(tag);
            partsArray.push(':');
            partsArray.push(value);

            brackets = '[]';
        }

        return { partsArray: partsArray, brackets: brackets };
    }
}
