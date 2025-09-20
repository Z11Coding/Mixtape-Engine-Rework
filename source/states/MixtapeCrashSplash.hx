package states;

import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.SplashScreen.SplashGlowParticle;

/**
 * Rare crash splash screen variant that shows the Mixtape Engine text fading in slowly,
 * then the logo crashes down breaking apart the text with a metal pipe sound effect
 */
class MixtapeCrashSplash extends MusicBeatState {
    // Text elements
    var mixtapeEngineText:FlxText;
    var mixtapeLogo:FlxSprite;

    // Background
    var splashGrad:FlxSprite;

    // Particle systems
    var splashGlowParticles:FlxTypedGroup<SplashGlowParticle>;
    var debrisParticles:FlxTypedGroup<DebrisParticle>;

    // Audio
    var metalPipeSound:FlxSound;

    // Animation states
    var currentPhase:Int = 0;
    var logoFalling:Bool = false;
    var crashComplete:Bool = false;

    // Timing
    var phaseTimer:FlxTimer;

    override public function create() {
        super.create();

        // Mark game as initialized
        states.FirstCheckState.gameInitialized = true;

        setupBackground();
        setupText();
        setupLogo();
        setupParticles();
        setupAudio();
        startAnimation();
    }

    function setupBackground() {
        // Gradient background similar to normal splash but darker
        splashGrad = new FlxSprite().loadGraphic(Paths.image('effects/GradientSplash'));
        splashGrad.screenCenter();
        splashGrad.color = FlxColor.fromRGB(40, 10, 60); // Darker purple
        splashGrad.alpha = 0.3;
        add(splashGrad);

        // Slowly brighten the background
        FlxTween.tween(splashGrad, {alpha: 0.8}, 3, {ease: FlxEase.sineInOut});
    }

    function setupText() {
        // Main Mixtape Engine text - starts invisible
        mixtapeEngineText = new FlxText(0, 0, 1200, "MIXTAPE ENGINE", 32);
        mixtapeEngineText.font = Paths.font('FridayNightFunkin.ttf');
        mixtapeEngineText.screenCenter();
        mixtapeEngineText.size = 120;
        mixtapeEngineText.alpha = 0;
        mixtapeEngineText.color = FlxColor.WHITE;
        add(mixtapeEngineText);
    }

    function setupLogo() {
        // Mixtape logo starts way off screen above
        mixtapeLogo = new FlxSprite().loadGraphic(Paths.image('logo'));
        mixtapeLogo.screenCenter();
        mixtapeLogo.setGraphicSize(Std.int(mixtapeLogo.width * 0.6)); // Bigger than normal splash
        mixtapeLogo.updateHitbox();
        mixtapeLogo.y = -500; // Start way above screen
        mixtapeLogo.alpha = 0;
        add(mixtapeLogo);
    }

    function setupParticles() {
        // Glow particles for the text reveal
        splashGlowParticles = new FlxTypedGroup<SplashGlowParticle>();
        add(splashGlowParticles);

        // Debris particles for the crash
        debrisParticles = new FlxTypedGroup<DebrisParticle>();
        add(debrisParticles);
    }

    function setupAudio() {
        // Load the metal pipe sound
        metalPipeSound = new FlxSound().loadEmbedded(Paths.sound('metal_pipe'));
        metalPipeSound.volume = 0.8;
        FlxG.sound.list.add(metalPipeSound);
    }

    function startAnimation() {
        // Phase 1: Slow text fade in (3 seconds)
        phaseTimer = new FlxTimer().start(1, function(_) {
            currentPhase = 1;
            fadeInText();
        });
    }

    function fadeInText() {
        // Very slow fade in with glow effect
        FlxTween.tween(mixtapeEngineText, {alpha: 1}, 3, {
            ease: FlxEase.sineInOut,
            onComplete: function(_) {
                // Add subtle glow particles around text
                createTextGlow();

                // Wait a moment, then start the crash sequence
                phaseTimer = new FlxTimer().start(2, function(_) {
                    currentPhase = 2;
                    startCrashSequence();
                });
            }
        });
    }

