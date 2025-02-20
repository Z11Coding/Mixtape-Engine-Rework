local active = false
local turnON = false
local shaderList = {
    [0] = 'starfield',
    [1] = 'vcr_with_no_glitch',
    [2] = 'Glitched',
    [3] = 'static',
    [4] = 'vcr_with_glitch',
    [5] = 'underwater',
    [6] = 'analog_tv',
    [7] = 'bloom',
    [8] = 'glitch',
}
guh = 0
local window_default = {}
function onCreate()
    window_default[1] = getPropertyFromClass("openfl.Lib", "application.window.x")
	window_default[2] = getPropertyFromClass("openfl.Lib", "application.window.y")
	--setPropertyFromClass("openfl.Lib", "application.window.borderless",true)
    if songName == 'NoWitness' then
        turnON = false
    else
        turnON = false
    end
end
function onCreatePost()
    luaDebugMode = false
    if getPropertyFromClass('backend.ClientPrefs', 'data.shaders') then
        initLuaShader("glitch")
        makeLuaSprite("underwater2")
        makeGraphic("underwater2", screenWidth, screenHeight)
        setSpriteShader("underwater2", "glitch")

        addHaxeLibrary("ShaderFilter", "openfl.filters")
        runHaxeCode([[
            game.camGame.setFilters([new ShaderFilter(game.getLuaObject("underwater2").shader)]);
            //game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("underwater2").shader)]);
        ]])
    end
end
local shadeRand = math.random(0, 7)
local shadeRand2 = math.random(0, 3)
function onUpdate(elapsed)
    shadeRand = math.random(0, 7)
    shadeRand2 = math.random(0, 3)
    if keyboardJustPressed('E') then
        for i = 0,3 do
            setPropertyFromGroup('strumLineNotes', i, 'alpha', 1)
        end
        cancelTween('liftTheAbyss')
        cancelTween('camHUDLIVE')
        setProperty("iconP2.alpha", 1)
        setProperty("dadGroup.alpha", 1)
        setProperty("theDarkAbyss.alpha", 0)
        setProperty("camHUD.alpha", 1)
        setHealthBarColors(rgbToHex(getProperty("dad.healthColorArray")), rgbToHex(getProperty("boyfriend.healthColorArray")))
    end
    if turnON then
        if active then
            setTextString("timeTxt", "ERROR")
            setPropertyFromClass("openfl.Lib", "application.window.x",getPropertyFromClass("openfl.Lib", "application.window.x") + math.random(-10, 10))
            setPropertyFromClass("openfl.Lib", "application.window.y",getPropertyFromClass("openfl.Lib", "application.window.y") + math.random(-10, 10))
        else
            if getPropertyFromClass("openfl.Lib", "application.window.x") > window_default[1] then
                setPropertyFromClass("openfl.Lib", "application.window.x",getPropertyFromClass("openfl.Lib", "application.window.x") - 1)
            else if getPropertyFromClass("openfl.Lib", "application.window.x") < window_default[1] then
                setPropertyFromClass("openfl.Lib", "application.window.x",getPropertyFromClass("openfl.Lib", "application.window.x") + 1)
            end
            end
            if getPropertyFromClass("openfl.Lib", "application.window.y") > window_default[2] then
                setPropertyFromClass("openfl.Lib", "application.window.y",getPropertyFromClass("openfl.Lib", "application.window.y") - 1)
            else if getPropertyFromClass("openfl.Lib", "application.window.y") < window_default[2] then
                setPropertyFromClass("openfl.Lib", "application.window.y",getPropertyFromClass("openfl.Lib", "application.window.y") + 1)
            end
            end
        end
        if getPropertyFromClass('backend.ClientPrefs', 'data.shaders') then
            if active then
                if getPropertyFromClass('backend.ClientPrefs', 'data.flashing') then
                    setSpriteShader("dad", shaderList[shadeRand])
                    setSpriteShader("theDarkAbyssBG", shaderList[shadeRand])
                    setSpriteShader("theDarkAbyssBG2", shaderList[shadeRand])
                    setSpriteShader("rain", shaderList[shadeRand])
                    setSpriteShader("iconP2", shaderList[shadeRand])
                    setSpriteShader("healthBar.leftBar", shaderList[shadeRand])
                    for i = 0, getProperty('dadField.strumNotes.length') - 1 do
                        setSpriteShader('dadField.strumNotes.members['..i..']', shaderList[shadeRand])
                    end
                    for i = 0, getProperty("notes.length") do
                        if not getPropertyFromGroup('notes', i, 'mustPress') then
                            setSpriteShader('notes.members['..i..']', shaderList[shadeRand])
                        end
                    end
                end                
            end
        end
        guh = guh + elapsed
        setProperty('dad.y',150 - 50 * math.sin((guh * 0.3) * math.pi))
        setProperty('dad.x',150 - 50 * math.sin((guh * 0.23) * math.pi))
        if not mustHitSection then
            cameraSetTarget('dad')
        end
    end
