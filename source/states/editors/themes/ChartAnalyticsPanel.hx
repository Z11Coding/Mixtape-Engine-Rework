package states.editors.themes;

import backend.Song;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.Note;

/**
 * Advanced Chart Analytics Panel
 * Shows detailed information about the current chart including:
 * - Total notes, BPM changes, sections
 * - Note density analysis
 * - Difficulty metrics
 * - Time signatures and tempo analysis
 */
class ChartAnalyticsPanel extends MixtapeThemePanel
{
    // Text display elements
    var totalNotesText:FlxText;
    var bpmChangesText:FlxText;
    var sectionsText:FlxText;
    var difficultyText:FlxText;
    var densityText:FlxText;
    var timeSignatureText:FlxText;
    var songLengthText:FlxText;
    var notesPerSecondText:FlxText;
    var peakDensityText:FlxText;

    // Analytics data
    var totalNotes:Int = 0;
    var bpmChangeCount:Int = 0;
    var sectionCount:Int = 0;
    var averageNPS:Float = 0;
    var peakNPS:Float = 0;
    var difficultyRating:String = "Unknown";

    // Update timer for real-time analytics
    var updateTimer:FlxTimer;

    public function new(x:Float, y:Float, width:Float, height:Float, theme:MixtapeChartTheme)
    {
        super(x, y, width, height, "Chart Analytics", theme);

        createAnalyticsDisplay();

        // Set up real-time updates
        updateTimer = new FlxTimer();
        updateTimer.start(1.0, function(_) { refreshData(); }, 0); // Update every second
    }

    override function createContentArea():Void
    {
        super.createContentArea();
        createAnalyticsDisplay();
    }

    function createAnalyticsDisplay():Void
    {
        var startY = panelY + 35; // Below title bar
        var lineHeight = 18;
        var currentY = startY;

        // Total Notes
        totalNotesText = createAnalyticsText(panelX + 10, currentY, "Total Notes: 0", MixtapeChartTheme.textColor);
        currentY += lineHeight;

        // BPM Changes
        bpmChangesText = createAnalyticsText(panelX + 10, currentY, "BPM Changes: 0", MixtapeChartTheme.textColor);
        currentY += lineHeight;

        // Sections
        sectionsText = createAnalyticsText(panelX + 10, currentY, "Sections: 0", MixtapeChartTheme.textColor);
        currentY += lineHeight;

        // Song Length
        songLengthText = createAnalyticsText(panelX + 10, currentY, "Length: 0:00", MixtapeChartTheme.textColor);
        currentY += lineHeight;

        // Notes Per Second (Average)
        notesPerSecondText = createAnalyticsText(panelX + 10, currentY, "Avg NPS: 0.0", MixtapeChartTheme.accentColor);
        currentY += lineHeight;

        // Peak NPS
        peakDensityText = createAnalyticsText(panelX + 10, currentY, "Peak NPS: 0.0", MixtapeChartTheme.accentColor);
        currentY += lineHeight;

        // Time Signature
        timeSignatureText = createAnalyticsText(panelX + 10, currentY, "Time Sig: 4/4", MixtapeChartTheme.textColor);
        currentY += lineHeight;

        // Difficulty Rating
        difficultyText = createAnalyticsText(panelX + 10, currentY, "Difficulty: Unknown", MixtapeChartTheme.secondaryColor);
        currentY += lineHeight;

        // Note Density Analysis
        densityText = createAnalyticsText(panelX + 10, currentY, "Density: Analyzing...", MixtapeChartTheme.textColor);
    }

    function createAnalyticsText(x:Float, y:Float, text:String, color:FlxColor):FlxText
    {
        var textObj = new FlxText(x, y, panelWidth - 20, text, 11);
        textObj.setFormat(Paths.font("vcr.ttf"), 11, color, LEFT);
        textObj.borderStyle = OUTLINE;
        textObj.borderColor = FlxColor.BLACK;
        textObj.borderSize = 1;
        contentArea.add(textObj);
        return textObj;
    }

