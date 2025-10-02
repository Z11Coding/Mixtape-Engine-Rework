local attack = 0
function opponentNoteHit()
if attack == 1 then
    health = getProperty('health')
    if getProperty('health') > 0.05 then
        setProperty('health', health- 0.023);
    end
end
end

function onBeatHit()
    if curBeat == 126 then
	   attack = 1
    end
end