function onCreatePost()
	addHaxeLibrary('Application', 'lime.app')

	wasFull = getPropertyFromClass('openfl.Lib', 'application.window.fullscreen')

	setPropertyFromClass('openfl.Lib', 'application.window.fullscreen', true)
	screenX = getPropertyFromClass('openfl.Lib', 'application.window.width')
	screenY = getPropertyFromClass('openfl.Lib', 'application.window.height')
	setPropertyFromClass('openfl.Lib', 'application.window.fullscreen', wasFull)
end

function onEvent(name, value1, value2)
	if name == 'SetWindowVar' then
		if value1 == 'cameraFollow' then
			-- This isn't in use yet, don't mind it :P
			camFol = value2
		else
   			setPropertyFromClass('openfl.Lib', 'application.window.'.. value1, value2)
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