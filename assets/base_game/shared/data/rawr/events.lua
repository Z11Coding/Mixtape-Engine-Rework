introCam = true
buildupCam = false
function onCreatePost()
    makeLuaSprite("blank", nil, 0, 0)
    makeGraphic("blank", screenWidth*2, screenHeight*2, '000000')
    screenCenter("blank", 'xy')
    setObjectCamera("blank", "other")
    addLuaSprite("blank", false)
end

function onSongStart()
    if curStep <= 1 then
        doTweenAlpha("reveal", "blank", 0, stepCrochet*0.001*264, "sineInOut")
        switchCamBop("introCam")
    else
        setProperty("blank.alpha", 0)
    end
    triggerEvent("Edit Shadow", 'dad', 'false')
    triggerEvent("Edit Shadow", 'boyfriend', 'false')
    triggerEvent("Edit Shadow Duration", 'dad', '1')
    triggerEvent("Edit Shadow Duration", 'boyfriend', '1')
    triggerEvent("Edit Shadow Range", 'dad', '0.1')
    triggerEvent("Edit Shadow Range", 'boyfriend', '0.1')
    triggerEvent("Edit Shadow HexColor", 'dad', rgbToHex(getProperty("dad.healthColorArray")))
    triggerEvent("Edit Shadow HexColor", 'boyfriend', rgbToHex(getProperty("boyfriend.healthColorArray")))
end