    override public function refreshData():Void
    {
        if (theme.chartingState == null || theme.chartingState._song == null) return;

        calculateAnalytics();
        updateDisplayText();
    }

    function calculateAnalytics():Void
    {
        var song = theme.chartingState._song;
        if (song == null) return;

        // Calculate total notes
        totalNotes = 0;
        for (section in song.notes)
        {
            if (section.sectionNotes != null)
            {
                totalNotes += section.sectionNotes.length;
            }
        }

        // Count BPM changes
        bpmChangeCount = 0;
        var lastBPM:Float = song.bpm;
        for (section in song.notes)
        {
            if (section.bpm != null && section.bpm != lastBPM)
            {
                bpmChangeCount++;
                lastBPM = section.bpm;
            }
        }

        // Section count
        sectionCount = song.notes.length;

        // Calculate song length and NPS
        calculateNoteDensity();

        // Calculate difficulty rating
        calculateDifficultyRating();
    }

    function calculateNoteDensity():Void
    {
        var song = theme.chartingState._song;
        if (song == null) return;

        // Calculate song length in seconds
        var songLength:Float = 0;
        var crochet = ((60 / song.bpm) * 1000) / 4; // Length of a step in ms

        for (section in song.notes)
        {
            songLength += crochet * (section.lengthInSteps != null ? section.lengthInSteps : 16);
        }
        songLength /= 1000; // Convert to seconds

        // Calculate average NPS
        averageNPS = songLength > 0 ? totalNotes / songLength : 0;

        // Calculate peak NPS (analyze in 4-second windows)
        peakNPS = calculatePeakNPS(song);
    }

    function calculatePeakNPS(song:SwagSong):Float
    {
        var windowSize:Float = 4.0; // 4-second analysis window
        var maxNPS:Float = 0;

        // Create time-stamped note array
        var timestampedNotes:Array<Float> = [];
        var currentTime:Float = 0;
        var crochet = ((60 / song.bpm) * 1000) / 4;

        for (section in song.notes)
        {
            var sectionBPM = section.bpm != null ? section.bpm : song.bpm;
            var sectionCrochet = ((60 / sectionBPM) * 1000) / 4;

            if (section.sectionNotes != null)
            {
                for (note in section.sectionNotes)
                {
                    timestampedNotes.push(currentTime + (note[0] - (currentTime * 1000)) / 1000);
                }
            }

            currentTime += (sectionCrochet * (section.lengthInSteps != null ? section.lengthInSteps : 16)) / 1000;
        }

        // Analyze in sliding windows
        timestampedNotes.sort(function(a, b) return Std.int(a - b));

        for (i in 0...timestampedNotes.length)
        {
            var windowStart = timestampedNotes[i];
            var windowEnd = windowStart + windowSize;
            var notesInWindow = 0;

            for (j in i...timestampedNotes.length)
            {
                if (timestampedNotes[j] <= windowEnd)
                    notesInWindow++;
                else
                    break;
            }

            var windowNPS = notesInWindow / windowSize;
            if (windowNPS > maxNPS)
                maxNPS = windowNPS;
        }

        return maxNPS;
    }

    function calculateDifficultyRating():Void
    {
        // Basic difficulty algorithm based on NPS and note patterns
        if (averageNPS < 2.0)
            difficultyRating = "Easy";
        else if (averageNPS < 4.0)
            difficultyRating = "Normal";
        else if (averageNPS < 6.0)
            difficultyRating = "Hard";
        else if (averageNPS < 8.0)
            difficultyRating = "Expert";
        else
            difficultyRating = "Insane";

        // Adjust based on peak NPS
        if (peakNPS > averageNPS * 2.5)
            difficultyRating += " (Spiky)";
    }

