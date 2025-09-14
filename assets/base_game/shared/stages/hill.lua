blackH = 80

function onCreate()

	-- Background Shit --

	makeLuaSprite('back', 'stages/hill/back', -980, -690);
	setScrollFactor('back', 0.8, 0.8);
	scaleObject('back', 1.65, 1.65);

	makeLuaSprite('light', 'stages/hill/light', -980, -690);
	setScrollFactor('light', 0.9, 0.9);
	scaleObject('light', 1.65, 1.65);

	makeLuaSprite('lightB', 'stages/hill/light_blend', -980, -690);
	setScrollFactor('lightB', 1.0, 1.0);
	scaleObject('lightB', 1.65, 1.65);
    setBlendMode('lightB', 'screen');

	makeLuaSprite('main', 'stages/hill/main', -980, -690);
	setScrollFactor('main', 1.0, 1.0);
	scaleObject('main', 1.65, 1.65);

	makeLuaSprite('mainB', 'stages/hill/main_blend', -980, -690);
	setScrollFactor('mainB', 1.0, 1.0);
	scaleObject('mainB', 1.65, 1.65);
    setBlendMode('mainB', 'screen');

	makeLuaSprite('front', 'stages/hill/front', -980, -690);
	setScrollFactor('front', 0.8, 0.8);
	scaleObject('front', 1.65, 1.65);

	makeLuaSprite('black', 'stages/hill/black', -980, -690);
	setScrollFactor('black', 1.0, 1.0);
	scaleObject('black', 1.65, 1.65);

	addLuaSprite('back', false);
	addLuaSprite('light', false);
	addLuaSprite('lightB', false);
	addLuaSprite('main', false);
	addLuaSprite('mainB', true);
	addLuaSprite('front', true);
	addLuaSprite('black', true);

-- Black Bar --

	-- makeLuaSprite('hudblend', 'menuscreen/screenLenz', 0, 0);
	-- setObjectCamera('hudblend', 'other');
	-- addLuaSprite('hudblend', false);

	--[[makeLuaSprite('upBlack', '', 0, 0);
	makeGraphic('upBlack', screenWidth, blackH, '000000');
	setObjectCamera('upBlack', 'camHUD');
	addLuaSprite('upBlack', false);

	makeLuaSprite('downBlack', '', 0, screenHeight - blackH);
	makeGraphic('downBlack', screenWidth, blackH, '000000');
	setObjectCamera('downBlack', 'camHUD');
	addLuaSprite('downBlack', false);

	setObjectOrder('upBlack', 0);
	setObjectOrder('downBlack', 0);]]

end
