
local dialogueCount = 0
local inBoyfriendScene = false

local hideHudElem = {
    "iconP1",
    "iconP2",
    "healthBar",
    "scoreTxt",
    "strumLineNotes"
}

function onCreatePost()
    luaDebugMode = true
    if not seenCutscene then
        for k, v in pairs(hideHudElem) do
            if getProperty(v..".length") == nil or getProperty(v..".length") == v..".length" then
                setProperty(v..".alpha", 0)
            else
                for i = 0, getProperty(v..".length")-1 do
                    setProperty(v..".members["..i.."].alpha", 0)
                end
            end
        end
    end
end

function onStartCountdown()

    -- luaDebugMode = true

    if dialogueCount < 2 and not seenCutscene then
        dialogueCount = dialogueCount + 1
        if dialogueCount == 1 then
            makeLuaSprite("d_blackbg", "")
            --addLuaSprite("d_blackbg", true)
            setObjectCamera("d_blackbg", "hud")
            makeGraphic("d_blackbg", screenWidth, screenHeight, "000000")
            runTimer("dialogueDelay", 0.5)
        elseif dialogueCount == 2 then
            setProperty('boyfriend.alpha', 0)
            doTweenAlpha("d_blackbgA", "d_blackbg", 0, 2)
            inBoyfriendScene = true
            runTimer("boyfriendSpeaks", 0.1)
        end
        return Function_Stop
    end

    dialogueCount = 3

    setProperty("d_blackbg.visible", false)
    removeLuaSprite("d_blackbg")

    return Function_Continue
end

function onCountdownStarted()
    for k, v in pairs(hideHudElem) do
        if getProperty(v..".length") == nil or getProperty(v..".length") == v..".length" then
            setProperty(v..".alpha", 0)
            doTweenAlpha("hudShows_"..v, v, 1, crochet / 1000 / playbackRate)
        else
            for i = 0, getProperty(v..".length")-1 do
                setProperty(v.."["..i.."]".."alpha", 0)
                if v == "strumLineNotes" and middlescroll and i < 4 then
                    doTweenAlpha("hudShowGroups_"..v..i, v..".members["..i.."]", 0.35, crochet / 1000 / playbackRate)
                else
                    doTweenAlpha("hudShowGroups_"..v..i, v..".members["..i.."]", ((v == "ratingsTxt" and i == 0) and 0.5 or 1), crochet / 1000 / playbackRate)
                end
            end
        end
    end
end

function onTimerCompleted(t, l, ll)
    if t == "dialogueDelay" then
        startDialogue("dialogue-pt1", "wind_noise")
        for i = 0, getProperty("psychDialogue.arrayCharacters.length")-1 do
            setPropertyFromGroup("psychDialogue.arrayCharacters", i, "visible", false)
        end
    end

    if t == "waitForItDial1" then
        inBoyfriendScene = false
        doTweenZoom("zoomOutCamera", "camGame", getProperty("defaultCamZoom"), 1, "cubeOut")
        startDialogue("dialogue-pt2", "pauseMusic/breakfast-(pico)")
        soundFadeIn("", 2, 0, 0.5)
    end

    if t == "boyfriendSpeaks" then
        doTweenAlpha('appear', 'boyfriend', 1, 1, 'sineInOut')
        doTweenAngle('appearA', 'boyfriend', 360, 1, 'sineInOut')
        runTimer("waitForItDial1", 2)
    end
end

function onUpdatePost(elapsed)
    if dialogueCount == 2 then
        setProperty("camFollow.x", getMidpointX("boyfriend") - 100 - getProperty("boyfriend.cameraPosition[0]") - getProperty("boyfriendCameraOffset[0]"))
        setProperty("camFollow.y", getMidpointY("boyfriend") - 100 + getProperty("boyfriend.cameraPosition[1]") + getProperty("boyfriendCameraOffset[1]"))

        setProperty("camFollowPos.x", getMidpointX("boyfriend") - 100 - getProperty("boyfriend.cameraPosition[0]") - getProperty("boyfriendCameraOffset[0]"))
        setProperty("camFollowPos.y", getMidpointY("boyfriend") - 100 + getProperty("boyfriend.cameraPosition[1]") + getProperty("boyfriendCameraOffset[1]"))
    end

    if keyboardJustPressed('BACKSPACE') == true and not inBoyfriendScene then
        dialogueCount = 3
        doTweenAlpha("d_blackbgA", "d_blackbg", 0, 0.5)
    end
end
