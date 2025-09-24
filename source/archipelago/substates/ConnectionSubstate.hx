package archipelago.substates;

import archipelago.APStyledEntryState;
import archipelago.Client;
import backend.MusicBeatSubstate;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import haxe.Timer;

/**
 * Connection dialog substate with proper animations
 */
class ConnectionSubstate extends MusicBeatSubstate {
    var background:FlxSprite;
    var panel:FlxSprite;
    var connectingText:FlxText;
    var statusText:FlxText;
    var progressBar:FlxSprite;
    var progressFill:FlxSprite;
    var cancelButton:FlxSprite;
    var cancelButtonText:FlxText;
    var particles:FlxTypedGroup<FlxSprite>;

    var isAnimating:Bool = false;
    var connectionProgress:Float = 0;
    var maxProgress:Float = 100;
    var progressSpeed:Float = 15; // Progress per second

    var ap:Client;
    var host:String;
    var port:String;
    var slot:String;
    var password:String;

    var polltimer:Timer;
    var onConnectionSuccess:Client->Dynamic->Void;
    var onConnectionFailed:String->Void;

    public function new(host:String, port:String, slot:String, password:String,
                       onSuccess:Client->Dynamic->Void, onFailed:String->Void) {
        super();

        this.host = host;
        this.port = port;
        this.slot = slot;
        this.password = password;
        this.onConnectionSuccess = onSuccess;
        this.onConnectionFailed = onFailed;

        setupBackground();
        setupPanel();
        setupParticles();
        animateIn();
        startConnection();
    }

