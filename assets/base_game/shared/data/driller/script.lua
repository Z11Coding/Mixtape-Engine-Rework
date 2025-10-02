local dirAnim = {'LEFT', 'DOWN', 'UP', 'RIGHT'}
local HUDtoDELETE = {'healthBarBG', 'healthBar', 'timeBar', 'timeBarBG', 'iconP1', 'iconP2'}
local isStando = false
local prepareOra = false
local isOra = false
local healthPie = 12
local healthRegenTap = 0
local powerUp = 0
local powerUpEffect = 0
local invincibility = false
local dodging = false

local mattSoffsets = {
   -15, -15, -23, -15, --x
   12, 35, 9, 0 --y
}
local bfSoffsets = {
   -160, -160, -160, -200, --x
   -5, 55, 10, 10 --y
}
function onCreatePost()
 if downscroll then
   setProperty('scoreTxt.y', 10)
 else
   setProperty('scoreTxt.y', 690)
 end

   makeAnimatedLuaSprite('mattSTANDO', 'mechanics/matt/Stands/mattstando', 330, 440)
   addAnimationByPrefix('mattSTANDO', 'idle', 'matt idle', 24, true)
   addAnimationByPrefix('mattSTANDO', 'singLEFT', 'matt left note', 24, false)
   addAnimationByPrefix('mattSTANDO', 'singDOWN', 'matt down note', 24, false)
   addAnimationByPrefix('mattSTANDO', 'singUP', 'matt up note', 24, false)
   addAnimationByPrefix('mattSTANDO', 'singRIGHT', 'matt right note', 24, false)
   setObjectCamera('mattSTANDO', 'camGame')
   scaleObject('mattSTANDO', 1, 1)
   setProperty('mattSTANDO.alpha', 0)
   setProperty('mattSTANDO.visible', true)
   addLuaSprite('mattSTANDO', true)

   makeAnimatedLuaSprite('bfSTANDO', 'mechanics/matt/Stands/bfstando', 450, 460)
   addAnimationByPrefix('bfSTANDO', 'idle', 'BF idle dance', 24, true)
   addAnimationByPrefix('bfSTANDO', 'singLEFT', 'BF NOTE LEFT', 24, false)
   addOffset("bfSTANDO", "singLEFT", -130, 10)
   addAnimationByPrefix('bfSTANDO', 'singDOWN', 'BF NOTE DOWN', 24, false)
   addOffset("bfSTANDO", "singDOWN", -140, -45)
   addAnimationByPrefix('bfSTANDO', 'singUP', 'BF NOTE UP', 24, false)
   addOffset("bfSTANDO", "singUP", -160, -5)
   addAnimationByPrefix('bfSTANDO', 'singRIGHT', 'BF NOTE RIGHT', 24, false)
   addOffset("bfSTANDO", "singRIGHT", -100, -10)
   setObjectCamera('bfSTANDO', 'camGame')
   scaleObject('bfSTANDO', 1, 1)
   setProperty('bfSTANDO.alpha', 0)
   setProperty('bfSTANDO.visible', true)
   addLuaSprite('bfSTANDO', true)

   makeAnimatedLuaSprite('pie', 'mechanics/matt/HUD/pie', 40, 120)
  for i=0,12 do
   addAnimationByPrefix('pie', 'health'..i..'', 'health '..i..'', 0, false)
  end
   setObjectCamera('pie', 'camHUD')
   scaleObject('pie', 0.75, 0.75)
   setProperty('pie.alpha', 0)

   makeLuaSprite('powerBarBG', nil, 1240, 60)
   makeGraphic('powerBarBG', 16, 600, '000000')
   setObjectCamera('powerBarBG', 'camHUD')
   addLuaSprite('powerBarBG', true)
   makeLuaSprite('powerBar', nil, 1242, 65)
   makeGraphic('powerBar', 12, 590, '005FFF')
   setObjectCamera('powerBar', 'camHUD')

   makeLuaText('powerTxt', 'Press Z!', 500, 390, 500)
   setTextSize('powerTxt', 35)
   setProperty('powerTxt.alpha', 0)
