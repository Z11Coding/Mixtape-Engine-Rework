settings = {
	DenpaMiss = true,
}
function onUpdatePost(elapsed)
	if settings.DenpaMiss then
		if flinch == true then
			setProperty('iconP1.animation.curAnim.curFrame', 1)
			setProperty('iconP1.color', getColorFromHex('5f1ea4'))
			doTweenColor('what', 'iconP1', 'FFFFFF', 0.3, 'linear')
		end
	end
end

function noteMissPress()
	if settings.DenpaMiss then
		flinch = true
		runTimer('flinch', 0.25)
	end
end

function noteMiss()
	if settings.DenpaMiss then
		flinch = true
		runTimer('flinch', 0.25)
	end
end

function onTimerCompleted(tag)
	if tag == 'flinch' then
		flinch = false
	end
end