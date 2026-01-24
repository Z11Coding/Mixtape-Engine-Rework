package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import backend.Paths;

class ConfirmationSubstate extends FlxSubState
{
    var message:String;
    var onYes:Void->Void;
    var onNo:Void->Void;

    var bg:FlxSprite;
    var dialogBox:FlxSprite;
    var messageText:FlxText;
    var yesButton:FlxUIButton;
    var noButton:FlxUIButton;

    public function new(message:String, onYes:Void->Void, ?onNo:Void->Void)
    {
        super();
        this.message = message;
        this.onYes = onYes;
        this.onNo = onNo != null ? onNo : function() {};
    }

    override function create()
    {
        super.create();

        // Semi-transparent background
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        add(bg);

        // Dialog box
        dialogBox = new FlxSprite().makeGraphic(400, 200, FlxColor.GRAY);
        dialogBox.screenCenter();
        add(dialogBox);

        // Message text
        messageText = new FlxText(dialogBox.x + 20, dialogBox.y + 20, dialogBox.width - 40, message);
        messageText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        add(messageText);

        // Yes button
        yesButton = new FlxUIButton(dialogBox.x + 80, dialogBox.y + dialogBox.height - 60, "Yes", clickYes);
        yesButton.resize(80, 30);
        add(yesButton);

        // No button
        noButton = new FlxUIButton(dialogBox.x + 240, dialogBox.y + dialogBox.height - 60, "No", clickNo);
        noButton.resize(80, 30);
        add(noButton);

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

    function clickYes()
    {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        onYes();
        close();
    }

    function clickNo()
    {
        FlxG.sound.play(Paths.sound('cancelMenu'));
        onNo();
        close();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        // ESC to cancel
        if (FlxG.keys.justPressed.ESCAPE)
        {
            clickNo();
        }

        // Enter to confirm
        if (FlxG.keys.justPressed.ENTER)
        {
            clickYes();
        }
    }
}