package setup;

import backend.MusicBeatSubstate;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

/**
 * Custom substate for mod installation choice
 */
class ModInstallChoiceSubstate extends MusicBeatSubstate {
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var messageText:FlxText;
    var folderButton:FlxSprite;
    var folderButtonText:FlxText;
    var zipButton:FlxSprite;
    var zipButtonText:FlxText;
    var cancelButton:FlxSprite;
    var cancelButtonText:FlxText;

    var onFolder:Void->Void;
    var onZip:Void->Void;
    var selectedButton:Int = 0;

    public function new(onFolder:Void->Void, onZip:Void->Void) {
        super();
        this.onFolder = onFolder;
        this.onZip = onZip;
    }

    override function create() {
        super.create();

        background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
        add(background);

        panel = FlxGradient.createGradientFlxSprite(450, 300, [0xFF1a1a2e, 0xFF16213e], 1, 90);
        panel.x = (FlxG.width - panel.width) / 2;
        panel.y = (FlxG.height - panel.height) / 2;
        add(panel);

        titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, "Install Mod", 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        messageText = new FlxText(panel.x + 20, panel.y + 70, panel.width - 40,
            "📁 How would you like to add a mod?\n\n• Folder: Select a mod folder\n• ZIP: Select a mod ZIP file", 16);
        messageText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        messageText.borderSize = 1;
        add(messageText);

        var buttonY = panel.y + panel.height - 70;
        var buttonWidth = 100;
        var buttonHeight = 40;

        folderButton = new FlxSprite(panel.x + 30, buttonY);
        folderButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.BLUE);
        add(folderButton);

        folderButtonText = new FlxText(folderButton.x, folderButton.y + 10, buttonWidth, "FOLDER", 16);
        folderButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        folderButtonText.borderSize = 1;
        add(folderButtonText);

        zipButton = new FlxSprite(panel.x + 160, buttonY);
        zipButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.GREEN);
        add(zipButton);

        zipButtonText = new FlxText(zipButton.x, zipButton.y + 10, buttonWidth, "ZIP FILE", 16);
        zipButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        zipButtonText.borderSize = 1;
        add(zipButtonText);

        cancelButton = new FlxSprite(panel.x + 290, buttonY);
        cancelButton.makeGraphic(buttonWidth, buttonHeight, FlxColor.RED);
        add(cancelButton);

        cancelButtonText = new FlxText(cancelButton.x, cancelButton.y + 10, buttonWidth, "CANCEL", 16);
        cancelButtonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        cancelButtonText.borderSize = 1;
        add(cancelButtonText);

        updateButtonSelection();
    }

    function updateButtonSelection() {
        folderButton.alpha = selectedButton == 0 ? 1.0 : 0.7;
        zipButton.alpha = selectedButton == 1 ? 1.0 : 0.7;
        cancelButton.alpha = selectedButton == 2 ? 1.0 : 0.7;

        folderButtonText.color = selectedButton == 0 ? FlxColor.YELLOW : FlxColor.WHITE;
        zipButtonText.color = selectedButton == 1 ? FlxColor.YELLOW : FlxColor.WHITE;
        cancelButtonText.color = selectedButton == 2 ? FlxColor.YELLOW : FlxColor.WHITE;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.UI_LEFT_P && selectedButton > 0) {
            selectedButton--;
            updateButtonSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.UI_RIGHT_P && selectedButton < 2) {
            selectedButton++;
            updateButtonSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.ACCEPT) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            if (selectedButton == 0) {
                onFolder();
            } else if (selectedButton == 1) {
                onZip();
            }
            close();
        }

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            close();
        }

        if (FlxG.mouse.overlaps(folderButton) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            onFolder();
            close();
        }

        if (FlxG.mouse.overlaps(zipButton) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            onZip();
            close();
        }

        if (FlxG.mouse.overlaps(cancelButton) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            close();
        }
    }
}
