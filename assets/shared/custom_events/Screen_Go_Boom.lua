function onCreate()
    makeAnimatedLuaSprite("Glass_Effect", "effects/Glass_Boom", 0, 0)
    addAnimationByPrefix("Glass_Effect", "Break", "Break", 20, false)
    addLuaSprite("Glass_Effect")
    setObjectCamera("Glass_Effect", "other")

    setProperty("Glass_Effect.visible", false)
end

function onEvent(name, duration)
    if name == "Screen_Go_Boom" then
        setProperty("Glass_Effect.visible", true)
        local fps = (40 / tonumber(duration))
        objectPlayAnimation("Glass_Effect", "Break", true)
        setProperty("Glass_Effect.animation.curAnim.frameRate", fps) 
    end
end