    function createTextGlow() {
        // Create gentle particles around the text
        var particlesNum:Int = 15;
        for (i in 0...particlesNum) {
            var particle:SplashGlowParticle = new SplashGlowParticle(
                mixtapeEngineText.x + FlxG.random.float(0, mixtapeEngineText.width),
                mixtapeEngineText.y + FlxG.random.float(0, mixtapeEngineText.height),
                FlxColor.CYAN
            );
            particle.alpha = 0.3;
            splashGlowParticles.add(particle);
        }
    }

    function startCrashSequence() {
        currentPhase = 2;
        logoFalling = true;

        // Make logo visible and start falling
        mixtapeLogo.alpha = 1;

        // Camera shake anticipation
        FlxG.camera.shake(0.001, 0.5);

        // Logo falls down with increasing speed
        FlxTween.tween(mixtapeLogo, {
            y: mixtapeEngineText.y - 50
        }, 1.2, {
            ease: FlxEase.expoIn,
            onComplete: function(_) {
                crash();
            }
        });

        // Add falling sound effect (optional wind or whoosh)
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.3); // Temporary - could use whoosh sound
    }

    function crash() {
        currentPhase = 3;
        crashComplete = true;
        logoFalling = false;

        // METAL PIPE SOUND!
        metalPipeSound.play();

        // Massive camera shake
        FlxG.camera.shake(0.05, 1.0);

        // Flash effect
        var flashSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
        flashSprite.alpha = 0.8;
        add(flashSprite);
        FlxTween.tween(flashSprite, {alpha: 0}, 0.3, {
            ease: FlxEase.expoOut,
            onComplete: function(_) {
                remove(flashSprite);
            }
        });

        // Break apart the text
        breakText();

        // Create debris explosion
        createDebrisExplosion();

        // Logo bounces a bit then settles
        FlxTween.tween(mixtapeLogo, {y: mixtapeLogo.y + 20}, 0.1, {
            ease: FlxEase.bounceOut,
            onComplete: function(_) {
                FlxTween.tween(mixtapeLogo, {y: mixtapeLogo.y - 10}, 0.1, {
                    ease: FlxEase.sineOut,
                    onComplete: function(_) {
                        // Start fade out sequence after a moment
                        phaseTimer = new FlxTimer().start(2, function(_) {
                            startFadeOut();
                        });
                    }
                });
            }
        });
    }

    function breakText() {
        // Make original text flicker and break apart
        FlxTween.tween(mixtapeEngineText, {alpha: 0}, 0.2, {
            ease: FlxEase.expoOut
        });

        // Create individual letter pieces that fly away
        var letters = mixtapeEngineText.text.split('');
        var letterWidth = mixtapeEngineText.width / letters.length;

        for (i in 0...letters.length) {
            if (letters[i] != ' ') {
                var letterSprite = new FlxText(
                    mixtapeEngineText.x + (i * letterWidth),
                    mixtapeEngineText.y,
                    letterWidth,
                    letters[i],
                    Std.int(mixtapeEngineText.size)
                );
                letterSprite.font = mixtapeEngineText.font;
                letterSprite.color = mixtapeEngineText.color;
                add(letterSprite);

                // Random direction and rotation for each letter
                var randomX = FlxG.random.float(-200, 200);
                var randomY = FlxG.random.float(-100, 300);
                var randomAngle = FlxG.random.float(-360, 360);

                FlxTween.tween(letterSprite, {
                    x: letterSprite.x + randomX,
                    y: letterSprite.y + randomY,
                    angle: randomAngle,
                    alpha: 0
                }, FlxG.random.float(0.5, 1.5), {
                    ease: FlxEase.expoOut,
                    onComplete: function(_) {
                        remove(letterSprite);
                    }
                });
            }
        }
    }

    function createDebrisExplosion() {
        // Create debris particles from the impact point
        var impactX = mixtapeLogo.x + mixtapeLogo.width / 2;
        var impactY = mixtapeLogo.y + mixtapeLogo.height;

        for (i in 0...30) {
            var debris = new DebrisParticle(impactX, impactY);
            debrisParticles.add(debris);
        }

        // Create secondary particle explosion
        var particlesNum:Int = 25;
        for (i in 0...particlesNum) {
            var particle:SplashGlowParticle = new SplashGlowParticle(
                impactX + FlxG.random.float(-50, 50),
                impactY + FlxG.random.float(-30, 30),
                FlxColor.fromRGB(FlxG.random.int(150, 255), FlxG.random.int(100, 200), 0) // Orange/yellow explosion colors
            );
            particle.velocity.x = FlxG.random.float(-200, 200);
            particle.velocity.y = FlxG.random.float(-300, -100);
            splashGlowParticles.add(particle);
        }
    }

    function startFadeOut() {
        currentPhase = 4;

        // Fade out everything
        FlxTween.tween(mixtapeLogo, {alpha: 0}, 2, {ease: FlxEase.sineInOut});
        FlxTween.tween(splashGrad, {alpha: 0}, 2, {ease: FlxEase.sineInOut});

        // Fade out all particles
        splashGlowParticles.forEachAlive(function(particle:SplashGlowParticle) {
            FlxTween.tween(particle, {alpha: 0}, 1.5, {ease: FlxEase.sineOut});
        });

        debrisParticles.forEachAlive(function(debris:DebrisParticle) {
            FlxTween.tween(debris, {alpha: 0}, 1.5, {ease: FlxEase.sineOut});
        });

        // Transition to next state after fade out
        phaseTimer = new FlxTimer().start(2.5, function(_) {
            finishSplash();
        });
    }

    function finishSplash() {
        // Clean up
        Conductor.songPosition = 0;

        // Transition to the next state (same as normal splash screen)
        TransitionState.transitionState(
            FirstCheckState.relaunch ? MainMenuState : TitleState,
            {duration: 1.5, transitionType: "stickers", color: FlxColor.BLACK}
        );
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        // Allow skipping with any key after text appears
        if (currentPhase >= 1 && FlxG.keys.justPressed.ANY) {
            skipToEnd();
        }
    }

    function skipToEnd() {
        // Stop all timers and tweens
        if (phaseTimer != null) phaseTimer.cancel();
        FlxTween.globalManager.forEach(function(tween:FlxTween) {
            if (!tween.finished) tween.cancel();
        });

        // Quick fade to black and finish
        var blackout = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        blackout.alpha = 0;
        add(blackout);

        FlxTween.tween(blackout, {alpha: 1}, 0.5, {
            ease: FlxEase.sineOut,
            onComplete: function(_) {
                finishSplash();
            }
        });
    }

    override public function destroy() {
        // Clean up audio
        if (metalPipeSound != null) {
            metalPipeSound.stop();
            metalPipeSound = null;
        }

        super.destroy();
    }
}

/**
 * Debris particle class for the crash effect
 */
class DebrisParticle extends FlxSprite {
    public function new(x:Float, y:Float) {
        super(x, y);

        // Random debris shapes and colors
        var debrisSize = FlxG.random.int(3, 8);
        makeGraphic(debrisSize, debrisSize, FlxColor.fromRGB(
            FlxG.random.int(100, 200),
            FlxG.random.int(100, 200),
            FlxG.random.int(100, 200)
        ));

        // Random velocity and physics
        velocity.x = FlxG.random.float(-300, 300);
        velocity.y = FlxG.random.float(-400, -150);
        acceleration.y = 600; // Gravity
        drag.x = 100;

        // Random rotation
        angularVelocity = FlxG.random.float(-500, 500);

        // Auto-destroy after a while
        new FlxTimer().start(3, function(_) {
            destroy();
        });
    }
}
