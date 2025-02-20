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
    window_default[1] = getPropertyFromClass('lime.app.Application','current.window.x')
	window_default[2] = getPropertyFromClass('lime.app.Application','current.window.y')
	--setPropertyFromClass("openfl.Lib", "application.window.borderless",true)
end
function onCreatePost()
    for i = 0, 8 do
        initLuaShader(shaderList[i])
    end
    setSpriteShader("dad", "Unstable")
    setSpriteShader("rain", 'starfield')
    setSpriteShader("iconP2", 'UnstableOther')
    setSpriteShader("theAlley", 'Unstable')
    setSpriteShader("thegate", 'Unstable')
    setSpriteShader("healthBar.leftBar", 'static')
    for i = 0, getProperty("dadField.strumNotes.length") do
        setSpriteShader('dadField.strumNotes['..i..']', 'UnstableOther')
    end
end
local shadeRand = math.random(0, 7)
local shadeRand2 = math.random(0, 3)
function onUpdate(elapsed)
    shadeRand = math.random(0, 7)
    shadeRand2 = math.random(0, 3)
    if turnON then
        if getPropertyFromClass('backend.ClientPrefs', 'data.shaders') then
            if active then
                setProperty('camGame.x', getRandomInt(-50, 50))
                setProperty('camGame.y', getRandomInt(-50, 50))
                setProperty('camHUD.x', getRandomInt(-50, 50))
                setProperty('camHUD.y', getRandomInt(-50, 50))
                setPropertyFromClass('lime.app.Application','current.window.x', window_default[1] + getRandomInt(-10, 10))
                setPropertyFromClass('lime.app.Application','current.window.y', window_default[2] + getRandomInt(-10, 10))
                if getPropertyFromClass('backend.ClientPrefs', 'data.flashing') then
                    setSpriteShader("theAlley", shaderList[shadeRand])
                    setSpriteShader("thegate", shaderList[shadeRand])
                    setSpriteShader("dad", shaderList[shadeRand])
                    setSpriteShader("rain", shaderList[shadeRand])
                    setSpriteShader("iconP2", shaderList[shadeRand])
                    setSpriteShader("healthBar.leftBar", shaderList[shadeRand])
                    for i = 0, getProperty("dadField.strumNotes.length") do
                        setSpriteShader('dadField.strumNotes['..i..']', shaderList[shadeRand])
                    end
                end
            else
                for i = 0, getProperty("dadField.strumNotes.length") do
                    setSpriteShader('dadField.strumNotes['..i..']', 'UnstableOther')
                end                
            end
        end
    end
end 
local time = 0
function onUpdatePost(elapsed)
    time = time + elapsed
    setShaderFloat("dad", "iTime", os.clock())
    setShaderFloat("rain", "iTime", os.clock())
    setShaderFloat("iconP2", "iTime", os.clock())
    setShaderFloat("theAlley", "iTime", os.clock())
    setShaderFloat("thegate", "iTime", os.clock())
    setShaderFloat("healthBar.leftBar", "iTime", os.clock())
    for i = 0, getProperty("dadField.strumNotes.length") do
        setShaderFloat('dadField.strumNotes['..i..']', "iTime", os.clock())
    end
    for i = 0, getProperty("notes.length") do
        if not getPropertyFromGroup('notes', i, 'mustPress') then
            setShaderFloat('notes.members['..i..']', "iTime", os.clock())
        end
    end
end

function opponentNoteHit(a,b,c,d)
    if c == 'Crystal Note' then
        active = true
        turnON = true
        runTimer('reset', 0.1)
        if getProperty("health") > 0.1 then
            setProperty('health', getProperty("health") - 0.08)
        end
    else
        if getProperty("health") > 0.1 then
            setProperty('health', getProperty("health") - 0.007)
        end
    end
end

function onTimerCompleted(tag)
    if tag == 'reset' then
        active = false
        setProperty('camGame.x', 0)
        setProperty('camGame.y', 0)
        setProperty('camHUD.x', 0)
        setProperty('camHUD.y', 0)
        setSpriteShader("dad", "Unstable")
        setSpriteShader("rain", 'starfield')
        setSpriteShader("iconP2", 'UnstableOther')
        setSpriteShader("theAlley", 'Unstable')
        setSpriteShader("thegate", 'Unstable')
        setSpriteShader("healthBar.leftBar", 'static')
        for i = 0, getProperty("dadField.strumNotes.length") do
            setSpriteShader('dadField.strumNotes['..i..']', 'UnstableOther')
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