local daDrain = 0.01999
local fadetime = 0.05
function onCreatePost()
    makeLuaText("warn", "REMEMBER THE PATTERN!", 800, getProperty("botplayTxt.x") - 140, getProperty("botplayTxt.y") + 140)
    setTextSize('warn', 45)
    setObjectCamera("warn", "hud")
    setTextColor('warn', 'be201c')
    addLuaText('warn')
    setProperty("warn.visible", false)

    makeLuaText("pain", "You Won't Be Needing These!", 800, getProperty("botplayTxt.x") + 160, getProperty("botplayTxt.y") - 400)
    setTextSize('pain', 25)
    setObjectCamera("pain", "hud")
    addLuaText('pain')
    setProperty("pain.alpha", 0)

    makeAnimatedLuaSprite("notestoremember", "BeatBattle/NOTE_assets", 0, 0)
    screenCenter("notestoremember", 'xy')
    addAnimationByPrefix("notestoremember", "left", "purple0", 24, true)
    addAnimationByPrefix("notestoremember", "down", "blue0", 24, true)
    addAnimationByPrefix("notestoremember", "up", "green0", 24, true)
    addAnimationByPrefix("notestoremember", "right", "red0", 24, true)
    addLuaSprite("notestoremember", false)
    setObjectCamera("notestoremember", "hud")
    setProperty("notestoremember.alpha", 0)

    if difficultyName == 'Impossible' then
        setProperty('gfGroup.visible', false)
        for i = 0, 3 do
            --noteTweenX("suffering "..i, i, -400, 1, "elasticInOut")
            setValue('transformX', -1000, 1)
        end
    end
    if difficultyName == 'Normal' then
        daDrain = 0.00001
    end
    if difficultyName == 'Reasonable' then
        daDrain = 0.0001
    end
    if difficultyName == 'Unreasonable' then
        daDrain = 0.001
    end
    if difficultyName == 'Semi-Impossible' then
        daDrain = 0.01
    end
    if difficultyName == 'Impossible' then
        daDrain = 0.1
    end
end

function onSongStart()
    onBeatHit()
    if difficultyName == 'Impossible' or difficultyName == 'Semi-Impossible' then
        doTweenAlpha("pain", "pain", 1, 2, "sineOut")
        doTweenY("paina", "pain", getProperty("botplayTxt.y"), 2, "sineOut")
        queueEase(1, 16, 'transformY', -400, "elasticInOut", 0)
        for i = 4, 7 do
            --noteTweenY("suffering "..i, i, -400, 2, "elasticInOut")
        end
        runTimer("kys", 4, 1)
    end
end

function onTimerCompleted(tag)
    if tag == 'kys' then
        doTweenY("paina", "pain", getProperty("botplayTxt.y") - 400, 2, "sineOut")
    end
end

function onBeatHit()
    if curBeat % 2 == 1 then
        setProperty('camGame.zoom', getProperty("camGame.zoom") + 0.1)
        setProperty('camHUD.zoom', getProperty("camHUD.zoom") + 0.1)
    end
    if curBeat % 8 == 7 then
        playAnim('boyfriend', 'hey', true)
        playAnim('dad', 'cheer', true)
        setProperty('camGame.zoom', getProperty("camGame.zoom") + 0.5)
        setProperty('camHUD.zoom', getProperty("camHUD.zoom") + 0.1)
    end
    if curBeat % 64 == 47 then
        playAnim('boyfriend', 'hey', true)
        playAnim('dad', 'cheer', true)
        setProperty('camGame.zoom', getProperty("camGame.zoom") + 0.5)
        setProperty('camHUD.zoom', getProperty("camHUD.zoom") + 0.1)
    end
    if curBeat == 254 and (difficultyName == 'Semi-Impossible' or difficultyName == 'Impossible') then
        noteTweenY("suffering", 4, 70, 2, "elasticInOut")
    end
end

function onUpdatePost()
    for i = 0, getProperty('notes.length') -1 do
        if getPropertyFromGroup('notes', i, 'noteType') == 'ArrowMech' then
            if getPropertyFromGroup('notes', i, 'mustPress') then
                setPropertyFromGroup('notes', i, 'alpha', 0)
            else if not getPropertyFromGroup('notes', i, 'mustPress') and difficultyName == 'Unreasonable' then
                setPropertyFromGroup('notes', i, 'alpha', 0)
            end
            end
        end
    end
    if difficultyName == 'Impossible' then
        fadetime = 0.08
    end
    if getProperty("notestoremember.alpha") > 0 then
        setProperty("notestoremember.alpha", getProperty("notestoremember.alpha")-fadetime)
    end
end
local direcList = {'left', 'down', 'up', 'right'}
function opponentNoteHit(id, direc, nType, sus)
    if getProperty('health') > 0.1 then
        setProperty('health', getProperty('health') - daDrain)
    end
    if nType == 'ArrowMech' then
        setProperty("notestoremember.alpha", 1)
        playAnim('notestoremember', direcList[direc+1], true)
        setProperty("warn.visible", true)
        if difficultyName == 'Unreasonable' then
            for a = 0, 3 do
                setPropertyFromGroup('strumLineNotes', a, 'alpha', 0)
            end
        end
    else
        setProperty("warn.visible", false)
        if difficultyName == 'Unreasonable' then
            for a = 0, 3 do
                setPropertyFromGroup('strumLineNotes', a, 'alpha', 1)
            end
        end
        showArrow = false
    end
end

function goodNoteHit(index, noteDir, noteType, isSustainNote)
    if noteType == 'ArrowMech' then
        setProperty("warn.visible", true)
    else
        setProperty("warn.visible", false)
    end
end