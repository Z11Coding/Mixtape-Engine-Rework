hill = 'stages/hideandseek/hill/'
function onCreate()
    setProperty('opponentmode', true)
end
function onCreatePost()
    makeLuaSprite("sky", hill..'sky')
    screenCenter("sky")
    addLuaSprite('sky')

    makeLuaSprite("backMountains", hill..'far-mountains', 0, 80)
    screenCenter("backMountains", 'x')
    addLuaSprite('backMountains')
    setScrollFactor("backMountains", 0.2)

    makeLuaSprite("frontMountains", hill..'close-montains')
    screenCenter("frontMountains")
    addLuaSprite('frontMountains')

    makeLuaSprite("water", hill..'water', 0, 400)
    screenCenter("water", "x")
    addLuaSprite('water')

    makeLuaSprite("floor", hill..'floor', 0, 450)
    screenCenter("floor", "x")
    addLuaSprite('floor')

    makeLuaSprite("f&t", hill..'flowers-and-tree', 0, -450)
    screenCenter("f&t", "x")
    addLuaSprite('f&t')

    initLuaShader('scroll')
    setSpriteShader('water', 'scroll')
    setShaderFloat("water",'xSpeed', 0.05)
end

function onUpdatePost(elapsed)
    setShaderFloat('water', 'iTime', elapsed)
end

function onStepHit()
    if curStep == 4 then
        startVideo('tails_animation_3')
    end
end