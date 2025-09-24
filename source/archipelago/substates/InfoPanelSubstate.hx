package archipelago.substates;

import backend.MusicBeatSubstate;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;

/**
 * A substate that displays info panels as overlays
 */
class InfoPanelSubstate extends MusicBeatSubstate {
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var infoText:FlxText;
    var closeButton:FlxSprite;
    var closeButtonText:FlxText;

    var isAnimating:Bool = false;

    public function new(title:String, content:String, ?themeColor:FlxColor) {
        super();

        if (themeColor == null) themeColor = FlxColor.CYAN;

        setupBackground();
        setupPanel(title, content, themeColor);
        animateIn();
    }

    function setupBackground() {
        // Semi-transparent background that covers the entire screen
        background = new FlxSprite(0, 0);
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
        add(background);
    }

    function setupPanel(title:String, content:String, themeColor:FlxColor) {
        // Main info panel with gradient
        var panelWidth = 400;
        var panelHeight = 300;

        panel = FlxGradient.createGradientFlxSprite(panelWidth, panelHeight,
            [FlxColor.fromRGB(30, 30, 50), FlxColor.fromRGB(20, 20, 40)], 1, 90);
        panel.x = (FlxG.width - panelWidth) / 2;
        panel.y = (FlxG.height - panelHeight) / 2;
        add(panel);

        // Title
        titleText = new FlxText(panel.x + 20, panel.y + 20, panelWidth - 40, title, 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, themeColor, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Content
        infoText = new FlxText(panel.x + 20, panel.y + 60, panelWidth - 40, content, 14);
        infoText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        infoText.borderSize = 1;
        add(infoText);

        // Close button
        closeButton = new FlxSprite(panel.x + panelWidth - 80, panel.y + panelHeight - 50);
        closeButton.makeGraphic(60, 30, themeColor);
        add(closeButton);

        closeButtonText = new FlxText(closeButton.x, closeButton.y + 5, closeButton.width, "CLOSE", 12);
        closeButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
        closeButtonText.borderSize = 1;
        add(closeButtonText);
    }

    function animateIn() {
        isAnimating = true;

        // Scale in animation
        panel.scale.set(0.5, 0.5);
        panel.alpha = 0;
        titleText.alpha = 0;
        infoText.alpha = 0;
        closeButton.alpha = 0;
        closeButtonText.alpha = 0;

        FlxTween.tween(panel, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.4, {
            ease: FlxEase.backOut
        });

        FlxTween.tween(titleText, {alpha: 1}, 0.5, {
            ease: FlxEase.sineOut,
            startDelay: 0.1
        });

        FlxTween.tween(infoText, {alpha: 1}, 0.5, {
            ease: FlxEase.sineOut,
            startDelay: 0.2
        });

        FlxTween.tween(closeButton, {alpha: 1}, 0.3, {
            ease: FlxEase.sineOut,
            startDelay: 0.3,
            onComplete: function(_) {
                isAnimating = false;
            }
        });

        FlxTween.tween(closeButtonText, {alpha: 1}, 0.3, {
            ease: FlxEase.sineOut,
            startDelay: 0.3
        });
    }

    function animateOut(onComplete:Void->Void) {
        if (isAnimating) return;
        isAnimating = true;

        FlxTween.tween(panel, {"scale.x": 0.5, "scale.y": 0.5, alpha: 0}, 0.3, {
            ease: FlxEase.backIn,
            onComplete: function(_) {
                onComplete();
            }
        });

        FlxTween.tween(background, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (isAnimating) return;

        // Close on back/escape
        if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            close();
            return;
        }

        // Close button hover effect
        if (FlxG.mouse.overlaps(closeButton)) {
            closeButton.color = FlxColor.WHITE;
            closeButtonText.color = FlxColor.BLACK;

            if (FlxG.mouse.justPressed) {
                FlxG.sound.play(Paths.sound('confirmMenu'));
                close();
            }
        } else {
            closeButton.color = FlxColor.CYAN;
            closeButtonText.color = FlxColor.BLACK;
        }

        // Close if clicking outside the panel
        if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(panel)) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            closePanel();
        }
    }

    var isClosing:Bool = false;

    function closePanel() {
        if (isClosing) return;
        isClosing = true;

        animateOut(function() {
            forceClose();
        });
    }

    function forceClose() {
        super.close();
    }
}
