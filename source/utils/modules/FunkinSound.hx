package backend.modules;

import flixel.system.FlxSound;

class FunkinSound extends SoundLayer {
    public var bpm:Float;
    public var sections:Array<{start:Float, end:Float}>;
    public var currentSectionIndex:Int;
    private var skipToNextSection:Bool;

    public function new(id:String, soundPath:String, bpm:Float) {
        super(id, soundPath);
        this.bpm = bpm;
        this.sections = [];
        this.currentSectionIndex = 0;
        this.skipToNextSection = false;
        
        // Calculate section start and end times based on bpm and assuming 4/4 time signature
        var sectionDuration:Float = 60.0 / bpm * 4; // Calculate duration of one section in seconds
        var totalDuration:Float = this.sound.length; // Get total duration of the sound in seconds
        
        // Create sections based on the calculated start and end times
        for (i in 0...Std.int(totalDuration / sectionDuration)) {
            var start:Float = i * sectionDuration;
            var end:Float = (i + 1) * sectionDuration;
            this.sections.push({start: start, end: end});
        }
    }

    public function addSection(start:Float, end:Float):Void {
        this.sections.push({start: start, end: end});
    }

    public function play():Void {
        this.sound.play();
        this.sound.onComplete = this.onSoundComplete;
    }

    private function onSoundComplete():Void {
        if (this.skipToNextSection && this.currentSectionIndex < this.sections.length - 1) {
            this.currentSectionIndex++;
            this.skipToNextSection = false;
            this.sound.time = this.sections[this.currentSectionIndex].start;
            this.sound.play();
        }
    }

    public function skipToSection(index:Int):Void {
        if (index >= 0 && index < this.sections.length) {
            this.currentSectionIndex = index;
            this.sound.time = this.sections[index].start;
            this.sound.play();
        }
    }

    public function queueChangeToSection(index:Int):Void {
        if (index >= 0 && index < this.sections.length) {
            this.currentSectionIndex = index;
            this.skipToNextSection = true;
        }
    }

    public function changeTimeSignature(newBPM:Float):Void {
        var ratio:Float = newBPM / this.bpm;
        this.sound.rate = ratio;
        this.bpm = newBPM;
    }

    public function keyChange(semitones:Int):Void {
        // Placeholder for key change logic
        // This would require more advanced audio processing
    }
}