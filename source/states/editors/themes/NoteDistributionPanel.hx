package states.editors.themes;

import backend.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Note Distribution Panel
 * Shows how notes are distributed across sections and lanes
 * with visual charts and statistics
 */
class NoteDistributionPanel extends MixtapeThemePanel
{
    // Distribution data
    var sectionDistribution:Array<Int> = [];
    var laneDistribution:Array<Int> = [0, 0, 0, 0, 0, 0, 0, 0]; // 8 lanes (4 player + 4 opponent)
    var maxNotesInSection:Int = 0;

    // Visual elements
    var distributionChart:FlxSprite;
    var laneChart:FlxSprite;
    var distributionText:FlxText;
    var balanceText:FlxText;
    var asymmetryText:FlxText;

    // Chart dimensions
    var chartWidth:Int;
    var chartHeight:Int;

    public function new(x:Float, y:Float, width:Float, height:Float, theme:MixtapeChartTheme)
    {
        super(x, y, width, height, "Note Distribution", theme);

        chartWidth = Std.int(panelWidth - 20);
        chartHeight = Std.int((panelHeight - 100) / 2); // Split space for two charts

        createDistributionElements();
    }

    override function createContentArea():Void
    {
        super.createContentArea();
        createDistributionElements();
    }

    function createDistributionElements():Void
    {
        var contentY = panelY + 35;

        // Distribution summary text
        distributionText = createDistributionText(panelX + 10, contentY, "Analyzing distribution...", MixtapeChartTheme.textColor, 10);
        contentY += 15;

        // Balance analysis text
        balanceText = createDistributionText(panelX + 10, contentY, "Balance: Unknown", MixtapeChartTheme.accentColor, 10);
        contentY += 20;

        // Section distribution chart background
        var sectionChartBg = new FlxSprite(panelX + 10, contentY);
        sectionChartBg.makeGraphic(chartWidth, chartHeight, FlxColor.fromRGB(
            Std.int(MixtapeChartTheme.panelBg.red * 0.7),
            Std.int(MixtapeChartTheme.panelBg.green * 0.7),
            Std.int(MixtapeChartTheme.panelBg.blue * 0.7)
        ));
        contentArea.add(sectionChartBg);

        // Section distribution chart
        distributionChart = new FlxSprite(panelX + 10, contentY);
        distributionChart.makeGraphic(chartWidth, chartHeight, FlxColor.TRANSPARENT, true);
        contentArea.add(distributionChart);

        contentY += chartHeight + 10;

        // Lane distribution chart background
        var laneChartBg = new FlxSprite(panelX + 10, contentY);
        laneChartBg.makeGraphic(chartWidth, chartHeight, FlxColor.fromRGB(
            Std.int(MixtapeChartTheme.panelBg.red * 0.7),
            Std.int(MixtapeChartTheme.panelBg.green * 0.7),
            Std.int(MixtapeChartTheme.panelBg.blue * 0.7)
        ));
        contentArea.add(laneChartBg);

        // Lane distribution chart
        laneChart = new FlxSprite(panelX + 10, contentY);
        laneChart.makeGraphic(chartWidth, chartHeight, FlxColor.TRANSPARENT, true);
        contentArea.add(laneChart);

        contentY += chartHeight + 5;

        // Asymmetry analysis
        asymmetryText = createDistributionText(panelX + 10, contentY, "Asymmetry: Calculating...", MixtapeChartTheme.textColor, 10);

        refreshDistributionData();
    }