end
function onUpdate()
   objectPlayAnimation('pie', 'health'..healthPie..'', false)
   setProperty('powerBar.scale.y', powerUp / 100)
   if keyboardJustPressed('SPACE') then
      healthRegenTap = healthRegenTap + 1
   end
   if keyboardJustPressed('E') and dodging == false and isStando == false and mustHitSection == false and isOra == false and prepareOra == false then
      dodging = true
      triggerEvent('Play Animation', 'dodge', 'boyfriend')
	  runTimer('dodged', 1.25, 1)
   end
   if healthRegenTap == 4 then
      healthRegenTap = 0
	  healthPie = healthPie + 1
   end
   if healthPie <= 0 then
      setProperty('health', -420228)
   end
   if healthPie > 12 then
      healthPie = 12
   end
   if powerUp == 100 then
    setProperty('powerTxt.alpha', 1)
	setTextString('powerTxt', 'Press Z!')
     if keyboardJustPressed('Z') then
      powerUpEffect = getRandomInt(1,10)
	  powerUp = 0
	  runTimer('powerTxtFadeOut', 2, 1)
	  if powerUpEffect == 1 or powerUpEffect == 2 or powerUpEffect == 5 then
	     --nothing lol
		 setTextString('powerTxt', 'nothing lol')
	  end
	  if powerUpEffect == 4 or powerUpEffect == 10 or powerUpEffect == 8 then
	     healthPie = healthPie - getRandomInt(1,3)
		 setTextString('powerTxt', 'Die')
         setProperty('pie.alpha', 1)
	  end
	  if powerUpEffect == 3 or powerUpEffect == 6 or powerUpEffect == 9 then
	     healthPie = healthPie + getRandomInt(1,3)
		 setTextString('powerTxt', 'Extra Shield')
         setProperty('pie.alpha', 1)
	  end
	  if powerUpEffect == 7 then
	     invincibility = true
		 runTimer('stopInvincibility', 5, 1)
		 setTextString('powerTxt', 'Invincibility')
	  end
	 end
   end
end
function goodNoteHit(id, direction, type, isSustainNote)
  if type == 'punch' then
    for i=0,#dirAnim do
      if direction == i then
        cancelTween("boyfriendSTANDO1")
        setProperty('bfSTANDO.alpha', 1)
        playAnim('bfSTANDO', 'sing'..dirAnim[i+1]..'', false)
        doTweenAlpha('boyfriendSTAND01', 'bfSTANDO', 0, 0.5, 'cubeOut')
      end
    end
  end
 if powerUp < 100 then
   powerUp = powerUp + 0.5
 end
 if isStando == false and dodging == false and isOra == false and prepareOra == false then
  for i=0,#dirAnim do
    if direction == i then
      playAnim('dad', 'block'..dirAnim[i+1]..'', false)
      playAnim('boyfriend', 'punch'..dirAnim[i+1]..'', false)
    end
  end
 end
 if isStando == true then
  for i=0,#dirAnim do
    if direction == i then
      setProperty("bfSTANDO.alpha", 1)
      playAnim('bfSTANDO', 'sing'..dirAnim[i+1]..'', false)
    end
  end
 end
end
function opponentNoteHit(id, direction, type, isSustainNote)
  if type == 'punch' then
    for i=0,#dirAnim do
      if direction == i then
        setProperty('mattSTANDO.alpha', 1)
        playAnim('mattSTANDO', 'sing'..dirAnim[i+1]..'', false)
        doTweenAlpha('mattSTANDO1', 'mattSTANDO', 0, 0.5, 'cubeOut')
      end
    end
  end
 if isStando == false and isOra == false and prepareOra == false then
  for i=0,#dirAnim do
    if direction == i then
      playAnim('dad', 'punch'..dirAnim[i+1]..'', false)
     if dodging == false then
      playAnim('boyfriend', 'block'..dirAnim[i+1]..'', false)
	 end
    end
  end
 end
 if isStando == true then
  for i=0,#dirAnim do
    if direction == i then
      setProperty("mattSTANDO.alpha", 1)
      playAnim('mattSTANDO', 'sing'..dirAnim[i+1]..'', false)
      setProperty('mattSTANDO.x', 330+ mattSoffsets[i+1])
      setProperty('mattSTANDO.y', 440+ mattSoffsets[i+5])
    end
  end
 end
end
function noteMiss(id, direction, noteType, isSustainNote)
 playAnim('gf', 'sad', false)
 if invincibility == false then
  healthPie = healthPie - 1
  setProperty('pie.alpha', 1)
 end
 if invincibility == true then
  setProperty('pie.alpha', 1)
 end
 if isStando == true and mustHitSection == true then
   playAnim('boyfriend', 'stand', false)
 end
