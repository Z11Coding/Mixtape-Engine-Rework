local tweenTime = 1
local tweenType = 'linear'

function onCreatePost()
    addHaxeLibrary('FlxTween', 'flixel.tweens')
	addHaxeLibrary('Application', 'lime.app')

	wasFull = getPropertyFromClass('openfl.Lib', 'application.window.fullscreen')

	setPropertyFromClass('openfl.Lib', 'application.window.fullscreen', true)
	screenX = getPropertyFromClass('openfl.Lib', 'application.window.width')
	screenY = getPropertyFromClass('openfl.Lib', 'application.window.height')
	setPropertyFromClass('openfl.Lib', 'application.window.fullscreen', wasFull)
end

function onEvent(name, value1, value2)
	if name == 'TweenWindowVar' then
        if value1 == 'time' then
            tweenTime = value2
        elseif value1 == 'type' then
            tweenType = value2
        else
   		    runHaxeCode([[
                FlxTween.tween(Application.current.window, { ]].. value1 ..[[: ]].. value2 ..[[}, ]].. tweenTime ..[[, {ease: FlxEase.]].. tweenType ..[[})
            ]])
        end
	end
end

function onDestroy()
	setPropertyFromClass('openfl.Lib', 'application.window.width', screenX-screenX/4)
	setPropertyFromClass('openfl.Lib', 'application.window.height', (screenX-screenX/4)/16*9)
	setPropertyFromClass('openfl.Lib', 'application.window.fullscreen', wasFull)
	setPropertyFromClass('openfl.Lib', 'application.window.resizable', true)
	setPropertyFromClass('openfl.Lib', 'application.window.borderless', false)
end