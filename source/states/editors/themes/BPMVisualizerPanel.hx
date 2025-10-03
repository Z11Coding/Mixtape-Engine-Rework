package states.editors.themes;

import backend.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
 * BPM Visualizer Panel
 * Shows a visual representation of BPM changes throughout the song
 * with a timeline and interactive elements
 */
class BPMVisualizerPanel extends MixtapeThemePanel
{
    // Visual elements
    var bpmGraph:FlxSprite;
    var timelineSprite:FlxSprite;
    var currentBPMText:FlxText;
    var timePositionText:FlxText;
    var bpmAtTimeText:FlxText;

    // BPM data
    var bpmPoints:Array<BPMPoint> = [];
    var maxBPM:Float = 0;
    var minBPM:Float = 999999;
    var graphWidth:Int;
    var graphHeight:Int;

    // Animation
    var pulseScale:Float = 1.0;
    var lastBeatTime:Float = 0;

    public function new(x:Float, y:Float, width:Float, height:Float, theme:MixtapeChartTheme)
    {
        super(x, y, width, height, "BPM Visualizer", theme);

        graphWidth = Std.int(panelWidth - 20);
        graphHeight = Std.int(panelHeight - 80); // Leave space for text

        createVisualizerElements();
    }

    override function createContentArea():Void
    {
        super.createContentArea();
        createVisualizerElements();
    }

    function createVisualizerElements():Void
    {
        var contentY = panelY + 35;

        // Current BPM display
        currentBPMText = createVisualizerText(panelX + 10, contentY, "Current BPM: 120", MixtapeChartTheme.accentColor, 12);
        contentY += 20;

        // Time position
        timePositionText = createVisualizerText(panelX + 10, contentY, "Time: 0:00", MixtapeChartTheme.textColor, 10);

        // BPM at current time
        bpmAtTimeText = createVisualizerText(panelX + 120, contentY, "BPM: 120", MixtapeChartTheme.textColor, 10);
        contentY += 25;

        // Create BPM graph background
        var graphBg = new FlxSprite(panelX + 10, contentY);
        graphBg.makeGraphic(graphWidth, graphHeight, FlxColor.fromRGBFloat(
            MixtapeChartTheme.panelBg.redFloat * 0.7,
            MixtapeChartTheme.panelBg.greenFloat * 0.7,
            MixtapeChartTheme.panelBg.blueFloat * 0.7
        ));
        contentArea.add(graphBg);

        // Timeline sprite for BPM visualization
        timelineSprite = new FlxSprite(panelX + 10, contentY);
        timelineSprite.makeGraphic(graphWidth, graphHeight, FlxColor.TRANSPARENT, true);
        contentArea.add(timelineSprite);

        // BPM graph overlay
        bpmGraph = new FlxSprite(panelX + 10, contentY);
        bpmGraph.makeGraphic(graphWidth, graphHeight, FlxColor.TRANSPARENT, true);
        contentArea.add(bpmGraph);

        refreshBPMData();
    }

    function createVisualizerText(x:Float, y:Float, text:String, color:FlxColor, size:Int):FlxText
    {
        var textObj = new FlxText(x, y, panelWidth - 20, text, size);
        textObj.setFormat(Paths.font("vcr.ttf"), size, color, LEFT);
        textObj.borderStyle = OUTLINE;
        textObj.borderColor = FlxColor.BLACK;
        textObj.borderSize = 1;
        contentArea.add(textObj);
        return textObj;
    }

    override public function refreshData():Void
    {
        refreshBPMData();
        updateCurrentTimeDisplay();
        drawBPMGraph();
    }

    function refreshBPMData():Void
    {
        if (theme.chartingState == null || theme.chartingState._song == null) return;

        var song = theme.chartingState._song;
        bpmPoints = [];
        maxBPM = song.bpm;
        minBPM = song.bpm;

        var currentTime:Float = 0;
        var currentBPM:Float = song.bpm;

        // Add initial BPM point
        bpmPoints.push({time: 0, bpm: currentBPM});

        // Process each section
        for (i in 0...song.notes.length)
        {
            var section = song.notes[i];
            var sectionBPM = section.bpm != null ? section.bpm : currentBPM;

            if (sectionBPM != currentBPM)
            {
                bpmPoints.push({time: currentTime, bpm: sectionBPM});
                currentBPM = sectionBPM;

                if (sectionBPM > maxBPM) maxBPM = sectionBPM;
                if (sectionBPM < minBPM) minBPM = sectionBPM;
            }

            // Calculate section duration
            var crochet = ((60 / sectionBPM) * 1000) / 4;
            var sectionLength = section.lengthInSteps != null ? section.lengthInSteps : 16;
            currentTime += (crochet * sectionLength) / 1000;
        }

        // Ensure we have a reasonable range for visualization
        if (maxBPM == minBPM)
        {
            maxBPM += 20;
            minBPM -= 20;
        }
    }

