function onCreatePost()
    makeLuaSprite("void")
    makeGraphic("void", screenWidth*2, screenHeight*2, '000000')
    setObjectCamera('void', 'other')
    screenCenter("void")
    addLuaSprite('void', true)
    setProperty('void.alpha', 0)
end

function onStartCountdown()
    setProperty('camZoomingMult', 0)
    setProperty('camHUD.visible', false)
    setProperty('camHUD.alpha', 0)
end

function onCountdownStarted()
    if modcharts then
        queueEase(574, 576, 'boost', 1)
        queueEase(592, 593, 'boost', 0)
    end
end

function onStepHit()
    if curStep == 0 then
        setProperty('void.alpha', 0)
    end
    
    liveStep = curStep

    if curStep == 128 then
        setProperty('camHUD.visible', true)
        doTweenAlpha('bringHUDin', 'camHUD', 1, stepCrochet*0.001*64, 'sineOut')
    end

    if curStep == 254 then
        if cameraZoomOnBeat then screenBop = true end
        if modcharts then basicBop = true end
    end
    if curStep == 512 then
        if modcharts then 
            basicBop = false
            basicBopAlt = true
        end
    end
    if liveStep == 576 or liveStep == 832 or liveStep == 704 or liveStep == 960 then
        if modcharts then basicBopAlt = false end
    end
    if liveStep == 591 or liveStep == 847 or liveStep == 735 or liveStep == 991 then
        if modcharts then basicBopAlt = true end
    end
    if cameraZoomOnBeat then
        if curStep == 832 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
        end
        if curStep == 834 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
        end
        if curStep == 837 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
        end
        if curStep == 840 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
        end
        if curStep == 842 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
        end
        if curStep == 845 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
        end
    end
    if curStep == 1023 then
        if cameraZoomOnBeat then screenBop = false end
        if modcharts then 
            basicBopAlt = false
            setValue('dizzy', 1)
            setValue('wave', 2)
            queueEase(curStep, curStep+3, 'drunk', 1)
        end
    end
    if curStep == 1279 then
        setProperty('defaultCamZoom', getProperty('defaultCamZoom')+0.2)
        if cameraZoomOnBeat then screenBopDouble = true end
        if modcharts then 
            basicBop2 = true
            queueEase(curStep, curStep+3, 'drunk', 0)
            setValue('dizzy', 0)
            setValue('wave', 0)
        end
    end
    if cameraZoomOnBeat then
        if curStep == 1600 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
            setHealth(getHealth()-0.1)
        end
        if curStep == 1603 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
            setHealth(getHealth()-0.1)
        end
        if curStep == 1606 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
            setHealth(getHealth()-0.1)
        end
        if curStep == 1609 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
            setHealth(getHealth()-0.1)
        end
        if curStep == 1612 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
            setHealth(getHealth()-0.1)
        end
        if curStep == 1615 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
            setHealth(getHealth()-0.1)
        end
    end
    if curStep == 1791 then
        if cameraZoomOnBeat then screenBopDouble = false end
        if modcharts then 
            basicBop2 = false
            queueEase(curStep, curStep+3, 'invert', 0, 1)
            queueEase(curStep, curStep+3, 'drunk', 1)
            setValue('boost', 1)
            setValue('beatY', 1)
        end
    end
    if curStep == 2048 then
        if modcharts then 
            setValue('drunk', 0)
            setValue('boost', 0)
            setValue('beatY', 0)
        end
        setProperty('void.alpha', 1)
    end
    if curStep >= 1791 and curStep <= 2048 then
        setProperty('defaultCamZoom', getProperty('defaultCamZoom')+0.002)
        setValue('mini', getValue('mini')+0.002)
    end
end

cur = 0
curOpp = 0
function opponentNoteHit(index, noteDir, noteType, isSustainNote)
    if modcharts then 
        if (liveStep >= 576 and liveStep <= 591) or (liveStep >= 832 and liveStep <= 847) then
            setValue('transform'..noteDir..'X', getRandomInt(-50, 50), 1)
            setValue('transform'..noteDir..'Y', getRandomInt(-50, 50), 1)
            setValue('transform'..noteDir..'Z', getRandomInt(-50, 50), 1)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'X', 0, 1)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'Y', 0, 1)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'Z', 0, 1)
        end
        if liveStep >= 1599 and liveStep <= 1615 then
            curOpp=curOpp+1
            setValue('transform'..noteDir..'X', getRandomInt(-50, 50), 1)
            setValue('transform'..noteDir..'Y', getRandomInt(-50, 50), 1)
            setValue('transform'..noteDir..'Z', getRandomInt(-50, 50), 1)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'X', 0, 1)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'Y', 0, 1)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'Z', 0, 1)
            setValue('invert', (curOpp % 4)/2, 1)
        end
    end
end

