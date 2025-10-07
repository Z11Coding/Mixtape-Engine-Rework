package games.uno;

import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import games.uno.backend.UnoCPU;
import games.uno.backend.UnoPlayer;

/**
 * Stylish hand swap selection substate for the 7 rule
 */
class HandSwapSubstate extends MusicBeatSubstate {
    private var availablePlayers:Array<UnoPlayer>;
    private var currentPlayer:UnoPlayer;
    private var onPlayerSelected:UnoPlayer->Void;
    private var onPlayerCancel:UnoPlayer->Void;

    // UI Elements
    private var bgOverlay:FlxSprite;
    private var titleText:FlxText;
    private var instructionText:FlxText;
    private var playerButtons:FlxTypedGroup<FlxSprite>;
    private var playerTexts:FlxTypedGroup<FlxText>;
    private var playerCards:FlxTypedGroup<FlxSprite>;
    private var selectedIndex:Int = -1;
    private var glowEffect:FlxSprite;

    // Animation variables
    private var animationComplete:Bool = false;
    private var particles:FlxTypedGroup<FlxSprite>;
    private var cpuThinkingTimer:FlxTimer;
    private var shouldBeClosed:Bool = false;


    public function new(currentPlayer:UnoPlayer, availablePlayers:Array<UnoPlayer>, onPlayerSelected:UnoPlayer->Void, onPlayerCancel:UnoPlayer->Void) {
        super();
        this.currentPlayer = currentPlayer;
        this.availablePlayers = availablePlayers.copy();
        this.onPlayerSelected = onPlayerSelected;
        this.onPlayerCancel = onPlayerCancel;

        // Remove current player from available choices
        this.availablePlayers.remove(currentPlayer);
    }

    override function create() {
        try {
            super.create();
        } catch(e:Dynamic) {
            trace("Error in super.create: " + e);
        }

        try {
            setupBackground();
        } catch(e:Dynamic) {
            trace("Error in setupBackground: " + e);
        }

        try {
            setupUI();
        } catch(e:Dynamic) {
            trace("Error in setupUI: " + e);
        }

        try {
            setupPlayerOptions();
        } catch(e:Dynamic) {
            trace("Error in setupPlayerOptions: " + e);
        }

        try {
            setupParticles();
        } catch(e:Dynamic) {
            trace("Error in setupParticles: " + e);
        }

        try {
            animateIn();
        } catch(e:Dynamic) {
            trace("Error in animateIn: " + e);
            // Fallback: mark animation as complete
            animationComplete = true;
        }

        // Handle CPU players automatically
        try {
            if (currentPlayer != null && !currentPlayer.isHuman) {
                // Wait for animation to complete, then start CPU thinking
                try {
                    new FlxTimer().start(1.5, function(_) {
                        try {
                            if (animationComplete) {
                                startCPUSelection();
                            } else {
                                // If animation isn't complete yet, wait a bit more
                                try {
                                    new FlxTimer().start(0.2, function(_) {
                                        startCPUSelection();
                                    });
                                } catch(e:Dynamic) {
                                    trace("Error in CPU backup timer: " + e);
                                    startCPUSelection();
                                }
                            }
                        } catch(e:Dynamic) {
                            trace("Error in CPU timer callback: " + e);
                            try {
                                startCPUSelection();
                            } catch(e2:Dynamic) {
                                trace("Error in CPU fallback: " + e2);
                            }
                        }
                    });
                } catch(e:Dynamic) {
                    trace("Error starting CPU timer: " + e);
                    // Immediate fallback
                    try {
                        startCPUSelection();
                    } catch(e2:Dynamic) {
                        trace("Error in immediate CPU fallback: " + e2);
                    }
                }

                try {
                    Cursor.hide();
                } catch(e:Dynamic) {
                    trace("Error hiding cursor: " + e);
                }
            } else {
                try {
                    Cursor.show();
                    Cursor.cursorMode = Default;
                } catch(e:Dynamic) {
                    trace("Error showing cursor: " + e);
                }
            }
        } catch(e:Dynamic) {
            trace("Error in CPU/cursor setup: " + e);
        }
    }

