function onCreatePost()
    if songName == 'City Funk' then
        updateNotes('-alt')
        playAnim('dad', 'idle-alt', true)
    end
end

function onStepHit()
    if songName == 'Machina' then
        if curStep == 639 then
            updateNotes('-alt')
        end
        if curStep == 967 then
            updateNotes('')
        end
    end
end

function updateNotes(suff)
    triggerEvent('Alt Idle Animation', 'dad', suff)

    for i = 0, getProperty('unspawnNotes.length') - 1 do
        if not getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
            setPropertyFromGroup('unspawnNotes', i, 'animSuffix', suff)
        end
    end
    for i = 0, getProperty('notes.length') - 1 do
        if not getPropertyFromGroup('notes', i, 'mustPress') then
            setPropertyFromGroup('notes', i, 'animSuffix', suff)
        end
    end
end
