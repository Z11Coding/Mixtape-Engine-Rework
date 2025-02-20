local strength = 10
local dance = 'none'
local time = 0
local songStart = false

function onCreatePost()
	addHaxeLibrary('FlxTween', 'flixel.tweens')
	addHaxeLibrary('Application', 'lime.app')

	wasFull = getPropertyFromClass('openfl.Lib', 'application.window.fullscreen')

	setPropertyFromClass('openfl.Lib', 'application.window.fullscreen', true)
	screenX = getPropertyFromClass('openfl.Lib', 'application.window.width')
	screenY = getPropertyFromClass('openfl.Lib', 'application.window.height')
	setPropertyFromClass('openfl.Lib', 'application.window.fullscreen', false)
	setPropertyFromClass('openfl.Lib', 'application.window.resizable', false)
	setPropertyFromClass('openfl.Lib', 'application.window.borderless', true)
	setPropertyFromClass('openfl.Lib', 'application.window.width', screenX/2)
	setPropertyFromClass('openfl.Lib', 'application.window.height', screenY/2)
	runHaxeCode([[
		FlxTween.tween(Application.current.window, { x: ]].. screenX / 2 - (getPropertyFromClass('openfl.Lib', 'application.window.width') / 2) ..[[, y: ]].. screenY / 2 - (getPropertyFromClass('openfl.Lib', 'application.window.height') / 2) ..[[}, ]].. 60000/curBpm/1000*2 ..[[, {ease: FlxEase.quadInOut});
	]])
end

function onEvent(name, value1, value2)
	if name == 'ToggleWindowDance' then
        dance = value1
        strength = value2
	end
end

function onDestroy()
	setPropertyFromClass('openfl.Lib', 'application.window.width', screenX-screenX/4)
	setPropertyFromClass('openfl.Lib', 'application.window.height', (screenX-screenX/4)/16*9)
	setPropertyFromClass('openfl.Lib', 'application.window.fullscreen', wasFull)
	setPropertyFromClass('openfl.Lib', 'application.window.resizable', true)
	setPropertyFromClass('openfl.Lib', 'application.window.borderless', false)

	if not wasFull then
		runHaxeCode([[
			FlxTween.tween(Application.current.window, { x: ]].. screenX / 2 - (getPropertyFromClass('openfl.Lib', 'application.window.width') / 2) ..[[, y: ]].. screenY / 2 - (getPropertyFromClass('openfl.Lib', 'application.window.height') / 2) ..[[}, ]].. 0.5 ..[[, {ease: FlxEase.quadInOut});
		]])
	end
end

function onSongStart()
    songStart = true
end

-- Add more dances

function onUpdatePost(elapsed)
    time = time + elapsed
    if songStart then
        if dance == 'none' then
            if getPropertyFromClass('openfl.Lib', 'application.window.x') ~= screenX / 2 - (getPropertyFromClass('openfl.Lib', 'application.window.width') / 2) then
                setPropertyFromClass('openfl.Lib', 'application.window.x', screenX / 2 - (getPropertyFromClass('openfl.Lib', 'application.window.width') / 2))
                setPropertyFromClass('openfl.Lib', 'application.window.y', screenY / 2 - (getPropertyFromClass('openfl.Lib', 'application.window.height') / 2))
            end
        elseif dance == 'waterfall' then
            setPropertyFromClass('openfl.Lib', 'application.window.y', screenY * ((math.tan(time*(strength/15))+50)/100) - getPropertyFromClass('openfl.Lib', 'application.window.height') / 2)
            setPropertyFromClass('openfl.Lib', 'application.window.x', screenX * ((((time * strength) % 150)-25)/100) - getPropertyFromClass('openfl.Lib', 'application.window.width') / 2)
        end
    end
end