function onModifierRegisterPost()
    queueEase(1948, 1952, 'opponentSwap', 0.5, 'sineInOut')
    queueEase(2432, 2464, 'opponentSwap', 0, 'sineInOut')
    queueEase(2432, 2464, 'tipsy', 1, 'sineInOut')
    queueSet(2976, 'tipsy', 1)
end

function onStepHit()
    if bounce then
        if curStep % 8 == 0 then
            setValue('noteAngle', 25)
            setValue('receptorAngle', 25)
            setValue('transformY', -50)
            setValue('transformX', 25)
            queueEase(curStep, curStep+3, 'noteAngle', 0, 'circOut')
            queueEase(curStep, curStep+3, 'receptorAngle', 0, 'circOut')
            queueEase(curStep, curStep+3, 'transformY', 0, 'circOut')
            queueEase(curStep, curStep+3, 'transformX', 0, 'circOut')
        elseif curStep % 8 == 4 then
            setValue('noteAngle', -25)
            setValue('receptorAngle', -25)
            setValue('transformY', -50)
            setValue('transformX', -25)
            queueEase(curStep, curStep+3, 'noteAngle', 0, 'circOut')
            queueEase(curStep, curStep+3, 'receptorAngle', 0, 'circOut')
            queueEase(curStep, curStep+3, 'transformY', 0, 'circOut')
            queueEase(curStep, curStep+3, 'transformX', 0, 'circOut')
        end
    end
    if curStep == 1952 then
        bounce = true
        setProperty('defaultCamZoom', 1)
        triggerEvent("Camera Follow Pos", 1800, 1200)
    end
    if curStep == 2432 then
        doTweenZoom("moveBackZoom", "camGame", 0.25, stepCrochet*0.001*32, "sineInOut")
        setProperty('defaultCamZoom', 0.25)
        triggerEvent("Camera Follow Pos")
    end
    if curStep == 2432 then
        bounce = false
    end
end