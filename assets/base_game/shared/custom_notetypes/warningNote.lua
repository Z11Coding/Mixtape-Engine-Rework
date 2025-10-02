function onCreate()
	--Iterate over all notes
	for i = 0, getProperty('unspawnNotes.length')-1 do
		--Check if the note is an Instakill Note
		if getPropertyFromGroup('unspawnNotes', i, 'noteType') == 'warningNote' then
			setPropertyFromGroup('unspawnNotes', i, 'texture', 'Notes/warningNote'); --Change texture
			setPropertyFromGroup('unspawnNotes', i, 'missHealth', '1'); --Default value is: 0.0475, health lost on miss
			setPropertyFromGroup('unspawnNotes', i, 'hitCausesMiss', false);
			setPropertyFromGroup('unspawnNotes', i, 'rgbShader.enable', false); --custom notesplash color, why not			
		end
	end
end