    function updateDisplayText():Void
    {
        if (totalNotesText != null)
            totalNotesText.text = 'Total Notes: $totalNotes';

        if (bpmChangesText != null)
            bpmChangesText.text = 'BPM Changes: $bpmChangeCount';

        if (sectionsText != null)
            sectionsText.text = 'Sections: $sectionCount';

        if (notesPerSecondText != null)
            notesPerSecondText.text = 'Avg NPS: ${Math.round(averageNPS * 100) / 100}';

        if (peakDensityText != null)
            peakDensityText.text = 'Peak NPS: ${Math.round(peakNPS * 100) / 100}';

        if (difficultyText != null)
            difficultyText.text = 'Difficulty: $difficultyRating';

        if (songLengthText != null)
        {
            var song = theme.chartingState._song;
            if (song != null)
            {
                var totalLength = calculateSongLength();
                var minutes = Math.floor(totalLength / 60);
                var seconds = Math.floor(totalLength % 60);
                songLengthText.text = 'Length: $minutes:${seconds < 10 ? "0" : ""}$seconds';
            }
        }

        if (timeSignatureText != null)
        {
            // For now, assume 4/4 - could be enhanced to detect from chart
            timeSignatureText.text = "Time Sig: 4/4";
        }

        if (densityText != null)
        {
            var density = totalNotes > 0 && sectionCount > 0 ? Math.round((totalNotes / sectionCount) * 100) / 100 : 0;
            densityText.text = 'Avg Notes/Section: $density';
        }
    }

    function calculateSongLength():Float
    {
        var song = theme.chartingState._song;
        if (song == null) return 0;

        var totalLength:Float = 0;
        var crochet = ((60 / song.bpm) * 1000) / 4;

        for (section in song.notes)
        {
            var sectionBPM = section.bpm != null ? section.bpm : song.bpm;
            var sectionCrochet = ((60 / sectionBPM) * 1000) / 4;
            totalLength += (sectionCrochet * (section.lengthInSteps != null ? section.lengthInSteps : 16)) / 1000;
        }

        return totalLength;
    }

    override function updatePositions():Void
    {
        super.updatePositions();

        // Update analytics text positions
        var startY = panelY + 35;
        var lineHeight = 18;
        var currentY = startY;

        if (totalNotesText != null) { totalNotesText.setPosition(panelX + 10, currentY); currentY += lineHeight; }
        if (bpmChangesText != null) { bpmChangesText.setPosition(panelX + 10, currentY); currentY += lineHeight; }
        if (sectionsText != null) { sectionsText.setPosition(panelX + 10, currentY); currentY += lineHeight; }
        if (songLengthText != null) { songLengthText.setPosition(panelX + 10, currentY); currentY += lineHeight; }
        if (notesPerSecondText != null) { notesPerSecondText.setPosition(panelX + 10, currentY); currentY += lineHeight; }
        if (peakDensityText != null) { peakDensityText.setPosition(panelX + 10, currentY); currentY += lineHeight; }
        if (timeSignatureText != null) { timeSignatureText.setPosition(panelX + 10, currentY); currentY += lineHeight; }
        if (difficultyText != null) { difficultyText.setPosition(panelX + 10, currentY); currentY += lineHeight; }
        if (densityText != null) { densityText.setPosition(panelX + 10, currentY); currentY += lineHeight; }
    }

    override function savePanelPosition():Void
    {
        theme.layoutConfig.analyticsPanel.x = panelX;
        theme.layoutConfig.analyticsPanel.y = panelY;
        theme.saveLayoutConfig();
    }

    override function savePanelSize():Void
    {
        theme.layoutConfig.analyticsPanel.width = panelWidth;
        theme.layoutConfig.analyticsPanel.height = panelHeight;
        theme.saveLayoutConfig();
    }

    override public function destroy():Void
    {
        if (updateTimer != null)
        {
            updateTimer.destroy();
            updateTimer = null;
        }

        super.destroy();
    }
}
