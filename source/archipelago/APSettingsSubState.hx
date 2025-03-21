package archipelago;

import substates.RankingSubstate;
import backend.ui.*;
import archipelago.APEntryState;
import archipelago.APInfo;
import flixel.util.FlxGradient;
import yaml.Yaml;
import yaml.Renderer;
import substates.Prompt;
import backend.WeekData;
using yutautil.CollectionUtils;
import archipelago.ui.RandomizableUI;


class APSettingsSubState extends MusicBeatSubstate {
    public static var globalSongList:Array<String> = [];
    
    var box:PsychUIBox;
    var progression_balancing:RandomizableDropDownMenu;
    var accessibility:RandomizableDropDownMenu;
    var unlockType:RandomizableDropDownMenu;
    var unlockMethod:RandomizableDropDownMenu;
    var gradeRequirement:RandomizableDropDownMenu;
    var accRequirement:RandomizableDropDownMenu;
    var allowMods:RandomizableCheckBox;
    var deathlink:RandomizableCheckBox;
    var ticketPercent:RandomizableSlider;
    var ticketWinPercent:RandomizableSlider;
    var chartmodifierchance:RandomizableSlider;
    var trapAmount:RandomizableSlider;
    var bbcWeight:RandomizableSlider;
    var ghostChatWeight:RandomizableSlider;
    var tutorialWeight:RandomizableSlider;
    var svcWeight:RandomizableSlider;
    var fakeTransWeight:RandomizableSlider;
    var shieldWeight:RandomizableSlider;
    var MHPWeight:RandomizableSlider;
    var gradientBar:FlxSprite;
    var dim:FlxSprite;
    public static function generateSongList() {
        globalSongList = APInfo.baseGame.concat(APInfo.baseErect).concat(APInfo.basePico).concat(APInfo.secrets);
    
        var tempSongList:Map<String, Bool> = new Map();
    
        if (APEntryState.gameSettings.FNF.mods_enabled) {
            for (i in 0...WeekData.weeksList.length) {
                var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
                
                if (Mods.parseList().enabled.contains(leWeek.folder))
                for (song in leWeek.songs) {
                    var songName = (cast song[0] : String);
                    var folderName = StringTools.trim(leWeek.folder);
                    if (folderName.indexOf("{") != -1 || folderName.indexOf("}") != -1 || folderName.indexOf("[") != -1 || folderName.indexOf("]") != -1) {
                        folderName = folderName.replace("{", "<cOpen>").replace("}", "<cClose>").replace("[", "<sOpen>").replace("]", "<sClose>");
                    }
                    tempSongList.set(songName + (folderName != "" ? " (" + folderName + ")" : ""), true);
                }
            }
        }
    
        for (song in globalSongList) {
            tempSongList.set(song, false);
        }
    
        globalSongList = [];
        for (songName in tempSongList.keys()) {
            if (tempSongList.get(songName)) {
                var parts = songName.split(" (");
                var formattedName = parts[0];
                if (parts.length > 1) {
                    formattedName += " (" + parts.slice(1).join(" (");
                }
                if (!formattedName.endsWith(")")) {
                    formattedName += ")";
                }
                if (formattedName != songName.trim()) {
                    trace('Verification failed for: ' + songName);
                }
                globalSongList.push(formattedName);
            } else {
                var formattedName = songName.trim();
                if (formattedName != songName.trim()) {
                    trace('Verification failed for: ' + songName);
                }
                globalSongList.push(formattedName);
            }
        }
    }

