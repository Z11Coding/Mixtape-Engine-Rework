package backend;
import backend.modules.EventFunc;
import haxe.Json;
import sys.io.File;
import states.PlayState;
import sys.FileSystem;
import objects.Note;
import backend.Song;

class ChartCache {
    public static var cache:Map<String, Array<Note>> = new Map<String, Array<Note>();

    public static function addToCache(filePath:String):Void {
        if (!cache.exists(filePath)) {
            cache.set(filePath, generateSong(filePath));
        }
    }

	public  function generateChart(noteData:Array<SwagSection>, SONG:SwagSong):Array<Note>
        {			var AIPlayMap = [];
    
            if (AIPlayer.active)
                AIPlayMap = AIPlayer.GeneratePlayMap(SONG, AIPlayer.diff);
        for (section in noteData)
            {
                for (songNotes in section.sectionNotes)
                {
                    var daStrumTime:Float = songNotes[0];
                    var daNoteData:Int;
                    if (chartModifier != "4K Only" && chartModifier != "ManiaConverter")
                    {
                        daNoteData = Std.int(songNotes[1] % Note.ammo[mania]);
                    }
                    else
                    {
                        daNoteData = Std.int(songNotes[1] % Note.ammo[SONG.mania]);
                    }
    
                    var gottaHitNote:Bool = section.mustHitSection;
                    
                    switch (chartModifier)
                    {
                        case "Random":
                            daNoteData = FlxG.random.int(0, mania);
                        case "RandomBasic":
                            var randomDirection:Int;
                            do
                            {
                                randomDirection = FlxG.random.int(0, mania);
                            }
                            while (randomDirection == prevNoteData && mania > 1);
                            prevNoteData = randomDirection;
                            daNoteData = randomDirection;
                        case "RandomComplex":
                            var thisNoteData = daNoteData;
                            if (initialNoteData == -1)
                            {
                                initialNoteData = daNoteData;
                                daNoteData = FlxG.random.int(0, mania);
                            }
                            else
                            {
                                var newNoteData:Int;
                                do
                                {
                                    newNoteData = FlxG.random.int(0, mania);
                                }
                                while (newNoteData == prevNoteData && mania > 1);
                                if (thisNoteData == initialNoteData)
                                {
                                    daNoteData = prevNoteData;
                                }
                                else
                                {
                                    daNoteData = newNoteData;
                                }
                            }
                            prevNoteData = daNoteData;
                            initialNoteData = thisNoteData;
                        case "Flip":
                            if (gottaHitNote)
                            {
                                daNoteData = mania - Std.int(songNotes[1] % Note.ammo[mania]);
                            }
                        case "Pain":
                            daNoteData = daNoteData - Std.int(songNotes[1] % Note.ammo[mania]);
                        case "4K Only":
                            daNoteData = getNumberFromAnims(daNoteData, SONG.mania);
                        case "ManiaConverter":
                            daNoteData = getNumberFromAnims(daNoteData, mania);
                        case "Stairs":
                            daNoteData = stair % Note.ammo[mania];
                            stair++;
                        case "Wave":
                            // Sketchie... WHY?!
                            var ammoFromFortnite:Int = Note.ammo[mania];
                            var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                            var marioSex:Int = stair++ % luigiSex;
                            if (marioSex < ammoFromFortnite)
                            {
                                daNoteData = marioSex;
                            }
                            else
                            {
                                daNoteData = luigiSex - marioSex;
                            }
                        case "Trills":
                            var ammoFromFortnite:Int = Note.ammo[mania];
                            var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                            var marioSex:Int;
                            do
                            {
                                marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
                                if (marioSex < ammoFromFortnite)
                                {
                                    daNoteData = marioSex;
                                }
                                else
                                {
                                    daNoteData = luigiSex - marioSex;
                                }
                            }
                            while (daNoteData == prevNoteData && mania > 1);
                            prevNoteData = daNoteData;
                        case "Ew":
                            // I hate that I used Sketchie's variables as a base for this... ;-;
                            var ammoFromFortnite:Int = Note.ammo[mania];
                            var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                            var marioSex:Int = stair++ % luigiSex;
                            var noteIndex:Int = Std.int(marioSex / 2);
                            var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
                            daNoteData = noteIndex + noteDirection;
                            // If the note index is out of range, wrap it around
                            if (daNoteData < 0)
                            {
                                daNoteData = 1;
                            }
                            else if (daNoteData >= ammoFromFortnite)
                            {
                                daNoteData = ammoFromFortnite - 2;
                            }
                        case "Death":
                            var ammoFromFortnite:Int = Note.ammo[mania];
                            var luigiSex:Int = (ammoFromFortnite * 4 - 4);
                            var marioSex:Int = stair++ % luigiSex;
                            var step:Int = Std.int(luigiSex / 3);
    
                            if (marioSex < ammoFromFortnite)
                            {
                                daNoteData = marioSex % step;
                            }
                            else if (marioSex < ammoFromFortnite * 2)
                            {
                                daNoteData = (marioSex - ammoFromFortnite) % step + step;
                            }
                            else if (marioSex < ammoFromFortnite * 3)
                            {
                                daNoteData = (marioSex - ammoFromFortnite * 2) % step + step * 2;
                            }
                            else
                            {
                                daNoteData = (marioSex - ammoFromFortnite * 3) % step + step * 3;
                            }
                        case "What":
                            switch (stair % (2 * Note.ammo[mania]))
                            {
                                case 0:
                                case 1:
                                case 2:
                                case 3:
                                case 4:
                                    daNoteData = stair % Note.ammo[mania];
                                default:
                                    daNoteData = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
                            }
                            stair++;
                        case "Amalgam":
                            {
                                var modifierNames:Array<String> = [
                                    "Random", "RandomBasic", "RandomComplex", "Flip", "Pain", "Stairs", "Wave", "Huh", "Ew", "What", "Jack Wave", "SpeedRando",
                                    "Trills"
                                ];
    
                                if (caseExecutionCount <= 0)
                                {
                                    currentModifier = FlxG.random.int(-1, (modifierNames.length - 1)); // Randomly select a case from 0 to 9
                                    caseExecutionCount = FlxG.random.int(1, 51); // Randomly select a number from 1 to 50
                                    trace("Active Modifier: " + modifierNames[currentModifier] + ", Notes to edit: " + caseExecutionCount);
                                }
                                // trace('Notes remaining: ' + caseExecutionCount);
                                caseExecutionCount--;
                                switch (currentModifier)
                                {
                                    case 0: // "Random"
                                        daNoteData = FlxG.random.int(0, mania);
                                    case 1: // "RandomBasic"
                                        var randomDirection:Int;
                                        do
                                        {
                                            randomDirection = FlxG.random.int(0, mania);
                                        }
                                        while (randomDirection == prevNoteData && mania > 1);
                                        prevNoteData = randomDirection;
                                        daNoteData = randomDirection;
                                    case 2: // "RandomComplex"
                                        var thisNoteData = daNoteData;
                                        if (initialNoteData == -1)
                                        {
                                            initialNoteData = daNoteData;
                                            daNoteData = FlxG.random.int(0, mania);
                                        }
                                        else
                                        {
                                            var newNoteData:Int;
                                            do
                                            {
                                                newNoteData = FlxG.random.int(0, mania);
                                            }
                                            while (newNoteData == prevNoteData && mania > 1);
                                            if (thisNoteData == initialNoteData)
                                            {
                                                daNoteData = prevNoteData;
                                            }
                                            else
                                            {
                                                daNoteData = newNoteData;
                                            }
                                        }
                                        prevNoteData = daNoteData;
                                        initialNoteData = thisNoteData;
                                    case 3: // "Flip"
                                        if (gottaHitNote)
                                        {
                                            daNoteData = mania - Std.int(songNotes[1] % Note.ammo[mania]);
                                        }
                                    case 4: // "Pain"
                                        daNoteData = daNoteData - Std.int(songNotes[1] % Note.ammo[mania]);
                                    case 5: // "Stairs"
                                        daNoteData = stair % Note.ammo[mania];
                                        stair++;
                                    case 6: // "Wave"
                                        // Sketchie... WHY?!
                                        var ammoFromFortnite:Int = Note.ammo[mania];
                                        var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                                        var marioSex:Int = stair++ % luigiSex;
                                        if (marioSex < ammoFromFortnite)
                                        {
                                            daNoteData = marioSex;
                                        }
                                        else
                                        {
                                            daNoteData = luigiSex - marioSex;
                                        }
                                    case 7: // "Huh"
                                        var ammoFromFortnite:Int = Note.ammo[mania];
                                        var luigiSex:Int = (ammoFromFortnite * 4 - 4);
                                        var marioSex:Int = stair++ % luigiSex;
                                        var step:Int = Std.int(luigiSex / 3);
                                        var waveIndex:Int = Std.int(marioSex / step);
                                        var waveDirection:Int = waveIndex % 2 == 0 ? 1 : -1;
                                        var waveRepeat:Int = Std.int(waveIndex / 2);
                                        var repeatStep:Int = marioSex % step;
                                        if (repeatStep < waveRepeat)
                                        {
                                            daNoteData = waveIndex * step + waveDirection * repeatStep;
                                        }
                                        else
                                        {
                                            daNoteData = waveIndex * step + waveDirection * (waveRepeat * 2 - repeatStep);
                                        }
                                        if (daNoteData < 0)
                                        {
                                            daNoteData = 0;
                                        }
                                        else if (daNoteData >= ammoFromFortnite)
                                        {
                                            daNoteData = ammoFromFortnite - 1;
                                        }
                                    case 8: // "Ew"
                                        // I hate that I used Sketchie's variables as a base for this... ;-;
                                        var ammoFromFortnite:Int = Note.ammo[mania];
                                        var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                                        var marioSex:Int = stair++ % luigiSex;
                                        var noteIndex:Int = Std.int(marioSex / 2);
                                        var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
                                        daNoteData = noteIndex + noteDirection;
                                        // If the note index is out of range, wrap it around
                                        if (daNoteData < 0)
                                        {
                                            daNoteData = 1;
                                        }
                                        else if (daNoteData >= ammoFromFortnite)
                                        {
                                            daNoteData = ammoFromFortnite - 2;
                                        }
                                    case 9: // "What"
                                        switch (stair % (2 * Note.ammo[mania]))
                                        {
                                            case 0:
                                            case 1:
                                            case 2:
                                            case 3:
                                            case 4:
                                                daNoteData = stair % Note.ammo[mania];
                                            default:
                                                daNoteData = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
                                        }
                                        stair++;
                                    case 10: // Jack Wave
                                        var ammoFromFortnite:Int = Note.ammo[mania];
                                        var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                                        var marioSex:Int = Std.int((stair++ % (luigiSex * 4)) / 4);
                                        if (marioSex < ammoFromFortnite)
                                        {
                                            daNoteData = marioSex;
                                        }
                                        else
                                        {
                                            daNoteData = luigiSex - marioSex;
                                        }
                                    case 11: // SpeedRando
                                    // Handled by SpeedRando Code below!
                                    case 12: // Trills
                                        var ammoFromFortnite:Int = Note.ammo[mania];
                                        var luigiSex:Int = (ammoFromFortnite * 2 - 2);
                                        var marioSex:Int;
                                        do
                                        {
                                            marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
                                            if (marioSex < ammoFromFortnite)
                                            {
                                                daNoteData = marioSex;
                                            }
                                            else
                                            {
                                                daNoteData = luigiSex - marioSex;
                                            }
                                        }
                                        while (daNoteData == prevNoteData && mania > 1);
                                        prevNoteData = daNoteData;
                                    default:
                                        // Default case (optional)
                                }
                            }
                    }
    
                    if (chartModifier != "4K Only" && chartModifier != "ManiaConverter")
                    {
                        if (songNotes[1] > (Note.ammo[mania] - 1))
                        {
                            gottaHitNote = !section.mustHitSection;
                        }
                    }
                    else
                    {
                        if (songNotes[1] > (Note.ammo[SONG.mania] - 1))
                        {
                            gottaHitNote = !section.mustHitSection;
                        }
                    }
    
                    var oldNote:Note;
                    if (allNotes.length > 0)
                        oldNote = allNotes[Std.int(allNotes.length - 1)];
                    else
                        oldNote = null;
    
                    var type:Dynamic = songNotes[3];
                    //if(!Std.isOfType(type, String)) type = editors.ChartingState.noteTypeList[type];
    
                    // TODO: maybe make a checkNoteType n shit but idfk im lazy
                    // or maybe make a "Transform Notes" event which'll make notes which don't change texture change into the specified one
    
                    var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
                    if (!swagNote.mustPress)
                    {
                        if (AIPlayMap.length != 0 && [noteData.indexOf(section)] != null)
                        {
                            swagNote.AIStrumTime = AIPlayMap[noteData.indexOf(section)][section.sectionNotes.indexOf(songNotes)];
                            if (Math.abs(swagNote.AIStrumTime) > Conductor.safeZoneOffset)
                                swagNote.ignoreNote = swagNote.AIMiss = true;
                        }
                    }
                    swagNote.mustPress = gottaHitNote;
                    swagNote.sustainLength = songNotes[2];
                    swagNote.gfNote = section.gfSection;
                    swagNote.noteType = type;
                    swagNote.noteIndex = noteIndex++;
                    if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
                    swagNote.scrollFactor.set();
                    if (chartModifier == 'Amalgam' && currentModifier == 11)
                    {
                        swagNote.multSpeed = FlxG.random.float(0.1, 2);
                    }
    
                    var susLength:Float = swagNote.sustainLength;
    
                    susLength = susLength / Conductor.stepCrochet;
                    swagNote.ID = allNotes.length;
    
    
                    if(swagNote.fieldIndex==-1 && swagNote.field==null)
                        swagNote.field = swagNote.mustPress ? playerField : dadField;
    
                    if(swagNote.field!=null)
                        swagNote.fieldIndex = playfields.members.indexOf(swagNote.field);
    
    
                    var playfield:PlayField = playfields.members[swagNote.fieldIndex];
    
                    if (playfield!=null){
                        playfield.queue(swagNote); // queues the note to be spawned
                        allNotes.push(swagNote); // just for the sake of convenience
                    }else{
                        swagNote.destroy();
                        continue;
                    }
    
                    var floorSus:Int = Math.round(susLength);
                    if(floorSus > 0) {
                        for (susNote in 0...floorSus)
                        {
                            oldNote = allNotes[Std.int(allNotes.length - 1)];
    
                            var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet), daNoteData, oldNote, true);
                            sustainNote.mustPress = gottaHitNote;
                            sustainNote.gfNote = swagNote.gfNote;
                            swagNote.animSuffix = swagNote.animSuffix;
                            sustainNote.noteType = type;
                            sustainNote.noteIndex = swagNote.noteIndex;
                            if (chartModifier == 'Amalgam' && currentModifier == 11)
                            {
                                sustainNote.multSpeed = swagNote.multSpeed;
                            }
                            if(sustainNote==null || !sustainNote.alive)
                                break;
                            sustainNote.ID = allNotes.length;
                            sustainNote.scrollFactor.set();
                            swagNote.tail.push(sustainNote);
                            swagNote.unhitTail.push(sustainNote);
                            sustainNote.parent = swagNote;
                            //allNotes.push(sustainNote);
                            sustainNote.fieldIndex = swagNote.fieldIndex;
                            playfield.queue(sustainNote);
                            allNotes.push(sustainNote);
    
                            if (sustainNote.mustPress)
                            {
                                sustainNote.x += FlxG.width * 0.5; // general offset
                            } 
                        }
                    }
    
                    if (swagNote.mustPress)
                    {
                        swagNote.x += FlxG.width * 0.5; // general offset
                    }
                    else if(ClientPrefs.data.middleScroll)
                    {
                        swagNote.x += 310;
                        if(daNoteData > 1) //Up and Right
                        {
                            swagNote.x += FlxG.width / 2 + 25;
                        }
                    }
                    if(!noteTypes.contains(swagNote.noteType)) {
                        noteTypes.push(swagNote.noteType);
                    }
    
                }
                // daBeats += 1;
                
            } return allNotes;}
            
    
        var debugNum:Int = 0;
        var stair:Int = 0;
        var noteIndex:Int = -1;
        private var noteTypes:Array<String> = [];
        private var eventsPushed:Array<String> = [];
        private function generateSong(dataPath:String):Array<Note>
        {
           var SONG = Song.loadFromJson(dataPath);
            songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');
    
            // switch(songSpeedType)
            // {
            //     case "multiplicative":
            //         songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
            //     case "constant":
            //         songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
            // }
    
            var songData = SONG;
            // Conductor.changeBPM(songData.bpm);
    
            var curSong = songData.song;
    
    
            // Paths.inst(curSong.toLowerCase());
            // Paths.voices(curSong.toLowerCase());
            
            // vocals = new FlxSound();
            // opponentVocals = new FlxSound();
            // gfVocals = new FlxSound();
    
            // try 
            // {
            //     if (songData.needsVoices && songData.newVoiceStyle)
            //     {
            //         var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'player' : boyfriend.vocalsFile);
            //         if(playerVocals != null) 
            //         {
            //             vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.music('empty'));
            //             FlxG.sound.list.add(vocals);
            //         }
    
            //         var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'opponent' : dad.vocalsFile);
            //         if(oppVocals != null) 
            //         {
            //             opponentVocals.loadEmbedded(oppVocals != null ? oppVocals : Paths.music('empty'));
            //             FlxG.sound.list.add(opponentVocals);
            //         }
    
            //         if (((dad.vocalsFile == null || dad.vocalsFile.length < 1) && dad.vocalsFile != 'gf') && ((boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) && boyfriend.vocalsFile != 'gf'))
            //         {	
            //             var gfVoc = Paths.voices(songData.song, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'gf' : dad.vocalsFile);
            //             if(gfVoc != null) 
            //             {
            //                 gfVocals.loadEmbedded(gfVoc != null ? gfVoc : Paths.music('empty'));
            //                 FlxG.sound.list.add(gfVocals);
            //             }
            //         }
            //     }
            //     else if (songData.needsVoices && !songData.newVoiceStyle)
            //     {
            //         var playerVocals = Paths.voices(songData.song);
            //         if(playerVocals != null) 
            //         {
            //             vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));
            //             FlxG.sound.list.add(vocals);
            //         }
            //     }
            // }
            // catch(e) {}
    
            // inst = new FlxSound();
            // try {
            //     inst.loadEmbedded(Paths.inst(songData.song));
            // }
            // catch(e:Dynamic) 
            // {
            //     inst.loadEmbedded(Paths.music('empty'));
            // }
            // FlxG.sound.list.add(inst);
    
            if (SONG.extraTracks != null){
                for (trackName in SONG.extraTracks){
                    var newTrack = Paths.track(songData.song, trackName);
                    if(newTrack != null)
                    {
                        tracks.push(newTrack);
                        FlxG.sound.list.add(newTrack);
                    }
                }
            }
    
            add(notes);
    
            var noteData:Array<SwagSection>;
    
            // NEW SHIT
            noteData = songData.notes;
    
            var playerCounter:Int = 0;
            var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
    
            var songName:String = Paths.formatToSongPath(SONG.song);
            var file:String = Paths.json(songName + '/events');
            #if MODS_ALLOWED
            if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
            #else
            if (OpenFlAssets.exists(file)) {
            #end
                var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
                for (event in eventsData) //Event Notes
                    for (i in 0...event[1].length)
                        makeEvent(event, i);
            }
    
    
            speedChanges.sort(svSort);
    
           return generateChart(noteData, SONG);
        }
        return null;
    }
    public static function get(filePath:String):Dynamic {
        return cache.get(filePath);
    }

    public static function exists(filePath:String):Bool {
        return cache.exists(filePath);
    }

    public static function clearCache():Void {
        cache = new Map<String, Dynamic>();
    }

    public static function remove(filePath:String):Void {
        cache.remove(filePath);
    }

    public static function update(filePath:String, data:Dynamic):Void {
        cache.set(filePath, data);
    }

    public static function save(filePath:String):Void {
        var data = cache.get(filePath);
        var jsonData = haxe.Json.stringify(data);
        sys.io.File.saveContent(filePath, jsonData);
    }

    public static function saveAll():Void {
        for (filePath in cache.keys()) {
            save(filePath);
        }
    }

    public static function loadAll():Void {
        for (filePath in cache.keys()) {
            loadJson(filePath, function(data:Dynamic) {
                trace("Loaded data from: " + filePath);
            });
        }
    }

    public static function printCache():Void {
        for (filePath in cache.keys()) {
            trace(filePath + " : " + cache.get(filePath));
        }
    }

    public static function pushCache():Map<String, Dynamic> {
        return cache;
    }

    public static function popCache(newCache:Map<String, Dynamic>):Void {
        cache = newCache;
    }
}
        