    private function setupBackground():Void {
        // Semi-transparent dark overlay
        bgOverlay = new FlxSprite();
        bgOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.8));
        bgOverlay.alpha = 0;
        add(bgOverlay);

        // Glow effect behind selected option
        glowEffect = new FlxSprite();
        glowEffect.makeGraphic(320, 120, FlxColor.fromRGBFloat(1, 1, 0.2, 0.3));
        glowEffect.visible = false;
        add(glowEffect);
    }

    private function setupUI():Void {
        // Title
        titleText = new FlxText(0, 150, FlxG.width, "HAND SWAP", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.YELLOW, CENTER);
        titleText.alpha = 0;
        titleText.y -= 50;
        add(titleText);

        // Instruction
        instructionText = new FlxText(0, 200, FlxG.width,
            '${currentPlayer.name}, choose a player to swap hands with:', 16);
        instructionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        instructionText.alpha = 0;
        instructionText.y -= 30;
        add(instructionText);

        // Initialize groups
        playerButtons = new FlxTypedGroup<FlxSprite>();
        playerTexts = new FlxTypedGroup<FlxText>();
        playerCards = new FlxTypedGroup<FlxSprite>();
        add(playerButtons);
        add(playerTexts);
        add(playerCards);
    }

    private function setupPlayerOptions():Void {
        var startY = 280;
        var spacing = 100;
        var optionWidth = 300;
        var optionHeight = 80;

        for (i in 0...availablePlayers.length) {
            var player = availablePlayers[i];
            var yPos = startY + (i * spacing);

            // Player option background
            var optionBg = new FlxSprite(FlxG.width * 0.5 - optionWidth * 0.5, yPos);
            optionBg.makeGraphic(optionWidth, optionHeight, FlxColor.fromRGB(40, 40, 60));
            optionBg.alpha = 0;
            optionBg.scale.set(0.1, 0.1);
            playerButtons.add(optionBg);

            // Player name and info
            var playerInfo = '${player.name}\n${player.getHandSize()} cards';
            var playerText = new FlxText(optionBg.x + 20, optionBg.y + 15, optionWidth - 40, playerInfo, 16);
            playerText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
            playerText.alpha = 0;
            playerTexts.add(playerText);

            // Hand size indicator (mini cards)
            var cardGroup = new FlxSprite(optionBg.x + optionWidth - 80, optionBg.y + 20);
            cardGroup.makeGraphic(60, 40, FlxColor.TRANSPARENT);

            // Draw mini card representations
            var handSize = player.getHandSize();
            var cardWidth = Std.int(Math.min(8, 60 / Math.max(1, handSize)));
            for (j in 0...Std.int(Math.min(handSize, 7))) { // Show max 7 cards
                var miniCard = new FlxSprite();
                miniCard.makeGraphic(6, 10, FlxColor.fromRGB(200, 200, 200));
                var border = new FlxSprite();
                border.makeGraphic(4, 8, FlxColor.fromRGB(100, 100, 100));
                miniCard.stamp(border, 1, 1);
                cardGroup.stamp(miniCard, j * cardWidth, 15);
            }

            // Add "..." if more than 7 cards
            if (handSize > 7) {
                var dots = new FlxText(0, 0, 20, "...", 8);
                dots.setFormat(Paths.font("vcr.ttf"), 8, FlxColor.WHITE, CENTER);
                dots.y = 25;
                cardGroup.stamp(dots, 45, 0);
            }

            cardGroup.alpha = 0;
            playerCards.add(cardGroup);
        }
    }

    private function setupParticles():Void {
        particles = new FlxTypedGroup<FlxSprite>();
        add(particles);

        // Create floating card particles
        for (i in 0...20) {
            var particle = new FlxSprite();
            particle.makeGraphic(12, 16, FlxColor.fromRGBFloat(
                FlxG.random.float(0.7, 1.0),
                FlxG.random.float(0.7, 1.0),
                FlxG.random.float(0.2, 0.8)
            ));
            particle.x = FlxG.random.float(-50, FlxG.width + 50);
            particle.y = FlxG.random.float(FlxG.height, FlxG.height + 100);
            particle.alpha = FlxG.random.float(0.2, 0.6);
            particle.angle = FlxG.random.float(-15, 15);
            particles.add(particle);

            // Animate particles floating upward
            FlxTween.tween(particle, {
                y: FlxG.random.float(-100, -50),
                angle: particle.angle + FlxG.random.float(-45, 45)
            }, FlxG.random.float(8, 12), {
                ease: FlxEase.sineInOut,
                onComplete: function(_) {
                    particle.y = FlxG.random.float(FlxG.height, FlxG.height + 100);
                    particle.x = FlxG.random.float(-50, FlxG.width + 50);
                }
            });

            // Add gentle swaying
            FlxTween.tween(particle, {x: particle.x + FlxG.random.float(-30, 30)},
                FlxG.random.float(3, 5), {
                type: PINGPONG,
                ease: FlxEase.sineInOut
            });
        }
    }

    private function animateIn():Void {
        try {
            // Fade in background
            try {
                if (bgOverlay != null) {
                    FlxTween.tween(bgOverlay, {alpha: 1}, 0.5, {ease: FlxEase.sineOut});
                }
            } catch(e:Dynamic) {
                trace("Error animating background: " + e);
            }

            // Animate title
            try {
                if (titleText != null) {
                    FlxTween.tween(titleText, {alpha: 1, y: titleText.y + 50}, 0.6, {
                        ease: FlxEase.backOut,
                        startDelay: 0.2
                    });
                }
            } catch(e:Dynamic) {
                trace("Error animating title: " + e);
            }

            // Animate instruction
            try {
                if (instructionText != null) {
                    FlxTween.tween(instructionText, {alpha: 1, y: instructionText.y + 30}, 0.6, {
                        ease: FlxEase.backOut,
                        startDelay: 0.4
                    });
                }
            } catch(e:Dynamic) {
                trace("Error animating instruction: " + e);
            }

            // Animate player options with stagger
            try {
                if (playerButtons != null && playerTexts != null && playerCards != null) {
                    for (i in 0...playerButtons.length) {
                        try {
                            var button = null, text = null, cards = null;

                            // Safely get elements
                            try { button = (i < playerButtons.members.length) ? playerButtons.members[i] : null; } catch(e:Dynamic) button = null;
                            try { text = (i < playerTexts.members.length) ? playerTexts.members[i] : null; } catch(e:Dynamic) text = null;
                            try { cards = (i < playerCards.members.length) ? playerCards.members[i] : null; } catch(e:Dynamic) cards = null;

                            if (button == null || text == null || cards == null) {
                                trace("Skipping animation for index " + i + " - missing elements");
                                continue;
                            }

                            var delay = 0.6 + (i * 0.1);

                            // Scale in button
                            try {
                                if (button.scale != null) {
                                    FlxTween.tween(button.scale, {x: 1, y: 1}, 0.4, {
                                        ease: FlxEase.backOut,
                                        startDelay: delay
                                    });
                                }
                                FlxTween.tween(button, {alpha: 1}, 0.3, {
                                    startDelay: delay
                                });
                            } catch(e:Dynamic) {
                                trace("Error animating button " + i + ": " + e);
                            }

                            // Fade in text and cards
                            try {
                                FlxTween.tween(text, {alpha: 1}, 0.3, {
                                    startDelay: delay + 0.2
                                });
                            } catch(e:Dynamic) {
                                trace("Error animating text " + i + ": " + e);
                            }

                            try {
                                FlxTween.tween(cards, {alpha: 1}, 0.3, {
                                    startDelay: delay + 0.3
                                });
                            } catch(e:Dynamic) {
                                trace("Error animating cards " + i + ": " + e);
                            }
                        } catch(e:Dynamic) {
                            trace("Error in player option animation " + i + ": " + e);
                        }
                    }
                }
            } catch(e:Dynamic) {
                trace("Error in player options animation loop: " + e);
            }

            // Mark animation complete
            try {
                new FlxTimer().start(1.5, function(_) {
                    animationComplete = true;
                });
            } catch(e:Dynamic) {
                trace("Error starting animation timer: " + e);
                // Fallback: set animation complete immediately
                animationComplete = true;
            }
        } catch(e:Dynamic) {
            trace("Critical error in animateIn: " + e);
            // Emergency fallback
            animationComplete = true;
        }
    }

    private function animateOut(onComplete:Void->Void):Void {
        animationComplete = false;

        // Animate everything out
        FlxTween.tween(bgOverlay, {alpha: 0}, 0.4);
        FlxTween.tween(titleText, {alpha: 0, y: titleText.y - 30}, 0.4);
        FlxTween.tween(instructionText, {alpha: 0, y: instructionText.y - 20}, 0.4);

        for (i in 0...playerButtons.length) {
            // Get members safely with null checks
            var button = null, text = null, cards = null;
            try { button = (i < playerButtons.members.length) ? playerButtons.members[i] : null; } catch(e:Dynamic) button = null;
            try { text = (i < playerTexts.members.length) ? playerTexts.members[i] : null; } catch(e:Dynamic) text = null;
            try { cards = (i < playerCards.members.length) ? playerCards.members[i] : null; } catch(e:Dynamic) cards = null;

            var delay = i * 0.05;

            // Only animate if button exists
            if (button != null) {
                FlxTween.tween(button.scale, {x: 0.1, y: 0.1}, 0.3, {
                    startDelay: delay,
                    ease: FlxEase.backIn
                });
                FlxTween.tween(button, {alpha: 0}, 0.3, {startDelay: delay});
            }

            // Only animate if text exists
            if (text != null) {
                FlxTween.tween(text, {alpha: 0}, 0.2, {startDelay: delay});
            }

            // Only animate if cards exist
            if (cards != null) {
                FlxTween.tween(cards, {alpha: 0}, 0.2, {startDelay: delay});
            }
        }

        new FlxTimer().start(0.6, function(_) {
            onComplete();
        });
        shouldBeClosed = true;
        close();
        meantToClose = true;
    }
    var meantToClose:Bool = false;

    private function selectPlayer(index:Int):Void {
        if (!animationComplete || index < 0 || index >= availablePlayers.length || meantToClose) return;

        try {
            var selectedPlayer = availablePlayers[index];
            var button = null;

            // Safely get the button with error handling
            try {
                button = (index < playerButtons.members.length) ? playerButtons.members[index] : null;
            } catch(e:Dynamic) {
                trace("Error getting button at index " + index + ": " + e);
                button = null;
            }

            // Play selection sound
            try {
                FlxG.sound.play(Paths.sound('confirmMenu'), 0.8);
            } catch(e:Dynamic) {
                trace("Error playing selection sound: " + e);
            }

            // Flash effect (only if button exists)
            if (button != null) {
                FlxTween.color(button, 0.2, button.color, FlxColor.YELLOW, {
                    type: PINGPONG,
                    onComplete: function(_) {
                        animateOut(function() {
                            close();
                            if (onPlayerSelected != null) {
                                onPlayerSelected(selectedPlayer);
                            }
                            onPlayerSelected = null; // Prevent multiple calls
                        });
                    }
                });
            } else {
                trace("Warning: Button is null for index " + index + ", skipping flash animation");
                // No button animation, but still proceed with selection
                try {
                    animateOut(function() {
                        close();
                        if (onPlayerSelected != null) {
                            onPlayerSelected(selectedPlayer);
                        }
                        onPlayerSelected = null; // Prevent multiple calls
                    });
                } catch(e:Dynamic) {
                    trace("Error in no-button animateOut: " + e);
                    try {
                        close();
                        if (onPlayerSelected != null) {
                            onPlayerSelected(selectedPlayer);
                        }
                        onPlayerSelected = null; // Prevent multiple calls
                    } catch(e2:Dynamic) {
                        trace("No-button emergency close failed: " + e2);
                    }
                }
            }
        } catch(e:Dynamic) {
            trace("Critical error in selectPlayer: " + e);
            // Emergency fallback
            try {
                close();
            } catch(e2:Dynamic) {
                trace("Emergency close in selectPlayer failed: " + e2);
            }
        }
    }

    private function startCPUSelection():Void {
        try {
            if (!animationComplete || currentPlayer.isHuman) return;

            // Start CPU thinking timer after animation is complete
            try {
                cpuThinkingTimer = new FlxTimer().start(1.5, function(_) {
                    try {
                        // CPU chooses player with smallest hand (most beneficial)
                        if (availablePlayers == null || availablePlayers.length == 0) {
                            trace("Error: No available players for CPU selection");
                            return;
                        }

                        var bestChoice = availablePlayers[0];
                        try {
                            for (player in availablePlayers) {
                                if (player != null && player.getHandSize() < bestChoice.getHandSize()) {
                                    bestChoice = player;
                                }
                            }
                        } catch(e:Dynamic) {
                            trace("Error finding best choice: " + e);
                            // Use first available player as fallback
                            bestChoice = availablePlayers[0];
                        }

                        try {
                            var bestIndex = availablePlayers.indexOf(bestChoice);
                            if (bestIndex >= 0) {
                                selectPlayer(bestIndex);
                            } else {
                                trace("Error: Best choice not found in available players");
                                // Fallback: select first player
                                selectPlayer(0);
                            }
                        } catch(e:Dynamic) {
                            trace("Error in CPU selectPlayer call: " + e);
                            // Last resort: try to select first player
                            try {
                                selectPlayer(0);
                            } catch(e2:Dynamic) {
                                trace("CPU selection complete failure: " + e2);
                            }
                        }
                    } catch(e:Dynamic) {
                        trace("Error in CPU thinking timer callback: " + e);
                    }
                });
            } catch(e:Dynamic) {
                trace("Error starting CPU thinking timer: " + e);
                // Fallback: immediate selection
                try {
                    if (availablePlayers != null && availablePlayers.length > 0) {
                        selectPlayer(0);
                    }
                } catch(e2:Dynamic) {
                    trace("CPU immediate selection fallback failed: " + e2);
                }
            }
        } catch(e:Dynamic) {
            trace("Critical error in startCPUSelection: " + e);
        }
    }

    private function updateHover():Void {
        if (!animationComplete || !currentPlayer.isHuman) return; // Skip hover for CPU players

        try {
            var hoveredIndex = -1;

            // Safely check for hovered buttons
            try {
                if (playerButtons != null && playerButtons.members != null) {
                    for (i in 0...playerButtons.length) {
                        try {
                            var button = (i < playerButtons.members.length) ? playerButtons.members[i] : null;
                            if (button != null && FlxG.mouse.overlaps(button)) {
                                hoveredIndex = i;
                                break;
                            }
                        } catch(e:Dynamic) {
                            trace("Error checking button hover " + i + ": " + e);
                        }
                    }
                }
            } catch(e:Dynamic) {
                trace("Error in hover detection loop: " + e);
            }

            if (hoveredIndex != selectedIndex) {
                // Remove previous hover effect
                try {
                    if (selectedIndex >= 0 && selectedIndex < playerButtons.length && playerButtons.members != null) {
                        var prevButton = null;
                        try {
                            prevButton = (selectedIndex < playerButtons.members.length) ? playerButtons.members[selectedIndex] : null;
                        } catch(e:Dynamic) {
                            trace("Error getting previous button: " + e);
                        }

                        if (prevButton != null) {
                            try {
                                FlxTween.cancelTweensOf(prevButton);
                                FlxTween.tween(prevButton, {y: prevButton.y + 5}, 0.2, {ease: FlxEase.sineOut});
                            } catch(e:Dynamic) {
                                trace("Error removing hover effect: " + e);
                            }
                        }

                        try {
                            if (glowEffect != null) {
                                glowEffect.visible = false;
                            }
                        } catch(e:Dynamic) {
                            trace("Error hiding glow effect: " + e);
                        }
                    }
                } catch(e:Dynamic) {
                    trace("Error in removing previous hover: " + e);
                }

                selectedIndex = hoveredIndex;

                // Add new hover effect
                try {
                    if (selectedIndex >= 0 && selectedIndex < playerButtons.length && playerButtons.members != null) {
                        var button = null;
                        try {
                            button = (selectedIndex < playerButtons.members.length) ? playerButtons.members[selectedIndex] : null;
                        } catch(e:Dynamic) {
                            trace("Error getting new button: " + e);
                        }

                        if (button != null) {
                            try {
                                FlxTween.cancelTweensOf(button);
                                FlxTween.tween(button, {y: button.y - 5}, 0.2, {ease: FlxEase.sineOut});
                            } catch(e:Dynamic) {
                                trace("Error adding hover animation: " + e);
                            }

                            // Show glow effect
                            try {
                                if (glowEffect != null) {
                                    glowEffect.x = button.x - 10;
                                    glowEffect.y = button.y - 10;
                                    glowEffect.visible = true;
                                    glowEffect.alpha = 0.3;

                                    // Pulse glow
                                    FlxTween.tween(glowEffect, {alpha: 0.1}, 0.8, {
                                        type: PINGPONG,
                                        ease: FlxEase.sineInOut
                                    });
                                }
                            } catch(e:Dynamic) {
                                trace("Error showing glow effect: " + e);
                            }

                            try {
                                Cursor.cursorMode = Pointer;
                            } catch(e:Dynamic) {
                                trace("Error setting cursor to pointer: " + e);
                            }
                        }
                    } else {
                        try {
                            Cursor.cursorMode = Default;
                        } catch(e:Dynamic) {
                            trace("Error setting cursor to default: " + e);
                        }
                    }
                } catch(e:Dynamic) {
                    trace("Error in adding new hover: " + e);
                }
            }
        } catch(e:Dynamic) {
            trace("Critical error in updateHover: " + e);
        }
    }

    override function update(elapsed:Float) {
        try {
            super.update(elapsed);
        } catch(e:Dynamic) {
            trace("Error in super.update: " + e);
        }

        try {
            updateHover();
        } catch(e:Dynamic) {
            trace("Error in updateHover: " + e);
        }

        // Handle input only for human players
        try {
            if (currentPlayer != null && currentPlayer.isHuman) {
                try {
                    if (FlxG.mouse.justPressed && selectedIndex >= 0) {
                        selectPlayer(selectedIndex);
                    }
                } catch(e:Dynamic) {
                    trace("Error in mouse click handling: " + e);
                }

                try {
                    if (FlxG.keys.justPressed.ESCAPE) {
                        try {
                            FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
                        } catch(e:Dynamic) {
                            trace("Error playing cancel sound: " + e);
                        }
                        try {
                            animateOut(function() {
                                onPlayerCancel(currentPlayer);
                                close();
                            });
                        } catch(e:Dynamic) {
                            trace("Error in escape animateOut: " + e);
                            try {
                                onPlayerCancel(currentPlayer);
                                close();
                            } catch(e2:Dynamic) {
                                trace("Error in escape close: " + e2);
                            }
                        }
                    }
                } catch(e:Dynamic) {
                    trace("Error in escape key handling: " + e);
                }

                // Number key shortcuts
                try {
                    if (availablePlayers != null) {
                        for (i in 0...Std.int(Math.min(availablePlayers.length, 9))) {
                            try {
                                var keyPressed = false;
                                switch(i) {
                                    case 0: keyPressed = FlxG.keys.justPressed.ONE;
                                    case 1: keyPressed = FlxG.keys.justPressed.TWO;
                                    case 2: keyPressed = FlxG.keys.justPressed.THREE;
                                    case 3: keyPressed = FlxG.keys.justPressed.FOUR;
                                    case 4: keyPressed = FlxG.keys.justPressed.FIVE;
                                    case 5: keyPressed = FlxG.keys.justPressed.SIX;
                                    case 6: keyPressed = FlxG.keys.justPressed.SEVEN;
                                    case 7: keyPressed = FlxG.keys.justPressed.EIGHT;
                                    case 8: keyPressed = FlxG.keys.justPressed.NINE;
                                }

                                if (keyPressed) {
                                    selectPlayer(i);
                                    break;
                                }
                            } catch(e:Dynamic) {
                                trace("Error in number key " + i + " handling: " + e);
                            }
                        }
                    }
                } catch(e:Dynamic) {
                    trace("Error in number key shortcuts: " + e);
                }
            }
        } catch(e:Dynamic) {
            trace("Error in human player input handling: " + e);
        }
    }

    override function destroy() {
        // Clean up CPU thinking timer to prevent issues
        if (cpuThinkingTimer != null) {
            cpuThinkingTimer.cancel();
            cpuThinkingTimer.destroy();
            cpuThinkingTimer = null;
        }

        // Make sure cursor is restored
        if (currentPlayer != null && currentPlayer.isHuman) {
            Cursor.show();
            Cursor.cursorMode = Default;
        }

        super.destroy();
    }
}