end
function onEvent(name, value1, value2)
   if name == 'stando' then
     if value1 == 'T' or value1 == 't' --[[I'm Lazy. Leave me alone.]] then
	    isStando = true
        triggerEvent('Play Animation', 'stand', 'dad')
        triggerEvent('Camera Follow Pos', 700, 500)
	 end
     if value1 == 'F' or value1 == 'f' then
	    isStando = false
        triggerEvent('Play Animation', 'cheer', 'gf')
        triggerEvent('Change Focus', 'off')
	 end
   end
   if name == 'tweenStando' then
     if value1 == 'dad' then
	  if value2 == 't' then
      doTweenAlpha('mattSTANDO1', 'mattSTANDO', 1, 0.5, 'cubeOut')
     doTweenX('dadLeft', 'dad', getProperty('dad.x')- 420, 0.2, 'cubeInOut')
	  end
	  if value2 == 'f' then
       playAnim('dad', 'idle', false)
	     doTweenAlpha('mattSTANDO1', 'mattSTANDO', 0, 0.5, 'cubeOut')
       doTweenX('dadBACK', 'dad', getProperty('dad.x')+ 420, 0.25, 'cubeIn')
	  end
	 end
     if value1 == 'bf' then
	  if value2 == 't' then
      doTweenAlpha('boyfriendSTANDO1', 'bfSTANDO', 1, 0.5, 'cubeOut')
     doTweenX('bfRight2', 'boyfriend', getProperty('boyfriend.x')+ 420, 0.2, 'cubeInOut')
	  end
	  if value2 == 'f' then
      doTweenAlpha('boyfriendSTANDO1', 'bfSTANDO', 0, 0.5, 'cubeOut')
       playAnim('bfSTANDO', 'idle', false)
       doTweenX('bfBACK2', 'boyfriend', getProperty('boyfriend.x')- 420, 0.25, 'cubeIn')
	  end
	 end
   end
   if name == 'prepare' and prepareOra == false then
     prepareOra = true
	 doTweenX('dadLeft', 'dad', getProperty('dad.x')- 420, 0.2, 'cubeInOut')
	 doTweenX('bfRight', 'boyfriend', getProperty('boyfriend.x')+ 420, 0.2, 'cubeInOut')
     triggerEvent('Play Animation', 'prepare', 'dad')
     triggerEvent('Play Animation', 'prepare', 'bf')
   end
   if name == 'oraEnd' then
     isOra = false
     cameraFlash('camOther', 'FFFFFF', 0.75, false)
     triggerEvent('Play Animation', 'idle', 'dad')
     triggerEvent('Play Animation', 'idle', 'bf')
   end
end
function onStepHit()
  if curStep % 96 == 0 then
    doTweenY('gfDownLine', 'gf', getProperty('gf.y')+ 40, 0.75, 'cubeIn')
  end
  if isStando == true and mustHitSection == true and curStep % 8 == 0 then
    playAnim('boyfriend', 'stand', false)
  end
  if isOra == true then
     triggerEvent('Screen Shake', '0.1, 0.005', '0.1, 0.0025')
   if curStep % 4 == 0 then
     triggerEvent('Play Animation', 'ora', 'dad')
     triggerEvent('Play Animation', 'ora', 'bf')
   end
  end
end
function onBeatHit()
   if healthPie == 12 and curBeat % 4 == 0 and getProperty('pie.alpha') == 1 then
	  doTweenAlpha('pieBye', 'pie', 0, 0.5, 'cubeInOut')
   end
end
function onTweenCompleted(tag)
   if tag == 'gfDownLine' then
     doTweenY('gfUpLine', 'gf', getProperty('gf.y')- 40, 0.75, 'cubeOut')
   end
   if tag == 'bfRight' then
	 doTweenX('dadBACK', 'dad', getProperty('dad.x')+ 420, 0.25, 'cubeIn')
	 doTweenX('bfBACK', 'boyfriend', getProperty('boyfriend.x')- 420, 0.25, 'cubeIn')
   end
   if tag == 'bfBACK' then
      prepareOra = false
	  isOra = true
      triggerEvent('Play Animation', 'ora', 'dad')
      triggerEvent('Play Animation', 'ora', 'bf')
   end
end
function onTimerCompleted(tag, loops, loopsLeft)
   if tag == 'powerTxtFadeOut' then
      doTweenAlpha('powerTxtBye', 'powerTxt', 0, 0.5, 'cubeIn')
   end
   if tag == 'stopInvincibility' then
      invincibility = false
   end
   if tag == 'dodged' then
      dodging = false
	  playAnim('boyfriend', 'idle', false)
   end
end
