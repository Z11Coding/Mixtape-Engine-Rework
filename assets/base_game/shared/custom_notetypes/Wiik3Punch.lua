function onCreate()
	local ang = {90, 0, 180, -90}
    for i = 0,getProperty('unspawnNotes.length')-1 do
		if getPropertyFromGroup('unspawnNotes',i,'noteType') == 'Wiik3Punch' then
			setPropertyFromGroup('unspawnNotes',i,'texture','WiiNotes/Wiik3PunchAlt')
			setPropertyFromGroup('unspawnNotes',i,'missHealth',2)
			if not getPropertyFromGroup('unspawnNotes',i,'isSustainNote') then
				setPropertyFromGroup('unspawnNotes',i,'copyAngle',false)
				setPropertyFromGroup('unspawnNotes',i,'angle',ang[getPropertyFromGroup('unspawnNotes',i,'noteData') + 1])
			end
		end
    end
end
function goodNoteHit(id, data, type, sus)
	if type == 'Wiik3Punch' then
		callScript('scripts/global_functions','playerDodge',{false,data})
	end
end