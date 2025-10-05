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
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoPlayer;

/**
 * Stylish color choice substate for wild cards
 */
class ColorChoiceSubstate extends MusicBeatSubstate {
    private var availableColors:Array<UnoColor>;
    private var onColorSelected:UnoColor->Void;
    private var currentPlayer:UnoPlayer; // Track current player for CPU logic

    // UI Elements
    private var bgOverlay:FlxSprite;
    private var titleText:FlxText;
    private var instructionText:FlxText;
    private var colorOrbs:FlxTypedGroup<FlxSprite>;
    private var colorTexts:FlxTypedGroup<FlxText>;
    private var colorGlows:FlxTypedGroup<FlxSprite>;
    private var selectedIndex:Int = -1;
    private var centerGlow:FlxSprite;

    // Animation variables
    private var animationComplete:Bool = false;
    private var magicParticles:FlxTypedGroup<FlxSprite>;
    private var orbPositions:Array<{x:Float, y:Float}> = [];
    private var cpuThinkingTimer:FlxTimer;
    private var bgColorTween:FlxTween; // For background color matching

    public function new(currentPlayer:UnoPlayer, availableColors:Array<UnoColor>, onColorSelected:UnoColor->Void) {
        super();
        this.currentPlayer = currentPlayer;
        this.availableColors = availableColors.copy();
        this.onColorSelected = onColorSelected;

        // Remove WILD from choosable colors if present
        this.availableColors = this.availableColors.filter(function(color) return color != WILD);
    }

    override function create() {
        super.create();

        setupBackground();
        setupUI();
        setupColorOrbs();
        setupMagicEffects();
        animateIn();

        // Handle CPU players automatically
        if (!currentPlayer.isHuman) {
            // Import UnoCPU to access color choice logic
            if (Std.isOfType(currentPlayer, games.uno.backend.UnoCPU)) {
                var cpuPlayer = cast(currentPlayer, games.uno.backend.UnoCPU);
                cpuThinkingTimer = new FlxTimer().start(1.2, function(_) {
                    // Use CPU's own color choice logic
                    var chosenColor = cpuPlayer.chooseWildColor(availableColors);
                    var colorIndex = availableColors.indexOf(chosenColor);
                    if (colorIndex >= 0) {
                        selectColor(colorIndex);
                    } else if (availableColors.length > 0) {
                        // Fallback to first color if choice logic fails
                        selectColor(0);
                    }
                });
            } else {
                // Fallback for non-CPU players that aren't human
                cpuThinkingTimer = new FlxTimer().start(1.2, function(_) {
                    if (availableColors.length > 0) {
                        selectColor(0); // Choose first available color
                    }
                });
            }
            Cursor.hide();
        } else {
            Cursor.show();
            Cursor.cursorMode = Default;
        }
    }

