
local startTime = 0
local everyBeat = 2--set to 1 in-case you want it every beat lol
local lockCameraTarget = ""
local doStrumAngleAnim = false

function onCreatePost()


	precacheImage('characters/Z11Talking1')
	precacheImage('characters/Z11Talking2')
	
	
    startTime = getPropertyFromClass("states.PlayState", "startOnTime")

    addHaxeLibrary("shaders.ColorSwap")

    if startTime > 0 then
        setProperty("camZooming", true)
    end
	
	if startTime <= 0 then
    setProperty("defaultCamZoom", 0.00001)
	end

    makeLuaSprite('dark', nil, 0, 0);
    makeGraphic('dark', screenWidth, screenHeight, '000000')
    setGraphicSize('dark')
    addLuaSprite('dark', true);
    setProperty('dark.alpha', 1);
    setObjectCamera('dark','hud')
end

function addCameraZoom(camGameValue, camHUDValue)
    triggerEvent("Add Camera Zoom", tostring(camGameValue), tostring(camHUDValue))
end

function cameraFlashWrap(camera, color, duration, force, ignoreFlashSettings)
    if camera == nil then camera = "other" end
    if color == nil then color = "ffffff" end
    if duration == nil then duration = crochet / 500 / playbackRate end
    if force == nil then force = false end
    if ignoreFlashSettings == nil then ignoreFlashSettings = false end

    if flashingLights or ignoreFlashSettings then
        cameraFlash(camera, color, duration, force)
    end
end

local songTimeOffset = 0

function zoomEvent(v1,v2)

    if v2 == '' then
        setProperty("defaultCamZoom",v1)
    else
        doTweenZoom('camz','camGame',tonumber(v1),tonumber(v2),'sineIn')
    end
end

function noteShit(side, switchup)
    if curBeat % everyBeat * 2 == 0 or switchup == true then
        setPropertyFromGroup(side, 1, 'angle', -10)
        setPropertyFromGroup(side, 1, 'y', defaultOpponentStrumY0 - 40)

        setPropertyFromGroup(side, 2, 'angle', 10)
        setPropertyFromGroup(side, 2, 'y', defaultOpponentStrumY0 - 40)

        setPropertyFromGroup(side, 0, 'angle', 10)
        setPropertyFromGroup(side, 0, 'y', defaultOpponentStrumY0 - 20)

        setPropertyFromGroup(side, 3, 'angle', -10)
        setPropertyFromGroup(side, 3, 'y', defaultOpponentStrumY0 - 20)
    else
        setPropertyFromGroup(side, 1, 'angle', 10)
        setPropertyFromGroup(side, 1, 'y', defaultOpponentStrumY0 + 40)

        setPropertyFromGroup(side, 2, 'angle', -10)
        setPropertyFromGroup(side, 2, 'y', defaultOpponentStrumY0 + 40)

        setPropertyFromGroup(side, 0, 'angle', -10)
        setPropertyFromGroup(side, 0, 'y', defaultOpponentStrumY0 + 20)

        setPropertyFromGroup(side, 3, 'angle', 10)
        setPropertyFromGroup(side, 3, 'y', defaultOpponentStrumY0 + 20)
    end
    for i = 0, 7 do
        noteTweenAngle('resetAng'..i, i, 0, 0.6, 'bounceOut')
        noteTweenY('resetY'..i, i, defaultOpponentStrumY0, 0.6, 'bounceOut')
    end
end

function onTweenCompleted(name)
    if name == 'camz' then
        setProperty("defaultCamZoom",getProperty('camGame.zoom')) 
    end
end