function switchCamBop(setBop)
    function updateBopS(daStep)
        if setBop == "introCam" then
            if daStep % 64 == 0 then
                triggerEvent("Add Camera Zoom", 0.01, 0.01)
            end
            if daStep % 64 == 6 then
                triggerEvent("Add Camera Zoom", 0.01, 0.01)
            end
            if daStep % 64 == 16 then
                triggerEvent("Add Camera Zoom", 0.01, 0.01)
            end
            if daStep % 64 == 22 then
                triggerEvent("Add Camera Zoom", 0.01, 0.01)
            end
            if daStep % 64 == 32 then
                triggerEvent("Add Camera Zoom", 0.01, 0.01)
            end
            if daStep % 64 == 38 then
                triggerEvent("Add Camera Zoom", 0.01, 0.01)
            end
            if daStep % 64 == 48 then
                triggerEvent("Add Camera Zoom", 0.01, 0.01)
            end
            if daStep % 64 == 54 then
                triggerEvent("Add Camera Zoom", 0.01, 0.01)
            end
            if daStep % 64 == 60 then
                triggerEvent("Add Camera Zoom", 0.01, 0.01)
            end
        end

        if setBop == "buildupCam" then
            if daStep % 64 == 0 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 6 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 16 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 22 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 32 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 38 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 48 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 54 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 60 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 62 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
        end

        if setBop == "buildupCamalt" then
            if daStep % 64 == 0 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
                setProperty("camGame.angle", 5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
            end
            if daStep % 64 == 6 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
                setProperty("camGame.angle", -5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
            end
            if daStep % 64 == 16 then
                setProperty("camGame.angle", 5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 22 then
                setProperty("camGame.angle", -5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 32 then
                setProperty("camGame.angle", 5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 38 then
                setProperty("camGame.angle", -5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 48 then
                setProperty("camGame.angle", 5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 54 then
                setProperty("camGame.angle", -5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 60 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
        end

        if setBop == "buildupCamalt2" then
            if daStep % 32 == 0 then
                setProperty("camGame.angle", 5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.08, 0.06)
            end
            if daStep % 32 == 6 then
                setProperty("camGame.angle", -5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.08, 0.06)
            end
            if daStep % 32 == 16 then
                setProperty("camGame.angle", 5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.08, 0.06)
            end
            if daStep % 32 == 22 then
                setProperty("camGame.angle", -5)
                doTweenAngle('ang', "camGame", 0, stepCrochet*0.001*4, "sineInOut")
                triggerEvent("Add Camera Zoom", 0.08, 0.06)
            end
            if daStep % 32 == 28 then
                triggerEvent("Add Camera Zoom", 0.08, 0.06)
            end
            if daStep % 32 == 30 then
                triggerEvent("Add Camera Zoom", 0.08, 0.06)
            end
        end

        if setBop == "buildupCamSimple" then
            if daStep % 64 == 0 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 7 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 16 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 23 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 32 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 39 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 48 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
            if daStep % 64 == 55 then
                triggerEvent("Add Camera Zoom", 0.05, 0.03)
            end
        end

        if setBop == "buildupCamSimple+" then
            if daStep % 64 == 0 then
                triggerEvent("Add Camera Zoom", 0.1, 0.09)
            end
            if daStep % 64 == 7 then
                triggerEvent("Add Camera Zoom", 0.1, 0.09)
            end
            if daStep % 64 == 16 then
                triggerEvent("Add Camera Zoom", 0.1, 0.09)
            end
            if daStep % 64 == 23 then
                triggerEvent("Add Camera Zoom", 0.1, 0.09)
            end
            if daStep % 64 == 32 then
                triggerEvent("Add Camera Zoom", 0.1, 0.09)
            end
            if daStep % 64 == 39 then
                triggerEvent("Add Camera Zoom", 0.1, 0.09)
            end
            if daStep % 64 == 48 then
                triggerEvent("Add Camera Zoom", 0.1, 0.09)
            end
            if daStep % 64 == 55 then
                triggerEvent("Add Camera Zoom", 0.1, 0.09)
            end
        end
    end

    function updateBopB(daBeat)
        if setBop == "basicBop1" then
            triggerEvent("Add Camera Zoom", 0.08, 0.06)
        end
        if setBop == "semiBasicBop1" then
            triggerEvent("Add Camera Zoom", 0.2, 0.1)
        end
    end

end

function onStepHit()
    --GLOBAL EVENTS
    if curStep == 256 then
        cameraFlash('other', 'ffffff', 1)
        switchCamBop("buildupCam")
    end
    if curStep == 768 then
        switchCamBop("basicBop1")
    end
    if curStep == 1263 then
        switchCamBop("")
        setVar("enableLockInCam", false)
    end
    if curStep == 1264 then
        setProperty("camGame.zoom", getProperty("camGame.zoom")+0.3)
        setProperty("defaultCamZoom", getProperty("defaultCamZoom")+0.3)
    end
    if curStep == 1270 then
        setProperty("camGame.zoom", getProperty("camGame.zoom")+0.3)
        setProperty("defaultCamZoom", getProperty("defaultCamZoom")+0.3)
        setProperty("camGame.angle", -15)
    end
    if curStep == 1276 then
        setProperty("camGame.zoom", getProperty("camGame.zoom")+0.3)
        setProperty("defaultCamZoom", getProperty("defaultCamZoom")+0.3)
        setProperty("camGame.angle", 15)
    end
    if curStep == 1280 then
        setProperty("defaultCamZoom", 0.7)
        doTweenZoom('zoom', "camGame", getProperty("camGame.zoom")-0.6, stepCrochet*0.001*28, "sineInOut")
        doTweenAngle('left', "camGame", 0, stepCrochet*0.001*28, "sineInOut")
    end
    if curStep == 1312 then
        switchCamBop("buildupCamalt")
        setVar("enableLockInCam", true)
        cameraFlash('other', 'ffffff', 1)
    end
    if curStep == 1824 then
        switchCamBop("buildupCamalt2")
    end
    if curStep == 2063 then
        switchCamBop("")
    end
    if curStep == 2072 then
        triggerEvent("Add Camera Zoom", 0.5, 0.5)
    end
    if curStep == 2079 then
        switchCamBop("semiBasicBop1")
    end
    if curStep == 2143 then
        switchCamBop("buildupCamalt2")
    end
    if curStep == 2207 then
        switchCamBop("semiBasicBop1")
    end
    if curStep == 2271 then
        switchCamBop("buildupCamalt2")
    end
    if curStep == 2319 then
        switchCamBop("")
    end
    if curStep == 2332 then
        triggerEvent("Add Camera Zoom", -0.2, -0.2)
    end
    if curStep == 2336 then
        switchCamBop("buildupCamSimple")
    end
    if curStep == 2336 then
        switchCamBop("buildupCamSimple+")
    end
    if curStep == 2784 then
        doTweenAlpha("reveal", "blank", 1, stepCrochet*0.001*64, "sineInOut")
        doTweenAlpha("revealH", "camHUD", 0, stepCrochet*0.001*64, "sineInOut")
    end
    if curStep == 2832 then
        switchCamBop("")
    end
    if curStep == 2848 then
        switchCamBop("buildupCam")
        doTweenAlpha("reveal", "blank", 0, stepCrochet*0.001*264, "sineInOut")
    end
    if curStep == 3087 then
        switchCamBop("")
    end
    if curStep == 3088 then
        triggerEvent("Add Camera Zoom", 0.1, 0.1)
        doTweenAlpha("revealH", "camHUD", 1, stepCrochet*0.001*16, "sineInOut")
    end
    if curStep == 3096 then
        triggerEvent("Add Camera Zoom", 0.1, 0.1)
    end
    if curStep == 3104 then
        switchCamBop("basicBop1")
    end
    if curStep == 3343 then
        switchCamBop("")
    end
    if curStep == 3344 then
        setProperty("camGame.zoom", getProperty("camGame.zoom")+0.3)
        setProperty("defaultCamZoom", getProperty("defaultCamZoom")+0.3)
        setProperty("camGame.angle", 15)
    end
    if curStep == 3350 then
        setProperty("camGame.zoom", getProperty("camGame.zoom")+0.3)
        setProperty("defaultCamZoom", getProperty("defaultCamZoom")+0.3)
        setProperty("camGame.angle", -15)
    end
    if curStep == 3356 then
        setProperty("camGame.zoom", getProperty("camGame.zoom")+0.3)
        setProperty("defaultCamZoom", getProperty("defaultCamZoom")+0.3)
        setProperty("camGame.angle", 15)
    end
    if curStep == 3360 then
        setProperty("defaultCamZoom", 0.7)
        doTweenZoom('zoom', "camGame", getProperty("camGame.zoom")-0.6, stepCrochet*0.001*2, "sineInOut")
        doTweenAngle('left', "camGame", 0, stepCrochet*0.001*2, "sineInOut")
        switchCamBop("semiBasicBop1")
    end
    if curStep == 3599 then
        switchCamBop("")
    end
    if curStep == 3600 then
        triggerEvent("Add Camera Zoom", 0.1, 0.1)
    end
    if curStep == 3608 then
        triggerEvent("Add Camera Zoom", 0.1, 0.1)
    end
    if curStep == 3615 then
        switchCamBop("semiBasicBop1")
    end
    if curStep == 3855 then
        switchCamBop("")
    end
    if curStep == 3856 then
        setProperty("camGame.zoom", getProperty("camGame.zoom")+0.3)
        setProperty("defaultCamZoom", getProperty("defaultCamZoom")+0.3)
        setProperty("camGame.angle", 15)
    end
    if curStep == 3862 then
        setProperty("camGame.zoom", getProperty("camGame.zoom")+0.3)
        setProperty("defaultCamZoom", getProperty("defaultCamZoom")+0.3)
        setProperty("camGame.angle", -15)
    end
    if curStep == 3868 then
        setProperty("camGame.zoom", getProperty("camGame.zoom")+0.3)
        setProperty("defaultCamZoom", getProperty("defaultCamZoom")+0.3)
        setProperty("camGame.angle", 15)
        setProperty("defaultCamZoom", 0.7)
        doTweenZoom('zoom', "camGame", getProperty("camGame.zoom")-0.6, stepCrochet*0.001*2, "sineInOut")
        doTweenAngle('left', "camGame", 0, stepCrochet*0.001*2, "sineInOut")
        switchCamBop("buildupCamSimple+")
    end
    if curStep == 4375 then
        switchCamBop("")
    end
    if curStep == 4380 then
        triggerEvent("Add Camera Zoom", 0.1, 0.1)
    end
    if curStep == 4382 then
        triggerEvent("Add Camera Zoom", 0.1, 0.1)
        switchCamBop("buildupCam")
    end
    if curStep == 4639 then
        switchCamBop("")
    end
    if curStep == 4896 then
        setProperty('blank.alpha', 1)
    end
    if curStep == 512 then
        triggerEvent("Edit Shadow", 'boyfriend', 'true')
    end
    if curStep == 640 then
        triggerEvent("Edit Shadow", 'boyfriend', 'false')
        triggerEvent("Edit Shadow", 'dad', 'true')
    end
    if curStep == 768 then
        triggerEvent("Edit Shadow", 'dad', 'false')
    end
    if curStep == 1824 then
        triggerEvent("Edit Shadow", 'boyfriend', 'true')
    end
    if curStep == 1952 then
        triggerEvent("Edit Shadow", 'boyfriend', 'false')
        triggerEvent("Edit Shadow", 'dad', 'true')
    end
    if curStep == 2080 then
        triggerEvent("Edit Shadow", 'dad', 'false')
        triggerEvent("Edit Shadow", 'boyfriend', 'true')
    end
    if curStep == 2208 then
        triggerEvent("Edit Shadow", 'boyfriend', 'false')
        triggerEvent("Edit Shadow", 'dad', 'true')
    end
    if curStep == 2336 then
        triggerEvent("Edit Shadow", 'boyfriend', 'false')
        triggerEvent("Edit Shadow", 'dad', 'false')
    end
    if curStep == 2592 then
        triggerEvent("Edit Shadow", 'dad', 'false')
        triggerEvent("Edit Shadow", 'boyfriend', 'true')
    end
    if curStep == 2720 then
        triggerEvent("Edit Shadow", 'boyfriend', 'false')
        triggerEvent("Edit Shadow", 'dad', 'true')
    end
    if curStep == 2832 then
        triggerEvent("Edit Shadow", 'boyfriend', 'false')
        triggerEvent("Edit Shadow", 'dad', 'false')
    end
    if curStep == 3104 then
        triggerEvent("Edit Shadow", 'boyfriend', 'true')
        triggerEvent("Edit Shadow", 'dad', 'true')
    end
    if curStep == 4304 then
        triggerEvent("Edit Shadow", 'boyfriend', 'false')
        triggerEvent("Edit Shadow", 'dad', 'false')
    end
    updateBopS(curStep)
end

function onBeatHit()
    updateBopB(curBeat)
end

function getIconColor(chr)
	if trail == true then
		return getColorFromHex(rgbToHex(getProperty(chr .. ".healthColorArray")))
	end
end

function rgbToHex(array)
	if trail == true then
		return string.format('%.2x%.2x%.2x', math.min(array[1]+50,255), math.min(array[2]+50,255), math.min(array[3]+50,255))
	end
end