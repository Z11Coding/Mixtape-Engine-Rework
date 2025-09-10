function loadModchart()
    if getPropertyFromClass('backend.ClientPrefs', 'data.modcharts') then
        queueEase(1311, 1316, 'reverse', 1, 'expoInOut', 1, 0)
        queueEase(1375, 1380, 'reverse', 1, 'expoInOut', 0, 0)
        queueSetP(1407, 'drunk', 75, -1)
        queueEase(1440, 1444, 'reverse', 0, 'expoInOut', 1, 1)
        queueEase(1504, 1508, 'reverse', 0, 'expoInOut', 0, 1)
    end
end


function onStepHit()
    if getPropertyFromClass('backend.ClientPrefs', 'data.modcharts') then
        if curStep == 1 then
            setValue('boost', 1, -1)
        end
        if curStep == 256 then
            setValue('boost', 0, -1)
            setValue('brake', 1, -1)
        end
        if curStep == 512 then
            setValue('boost', 0, -1)
            setValue('beat', 0.5, -1)
        end
        if curStep == 640 then
            setValue('beat', 0, -1)
            setValue('drunk', 1, -1)
            setValue('tipZ', 1, -1)
        end
        if curStep == 768 then
            setValue('drunk', 0, -1)
            setValue('tipZ', 0, -1)
        end
        if curStep == 803 then
            setValue('invert', 1, -1)
        end
        if curStep == 812 then
            setValue('invert', 0, -1)
        end
        if curStep == 867 then
            setValue('invert', 1, -1)
        end
        if curStep == 876 then
            setValue('invert', 0, -1)
        end
        if curStep == 900 then
            setValue('boost', 1, -1)
        end
        if curStep == 904 then
            setValue('boost', 0, -1)
        end
        if curStep == 908 then
            setValue('boost', 1, -1)
        end
        if curStep == 912 then
            setValue('boost', 0, -1)
        end
        if curStep == 920 then
            setValue('boost', 1, -1)
        end
        if curStep == 926 then
            setValue('boost', 0, -1)
        end
        if curStep == 932 then
            setValue('boost', -2, -1)
        end
        if curStep == 936 then
            setValue('boost', 0, -1)
        end
        if curStep == 940 then
            setProperty('freezeNotes', true)
        end
        if curStep == 944 then
            setProperty('freezeNotes', false)
        end
        if curStep == 964 then
            setProperty('freezeNotes', true)
        end
        if curStep == 968 then
            setProperty('freezeNotes', false)
        end
        if curStep == 971 then
            setValue('boost', 1, -1)
        end
        if curStep == 976 then
            setValue('boost', 0, -1)
        end
        if curStep == 984 then
            setValue('boost', 1, -1)
        end
        if curStep == 990 then
            setValue('boost', 0, -1)
        end
        if curStep == 996 then
            setProperty('freezeNotes', true)
        end
        if curStep == 1000 then
            setProperty('freezeNotes', false)
        end
        if curStep == 1004 then
            setProperty('freezeNotes', true)
        end
        if curStep == 1007 then
            setProperty('freezeNotes', false)
        end
        if curStep == 1028 then
            setValue('beat', 0.1, 0)
        end
        if curStep == 1032 then
            setValue('beat', 0, 0)
        end
        if curStep == 1036 then
            setValue('beat', 0.1, 0)
        end
        if curStep == 1038 then
            setValue('beat', 0, 0)
        end
        if curStep == 1060 then
            setProperty('freezeNotes', true)
        end
        if curStep == 1064 then
            setProperty('freezeNotes', false)
        end
        if curStep == 1068 then
            setProperty('freezeNotes', true)
        end
        if curStep == 1072 then
            setProperty('freezeNotes', false)
        end
        if curStep == 1092 then
            setValue('beat', 0.1, 0)
        end
        if curStep == 1096 then
            setValue('beat', 0, 0)
        end
        if curStep == 1100 then
            setValue('beat', 0.1, 0)
        end
        if curStep == 1104 then
            setValue('beat', 0, 0)
        end
        if curStep == 1124 then
            setProperty('freezeNotes', true)
        end
        if curStep == 1128 then
            setProperty('freezeNotes', false)
        end
        if curStep == 1132 then
            setProperty('freezeNotes', true)
        end
        if curStep == 1136 then
            setProperty('freezeNotes', false)
        end
        if curStep == 1279 then
            setValue('brake', 0, -1)
        end
        if curStep == 1536 then
            setValue('drunk', 0, -1)
            speen = true
        end
        if curStep == 1791 then
            speen = false
            speen2 = true
        end
        if curStep == 2048 then
            setValue('drunkZ', 1, -1)
            setPercent('tornado', 0.5, -1)
        end
        if curStep == 2296 then
            speen2 = false
            setValue('boost', 1, -1)
            setValue('localrotateY', 0, -1)
        end
        if curStep == 2944 then
            setPercent('tornado', 0, -1)
        end
        if curStep == 3072 then
            setValue('drunkZ', 0, -1)
        end
        if curStep >= 1791 and curStep <= 2304 then
            if mustHitSection then
                setValue('receptorScroll', 0, 1)
                setValue('receptorScroll', 1, 0)
            else
                setValue('receptorScroll', 0, 0)
                setValue('receptorScroll', 1, 1)
            end
        else
            setValue('receptorScroll', 0, -1)
        end
    end
end

function onUpdate()
    setProperty('gfGroup.alpha', 0)
    if speen then
        setValue('localrotateY', getValue('localrotateY', whospeen) + 0.5, whospeen)
    end
    if speen2 then
        setValue('localrotateY', getValue('localrotateY', 0) + 0.5, -1)
    end

    if mustHitSection then whospeen = 1 else whospeen = 0 end
end
