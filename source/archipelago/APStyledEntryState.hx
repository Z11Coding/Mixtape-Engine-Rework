package archipelago;

import archipelago.*;
import archipelago.APAdvancedSettingsState;
import archipelago.APGameState;
import archipelago.Client;
import archipelago.PacketTypes.JSONMessagePart;
import archipelago.PacketTypes.NetworkItem;
import archipelago.substates.ConnectionSubstate;
import archipelago.substates.InfoPanelSubstate;
import archipelago.substates.PortInputSubstate;
import archipelago.substates.TextInputSubstate;
import backend.MusicBeatState;
import backend.ui.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
// import flixel.group.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import haxe.Exception;
import haxe.Timer;
import states.editors.content.FileDialogHandler;
import substates.Prompt;
import yutautil.modules.SyncUtils;

using yutautil.CollectionUtils;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

// Connection page structure for organizing connection options
typedef ConnectionPage = {
    var name:String;
    var description:String;
    var color:FlxColor;
}

class APStyledEntryState extends MusicBeatState {
    // Visual elements matching APAdvancedSettingsState style
    var bg:FlxSprite;
    var gradientOverlay:FlxSprite;
    var titleText:FlxText;
    var descriptionText:FlxText;
    var pageIndicator:FlxText;
    var infoPanel:FlxSprite;
    var infoText:FlxText;

    // Navigation elements
    var backButton:FlxSprite;
    var connectButton:FlxSprite;

    // Animation elements
    var particles:FlxTypedGroup<FlxSprite>;
    var glowEffect:FlxSprite;

    // Connection form elements
    var connectionPanel:FlxSprite;
    var hostField:FlxSprite;
    var portField:FlxSprite;
    var slotField:FlxSprite;
    var passwordField:FlxSprite;
    var hostText:FlxText;
    var portText:FlxText;
    var slotText:FlxText;
    var passwordText:FlxText;

    // Connection data
    var hostValue:String = "archipelago.gg";
    var portValue:String = "38281";
    var slotValue:String = "Player";
    var passwordValue:String = "";

    var connectionFields:Array<FlxSprite> = [];

    // Buttons and actions
    var settingsButton:FlxSprite;
    var yamlButton:FlxSprite;
    var installButton:FlxSprite;

    // Pages system
    var pages:Array<ConnectionPage> = [];
    var currentPage:Int = 0;

    // Animation state
    var isAnimating:Bool = false;
    var transitionTime:Float = 0.3;

    // Connection state
    var connectionElements:Array<FlxSprite> = [];

    // Static references from original APEntryState
    public static var ap:Client;
    public static var apGame:APGameState;
    public static var inArchipelagoMode:Bool = false;
    public static var gonnaRunSync:Bool = false;
    public static var lowFilterAmount:Float = 1;
    public static var deathLink:Bool = false;
    public static var victorySong:String = '???';
    public static var fullSongCount:Int = 1;

    static var currentAPLocation:String = new yutautil.save.MixSaveWrapper(null, "save/apLocation.json", true).getItem("apLocation") != null
        ? new yutautil.save.MixSaveWrapper(null, "save/apLocation.json", true).getItem("apLocation")
        : "C:/ProgramData/Archipelago";

    override function create() {
        super.create();

        if (!FlxG.sound.music.playing || FlxG.sound.music == null)
            MusicManager.playMenuMusic();

        Cursor.show();
        Cursor.cursorMode = Default;

        setupBackground();
        setupPages();
        setupUI();
        setupAnimations();
        loadLastGameSettings();

        // Animate in
        animateIn();

        // Setup particle system
        setupParticles();
    }

    function setupBackground() {
        // Dynamic gradient background (similar to APAdvancedSettingsState)
        bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [0xFF0d1a2e, 0xFF16213e, 0xFF0f3460], 1, 90);
        bg.scrollFactor.set();
        add(bg);

