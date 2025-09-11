function onCreate() 
	setPropertyFromClass('GameOverSubstate', 'characterName', 'bf_ourple')
	makeLuaSprite('backstage','bg/bckrom', -550,-580)
	scaleObject('backstage', 1.75, 1.75)
	updateHitbox('backstage')
	setProperty('backstage.antialiasing', false)
	addLuaSprite('backstage',false)
end

function onCreatePost()
	makeCharacter('girl', 'girlf', {getProperty('boyfriend.x')+200, 150}, true, {{'girlNote', true, false}})
    addCharacter('girl', true)
	wMove("50, -50, true", "0.001, linear")
end

function wMove(x,y)
	--X = Pos X (Number), Pos Y (Number), isCenter (Bool)
	--Y = Time (Number), Ease (String)
	triggerEvent("Window Dance - Move", x, y)
end
function wSet(x,y)
	--X = Pos X (Number), Pos Y (Number), isCenter (Bool)
	--Y = isSize (Bool)
	triggerEvent("Window Dance - Set", x, y)
end
function wScale(x,y)
	--X = Pos X (Number), Pos Y (Number)
	--Y = Time (Number), Ease (String)
	triggerEvent("Window Dance - Scale", x, y)
end
function wSway(x,y)
	--X = Pos X (Number), Pos Y (Number), isCenter (Bool), transTime(Number), transEase (String)
	--Y = angle (Number), amplitude (Number), time (number), ease (String), keepProgress (Bool)
	triggerEvent("Window Dance - Sway", x, y)
end

function onStepHit()
	if curStep == 1 then
		wMove("50, 50, true", ""..((stepCrochet*0.001*64)*8)..", elasticOut")
	end
end