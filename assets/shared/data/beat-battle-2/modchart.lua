function onCreatePost()
    loadModchart()
    setValue('transformX', 200, 1)
    setValue('localrotateZ', 90, 1)
    setValue('noteAngle', 90, 1)
    setValue('receptorAngle', 90, 1)
    setValue('brake', 1, 1)
    makeLuaSprite("black")
    makeGraphic("black", screenWidth, screenHeight, '000000')
    setObjectCamera('black', 'hud')
    addLuaSprite('black', true)
    if (shadersEnabled) then
        initLuaShader('old timer')
        makeLuaSprite("oldtimer")
        makeGraphic("oldtimer", screenWidth, screenHeight, '000000')
        setSpriteShader("oldtimer", "old timer")
        addHaxeLibrary("ShaderFilter", "openfl.filters");
    end
    if not middlescroll then
        setValue('transformX', -315, 0)
    end
end

function onSongStart()
    
end

function onUpdatePost(elapsed)
    setShaderFloat("oldtimer", "iTime", os.clock());
end

function loadModchart()
    if getPropertyFromClass('backend.ClientPrefs', 'data.modcharts') then
        queueSet(348, 'reverse', 0.5, 0)
        queueSet(350, 'reverse', 1, 0)
        queueSet(412, 'reverse', 0.5, 0)
        queueSet(414, 'reverse', 0, 0)
        queueSet(476, 'reverse', 0.5, 0)
        queueSet(478, 'reverse', 0, 0)
        queueSet(478, 'centered', 1, 0)
        queueSet(480, 'split', 1, 0)
        queueSet(734, 'split', 0, 0)
        queueSet(734, 'centered', 0, 0)
        queueSet(734, 'receptorScroll', 1, 0)
        queueSet(734, 'sudden', 0.5, 0)
        queueSet(864, 'sudden', 1, 0)
        queueSet(988, 'fieldRoll', 180/4, 0)
        queueSet(990, 'fieldRoll', 180/3, 0)
        queueSet(992, 'fieldRoll', 180/2, 0)
        queueSet(1052, 'fieldRoll', 270/4, 0)
        queueSet(1054, 'fieldRoll', 270/3, 0)
        queueSet(1056, 'fieldRoll', 270/2, 0)
        queueSet(1120, 'fieldRoll', 0, 0)
        queueSet(1120, 'sudden', 0, 0)
        queueSet(1120, 'receptorScroll', 0, 0)
    end
end

index = 0
lol = 1
function onStepHit()
    function effectSwitcher(eff)
        if eff == 'basic' then
            if curStep % 8 == 0 then
                queueSet(curStep, 'drunk', 5, 0)
                queueEase(curStep, curStep+4, 'drunk', 0, 'cubeOut', 0)
            end
            if curStep % 8 == 4 then
                queueSet(curStep, 'drunk', -5, 0)
                queueEase(curStep, curStep+4, 'drunk', 0, 'cubeOut', 0)
            end
        elseif eff == 'basicAlt' then
            if curStep % 8 == 0 then
                queueSet(curStep, 'tipZ', 5)
                queueEase(curStep, curStep+4, 'tipZ', 0, 'cubeOut')
            end
            if curStep % 8 == 4 then
                queueSet(curStep, 'tipZ', -5)
                queueEase(curStep, curStep+4, 'tipZ', 0, 'cubeOut')
            end
        elseif eff == 'rotato' then
            if curStep % 8 == 0 then
                rotateArray = {0, 90, 180, 270};
                queueEase(curStep, curStep+8, 'centerrotateZ', rotateArray[curBeat % 5], 'cubeOut', 0)
            end
        end
    end

    if getPropertyFromClass('backend.ClientPrefs', 'data.modcharts') then
        if curStep >= 284 and curStep <= 347 then
            effectSwitcher('basic')
        elseif curStep >= 352 and curStep <= 411 or curStep >= 864 and curStep <= 987 then
            effectSwitcher('basicAlt')
        elseif curStep >= 480 and curStep <= 731 then
            effectSwitcher('rotato')
        end
    end
    
    if curStep == 32 then
        doTweenAlpha('reveal', 'black', 0, stepCrochet*0.001*128, 'sineInOut')
    end
    if (shadersEnabled) then
        if (shadersEnabled) then
            runHaxeCode([[
                if (curStep == 1)
                {
                    game.camGame.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
                    game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
                }
                if (curStep == 284)
                {
                    game.camGame.setFilters([]);
                    game.camHUD.setFilters([]);
                }
                if (curStep == 732)
                {
                    game.camGame.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
                    game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
                }
                if (curStep == 864)
                {
                    game.camGame.setFilters([]);
                    game.camHUD.setFilters([]);
                }
                if (curStep == 1120)
                {
                    game.camGame.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
                    game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("oldtimer").shader)]);
                }
                if (curStep == 1184)
                {
                    game.camGame.setFilters([]);
                    game.camHUD.setFilters([]);
                }
            ]]);
        end
        if curStep == 284 then
            setObjectCamera('black', 'other')
            setProperty('black.alpha', 1)
        end
        if curStep == 288 then
            cameraFlash('other', 'FFFFFF', 1)
            setProperty('black.alpha', 0)
        end
        if curStep == 732 then
            setProperty('black.alpha', 1)
        end
        if curStep == 736 then
            cameraFlash('other', 'FFFFFF', 1)
            setProperty('black.alpha', 0)
        end
        if curStep == 864 then
            cameraFlash('other', 'FFFFFF', 1)
        end
        if curStep == 1120 then
            if getPropertyFromClass('backend.ClientPrefs', 'data.modcharts') then setValue('centerrotateZ', 0, 0) end
            cameraFlash('other', 'FFFFFF', 1)
        end
        if curStep == 1184 then
            setProperty('black.alpha', 1)
        end
    end
end

function onDestroy()
    if (shadersEnabled) then
        runHaxeCode([[
            trace('No More Shaders');
            game.camGame.setFilters([]);
            game.camHUD.setFilters([]);
        ]]);
    end
end