local funnie = {
	['1000'] = 'W',
	['0100'] = 'S',
	['0010'] = 'N',
	['0001'] = 'E',
	['1100'] = 'WS',
	['0110'] = 'NS',
	['0011'] = 'NE',
	['1010'] = 'NW',
	['0101'] = 'SE',
	['1001'] = 'WE',
	['1110'] = 'WNS',
	['1101'] = 'WSE',
	['1011'] = 'WNE',
	['0111'] = 'NSE',
	['1111'] = 'NSWE'
}
local singingnote = {0, 0, 0, 0};
local hold = {0, 0, 0, 0};
local holdstart = {-1000, -1000, -1000, -1000};
local hittime = {-1000, -1000, -1000, -1000}; --fuck yourself

function noteMiss(id, dir, ntype, sus)
	singingnote[dir + 1] = 0;
	hold[dir + 1] = 0;
	holdstart[dir + 1] = -1000;
	hittime[dir + 1] = -1000;
end

function goodNoteHit(id, dir, ntype, sus)
	if not sus then
		for i = 1, 4 do
			if math.abs(hittime[i] - getPropertyFromGroup('notes', id, 'strumTime')) > 10 then
				singingnote[i] = singingnote[i] * hold[i];
			end
			if hittime[i] < 0 then
				singingnote[i] = 0;
			end
		end
	end
	singingnote[dir + 1] = 1;
	hittime[dir + 1] = getPropertyFromGroup('notes', id, 'strumTime');
	hold[dir + 1] = (sus and 1 or 0);
	holdstart[dir + 1] = sus and getPropertyFromGroup('notes', id, 'strumTime') or -1000;
	if stringEndsWith(getPropertyFromGroup('notes', id, 'animation.curAnim.name'), 'tail') then
		hold[dir + 1] = 0;
		holdstart[dir + 1] = -1000;
	end
	local basetime = (holdstart[dir + 1] >= 0) and getPropertyFromGroup('notes', id, 'strumTime') or holdstart[dir + 1];
	for i = 0, getProperty('notes.length') - 1 do
		if getPropertyFromGroup('notes', i, 'mustPress')
		and	math.abs(getPropertyFromGroup('notes', i, 'strumTime') - basetime) <= 10 then
			local susb = getPropertyFromGroup('notes', i, 'isSustainNote');
			local datab = getPropertyFromGroup('notes', i, 'noteData');
			if stringEndsWith(getPropertyFromGroup('notes', i, 'animation.curAnim.name'), 'tail') then
				hold[datab + 1] = 0;
				holdstart[datab + 1] = -1000;
				hittime[datab + 1] = -1000;
			else
				singingnote[datab + 1] = 1;
				hittime[datab + 1] = getPropertyFromGroup('notes', i, 'strumTime');
				hold[datab + 1] = (susb and 1 or 0);
				holdstart[datab + 1] = sus and getPropertyFromGroup('notes', i, 'strumTime') or -1000;
				if stringEndsWith(getPropertyFromGroup('notes', i, 'animation.curAnim.name'), 'tail') then
					hold[datab + 1] = 0;
					holdstart[datab + 1] = -1000;
				end
			end
		end
	end
	local ani = table.concat(singingnote, '');
	if funnie[ani] ~= nil then
		playAnim('boyfriend', 'sing' .. funnie[ani], true);
	end
	if stringEndsWith(getPropertyFromGroup('notes', id, 'animation.curAnim.name'), 'tail') then
		hold[dir + 1] = 0;
		holdstart[dir + 1] = -1000;
		hittime[datab + 1] = -1000;
	end
end