    function drawBPMGraph():Void
    {
        if (bpmGraph == null || bpmPoints.length == 0) return;

        bpmGraph.pixels.fillRect(bpmGraph.pixels.rect, FlxColor.TRANSPARENT);

        // Draw grid lines
        drawGridLines();

        // Draw BPM curve
        drawBPMCurve();

        // Draw current time indicator
        drawTimeIndicator();

        bpmGraph.dirty = true;
    }

    function drawGridLines():Void
    {
        var gridColor = FlxColor.fromRGBFloat(
            MixtapeChartTheme.primaryColor.redFloat * 0.3,
            MixtapeChartTheme.primaryColor.greenFloat * 0.3,
            MixtapeChartTheme.primaryColor.blueFloat * 0.3
        );

        // Horizontal grid lines (BPM levels)
        var bpmRange = maxBPM - minBPM;
        var gridSteps = 5;

        for (i in 0...gridSteps + 1)
        {
            var y = Std.int((i / gridSteps) * graphHeight);
            var bpmValue = maxBPM - (i / gridSteps) * bpmRange;

            // Draw horizontal line
            for (x in 0...graphWidth)
            {
                if (x % 4 == 0) // Dotted line
                    bpmGraph.pixels.setPixel32(x, y, gridColor);
            }
        }

        // Vertical grid lines (time)
        var timeSteps = 8;
        for (i in 0...timeSteps + 1)
        {
            var x = Std.int((i / timeSteps) * graphWidth);

            // Draw vertical line
            for (y in 0...graphHeight)
            {
                if (y % 4 == 0) // Dotted line
                    bpmGraph.pixels.setPixel32(x, y, gridColor);
            }
        }
    }

    function drawBPMCurve():Void
    {
        if (bpmPoints.length < 2) return;

        var songLength = getSongLength();
        var curveColor = MixtapeChartTheme.accentColor;
        var strokeWidth = 2;

        // Draw BPM changes as connected line segments
        for (i in 0...bpmPoints.length - 1)
        {
            var point1 = bpmPoints[i];
            var point2 = bpmPoints[i + 1];

            var x1 = Std.int((point1.time / songLength) * graphWidth);
            var y1 = Std.int(graphHeight - ((point1.bpm - minBPM) / (maxBPM - minBPM)) * graphHeight);

            var x2 = Std.int((point2.time / songLength) * graphWidth);
            var y2 = Std.int(graphHeight - ((point2.bpm - minBPM) / (maxBPM - minBPM)) * graphHeight);

            // Draw line segment
            drawLine(x1, y1, x2, y2, curveColor, strokeWidth);

            // Draw BPM change marker
            drawCircle(x2, y2, 3, FlxColor.WHITE);
        }

        // Draw current BPM pulse effect
        var currentTime = getCurrentTime();
        var currentBPM = getBPMAtTime(currentTime);
        var pulseX = Std.int((currentTime / songLength) * graphWidth);
        var pulseY = Std.int(graphHeight - ((currentBPM - minBPM) / (maxBPM - minBPM)) * graphHeight);

        var pulseSize = Std.int(3 + pulseScale * 2);
        drawCircle(pulseX, pulseY, pulseSize, MixtapeChartTheme.secondaryColor);
    }

    function drawTimeIndicator():Void
    {
        var currentTime = getCurrentTime();
        var songLength = getSongLength();

        if (songLength <= 0) return;

        var indicatorX = Std.int((currentTime / songLength) * graphWidth);
        var indicatorColor = MixtapeChartTheme.secondaryColor;

        // Draw vertical line for current time
        for (y in 0...graphHeight)
        {
            bpmGraph.pixels.setPixel32(indicatorX, y, indicatorColor);
            if (indicatorX > 0)
                bpmGraph.pixels.setPixel32(indicatorX - 1, y, FlxColor.fromRGBFloat(
                    indicatorColor.redFloat * 0.5,
                    indicatorColor.greenFloat * 0.5,
                    indicatorColor.blueFloat * 0.5
                ));
            if (indicatorX < graphWidth - 1)
                bpmGraph.pixels.setPixel32(indicatorX + 1, y, FlxColor.fromRGBFloat(
                    indicatorColor.redFloat * 0.5,
                    indicatorColor.greenFloat * 0.5,
                    indicatorColor.blueFloat * 0.5
                ));
        }
    }