function onBeatHit()
    if (curBeat >= 96 and curBeat < 120) or (curBeat >= 124 and curBeat < 152)  or (curBeat >= 156 and curBeat < 160) or (curBeat >= 576 and curBeat < 637) or (curBeat >= 640 and curBeat < 702) or (curBeat >= 704 and curBeat < 766) then
        if curBeat % 4 == 0 then
            addCameraZoom(-0.015, -0.03)
        end
        addCameraZoom()
        noteShit('playerStrums')
        noteShit('opponentStrums')
        doStrumAngleAnim = true
        if flashingLights and curStage == "hill" then
            runHaxeCode([[
                var colorSwap;
                colorSwap = new shaders.ColorSwap();
                game.camHUD.setFilters([new ShaderFilter(colorSwap.shader)]);
                game.camGame.setFilters([new ShaderFilter(colorSwap.shader)]);

                var colorSwap2; 
                colorSwap2 = new shaders.ColorSwap();
                game.getLuaObject("back").shader = colorSwap2.shader;
                game.getLuaObject("lightB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;

                colorSwap2.brightness = 0.4;
                game.modchartTweens.set("colorSwapFade", FlxTween.tween(colorSwap2, {brightness: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFade");
                }}));

                colorSwap.hue = 0.025;
                colorSwap.brightness = 0.2;
                colorSwap.saturation = 0.1;
                game.modchartTweens.set("colorSwapFadeHUD", FlxTween.tween(colorSwap, {brightness: 0, saturation: 0, hue: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFadeHUD");
                }}));
            ]])
        end
        if songTimeOffset == 0 then
            songTimeOffset = getSongPosition()
        end
    else
        doStrumAngleAnim = false
    end

    if (curBeat >= 768 and curBeat < 896) then
        if curBeat % 4 == 0 then
            addCameraZoom(0.025, 0.06)
        end
        addCameraZoom()
        noteShit('playerStrums')
        noteShit('opponentStrums')
        if flashingLights and curStage == "hill" then
            runHaxeCode([[
                var colorSwap;
                colorSwap = new shaders.ColorSwap();
                game.camHUD.setFilters([new ShaderFilter(colorSwap.shader)]);
                game.camGame.setFilters([new ShaderFilter(colorSwap.shader)]);

                var colorSwap2; 
                colorSwap2 = new shaders.ColorSwap();
                game.getLuaObject("back").shader = colorSwap2.shader;
                game.getLuaObject("lightB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;

                colorSwap2.brightness = 0.6;
                game.modchartTweens.set("colorSwapFade", FlxTween.tween(colorSwap2, {brightness: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFade");
                }}));

                colorSwap.hue = 0.075;
                colorSwap.brightness = 0.4;
                colorSwap.saturation = 0.2;
                game.modchartTweens.set("colorSwapFadeHUD", FlxTween.tween(colorSwap, {brightness: 0, saturation: 0, hue: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFadeHUD");
                }}));
            ]])
        end
        if songTimeOffset == 0 then
            songTimeOffset = getSongPosition()
        end
    else
        doStrumAngleAnim = false
    end

    if curBeat == 196 then
        --cameraFade("hud", "000000", crochet / 250)
    end

    -- print(curBeat)
end

