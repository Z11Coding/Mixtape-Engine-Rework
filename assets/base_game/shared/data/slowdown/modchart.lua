function onCreatePost()
    luaDebugMode = true
    makeLuaSprite("black")
    makeGraphic("black", screenWidth, screenHeight, '000000')
    setObjectCamera('black', 'hud')
    screenCenter("black")
    addLuaSprite('black', true)
    --setProperty('black.alpha', 0)

    makeLuaText('warning', 'WARNING:\nAstria will now try to mess with you!\nKeep in mind that you wont die until you miss at 0 HP!\n\nGOOD LUCK!', 800, 0, 0)
    setTextColor("warning", "FF0000")
    setObjectCamera('warning', 'other')
    setTextSize("warning", 50)
    setTextAlignment("warning", 'center')
    screenCenter("warning")
    addLuaText('warning')
    setProperty('warning.alpha', 0)
    setProperty('defaultCamZoom', 2)
    setProperty('camGame.zoom', 2)
    setValue('drunk', 1, 1)
    loadModchart()
end

function onSongStart()
    doTweenAlpha('reveal', 'black', 0, stepCrochet*0.001*(126*2), 'sineInOut')
    doTweenZoom('camZoom', 'camGame', 1, stepCrochet*0.001*(126*2), 'sineInOut')
end

function onSkipIntro()
    cancelTween('reveal')
    cancelTween('camZoom')
    setProperty('black.alpha', 0)
    setProperty('camGame.zoom', 1)
    setProperty('defaultCamZoom', 1)
end

function onTweenCompleted(tag)
    if tag == 'camZoom' then
        setProperty('defaultCamZoom', getProperty("camGame.zoom"))
    end
end

function onUpdate(elapsed)
    songPos = getSongPosition()
    local currentBeat = (songPos/5000)*(curBpm/60)

    doTweenY('opponentmove', 'dad', 100 - 150*math.sin((currentBeat+12*12)*math.pi/3), 2)
    doTweenX('opponentmove2', 'dad', 100 - 150*math.sin((currentBeat+24*24)*math.pi/4), 2)
    if not (curStep > 2550) then runHaxeCode('game.moveCameraSection();') end
end

function loadModchart()
    --intro = true
    setProperty('camZoomingMult', 0)
    if not middlescroll then
        queueEase(2552, 2560, 'transformX', -315, 'sineInOut', 0)
    end
    queueEase(2552, 2560, 'twirl', 1, 'sineInOut', 0)
    queueEase(2552, 2560, 'bounce', 1, 'sineInOut', 0)
    queueEase(2552, 2560, 'tornado', 2, 'sineInOut', 0)
    queueEase(2552, 2560, 'tornado', 3, 'sineInOut', 1)
    queueEase(2552, 2560, 'drunk', 2, 'sineInOut', 0)
    queueEase(2552, 2560, 'drunkZ', 1, 'sineInOut', 0)
end

