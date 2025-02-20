--Created by RamenDominoes (Please credit if using this, thanks! <3)
--Not bad for updating the script heh... lol
--HOLY FUCK I ACTUALLY DID IT, GOD I WAS HAVING SUCH A HARD TIME ADDING THE "DISTANCE" THING TO IT YIPPEEE!!!!!


local HudPieces = {'healthBarBG','healthBar','scoreTxt','iconP1','iconP2','timeBar','timeBarBG','timeTxt'}
local index = 1
function onCreatePost()

	

------------------------------------------------------------------------
	--THE TOP BAR--
	makeLuaSprite('UpperBar', 'empty', -110, -350)
	makeGraphic('UpperBar', 1500, 350, '000000')
	setObjectCamera('UpperBar', 'HUD')
	addLuaSprite('UpperBar', false)


	--THE BOTTOM BAR--
	makeLuaSprite('LowerBar', 'empty', -110, 720)
	makeGraphic('LowerBar', 1500, 350, '000000')
	setObjectCamera('LowerBar', 'HUD')
	addLuaSprite('LowerBar', false)
	
------------------------------------------------------------------------

	UpperBar = getProperty('UpperBar.y')
	LowerBar = getProperty('LowerBar.y')

------------------------------------------------------------------------

	for Notes = 0,7 do 
        	StrumY = getPropertyFromGroup('strumLineNotes', Notes, 'y')
	
	end
------------------------------------------------------------------------
end



--FOR UPSCROLL ENTRANCE--
------------------------------------------------------------------------
function onEvent(name, value1, value2)
	if name == 'blackbars' then
	
	Speed = tonumber(value1)
	Distance = tonumber(value2)
	
	
	
	end

	if Speed and Distance > 0 then	

	doTweenY('Cinematics1', 'UpperBar', UpperBar + Distance, Speed, 'QuadOut')
	doTweenY('Cinematics2', 'LowerBar', LowerBar - Distance, Speed, 'QuadOut')

		for Tweens = 0,7 do 
		noteTweenY('leftBF'..Tweens, Tweens, (StrumY + Distance) - 35, Speed, 'QuadOut')
	
			for Alphas = 1,8 do
			doTweenAlpha('Alpha'..Alphas, HudPieces[index], 0, Speed - 0.1)
			index = index + 1
    				
				if index > #HudPieces then
				index = 1
				
				end
			end
		end
	end


--FOR DOWNSCROLL ENTRANCE--
------------------------------------------------------------------------
	if downscroll and Speed and Distance > 0 then	

	doTweenY('Cinematics1', 'UpperBar', UpperBar + Distance, Speed, 'QuadOut')
	doTweenY('Cinematics2', 'LowerBar', LowerBar - Distance, Speed, 'QuadOut')

		for Tweens = 0,7 do 
		noteTweenY('leftBF'..Tweens, Tweens, (StrumY - Distance) + 35, Speed, 'QuadOut')
	
			for Alphas = 1,8 do
			doTweenAlpha('Alpha'..Alphas, HudPieces[index], 0, Speed - 0.1)
			index = index + 1
    				
				if index > #HudPieces then
				index = 1
				
				end
			end
		end
	end


--FOR EXIT--
------------------------------------------------------------------------
	if Distance <= 0 then		

	doTweenY('Cinematics1', 'UpperBar', UpperBar, Speed, 'QuadIn')
	doTweenY('Cinematics2', 'LowerBar', LowerBar, Speed, 'QuadIn')

		for Tweens = 0,7 do 
		noteTweenY('leftBF'..Tweens, Tweens, StrumY , Speed, 'QuadIn')
	
			for Alphas = 1,8 do
			doTweenAlpha('Alpha'..Alphas, HudPieces[index], 1, Speed + 0.1)
			index = index + 1
    				
				if index > #HudPieces then
				index = 1
				
				end
			end
		end
	end	
end

