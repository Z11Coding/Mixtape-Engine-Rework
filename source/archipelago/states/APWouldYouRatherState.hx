package archipelago.states;

import archipelago.APItem;
import archipelago.states.APChoiceState;
import archipelago.traps.TrapGameManager;
import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween.FlxTweenType;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class APWouldYouRatherState extends APChoiceState
{
    private static var scenarios:Array<ScenarioData> = [];
    private static var initialized:Bool = false;

    public function new(?backToState:FlxState)
    {
        if (!initialized) initializeScenarios();

        var scenario = scenarios[FlxG.random.int(0, scenarios.length - 1)];

        super(
            "Would You Rather?",
            scenario.description,
            scenario.choice1,
            scenario.choice2,
            scenario.choice1Action,
            scenario.choice2Action,
            backToState
        );
    }

    private static function initializeScenarios():Void
    {
        scenarios = [
            // Health vs Items scenario with mysterious effects
            {
                description: "The shadow realm whispers of a forbidden exchange...",
                choice1: "Embrace the shadows: Gain 3 Shield items but drain your life force",
                choice2: "Reject the shadows: Gain full health but lose protective barriers",
                choice1Action: function() {
                    APItem.createCustomItem("Shadow Deal - Power", ConditionHelper.PlayState(), function() {
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;
                            playState.health = 0.01; // Almost dead but not quite

                            // Mysterious shadow effects
                            playState.camGame.alpha = 0.3;
                            FlxTween.tween(playState.camGame, {alpha: 1.0}, 3.0, {ease: FlxEase.quadOut});

                            // Character becomes shadowy
                            if (playState.boyfriend != null) {
                                playState.boyfriend.alpha = 0.7;
                                FlxTween.tween(playState.boyfriend, {alpha: 1.0}, 2.0, {ease: FlxEase.quadOut});
                            }

                            // Vocals become whispered
                            if (playState.vocals != null) {
                                playState.vocals.volume *= 0.5;
                                playState.vocals.pitch = 0.8;
                            }
                        }

                        // Add 3 shields
                        for (i in 0...3) {
                            APItem.createItemByName("Shield");
                        }
                        APItem.popup("The shadows embrace you, granting protection...", "Would You Rather?");
                    });
                },
                choice2Action: function() {
                    APItem.createCustomItem("Shadow Deal - Rejection", ConditionHelper.PlayState(), function() {
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;
                            playState.health = playState.MaxHP; // Full health

                            // Light-based effects for rejecting shadows
                            playState.camGame.zoom = 1.3;
                            FlxTween.tween(playState.camGame, {zoom: 1.0}, 1.5, {ease: FlxEase.elasticOut});

                            // Character glows briefly
                            if (playState.boyfriend != null) {
                                playState.boyfriend.alpha = 1.5;
                                FlxTween.tween(playState.boyfriend, {alpha: 1.0}, 1.0, {ease: FlxEase.quadOut});
                            }
                        }

                        // Remove all shields
                        APItem.shields = 0;
                        APItem.popup("Light purges the shadows but leaves you exposed...", "Would You Rather?");
                    });
                }
            },

            // Minigame challenge vs consequence
            {
                description: "The Arena of Trials calls to you...",
                choice1: "Accept the Trial of Reflexes (Face the Pong Challenge)",
                choice2: "Accept the Trial of Strategy (Face the Card Challenge)",
                choice1Action: function() {
                    APItem.createCustomItem("Arena Trial - Reflexes", ConditionHelper.Everywhere(), function() {
                        APItem.popup("The Arena beckons... prove your reflexes!", "Would You Rather?");
                        TrapGameManager.launchPongTrap(cast FlxG.state);
                        // Rewards/consequences handled by Pong completion
                    });
                },
                choice2Action: function() {
                    APItem.createCustomItem("Arena Trial - Strategy", ConditionHelper.Everywhere(), function() {
                        APItem.popup("The cards of fate shuffle... prove your cunning!", "Would You Rather?");
                        TrapGameManager.launchUnoTrap(cast FlxG.state);
                        // Rewards/consequences handled by UNO completion
                    });
                }
            },

            // Risk vs Reward with comprehensive effects
            {
                description: "The cosmic dice await your decision...",
                choice1: "Roll the Chaos Dice: Reality might bend in your favor... or against you",
                choice2: "Take the Certain Path: Get guaranteed protection but with mystical bindings",
                choice1Action: function() {
                    APItem.createCustomItem("Cosmic Gamble - Chaos", ConditionHelper.PlayState(), function() {
                        // Mystical dice rolling effects
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;

                            // Camera spins like a dice roll
                            playState.camGame.angle = 360;
                            FlxTween.tween(playState.camGame, {angle: 0}, 2.0, {ease: FlxEase.bounceOut});

                            // Song speed fluctuates during the "roll"
                            if (playState.songSpeedTween != null) playState.songSpeedTween.cancel();
                            playState.songSpeedTween = FlxTween.tween(playState, {songSpeed: 0.1}, 1.0, {
                                ease: FlxEase.quadOut,
                                onComplete: function(twn) {
                                    FlxTween.tween(playState, {songSpeed: 1.0}, 1.0, {ease: FlxEase.bounceOut});
                                }
                            });
                        }

                        if (FlxG.random.bool(50)) {
                            APItem.createItemByName("SvC Effect");
                            APItem.popup("The dice smile upon you! Reality bends to your will!", "Would You Rather?");
                        } else {
                            APItem.createItemByName("Ghost Chat");
                            APItem.popup("The cosmic dice show no mercy...", "Would You Rather?");
                        }
                    });
                },
                choice2Action: function() {
                    APItem.createCustomItem("Cosmic Path - Certainty", ConditionHelper.PlayState(), function() {
                        APItem.createItemByName("Shield");

                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;

                            // Mystical binding effects
                            if (playState.boyfriend != null) {
                                var originalX = playState.boyfriend.x;
                                FlxTween.tween(playState.boyfriend, {x: originalX - 30}, 0.5, {
                                    ease: FlxEase.quadInOut,
                                    type: FlxTweenType.PINGPONG,
                                    loopDelay: 0.5
                                });
                            }

                            // Temporary no heal effect representing bindings
                            playState.noHeal = true;
                            new FlxTimer().start(10.0, function(timer) {
                                playState.noHeal = false;
                                APItem.popup("The mystical bindings fade...", "");
                            });
                        }

                        APItem.popup("Protection comes with mystical bindings...", "Would You Rather?");
                    });
                }
            },

            // Moral dilemma with character interactions
            {
                description: "The spirits of all fighters whisper for aid...",
                choice1: "Channel your essence to aid all: Help others but face the trial",
                choice2: "Embrace personal power: Gain strength but isolation",
                choice1Action: function() {
                    APItem.createCustomItem("Spirit Aid - Altruism", ConditionHelper.PlayState(), function() {
                        // In a real multiplayer context, this would affect all players
                        APItem.createItemByName("Shield"); // Simulating "all players"

                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;

                            // All characters participate in the ritual
                            var characters = [playState.boyfriend, playState.dad, playState.gf].filter(function(char) return char != null);
                            for (char in characters) {
                                // Characters glow with shared energy
                                FlxTween.tween(char, {alpha: 1.5}, 0.5, {
                                    ease: FlxEase.quadInOut,
                                    onComplete: function(twn) {
                                        FlxTween.tween(char, {alpha: 1.0}, 1.0, {ease: FlxEase.quadOut});
                                    }
                                });
                            }

                            // Harmony in vocals
                            if (playState.vocals != null && playState.opponentVocals != null) {
                                playState.vocals.pitch = 1.0;
                                playState.opponentVocals.pitch = 1.0;
                            }
                        }

                        // Face a trial for your kindness
                        APItem.popup("Your sacrifice is noted, but proves your worth in trial...", "Would You Rather?");
                        new FlxTimer().start(2.0, function(timer) {
                            if (FlxG.random.bool()) {
                                TrapGameManager.launchPongTrap(cast FlxG.state);
                            } else {
                                TrapGameManager.launchUnoTrap(cast FlxG.state);
                            }
                        });
                    });
                },
                choice2Action: function() {
                    APItem.createCustomItem("Spirit Aid - Isolation", ConditionHelper.PlayState(), function() {
                        APItem.createItemByName("Max HP Up");
                        APItem.createItemByName("Max HP Up");

                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;

                            // Isolation effects - other characters become distant
                            if (playState.dad != null) {
                                FlxTween.tween(playState.dad, {alpha: 0.5}, 1.0, {ease: FlxEase.quadOut});
                            }
                            if (playState.gf != null) {
                                FlxTween.tween(playState.gf, {alpha: 0.5}, 1.0, {ease: FlxEase.quadOut});
                            }

                            // Player becomes more prominent
                            if (playState.boyfriend != null) {
                                var originalScale = playState.boyfriend.scale.x;
                                FlxTween.tween(playState.boyfriend.scale, {x: originalScale * 1.2, y: originalScale * 1.2}, 1.0, {ease: FlxEase.quadOut});
                            }

                            // Solo vocals become stronger
                            if (playState.vocals != null) {
                                playState.vocals.volume *= 1.3;
                            }
                            if (playState.opponentVocals != null) {
                                playState.opponentVocals.volume *= 0.7;
                            }
                        }

                        APItem.popup("Power flows through you, but you stand alone...", "Would You Rather?");
                    });
                }
            },

            // Time vs Power with comprehensive temporal effects
            {
                description: "The temporal vortex offers you a choice in time itself...",
                choice1: "Accelerate through time: Instant healing but reality rushes past you",
                choice2: "Slow the flow of time: Endure frozen moments but gain mystical insight",
                choice1Action: function() {
                    APItem.createCustomItem("Temporal Choice - Acceleration", ConditionHelper.PlayState(), function() {
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;
                            playState.health = playState.MaxHP; // Full heal

                            // Everything speeds up dramatically
                            if (playState.songSpeedTween != null) playState.songSpeedTween.cancel();
                            playState.songSpeedTween = FlxTween.tween(playState, {songSpeed: 3.0}, 1.0, {
                                ease: FlxEase.quadOut,
                                onComplete: function(twn) {
                                    // Then slow back to normal
                                    FlxTween.tween(playState, {songSpeed: 1.0}, 2.0, {ease: FlxEase.quadInOut});
                                }
                            });

                            // Camera effects for speed
                            playState.camZooming = true;
                            playState.camZoomingMult = 4.0;
                            playState.camZoomingFrequency = 16.0;

                            // Characters move in fast forward - use scale pulsing for visual effect
                            var characters = [playState.boyfriend, playState.dad, playState.gf].filter(function(char) return char != null);
                            for (char in characters) {
                                // Simulate faster movement with rapid scale pulsing
                                var originalScaleX = char.scale.x;
                                var originalScaleY = char.scale.y;
                                FlxTween.tween(char.scale, {x: originalScaleX * 1.1, y: originalScaleY * 1.1}, 0.1, {
                                    type: FlxTweenType.PINGPONG,
                                    loopDelay: 0,
                                    onComplete: function(twn) {
                                        // Restore after acceleration period
                                        new FlxTimer().start(3.0, function(timer) {
                                            twn.cancel();
                                            FlxTween.tween(char.scale, {x: originalScaleX, y: originalScaleY}, 0.5);
                                        });
                                    }
                                });
                            }

                            // Audio pitch increases
                            if (playState.vocals != null) playState.vocals.pitch = 1.5;
                            if (playState.opponentVocals != null) playState.opponentVocals.pitch = 1.5;
                        } else {
                            APItem.popup("The time magic fizzles without a battle to heal...", "Would You Rather?");
                        }

                        APItem.popup("Time accelerates, healing wounds but blurring reality...", "Would You Rather?");
                    });
                },
                choice2Action: function() {
                    APItem.createCustomItem("Temporal Choice - Deceleration", ConditionHelper.PlayState(), function() {
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;

                            // Everything slows to a crawl
                            if (playState.songSpeedTween != null) playState.songSpeedTween.cancel();
                            playState.songSpeedTween = FlxTween.tween(playState, {songSpeed: 0.2}, 2.0, {
                                ease: FlxEase.quadOut,
                                onComplete: function(twn) {
                                    // Gradually return to normal
                                    FlxTween.tween(playState, {songSpeed: 1.0}, 3.0, {ease: FlxEase.quadOut});
                                }
                            });

                            // Camera moves in slow motion
                            playState.defaultCamZoom *= 0.8;
                            playState.camZooming = true;
                            playState.camZoomingMult = 0.5;
                            playState.camZoomingFrequency = 2.0;

                            // Audio becomes deep and slow
                            if (playState.vocals != null) playState.vocals.pitch = 0.6;
                            if (playState.opponentVocals != null) playState.opponentVocals.pitch = 0.6;
                        }

                        APItem.createItemByName("Ice Notes"); // Represents the frozen time effect
                        APItem.popup("Time crawls... you see patterns hidden in stillness...", "Would You Rather?");
                    });
                }
            },

            // Mystery vs Mystery with full environmental effects
            {
                description: "Two ancient doorways materialize, each pulsing with unknown energy...",
                choice1: "Step through the Crimson Portal (Face unknown mystical consequences)",
                choice2: "Step through the Azure Portal (Face unknown arcane trials)",
                choice1Action: function() {
                    APItem.createCustomItem("Portal - Crimson", ConditionHelper.PlayState(), function() {
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;

                            // Crimson portal effects - warm, chaotic
                            playState.camGame.angle = FlxG.random.float(-10, 10);
                            FlxTween.tween(playState.camGame, {angle: 0}, 2.0, {ease: FlxEase.elasticOut});

                            // Red tinting effect (simulated with alpha changes)
                            playState.camHUD.alpha = 0.8;
                            FlxTween.tween(playState.camHUD, {alpha: 1.0}, 2.0, {ease: FlxEase.quadOut});

                            // Characters react to crimson energy
                            var characters = [playState.boyfriend, playState.dad, playState.gf].filter(function(char) return char != null);
                            for (char in characters) {
                                var originalY = char.y;
                                FlxTween.tween(char, {y: originalY - FlxG.random.float(50, 100)}, 1.0, {
                                    ease: FlxEase.quadOut,
                                    onComplete: function(twn) {
                                        FlxTween.tween(char, {y: originalY}, 1.0, {ease: FlxEase.bounceOut});
                                    }
                                });
                            }
                        }

                        // Random mystical consequence
                        var mysticalItems = ["Shield", "Max HP Up", "SvC Effect", "Blue Balls Curse", "Ghost Chat"];
                        var randomItem = mysticalItems[FlxG.random.int(0, mysticalItems.length - 1)];
                        APItem.createItemByName(randomItem);
                        APItem.popup("The Crimson Portal's energy courses through you...", "Would You Rather?");
                    });
                },
                choice2Action: function() {
                    APItem.createCustomItem("Portal - Azure", ConditionHelper.PlayState(), function() {
                        if (Std.is(FlxG.state, states.PlayState)) {
                            var playState:states.PlayState = cast FlxG.state;

                            // Azure portal effects - cool, structured
                            playState.camGame.zoom = 1.4;
                            FlxTween.tween(playState.camGame, {zoom: 1.0}, 3.0, {ease: FlxEase.quadInOut});

                            // Blue tinting effect
                            playState.camHUD.alpha = 0.9;
                            FlxTween.tween(playState.camHUD, {alpha: 1.0}, 3.0, {ease: FlxEase.quadOut});

                            // Orderly, crystalline movement patterns
                            var characters = [playState.boyfriend, playState.dad, playState.gf].filter(function(char) return char != null);
                            for (i => char in characters) {
                                if (char != null) {
                                    var originalX = char.x;
                                    FlxTween.tween(char, {x: originalX + (i % 2 == 0 ? 50 : -50)}, 1.5, {
                                        ease: FlxEase.quadInOut,
                                        onComplete: function(twn) {
                                            FlxTween.tween(char, {x: originalX}, 1.5, {ease: FlxEase.quadInOut});
                                        }
                                    });
                                }
                            }
                        }

                        // Azure portal leads to trials
                        APItem.popup("The Azure Portal tests your worthiness...", "Would You Rather?");
                        new FlxTimer().start(2.0, function(timer) {
                            // Random trial type
                            if (FlxG.random.bool()) {
                                TrapGameManager.launchPongTrap(cast FlxG.state);
                            } else {
                                TrapGameManager.launchUnoTrap(cast FlxG.state);
                            }
                        });
                    });
                }
            }
        ];

        initialized = true;
    }
}

typedef ScenarioData = {
    description: String,
    choice1: String,
    choice2: String,
    choice1Action: Void->Void,
    choice2Action: Void->Void
}
