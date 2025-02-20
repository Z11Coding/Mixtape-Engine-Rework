--script by bbpanzu
--recoded by Just Devi
local onBeat = false;
local dadsingL = 4
local bfsingL = 4
		realAnimdad = 'idle'
		realAnimbf = 'idle'
		
		--[[
function onCreatePost()



for i=0, getProperty('unspawnNotes.length')-1 do
	if getPropertyFromGroup('unspawnNotes', i, 'isSustainNote') and not getPropertyFromGroup('unspawnNotes', i, 'gfNote') then --Doesn't let Dad/Opponent notes get ignored
		setPropertyFromGroup('unspawnNotes', i, 'noAnimation', true); --Miss Misshas no penalties
	end

end

end
function onUpdatePost()



for i=0, getProperty('notes.length')-1 do
	if getPropertyFromGroup('notes', i, 'isSustainNote') and not getPropertyFromGroup('notes', i, 'gfNote') then --Doesn't let Dad/Opponent notes get ignored
		setPropertyFromGroup('notes', i, 'noAnimation', true); --Miss Misshas no penalties
	end

end

end
function goodNoteHit(id,d,t,s)


	if s then

		if(string.startswith(getAnim("boyfriend"),'sing')) then realAnimdad = string.gsub(getAnim("boyfriend"),'-hold','') end
		characterPlayAnim('boyfriend',realAnimdad .. '-hold')
		setProperty('boyfriend.specialAnim',true)
		runTimer('bfSing',(stepCrochet*2)/1000)

		
	end


end

function onTimerCompleted(t,l,ll)

if t == 'dadSing' then

	setProperty('dad.specialAnim',false)

end


if t == 'bfSing' then

	setProperty('boyfriend.specialAnim',false)

end

end

function opponentNoteHit(id,d,t,s)

	if s then

		if(string.startswith(getAnim("dad"),'sing')) then realAnimdad = string.gsub(getAnim("dad"),'-hold','') end
		characterPlayAnim('dad',realAnimdad .. '-hold')
		setProperty('dad.specialAnim',true)
		runTimer('dadSing',(stepCrochet*2)/1000)

		
	end


end
string.startswith = function(self, str) 
    return self:find('^' .. str) ~= nil
end]]--
function getAnim(char,prop)
prop = prop or 'name'
	return getProperty(char .. '.animation.curAnim.' .. prop)

end


function onBeatHit()
	if onBeat then
		if getAnim("dad") == "idle"..getProperty('dad.idleSuffix') then
			characterPlayAnim("dad","idle"..getProperty('dad.idleSuffix'),true)
		end
		if getAnim("boyfriend") == "idle"..getProperty('boyfriend.idleSuffix') then
			characterPlayAnim("boyfriend","idle"..getProperty('boyfriend.idleSuffix'),true)
		end


	end

end
function onEvent(n,v1,v2)
	if n == "onBeat" then
		onBeat = v1 == "true"
	end
end