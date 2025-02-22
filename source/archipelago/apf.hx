
effectMap = [
    'colorblind' => function() {
        var ttl:Float = 16;
        var onEnd:(Void->Void) = function() {
            camHUDfilters.remove(filterMap.get("Grayscale").filter);
            camGamefilters.remove(filterMap.get("Grayscale").filter);
        };
        var playSound:String = "colorblind";
        var playSoundVol:Float = 0.8;
        var noIcon:Bool = false;

        camHUDfilters.push(filterMap.get("Grayscale").filter);
        camGamefilters.push(filterMap.get("Grayscale").filter);

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'blur' => function() {
        var originalShaders:Map<Dynamic, Dynamic> = new Map<Dynamic, Dynamic>();
        var ttl:Float = 12;
        var onEnd:(Void->Void) = function() {
            for (sprite in playerField.strumNotes) {
                sprite.shader = originalShaders.get(sprite);
            };
            for (sprite in dadField.strumNotes) {
                sprite.shader = originalShaders.get(sprite);
            };
            for (daNote in unspawnNotes) {
                if (daNote == null) continue;
                if (daNote.strumTime >= Conductor.songPosition)
                    daNote.shader = originalShaders.get(daNote);
            }
            for (daNote in notes) {
                if (daNote == null) continue;
                else
                    daNote.shader = originalShaders.get(daNote);
            }
            boyfriend.shader = originalShaders.get(boyfriend);
            dad.shader = originalShaders.get(dad);
            if (gf != null) gf.shader = originalShaders.get(gf);
            blurEffect.setStrength(0, 0);
            camGamefilters.remove(filterMap.get("BlurLittle").filter);
        };
        var playSound:String = "blur";
        var playSoundVol:Float = 0.7;
        var noIcon:Bool = false;

        if (effectsActive[effect] == null || effectsActive[effect] <= 0) {
            camGamefilters.push(filterMap.get("BlurLittle").filter);
            if (PlayState.curStage.startsWith('school'))
                blurEffect.setStrength(2, 2);
            else
                blurEffect.setStrength(32, 32);
            for (sprite in playerField.strumNotes) {
                originalShaders.set(sprite, sprite.shader);
                sprite.shader = blurEffect.shader;
            };
            for (sprite in dadField.strumNotes) {
                originalShaders.set(sprite, sprite.shader);
                sprite.shader = blurEffect.shader;
            };
            for (daNote in unspawnNotes) {
                if (daNote == null) continue;
                if (daNote.strumTime >= Conductor.songPosition) {
                    originalShaders.set(daNote, daNote.shader);
                    daNote.shader = blurEffect.shader;
                }
            }
            for (daNote in notes) {
                if (daNote == null) continue;
                else {
                    originalShaders.set(daNote, daNote.shader);
                    daNote.shader = blurEffect.shader;
                }
            }
            originalShaders.set(boyfriend, boyfriend.shader);
            boyfriend.shader = blurEffect.shader;
            originalShaders.set(dad, dad.shader);
            dad.shader = blurEffect.shader;
            if (gf != null) {
                originalShaders.set(gf, gf.shader);
                gf.shader = blurEffect.shader;
            }
        }

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'lag' => function() {
        var ttl:Float = 12;
        var onEnd:(Void->Void) = function() {
            lagOn = false;
        };
        var playSound:String = "lag";
        var playSoundVol:Float = 0.7;
        var noIcon:Bool = false;

        lagOn = true;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'mine' => function() {
        var noIcon:Bool = true;
        var startPoint:Int = FlxG.random.int(5, 9);
        var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
        var lastPoint:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
        addNote(1, startPoint, startPoint);
        addNote(1, nextPoint, nextPoint);
        addNote(1, lastPoint, lastPoint);
    },
    'warning' => function() {
        var noIcon:Bool = true;
        var startPoint:Int = FlxG.random.int(5, 9);
        var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
        var lastPoint:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
        addNote(2, startPoint, startPoint, -1);
        addNote(2, nextPoint, nextPoint, -1);
        addNote(2, lastPoint, lastPoint, -1);
    },
    'heal' => function() {
        var noIcon:Bool = true;
        addNote(3, 5, 9);
    },
    'spin' => function() {
        var ttl:Float = 15;
        var onEnd:(Void->Void) = function() {
            for (daNote in unspawnNotes) {
                if (daNote == null) continue;
                if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote) {
                    daNote.spinAmount = 0;
                    daNote.angle = 0;
                }
            }
            for (daNote in notes) {
                if (daNote == null) continue;
                if (!daNote.isSustainNote) {
                    daNote.spinAmount = 0;
                    daNote.angle = 0;
                }
            }
        };
        var playSound:String = "spin";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;

        for (daNote in unspawnNotes) {
            if (daNote == null) continue;
            if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote)
                modManager.setValue('roll', (FlxG.random.bool() ? 1 : -1) * FlxG.random.float(333 * 0.8, 333 * 1.15));
        }
        for (daNote in notes) {
            if (daNote == null) continue;
            if (!daNote.isSustainNote)
                modManager.setValue('roll', 0);
        }

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'songslower' => function() {
        var desiredChangeAmount:Float = FlxG.random.float(0.1, 0.9);
        var changeAmount = playbackRate - Math.max(playbackRate - desiredChangeAmount, 0.2);
        var ttl:Float = 15;
        var onEnd:(Void->Void) = function() {
            set_playbackRate(playbackRate + changeAmount);
            playbackRate + changeAmount;
        };
        var playSound:String = "songslower";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        var alwaysEnd:Bool = true;

        set_playbackRate(playbackRate - changeAmount);
        playbackRate - changeAmount;
        trace(playbackRate);

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd);
    },
    'songfaster' => function() {
        var changeAmount:Float = FlxG.random.float(0.1, 0.9);
        var ttl:Float = 15;
        var onEnd:(Void->Void) = function() {
            set_playbackRate(playbackRate - changeAmount);
            playbackRate - changeAmount;
        };
        var playSound:String = "songfaster";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        var alwaysEnd:Bool = true;

        set_playbackRate(playbackRate + changeAmount);
        playbackRate + changeAmount;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd);
    },
    'scrollswitch' => function() {
        var noIcon:Bool = false;
        var playSound:String = "scrollswitch";
        effectiveDownScroll = !effectiveDownScroll;
        updateScrollUI();
        applyEffect(0, null, playSound, 1, noIcon);
    },
    'scrollfaster' => function() {
        var changeAmount:Float = FlxG.random.float(1.1, 3);
        var ttl:Float = 20;
        var onEnd:(Void->Void) = function() {
            effectiveScrollSpeed -= changeAmount;
            songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
        };
        var playSound:String = "scrollfaster";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        var alwaysEnd:Bool = true;

        effectiveScrollSpeed += changeAmount;
        songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd);
    },
    'notif' => function() {
        backend.window.CppAPI.sendWindowsNotification("Archipelago", notifs[FlxG.random.int(0, notifs.length-1)]);
    },
    'scrollslower' => function() {
        var changeAmount:Float = FlxG.random.float(0.1, 0.9);
        var ttl:Float = 20;
        var onEnd:(Void->Void) = function() {
            effectiveScrollSpeed += changeAmount;
            songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;
        };
        var playSound:String = "scrollslower";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        var alwaysEnd:Bool = true;

        effectiveScrollSpeed -= changeAmount;
        songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * effectiveScrollSpeed;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd);
    },
    'rainbow' => function() {
        var ttl:Float = 20;
        var onEnd:(Void->Void) = function() {
            for (daNote in unspawnNotes) {
                if (daNote == null) continue;
                if (daNote.strumTime >= Conductor.songPosition)
                    daNote.defaultRGB();
            }
            for (daNote in notes) {
                if (daNote == null) continue;
                daNote.defaultRGB();
            }
        };
        var playSound:String = "rainbow";
        var playSoundVol:Float = 0.5;
        var noIcon:Bool = false;

        for (daNote in unspawnNotes) {
            if (daNote == null) continue;
            if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote) {
                daNote.rgbShader.r = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                daNote.rgbShader.g = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                daNote.rgbShader.b = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
            } else if (daNote.strumTime >= Conductor.songPosition && daNote.isSustainNote) {
                daNote.rgbShader.r = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                daNote.rgbShader.g = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                daNote.rgbShader.b = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
            }
        }
        for (daNote in notes) {
            if (daNote == null) continue;
            if (daNote.strumTime >= Conductor.songPosition && !daNote.isSustainNote) {
                daNote.rgbShader.r = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                daNote.rgbShader.g = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                daNote.rgbShader.b = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
            } else if (daNote.strumTime >= Conductor.songPosition && daNote.isSustainNote) {
                daNote.rgbShader.r = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                daNote.rgbShader.g = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
                daNote.rgbShader.b = FlxColor.getHSBColorWheel()[FlxG.random.int(0, 360)];
            }
        }

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'cover' => function() {
        var ttl:Float = 12;
        var onEnd:(Void->Void) = function() {
            errorMessage.kill();
            errorMessages.remove(errorMessage);
            FlxDestroyUtil.destroy(errorMessage);
        };
        var playSound:String = "";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        var alwaysEnd:Bool = true;

        var errorMessage = new FlxSprite();
        var random = FlxG.random.int(0, 14);
        var randomPosition:Bool = true;

        switch (random) {
            case 0:
                errorMessage.loadGraphic(Paths.image("zzzzzzzz"));
                errorMessage.scale.x = errorMessage.scale.y = 0.5;
                errorMessage.updateHitbox();
                playSound = "bell";
                playSoundVol = 0.6;
            case 1:
                errorMessage.loadGraphic(Paths.image("streamervschat/scam"));
                playSound = 'scam';
            case 2:
                errorMessage.loadGraphic(Paths.image("streamervschat/funnyskeletonman"));
                playSound = 'doot';
                errorMessage.scale.x = errorMessage.scale.y = 0.8;
            case 3:
                errorMessage.loadGraphic(Paths.image("streamervschat/error"));
                playSound = 'error';
                errorMessage.scale.x = errorMessage.scale.y = 0.8;
                errorMessage.antialiasing = true;
                errorMessage.updateHitbox();
            case 4:
                errorMessage.loadGraphic(Paths.image("streamervschat/nopunch"));
                playSound = 'nopunch';
                errorMessage.scale.x = errorMessage.scale.y = 0.8;
                errorMessage.antialiasing = true;
                errorMessage.updateHitbox();
            case 5:
                errorMessage.loadGraphic(Paths.image("streamervschat/banana"), true, 397, 750);
                errorMessage.animation.add("dance", [0, 1, 2, 3, 4, 5, 6, 7, 8], 9, true);
                errorMessage.animation.play("dance");
                playSound = 'banana';
                playSoundVol = 0.5;
                errorMessage.scale.x = errorMessage.scale.y = 0.5;
            case 6:
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/mark'), null, false, false).setDimensions(378, 362);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
            case 7:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/fireworks'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'firework';
            case 8:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/spiral'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'spiral';
            case 9:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/thingy'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'thingy';
            case 10:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/light'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'light';
            case 11:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/snow'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'snow';
                playSoundVol = 0.6;
            case 12:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/spiral2'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'spiral';
            case 13:
                randomPosition = false;
                errorMessage = new VideoHandlerMP4();
                cast(errorMessage, VideoHandlerMP4).playMP4(Paths.video('streamervschat/wheel'), null, false, false).setDimensions(1280, 720);
                addedMP4s.push(cast(errorMessage, VideoHandlerMP4));
                errorMessages.add(errorMessage);
                errorMessage.x = errorMessage.y = 0;
                errorMessage.blend = ADD;
                playSound = 'wheel';
            case 14:
                var transitions = ["fadeOut", "fadeColor", "slideLeft", "slideRight", "slideUp", "slideDown", "slideRandom", "fallRandom", "fallSequential"];
                var transition = transitions[FlxG.random.int(0, transitions.length - 1)];
                var duration = FlxG.random.float(0.5, 2);
                TransitionState.fakeTransition({
                    transitionType: transition,
                    duration: duration,
                });
        }

        if (randomPosition) {
            var position = FlxG.random.int(0, 4);
            switch (position) {
                case 0:
                    errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
                    errorMessage.screenCenter(Y);
                    errorMessages.add(errorMessage);
                case 1:
                    errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
                    errorMessage.y = (effectiveDownScroll ? FlxG.height - errorMessage.height : 0);
                    errorMessages.add(errorMessage);
                case 2:
                    errorMessage.x = (FlxG.width - FlxG.width / 4) - errorMessage.width / 2;
                    errorMessage.y = (effectiveDownScroll ? 0 : FlxG.height - errorMessage.height);
                    errorMessages.add(errorMessage);
                case 3:
                    errorMessage.screenCenter(XY);
                    errorMessages.add(errorMessage);
                case 4:
                    errorMessage.x = 0;
                    errorMessage.y = 0;
                    FlxTween.circularMotion(errorMessage, FlxG.width / 2 - errorMessage.width / 2, FlxG.height / 2 - errorMessage.height / 2,
                        errorMessage.width / 2, 0, true, 6, true, {
                            onStart: function(_) {
                                errorMessages.add(errorMessage);
                            },
                            type: LOOPING
                        });
            }
        }

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd);
    },
    'ghost' => function() {
        var ttl:Float = 15;
        var onEnd:(Void->Void) = function() {
            modManager.setValue('sudden', 0);
        };
        var playSound:String = "ghost";
        var playSoundVol:Float = 0.5;
        var noIcon:Bool = false;

        modManager.setValue('sudden', 1);

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'flashbang' => function() {
        var noIcon:Bool = true;
        var playSound:String = "bang";
        if (flashbangTimer != null && flashbangTimer.active)
            flashbangTimer.cancel();
        var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
        whiteScreen.scrollFactor.set();
        whiteScreen.cameras = [camOther];
        add(whiteScreen);
        flashbangTimer.start(0.4, function(timer) {
            camOther.flash(FlxColor.WHITE, 7, null, true);
            remove(whiteScreen);
            FlxG.sound.play(Paths.sound('streamervschat/ringing'), 0.4);
        });
        applyEffect(0, null, playSound, 1, noIcon);
    },
    'nostrum' => function() {
        var ttl:Float = 13;
        var onEnd:(Void->Void) = function() {
            for (i in 0...playerField.strumNotes.length)
                playerField.strumNotes[i].visible = true;
        };
        var playSound:String = "nostrum";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;

        for (i in 0...playerField.strumNotes.length)
            playerField.strumNotes[i].visible = false;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'jackspam' => function() {
        var noIcon:Bool = true;
        var startingPoint = FlxG.random.int(5, 9);
        var endingPoint = FlxG.random.int(startingPoint + 6, startingPoint + 12);
        var dataPicked = FlxG.random.int(0, PlayState.mania);
        for (i in startingPoint...endingPoint) {
            addNote(0, i, i, dataPicked);
        }
    },
    'spam' => function() {
        var noIcon:Bool = true;
        var startingPoint = FlxG.random.int(5, 9);
        var endingPoint = FlxG.random.int(startingPoint + 5, startingPoint + 10);
        for (i in startingPoint...endingPoint) {
            addNote(0, i, i);
        }
    },
    'sever' => function() {
        var ttl:Float = 6;
        var onEnd:(Void->Void) = function() {
            playerField.strumNotes[picked].alpha = 1;
            severInputs[picked] = false;
        };
        var playSound:String = "sever";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;
        var alwaysEnd:Bool = true;

        var chooseFrom:Array<Int> = [];
        for (i in 0...severInputs.length) {
            if (!severInputs[i])
                chooseFrom.push(i);
        }
        if (chooseFrom.length <= 0)
            picked = FlxG.random.int(0, 3);
        else
            picked = chooseFrom[FlxG.random.int(0, chooseFrom.length - 1)];
        playerField.strumNotes[picked].alpha = 0;
        severInputs[picked] = true;

        var okayden:Array<Int> = [];
        for (i in 0...64) {
            okayden.push(i);
        }
        var explosion = new FlxSprite().loadGraphic(Paths.image("streamervschat/explosion"), true, 256, 256);
        explosion.animation.add("boom", okayden, 60, false);
        explosion.animation.finishCallback = function(name) {
            explosion.visible = false;
            explosion.kill();
            remove(explosion);
            FlxDestroyUtil.destroy(explosion);
        };
        explosion.cameras = [camHUD];
        explosion.x = playerField.strumNotes[picked].x + playerField.strumNotes[picked].width / 2 - explosion.width / 2;
        explosion.y = playerField.strumNotes[picked].y + playerField.strumNotes[picked].height / 2 - explosion.height / 2;
        explosion.animation.play("boom", true);
        add(explosion);

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon, alwaysEnd);
    },
    'shake' => function() {
        var noIcon:Bool = false;
        var playSound:String = "shake";
        var playSoundVol:Float = 0.5;
        camHUD.shake(FlxG.random.float(0.03, 0.06), 9, null, true);
        camGame.shake(FlxG.random.float(0.03, 0.06), 9, null, true);
        applyEffect(0, null, playSound, playSoundVol, noIcon);
    },
    'poison' => function() {
        var ttl:Float = 5;
        var onEnd:(Void->Void) = function() {
            drainHealth = false;
            boyfriend.color = 0xffffff;
        };
        var playSound:String = "poison";
        var playSoundVol:Float = 0.6;
        var noIcon:Bool = false;

        drainHealth = true;
        boyfriend.color = 0xf003fc;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'dizzy' => function() {
        var ttl:Float = 8;
        var onEnd:(Void->Void) = function() {
            if (drunkTween != null && drunkTween.active) {
                drunkTween.cancel();
                FlxDestroyUtil.destroy(drunkTween);
            }
            camHUD.scrollAngle = camAngle;
            camGame.scrollAngle = camAngle;
        };
        var playSound:String = "dizzy";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;

        if (effectsActive[effect] == null || effectsActive[effect] <= 0) {
            if (drunkTween != null && drunkTween.active) {
                drunkTween.cancel();
                FlxDestroyUtil.destroy(drunkTween);
            }
            drunkTween = FlxTween.num(0, 24, FlxG.random.float(1.2, 1.4), {
                onUpdate: function(tween) {
                    camHUD.scrollAngle = (tween.executions % 4 > 1 ? 1 : -1) * cast(tween, NumTween).value + camAngle;
                    camGame.scrollAngle = (tween.executions % 4 > 1 ? -1 : 1) * cast(tween, NumTween).value / 2 + camAngle;
                },
                type: PINGPONG
            });
        }

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'noise' => function() {
        var noIcon:Bool = false;
        var noisysound:String = "";
        var noisysoundVol:Float = 1.0;
        switch (FlxG.random.int(0, 9)) {
            case 0:
                noisysound = "dialup";
                noisysoundVol = 0.5;
            case 1:
                noisysound = "crowd";
                noisysoundVol = 0.3;
            case 2:
                noisysound = "airhorn";
                noisysoundVol = 0.6;
            case 3:
                noisysound = "copter";
                noisysoundVol = 0.5;
            case 4:
                noisysound = "magicmissile";
                noisysoundVol = 0.9;
            case 5:
                noisysound = "ping";
                noisysoundVol = 1.0;
            case 6:
                noisysound = "call";
                noisysoundVol = 1.0;
            case 7:
                noisysound = "knock";
                noisysoundVol = 1.0;
            case 8:
                noisysound = "fuse";
                noisysoundVol = 0.7;
            case 9:
                noisysound = "hallway";
                noisysoundVol = 0.9;
        }
        noiseSound.stop();
        noiseSound.loadEmbedded(Paths.sound("streamervschat/"+noisysound));
        noiseSound.volume = noisysoundVol;
        noiseSound.play(true);
    },
    'flip' => function() {
        var ttl:Float = 5;
        var onEnd:(Void->Void) = function() {
            camAngle = 0;
            camHUD.angle = camAngle;
            camGame.angle = camAngle;
        };
        var playSound:String = "flip";
        var playSoundVol:Float = 1;
        var noIcon:Bool = false;

        camAngle = 180;
        camHUD.angle = camAngle;
        camGame.angle = camAngle;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'invuln' => function() {
        var ttl:Float = 5;
        var onEnd:(Void->Void) = function() {
            boyfriend.invuln = false;
            shieldSprite.visible = false;
            dmgMultiplier = 1.0;
        };
        var playSound:String = "invuln";
        var playSoundVol:Float = 0.5;
        var noIcon:Bool = false;

        if (boyfriend.curCharacter.contains("pixel")) {
            shieldSprite.x = boyfriend.x + boyfriend.width / 2 - shieldSprite.width / 2 - 150;
            shieldSprite.y = boyfriend.y + boyfriend.height / 2 - shieldSprite.height / 2 - 150;
        } else {
            shieldSprite.x = boyfriend.x + boyfriend.width / 2 - shieldSprite.width / 2;
            shieldSprite.y = boyfriend.y + boyfriend.height / 2 - shieldSprite.height / 2;
        }
        shieldSprite.visible = true;
        dmgMultiplier = 0;
        boyfriend.invuln = true;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'desync' => function() {
        var ttl:Float = 8;
        var onEnd:(Void->Void) = function() {
            FlxG.sound.music.time += delayOffset;
            delayOffset = 0;
        };
        var playSound:String = "delay";
        var playSoundVol:Float = 1;
        var noIcon:Bool = true;

        delayOffset = FlxG.random.int(Std.int(Conductor.stepCrochet), Std.int(Conductor.stepCrochet) * 3);
        FlxG.sound.music.time -= delayOffset;
        resyncVocals();

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'mute' => function() {
        var ttl:Float = 8;
        var onEnd:(Void->Void) = function() {
            instVolumeMultiplier = 1;
            vocalVolumeMultiplier = 1;
        };
        var playSound:String = "delay";
        var playSoundVol:Float = 1;
        var noIcon:Bool = true;

        if (FlxG.random.bool(15)) {
            instVolumeMultiplier = 0;
        } else {
            vocalVolumeMultiplier = 0;
        }

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'ice' => function() {
        var noIcon:Bool = true;
        var startPoint:Int = FlxG.random.int(5, 9);
        var nextPoint:Int = FlxG.random.int(startPoint + 2, startPoint + 6);
        var lastPoint:Int = FlxG.random.int(nextPoint + 2, nextPoint + 6);
        addNote(4, startPoint, startPoint, -1);
        addNote(4, nextPoint, nextPoint, -1);
        addNote(4, lastPoint, lastPoint, -1);
    },
    'randomize' => function() {
        var ttl:Float = 10;
        var onEnd:(Void->Void) = function() {
            modManager.queueEase(curStep, curStep+3, availableS, 0, "sineInOut");
        };
        var playSound:String = "randomize";
        var playSoundVol:Float = 0.7;
        var noIcon:Bool = false;

        var availableS:String = "";
        switch (FlxG.random.bool(15)) {
            case true:
                availableS = "invert";
            case false:
                availableS = "flip";
        }
        modManager.queueEase(curStep, curStep+3, availableS, .96, "sineInOut");
        trace(availableS);

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'randomizeAlt' => function() {
        var ttl:Float = 10;
        var onEnd:(Void->Void) = function() {
            available = [];
            doRandomize = false;
            for (daNote in notes) {
                if (daNote == null) continue;
                else {
                    daNote.noteData = daNote.trueNoteData;
                }
            }
            for (data => column in playerField.noteQueue) {
                if (column[0] != null) {
                    if (column[0] == null) continue;
                    else {
                        column[0].noteData = available[column[0].noteData];
                    }
                }
            }
        };
        var playSound:String = "randomize";
        var playSoundVol:Float = 0.7;
        var noIcon:Bool = false;

        available = [];
        for (i in 0...PlayState.mania+1) {
            available.push(i);
            trace("available: " + available);
        }
        FlxG.random.shuffle(available);
        switch (available) {
            case [0, 1, 2, 3]:
                available = [3, 2, 1, 0];
            default:
        }
        for (daNote in notes) {
            if (daNote == null) continue;
            else {
                daNote.noteData = available[daNote.noteData];
            }
        }
        for (data => column in playerField.noteQueue) {
            if (column[0] != null) {
                if (column[0] == null) continue;
                else {
                    column[0].noteData = available[column[0].noteData];
                }
            }
        }

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'opponentPlay' => function() {
        var ttl:Float = 12;
        var onEnd:(Void->Void) = function() {
            opponentmode =  false;
            playerField.isPlayer = !opponentmode && !PlayState.playAsGF || bothMode;
            playerField.autoPlayed = opponentmode || cpuControlled || PlayState.playAsGF;
            playerField.noteHitCallback = opponentmode ? opponentNoteHit : goodNoteHit;
            dadField.isPlayer = opponentmode && !PlayState.playAsGF || bothMode;
            dadField.autoPlayed = (!opponentmode || (opponentmode && cpuControlled) || PlayState.playAsGF) || bothMode && cpuControlled;
            dadField.noteHitCallback = opponentmode ? goodNoteHit : opponentNoteHit;
            hp = MaxHP + health;
        };
        var playSound:String = "randomize";
        var playSoundVol:Float = 0.7;
        var noIcon:Bool = true;

        opponentmode =  true;
        playerField.isPlayer = !opponentmode && !PlayState.playAsGF || bothMode;
        playerField.autoPlayed = opponentmode || cpuControlled || PlayState.playAsGF;
        playerField.noteHitCallback = opponentmode ? opponentNoteHit : goodNoteHit;
        dadField.isPlayer = opponentmode && !PlayState.playAsGF || bothMode;
        dadField.autoPlayed = (!opponentmode || (opponentmode && cpuControlled) || PlayState.playAsGF) || bothMode && cpuControlled;
        dadField.noteHitCallback = opponentmode ? goodNoteHit : opponentNoteHit;
        health = MaxHP - health;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'bothplay' => function() {
        var ttl:Float = 12;
        var onEnd:(Void->Void) = function() {
            bothMode = false;
            playerField.isPlayer = !opponentmode && !PlayState.playAsGF || bothMode;
            playerField.autoPlayed = opponentmode || cpuControlled || PlayState.playAsGF;
            playerField.noteHitCallback = opponentmode ? opponentNoteHit : goodNoteHit;
            dadField.isPlayer = opponentmode && !PlayState.playAsGF || bothMode;
            dadField.autoPlayed = (!opponentmode || (opponentmode && cpuControlled) || PlayState.playAsGF) || bothMode && cpuControlled;
            dadField.noteHitCallback = opponentmode ? goodNoteHit : opponentNoteHit;
        };
        var playSound:String = "randomize";
        var playSoundVol:Float = 0.7;
        var noIcon:Bool = true;

        bothMode = true;
        playerField.isPlayer = !opponentmode && !PlayState.playAsGF || bothMode;
        playerField.autoPlayed = opponentmode || cpuControlled || PlayState.playAsGF;
        playerField.noteHitCallback = opponentmode ? opponentNoteHit : goodNoteHit;
        dadField.isPlayer = opponentmode && !PlayState.playAsGF || bothMode;
        dadField.autoPlayed = (!opponentmode || (opponentmode && cpuControlled) || PlayState.playAsGF) || bothMode && cpuControlled;
        dadField.noteHitCallback = opponentmode ? goodNoteHit : opponentNoteHit;

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'fakeheal' => function() {
        var noIcon:Bool = true;
        addNote(5, 5, 9);
    },
    'spell' => function() {
        var noIcon:Bool = false;
        var playSound:String = "spell";
        var playSoundVol:Float = 0.66;
        var spellThing = new SpellPrompt();
        spellPrompts.push(spellThing);
        applyEffect(0, null, playSound, playSoundVol, noIcon);
    },
    'terminate' => function() {
        var noIcon:Bool = true;
        terminateStep = 3;
    },
    'lowpass' => function() {
        var ttl:Float = 10;
        var onEnd:(Void->Void) = function() {
            blurEffect.setStrength(0, 0);
            camHUDfilters.remove(filterMap.get("BlurLittle").filter);
            camGamefilters.remove(filterMap.get("BlurLittle").filter);
            lowFilterAmount = 1;
            vocalLowFilterAmount = 1;
        };
        var playSound:String = "delay";
        var playSoundVol:Float = 0.6;
        var noIcon:Bool = true;

        if (FlxG.random.bool(40)) {
            lowFilterAmount = .0134;
            camGamefilters.push(filterMap.get("BlurLittle").filter);
            blurEffect.setStrength(32, 32);
        } else {
            vocalLowFilterAmount = .0134;
            camHUDfilters.push(filterMap.get("BlurLittle").filter);
            camGamefilters.push(filterMap.get("BlurLittle").filter);
            blurEffect.setStrength(32, 32);
        }

        applyEffect(ttl, onEnd, playSound, playSoundVol, noIcon);
    },
    'songSwitch' => function() {
        if (FlxG.save.data.manualOverride != null && FlxG.save.data.manualOverride == false) 
            FlxG.save.data.manualOverride = true;
        else if (FlxG.save.data.manualOverride != null && FlxG.save.data.manualOverride == true) 
            FlxG.save.data.manualOverride = false;

        trace('MANUAL OVERRIDE: ' + FlxG.save.data.manualOverride);

        if (FlxG.save.data.manualOverride) {
            FlxG.save.data.storyWeek = PlayState.storyWeek;
            FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
            FlxG.save.data.difficulties = Difficulty.list; // just in case
            FlxG.save.data.SONG = PlayState.SONG;
            FlxG.save.data.storyDifficulty = PlayState.storyDifficulty;
            FlxG.save.data.songPos = Conductor.songPosition;
            FlxG.save.flush();
        }

        if (FlxG.save.data.manualOverride) {
            PlayState.storyWeek = 0;
            Mods.currentModDirectory = '';
            Difficulty.list = Difficulty.defaultList.copy();
            PlayState.SONG = Song.loadFromJson(Highscore.formatSong('tutorial', curDifficulty), Paths.formatToSongPath('tutorial'));
            PlayState.storyDifficulty = curDifficulty;
            FlxG.save.flush();
        }
        MusicBeatState.resetState();
    }
];