    private function setupBackground():Void {
        // Semi-transparent dark overlay with magical feel
        bgOverlay = new FlxSprite();
        bgOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0.1, 0.05, 0.2, 0.9));
        bgOverlay.alpha = 0;
        add(bgOverlay);

        // Central magical glow
        centerGlow = new FlxSprite();
        centerGlow.makeGraphic(400, 400, FlxColor.fromRGBFloat(0.3, 0.2, 0.8, 0.2));
        centerGlow.x = FlxG.width * 0.5 - 200;
        centerGlow.y = FlxG.height * 0.5 - 200;
        centerGlow.alpha = 0;
        add(centerGlow);
    }

    private function setupUI():Void {
        // Title with magical styling
        titleText = new FlxText(0, 180, FlxG.width, "✦ CHOOSE COLOR ✦", 28);
        titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.fromRGB(255, 215, 0), CENTER);
        titleText.alpha = 0;
        titleText.y -= 40;
        add(titleText);

        // Instruction
        instructionText = new FlxText(0, 230, FlxG.width,
            "Select the color for your wild card", 14);
        instructionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.fromRGB(200, 200, 255), CENTER);
        instructionText.alpha = 0;
        instructionText.y -= 20;
        add(instructionText);

        // Initialize groups
        colorOrbs = new FlxTypedGroup<FlxSprite>();
        colorTexts = new FlxTypedGroup<FlxText>();
        colorGlows = new FlxTypedGroup<FlxSprite>();
        add(colorGlows);
        add(colorOrbs);
        add(colorTexts);
    }

    private function setupColorOrbs():Void {
        var centerX = FlxG.width * 0.5;
        var centerY = FlxG.height * 0.5 + 20;
        var radius = 120;

        // Calculate positions in a circle
        for (i in 0...availableColors.length) {
            var angle = (i / availableColors.length) * Math.PI * 2 - Math.PI * 0.5; // Start at top
            var x = centerX + Math.cos(angle) * radius - 40;
            var y = centerY + Math.sin(angle) * radius - 40;
            orbPositions.push({x: x, y: y});
        }

        for (i in 0...availableColors.length) {
            var color = availableColors[i];
            var pos = orbPositions[i];

            // Color glow (behind orb)
            var glow = new FlxSprite(pos.x - 20, pos.y - 20);
            glow.makeGraphic(120, 120, FlxColor.fromRGBFloat(1, 1, 1, 0.1));
            glow.alpha = 0;
            colorGlows.add(glow);

            // Color orb
            var orb = new FlxSprite(pos.x, pos.y);
            createColorOrb(orb, color);
            orb.alpha = 0;
            orb.scale.set(0.1, 0.1);
            colorOrbs.add(orb);

            // Color name
            var colorName = getColorName(color);
            var colorText = new FlxText(pos.x - 20, pos.y + 90, 120, colorName, 12);
            colorText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
            colorText.alpha = 0;
            colorTexts.add(colorText);
        }
    }

    private function createColorOrb(orb:FlxSprite, color:UnoColor):Void {
        var orbColor = switch(color) {
            case RED: FlxColor.fromRGB(220, 20, 20);
            case BLUE: FlxColor.fromRGB(20, 20, 220);
            case GREEN: FlxColor.fromRGB(20, 180, 20);
            case YELLOW: FlxColor.fromRGB(255, 220, 0);
            case CUSTOM(clr, _): clr;
            case _: FlxColor.WHITE;
        };

        // Create orb with gradient effect
        orb.makeGraphic(80, 80, orbColor);

        // Add highlight
        var highlight = new FlxSprite();
        highlight.makeGraphic(60, 60, FlxColor.fromRGBFloat(1, 1, 1, 0.3));
        orb.stamp(highlight, 10, 10);

        // Add inner glow
        var innerGlow = new FlxSprite();
        innerGlow.makeGraphic(40, 40, FlxColor.fromRGBFloat(1, 1, 1, 0.15));
        orb.stamp(innerGlow, 20, 20);

        // Add border
        var border = new FlxSprite();
        border.makeGraphic(76, 76, FlxColor.fromRGBFloat(1, 1, 1, 0.8));
        var innerBorder = new FlxSprite();
        innerBorder.makeGraphic(72, 72, orbColor);
        border.stamp(innerBorder, 2, 2);
        orb.stamp(border, 2, 2);
    }

    private function getColorName(color:UnoColor):String {
        return switch(color) {
            case RED: "RED";
            case BLUE: "BLUE";
            case GREEN: "GREEN";
            case YELLOW: "YELLOW";
            case CUSTOM(_, name): name != null ? name.substr(0, 8) : "CUSTOM";
            case _: "UNKNOWN";
        };
    }

    private function setupMagicEffects():Void {
        magicParticles = new FlxTypedGroup<FlxSprite>();
        add(magicParticles);

        // Create floating magical particles
        for (i in 0...30) {
            var particle = new FlxSprite();
            var particleColors = [
                FlxColor.fromRGB(255, 215, 0),  // Gold
                FlxColor.fromRGB(255, 255, 255), // White
                FlxColor.fromRGB(200, 200, 255), // Light blue
                FlxColor.fromRGB(255, 200, 255)  // Light pink
            ];

            var particleColor = FlxG.random.getObject(particleColors);
            var size = FlxG.random.int(2, 6);
            particle.makeGraphic(size, size, particleColor);

            // Random position around the center
            var angle = FlxG.random.float(0, Math.PI * 2);
            var distance = FlxG.random.float(50, 200);
            particle.x = FlxG.width * 0.5 + Math.cos(angle) * distance;
            particle.y = FlxG.height * 0.5 + Math.sin(angle) * distance;
            particle.alpha = FlxG.random.float(0.3, 0.8);

            magicParticles.add(particle);

            // Orbit around center
            var orbitSpeed = FlxG.random.float(2, 6);
            var orbitRadius = distance;

            function updateOrbit() {
                angle += orbitSpeed * FlxG.elapsed;
                particle.x = FlxG.width * 0.5 + Math.cos(angle) * orbitRadius;
                particle.y = FlxG.height * 0.5 + Math.sin(angle) * orbitRadius;
            }

            // Add sparkle effect
            FlxTween.tween(particle, {alpha: 0.1}, FlxG.random.float(1, 3), {
                type: PINGPONG,
                ease: FlxEase.sineInOut
            });
        }
    }

    private function animateIn():Void {
        // Fade in background
        FlxTween.tween(bgOverlay, {alpha: 1}, 0.6, {ease: FlxEase.sineOut});

        // Glow center
        FlxTween.tween(centerGlow, {alpha: 1}, 0.8, {
            ease: FlxEase.sineOut,
            startDelay: 0.2
        });

        // Rotate center glow
        FlxTween.angle(centerGlow, 0, 360, 10, {type: LOOPING});

        // Animate title
        FlxTween.tween(titleText, {alpha: 1, y: titleText.y + 40}, 0.7, {
            ease: FlxEase.backOut,
            startDelay: 0.3
        });

        // Animate instruction
        FlxTween.tween(instructionText, {alpha: 1, y: instructionText.y + 20}, 0.6, {
            ease: FlxEase.backOut,
            startDelay: 0.5
        });

        // Animate color orbs with magical entrance
        for (i in 0...colorOrbs.length) {
            var orb = colorOrbs.members[i];
            var text = colorTexts.members[i];
            var glow = colorGlows.members[i];

            var delay = 0.7 + (i * 0.15);

            // Scale in orb with bounce
            FlxTween.tween(orb.scale, {x: 1.2, y: 1.2}, 0.3, {
                ease: FlxEase.backOut,
                startDelay: delay,
                onComplete: function(_) {
                    FlxTween.tween(orb.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.sineOut});
                }
            });

            FlxTween.tween(orb, {alpha: 1}, 0.4, {
                startDelay: delay
            });

            // Fade in text
            FlxTween.tween(text, {alpha: 1}, 0.3, {
                startDelay: delay + 0.2
            });

            // Gentle glow pulse
            FlxTween.tween(glow, {alpha: 0.2}, 0.5, {
                startDelay: delay + 0.3,
                onComplete: function(_) {
                    FlxTween.tween(glow, {alpha: 0.05}, 2, {
                        type: PINGPONG,
                        ease: FlxEase.sineInOut
                    });
                }
            });
        }

        // Mark animation complete
        new FlxTimer().start(2, function(_) {
            animationComplete = true;
        });
    }

    private function animateOut(selectedColor:UnoColor, onComplete:Void->Void):Void {
        animationComplete = false;

        // Find selected orb
        var selectedOrbIndex = availableColors.indexOf(selectedColor);

        // Burst effect from selected orb
        if (selectedOrbIndex >= 0) {
            var selectedOrb = colorOrbs.members[selectedOrbIndex];

            // Create burst particles
            for (i in 0...12) {
                var burst = new FlxSprite(selectedOrb.x + 40, selectedOrb.y + 40);
                burst.makeGraphic(4, 4, selectedOrb.color);
                add(burst);

                var angle = (i / 12) * Math.PI * 2;
                var distance = FlxG.random.float(80, 150);

                FlxTween.tween(burst, {
                    x: burst.x + Math.cos(angle) * distance,
                    y: burst.y + Math.sin(angle) * distance,
                    alpha: 0
                }, 0.8, {
                    ease: FlxEase.sineOut
                });
            }

            // Pulse selected orb
            FlxTween.tween(selectedOrb.scale, {x: 1.5, y: 1.5}, 0.3, {
                ease: FlxEase.sineOut,
                onComplete: function(_) {
                    FlxTween.tween(selectedOrb.scale, {x: 0.1, y: 0.1}, 0.3, {
                        ease: FlxEase.backIn
                    });
                }
            });
        }

        // Fade out other elements
        FlxTween.tween(bgOverlay, {alpha: 0}, 0.5);
        FlxTween.tween(titleText, {alpha: 0, y: titleText.y - 30}, 0.4);
        FlxTween.tween(instructionText, {alpha: 0, y: instructionText.y - 20}, 0.4);
        FlxTween.tween(centerGlow, {alpha: 0}, 0.4);

        // Animate out non-selected orbs
        for (i in 0...colorOrbs.length) {
            if (i == selectedOrbIndex) continue;

            var orb = colorOrbs.members[i];
            var text = colorTexts.members[i];
            var glow = colorGlows.members[i];

            var delay = i * 0.03;

            FlxTween.tween(orb.scale, {x: 0.1, y: 0.1}, 0.3, {
                startDelay: delay,
                ease: FlxEase.backIn
            });
            FlxTween.tween(orb, {alpha: 0}, 0.3, {startDelay: delay});
            FlxTween.tween(text, {alpha: 0}, 0.2, {startDelay: delay});
            FlxTween.tween(glow, {alpha: 0}, 0.2, {startDelay: delay});
        }

        new FlxTimer().start(0.8, function(_) {
            onComplete();
        });
    }

    private function selectColor(index:Int):Void {
        if (!animationComplete || index < 0 || index >= availableColors.length) return;

        var selectedColor = availableColors[index];

        // Play magical selection sound
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.9);

        // Start smart timeout - if game doesn't progress in 3 seconds, force completion
        var initialSubstateExists = true;
        var timeoutTimer = new FlxTimer().start(3.0, function(_) {
            // Check if game has progressed
            var gameProgressed = false;
            try {
                // Check if substate still exists (should be closed by now)
                if (FlxG.state != null && FlxG.state.subState == null) {
                    gameProgressed = true;
                }
                // Additional checks could be added here for game state
            } catch (e:Dynamic) {
                trace("Error checking game progress: " + e);
            }

            if (!gameProgressed && initialSubstateExists) {
                trace("Smart timeout triggered - forcing color choice completion");
                // Force close and trigger callback
                close();
                if (onColorSelected != null) {
                    onColorSelected(selectedColor);
                }
            }
        });

        animateOut(selectedColor, function() {
            // Cancel timeout since normal completion happened
            if (timeoutTimer != null) {
                timeoutTimer.cancel();
            }
            initialSubstateExists = false;
            close();
            if (onColorSelected != null) {
                onColorSelected(selectedColor);
            }
        });
    }

    private function updateHover():Void {
        if (!animationComplete || !currentPlayer.isHuman) return; // Skip hover for CPU players

        var hoveredIndex = -1;

        for (i in 0...colorOrbs.length) {
            var orb = colorOrbs.members[i];
            if (orb != null && FlxG.mouse.overlaps(orb)) {
                hoveredIndex = i;
                break;
            }
        }

        if (hoveredIndex != selectedIndex) {
            // Remove previous hover effect
            if (selectedIndex >= 0) {
                var prevOrb = colorOrbs.members[selectedIndex];
                var prevGlow = colorGlows.members[selectedIndex];
                FlxTween.cancelTweensOf(prevOrb.scale);
                FlxTween.tween(prevOrb.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.sineOut});
                FlxTween.tween(prevGlow, {alpha: 0.05}, 0.2);
            }

            selectedIndex = hoveredIndex;

            // Add new hover effect
            if (selectedIndex >= 0) {
                var orb = colorOrbs.members[selectedIndex];
                var glow = colorGlows.members[selectedIndex];

                FlxTween.cancelTweensOf(orb.scale);
                FlxTween.tween(orb.scale, {x: 1.1, y: 1.1}, 0.2, {ease: FlxEase.sineOut});
                FlxTween.tween(glow, {alpha: 0.4}, 0.2);

                // Add gentle rotation
                FlxTween.angle(orb, orb.angle, orb.angle + 360, 2, {ease: FlxEase.sineInOut});

                // Tween background color to match selected orb
                var targetColor = switch(availableColors[selectedIndex]) {
                    case RED: 0xFFFF0000;
                    case YELLOW: 0xFFFFFF00;
                    case GREEN: 0xFF00FF00;
                    case BLUE: 0xFF0000FF;
                    default: 0xFFFFFFFF;
                };
                if (bgColorTween != null) bgColorTween.cancel();
                bgColorTween = FlxTween.color(bgOverlay, 0.3, bgOverlay.color,
                    FlxColor.interpolate(0xFF000000, targetColor, 0.3), {
                    ease: FlxEase.sineOut
                });

                Cursor.cursorMode = Pointer;
            } else {
                // Reset background to dark when not hovering
                if (bgColorTween != null) bgColorTween.cancel();
                bgColorTween = FlxTween.color(bgOverlay, 0.3, bgOverlay.color, 0xFF000000, {
                    ease: FlxEase.sineOut
                });
                Cursor.cursorMode = Default;
            }
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        updateHover();

        // Update magic particle orbits
        for (particle in magicParticles.members) {
            if (particle == null) continue;

            var centerX = FlxG.width * 0.5;
            var centerY = FlxG.height * 0.5;
            var dx = particle.x - centerX;
            var dy = particle.y - centerY;
            var distance = Math.sqrt(dx * dx + dy * dy);
            var angle = Math.atan2(dy, dx);

            angle += 2 * elapsed;
            particle.x = centerX + Math.cos(angle) * distance;
            particle.y = centerY + Math.sin(angle) * distance;
        }

        // Handle input only for human players
        if (currentPlayer.isHuman) {
            if (FlxG.mouse.justPressed && selectedIndex >= 0) {
                selectColor(selectedIndex);
            }

            if (FlxG.keys.justPressed.ESCAPE) {
                FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
                animateOut(null, function() {
                    close();
                });
            }

            // Number key shortcuts and arrow keys
            for (i in 0...Std.int(Math.min(availableColors.length, 9))) {
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
                    selectColor(i);
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

        // Clean up background color tween
        if (bgColorTween != null) {
            bgColorTween.cancel();
            bgColorTween = null;
        }

        // Make sure cursor is restored
        if (currentPlayer != null && currentPlayer.isHuman) {
            Cursor.show();
            Cursor.cursorMode = Default;
        }

        super.destroy();
    }
}
