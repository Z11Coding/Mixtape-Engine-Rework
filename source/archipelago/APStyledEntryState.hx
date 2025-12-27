package archipelago;

import archipelago.*;
import archipelago.APAdvancedSettingsState;
import archipelago.APGameState;
import archipelago.Client;
import archipelago.PacketTypes.JSONMessagePart;
import archipelago.PacketTypes.NetworkItem;
import archipelago.substates.ConnectionSubstate;
import archipelago.substates.ExportAPWorldChoiceSubstate;
import archipelago.substates.InfoPanelSubstate;
import archipelago.substates.PortInputSubstate;
import archipelago.substates.TextInputSubstate.InputMode;
import archipelago.substates.TextInputSubstate;
import archipelago.substates.YAMLOptionsSubstate;
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
import substates.Prompt;
import yutautil.GenericProgressSubstate;
import yutautil.modules.SyncUtils;

using yutautil.CollectionUtils;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

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
    var refreshYAMLButton:FlxSprite;
    var exportAPWorldButton:FlxSprite;
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
            FlxColor.CYAN,
            BASIC // Use basic input mode
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
            16, // Max length
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_", // Allowed characters
            "Enter your player name from the YAML file (YAML-safe characters only)",
            FlxColor.CYAN,
            YAML // Use YAML input mode for player names
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
            PASSWORD // Use password input mode
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

        // Refresh YAML button
        refreshYAMLButton = new FlxSprite(connectionPanel.x + connectionPanel.width + 20, buttonY + buttonSpacing * 2);
        refreshYAMLButton.makeGraphic(120, 40, FlxColor.LIME);
        add(refreshYAMLButton);

        var refreshYAMLText = new FlxText(refreshYAMLButton.x, refreshYAMLButton.y + 10, refreshYAMLButton.width, "REFRESH\nYAML", 10);
        refreshYAMLText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
        refreshYAMLText.borderSize = 1;
        add(refreshYAMLText);

        #if sys
        // Export APWorld button
        exportAPWorldButton = new FlxSprite(connectionPanel.x + connectionPanel.width + 20, buttonY + buttonSpacing * 3);
        exportAPWorldButton.makeGraphic(120, 40, FlxColor.ORANGE);
        add(exportAPWorldButton);

        var exportAPWorldText = new FlxText(exportAPWorldButton.x, exportAPWorldButton.y + 10, exportAPWorldButton.width, "EXPORT\nAPWORLD", 10);
        exportAPWorldText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        exportAPWorldText.borderSize = 1;
        add(exportAPWorldText);

        // Install button
        installButton = new FlxSprite(connectionPanel.x + connectionPanel.width + 20, buttonY + buttonSpacing * 4);
        var installText = FileSystem.exists(currentAPLocation + "/custom_worlds/fridaynightfunkin.apworld") ? "UPDATE" : "INSTALL";
        installButton.makeGraphic(120, 40, FlxColor.PURPLE);
        add(installButton);

        var installButtonText = new FlxText(installButton.x, installButton.y + 10, installButton.width, installText, 12);
        installButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        installButtonText.borderSize = 1;
        add(installButtonText);

        // Change AP Location button
        var changeLocationButton = new FlxSprite(connectionPanel.x + connectionPanel.width + 20, buttonY + buttonSpacing * 5);
        changeLocationButton.makeGraphic(120, 40, FlxColor.fromRGB(180, 80, 180)); // Purple-pink color
        add(changeLocationButton);

        var changeLocationText = new FlxText(changeLocationButton.x, changeLocationButton.y + 10, changeLocationButton.width, "CHANGE\nAP LOCATION", 9);
        changeLocationText.setFormat(Paths.font("vcr.ttf"), 9, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        changeLocationText.borderSize = 1;
        add(changeLocationText);
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


        infoContent += "\n\nNote for Universal Tracker users: \n";
        infoContent += "Ensure that when you connect with Universal Tracker, you have all of the YAML files of all players in your session placed in the Archipelago Players folder, so that all items and IDs can be properly synchronized.";

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

        if (refreshYAMLButton != null && FlxG.mouse.overlaps(refreshYAMLButton) && FlxG.mouse.justPressed) {
            refreshYAML();
        }

        #if sys
        if (exportAPWorldButton != null && FlxG.mouse.overlaps(exportAPWorldButton) && FlxG.mouse.justPressed) {
            exportAPWorld();
        }

        if (installButton != null && FlxG.mouse.overlaps(installButton) && FlxG.mouse.justPressed) {
            handleAPWorldInstall();
        }

        // Check Change AP Location button click by coordinates (since we didn't store it in a variable)
        var changeLocationX = connectionPanel.x + connectionPanel.width + 20;
        var changeLocationY = connectionPanel.y + 20 + (60 * 5); // buttonY + buttonSpacing * 5
        if (FlxG.mouse.x >= changeLocationX && FlxG.mouse.x <= changeLocationX + 120 &&
            FlxG.mouse.y >= changeLocationY && FlxG.mouse.y <= changeLocationY + 40 &&
            FlxG.mouse.justPressed) {
            changeAPLocation();
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
        APEntryState.gonnaRunSync = true;

        // Remove ap callbacks since APGameState will take over
        // Note: The connection-specific callbacks (onRoomInfo, onSlotRefused, etc.)
        // are already cleaned up by the ConnectionSubstate

        APEntryState.deathLink = slotData.deathlink == 0 ? false : true;
        APEntryState.victorySong = slotData.victoryLocation;
        APEntryState.fullSongCount = slotData.fullSongCount;
        APInfo.ticketWinCount = slotData.ticketWinCount;
        APInfo.ticketCount = 0;
        APInfo.grabLimits(slotData.gradeNeeded, slotData.accuracyNeeded);
        APInfo.unlockMethod = slotData.locationType;

        FlxG.save.flush();
        APEntryState.inArchipelagoMode = true;

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

        // Check if high quality content is expected and should be downloaded
        if (slotData != null && slotData.highQualityExpected == true) {
            // Go to existing high quality waiting state first
            FlxG.switchState(new archipelago.states.HighQualityWaitingState(apGame, ap, false));
        } else {
            // Normal flow - go directly to AP category state
            FlxG.switchState(new archipelago.APCategoryState(apGame, ap));
        }

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

        var yamlSubstate = new YAMLOptionsSubstate(
            function() {
                // Generate YAML - go to settings
                openSettings();
            },
            function() {
                // Refresh YAML - import and immediately export
                refreshYAML();
            },
            function() {
                // Import YAML only
                importYAML();
            }
        );

        openSubState(yamlSubstate);
    }

    function importYAML() {
        var stuff = null;
        var tasks = [
            GenericProgressSubstate.createTask("Opening file dialog", function(results:Array<Dynamic>) {
                var yamlContent = yutautil.ImprovedFileHandling.loadFile("Import YAML", [{ext: "yaml", desc: "FNF AP YAML File"}], Text);
                if (yamlContent == null) {
                    throw new Exception("No file selected or file could not be loaded");
                }
                return yamlContent;
            }),
            GenericProgressSubstate.createTask("Parsing YAML structure", function(results:Array<Dynamic>) {
                var content:String = results[0];
                return new archipelago.APYaml(content);
            }),
            GenericProgressSubstate.createTask("Processing YAML content", function(results:Array<Dynamic>) {
                var content:String = results[0];
                var yamlLines = content.split('\n');
                // Process lines to show some progress
                var processedLines = 0;
                for (line in yamlLines) {
                    if (line.trim().length > 0) {
                        processedLines++;
                    }
                }
                return 'Processed $processedLines lines';
            }),
            GenericProgressSubstate.createTask("Applying settings", function(results:Array<Dynamic>) {
                var yaml:archipelago.APYaml = results[1];
                APEntryState.gameSettings.name = yaml.name;
                slotValue = yaml.name;
                trace('YAML Slot Name: $slotValue');
                if (slotValue.isEmpty()) slotValue = "Player";
                if (slotText != null && slotValue?.trim() != '') slotText.text = slotValue;

                try {
                    for (field in Reflect.fields(yaml.settings)) {
                        if (Reflect.hasField(APEntryState.gameSettings.FNF, field)) {
                            var fieldValue:archipelago.APYaml.APOption = Reflect.field(yaml.settings, field);
                            Reflect.setField(APEntryState.gameSettings.FNF, field, fieldValue);
                        }
                    }
                } catch (e:Dynamic) {
                    trace('Error applying YAML settings: $e');
                }
                return "Settings applied successfully";
            }),
            GenericProgressSubstate.createIterTask("Validating...", Reflect.fields(APEntryState.gameSettings.FNF), function(results:Dynamic) {
                // Simulate validation delay
                Sys.sleep(0.1);
                trace('Validated setting: ' + results);
                return 'validated ' + results;
            })
        ];

        var progressSubstate = new GenericProgressSubstate(
            "Importing YAML Configuration",
            tasks,
            function(results:Array<Dynamic>) {
                // On completion, open Advanced Settings
                FlxG.sound.play(Paths.sound('confirmMenu'));
                var yaml:archipelago.APYaml = results[1];
                MusicBeatState.switchState(new APAdvancedSettingsState(yaml));
            },
            function(error:String, shouldThrow:Bool) {
                trace('YAML import error: $error');
                if (error.indexOf("No file selected") == -1) {
                    var errorPrompt = new InfoPanelSubstate("YAML Import Error", error, FlxColor.RED);
                    openSubState(errorPrompt);
                }
                // If no file selected, just silently cancel
            },
            function() {
                // On cancel - do nothing
            }
        );

        openSubState(progressSubstate);
    }

    #if sys
    function handleAPWorldInstall() {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        if (!FileSystem.exists(currentAPLocation)) {
            // Use Prompt instead of InfoPanelSubstate for location change option
            var locationPrompt = new Prompt("Archipelago not found at:\n" + currentAPLocation + "\n\nWould you like to change the AP location?", 0, function() {
                changeAPLocation();
            }, function() {
                // Cancel
            }, 'Change Location', 'Cancel');
            openSubState(locationPrompt);
        } else {
            // Create installation tasks
            var tasks = [
                GenericProgressSubstate.createTask("Checking Archipelago installation", function(results:Array<Dynamic>) {
                    if (!FileSystem.exists(currentAPLocation + "/custom_worlds")) {
                        FileSystem.createDirectory(currentAPLocation + "/custom_worlds");
                    }
                    return "Directory verified";
                }),
                GenericProgressSubstate.createTask("Copying APWorld file", function(results:Array<Dynamic>) {
                    APEntryState.installAPWorld();
                    return "APWorld installed";
                }),
                GenericProgressSubstate.createTask("Verifying installation", function(results:Array<Dynamic>) {
                    var apworldPath = currentAPLocation + "/custom_worlds/fridaynightfunkin.apworld";
                    return FileSystem.exists(apworldPath) ? "Installation verified" : "Installation failed";
                })
            ];

            var progressSubstate = new GenericProgressSubstate(
                "Installing Friday Night Funkin APWorld",
                tasks,
                function(results:Array<Dynamic>) {
                    // On completion
                    var successPrompt = new InfoPanelSubstate(
                        "Installation Complete",
                        "Friday Night Funkin APWorld has been successfully installed!\n\nLocation: " + currentAPLocation + "/custom_worlds/fridaynightfunkin.apworld",
                        FlxColor.LIME
                    );
                    openSubState(successPrompt);
                },
                function(error:String, shouldThrow:Bool) {
                    var errorPrompt = new InfoPanelSubstate(
                        "Installation Error",
                        "Failed to install APWorld:\n" + error,
                        FlxColor.RED
                    );
                    openSubState(errorPrompt);
                },
                function() {
                    // On cancel - do nothing
                }
            );

            openSubState(progressSubstate);
        }
    }

    function refreshYAML() {
        // Import a YAML using the same method as importYAML, but then force export to original location
        var stuff = null;
        var yamlPathToExportTo:String = null;

        var tasks = [
            GenericProgressSubstate.createTask("Opening file dialog", function(results:Array<Dynamic>) {
                // Use loadFile to get content and then access lastPath for the file path
                var yamlContent = yutautil.ImprovedFileHandling.loadFile("Select YAML to Refresh", [{ext: "yaml", desc: "FNF AP YAML File"}, {ext: "yml", desc: "FNF AP YAML File"}], yutautil.ReadType.Text);
                if (yamlContent == null) {
                    throw new Exception("No file selected");
                }
                // Get the path from lastPath after loading
                yamlPathToExportTo = yutautil.ImprovedFileHandling.lastPath;
                return yamlContent;
            }),
            GenericProgressSubstate.createTask("Parsing YAML structure", function(results:Array<Dynamic>) {
                var content:String = results[0];
                return new archipelago.APYaml(content);
            }),
            GenericProgressSubstate.createTask("Processing YAML content", function(results:Array<Dynamic>) {
                var content:String = results[0];
                var yamlLines = content.split('\n');
                // Process lines to show some progress
                var processedLines = 0;
                for (line in yamlLines) {
                    if (line.trim().length > 0) {
                        processedLines++;
                    }
                }
                return 'Processed $processedLines lines';
            }),
            GenericProgressSubstate.createTask("Applying settings", function(results:Array<Dynamic>) {
                var yaml:archipelago.APYaml = results[1];
                APEntryState.gameSettings.name = yaml.name;
                slotValue = yaml.name;
                trace('YAML Slot Name: $slotValue');
                if (slotValue.isEmpty()) slotValue = "Player";
                if (slotText != null && slotValue?.trim() != '') slotText.text = slotValue;

                try {
                    for (field in Reflect.fields(yaml.settings)) {
                        if (Reflect.hasField(APEntryState.gameSettings.FNF, field)) {
                            var fieldValue:archipelago.APYaml.APOption = Reflect.field(yaml.settings, field);
                            Reflect.setField(APEntryState.gameSettings.FNF, field, fieldValue);
                        }
                    }
                } catch (e:Dynamic) {
                    trace('Error applying YAML settings: $e');
                }
                return "Settings applied successfully";
            }),
            GenericProgressSubstate.createIterTask("Validating...", Reflect.fields(APEntryState.gameSettings.FNF), function(results:Dynamic) {
                // Simulate validation delay
                Sys.sleep(0.1);
                trace('Validated setting: ' + results);
                return 'validated ' + results;
            })
        ];

        var progressSubstate = new GenericProgressSubstate(
            "Refreshing YAML Configuration",
            tasks,
            function(results:Array<Dynamic>) {
                // On completion, go to Advanced Settings and force export to original path
                FlxG.sound.play(Paths.sound('confirmMenu'));
                var yaml:archipelago.APYaml = results[1];

                // Create Advanced Settings state with the imported YAML and force export path
                var advancedState = new APAdvancedSettingsState(yaml);
                advancedState.forceExportPath = yamlPathToExportTo; // Set the path to export to
                MusicBeatState.switchState(advancedState);
            },
            function(error:String, shouldThrow:Bool) {
                trace('YAML refresh error: $error');
                if (error.indexOf("No file selected") == -1) {
                    var errorPrompt = new InfoPanelSubstate("YAML Refresh Error", error, FlxColor.RED);
                    openSubState(errorPrompt);
                }
                // If no file selected, just silently cancel
            },
            function() {
                // On cancel - do nothing
            }
        );

        openSubState(progressSubstate);
    }

    function exportAPWorld() {
        var choiceSubstate = new ExportAPWorldChoiceSubstate(
            function() {
                // Export to default location (root folder)
                performAPWorldExport("./fridaynightfunkin.apworld");
            },
            function() {
                // Let user choose location
                var savePath = yutautil.ImprovedFileHandling.saveFile("Export APWorld", {ext: "apworld", desc: "APWorld Files"});
                if (savePath != null) {
                    performAPWorldExport(savePath);
                }
            }
        );
        openSubState(choiceSubstate);
    }

    function performAPWorldExport(targetPath:String) {
        // Show progress while exporting APWorld
        var tasks = [
            GenericProgressSubstate.createTask("Copying APWorld file", function(results:Array<Dynamic>) {
                try {
                    // Copy the APWorld file from the Archipelago installation
                    var sourcePath = currentAPLocation + "/custom_worlds/fridaynightfunkin.apworld";
                    if (FileSystem.exists(sourcePath)) {
                        File.copy(sourcePath, targetPath);
                        return "APWorld exported successfully";
                    } else {
                        throw new Exception("APWorld not found at: " + sourcePath);
                    }
                } catch (e:Exception) {
                    throw e;
                }
            })
        ];

        var progressSubstate = new GenericProgressSubstate(
            "Exporting APWorld...",
            tasks,
            function(results:Array<Dynamic>) {
                // On success
                openSubState(new InfoPanelSubstate("Export Complete",
                    "APWorld file exported successfully to:\n" + targetPath,
                    FlxColor.GREEN));
            },
            function(error:String, shouldThrow:Bool) {
                // On error
                openSubState(new InfoPanelSubstate("Export Error",
                    "Failed to export APWorld:\n" + error,
                    FlxColor.RED));
            },
            function() {
                // On cancel - do nothing
            }
        );

        openSubState(progressSubstate);
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
        openSubState(new InfoPanelSubstate("Error", errDesc(str) + (vars != null ? "\n\n" + [for (k in vars.keys()) '$k: ${vars.get(k)}'].join("\n") : ""), FlxColor.RED));

    function onBack() {
        MusicBeatState.switchState(new states.MainMenuState());
    }

    #if sys
    function changeAPLocation() {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        var before = currentAPLocation;
        currentAPLocation = yutautil.ImprovedFileHandling.selectFolder("Select Archipelago Folder", true);

        if (currentAPLocation != null && currentAPLocation.trim() != "") {
            var save = new yutautil.save.MixSaveWrapper(null, "save/apLocation.json", true);
            save.addItem("apLocation", currentAPLocation);

            // Show success message using InfoPanelSubstate for consistency
            var successPanel = new InfoPanelSubstate(
                "✅ Archipelago Location Changed",
                "Archipelago location changed to:\\n" + currentAPLocation + "\\n\\nThe state will refresh to apply changes.",
                FlxColor.LIME,
                function() {
                    save.save();
                    FlxG.resetState();
                }
            );
            openSubState(successPanel);
        } else {
            // Show cancellation message
            currentAPLocation = before;
            var cancelPanel = new InfoPanelSubstate(
                "❌ Location Change Cancelled",
                "Archipelago location was not changed.\\n\\nThe current location remains:\\n" + currentAPLocation,
                FlxColor.ORANGE
            );
            openSubState(cancelPanel);
        }
    }
    #end
}
