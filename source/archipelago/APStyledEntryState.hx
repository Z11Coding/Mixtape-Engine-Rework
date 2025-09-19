package archipelago;

import archipelago.*;
import archipelago.APAdvancedSettingsState;
import archipelago.APGameState;
import archipelago.Client;
import archipelago.PacketTypes.JSONMessagePart;
import archipelago.PacketTypes.NetworkItem;
import backend.MusicBeatState;
import backend.ui.*;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
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
    var leftArrow:FlxSprite;
    var rightArrow:FlxSprite;
    var backButton:FlxSprite;
    var connectButton:FlxSprite;

    // Animation elements
    var particles:FlxTypedGroup<FlxSprite>;
    var glowEffect:FlxSprite;

    // Connection form elements
    var connectionPanel:FlxSprite;
    var _hostInput:PsychUIInputText;
    var _portInput:PsychUIInputText;
    var _slotInput:PsychUIInputText;
    var _pwInput:PsychUIInputText;
    var _tabOrder:Array<PsychUIInputText> = [];

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
    var navigationCooldown:Float = 0;
    var navigationDelay:Float = 0.15;

    // Connection state
    var isConnecting:Bool = false;
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

    static final wsCheck = ~/^wss?:\/\//;
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
            },
            {
                name: "SETUP",
                description: "Install and configure Archipelago world",
                color: FlxColor.LIME
            },
            {
                name: "SETTINGS",
                description: "Configure your game settings",
                color: FlxColor.ORANGE
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

        // Page indicator
        pageIndicator = new FlxText(50, FlxG.height - 140, FlxG.width - 100, "", 16);
        pageIndicator.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        pageIndicator.borderSize = 1;
        add(pageIndicator);

        // Navigation arrows
        leftArrow = new FlxSprite(30, Std.int(FlxG.height / 2) - 25);
        leftArrow.makeGraphic(40, 30, FlxColor.WHITE);
        add(leftArrow);

        rightArrow = new FlxSprite(Std.int(FlxG.width - 80), Std.int(FlxG.height / 2) - 25);
        rightArrow.makeGraphic(40, 30, FlxColor.WHITE);
        add(rightArrow);

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
        loadPage(0);
    }

    function setupInfoPanel() {
        infoPanel = new FlxSprite(FlxG.width - 300, 120);
        infoPanel.makeGraphic(280, 200, FlxColor.BLACK);
        infoPanel.alpha = 0.7;
        add(infoPanel);

        infoText = new FlxText(infoPanel.x + 10, infoPanel.y + 10, 260, "", 12);
        infoText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        infoText.borderSize = 1;
        add(infoText);
    }

    function setupConnectionPanel() {
        connectionPanel = new FlxSprite(100, 140);
        connectionPanel.makeGraphic(FlxG.width - 350, 250, FlxColor.fromRGB(20, 20, 40));
        connectionPanel.alpha = 0.9;
        add(connectionPanel);

        // Connection form inputs
        var startY = connectionPanel.y + 30;
        var spacing = 50;

        var hostLabel = new FlxText(connectionPanel.x + 20, startY, 100, "Host:", 16);
        hostLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        hostLabel.borderSize = 1;
        add(hostLabel);

        _hostInput = new PsychUIInputText(connectionPanel.x + 120, startY - 5, 200, "", 16);
        add(_hostInput);

        var portLabel = new FlxText(connectionPanel.x + 20, startY + spacing, 100, "Port:", 16);
        portLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        portLabel.borderSize = 1;
        add(portLabel);

        _portInput = new PsychUIInputText(connectionPanel.x + 120, startY + spacing - 5, 200, "", 16);
        _portInput.filterMode = 2; // Numbers only
        _portInput.maxLength = 6;
        add(_portInput);

        var slotLabel = new FlxText(connectionPanel.x + 20, startY + spacing * 2, 100, "Slot Name:", 16);
        slotLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        slotLabel.borderSize = 1;
        add(slotLabel);

        _slotInput = new PsychUIInputText(connectionPanel.x + 120, startY + spacing * 2 - 5, 200, "", 16);
        add(_slotInput);

        var pwLabel = new FlxText(connectionPanel.x + 20, startY + spacing * 3, 100, "Password:", 16);
        pwLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        pwLabel.borderSize = 1;
        add(pwLabel);

        _pwInput = new PsychUIInputText(connectionPanel.x + 120, startY + spacing * 3 - 5, 200, "", 16);
        _pwInput.passwordMask = true;
        add(_pwInput);

        _tabOrder = [_hostInput, _portInput, _slotInput, _pwInput];

        // Side buttons for different pages
        setupSideButtons();
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

    function loadPage(pageIndex:Int) {
        if (pageIndex < 0 || pageIndex >= pages.length) return;

        currentPage = pageIndex;
        var page = pages[currentPage];

        // Update page info
        descriptionText.text = page.description;
        pageIndicator.text = '${currentPage + 1} / ${pages.length} - ${page.name}';

        // Change title color based on page
        titleText.color = page.color;
        if (glowEffect != null) {
            glowEffect.color = page.color;
        }

        updateInfoPanel();
        updatePageContent();

        // Animate page transition
        animatePageTransition();
    }

    function updateInfoPanel() {
        var infoString = "=== ${pages[currentPage].name} INFO ===\n\n";

        switch (currentPage) {
            case 0: // Connection
                infoString += "Enter your Archipelago server\nconnection details:\n\n";
                infoString += "• Host: Server address\n";
                infoString += "• Port: Usually 38281\n";
                infoString += "• Slot: Your player name\n";
                infoString += "• Password: If required\n\n";
                infoString += "Last Connection:\n";
                var FNF = new FlxSave();
                FNF.bind("FNF");
                var lastGame:Dynamic = FNF.data.lastGame;
                if (lastGame != null) {
                    infoString += "• ${lastGame.server}:${lastGame.port}\n";
                    infoString += "• Slot: ${lastGame.slot}";
                }
                FNF.destroy();

            case 1: // Setup
                infoString += "Archipelago World Setup:\n\n";
                var status = APEntryState.checkAPWorld();
                infoString += "Status: " + status.status.toUpperCase() + "\n\n";
                infoString += status.message + "\n\n";
                infoString += "AP Location:\n";
                infoString += currentAPLocation + "\n\n";
                infoString += "• Install/Update APWorld\n";
                infoString += "• Generate YAML files\n";
                infoString += "• Configure settings";

            case 2: // Settings
                infoString += "Game Configuration:\n\n";
                if (APEntryState.gameSettings != null) {
                    var settings = APEntryState.gameSettings.FNF;
                    infoString += "• Unlock: " + settings.unlock_type + "\n";
                    infoString += "• Method: " + settings.unlock_method + "\n";
                    infoString += "• DeathLink: " + (settings.deathlink ? "ON" : "OFF") + "\n";
                    infoString += "• Song Limit: " + settings.song_limit + "\n";
                    infoString += "• Traps: " + settings.trapAmount + "\n\n";
                }
                infoString += "Use Advanced Settings for\nfull configuration options.";
        }

        infoText.text = infoString;
    }

    function updatePageContent() {
        // Show/hide elements based on current page
        var showConnection = currentPage == 0;
        var showSetup = currentPage == 1;
        var showSettings = currentPage == 2;

        connectionPanel.visible = showConnection;
        _hostInput.visible = showConnection;
        _portInput.visible = showConnection;
        _slotInput.visible = showConnection;
        _pwInput.visible = showConnection;

        // Update button visibility and functionality
        connectButton.visible = showConnection;

        // Update button colors based on page
        connectButton.color = pages[currentPage].color;

        for (input in _tabOrder) {
            input.visible = showConnection;
        }
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

            // Animate inputs
            for (i in 0..._tabOrder.length) {
                var input = _tabOrder[i];
                input.x = FlxG.width + 120;
                FlxTween.tween(input, {x: connectionPanel.x + 120}, transitionTime + (i * 0.05), {
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

        leftArrow.x = -100;
        rightArrow.x = FlxG.width + 100;
        FlxTween.tween(leftArrow, {x: 30}, 1, {ease: FlxEase.backOut});
        FlxTween.tween(rightArrow, {x: FlxG.width - 80}, 1, {ease: FlxEase.backOut});

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
            _hostInput.text = lastGame.server != null ? lastGame.server : "archipelago.gg";
            _portInput.text = lastGame.port != null ? lastGame.port : "38281";
            _slotInput.text = lastGame.slot != null ? lastGame.slot : "Player";
        } else {
            _hostInput.text = "archipelago.gg";
            _portInput.text = "38281";
            _slotInput.text = "Player";
        }
        FNF.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Update navigation cooldown
        if (navigationCooldown > 0) {
            navigationCooldown -= elapsed;
        }

        // Don't handle input during connection or if a substate is open
        if (isConnecting || subState != null) return;

        // Handle page navigation
        if (navigationCooldown <= 0) {
            if (controls.UI_LEFT || FlxG.keys.justPressed.LEFT) {
                if (currentPage > 0) {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    loadPage(currentPage - 1);
                    navigationCooldown = navigationDelay;
                }
            }

            if (controls.UI_RIGHT || FlxG.keys.justPressed.RIGHT) {
                if (currentPage < pages.length - 1) {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    loadPage(currentPage + 1);
                    navigationCooldown = navigationDelay;
                }
            }
        }

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
        if (isConnecting || subState != null) return;

        // Check page navigation arrows
        if (FlxG.mouse.overlaps(leftArrow) && FlxG.mouse.justPressed && currentPage > 0 && navigationCooldown <= 0) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            loadPage(currentPage - 1);
            navigationCooldown = navigationDelay;
        }

        if (FlxG.mouse.overlaps(rightArrow) && FlxG.mouse.justPressed && currentPage < pages.length - 1 && navigationCooldown <= 0) {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            loadPage(currentPage + 1);
            navigationCooldown = navigationDelay;
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
        var port = Std.parseInt(_portInput.text);
        if (_hostInput.text == "")
            postError('noHost');
        else if (_portInput.text == "")
            postError('noPort');
        else if (!~/^\d+$/.match(_portInput.text))
            postError('portNonNumeric');
        else if (port <= 0 || port > 65535)
            postError('portOutOfRange');
        else if (_slotInput.text == "")
            postError('noSlot');
        else {
            startConnection();
        }
    }

    function startConnection() {
        isConnecting = true;
        FlxG.autoPause = false;

        // Create connection animation
        var connectingText = new FlxText(0, 0, 0, "CONNECTING...", 24);
        connectingText.setFormat(Paths.font("vcr.ttf"), 24, pages[currentPage].color, CENTER, OUTLINE, FlxColor.BLACK);
        connectingText.borderSize = 2;
        connectingText.screenCenter();
        add(connectingText);

        var cancelButton = new FlxSprite(0, connectingText.y + 60);
        cancelButton.makeGraphic(200, 40, FlxColor.RED);
        cancelButton.screenCenter(X);
        add(cancelButton);

        var cancelText = new FlxText(cancelButton.x, cancelButton.y + 10, cancelButton.width, "CANCEL", 16);
        cancelText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        cancelText.borderSize = 1;
        add(cancelText);

        connectionElements = [connectingText, cancelButton, cancelText];

        // Animate connection elements
        FlxFlicker.flicker(connectingText, 0, 0.5);

        // Set up connection (using original APEntryState logic)
        var uri = '${#if sys (_hostInput.text == "localhost" || _hostInput.text == "127.0.0.1") ? sys.net.Host.localhost() : _hostInput.text #else _hostInput.text #end}:${_portInput.text}';
        if (!wsCheck.match(uri))
            uri = 'ws://$uri';

        ap = new Client('FNF-${_slotInput.text}', "Friday Night Funkin", uri);

        ap.onRoomInfo.add(onRoomInfo);
        ap.onSlotRefused.add(onSlotRefused);
        ap.onSocketDisconnected.add(onSocketDisconnected);
        ap.onSlotConnected.add(onSlotConnected);

        var polltimer = new Timer(50);
        polltimer.run = ap.poll;

        // Cancel button functionality
        var checkCancel = function() {
            if (FlxG.mouse.overlaps(cancelButton) && FlxG.mouse.justPressed) {
                cancelConnection();
            }
        };

        new FlxTimer().start(0.01, function(timer) {
            if (isConnecting) {
                checkCancel();
                timer.reset();
            }
        }, 0);
    }

    function cancelConnection() {
        isConnecting = false;
        inArchipelagoMode = false;
        FlxG.autoPause = true;

        if (ap != null) {
            ap.disconnect_socket();
        }

        // Remove connection elements
        for (element in connectionElements) {
            remove(element);
        }
        connectionElements = [];

        FlxG.sound.play(Paths.sound('cancelMenu'));
    }

    // Connection callback functions (from original APEntryState)
    function onRoomInfo():Void {
        trace("Got room info - sending connect packet");
        #if debug
        var tags = ["AP", "Testing"];
        #else
        var tags = ["AP", "Testing"];
        #end
        ap.ConnectSlot(_slotInput.text, _pwInput.text.length > 0 ? _pwInput.text : null, 0x7, tags, {major: 0, minor: 5, build: 0});
    }

    function onSlotRefused(errors:Array<String>):Void {
        inArchipelagoMode = false;
        isConnecting = false;
        trace("Slot refused", errors);

        // Remove connection elements
        for (element in connectionElements) {
            remove(element);
        }
        connectionElements = [];

        switch (errors[0]) {
            case x = "InvalidSlot" | "InvalidGame": postError(x, ["name" => _slotInput.text]);
            case x = "IncompatibleVersion" | "InvalidPassword" | "InvalidItemsHandling": postError(x);
            case x: postError("default", ["error" => x]);
        }
    }

    function onSocketDisconnected():Void {
        inArchipelagoMode = false;
        isConnecting = false;
        trace("Disconnected");

        // Remove connection elements
        for (element in connectionElements) {
            remove(element);
        }
        connectionElements = [];

        postError("connectionReset");
    }

    function onSlotConnected(slotData:Dynamic):Void {
        trace("Connected - switching to game state");
        isConnecting = false;
        gonnaRunSync = true;

        ap.onRoomInfo.remove(onRoomInfo);
        ap.onSlotRefused.remove(onSlotRefused);
        ap.onSlotConnected.remove(onSlotConnected);

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
            server: _hostInput.text,
            port: _portInput.text,
            slot: _slotInput.text
        };
        FNF.data.gameSettings = APEntryState.gameSettings;
        FNF.close();

        // Create AP game state
        apGame = new APGameState(ap, slotData);
        if (deathLink)
            apGame.info().add_tag("DeathLink");
        apGame.info().toggleDeathLink(deathLink);

        APGameState.isSync = true;
        runArch();
    }

    function runArch():Void {
        inArchipelagoMode = true;
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
                _slotInput.text = yaml.name;
                for (field in Reflect.fields(yaml.settings)) {
                    if (Reflect.hasField(APEntryState.gameSettings.FNF, field)) {
                        Reflect.setField(APEntryState.gameSettings.FNF, field, Reflect.field(yaml.settings, field));
                    }
                }
                updateInfoPanel(); // Refresh info display
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
            // Refresh the info panel after installation
            new FlxTimer().start(1, function(_) {
                updateInfoPanel();
            });
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
            updateInfoPanel();
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
                daReason = "No server was found at \""+_hostInput.text+"\".";
            case 'default':
                daReason = "Slot name cannot be empty. (That's your name on your YAML configuration file.)";
        }
        return daReason;
    }

    inline function postError(str:String, ?vars:Map<String, Dynamic>)
        openSubState(new Prompt("Error: " + errDesc(str), 0, null, null, false));

    function onBack() {
        MusicBeatState.switchState(new states.MainMenuState());
    }
}
