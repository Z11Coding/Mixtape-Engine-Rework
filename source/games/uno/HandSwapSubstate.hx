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

    public function new(currentPlayer:UnoPlayer, availablePlayers:Array<UnoPlayer>, onPlayerSelected:UnoPlayer->Void) {
        super();
        this.currentPlayer = currentPlayer;
        this.availablePlayers = availablePlayers.copy();
        this.onPlayerSelected = onPlayerSelected;

        // Remove current player from available choices
        this.availablePlayers.remove(currentPlayer);
    }

    override function create() {
        super.create();

        setupBackground();
        setupUI();
        setupPlayerOptions();
        setupParticles();
        animateIn();

        // Handle CPU players automatically
        if (!currentPlayer.isHuman) {
            cpuThinkingTimer = new FlxTimer().start(1.5, function(_) {
                // CPU chooses player with smallest hand (most beneficial)
                var bestChoice = availablePlayers[0];
                for (player in availablePlayers) {
                    if (player.getHandSize() < bestChoice.getHandSize()) {
                        bestChoice = player;
                    }
                }
                selectPlayer(availablePlayers.indexOf(bestChoice));
            });
            Cursor.hide();
        } else {
            Cursor.show();
            Cursor.cursorMode = Default;
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
        // Fade in background
        FlxTween.tween(bgOverlay, {alpha: 1}, 0.5, {ease: FlxEase.sineOut});

        // Animate title
        FlxTween.tween(titleText, {alpha: 1, y: titleText.y + 50}, 0.6, {
            ease: FlxEase.backOut,
            startDelay: 0.2
        });

        // Animate instruction
        FlxTween.tween(instructionText, {alpha: 1, y: instructionText.y + 30}, 0.6, {
            ease: FlxEase.backOut,
            startDelay: 0.4
        });

        // Animate player options with stagger
        for (i in 0...playerButtons.length) {
            var button = playerButtons.members[i];
            var text = playerTexts.members[i];
            var cards = playerCards.members[i];

            if (button == null || text == null || cards == null) continue;

            var delay = 0.6 + (i * 0.1);

            // Scale in button
            FlxTween.tween(button.scale, {x: 1, y: 1}, 0.4, {
                ease: FlxEase.backOut,
                startDelay: delay
            });

            FlxTween.tween(button, {alpha: 1}, 0.3, {
                startDelay: delay
            });

            // Fade in text and cards
            FlxTween.tween(text, {alpha: 1}, 0.3, {
                startDelay: delay + 0.2
            });

            FlxTween.tween(cards, {alpha: 1}, 0.3, {
                startDelay: delay + 0.3
            });
        }

        // Mark animation complete
        new FlxTimer().start(1.5, function(_) {
            animationComplete = true;
        });
    }

    private function animateOut(onComplete:Void->Void):Void {
        animationComplete = false;

        // Animate everything out
        FlxTween.tween(bgOverlay, {alpha: 0}, 0.4);
        FlxTween.tween(titleText, {alpha: 0, y: titleText.y - 30}, 0.4);
        FlxTween.tween(instructionText, {alpha: 0, y: instructionText.y - 20}, 0.4);

        for (i in 0...playerButtons.length) {
            // Get members safely with null checks
            var button = (i < playerButtons.members.length) ? playerButtons.members[i] : null;
            var text = (i < playerTexts.members.length) ? playerTexts.members[i] : null;
            var cards = (i < playerCards.members.length) ? playerCards.members[i] : null;

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
    }

    private function selectPlayer(index:Int):Void {
        if (!animationComplete || index < 0 || index >= availablePlayers.length) return;

        var selectedPlayer = availablePlayers[index];
        var button = playerButtons.members[index];

        // Play selection sound
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.8);

        // Flash effect
        FlxTween.color(button, 0.2, button.color, FlxColor.YELLOW, {
            type: PINGPONG,
            onComplete: function(_) {
                animateOut(function() {
                    close();
                    if (onPlayerSelected != null) {
                        onPlayerSelected(selectedPlayer);
                    }
                });
            }
        });
    }

    private function updateHover():Void {
        if (!animationComplete || !currentPlayer.isHuman) return; // Skip hover for CPU players

        var hoveredIndex = -1;

        for (i in 0...playerButtons.length) {
            var button = playerButtons.members[i];
            if (button != null && FlxG.mouse.overlaps(button)) {
                hoveredIndex = i;
                break;
            }
        }

        if (hoveredIndex != selectedIndex) {
            // Remove previous hover effect
            if (selectedIndex >= 0 && selectedIndex < playerButtons.length) {
                var prevButton = playerButtons.members[selectedIndex];
                if (prevButton != null) {
                    FlxTween.cancelTweensOf(prevButton);
                    FlxTween.tween(prevButton, {y: prevButton.y + 5}, 0.2, {ease: FlxEase.sineOut});
                }
                glowEffect.visible = false;
            }

            selectedIndex = hoveredIndex;

            // Add new hover effect
            if (selectedIndex >= 0 && selectedIndex < playerButtons.length) {
                var button = playerButtons.members[selectedIndex];
                if (button != null) {
                    FlxTween.cancelTweensOf(button);
                FlxTween.tween(button, {y: button.y - 5}, 0.2, {ease: FlxEase.sineOut});

                // Show glow effect
                glowEffect.x = button.x - 10;
                glowEffect.y = button.y - 10;
                glowEffect.visible = true;
                glowEffect.alpha = 0.3;

                // Pulse glow
                FlxTween.tween(glowEffect, {alpha: 0.1}, 0.8, {
                    type: PINGPONG,
                    ease: FlxEase.sineInOut
                });

                    Cursor.cursorMode = Pointer;
                }
            } else {
                Cursor.cursorMode = Default;
            }
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        updateHover();

        // Handle input only for human players
        if (currentPlayer.isHuman) {
            if (FlxG.mouse.justPressed && selectedIndex >= 0) {
                selectPlayer(selectedIndex);
            }

            if (FlxG.keys.justPressed.ESCAPE) {
                FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
                animateOut(function() {
                    close();
                });
            }

            // Number key shortcuts
            for (i in 0...Std.int(Math.min(availablePlayers.length, 9))) {
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
        }
        } // End human player input check
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
