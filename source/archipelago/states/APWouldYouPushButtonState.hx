package archipelago.states;

import archipelago.APItem;
import archipelago.states.APChoiceState;
import archipelago.traps.TrapGameManager;
import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class APWouldYouPushButtonState extends APChoiceState
{
    private static var buttonScenarios:Array<ButtonScenarioData> = [];
    private static var initialized:Bool = false;

    public function new(?backToState:FlxState)
    {
        if (!initialized) initializeScenarios();

        var scenario = buttonScenarios[FlxG.random.int(0, buttonScenarios.length - 1)];

        super(
            "Would You Push The Button?",
            scenario.description + "\n\nBUT: " + scenario.consequence,
            "PUSH THE BUTTON",
            "DON'T PUSH IT",
            scenario.pushAction,
            scenario.dontPushAction,
            backToState
        );
    }

    private static function initializeScenarios():Void
    {
        buttonScenarios = [
            // Ultimate power scenario
            {
                description: "You gain unlimited Shield items and Max HP Ups for the rest of the game...",
                consequence: "But reality itself will bend and warp around you",
                pushAction: function() {
                    APItem.createCustomItem("Button - Ultimate Power", ConditionHelper.Everywhere(), function() {
                        // Give massive benefits (GOOD)
                        for (i in 0...10) {
                            APItem.createItemByName("Shield");
                            APItem.createItemByName("Max HP Up");
                        }
                        // BAD: Reality bending effects
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;
                            // Warp the song speed mysteriously
                            if (playState.songSpeedTween != null) playState.songSpeedTween.cancel();
                            playState.songSpeedTween = FlxTween.tween(playState, {songSpeed: playState.songSpeed * 0.3}, 2.0, {
                                ease: FlxEase.cubeInOut,
                                onComplete: function(twn:FlxTween) {
                                    FlxTween.tween(playState, {songSpeed: playState.songSpeed * 3.33}, 1.5, {ease: FlxEase.bounceOut});
                                }
                            });
                            // Mysterious camera effects
                            playState.defaultCamZoom += 0.5;
                            playState.camZooming = true;
                            playState.camZoomingMult = 2.0;
                            // Vocals distortion
                            if (playState.vocals != null) playState.vocals.pitch = 0.7;
                            if (playState.opponentVocals != null) playState.opponentVocals.pitch = 1.3;
                        }
                        APItem.createItemByName("Blue Balls Curse"); // Additional curse
                        APItem.popup("Power courses through you as reality warps...", "The Button");
                    });
                },
                dontPushAction: function() {
                    // Nothing happens - no reward, no penalty
                    APItem.createCustomItem("Button - Restraint", ConditionHelper.Everywhere(), function() {
                        APItem.popup("You chose not to push the button. Nothing happens.", "The Button");
                    });
                }
            },

            // Chaos scenario with minigame
            {
                description: "You instantly complete the current song with perfect accuracy...",
                consequence: "But you must prove your skill in a trial of reflexes",
                pushAction: function() {
                    APItem.createCustomItem("Button - Chaos Victory", ConditionHelper.PlayState(), function() {
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;
                            // GOOD: Full heal and mysterious benefits
                            playState.health = playState.MaxHP;
                            // Mysterious character movements
                            if (playState.boyfriend != null) {
                                FlxTween.tween(playState.boyfriend, {x: playState.boyfriend.x + 100}, 1.0, {ease: FlxEase.elasticOut});
                            }
                            if (playState.dad != null) {
                                FlxTween.tween(playState.dad, {x: playState.dad.x - 100}, 1.0, {ease: FlxEase.elasticOut});
                            }
                            // BAD: Must face the Pong challenge
                            APItem.popup("Victory achieved, but prove your worth in the trial...", "The Button");
                            FlxG.sound.music.fadeOut(1.0);
                            new FlxTimer().start(1.5, function(timer) {
                                TrapGameManager.launchPongTrap(cast FlxG.state);
                            });
                        } else {
                            // Outside PlayState, just give benefits and curse
                            APItem.createItemByName("Max HP Up");
                            APItem.createItemByName("Blue Balls Curse");
                            APItem.popup("The button's power works differently here...", "The Button");
                        }
                    });
                },
                dontPushAction: function() {
                    // Nothing happens
                    APItem.createCustomItem("Button - No Action", ConditionHelper.Everywhere(), function() {
                        APItem.popup("You chose not to push the button. Nothing happens.", "The Button");
                    });
                }
            },

            // Gambling scenario with UNO challenge
            {
                description: "You have a chance to get massive defensive bonuses...",
                consequence: "But first, you must face the test of cards and strategy",
                pushAction: function() {
                    APItem.createCustomItem("Button - Card Gamble", ConditionHelper.Everywhere(), function() {
                        // Always trigger the UNO challenge first
                        APItem.popup("The cards of fate demand a trial...", "The Button");
                        TrapGameManager.launchUnoTrap(cast FlxG.state);
                        // Note: Rewards will be given after UNO completion through UNO state logic
                    });
                },
                dontPushAction: function() {
                    // Nothing happens
                    APItem.createCustomItem("Button - No Gamble", ConditionHelper.Everywhere(), function() {
                        APItem.popup("You chose not to gamble. Nothing happens.", "The Button");
                    });
                }
            },

            // Time manipulation scenario with mysterious effects
            {
                description: "You can rewind time to before any mistake you've made...",
                consequence: "But temporal energy will surge through the battlefield",
                pushAction: function() {
                    APItem.createCustomItem("Button - Time Rewind", ConditionHelper.PlayState(), function() {
                        // GOOD: Reset health and clear negative effects
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;
                            playState.health = playState.MaxHP;
                            playState.noHeal = false;

                            // BAD: Mysterious temporal effects
                            // Freeze time momentarily
                            playState.songSpeed = 0;
                            FlxTween.tween(playState, {songSpeed: 1.0}, 3.0, {ease: FlxEase.quadOut});

                            // Camera filters and effects
                            playState.camGame.zoom = 1.5;
                            FlxTween.tween(playState.camGame, {zoom: 1.0}, 2.0, {ease: FlxEase.bounceOut});

                            // Character position warping
                            if (playState.gf != null) {
                                var originalY = playState.gf.y;
                                FlxTween.tween(playState.gf, {y: originalY - 200}, 1.0, {
                                    ease: FlxEase.quadOut,
                                    onComplete: function(twn) {
                                        FlxTween.tween(playState.gf, {y: originalY}, 1.0, {ease: FlxEase.bounceOut});
                                    }
                                });
                            }
                        }

                        // Lose a beneficial thing as price
                        var lossOptions = [
                            function() { if (APItem.shields > 0) APItem.shields--; },
                            function() { if (APItem.maxHPUp > 0) APItem.maxHPUp--; },
                            function() { APItem.createItemByName("Ice Notes"); }
                        ];
                        var randomLoss = lossOptions[FlxG.random.int(0, lossOptions.length - 1)];
                        randomLoss();

                        APItem.popup("Time rewinds, but temporal energy disrupts reality...", "The Button");
                    });
                },
                dontPushAction: function() {
                    // Nothing happens
                    APItem.createCustomItem("Button - Accept Time", ConditionHelper.Everywhere(), function() {
                        APItem.popup("You chose not to manipulate time. Nothing happens.", "The Button");
                    });
                }
            },

            // Vision scenario with mysterious effects
            {
                description: "You can glimpse the patterns of fate and see future challenges...",
                consequence: "But the visions will haunt your perception of reality",
                pushAction: function() {
                    APItem.createCustomItem("Button - Future Sight", ConditionHelper.Everywhere(), function() {
                        // GOOD: Give defensive bonuses
                        APItem.createItemByName("Shield");
                        APItem.createItemByName("Max HP Up");

                        // BAD: Mysterious visual distortions
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;
                            // Camera shake and zoom effects
                            playState.camGame.shake(0.01, 5.0);
                            FlxTween.tween(playState.camGame, {zoom: 0.8}, 1.0, {
                                ease: FlxEase.quadInOut,
                                onComplete: function(twn) {
                                    FlxTween.tween(playState.camGame, {zoom: 1.2}, 1.0, {
                                        ease: FlxEase.quadInOut,
                                        onComplete: function(twn2) {
                                            FlxTween.tween(playState.camGame, {zoom: 1.0}, 0.5, {ease: FlxEase.quadOut});
                                        }
                                    });
                                }
                            });

                            // HUD transparency effects for "haunting" feel
                            if (playState.camHUD != null) {
                                FlxTween.tween(playState.camHUD, {alpha: 0.3}, 2.0, {
                                    ease: FlxEase.quadInOut,
                                    onComplete: function(twn) {
                                        FlxTween.tween(playState.camHUD, {alpha: 1.0}, 1.0, {ease: FlxEase.quadOut});
                                    }
                                });
                            }
                        }

                        APItem.createItemByName("Ghost Chat"); // Represents haunting visions
                        APItem.popup("The visions reveal much, but leave their mark...", "The Button");
                    });
                },
                dontPushAction: function() {
                    // Nothing happens
                    APItem.createCustomItem("Button - Stay Blind", ConditionHelper.Everywhere(), function() {
                        APItem.popup("You chose to remain in the dark. Nothing happens.", "The Button");
                    });
                }
            },

            // Sacrifice scenario with character animation
            {
                description: "You can channel your life force to protect others...",
                consequence: "But your very essence will be changed by the ritual",
                pushAction: function() {
                    APItem.createCustomItem("Button - Life Sacrifice", ConditionHelper.Everywhere(), function() {
                        // BAD first: Lose defensive items
                        APItem.shields = 0;
                        APItem.maxHPUp = 0;

                        // GOOD: Gain different power with valid items
                        APItem.createItemByName("Max HP Up");
                        APItem.createItemByName("Shield");

                        // Mysterious ritual effects
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;

                            // All characters participate in the ritual
                            if (playState.boyfriend != null) {
                                var originalScale = playState.boyfriend.scale.x;
                                FlxTween.tween(playState.boyfriend.scale, {x: originalScale * 1.5, y: originalScale * 1.5}, 1.0, {
                                    ease: FlxEase.quadOut,
                                    onComplete: function(twn) {
                                        FlxTween.tween(playState.boyfriend.scale, {x: originalScale, y: originalScale}, 1.0, {ease: FlxEase.elasticOut});
                                    }
                                });
                            }

                            if (playState.dad != null && playState.gf != null) {
                                // Characters glow briefly
                                playState.dad.alpha = 0.5;
                                playState.gf.alpha = 0.5;
                                FlxTween.tween(playState.dad, {alpha: 1.0}, 2.0, {ease: FlxEase.quadOut});
                                FlxTween.tween(playState.gf, {alpha: 1.0}, 2.0, {ease: FlxEase.quadOut});
                            }

                            // Vocals become ethereal
                            if (playState.vocals != null) playState.vocals.pitch = 0.9;
                            if (playState.gfVocals != null) playState.gfVocals.pitch = 1.1;
                        }

                        APItem.popup("The ritual is complete. You are... different...", "The Button");
                    });
                },
                dontPushAction: function() {
                    // Nothing happens
                    APItem.createCustomItem("Button - Preserve Self", ConditionHelper.Everywhere(), function() {
                        APItem.popup("You chose to keep your essence unchanged. Nothing happens.", "The Button");
                    });
                }
            },

            // Reality distortion scenario with comprehensive effects
            {
                description: "The fabric of the song itself will bend to your will...",
                consequence: "But chaos will reign as the musical universe tries to correct itself",
                pushAction: function() {
                    APItem.createCustomItem("Button - Reality Distortion", ConditionHelper.Everywhere(), function() {
                        // GOOD: Potential massive rewards
                        for (i in 0...3) {
                            APItem.createItemByName("Shield");
                            APItem.createItemByName("Max HP Up");
                        }

                        // BAD: Comprehensive reality distortion
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;

                            // Song speed chaos
                            if (playState.songSpeedTween != null) playState.songSpeedTween.cancel();
                            playState.songSpeedTween = FlxTween.tween(playState, {songSpeed: 2.0}, 1.0, {
                                ease: FlxEase.quadInOut,
                                onComplete: function(twn) {
                                    FlxTween.tween(playState, {songSpeed: 0.5}, 1.5, {
                                        ease: FlxEase.quadInOut,
                                        onComplete: function(twn2) {
                                            FlxTween.tween(playState, {songSpeed: 1.0}, 1.0, {ease: FlxEase.bounceOut});
                                        }
                                    });
                                }
                            });

                            // Camera chaos
                            playState.camZooming = true;
                            playState.camZoomingMult = 3.0;
                            playState.camZoomingFrequency = 8.0;

                            // Character position chaos
                            var characters = [playState.boyfriend, playState.dad, playState.gf].filter(function(char) return char != null);
                            for (char in characters) {
                                var originalX = char.x;
                                var originalY = char.y;
                                FlxTween.tween(char, {
                                    x: originalX + FlxG.random.float(-200, 200),
                                    y: originalY + FlxG.random.float(-100, 100)
                                }, 2.0, {
                                    ease: FlxEase.quadOut,
                                    onComplete: function(twn) {
                                        FlxTween.tween(char, {x: originalX, y: originalY}, 1.5, {ease: FlxEase.elasticOut});
                                    }
                                });
                            }

                            // Audio distortion
                            if (playState.vocals != null) {
                                FlxTween.tween(playState.vocals, {pitch: 1.5}, 1.0, {
                                    ease: FlxEase.quadInOut,
                                    onComplete: function(twn) {
                                        FlxTween.tween(playState.vocals, {pitch: 1.0}, 2.0, {ease: FlxEase.quadOut});
                                    }
                                });
                            }
                        }

                        APItem.createItemByName("SvC Effect"); // Immediate chaos
                        APItem.popup("Reality fractures and rebuilds itself around you...", "The Button");
                    });
                },
                dontPushAction: function() {
                    // Nothing happens
                    APItem.createCustomItem("Button - Preserve Reality", ConditionHelper.Everywhere(), function() {
                        APItem.popup("You chose to leave reality unchanged. Nothing happens.", "The Button");
                    });
                }
            }
        ];

        initialized = true;
    }
}

typedef ButtonScenarioData = {
    description: String,
    consequence: String,
    pushAction: Void->Void,
    dontPushAction: Void->Void
}