function goodNoteHit(index, noteDir, noteType, isSustainNote)
    if modcharts then
        if (liveStep >= 704 and liveStep <= 735) or (liveStep >= 960 and liveStep <= 991) then
            setValue('transform'..noteDir..'X', getRandomInt(-50, 50), 0)
            setValue('transform'..noteDir..'Y', getRandomInt(-50, 50), 0)
            setValue('transform'..noteDir..'Z', getRandomInt(-50, 50), 0)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'X', 0, 0)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'Y', 0, 0)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'Z', 0, 0)
        end
        if liveStep >= 1727 and liveStep <= 1759 then
            setValue('transform'..noteDir..'X', getRandomInt(-100, 100), 0)
            setValue('transform'..noteDir..'Y', getRandomInt(-100, 100), 0)
            setValue('transform'..noteDir..'Z', getRandomInt(-100, 100), 0)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'X', 0, 0)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'Y', 0, 0)
            queueEase(liveStep, liveStep+2, 'transform'..noteDir..'Z', 0, 0)
        end
    end
end

function onModifierRegisterPost()
    addBlankMod('gameAngle', 0)
    addBlankMod('hudAngle', 0)
end

function onUpdate(elapsed)
    setProperty('camGame.angle', getValue('gameAngle'))
    setProperty('camHUD.angle', getValue('hudAngle'))
    if keyboardJustPressed('SPACE') then
        setProperty("camHUD.visible", true)
        setProperty("camHUD.alpha", 1)
    end
end

