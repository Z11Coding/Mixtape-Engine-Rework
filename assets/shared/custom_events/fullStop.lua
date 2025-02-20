function onCreatePost()
    if getPropertyFromClass('backend.ClientPrefs', 'data.shaders') then
        initLuaShader("Unstable")
        makeLuaSprite("underwater2")
        makeGraphic("underwater2", screenWidth, screenHeight)
        setSpriteShader("underwater2", "Unstable")

        addHaxeLibrary("ShaderFilter", "openfl.filters")
        runHaxeCode([[
            game.camGame.setFilters([new ShaderFilter(game.getLuaObject("underwater2").shader)]);
            game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("underwater2").shader)]);
        ]])
        setShaderFloat("underwater2", "iTime", 0)
    end
    defaultSpeed = getProperty("SONG.speed")
end

function onEvent(eventName, value1, value2)
    if eventName == 'fullStop' then
        if value1 == 'on' then
            setShaderFloat("underwater2", "iTime", 1)
            triggerEvent("Change Scroll Speed", 0.6, 0)
            setProperty('freezeNotes', true)
        elseif value1 == 'off' then
            setShaderFloat("underwater2", "iTime", 0)
            triggerEvent("Change Scroll Speed", defaultSpeed, 0)
            setProperty('freezeNotes', false)
        end
    end
end