function onStepHit()
    if curStep == 1 then
        doTweenAlpha('StartA','dark', 0, 10,'linear')
        zoomEvent(0.8, 10)
    end
    if curStep == 230 then
        if flashingLights then
            runHaxeCode([[
                var colorSwap;
                colorSwap = new shaders.ColorSwap();
                game.camHUD.setFilters([new ShaderFilter(colorSwap.shader)]);
                game.camGame.setFilters([new ShaderFilter(colorSwap.shader)]);

                var colorSwap2; 
                colorSwap2 = new shaders.ColorSwap();
                game.getLuaObject("back").shader = colorSwap2.shader;
                game.getLuaObject("lightB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;

                colorSwap.hue = 0.025;
                colorSwap.brightness = 0.2;
                colorSwap.saturation = 0.1;
                game.modchartTweens.set("colorSwapFadeHUD", FlxTween.tween(colorSwap, {brightness: 0, saturation: 0, hue: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFadeHUD");
                }}));
            ]])
        end
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 234 then
        if flashingLights then
            runHaxeCode([[
                var colorSwap;
                colorSwap = new shaders.ColorSwap();
                game.camHUD.setFilters([new ShaderFilter(colorSwap.shader)]);
                game.camGame.setFilters([new ShaderFilter(colorSwap.shader)]);

                var colorSwap2; 
                colorSwap2 = new shaders.ColorSwap();
                game.getLuaObject("back").shader = colorSwap2.shader;
                game.getLuaObject("lightB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;

                colorSwap.hue = 0.025;
                colorSwap.brightness = 0.2;
                colorSwap.saturation = 0.1;
                game.modchartTweens.set("colorSwapFadeHUD", FlxTween.tween(colorSwap, {brightness: 0, saturation: 0, hue: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFadeHUD");
                }}));
            ]])
        end
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 238 then
        if flashingLights then
            runHaxeCode([[
                var colorSwap;
                colorSwap = new shaders.ColorSwap();
                game.camHUD.setFilters([new ShaderFilter(colorSwap.shader)]);
                game.camGame.setFilters([new ShaderFilter(colorSwap.shader)]);

                var colorSwap2; 
                colorSwap2 = new shaders.ColorSwap();
                game.getLuaObject("back").shader = colorSwap2.shader;
                game.getLuaObject("lightB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;

                colorSwap.hue = 0.025;
                colorSwap.brightness = 0.2;
                colorSwap.saturation = 0.1;
                game.modchartTweens.set("colorSwapFadeHUD", FlxTween.tween(colorSwap, {brightness: 0, saturation: 0, hue: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFadeHUD");
                }}));
            ]])
        end
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 358 then
        if flashingLights then
            runHaxeCode([[
                var colorSwap;
                colorSwap = new shaders.ColorSwap();
                game.camHUD.setFilters([new ShaderFilter(colorSwap.shader)]);
                game.camGame.setFilters([new ShaderFilter(colorSwap.shader)]);

                var colorSwap2; 
                colorSwap2 = new shaders.ColorSwap();
                game.getLuaObject("back").shader = colorSwap2.shader;
                game.getLuaObject("lightB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;

                colorSwap.hue = 0.025;
                colorSwap.brightness = 0.2;
                colorSwap.saturation = 0.1;
                game.modchartTweens.set("colorSwapFadeHUD", FlxTween.tween(colorSwap, {brightness: 0, saturation: 0, hue: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFadeHUD");
                }}));
            ]])
        end
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 362 then
        if flashingLights then
            runHaxeCode([[
                var colorSwap;
                colorSwap = new shaders.ColorSwap();
                game.camHUD.setFilters([new ShaderFilter(colorSwap.shader)]);
                game.camGame.setFilters([new ShaderFilter(colorSwap.shader)]);

                var colorSwap2; 
                colorSwap2 = new shaders.ColorSwap();
                game.getLuaObject("back").shader = colorSwap2.shader;
                game.getLuaObject("lightB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;

                colorSwap.hue = 0.025;
                colorSwap.brightness = 0.2;
                colorSwap.saturation = 0.1;
                game.modchartTweens.set("colorSwapFadeHUD", FlxTween.tween(colorSwap, {brightness: 0, saturation: 0, hue: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFadeHUD");
                }}));
            ]])
        end
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 366 then
        if flashingLights then
            runHaxeCode([[
                var colorSwap;
                colorSwap = new shaders.ColorSwap();
                game.camHUD.setFilters([new ShaderFilter(colorSwap.shader)]);
                game.camGame.setFilters([new ShaderFilter(colorSwap.shader)]);

                var colorSwap2; 
                colorSwap2 = new shaders.ColorSwap();
                game.getLuaObject("back").shader = colorSwap2.shader;
                game.getLuaObject("lightB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;
                game.getLuaObject("mainB").shader = colorSwap2.shader;

                colorSwap.hue = 0.025;
                colorSwap.brightness = 0.2;
                colorSwap.saturation = 0.1;
                game.modchartTweens.set("colorSwapFadeHUD", FlxTween.tween(colorSwap, {brightness: 0, saturation: 0, hue: 0}, Conductor.crochet / 1100, {onComplete: twn -> {
                    game.modchartTweens.remove("colorSwapFadeHUD");
                }}));
            ]])
        end
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 375 then
        zoomEvent(0.9, 0.5)
    end
    if curStep == 383 then
        zoomEvent(0.5, 0.5)
        cameraFlashWrap()
    end
    if curStep == 484 then
        zoomEvent(0.6, 0.1)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 486 then
        zoomEvent(0.7, 0.1)
        cameraFlashWrap()
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 490 then
        zoomEvent(0.8, 0.1)
        cameraFlashWrap()
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 494 then
        zoomEvent(0.9, 0.1)
        cameraFlashWrap()
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 498 then
        zoomEvent(0.5, 0.5)
    end
    
    if curStep == 612 then
        zoomEvent(0.6, 0.1)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 614 then
        zoomEvent(0.7, 0.1)
        cameraFlashWrap()
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 618 then
        zoomEvent(0.8, 0.1)
        cameraFlashWrap()
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 622 then
        zoomEvent(0.9, 0.1)
        cameraFlashWrap()
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 626 then
        zoomEvent(0.5, 0.5)
    end
    if curStep == 740 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 742 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 746 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 750 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    
    if curStep == 868 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 870 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 874 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 878 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end

    if curStep == 996 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 998 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1002 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1006 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end

    if curStep == 1124 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1126 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1130 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1134 then
        addCameraZoom(0.05, 0.05)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end

    if curStep == 1144 then
        zoomEvent(0.8, 0.1)
    end
    if curStep == 1151 then
        zoomEvent(0.5, 0.5)
    end

    if curStep == 1254 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1258 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1262 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end

    if curStep == 1382 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1386 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1390 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end

    if curStep == 1400 then
        zoomEvent(0.8, 0.1)
    end
    if curStep == 1407 then
        zoomEvent(0.5, 0.5)
    end

    if curStep == 1510 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1514 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1518 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end

    if curStep == 1638 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1642 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1646 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 1663 then
        cameraFlashWrap()
        zoomEvent(0.6, 0.5)
    end

    if curStep == 1727 then
        zoomEvent(0.7, 0.1)
    end
    if curStep == 1743 then
        zoomEvent(0.8, 0.1)
    end
    if curStep == 1759 then
        zoomEvent(0.9, 0.1)
    end
    if curStep == 1775 then
        zoomEvent(1, 0.1)
    end
    if curStep == 1791 then
        zoomEvent(0.6, 0.5)
    end
    
    if curStep == 1856 then
        zoomEvent(0.7, 0.1)
    end
    if curStep == 1872 then
        zoomEvent(0.8, 0.1)
    end
    if curStep == 1888 then
        zoomEvent(0.9, 0.1)
    end
    if curStep == 1904 then
        zoomEvent(1, 0.1)
    end
    if curStep == 1916 then
        zoomEvent(1.2, 0.1)
    end

    if curStep == 1920 then
        zoomEvent(0.6, 0.5)
    end

    if curStep == 1984 then
        zoomEvent(0.7, 0.1)
    end
    if curStep == 2000 then
        zoomEvent(0.8, 0.1)
    end
    if curStep == 2016 then
        zoomEvent(0.9, 0.1)
    end
    if curStep == 2032 then
        zoomEvent(1, 0.1)
    end
    if curStep == 2048 then
        zoomEvent(0.6, 0.5)
    end
    
    if curStep == 2112 then
        zoomEvent(0.7, 0.1)
    end
    if curStep == 2128 then
        zoomEvent(0.8, 0.1)
    end
    if curStep == 2144 then
        zoomEvent(0.9, 0.1)
    end
    if curStep == 2160 then
        zoomEvent(1, 0.1)
    end
    if curStep == 2176 then
        zoomEvent(0.6, 0.5)
    end

    if curStep == 2236 then --*snaps to make the song faster*
        addCameraZoom(1, 1)
    end

    if curStep == 2368 then
        zoomEvent(0.7, 0.1)
    end
    if curStep == 2384 then
        zoomEvent(0.8, 0.1)
    end
    if curStep == 2400 then
        zoomEvent(0.9, 0.1)
    end
    if curStep == 2416 then
        zoomEvent(1, 0.1)
    end
    if curStep == 2432 then
        zoomEvent(0.6, 0.5)
    end

    if curStep == 2496 then
        zoomEvent(0.7, 0.1)
    end
    if curStep == 2512 then
        zoomEvent(0.8, 0.1)
    end
    if curStep == 2528 then
        zoomEvent(0.9, 0.1)
    end
    if curStep == 2544 then
        zoomEvent(1, 0.1)
    end
    if curStep == 2560 then
        zoomEvent(0.5, 0.5)
        cameraFlashWrap()
    end

    if curStep == 2816 then
        cameraFlashWrap()
    end

    if curStep == 3064 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 3066 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 3068 then
        addCameraZoom(0.09, 0.09)
        noteShit('playerStrums')
        noteShit('opponentStrums')
    end
    if curStep == 3455 then
        zoomEvent(1, 10)
    end

    if curStep == 3584 then
        zoomEvent(0.5, 0.1)
    end

    if curStep == 4416 then
        cameraFade("hud", "000000", crochet / 750)
    end
end

function math.bound(value, min, max)
    return math.max(min, math.min(max, value));
end

function math.lerp(a, b, ratio)
    return a + ratio * (b - a);
end

function onUpdatePost(elapsed)

    if lockCameraTarget and lockCameraTarget ~= "" then
        cameraSetTarget(lockCameraTarget)
    end

    if not inGameOver then
        local mult = math.lerp(0, getProperty("iconP1.angle"), math.bound(1 - (elapsed * 4 * playbackRate), 0, 1))
        setProperty("iconP1.angle", mult)
    
        local mult = math.lerp(0, getProperty("iconP2.angle"), math.bound(1 - (elapsed * 4 * playbackRate), 0, 1))
        setProperty("iconP2.angle", mult)
    end

    if doStrumAngleAnim then
        for i = 0, getProperty("strumLineNotes.length")-1 do
            setPropertyFromGroup("strumLineNotes", i, "angle", math.sin((songTimeOffset - getSongPosition()) / 1000) * 7.5)
        end
    end
end