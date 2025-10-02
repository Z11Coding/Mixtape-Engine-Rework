function goodNoteHit(direction, noteData, typea, isSustainNote)
    if typea == 'punch' then
        setHealth(getHealth() + 0.15)
    end	 
end
function opponentNoteHit(id, direction, typea, isSustainNote)
    if typea == 'punch' then
        setHealth(getHealth() - 0.15)
    else
        setHealth(getHealth() - 0.03)
    end	  
end