    function createDistributionText(x:Float, y:Float, text:String, color:FlxColor, size:Int):FlxText
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
        refreshDistributionData();
        drawDistributionCharts();
        updateDistributionText();
    }

    function refreshDistributionData():Void
    {
        if (theme.chartingState == null || theme.chartingState._song == null) return;

        var song = theme.chartingState._song;

        // Reset data
        sectionDistribution = [];
        laneDistribution = [0, 0, 0, 0, 0, 0, 0, 0];
        maxNotesInSection = 0;

        // Analyze each section
        for (i in 0...song.notes.length)
        {
            var section = song.notes[i];
            var sectionNoteCount = 0;

            if (section.sectionNotes != null)
            {
                for (note in section.sectionNotes)
                {
                    var noteData = Std.int(note[1]);

                    // Count notes in each lane
                    if (noteData >= 0 && noteData < 8)
                    {
                        laneDistribution[noteData]++;
                        sectionNoteCount++;
                    }
                }
            }

            sectionDistribution.push(sectionNoteCount);
            if (sectionNoteCount > maxNotesInSection)
                maxNotesInSection = sectionNoteCount;
        }
    }

    function drawDistributionCharts():Void
    {
        drawSectionDistributionChart();
        drawLaneDistributionChart();
    }

    function drawSectionDistributionChart():Void
    {
        if (distributionChart == null || sectionDistribution.length == 0) return;

        distributionChart.pixels.fillRect(distributionChart.pixels.rect, FlxColor.TRANSPARENT);

        var barWidth = Math.max(1, chartWidth / sectionDistribution.length);
        var maxHeight = chartHeight - 20; // Leave space for labels

        for (i in 0...sectionDistribution.length)
        {
            var noteCount = sectionDistribution[i];
            var barHeight = maxNotesInSection > 0 ? Std.int((noteCount / maxNotesInSection) * maxHeight) : 0;

            var x = Std.int(i * barWidth);
            var y = maxHeight - barHeight;

            // Color coding based on note density
            var barColor = getIntensityColor(noteCount, maxNotesInSection);

            // Draw bar
            for (bx in x...Std.int(x + barWidth - 1))
            {
                for (by in y...maxHeight)
                {
                    if (bx >= 0 && bx < chartWidth && by >= 0 && by < chartHeight)
                    {
                        distributionChart.pixels.setPixel32(bx, by, barColor);
                    }
                }
            }

            // Draw outline
            drawBarOutline(x, y, Std.int(barWidth - 1), barHeight, FlxColor.WHITE);
        }

        distributionChart.dirty = true;
    }

    function drawLaneDistributionChart():Void
    {
        if (laneChart == null) return;

        laneChart.pixels.fillRect(laneChart.pixels.rect, FlxColor.TRANSPARENT);

        var maxNotes = 0;
        for (count in laneDistribution)
        {
            if (count > maxNotes) maxNotes = count;
        }

        if (maxNotes == 0) return;

        var barWidth = chartWidth / 8; // 8 lanes
        var maxHeight = chartHeight - 20;

        for (i in 0...8)
        {
            var noteCount = laneDistribution[i];
            var barHeight = Std.int((noteCount / maxNotes) * maxHeight);

            var x = Std.int(i * barWidth);
            var y = maxHeight - barHeight;

            // Color coding: opponent lanes vs player lanes
            var barColor = i < 4 ? MixtapeChartTheme.accentColor : MixtapeChartTheme.secondaryColor;

            // Draw bar
            for (bx in x...Std.int(x + barWidth - 2))
            {
                for (by in y...maxHeight)
                {
                    if (bx >= 0 && bx < chartWidth && by >= 0 && by < chartHeight)
                    {
                        laneChart.pixels.setPixel32(bx, by, barColor);
                    }
                }
            }

            // Draw outline
            drawBarOutline(x, y, Std.int(barWidth - 2), barHeight, FlxColor.WHITE);

            // Draw lane number
            var laneLabel = '${i % 4}';
            // Note: In a real implementation, you'd draw text on the chart
        }

        laneChart.dirty = true;
    }

    function drawBarOutline(x:Int, y:Int, width:Int, height:Int, color:FlxColor):Void
    {
        // Top line
        for (i in 0...width)
        {
            if (x + i >= 0 && x + i < chartWidth && y >= 0 && y < chartHeight)
                distributionChart.pixels.setPixel32(x + i, y, color);
        }

        // Bottom line
        for (i in 0...width)
        {
            if (x + i >= 0 && x + i < chartWidth && y + height - 1 >= 0 && y + height - 1 < chartHeight)
                distributionChart.pixels.setPixel32(x + i, y + height - 1, color);
        }

        // Left line
        for (i in 0...height)
        {
            if (x >= 0 && x < chartWidth && y + i >= 0 && y + i < chartHeight)
                distributionChart.pixels.setPixel32(x, y + i, color);
        }

        // Right line
        for (i in 0...height)
        {
            if (x + width - 1 >= 0 && x + width - 1 < chartWidth && y + i >= 0 && y + i < chartHeight)
                distributionChart.pixels.setPixel32(x + width - 1, y + i, color);
        }
    }

    function getIntensityColor(value:Int, maxValue:Int):FlxColor
    {
        if (maxValue == 0) return MixtapeChartTheme.primaryColor;

        var intensity = value / maxValue;

        if (intensity < 0.3)
            return FlxColor.interpolate(MixtapeChartTheme.primaryColor, FlxColor.GREEN, 0.7);
        else if (intensity < 0.6)
            return FlxColor.interpolate(FlxColor.GREEN, FlxColor.YELLOW, (intensity - 0.3) / 0.3);
        else if (intensity < 0.8)
            return FlxColor.interpolate(FlxColor.YELLOW, FlxColor.ORANGE, (intensity - 0.6) / 0.2);
        else
            return FlxColor.interpolate(FlxColor.ORANGE, FlxColor.RED, (intensity - 0.8) / 0.2);
    }

    function updateDistributionText():Void
    {
        // Calculate distribution statistics
        var totalNotes = 0;
        for (count in laneDistribution)
            totalNotes += count;

        var playerNotes = laneDistribution[4] + laneDistribution[5] + laneDistribution[6] + laneDistribution[7];
        var opponentNotes = laneDistribution[0] + laneDistribution[1] + laneDistribution[2] + laneDistribution[3];

        // Update distribution text
        if (distributionText != null)
        {
            var avgNotesPerSection = sectionDistribution.length > 0 ? Math.round((totalNotes / sectionDistribution.length) * 100) / 100 : 0;
            distributionText.text = 'Total: $totalNotes notes, Avg/Section: $avgNotesPerSection';
        }

        // Update balance text
        if (balanceText != null)
        {
            var balance = totalNotes > 0 ? Math.round((playerNotes / totalNotes) * 100) : 50;
            var balanceStatus = getBalanceStatus(balance);
            balanceText.text = 'Player/Opponent: $playerNotes/$opponentNotes ($balance% player) - $balanceStatus';
        }

        // Update asymmetry text
        if (asymmetryText != null)
        {
            var asymmetry = calculateLaneAsymmetry();
            asymmetryText.text = 'Lane Balance: ${asymmetry}% asymmetry';
        }
    }

    function getBalanceStatus(playerPercent:Int):String
    {
        if (playerPercent >= 45 && playerPercent <= 55)
            return "Balanced";
        else if (playerPercent > 60)
            return "Player Heavy";
        else if (playerPercent < 40)
            return "Opponent Heavy";
        else
            return "Slightly Unbalanced";
    }

    function calculateLaneAsymmetry():Int
    {
        // Calculate how evenly notes are distributed across lanes within each side
        var playerLanes = [laneDistribution[4], laneDistribution[5], laneDistribution[6], laneDistribution[7]];
        var opponentLanes = [laneDistribution[0], laneDistribution[1], laneDistribution[2], laneDistribution[3]];

        var playerAsymmetry = calculateSideAsymmetry(playerLanes);
        var opponentAsymmetry = calculateSideAsymmetry(opponentLanes);

        return Math.round((playerAsymmetry + opponentAsymmetry) / 2);
    }

    function calculateSideAsymmetry(lanes:Array<Int>):Float
    {
        var total = 0;
        for (count in lanes) total += count;

        if (total == 0) return 0;

        var average = total / 4;
        var variance = 0.0;

        for (count in lanes)
        {
            var diff = count - average;
            variance += diff * diff;
        }

        var standardDeviation = Math.sqrt(variance / 4);
        return (standardDeviation / average) * 100; // Return as percentage
    }

    override function updatePositions():Void
    {
        super.updatePositions();

        var contentY = panelY + 35;

        if (distributionText != null) { distributionText.setPosition(panelX + 10, contentY); contentY += 15; }
        if (balanceText != null) { balanceText.setPosition(panelX + 10, contentY); }

        // Charts will be repositioned when the panel is recreated
    }

    override function savePanelPosition():Void
    {
        theme.layoutConfig.noteDistPanel.x = panelX;
        theme.layoutConfig.noteDistPanel.y = panelY;
        theme.saveLayoutConfig();
    }

    override function savePanelSize():Void
    {
        theme.layoutConfig.noteDistPanel.width = panelWidth;
        theme.layoutConfig.noteDistPanel.height = panelHeight;
        theme.saveLayoutConfig();
    }
}