        // Animated overlay
        gradientOverlay = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
            [0x00000000, 0x3335ff6b, 0x00000000], 1, 0);
        gradientOverlay.scrollFactor.set();
        gradientOverlay.alpha = 0.6;
        add(gradientOverlay);

        // Animate overlay
        FlxTween.tween(gradientOverlay, {alpha: 0.8}, 2, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });
    }

    function setupPages() {
        pages = [
            {
                name: "CONNECTION",
                description: "Connect to your Archipelago server",
                color: FlxColor.CYAN
            }
        ];
    }

    function setupUI() {
        // Title
        titleText = new FlxText(50, 30, FlxG.width - 100, "FRIDAY NIGHT FUNKIN: ARCHIPELAGO", 48);
        titleText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 3;
        add(titleText);

        // Description
        descriptionText = new FlxText(50, 90, FlxG.width - 100, "", 20);
        descriptionText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 1;
        add(descriptionText);

        // Page indicator (simplified for single page)
        pageIndicator = new FlxText(50, FlxG.height - 140, FlxG.width - 100, "", 16);
        pageIndicator.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        pageIndicator.borderSize = 1;
        add(pageIndicator);

        // Bottom buttons
        connectButton = new FlxSprite(Std.int(FlxG.width / 2) - 200, Std.int(FlxG.height - 80));
        connectButton.makeGraphic(180, 50, FlxColor.GREEN);
        add(connectButton);

        var connectText = new FlxText(connectButton.x, connectButton.y + 10, connectButton.width, "CONNECT", 16);
        connectText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        connectText.borderSize = 1;
        add(connectText);

        backButton = new FlxSprite(Std.int(FlxG.width / 2) + 20, Std.int(FlxG.height - 80));
        backButton.makeGraphic(180, 50, FlxColor.RED);
        add(backButton);

        var backText = new FlxText(backButton.x, backButton.y + 10, backButton.width, "BACK", 16);
        backText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        backText.borderSize = 1;
        add(backText);

        // Info panel
        setupInfoPanel();

        // Connection panel
        setupConnectionPanel();

        // Load initial page
        loadPage();
    }

    function setupInfoPanel() {
        // Instead of always visible panel, create an info button
        infoPanel = new FlxSprite(FlxG.width - 100, 30);
        infoPanel.makeGraphic(80, 40, FlxColor.fromRGB(60, 60, 100));
        infoPanel.alpha = 0.9;
        add(infoPanel);

        infoText = new FlxText(infoPanel.x, infoPanel.y + 10, infoPanel.width, "INFO", 14);
        infoText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        infoText.borderSize = 1;
        add(infoText);
    }

    function setupConnectionPanel() {
        connectionPanel = new FlxSprite(100, 140);
        connectionPanel.makeGraphic(FlxG.width - 250, 250, FlxColor.fromRGB(20, 20, 40)); // Reduced width to avoid overlap
        connectionPanel.alpha = 0.9;
        add(connectionPanel);

        // Connection form fields
        var startY = connectionPanel.y + 30;
        var spacing = 50;
        var fieldWidth = 300;
        var fieldHeight = 30;

        // Host field
        var hostLabel = new FlxText(connectionPanel.x + 20, startY, 100, "Host:", 16);
        hostLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        hostLabel.borderSize = 1;
        add(hostLabel);

        hostField = new FlxSprite(connectionPanel.x + 120, startY - 5);
        hostField.makeGraphic(fieldWidth, fieldHeight, FlxColor.fromRGB(40, 40, 70));
        add(hostField);

        hostText = new FlxText(hostField.x + 5, hostField.y + 5, fieldWidth - 10, hostValue, 14);
        hostText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        hostText.borderSize = 1;
        add(hostText);

        // Port field
        var portLabel = new FlxText(connectionPanel.x + 20, startY + spacing, 100, "Port:", 16);
        portLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        portLabel.borderSize = 1;
        add(portLabel);

        portField = new FlxSprite(connectionPanel.x + 120, startY + spacing - 5);
        portField.makeGraphic(fieldWidth, fieldHeight, FlxColor.fromRGB(40, 40, 70));
        add(portField);

        portText = new FlxText(portField.x + 5, portField.y + 5, fieldWidth - 10, portValue, 14);
        portText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        portText.borderSize = 1;
        add(portText);

        // Slot field
        var slotLabel = new FlxText(connectionPanel.x + 20, startY + spacing * 2, 100, "Slot Name:", 16);
        slotLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        slotLabel.borderSize = 1;
        add(slotLabel);

        slotField = new FlxSprite(connectionPanel.x + 120, startY + spacing * 2 - 5);
        slotField.makeGraphic(fieldWidth, fieldHeight, FlxColor.fromRGB(40, 40, 70));
        add(slotField);

        slotText = new FlxText(slotField.x + 5, slotField.y + 5, fieldWidth - 10, slotValue, 14);
        slotText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        slotText.borderSize = 1;
        add(slotText);

        // Password field
        var pwLabel = new FlxText(connectionPanel.x + 20, startY + spacing * 3, 100, "Password:", 16);
        pwLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        pwLabel.borderSize = 1;
        add(pwLabel);

        passwordField = new FlxSprite(connectionPanel.x + 120, startY + spacing * 3 - 5);
        passwordField.makeGraphic(fieldWidth, fieldHeight, FlxColor.fromRGB(40, 40, 70));
        add(passwordField);

        passwordText = new FlxText(passwordField.x + 5, passwordField.y + 5, fieldWidth - 10, maskPassword(passwordValue), 14);
        passwordText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        passwordText.borderSize = 1;
        add(passwordText);

        connectionFields = [hostField, portField, slotField, passwordField];

        // Side buttons for different pages
        setupSideButtons();
    }

    function maskPassword(password:String):String {
        if (password.length == 0) return "(Click to set password)";
        var masked = "";
        for (i in 0...password.length) {
            masked += "•";
        }
        return masked;
    }

    function openHostInput() {
        var hostInput = new TextInputSubstate(
            "Server Host",
            hostValue,
            function(newHost:String) {
                hostValue = newHost;
                if (hostText != null) hostText.text = hostValue;
            },
            function() {
                // Cancel callback - do nothing
            },
            100, // Max length
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_", // Allowed characters
            "Enter the Archipelago server address (e.g., archipelago.gg)",
            FlxColor.CYAN
        );
        openSubState(hostInput);
    }

    function openPortInput() {
        var portInput = new PortInputSubstate(
            portValue,
            function(newPort:String) {
                portValue = newPort;
                if (portText != null) portText.text = portValue;
            },
            function() {
                // Cancel callback - do nothing
            }
        );
        openSubState(portInput);
    }

    function openSlotInput() {
        var slotInput = new TextInputSubstate(
            "Slot Name",
            slotValue,
            function(newSlot:String) {
                slotValue = newSlot;
                if (slotText != null) slotText.text = slotValue;
            },
            function() {
                // Cancel callback - do nothing
            },
            30, // Max length
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_", // Allowed characters
            "Enter your player name from the YAML file",
            FlxColor.CYAN
        );
        openSubState(slotInput);
    }

    function openPasswordInput() {
        var passwordInput = new TextInputSubstate(
            "Server Password",
            passwordValue,
            function(newPassword:String) {
                passwordValue = newPassword;
                if (passwordText != null) passwordText.text = maskPassword(passwordValue);
            },
            function() {
                // Cancel callback - do nothing
            },
            50, // Max length
            "", // All characters allowed
            "Enter server password (leave empty if none required)",
            FlxColor.CYAN,
            true // Password mode - mask the input
        );
        openSubState(passwordInput);
    }

    function setupSideButtons() {
        var buttonY = connectionPanel.y + 20;
        var buttonSpacing = 60;

        // Settings button
        settingsButton = new FlxSprite(connectionPanel.x + connectionPanel.width + 20, buttonY);
        settingsButton.makeGraphic(120, 40, FlxColor.BLUE);
        add(settingsButton);

        var settingsText = new FlxText(settingsButton.x, settingsButton.y + 10, settingsButton.width, "SETTINGS", 12);
        settingsText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        settingsText.borderSize = 1;
        add(settingsText);

        // YAML button
        yamlButton = new FlxSprite(connectionPanel.x + connectionPanel.width + 20, buttonY + buttonSpacing);
        yamlButton.makeGraphic(120, 40, FlxColor.YELLOW);
        add(yamlButton);

        var yamlText = new FlxText(yamlButton.x, yamlButton.y + 10, yamlButton.width, "YAML", 12);
        yamlText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
        yamlText.borderSize = 1;
        add(yamlText);

        #if sys
        // Install button
        installButton = new FlxSprite(connectionPanel.x + connectionPanel.width + 20, buttonY + buttonSpacing * 2);
        var installText = FileSystem.exists(currentAPLocation + "/custom_worlds/fridaynightfunkin.apworld") ? "UPDATE" : "INSTALL";
        installButton.makeGraphic(120, 40, FlxColor.PURPLE);
        add(installButton);

        var installButtonText = new FlxText(installButton.x, installButton.y + 10, installButton.width, installText, 12);
        installButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        installButtonText.borderSize = 1;
        add(installButtonText);
        #end
    }

    function setupAnimations() {
        // Glow effect for title
        glowEffect = new FlxSprite(titleText.x - 10, titleText.y - 10);
        glowEffect.makeGraphic(Std.int(titleText.width + 20), Std.int(titleText.height + 20), FlxColor.CYAN);
        glowEffect.alpha = 0;
        insert(members.indexOf(titleText), glowEffect);

        FlxTween.tween(glowEffect, {alpha: 0.3}, 1.5, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });
    }

    function setupParticles() {
        particles = new FlxTypedGroup<FlxSprite>();
        add(particles);

        // Create floating particles
        for (i in 0...20) {
            var particle = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
            particle.makeGraphic(3, 3, FlxColor.WHITE);
            particle.alpha = FlxG.random.float(0.1, 0.5);
            particles.add(particle);

            // Animate particles
            FlxTween.tween(particle, {y: particle.y - FlxG.random.float(100, 300)}, FlxG.random.float(5, 10), {
                type: LOOPING,
                ease: FlxEase.sineInOut,
                onComplete: function(_) {
                    particle.y = FlxG.height + 10;
                    particle.x = FlxG.random.float(0, FlxG.width);
                }
            });
        }
    }

    function loadPage() {
        currentPage = 0; // Always 0 since we only have one page
        var page = pages[0];

        // Update page info
        descriptionText.text = page.description;
        pageIndicator.text = 'CONNECTION';

        // Set title color
        titleText.color = page.color;
        if (glowEffect != null) {
            glowEffect.color = page.color;
        }

        updatePageContent();

        // Animate page transition
        animatePageTransition();
    }

    function updateInfoPanel() {
        // This function now just prepares the info content
        // The actual display will be handled by the InfoPanelSubstate
    }

    function showInfoPanel() {
        var infoTitle = "CONNECTION INFO";
        var infoContent = "";

        infoContent = "Enter your Archipelago server connection details:\n\n";
        infoContent += "• Host: Server address (e.g., archipelago.gg)\n";
        infoContent += "• Port: Usually 38281\n";
        infoContent += "• Slot: Your player name from YAML\n";
        infoContent += "• Password: If server requires one\n\n";
        infoContent += "Last Connection:\n";
        var FNF = new FlxSave();
        FNF.bind("FNF");
        var lastGame:Dynamic = FNF.data.lastGame;
        if (lastGame != null) {
            infoContent += '• ${lastGame.server}:${lastGame.port}\n';
            infoContent += '• Slot: ${lastGame.slot}';
        } else {
            infoContent += "• None";
        }
        FNF.destroy();

        openSubState(new InfoPanelSubstate(infoTitle, infoContent, FlxColor.CYAN));
    }

    function updatePageContent() {
        // Always show connection elements since we only have one page
        connectionPanel.visible = true;

        // Show connection fields
        for (field in connectionFields) {
            field.visible = true;
        }

        if (hostText != null) hostText.visible = true;
        if (portText != null) portText.visible = true;
        if (slotText != null) slotText.visible = true;
        if (passwordText != null) passwordText.visible = true;

        connectButton.visible = true;

        // Update button color
        connectButton.color = pages[0].color;
    }

    function animatePageTransition() {
        if (isAnimating) return;
        isAnimating = true;

        // Animate connection panel
        if (connectionPanel.visible) {
            connectionPanel.x = FlxG.width;
            FlxTween.tween(connectionPanel, {x: 100}, transitionTime, {
                ease: FlxEase.backOut,
                onComplete: function(_) {
                    isAnimating = false;
                }
            });

            // Animate connection fields
            for (i in 0...connectionFields.length) {
                var field = connectionFields[i];
                field.x = FlxG.width + 120;
                FlxTween.tween(field, {x: connectionPanel.x + 120}, transitionTime + (i * 0.05), {
                    ease: FlxEase.backOut
                });
            }
        } else {
            isAnimating = false;
        }
    }

    function animateIn() {
        // Animate UI elements in
        titleText.y = -100;
        FlxTween.tween(titleText, {y: 30}, 0.8, {ease: FlxEase.backOut});

        descriptionText.alpha = 0;
        FlxTween.tween(descriptionText, {alpha: 1}, 1.2, {ease: FlxEase.sineOut});

        connectButton.y = FlxG.height + 50;
        backButton.y = FlxG.height + 50;
        FlxTween.tween(connectButton, {y: FlxG.height - 80}, 1.2, {ease: FlxEase.backOut});
        FlxTween.tween(backButton, {y: FlxG.height - 80}, 1.2, {ease: FlxEase.backOut});

        connectionPanel.alpha = 0;
        FlxTween.tween(connectionPanel, {alpha: 0.9}, 1, {ease: FlxEase.sineOut});
    }

    function loadLastGameSettings() {
        var FNF = new FlxSave();
        FNF.bind("FNF");
        var lastGame:Dynamic = FNF.data.lastGame;
        if (lastGame != null) {
            hostValue = lastGame.server != null ? lastGame.server : "archipelago.gg";
            portValue = lastGame.port != null ? lastGame.port : "38281";
            slotValue = lastGame.slot != null ? lastGame.slot : "Player";
        } else {
            hostValue = "archipelago.gg";
            portValue = "38281";
            slotValue = "Player";
        }

        // Update the text displays
        if (hostText != null) hostText.text = hostValue;
        if (portText != null) portText.text = portValue;
        if (slotText != null) slotText.text = slotValue;
        if (passwordText != null) passwordText.text = maskPassword(passwordValue);

        FNF.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Don't handle input during if a substate is open
        if (subState != null) return;

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            onBack();
        }

        // Handle mouse clicks
        handleMouseInput();

        // Update visual effects (similar to original APEntryState)
        var e = Std.int(elapsed * 60 * 2); // Convert to frame-based
        titleText.color = FlxColor.fromHSL(((e / 2) / 300 * 360) % 360, 1.0, 0.5*1.0);

        // Audio filter effect
        if(FlxG.sound.music != null && FlxG.sound.music.playing) {
            @:privateAccess {
                var af = lime.media.openal.AL.createFilter();
                lime.media.openal.AL.filteri(af, lime.media.openal.AL.FILTER_TYPE, lime.media.openal.AL.FILTER_LOWPASS);
                lime.media.openal.AL.filterf(af, lime.media.openal.AL.LOWPASS_GAIN, 1);
                lime.media.openal.AL.filterf(af, lime.media.openal.AL.LOWPASS_GAINHF, lowFilterAmount);
                lime.media.openal.AL.sourcei(FlxG.sound.music._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af);
            }
        }
    }

    function handleMouseInput() {
        if (subState != null) return;

        // Info button hover effect
        if (FlxG.mouse.overlaps(infoPanel)) {
            infoPanel.color = FlxColor.fromRGB(100, 100, 140);
            infoText.color = FlxColor.YELLOW;

            if (FlxG.mouse.justPressed) {
                FlxG.sound.play(Paths.sound('scrollMenu'));
                showInfoPanel();
                return;
            }
        } else {
            infoPanel.color = FlxColor.fromRGB(60, 60, 100);
            infoText.color = FlxColor.WHITE;
        }

        // Check connection field clicks - check both field and text overlaps
        if ((FlxG.mouse.overlaps(hostField) || FlxG.mouse.overlaps(hostText)) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            openHostInput();
            return;
        }

        if ((FlxG.mouse.overlaps(portField) || FlxG.mouse.overlaps(portText)) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            openPortInput();
            return;
        }

        if ((FlxG.mouse.overlaps(slotField) || FlxG.mouse.overlaps(slotText)) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            openSlotInput();
            return;
        }

        if ((FlxG.mouse.overlaps(passwordField) || FlxG.mouse.overlaps(passwordText)) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            openPasswordInput();
            return;
        }

        // Handle hover effects for connection fields
        if (FlxG.mouse.overlaps(hostField) || FlxG.mouse.overlaps(hostText)) {
            hostField.color = FlxColor.fromRGB(60, 60, 100);
        } else {
            hostField.color = FlxColor.fromRGB(40, 40, 70);
        }

        if (FlxG.mouse.overlaps(portField) || FlxG.mouse.overlaps(portText)) {
            portField.color = FlxColor.fromRGB(60, 60, 100);
        } else {
            portField.color = FlxColor.fromRGB(40, 40, 70);
        }

        if (FlxG.mouse.overlaps(slotField) || FlxG.mouse.overlaps(slotText)) {
            slotField.color = FlxColor.fromRGB(60, 60, 100);
        } else {
            slotField.color = FlxColor.fromRGB(40, 40, 70);
        }

        if (FlxG.mouse.overlaps(passwordField) || FlxG.mouse.overlaps(passwordText)) {
            passwordField.color = FlxColor.fromRGB(60, 60, 100);
        } else {
            passwordField.color = FlxColor.fromRGB(40, 40, 70);
        }

        // Check bottom buttons
        if (FlxG.mouse.overlaps(connectButton) && FlxG.mouse.justPressed) {
            onConnect();
        }

        if (FlxG.mouse.overlaps(backButton) && FlxG.mouse.justPressed) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            onBack();
        }

        // Check side buttons
        if (FlxG.mouse.overlaps(settingsButton) && FlxG.mouse.justPressed) {
            openSettings();
        }

        if (FlxG.mouse.overlaps(yamlButton) && FlxG.mouse.justPressed) {
            openYAMLOptions();
        }

        #if sys
        if (installButton != null && FlxG.mouse.overlaps(installButton) && FlxG.mouse.justPressed) {
            handleAPWorldInstall();
        }
        #end
    }

    function onConnect() {
        // Validation logic from original APEntryState
        var port = Std.parseInt(portValue);
        if (hostValue == "")
            postError('noHost');
        else if (portValue == "")
            postError('noPort');
        else if (!~/^\d+$/.match(portValue))
            postError('portNonNumeric');
        else if (port <= 0 || port > 65535)
            postError('portOutOfRange');
        else if (slotValue == "")
            postError('noSlot');
        else {
            startConnection();
        }
    }

    function startConnection() {
        FlxG.autoPause = false;

        openSubState(new ConnectionSubstate(
            hostValue,
            portValue,
            slotValue,
            passwordValue,
            onConnectionSuccess,
            onConnectionFailed
        ));
    }

    function onConnectionSuccess(client:Client, slotData:Dynamic) {
        // Connection successful, prepare for AP mode with special animation
        ap = client;
        gonnaRunSync = true;

        // Remove ap callbacks since APGameState will take over
        // Note: The connection-specific callbacks (onRoomInfo, onSlotRefused, etc.)
        // are already cleaned up by the ConnectionSubstate

        deathLink = slotData.deathlink == 0 ? false : true;
        victorySong = slotData.victoryLocation;
        fullSongCount = slotData.fullSongCount;
        APInfo.ticketWinCount = slotData.ticketWinCount;
        APInfo.ticketCount = 0;
        APInfo.grabLimits(slotData.gradeNeeded, slotData.accuracyNeeded);
        APInfo.unlockMethod = slotData.locationType;

        FlxG.save.flush();
        inArchipelagoMode = true;

        // Save last game settings
        var FNF = new FlxSave();
        FNF.bind("FNF");
        FNF.data.lastGame = {
            server: hostValue,
            port: portValue,
            slot: slotValue
        };
        FNF.data.gameSettings = APEntryState.gameSettings;
        FNF.close();

        APEntryState.ap = ap;



        // Special AP Mode entry animation
        startAPModeTransition(ap, slotData);
    }

    function onConnectionFailed(error:String) {
        FlxG.autoPause = ClientPrefs.data.autoPause;

        // Show error dialog
        var errorDesc = getErrorDescription(error);
        var errorPrompt = new InfoPanelSubstate("Connection Failed", error, FlxColor.RED);
        openSubState(errorPrompt);
    }

    function startAPModeTransition(ap, slotData) {
        // Create a special transition animation when entering AP Mode
        var transitionOverlay = new FlxSprite(0, 0);
        transitionOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        transitionOverlay.alpha = 0;
        add(transitionOverlay);

        var transitionText = new FlxText(0, 0, 0, "ENTERING ARCHIPELAGO MODE", 32);
        transitionText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        transitionText.borderSize = 3;
        transitionText.screenCenter();
        add(transitionText);

        // Animate the transition
        FlxTween.tween(transitionOverlay, {alpha: 1}, 0.8, {
            ease: FlxEase.sineIn,
            onComplete: function(_) {
                FlxFlicker.flicker(transitionText, 1, 0.1, false, false, function(_) {
                    runArch(slotData);
                });
            }
        });

        // Add some particle effects during transition
        for (i in 0...30) {
            var particle = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
            particle.makeGraphic(4, 4, FlxColor.CYAN);
            particle.alpha = 0;
            add(particle);

            FlxTween.tween(particle, {
                alpha: 1,
                y: particle.y - FlxG.random.float(100, 200)
            }, FlxG.random.float(0.5, 1.5), {
                ease: FlxEase.sineOut,
                startDelay: FlxG.random.float(0, 0.8)
            });
        }
    }

    function runArch(slotData):Void {
        inArchipelagoMode = true;
        APEntryState.inArchipelagoMode = true; // Global flag
        backend.WeekData.reloadWeekFiles(false);
        FlxG.save.data.closeDuringOverRide = false;
        FlxG.save.data.manualOverride = false;
        FlxG.save.data.storyWeek = null;
        FlxG.save.data.currentModDirectory = null;
        FlxG.save.data.difficulties = null;
        FlxG.save.data.SONG = null;
        FlxG.save.data.storyDifficulty = null;
        FlxG.save.data.songPos = null;
        FlxG.save.flush();

        // Create AP game state
        apGame = new APGameState(ap, slotData);
        if (deathLink)
            apGame.info().add_tag("DeathLink");
        apGame.info().toggleDeathLink(deathLink);

        APGameState.isSync = true;

        APEntryState.apGame = apGame;

        FlxG.switchState(new archipelago.APCategoryState(apGame, ap));
        backend.ClientPrefs.data.gameplaySettings.set("chartModifier", "Normal");
        backend.ClientPrefs.data.gameplaySettings.set("convertMania", 3);
    }

    function openSettings() {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        // Show settings choice dialog
        var settingsPrompt = new Prompt("Choose Settings Interface\n\nWhich settings interface would you like to use?", 0, function() {
            // Basic settings
            openSubState(new APSettingsSubState());
        }, function() {
            // Advanced settings
            MusicBeatState.switchState(new APAdvancedSettingsState());
        }, 'Basic', 'Advanced');

        openSubState(settingsPrompt);
    }

    function openYAMLOptions() {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        var yamlPrompt = new Prompt("YAML Options\n\nWhat would you like to do?", 0, function() {
            // Generate YAML
            openSettings(); // This will lead to YAML generation
        }, function() {
            // Import YAML
            importYAML();
        }, 'Generate', 'Import');

        openSubState(yamlPrompt);
    }

    function importYAML() {
        var yamlContent = yutautil.ImprovedFileHandling.loadFile("Import YAML", [{ext: "yaml", desc: "FNF AP YAML File"}], Text);
        if (yamlContent != null) {
            try {
                var yaml = new archipelago.APYaml(yamlContent);
                APEntryState.gameSettings.name = yaml.name;
                slotValue = yaml.name;
                if (slotText != null) slotText.text = slotValue;
                for (field in Reflect.fields(yaml.settings)) {
                    if (Reflect.hasField(APEntryState.gameSettings.FNF, field)) {
                        Reflect.setField(APEntryState.gameSettings.FNF, field, Reflect.field(yaml.settings, field));
                    }
                }
                FlxG.sound.play(Paths.sound('confirmMenu'));
            } catch(e) {
                trace('YAML import error: $e');
                postError('default', ["error" => "Failed to import YAML file"]);
            }
        }
    }

    #if sys
    function handleAPWorldInstall() {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        if (!FileSystem.exists(currentAPLocation)) {
            var locationPrompt = new Prompt("Archipelago not found.\n\nWould you like to change the AP location?", 0, function() {
                changeAPLocation();
            }, null, false, 'Change Location', 'Cancel');
            openSubState(locationPrompt);
        } else {
            APEntryState.installAPWorld();
            // Info panel content will be updated when next accessed
        }
    }

    function changeAPLocation() {
        var before = currentAPLocation;
        currentAPLocation = yutautil.ImprovedFileHandling.selectFolder("Select Archipelago Folder", true);
        if (currentAPLocation != null && currentAPLocation.trim() != "") {
            var save = new yutautil.save.MixSaveWrapper(null, "save/apLocation.json", true);
            save.addItem("apLocation", currentAPLocation);
            lime.app.Application.current.window.alert("Archipelago location changed to: " + currentAPLocation, "Archipelago Location Changed");
            save.save();
            // Info panel content will be updated when next accessed
        } else {
            lime.app.Application.current.window.alert("Archipelago location not changed.", "Archipelago Location Not Changed");
            currentAPLocation = before;
        }
    }
    #end

    // Error handling (from original APEntryState)
    var daReason:String = "man idk";
    function errDesc(a:String) {
        switch (a) {
            case 'noHost':
                daReason = "Host name cannot be empty. (That's the address of the server you're connecting to.)";
            case 'noPort':
                daReason = "Port number cannot be empty. (That's the 4-5 digits at the end of the server address, often 38281.)";
            case 'portNonNumeric':
                daReason = "Port must be numeric.";
            case 'portOutOfRange':
                daReason = "Port should be a number from 1 to 65535 (most likely 38281).";
            case 'noSlot':
                daReason = "Slot name cannot be empty. (That's your name on your YAML configuration file.)";
            case 'InvalidSlot':
                daReason = "That player isn't listed for this server instance.";
            case 'InvalidGame':
                daReason = "That Player isn't listed as a Friday Night Funkin slot.";
            case 'IncompatibleVersion':
                daReason = "The server is expecting a newer version of the game. Please ensure you're running the latest version.";
            case 'InvalidPassword':
                daReason = "The password supplied is incorrect.";
            case 'InvalidItemsHandling':
                daReason = "Please report a bug stating that an \"InvalidItemsHandling\" error was received.";
            case 'connectionReset':
                daReason = "The server closed the connection.";
            case 'badHostFormat':
                daReason = "Please check the value entered as Host. The format is invalid.";
            case 'unknownHost':
                daReason = "No server was found at \""+hostValue+"\".";
            case 'default':
                daReason = "Unknown connection error occurred.";
        }
        return daReason;
    }

    function getErrorDescription(error:String):String {
        return errDesc(error);
    }

    inline function postError(str:String, ?vars:Map<String, Dynamic>)
        openSubState(new Prompt("Error: " + errDesc(str), 0, null, null, false));

    function onBack() {
        MusicBeatState.switchState(new states.MainMenuState());
    }
}