end 
local time = 0
function onUpdatePost(elapsed)
    for i = 0, getProperty("notes.length") - 1 do
        if getPropertyFromGroup('notes', i, 'noteType') == 'Void Note' then
            setPropertyFromGroup('notes', i, 'rgbShader.r', '0xFF000000')
            setPropertyFromGroup('notes', i, 'rgbShader.g', '0xFF000000')
            setPropertyFromGroup('notes', i, 'rgbShader.b', '0xFF000000')
        end
    end
    time = time + elapsed
    for i = 0, getProperty('dadField.strumNotes.length') - 1 do
        setShaderFloat('dadField.strumNotes.members['..i..']', "iTime", os.clock())
    end
    setShaderFloat("dad", "iTime", os.clock())
    setShaderFloat("underwater2", "time", os.clock())
    setShaderFloat("boyfriend", "iTime", os.clock())
end

function opponentNoteHit(a,b,c,d)
    if getProperty("health") > 0.1 then
        setProperty('health', getProperty("health") - 0.007)
    end
    if c == 'Void Note' then
        active = true
        turnON = true
        runTimer('reset', 0.1)
        if getProperty("health") > 0.1 then
            setProperty('health', getProperty("health") - 0.08)
        end
        setPropertyFromClass("openfl.Lib", "application.window.x",window_default[1])
        setPropertyFromClass("openfl.Lib", "application.window.y",window_default[2])
    end
end

function onTimerCompleted(tag)
    if tag == 'reset' then
        active = false
        setSpriteShader("dad", "starfield")
        setSpriteShader("theDarkAbyssBG", 'starfield')
        setSpriteShader("theDarkAbyssBG2", 'starfield')
        setSpriteShader("rain", 'starfield')
        setSpriteShader("iconP2", 'starfield')
        setSpriteShader("healthBar.leftBar", 'starfield')
        for i = 0, getProperty('dadField.strumNotes.length') - 1 do
            setSpriteShader('dadField.strumNotes.members['..i..']', 'starfield')
        end
        for i = 0, getProperty("notes.length") do
            if not getPropertyFromGroup('notes', i, 'mustPress') then
                setSpriteShader('notes.members['..i..']', 'RGBPalette')
                setPropertyFromGroup('notes', i, 'rgbShader.r', '0xFF000000')
                setPropertyFromGroup('notes', i, 'rgbShader.g', '0xFF000000')
                setPropertyFromGroup('notes', i, 'rgbShader.b', '0xFF000000')
            end
        end
    end
end

function onDestroy()
    --setPropertyFromClass("openfl.Lib", "application.window.borderless",false)
    setPropertyFromClass("openfl.Lib", "application.window.x",window_default[1])
    setPropertyFromClass("openfl.Lib", "application.window.y",window_default[2])
end

function boundTo(value, min, max)
    return math.max(min, math.min(max, value))
end
function math.lerp(from,to,i)return from+(to-from)*i end