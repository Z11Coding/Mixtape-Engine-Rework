function onEvent(name, value1, value2)
	if name == 'bounce' then
		if value1 == '1' then --left
         triggerEvent('Add Camera Zoom', 0.06,0.05)
		 setProperty('camHUD.angle',3)
		 setProperty('camGame.angle',3)
         doTweenAngle('tuin', 'camHUD', 0, crochet*0.001, 'quadOut')
         doTweenAngle('tuin2', 'camGame', 0, crochet*0.002, 'quadOut')
		elseif value1 == '2' then --right
         triggerEvent('Add Camera Zoom', 0.06,0.05)
		 setProperty('camGame.angle',-3)
		 setProperty('camHUD.angle',-3)
         doTweenAngle('tuin', 'camHUD', 0, crochet*0.001, 'quadOut')
         doTweenAngle('tuin2', 'camGame', 0, crochet*0.002, 'quadOut')
		 end
		end 
end