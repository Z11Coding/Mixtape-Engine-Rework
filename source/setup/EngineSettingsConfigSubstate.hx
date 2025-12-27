package setup;

import backend.MusicBeatSubstate;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import options.GameplaySettingsSubState;
import options.GraphicsSettingsSubState;
import options.NotesColorSubState;
import options.VisualsSettingsSubState;

/**
 * Engine settings configuration substate
 */
class EngineSettingsConfigSubstate extends MusicBeatSubstate {
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var settingsButtons:Array<FlxSprite> = [];
    var settingsTexts:Array<FlxText> = [];
    var settingsOptions:Array<String> = [];
    var selectedSetting:Int = 0;

    var onComplete:Void->Void;

    public function new(onComplete:Void->Void) {
        super();
        this.onComplete = onComplete;
    }

    override function create() {
        super.create();

        background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
        add(background);

        panel = FlxGradient.createGradientFlxSprite(600, 500, [0xFF1a1a2e, 0xFF16213e], 1, 90);
        panel.x = (FlxG.width - panel.width) / 2;
        panel.y = (FlxG.height - panel.height) / 2;
        add(panel);

        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, "Engine Settings", 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Settings options (excluding restricted ones)
        settingsOptions = ["Graphics", "Visuals", "Gameplay", "Note Colors"];

        createSettingsButtons();

        var instructionText = new FlxText(panel.x + 20, panel.y + panel.height - 80, panel.width - 40,
            "Select settings to configure. Press ENTER to open, ESC when done.", 14);
        instructionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        instructionText.borderSize = 1;
        add(instructionText);
    }

    function createSettingsButtons() {
        var startY = panel.y + 70;
        var buttonHeight = 50;
        var spacing = 10;

        for (i in 0...settingsOptions.length) {
            var option = settingsOptions[i];
            var buttonY = startY + (buttonHeight + spacing) * i;

            var button = new FlxSprite(panel.x + 50, buttonY);
            button.makeGraphic(Std.int(panel.width - 100), buttonHeight, FlxColor.fromRGB(50, 50, 80));
            add(button);
            settingsButtons.push(button);

            var text = new FlxText(button.x + 10, button.y + 15, button.width - 20, option, 18);
            text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
            text.borderSize = 1;
            add(text);
            settingsTexts.push(text);
        }

        updateButtonSelection();
    }

    function updateButtonSelection() {
        for (i in 0...settingsButtons.length) {
            var isSelected = i == selectedSetting;
            settingsButtons[i].color = isSelected ? FlxColor.fromRGB(80, 120, 180) : FlxColor.fromRGB(50, 50, 80);
            settingsTexts[i].color = isSelected ? FlxColor.YELLOW : FlxColor.WHITE;
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.UI_UP_P && selectedSetting > 0) {
            selectedSetting--;
            updateButtonSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.UI_DOWN_P && selectedSetting < settingsOptions.length - 1) {
            selectedSetting++;
            updateButtonSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.ACCEPT) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            openSettingsMenu(settingsOptions[selectedSetting]);
        }

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            onComplete();
            close();
        }

        // Mouse interactions
        for (i in 0...settingsButtons.length) {
            if (FlxG.mouse.overlaps(settingsButtons[i])) {
                if (selectedSetting != i) {
                    selectedSetting = i;
                    updateButtonSelection();
                    FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
                }

                if (FlxG.mouse.justPressed) {
                    FlxG.sound.play(Paths.sound('confirmMenu'));
                    openSettingsMenu(settingsOptions[i]);
                }
            }
        }
    }

    function openSettingsMenu(settingType:String) {
        switch (settingType) {
            case "Graphics":
                FlxG.state.openSubState(new GraphicsSettingsSubState());
            case "Visuals":
                FlxG.state.openSubState(new VisualsSettingsSubState());
            case "Gameplay":
                FlxG.state.openSubState(new GameplaySettingsSubState());
            case "Note Colors":
                FlxG.state.openSubState(new NotesColorSubState());
        }
    }
}
