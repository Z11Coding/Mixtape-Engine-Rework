-- these are the sfx and music file locations:
-- mods/<your-mod>/sounds/gameOverStart-gf.ogg
-- mods/<your-mod>/sounds/crying_sfx.ogg
-- mods/<your-mod>/music/gameOver-gf.ogg
-- mods/<your-mod>/music/gameOverEnd-gf.ogg

local LOOP_VOL   = 1.0     -- song volume
local CRY_VOL    = 1.9     -- crying volume
local POLL_EVERY = 0.05    -- seconds between checks for loop start
local MAX_WAIT   = 5.0     -- fallback start time if loop not detected
local CRY_DELAY  = 0.06    -- lil bit of extra delay after loop starts (avoids overlap with stinger)

-- STATES AND SHIT!!
local inGO, startedCry, waited = false, false, 0.0

local function isGF()
    return getProperty('boyfriend.curCharacter') == 'GF_V3'
end

local function startCrying()
    playSound('crying_sfx', CRY_VOL, 'gfCry')
end

function onCreate()
    if not isGF() then return end
    setPropertyFromClass('substates.GameOverSubstate', 'characterName',  'GF_DeadAlt')
    setPropertyFromClass('substates.GameOverSubstate', 'deathSoundName', 'gameOverStart-gf') -- /sounds
    setPropertyFromClass('substates.GameOverSubstate', 'loopSoundName',  'gameOver-gf')      -- /music
    setPropertyFromClass('substates.GameOverSubstate', 'endSoundName',   'gameOverEnd-gf')   -- /music
end

function onGameOverStart()
    if not isGF() then return end
    inGO, startedCry, waited = true, false, 0.0
    runTimer('GF_WaitForLoop', POLL_EVERY, 0) -- repeat until loop is detected (or MAX_WAIT)
end

function onTimerCompleted(tag, loops, loopsLeft)
    if not inGO then return end

    if tag == 'GF_WaitForLoop' and not startedCry then
        local loopReady = runHaxeCode([[
            import flixel.FlxG;
            (FlxG.sound.music != null && FlxG.sound.music.playing);
        ]])

        if loopReady then
            cancelTimer('GF_WaitForLoop')
            runTimer('GF_StartCry', CRY_DELAY)  -- tiny delay so we start after the stinger
            return
        end

        waited = waited + POLL_EVERY
        if waited >= MAX_WAIT then
            cancelTimer('GF_WaitForLoop')
            runTimer('GF_StartCry', 0)          -- fallback start if shit fucks up
        end
        return
    end

    if tag == 'GF_StartCry' and not startedCry then
        startedCry = true
        startCrying()
        return
    end
end

function onSoundFinished(tag)
    if inGO and tag == 'gfCry' then
        startCrying() -- idk how to make it loop
    end
end

function onUpdatePost(elapsed)
    if not inGO then return end
    -- keep loop volume
    runHaxeCode([[
        if (FlxG.sound.music != null) {
            FlxG.sound.music.volume = ]] .. tostring(LOOP_VOL) .. [[;
        }
    ]])
end

function onGameOverConfirm(retry)
    if not inGO then return end
    inGO, startedCry = false, false
    cancelTimer('GF_WaitForLoop')
    cancelTimer('GF_StartCry')
    if soundFadeOut then
        soundFadeOut('gfCry', 0.1, 0)
    elseif stopSound then
        stopSound('gfCry')
    end
end

function onDestroy()
    -- safety if the scene unloads
    if stopSound then stopSound('gfCry') end
end
