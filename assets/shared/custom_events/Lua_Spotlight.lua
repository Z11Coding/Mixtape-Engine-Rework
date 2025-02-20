-- DADBATTLE SPOTLIGHT EVENT RECREATION
-- OI AIZAKKU ! ! !
-- @author BeastlyGhost#9035

local smokeGroup = {}

local ogZoom = 1

function onCreatePost()
    ogZoom = getProperty('defaultCamZoom')

    makeLuaSprite('dramaticBlackBG', '', -800, -400)
    makeGraphic('dramaticBlackBG', screenWidth * 2, screenHeight * 2, '000000') -- bg
    setProperty('dramaticBlackBG.alpha', 0.75)
    setProperty('dramaticBlackBG.visible', false)
    addLuaSprite('dramaticBlackBG')

    makeLuaSprite('dadSpotlight', 'stages/stage/spotlight', 400, -400) -- light
    setProperty('dadSpotlight.alpha', 0.375)
    setProperty('dadSpotlight.visible', false)
    scaleObject('dadSpotlight', 1.5, 1.5, true)
    setBlendMode('dadSpotlight', 'add')
    addLuaSprite('dadSpotlight', true)

    for i = 1, 2 do
        local smokeX = -1150
        local velR1 = 15
        local velR2 = 22
        if i == 2 then
            smokeX = 1150
            velR1 = -15
            velR2 = -22
        end

        -- smoke barbecue bacon burger
        makeLuaSprite('stageSmoke'..i, 'stages/stage/smoke', smokeX + 200, 660 + getRandomFloat(-20, 20))
        setScrollFactor('stageSmoke'..i, 1.2, 1.05)
        setGraphicSize('stageSmoke'..i, getProperty('stageSmoke'..i..'.width') * getRandomFloat(1.1, 1.22))
        updateHitbox('stageSmoke'..i)

        setBlendMode('stageSmoke'..i, 'add')
        setProperty('stageSmoke'..i..'.velocity.x', getRandomFloat(velR1, velR2))
        setProperty('stageSmoke'..i..'.visible', false)
        setProperty('stageSmoke'..i..'.alpha', 0.7)
        if i == 2 then setProperty('stageSmoke'..i..'.flipX', true) end
        addLuaSprite('stageSmoke'..i, true)
        smokeGroup[i] = 'stageSmoke'..i
    end
end

function onEvent(event, whose, isEnabled)
    if event == 'Lua_Spotlight' then
        local whiteWidth = getProperty('dadSpotlight.width')
        local whiteHeight = getProperty('dadSpotlight.height')
        local bfMidX = getGraphicMidpointX(getProperty('boyfriend'))
        local gfMidX = getGraphicMidpointX(getProperty('gf'))
        local dadMidX = getGraphicMidpointX(getProperty('dad')) + 200

        local bfY = getProperty('boyfriend.y')
        local gfY = getProperty('gf.y')
        local dadY = getProperty('dad.y')

        local bfHeight = getProperty('boyfriend.height')
        local gfHeight = getProperty('gf.height')
        local dadHeight = getProperty('dad.height')

        if isEnabled == 'true' then
            for _, v in pairs(smokeGroup) do setProperty(v..'.visible', true) end
            setProperty("defaultCamZoom", getProperty("defaultCamZoom") + 0.12)
            setProperty('dramaticBlackBG.visible', true)
            setProperty('dadSpotlight.visible', true)
            setProperty('dadSpotlight.alpha', 0)
            runTimer('spotlightTimer', 0.12)

            if whose == 'bf' then
                setProperty('dadSpotlight.x', bfMidX - whiteWidth / 2)
                setProperty('dadSpotlight.y', (bfY + bfHeight) - whiteHeight + 50)
            elseif whose == 'gf' then
                setProperty('dadSpotlight.x', gfMidX - whiteWidth / 2)
                setProperty('dadSpotlight.y', (gfY + gfHeight) - whiteHeight + 50)
            else -- follow dad
                setProperty('dadSpotlight.x', dadMidX - whiteWidth / 2)
                setProperty('dadSpotlight.y', (dadY + dadHeight) - whiteHeight + 50)
            end
        else
            for i, v in pairs(smokeGroup) do doTweenAlpha('smokeTween'..i, v, 0, 1) end
            setProperty("defaultCamZoom", ogZoom)
            setProperty('dramaticBlackBG.visible', false)
            setProperty('dadSpotlight.visible', false)
        end
    end
end

function onTweenCompleted(tag)
    for i, v in pairs(smokeGroup) do
        if tag == 'smokeTween'..i then setProperty(v..'.visible', true) end
    end
end

function onTimerCompleted(tag)
    if tag == 'spotlightTimer' then setProperty('dadSpotlight.alpha', 0.375) end
end