    override function create() {
        FlxTween.num(1, 0.0134, 1, {ease: FlxEase.sineInOut}, function(t) {
            APEntryState.lowFilterAmount = t;
        });

        dim = new FlxSprite().makeGraphic(FlxG.width*4, FlxG.height*4, 0x000000);
        dim.scrollFactor.set();
        dim.screenCenter();
        add(dim);
        dim.alpha = 0.5;

        box = new PsychUIBox(0, 0, 300, 480, ['Main Settings', 'Songs', 'Traps']);
		box.selectedName = 'Main Settings';
		box.scrollFactor.set();
        box.canMove = false;
        box.canMinimize = false;
        box.screenCenter();
		add(box);

        addMainSettings();
        addSongsSettings();
        addTrapsSettings();

        progression_balancing.list = ['disabled', 'normal', 'extreme'];
        accessibility.list = ['full', 'minimal'];
        unlockType.list = ["Per Song", "Per Week"];
        unlockMethod.list = ["Note Checks", "Song Completion", "Both"];
        
        var songList:Array<String> = [];
        WeekData.reloadWeekFiles(false);
        for (i in 0...WeekData.weeksList.length) {
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			
			for (song in leWeek.songs)
			{
				songList.push(song[0]);
			}
		}
        songList.sort((a:String, b:String) -> (a.toUpperCase() < b.toUpperCase()) ? -1 : 1); //Sort alphabetically descending

        gradeRequirement.list =
        [
            'Any',
            "MFC",
            "SFC",
            "GFC",
            "AFC",
            "FC",
            "SDCB"
        ];

        accRequirement.list =
        [
            "Any",
            "P",
            "X",
            "X-",
            "SS+",
            "SS",
            "SS-",
            "S+",
            "S",
            "S-",
            "A+",
            "A",
            "A=",
            "B",
            "C",
            "D",
            "E",
        ];
        
        super.create();
    }
    
    function addRandomCheckbox(tab_group:FlxSpriteGroup, obj:Dynamic, objX:Int, objY:Int, label:String, onRandomChange:Void->Void) {
        var randomCheckbox = new PsychUICheckBox(objX + 150, objY, "Random", 100, function() {
            var randomCheckbox = cast obj.randomCheckbox; // Ensure randomCheckbox is retrieved from obj
            obj.alpha = randomCheckbox != null && randomCheckbox.checked ? 0.5 : 1; // Make transparent if random is selected
            onRandomChange();
        });
        randomCheckbox.checked = false;
        tab_group.add(new FlxText(randomCheckbox.x, randomCheckbox.y - 15, 120, label + " Random:"));
        tab_group.add(randomCheckbox);
        return randomCheckbox;
    }

    function addMainSettings()
    {
        var tab_group = box.getTab('Main Settings').menu;
        var objX = 10;
        var objY = 40;

        progression_balancing = new RandomizableDropDownMenu(objX, objY, [''], function(id:Int, prog:String)
        {
            APEntryState.gameSettings.FNF.progression_balancing = prog;
        });
        progression_balancing.selectedLabel = APEntryState.gameSettings.FNF.progression_balancing;
        progression_balancing.attachRandomCheckbox(tab_group, "Progression Balancing", objX, objY, function() {
            // APEntryState.gameSettings.FNF.progression_balancing_random = progression_balancing.randomCheckbox.checked;
        });

        accessibility = new RandomizableDropDownMenu(objX + 150, objY, [''], function(id:Int, acc:String)
        {
            APEntryState.gameSettings.FNF.accessibility = acc;
        });
        accessibility.selectedLabel = APEntryState.gameSettings.FNF.accessibility;
        accessibility.attachRandomCheckbox(tab_group, "Accessibility", objX + 150, objY, function() {
            // APEntryState.gameSettings.FNF.accessibility_random = accessibility.randomCheckbox.checked;
        });

        objY += 50;
        unlockType = new RandomizableDropDownMenu(objX, objY, [''], function(id:Int, unlock:String)
        {
            APEntryState.gameSettings.FNF.unlock_type = unlock;
        });
        unlockType.selectedLabel = APEntryState.gameSettings.FNF.unlock_type;
        unlockType.attachRandomCheckbox(tab_group, "Unlock Type", objX, objY, function() {
            // APEntryState.gameSettings.FNF.unlock_type_random = unlockType.randomCheckbox.checked;
        });

        unlockMethod = new RandomizableDropDownMenu(objX + 150, objY, [''], function(id:Int, unlock:String)
        {
            APEntryState.gameSettings.FNF.unlock_method = unlock;
        });
        unlockMethod.selectedLabel = APEntryState.gameSettings.FNF.unlock_method;
        unlockMethod.attachRandomCheckbox(tab_group, "Unlock Method", objX + 150, objY, function() {
            // APEntryState.gameSettings.FNF.unlock_method_random = unlockMethod.randomCheckbox.checked;
        });

        objY += 70;
        deathlink = new RandomizableCheckBox(objX, objY, 'DeathLink', 100, function() APEntryState.gameSettings.FNF.deathlink = deathlink.checked);
        deathlink.attachRandomCheckbox(tab_group, "DeathLink", objX, objY, function() {
            // APEntryState.gameSettings.FNF.deathlink_random = deathlink.randomCheckbox.checked;
        });
        
        objY += 50;
        ticketPercent = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.ticket_percentage = Std.int(v));
        ticketPercent.decimals = 0;
        ticketPercent.min = 10;
        ticketPercent.max = 50;
        ticketPercent.value = APEntryState.gameSettings.FNF.ticket_percentage;
        ticketPercent.attachRandomCheckbox(tab_group, "Ticket Percent", objX, objY, function() {
            // APEntryState.gameSettings.FNF.ticket_percentage_random = ticketPercent.randomCheckbox.checked;
        });