function onBeatHit()
    if screenBop then
        if curBeat % 2 == 0 then
            setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
            setProperty('camHUD.zoom', getProperty('camHUD.zoom')+0.1)
        end
    end
    if screenBopDouble then
        setProperty('camGame.zoom', getProperty('camGame.zoom')+0.2)
        setProperty('camHUD.zoom', getProperty('camHUD.zoom')+0.1)
    end
    if basicBop then
        if curBeat % 4 == 0 then
            setValue('fieldYaw', 25)
            queueEase(curStep, curStep+6, "fieldYaw", 0, "sineInOut")

            setValue('drunk', 2)
            queueEase(curStep, curStep+6, "drunk", 0, "sineInOut")

            setValue('0rotateX', 5)
            setValue('2rotateX', 5)
            setValue('1rotateX', -5)
            setValue('3rotateX', -5)
            queueEase(curStep, curStep+6, "0rotateX", 0, "sineInOut")
            queueEase(curStep, curStep+6, "2rotateX", 0, "sineInOut")
            queueEase(curStep, curStep+6, "1rotateX", 0, "sineInOut")
            queueEase(curStep, curStep+6, "3rotateX", 0, "sineInOut")

            setValue('0rotateZ', 5)
            setValue('2rotateZ', 5)
            setValue('1rotateZ', -5)
            setValue('3rotateZ', -5)
            queueEase(curStep, curStep+6, "0rotateZ", 0, "sineInOut")
            queueEase(curStep, curStep+6, "2rotateZ", 0, "sineInOut")
            queueEase(curStep, curStep+6, "1rotateZ", 0, "sineInOut")
            queueEase(curStep, curStep+6, "3rotateZ", 0, "sineInOut")

            setValue('0rotateY', 5)
            setValue('2rotateY', 5)
            setValue('1rotateY', -5)
            setValue('3rotateY', -5)
            queueEase(curStep, curStep+6, "0rotateY", 0, "sineInOut")
            queueEase(curStep, curStep+6, "2rotateY", 0, "sineInOut")
            queueEase(curStep, curStep+6, "1rotateY", 0, "sineInOut")
            queueEase(curStep, curStep+6, "3rotateY", 0, "sineInOut")
        end
        if curBeat % 4 == 2 then
            setValue('fieldYaw', -25)
            queueEase(curStep, curStep+6, "fieldYaw", 0, "sineInOut")

            setValue('drunk', -2)
            queueEase(curStep, curStep+6, "drunk", 0, "sineInOut")

            setValue('0rotateX', -5)
            setValue('2rotateX', -5)
            setValue('1rotateX', 5)
            setValue('3rotateX', 5)
            queueEase(curStep, curStep+6, "0rotateX", 0, "sineInOut")
            queueEase(curStep, curStep+6, "2rotateX", 0, "sineInOut")
            queueEase(curStep, curStep+6, "1rotateX", 0, "sineInOut")
            queueEase(curStep, curStep+6, "3rotateX", 0, "sineInOut")
            
            setValue('0rotateZ', -5)
            setValue('2rotateZ', -5)
            setValue('1rotateZ', 5)
            setValue('3rotateZ', 5)
            queueEase(curStep, curStep+6, "0rotateZ", 0, "sineInOut")
            queueEase(curStep, curStep+6, "2rotateZ", 0, "sineInOut")
            queueEase(curStep, curStep+6, "1rotateZ", 0, "sineInOut")
            queueEase(curStep, curStep+6, "3rotateZ", 0, "sineInOut")

            setValue('0rotateY', -5)
            setValue('2rotateY', -5)
            setValue('1rotateY', 5)
            setValue('3rotateY', 5)
            queueEase(curStep, curStep+6, "0rotateY", 0, "sineInOut")
            queueEase(curStep, curStep+6, "2rotateY", 0, "sineInOut")
            queueEase(curStep, curStep+6, "1rotateY", 0, "sineInOut")
            queueEase(curStep, curStep+6, "3rotateY", 0, "sineInOut")
        end
    end
    if basicBop2 then
        if curBeat % 2 == 0 then
            setValue('fieldYaw', 25)
            queueEase(curStep, curStep+3, "fieldYaw", 0, "sineInOut")

            setValue('drunk', 2)
            queueEase(curStep, curStep+3, "drunk", 0, "sineInOut")

            setValue('0rotateX', 5)
            setValue('2rotateX', 5)
            setValue('1rotateX', -5)
            setValue('3rotateX', -5)
            queueEase(curStep, curStep+3, "0rotateX", 0, "sineInOut")
            queueEase(curStep, curStep+3, "2rotateX", 0, "sineInOut")
            queueEase(curStep, curStep+3, "1rotateX", 0, "sineInOut")
            queueEase(curStep, curStep+3, "3rotateX", 0, "sineInOut")

            setValue('0rotateZ', 5)
            setValue('2rotateZ', 5)
            setValue('1rotateZ', -5)
            setValue('3rotateZ', -5)
            queueEase(curStep, curStep+3, "0rotateZ", 0, "sineInOut")
            queueEase(curStep, curStep+3, "2rotateZ", 0, "sineInOut")
            queueEase(curStep, curStep+3, "1rotateZ", 0, "sineInOut")
            queueEase(curStep, curStep+3, "3rotateZ", 0, "sineInOut")

            setValue('0rotateY', 5)
            setValue('2rotateY', 5)
            setValue('1rotateY', -5)
            setValue('3rotateY', -5)
            queueEase(curStep, curStep+3, "0rotateY", 0, "sineInOut")
            queueEase(curStep, curStep+3, "2rotateY", 0, "sineInOut")
            queueEase(curStep, curStep+3, "1rotateY", 0, "sineInOut")
            queueEase(curStep, curStep+3, "3rotateY", 0, "sineInOut")
        end
        if curBeat % 2 == 1 then
            setValue('fieldYaw', -25)
            queueEase(curStep, curStep+3, "fieldYaw", 0, "cubeOut")

            setValue('drunk', -2)
            queueEase(curStep, curStep+3, "drunk", 0, "cubeOut")

            setValue('0rotateX', -5)
            setValue('2rotateX', -5)
            setValue('1rotateX', 5)
            setValue('3rotateX', 5)
            queueEase(curStep, curStep+3, "0rotateX", 0, "cubeOut")
            queueEase(curStep, curStep+3, "2rotateX", 0, "cubeOut")
            queueEase(curStep, curStep+3, "1rotateX", 0, "cubeOut")
            queueEase(curStep, curStep+3, "3rotateX", 0, "cubeOut")
            
            setValue('0rotateZ', -5)
            setValue('2rotateZ', -5)
            setValue('1rotateZ', 5)
            setValue('3rotateZ', 5)
            queueEase(curStep, curStep+3, "0rotateZ", 0, "cubeOut")
            queueEase(curStep, curStep+3, "2rotateZ", 0, "cubeOut")
            queueEase(curStep, curStep+3, "1rotateZ", 0, "cubeOut")
            queueEase(curStep, curStep+3, "3rotateZ", 0, "cubeOut")

            setValue('0rotateY', -5)
            setValue('2rotateY', -5)
            setValue('1rotateY', 5)
            setValue('3rotateY', 5)
            queueEase(curStep, curStep+3, "0rotateY", 0, "cubeOut")
            queueEase(curStep, curStep+3, "2rotateY", 0, "cubeOut")
            queueEase(curStep, curStep+3, "1rotateY", 0, "cubeOut")
            queueEase(curStep, curStep+3, "3rotateY", 0, "cubeOut")
        end
    end
    if basicBopAlt then
        if curBeat % 4 == 0 then
            setValue('transform0Y', 25)
            setValue('transform2Y', 25)
            setValue('transform1Y', -25)
            setValue('transform3Y', -25)
            queueEase(curStep, curStep+6, "transform0Y", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform2Y", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform1Y", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform3Y", 0, "sineInOut")

            setValue('transform0Z', 25)
            setValue('transform2Z', 25)
            setValue('transform1Z', -25)
            setValue('transform3Z', -25)
            queueEase(curStep, curStep+6, "transform0Z", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform2Z", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform1Z", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform3Z", 0, "sineInOut")
        end
        if curBeat % 4 == 2 then
            setValue('transform0Y', -25)
            setValue('transform2Y', -25)
            setValue('transform1Y', 25)
            setValue('transform3Y', 25)
            queueEase(curStep, curStep+6, "transform0Y", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform2Y", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform1Y", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform3Y", 0, "sineInOut")

            setValue('transform0Z', -25)
            setValue('transform2Z', -25)
            setValue('transform1Z', 25)
            setValue('transform3Z', 25)
            queueEase(curStep, curStep+6, "transform0Z", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform2Z", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform1Z", 0, "sineInOut")
            queueEase(curStep, curStep+6, "transform3Z", 0, "sineInOut")
        end
    end
end