function onStepHit()
    if curStep == 240 then
        intro = false
    end
    if curStep == 256 then
        kick1 = true
    end
    if curStep == 495 then
        kick1 = false
    end
    if curStep == 511 then
        bopCam = true
    end
    if curStep == 1024 then
        bopCam = false
        bopCamLiteH = true
    end
    if curStep == 1280 then
        growChant = true
    end
    if curStep == 1536 then
        growChant = false
        cameraFlash('camOther', 'FFFFFF', 1)
        setObjectCamera('black', 'camOther')
        setProperty('black.alpha', 1)
        setValue('drunk', 1, 0)
    end
    if curStep == 1664 then
        doTweenAlpha('reveal', 'black', 0, stepCrochet*0.001*128, 'sineInOut')
        doTweenZoom('camZoom', 'camGame', 1.5, stepCrochet*0.001*128, 'sineInOut')
    end
    if curStep == 2048 then
        cameraFlash('camOther', 'FFFFFF', 1)
        setProperty('black.alpha', 1)
        setValue('drunk', 0, 0)
        doTweenAlpha('warnem', 'warning', 1, stepCrochet*0.001*128, 'sineInOut')
    end
    if curStep == 2176 then
        doTweenZoom('camZoom', 'camGame', 1, stepCrochet*0.001*128, 'sineInOut')
        setValue('drunk', 7, 1)
        doTweenAlpha('reveal', 'black', 0, stepCrochet*0.001*128, 'sineInOut')
        doTweenAlpha('warnem', 'warning', 0, stepCrochet*0.001*128, 'sineInOut')
    end
    if curStep == 2559 then
        setProperty('defaultCamZoom', 0.8)
        noteBounce = true
    end
    if curStep == 2560 then
        setProperty('defaultCamZoom', 0.8)
    end
    if curStep == 2816 then
        cameraFlash('camOther', 'FFFFFF', 1)
        setValue('reverse', 1, 0)
    end
    if curStep == 3040 then
        doTweenAlpha('reveal', 'black', 0.9, stepCrochet*0.001*32, 'linear')
    end
    if curStep == 3072 then
        doTweenAlpha('reveal', 'black', 0, stepCrochet*0.001*128, 'linear')
    end
    if curStep == 3328 then
        cameraFlash('camOther', 'FFFFFF', 1)
        setProperty('black.alpha', 1)
    end

    if intro then
        if curStep % 64 == 0 then
            triggerEvent("Add Camera Zoom", 0, 0.05)
        end
        if curStep % 32 == 6 then
            triggerEvent("Add Camera Zoom", 0, 0.05)
        end
        if curStep % 32 == 29 then
            triggerEvent("Add Camera Zoom", 0, 0.05)
        end
    end
    if kick1 then
        if curStep % 32 == 0 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 32 == 6 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 32 == 10 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 32 == 16 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 32 == 22 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 32 == 26 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
        if curStep % 32 == 30 then
            triggerEvent("Add Camera Zoom", 0.05, 0.05)
        end
    end
    if growChant then
        if curStep % 16 == 8 then
            setValue('scale', 1.5)
            setValue('noteAngle', 360)
            setValue('receptorAngle', 360)
            queueEase(curStep, curStep+4, 'scale', 1, 'quadOut')
            queueEase(curStep, curStep+4, 'noteAngle', 0, 'quadOut')
            queueEase(curStep, curStep+4, 'receptorAngle', 0, 'quadOut')
        end
    end
end

function onBeatHit()
    if bopCam then
        triggerEvent("Add Camera Zoom", 0.05, 0.05)
    end
    if bopCamLite then
        triggerEvent("Add Camera Zoom", 0.02, 0.02)
    end
    if bopCamLiteH then
        if curBeat % 4 == 2 then
            triggerEvent("Add Camera Zoom", 0.02, 0.02)
        end
    end
    if noteBounce then
        if curBeat % 2 == 0 then
            setValue('transformY', -50)
            setValue('noteAngle', 25)
            setValue('receptorAngle', -25)
            queueEase(curStep, curStep+4, 'split', 0, 'quadInOut')
            queueEase(curStep, curStep+4, 'transformY', 0, 'quadInOut')
            queueEase(curStep, curStep+4, 'noteAngle', 0, 'quadInOut')
            queueEase(curStep, curStep+4, 'receptorAngle', 0, 'quadInOut')
        elseif curBeat % 2 == 1 then
            setValue('transformY', -50)
            setValue('noteAngle', -25)
            setValue('receptorAngle', 25)
            queueEase(curStep, curStep+4, 'transformY', 0, 'quadInOut')
            queueEase(curStep, curStep+4, 'noteAngle', 0, 'quadInOut')
            queueEase(curStep, curStep+4, 'receptorAngle', 0, 'quadInOut')
        end
    end
end

function onDestroy()

end