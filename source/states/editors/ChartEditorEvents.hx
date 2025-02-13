package states.editors;

class ChartEditorEvents {
    public static var Events:haxe.ds.IntMap<Map<String, String>> = [
        1 => ['' => "Nothing. Yep, that's right."],
        2 => ['Dadbattle Spotlight' => "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"],
        3 => ['Hey!' => "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2:  animation duration,\nleave it blank for 0.6s"],
        4 => ['Set GF Speed' => "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
        5 => ['Philly Glow' => "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."],
        6 => ['Kill Henchmen' => "For Mom's songs, don't use this please, i love them :("],
        7 => ['Add Camera Zoom' => "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
        8 => ['BG Freaks Expression' => "Should be used only in \"school\" Stage!"],
        9 => ['Trigger BG Ghouls' => "Should be used only in \"schoolEvil\" Stage!"],
        10 => ['Play Animation' => "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
        11 => ['Camera Follow Pos' => "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
        12 => ['Change Focus' => 'Move the focus of the camera to a specific character\nLeave it empty to return the camera to normal.'],
        13 => ['Set Game Cam Zoom and angle' => "Value 1: Cam Zoom \n(1 is default, but depends in the stage's) \n Value 2: Cam angle"],
        14 => ['Set hud Cam Zoom and angle' => "Value 1: Hud Cam Zoom \n\n (1 is default, but depends) \n Value 2: Cam angle"],
        15 => ['Alt Idle Animation' => "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
        16 => ['Screen Shake' => "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
        17 => ['Change Character' => "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"],
        18 => ['Change Stage' => "Value 1: New stage name"],
        19 => ['Change Scroll Speed' => "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
        20 => ['Set Property' => "Value 1: Variable name\nValue 2: New value", 
               'Set Any Property' => "Value 1: Variable name\nValue 2: New value"],
        21 => ['Play Sound' => "Value 1: Sound file name\nValue 2: Volume (Default: 1), ranges from 0 to 1"],
        22 => ['Change Mania' => "Value 1: The new mania value (min: 0; max: 9)"],
        23 => ['Change Mania (Special)' => "Value 1: The new mania value (min: 0; max: 9)"],
        24 => ['Dad Fly' => "Fly da dad. Value 1: True or False"],
        25 => ['Turn on StrumFocus' => "focuses the strums"],
        26 => ['Turn off StrumFocus' => "un-focuses the strums"],
        27 => ['Fade In' => "Hello There.\nValue 1 = time it takes to fade."],
        28 => ['Fade Out' => "Bye Bye!\nValue 1 = time it takes to fade."],
        29 => ['Silhouette' => 'KSGDUSN UYGD WHERE DID THE CHARACTERS GO!?!?!!?\nValue 1 Can Either Be Black Or White. Leave Blank For Normal'],
        30 => ['Save Song Posititon' => 'Place event where the player will start the song when they retry after they die.'],
        31 => ['False Timer' => 'Dang that was a short so-OH MY GOD WAIT I HAVE 5 MINUTES LEFT WHAT!\nPlace the event where the timer will revert back to the next\nfalse timer event or the actual length of the song.'],
        32 => ['Chromatic Aberration' => "Adds Le Chromatic Aberration.\nValue 1 = Amount Of Abberation"],
        33 => ['Move Window' => "Move The Window. No Im Not Kidding. Value1 = X Posiion. Value2 = Y Position."],
        34 => ['Static' => "Da Static\nValue 1 = Type Of Static:\n0 = Full Static\n1 = I See You\n2 = Half Static\n3 = No Static"],
        35 => ['Static Fade' => "Da Static Fade\nValue 1 = Time To Fade Static\nValue 2 = Alpha to Fade Static To"],
        36 => ['Thunderstorm Trigger' => "Ayo Its Raining.\nValue 1 = Type Of Storm.\n0 = light rain\n1 = heavy rain\n2 = thunderstorm\n3 = clear skys"],
        37 => ['Rave Mode' => "Reworked and WAY cooler!\nValue 1 can either be \n0(Off), 1(Light Rave), 2(Light Rave with Spotlight),\n3(Light Rave with Philly Glow), 4(Light Rave with Spotlight and Philly Glow),\n5(Heavy Rave), 6(Heavy Rave with Spotlight),\n7(Heavy Rave with Philly Glow), 8(Heavy Rave with Spotlight and Philly Glow)\nValue 2 can either be A or M for Auto and Manual toggle.\n\nFor now, the spotlight is automated, and same with\nPhilly Glow, but i'm working on it."],
        38 => ['gfScared' => "Value 1 can be true or false."],
        39 => ['Freeze Notes' => "Freeze The Notes Mid-Song"],
        40 => ['Funnie Window Tween' => 'Ayo What The Window Doin?\nValue 1: X,Y\nValue 2: Time'],
        41 => ['Chrom Beat Effect' => "Does The Chromatic Abberation Effect\nOn Every Beathit.\nSlow = Every 4 beats\nFast = Every 2 beats\nFaster = Every 1 beat\nslower = Every 8 beats\nMUST BE LOWER CASE!"],
        42 => ['Change Lyric' => 'AYO LYRICS!?!?!?!?!?!?ASKJSD:LKHSFCHU:OSCHNFC:OUSJKL BFLJS BFHNIKKS FNCS CFL>SFBHPOIS FLJKSN\nValue 1 = Lyrics\nValue 2 = Color And Effect\nValue 2 Is Optional.\nEx. Value 1 = da lyric Value 2 = white,fadein'],
        43 => ['Enable or Disable Dad Trail' => 'Can be either true or false.\nDon\'t ask what it does, you already know.'],
        44 => ['Enable or Disable BF Trail' => 'Can be either true or false.\nDon\'t ask what it does, you already know.'],
        45 => ['Enable or Disable GF Trail' => 'Can be either true or false.\nDon\'t ask what it does, you already know.']
    ];

    // public static function overrideEvents():Void {
    //     ChartingStateOG.eventStuff = mapToArray(Events);
    //     ChartingStatePsych.defaultEvents = mapToArray(Events);
    // }

    public static function mapToArray(map:haxe.ds.IntMap<Map<String, String>>):Array<Array<String>> {
        var array:Array<Array<String>> = [];
        for (key in Events.keys()) {
            for (subKey in Events.get(key).keys()) {
                array.push([subKey, map.get(key).get(subKey)]);
            }
        }
        array.sort((a, b) -> {
            var indexA = -1;
            var indexB = -1;
            for (key in Events.keys()) {
                if (Events.get(key).exists(a[0])) {
                    indexA = key;
                }
                if (Events.get(key).exists(b[0])) {
                    indexB = key;
                }
            }
            return Reflect.compare(indexA, indexB);
        });
        return array;
    }

    public static function getEventDescription(eventName:String):String {
        for (key in Events.keys()) {
            if (Events.get(key).exists(eventName)) {
                return Events.get(key).get(eventName);
            }
        }
        return null;
    }

    public static function addEvents():Array<Array<String>> {
        return mapToArray(Events);
    }

    public static function pushEvents():Array<Array<String>> {
        return mapToArray(Events);
    }

    public static function pushToArray(array:Array<Array<String>>):Array<Array<String>> {
        for (key in Events.keys()) {
            for (subKey in Events.get(key).keys()) {
                array.push([subKey, Events.get(key).get(subKey)]);
            }
        }
        var tempArray:Array<Array<String>> = mapToArray(Events);
        array.sort((a, b) -> {
            var indexA = -1;
            var indexB = -1;
            for (key in Events.keys()) {
            if (Events.get(key).exists(a[0])) {
                indexA = key;
            }
            if (Events.get(key).exists(b[0])) {
                indexB = key;
            }
            }
            return Reflect.compare(indexA, indexB);
        });
        return array.copy();
    }
}

// public static final defaultEvents:Array<Array<String>> = ChartEditorEvents.mapToArray(ChartEditorEvents.Events);

// var eventStuff:Array<Dynamic> = ChartEditorEvents.mapToArray(ChartEditorEvents.Events);