        objY += 50;
        ticketWinPercent = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.ticket_win_percentage = Std.int(v));
        ticketWinPercent.decimals = 0;
        ticketWinPercent.min = 50;
        ticketWinPercent.max = 100;
        ticketWinPercent.value = APEntryState.gameSettings.FNF.ticket_win_percentage;
        ticketWinPercent.attachRandomCheckbox(tab_group, "Ticket Win Percent", objX, objY, function() {
            // APEntryState.gameSettings.FNF.ticket_win_percentage_random = ticketWinPercent.randomCheckbox.checked;
        });

        tab_group.add(new FlxText(progression_balancing.x, progression_balancing.y - 15, 120, 'Progression Balancing:'));
        tab_group.add(new FlxText(accessibility.x, accessibility.y - 15, 120, 'Accessibility:'));
        tab_group.add(new FlxText(unlockType.x, unlockType.y - 15, 120, 'Unlock Type:'));
        tab_group.add(new FlxText(unlockMethod.x, unlockMethod.y - 15, 120, 'Unlock Method:'));
        tab_group.add(new FlxText(ticketPercent.x, ticketPercent.y - 15, 120, 'Ticket Percent:'));
        tab_group.add(new FlxText(ticketWinPercent.x, ticketWinPercent.y - 15, 120, 'Ticket Win Percent:'));
        tab_group.add(unlockMethod);
        tab_group.add(accessibility);
        tab_group.add(unlockType);
        tab_group.add(progression_balancing);
        tab_group.add(deathlink);
        tab_group.add(ticketPercent);
        tab_group.add(ticketWinPercent);
    }

    function addSongsSettings()
    {
        var tab_group = box.getTab('Songs').menu;
        var objX = 10;
        var objY = 10;

        allowMods = new RandomizableCheckBox(objX, objY, 'Allow Mods', 100, 
        function() 
        {
            APEntryState.gameSettings.FNF.mods_enabled = allowMods.checked;
            generateSongList();
        });
        allowMods.attachRandomCheckbox(tab_group, "Allow Mods", objX, objY, function() {
            // APEntryState.gameSettings.FNF.mods_enabled_random = allowMods.randomCheckbox.checked;
        });

        objY += 50;
        gradeRequirement = new RandomizableDropDownMenu(objX, objY, [''], function(id:Int, grade:String)
        {
            APEntryState.gameSettings.FNF.graderequirement = grade;
            RankingSubstate.comboRankSetLimit = id;
            trace(id);
        });
        gradeRequirement.selectedLabel = APEntryState.gameSettings.FNF.graderequirement;
        gradeRequirement.attachRandomCheckbox(tab_group, "Grade Requirement", objX, objY, function() {
            // APEntryState.gameSettings.FNF.graderequirement_random = gradeRequirement.randomCheckbox.checked;
        });

        objX += 150;
        accRequirement = new RandomizableDropDownMenu(objX, objY, [''], function(id:Int, accuracy:String)
        {
            APEntryState.gameSettings.FNF.accrequirement = accuracy;
            RankingSubstate.accRankSetLimit = id;
            trace(id);
        });
        accRequirement.selectedLabel = APEntryState.gameSettings.FNF.accrequirement;
        accRequirement.attachRandomCheckbox(tab_group, "Accuracy Requirement", objX, objY, function() {
            // APEntryState.gameSettings.FNF.accrequirement_random = accRequirement.randomCheckbox.checked;
        });

        tab_group.add(new FlxText(gradeRequirement.x, gradeRequirement.y - 15, 120, 'Grade Requirement:'));
        tab_group.add(new FlxText(accRequirement.x, accRequirement.y - 15, 120, 'Accuracy Requirement:'));
        tab_group.add(allowMods);
        tab_group.add(accRequirement);
        tab_group.add(gradeRequirement);
    }

    function addTrapsSettings()
    {
        var tab_group = box.getTab('Traps').menu;
        var objX = 10;
        var objY = 20;

        trapAmount = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.trapAmount = Std.int(v));
        trapAmount.min = 0;
        trapAmount.max = 60;
        trapAmount.decimals = 0;
        trapAmount.value = APEntryState.gameSettings.FNF.trapAmount;
        trapAmount.attachRandomCheckbox(tab_group, "Trap Amount", objX, objY, function() {
            // APEntryState.gameSettings.FNF.trapAmount_random = trapAmount.randomCheckbox.checked;
        });

        objY += 40;
        bbcWeight = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.bbcWeight = Std.int(v));
        bbcWeight.min = 0;
        bbcWeight.max = 10;
        bbcWeight.decimals = 0;
        bbcWeight.value = APEntryState.gameSettings.FNF.bbcWeight;
        bbcWeight.attachRandomCheckbox(tab_group, "Blue Balls Curse Trap Weight", objX, objY, function() {
            // APEntryState.gameSettings.FNF.bbcWeight_random = bbcWeight.randomCheckbox.checked;
        });

        objY += 40;
        ghostChatWeight = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.ghostChatWeight = Std.int(v));
        ghostChatWeight.min = 0;
        ghostChatWeight.max = 10;
        ghostChatWeight.decimals = 0;
        ghostChatWeight.value = APEntryState.gameSettings.FNF.ghostChatWeight;
        ghostChatWeight.attachRandomCheckbox(tab_group, "Ghost Chat Trap Weight", objX, objY, function() {
            // APEntryState.gameSettings.FNF.ghostChatWeight_random = ghostChatWeight.randomCheckbox.checked;
        });

        objY += 40;
        tutorialWeight = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.svcWeight = Std.int(v));
        tutorialWeight.min = 0;
        tutorialWeight.max = 10;
        tutorialWeight.decimals = 0;
        tutorialWeight.value = APEntryState.gameSettings.FNF.svcWeight;
        tutorialWeight.attachRandomCheckbox(tab_group, "Tutorial Trap Weight", objX, objY, function() {
            // APEntryState.gameSettings.FNF.svcWeight_random = tutorialWeight.randomCheckbox.checked;
        });

        objY += 40;
        svcWeight = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.tutorialWeight = Std.int(v));
        svcWeight.min = 0;
        svcWeight.max = 10;
        svcWeight.decimals = 0;
        svcWeight.value = APEntryState.gameSettings.FNF.tutorialWeight;
        svcWeight.attachRandomCheckbox(tab_group, "Streamer Vs. Chat Trap Weight", objX, objY, function() {
            // APEntryState.gameSettings.FNF.tutorialWeight_random = svcWeight.randomCheckbox.checked;
        });

        objY += 40;
        fakeTransWeight = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.fakeTransWeight = Std.int(v));
        fakeTransWeight.min = 0;
        fakeTransWeight.max = 10;
        fakeTransWeight.decimals = 0;
        fakeTransWeight.value = APEntryState.gameSettings.FNF.fakeTransWeight;
        fakeTransWeight.attachRandomCheckbox(tab_group, "Fake Transition Trap Weight", objX, objY, function() {
            // APEntryState.gameSettings.FNF.fakeTransWeight_random = fakeTransWeight.randomCheckbox.checked;
        });

        objY += 40;
        chartmodifierchance = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.chart_modifier_change_chance = Std.int(v));
        chartmodifierchance.min = 0;
        chartmodifierchance.max = 10;
        chartmodifierchance.decimals = 0;
        chartmodifierchance.value = APEntryState.gameSettings.FNF.chart_modifier_change_chance;
        chartmodifierchance.attachRandomCheckbox(tab_group, "Chart Modifier Chance", objX, objY, function() {
            // APEntryState.gameSettings.FNF.chart_modifier_change_chance_random = chartmodifierchance.randomCheckbox.checked;
        });

        objY += 40;
        shieldWeight = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.shieldWeight = Std.int(v));
        shieldWeight.min = 0;
        shieldWeight.max = 10;
        shieldWeight.decimals = 0;
        shieldWeight.value = APEntryState.gameSettings.FNF.shieldWeight;
        shieldWeight.attachRandomCheckbox(tab_group, "Shield Item Weight", objX, objY, function() {
            // APEntryState.gameSettings.FNF.shieldWeight_random = shieldWeight.randomCheckbox.checked;
        });

        objY += 40;
        MHPWeight = new RandomizableSlider(objX, objY, function(v:Float) APEntryState.gameSettings.FNF.MHPWeight = Std.int(v));
        MHPWeight.min = 0;
        MHPWeight.max = 10;
        MHPWeight.decimals = 0;
        MHPWeight.value = APEntryState.gameSettings.FNF.MHPWeight;
        MHPWeight.attachRandomCheckbox(tab_group, "Hax HP Item Weight", objX, objY, function() {
            // APEntryState.gameSettings.FNF.MHPWeight_random = MHPWeight.randomCheckbox.checked;
        });

        tab_group.add(new FlxText(chartmodifierchance.x, chartmodifierchance.y - 15, 300, 'Chart Modifier Chance:'));
        tab_group.add(new FlxText(trapAmount.x, trapAmount.y - 15, 300, 'Trap Amount:'));
        tab_group.add(new FlxText(bbcWeight.x, bbcWeight.y - 15, 300, 'Blue Balls Curse Trap Weight:'));
        tab_group.add(new FlxText(ghostChatWeight.x, ghostChatWeight.y - 15, 300, 'Ghost Chat Trap Weight:'));
        tab_group.add(new FlxText(tutorialWeight.x, tutorialWeight.y - 15, 300, 'Tutorial Trap Weight:'));
        tab_group.add(new FlxText(svcWeight.x, svcWeight.y - 15, 300, 'Streamer Vs. Chat Trap Weight:'));
        tab_group.add(new FlxText(fakeTransWeight.x, fakeTransWeight.y - 15, 300, 'Fake Transition Trap Weight:'));
        tab_group.add(new FlxText(shieldWeight.x, shieldWeight.y - 15, 300, 'Shield Item Weight:'));
        tab_group.add(new FlxText(MHPWeight.x, MHPWeight.y - 15, 300, 'Hax HP Item Weight:'));
        tab_group.add(chartmodifierchance);
        tab_group.add(trapAmount);
        tab_group.add(bbcWeight);
        tab_group.add(ghostChatWeight);
        tab_group.add(tutorialWeight);
        tab_group.add(svcWeight);
        tab_group.add(fakeTransWeight);
        tab_group.add(shieldWeight);
        tab_group.add(MHPWeight);
    }

    var testMap:Map<String, Dynamic>;
    function onGenYaml()
	{

        var yamlThing = {}
        for (thing in Reflect.fields(APEntryState.gameSettings.FNF))
        {
            Reflect.setField(yamlThing, thing, Reflect.field(APEntryState.gameSettings.FNF, thing));
        }

        while (globalSongList.length == 0) {
            generateSongList();
        }
        APEntryState.gameSettings.FNF.songList = globalSongList;

        if (APEntryState.gameSettings.FNF.songList.length == 0) {
            while (APEntryState.gameSettings.FNF.songList.length == 0) {
                generateSongList();
                APEntryState.gameSettings.FNF.songList = globalSongList;
            }
        }


        var mainSettings = {name: APEntryState.yamlName, description: APEntryState.gameSettings.description, game: APEntryState.gameSettings.game};
        var document = Yaml.render(mainSettings, Renderer.options().setFlowLevel(1));
		trace(document);

        if (Reflect.hasField(yamlThing, "ticket_percentage"))
            if (Reflect.field(yamlThing, "ticket_percentage") < 10)
                Reflect.setField(yamlThing, "ticket_percentage", 10);

        if (Reflect.hasField(yamlThing, "ticket_win_percentage"))
            if (Reflect.field(yamlThing, "ticket_win_percentage") < 50)
                Reflect.setField(yamlThing, "ticket_win_percentage", 50);

        if (Reflect.hasField(yamlThing, "unlock_type"))
            if (Reflect.field(yamlThing, "unlock_type") != "Per Song" && Reflect.field(yamlThing, "unlock_type") != "Per Week")
                Reflect.setField(yamlThing, "unlock_type", "Per Song");

        if (Reflect.hasField(yamlThing, "unlock_method"))
            if (Reflect.field(yamlThing, "unlock_method") != "Note Checks" && Reflect.field(yamlThing, "unlock_method") != "Song Completion" && Reflect.field(yamlThing, "unlock_method") != "Both")
                Reflect.setField(yamlThing, "unlock_method", "Song Completion");

        if (Reflect.hasField(yamlThing, "progression_balancing"))
            if (Reflect.field(yamlThing, "progression_balancing") != "disabled" && Reflect.field(yamlThing, "progression_balancing") != "normal" && Reflect.field(yamlThing, "progression_balancing") != "extreme")
                Reflect.setField(yamlThing, "progression_balancing", "normal");

        if (Reflect.hasField(yamlThing, "songList")) {
            var songList = Reflect.field(yamlThing, "songList");
            var uniqueSongList = new Array<String>();
            for (song in yutautil.CollectionUtils.toArray(globalSongList)) {
                if (!uniqueSongList.contains(song)) {
                    uniqueSongList.push(song);
                }
            }
            Reflect.setField(yamlThing, "songList", uniqueSongList);
        }

        // Handle random settings for all randomizable elements
        var randomizableElements = [
            progression_balancing, accessibility, unlockType, unlockMethod,
            gradeRequirement, accRequirement, allowMods, deathlink,
            ticketPercent, ticketWinPercent, chartmodifierchance, trapAmount,
            bbcWeight, ghostChatWeight, tutorialWeight, svcWeight,
            fakeTransWeight, shieldWeight, MHPWeight
        ];

        for (element in randomizableElements) {
            if (element == null) continue;
            var element:RandomizableOption = cast element;

            var fieldName:String = null;
            if (Std.is(element, RandomizableDropDownMenu)) {
            fieldName = (cast element:RandomizableDropDownMenu).name;
            } else if (Std.is(element, RandomizableCheckBox)) {
            fieldName = (cast element:RandomizableCheckBox).name;
            } else if (Std.is(element, RandomizableSlider)) {
            fieldName = (cast element:RandomizableSlider).name;
            }

            if (fieldName != null && element.randomCheckbox != null && element.randomCheckbox.checked) {
            Reflect.setField(yamlThing, fieldName, "random");
            }
        }


        var yamlString = "Friday Night Funkin:\n";
        for (key in Reflect.fields(yamlThing)) {
            yamlString += "  " + key + ": " + Reflect.field(yamlThing, key) + "\n";
        }

		#if sys
		// This time write that same document to disk and adjust the flow level giving
		// a more compact result.
		if (!FileSystem.exists("./PlayerSettings/"))
			FileSystem.createDirectory("./PlayerSettings/");
		Yaml.write("PlayerSettings/" + APEntryState.yamlName + ".yaml", mainSettings, Renderer.options().setFlowLevel(1));
		#end
		openSubState(new Prompt("Settings Exported Successfully!", 0, null, null, false));

        // Add actual settings.
        if (FileSystem.exists("PlayerSettings/" + APEntryState.yamlName + ".yaml")) {
            FileSystem.deleteFile("PlayerSettings/" + APEntryState.yamlName + ".yaml");
        }

        var finalDocument = document + "\n" + yamlString;
        trace(finalDocument);

        #if sys
        sys.io.File.saveContent("PlayerSettings/" + APEntryState.yamlName + ".yaml", finalDocument);
        #end
        close();
	}

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			@:privateAccess
			{
				var af = lime.media.openal.AL.createFilter(); // create AudioFilter
				lime.media.openal.AL.filteri( af, lime.media.openal.AL.FILTER_TYPE, lime.media.openal.AL.FILTER_LOWPASS ); // set filter type
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAIN, 1 ); // set gain
				lime.media.openal.AL.filterf( af, lime.media.openal.AL.LOWPASS_GAINHF, APEntryState.lowFilterAmount ); // set gainhf
				lime.media.openal.AL.sourcei( FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af ); // apply filter to source (handle)
				//lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.HIGHPASS_GAIN, 0);
			}
		}
        if (FlxG.keys.justPressed.ESCAPE) 
        {
            trace(globalSongList);
            onGenYaml();
            FlxTween.num(0.0134, 1, 1, {ease: FlxEase.sineInOut}, function(t) {
                APEntryState.lowFilterAmount = t;
            });
        }
    }
}