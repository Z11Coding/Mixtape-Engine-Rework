local noAnimations = false
function onUpdate()
  if noAnimations == false then
    for i = 0, getProperty('unspawnNotes.length')-1 do
        setPropertyFromGroup('unspawnNotes', i, 'noAnimation', false);
    end
  end	
  if noAnimations == true then
    for i = 0, getProperty('unspawnNotes.length')-1 do
        setPropertyFromGroup('unspawnNotes', i, 'noAnimation', true);
    end
  end	
end
function onEvent(name, value1, value2)
   if name == 'noAnimEvent' then
     if value1 == 'on' then
	    noAnimations = true
     end
     if value1 == 'off' then
	    noAnimations = false	 
     end	 
   end
end