    function drawLine(x1:Int, y1:Int, x2:Int, y2:Int, color:FlxColor, width:Int):Void
    {
        // Simple line drawing using Bresenham's algorithm
        var dx = Math.abs(x2 - x1);
        var dy = Math.abs(y2 - y1);
        var sx = x1 < x2 ? 1 : -1;
        var sy = y1 < y2 ? 1 : -1;
        var err = dx - dy;

        var x = x1;
        var y = y1;

        while (true)
        {
            // Draw pixel with width
            for (i in 0...width)
            {
                for (j in 0...width)
                {
                    var px = x + i - Std.int(width / 2);
                    var py = y + j - Std.int(width / 2);

                    if (px >= 0 && px < graphWidth && py >= 0 && py < graphHeight)
                    {
                        bpmGraph.pixels.setPixel32(px, py, color);
                    }
                }
            }

            if (x == x2 && y == y2) break;

            var e2 = 2 * err;
            if (e2 > -dy)
            {
                err -= dy;
                x += sx;
            }
            if (e2 < dx)
            {
                err += dx;
                y += sy;
            }
        }
    }

    function drawCircle(centerX:Int, centerY:Int, radius:Int, color:FlxColor):Void
    {
        for (x in (centerX - radius)...(centerX + radius + 1))
        {
            for (y in (centerY - radius)...(centerY + radius + 1))
            {
                var dx = x - centerX;
                var dy = y - centerY;
                if (dx * dx + dy * dy <= radius * radius)
                {
                    if (x >= 0 && x < graphWidth && y >= 0 && y < graphHeight)
                    {
                        bpmGraph.pixels.setPixel32(x, y, color);
                    }
                }
            }
        }
    }

    function updateCurrentTimeDisplay():Void
    {
        var currentTime = getCurrentTime();
        var currentBPM = getBPMAtTime(currentTime);

        if (currentBPMText != null)
        {
            currentBPMText.text = 'Current BPM: ${Math.round(currentBPM)}';
        }

        if (timePositionText != null)
        {
            var minutes = Math.floor(currentTime / 60);
            var seconds = Math.floor(currentTime % 60);
            timePositionText.text = 'Time: $minutes:${seconds < 10 ? "0" : ""}$seconds';
        }

        if (bpmAtTimeText != null)
        {
            bpmAtTimeText.text = 'BPM: ${Math.round(currentBPM)}';
        }

        // Update pulse animation based on current BPM
        updatePulseAnimation(currentBPM);
    }

    function updatePulseAnimation(bpm:Float):Void
    {
        var beatDuration = 60.0 / bpm; // seconds per beat
        var currentTimeInSong = getCurrentTime();

        var timeSinceLastBeat = (currentTimeInSong - lastBeatTime) % beatDuration;
        var beatProgress = timeSinceLastBeat / beatDuration;

        // Create pulse effect
        pulseScale = 1.0 + Math.sin(beatProgress * Math.PI * 2) * 0.3;

        if (beatProgress < 0.1 && timeSinceLastBeat > beatDuration * 0.9)
        {
            lastBeatTime = currentTimeInSong;
        }
    }

    function getCurrentTime():Float
    {
        // Get current time from charting state
        if (theme.chartingState != null && theme.chartingState.inst != null && theme.chartingState.inst.playing)
        {
            return theme.chartingState.inst.time / 1000.0;
        }
        return 0;
    }

    function getSongLength():Float
    {
        if (bpmPoints.length == 0) return 1;

        var lastPoint = bpmPoints[bpmPoints.length - 1];
        return Math.max(lastPoint.time, 1); // Ensure minimum length of 1 second
    }

    function getBPMAtTime(time:Float):Float
    {
        if (bpmPoints.length == 0) return 120;

        var currentBPM = bpmPoints[0].bpm;

        for (point in bpmPoints)
        {
            if (point.time <= time)
                currentBPM = point.bpm;
            else
                break;
        }

        return currentBPM;
    }

    override function updatePositions():Void
    {
        super.updatePositions();

        var contentY = panelY + 35;

        if (currentBPMText != null) { currentBPMText.setPosition(panelX + 10, contentY); contentY += 20; }
        if (timePositionText != null) { timePositionText.setPosition(panelX + 10, contentY); }
        if (bpmAtTimeText != null) { bpmAtTimeText.setPosition(panelX + 120, contentY); }
    }

    override function savePanelPosition():Void
    {
        theme.layoutConfig.bpmPanel.x = panelX;
        theme.layoutConfig.bpmPanel.y = panelY;
        theme.saveLayoutConfig();
    }

    override function savePanelSize():Void
    {
        theme.layoutConfig.bpmPanel.width = panelWidth;
        theme.layoutConfig.bpmPanel.height = panelHeight;
        theme.saveLayoutConfig();
    }
}

typedef BPMPoint = {
    time: Float,
    bpm: Float
}