    function setupBackground() {
        // Semi-transparent background
        background = new FlxSprite(0, 0);
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 180));
        add(background);
    }

    function setupPanel() {
        // Main connection panel
        var panelWidth = 500;
        var panelHeight = 250;

        panel = FlxGradient.createGradientFlxSprite(panelWidth, panelHeight,
            [FlxColor.fromRGB(20, 30, 50), FlxColor.fromRGB(30, 40, 60)], 1, 90);
        panel.x = (FlxG.width - panelWidth) / 2;
        panel.y = (FlxG.height - panelHeight) / 2;
        add(panel);

        // Connecting text
        connectingText = new FlxText(panel.x + 20, panel.y + 30, panelWidth - 40, "CONNECTING TO ARCHIPELAGO", 24);
        connectingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        connectingText.borderSize = 2;
        add(connectingText);

        // Status text
        statusText = new FlxText(panel.x + 20, panel.y + 70, panelWidth - 40, "Establishing connection...", 16);
        statusText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        statusText.borderSize = 1;
        add(statusText);

        // Progress bar
        progressBar = new FlxSprite(panel.x + 50, panel.y + 110);
        progressBar.makeGraphic(panelWidth - 100, 20, FlxColor.fromRGB(40, 40, 60));
        add(progressBar);

        progressFill = new FlxSprite(progressBar.x + 2, progressBar.y + 2);
        progressFill.makeGraphic(1, 16, FlxColor.CYAN);
        add(progressFill);

        // Cancel button
        cancelButton = new FlxSprite(panel.x + panelWidth - 120, panel.y + panelHeight - 50);
        cancelButton.makeGraphic(100, 30, FlxColor.RED);
        add(cancelButton);

        cancelButtonText = new FlxText(cancelButton.x, cancelButton.y + 5, cancelButton.width, "CANCEL", 14);
        cancelButtonText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        cancelButtonText.borderSize = 1;
        add(cancelButtonText);
    }

    function setupParticles() {
        particles = new FlxTypedGroup<FlxSprite>();
        add(particles);

        // Create connection particles
        for (i in 0...15) {
            var particle = new FlxSprite(
                panel.x + FlxG.random.float(0, panel.width),
                panel.y + FlxG.random.float(0, panel.height)
            );
            particle.makeGraphic(2, 2, FlxColor.CYAN);
            particle.alpha = FlxG.random.float(0.3, 0.8);
            particles.add(particle);

            // Animate particles
            FlxTween.tween(particle, {
                y: particle.y - FlxG.random.float(30, 60),
                alpha: 0
            }, FlxG.random.float(1, 3), {
                type: LOOPING,
                ease: FlxEase.sineOut,
                onComplete: function(_) {
                    particle.y = panel.y + panel.height;
                    particle.x = panel.x + FlxG.random.float(0, panel.width);
                    particle.alpha = FlxG.random.float(0.3, 0.8);
                }
            });
        }
    }

    function animateIn() {
        isAnimating = true;

        // Scale in animation
        panel.scale.set(0.7, 0.7);
        panel.alpha = 0;

        FlxTween.tween(panel, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.5, {
            ease: FlxEase.backOut,
            onComplete: function(_) {
                isAnimating = false;
                // Start flickering the connecting text
                FlxFlicker.flicker(connectingText, 0, 0.5);
            }
        });

        // Fade in other elements
        for (member in members) {
            if (member != background && member != panel && member != particles) {
                if (Std.isOfType(member, FlxSprite)) {
                    var sprite:FlxSprite = cast(member, FlxSprite);
                    sprite.alpha = 0;
                    FlxTween.tween(sprite, {alpha: 1}, 0.4, {
                        ease: FlxEase.sineOut,
                        startDelay: 0.2
                    });
                }
            }
        }
    }

    function startConnection() {
        try {
            // Set up connection similar to APStyledEntryState
            var uri = '${#if sys (host == "localhost" || host == "127.0.0.1") ? sys.net.Host.localhost() : host #else host #end}:$port';
            var wsCheck = ~/^wss?:\/\//;
            if (!wsCheck.match(uri))
                uri = 'ws://$uri';

            ap = new Client('FNF-$slot', "Friday Night Funkin", uri);

            ap.onRoomInfo.add(onRoomInfo);
            ap.onSlotRefused.add(onSlotRefused);
            ap.onSocketDisconnected.add(onSocketDisconnected);
            ap.onSlotConnected.add(onSlotConnected);
            ap.onThrow.add(onThrow);

            polltimer = new Timer(50);
            polltimer.run = function() {
                try {
                    ap.poll();
                } catch (e:Dynamic) {
                    updateStatus("Connection error during polling: " + Std.string(e));
                    updateProgress(0);

                    if (polltimer != null) {
                        polltimer.stop();
                        polltimer = null;
                    }

                    cleanupCallbacks();

                    new FlxTimer().start(2, function(_) {
                        onConnectionFailed("Polling error: " + Std.string(e));
                        animateOut();
                    });
                }
            };

            updateStatus("Connecting to server...");
        } catch (e:Dynamic) {
            updateStatus("Connection failed: " + Std.string(e));
            updateProgress(0);

            // Clean up on exception
            if (polltimer != null) {
                polltimer.stop();
                polltimer = null;
            }

            new FlxTimer().start(2, function(_) {
                onConnectionFailed("Connection error: " + Std.string(e));
                animateOut();
            });
        }
    }

    function updateStatus(status:String) {
        statusText.text = status;
    }

    function updateProgress(progress:Float) {
        connectionProgress = Math.min(progress, maxProgress);
        var fillWidth = Std.int((progressBar.width - 4) * (connectionProgress / maxProgress));
        progressFill.makeGraphic(Std.int(Math.max(1, fillWidth)), 16, FlxColor.CYAN);
    }

    // Connection callback functions
    function onRoomInfo():Void {
        updateStatus("Room info received, authenticating...");
        updateProgress(33);

        #if debug
        var tags = ["AP", "Testing"];
        #else
        var tags = ["AP", "Testing"];
        #end
        ap.ConnectSlot(slot, password.length > 0 ? password : null, 0x7, tags, {major: 0, minor: 5, build: 0});
    }

    function onSlotRefused(errors:Array<String>):Void {
        updateStatus("Connection refused: " + errors[0]);
        updateProgress(0);

        if (polltimer != null) {
            polltimer.stop();
            polltimer = null;
        }

        // Clean up callbacks on failure
        cleanupCallbacks();

        new FlxTimer().start(2, function(_) {
            onConnectionFailed(errors[0]);
            animateOut();
        });
    }

    function onSocketDisconnected():Void {
        updateStatus("Connection lost");
        updateProgress(0);

        if (polltimer != null) {
            polltimer.stop();
            polltimer = null;
        }

        // Clean up callbacks on failure
        cleanupCallbacks();

        new FlxTimer().start(1.5, function(_) {
            onConnectionFailed("connectionReset");
            animateOut();
        });
    }

    function onSlotConnected(slotData:Dynamic):Void {
        updateStatus("Connected successfully!");
        updateProgress(100);

        // Stop the timer
        if (polltimer != null) {
            polltimer.stop();
            polltimer = null;
        }

        // Clean up callbacks
        cleanupCallbacks();

        // Success animation
        connectingText.text = "CONNECTION SUCCESSFUL!";
        connectingText.color = FlxColor.LIME;
        FlxFlicker.stopFlickering(connectingText);

        new FlxTimer().start(1, function(_) {
            onConnectionSuccess(ap, slotData);
            animateOut();
        });
    }

    function onThrow(message:String, error:Dynamic):Void {
        updateStatus("Client error: " + message);
        updateProgress(0);

        if (polltimer != null) {
            polltimer.stop();
            polltimer = null;
        }

        // Clean up callbacks on error
        cleanupCallbacks();

        new FlxTimer().start(2, function(_) {
            onConnectionFailed("Client threw error: " + message + " - " + Std.string(error));
            animateOut();
        });
    }

    function animateOut() {
        if (isAnimating) return;
        isAnimating = true;

        FlxTween.tween(panel, {"scale.x": 0.5, "scale.y": 0.5, alpha: 0}, 0.4, {
            ease: FlxEase.backIn,
            onComplete: function(_) {
                close();
            }
        });

        FlxTween.tween(background, {alpha: 0}, 0.4, {ease: FlxEase.sineIn});
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (isAnimating) return;

        // Update fake progress for visual feedback
        if (connectionProgress < 25) {
            updateProgress(connectionProgress + progressSpeed * elapsed);
        }

        // Cancel button functionality
        if (FlxG.mouse.overlaps(cancelButton)) {
            cancelButton.color = FlxColor.fromRGB(200, 100, 100);

            if (FlxG.mouse.justPressed) {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                cancelConnection();
            }
        } else {
            cancelButton.color = FlxColor.RED;
        }

        // Cancel on back/escape
        if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            cancelConnection();
        }
    }

    function cleanupCallbacks() {
        if (ap != null) {
            // Properly remove callback functions from event listeners
            if (ap.onRoomInfo != null) ap.onRoomInfo.remove(onRoomInfo);
            if (ap.onSlotRefused != null) ap.onSlotRefused.remove(onSlotRefused);
            if (ap.onSlotConnected != null) ap.onSlotConnected.remove(onSlotConnected);
            if (ap.onSocketDisconnected != null) ap.onSocketDisconnected.remove(onSocketDisconnected);
            if (ap.onThrow != null) ap.onThrow.remove(onThrow);
        }
    }

    function cancelConnection() {
        if (polltimer != null) {
            polltimer.stop();
            polltimer = null;
        }

        // Clean up callbacks on cancellation
        cleanupCallbacks();

        if (ap != null) {
            ap.disconnect_socket();
        }

        updateStatus("Connection cancelled");
        animateOut();
    }

    override function destroy() {
        if (polltimer != null) {
            polltimer.stop();
            polltimer = null;
        }
        super.destroy();
    }
}
