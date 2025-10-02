function onCreate()
	-- background shit
	makeLuaSprite('stageback1', 'stages/wiistage/stageback1', -600, -300);
	setScrollFactor('stageback1', 0.9, 0.9);
	scaleObject('stagefront1', 0.9, 0.9);
	
	makeLuaSprite('stagefront1', 'stages/wiistage/stagefront1', -1025, 600);
	scaleObject('stagefront1', 1.3, 1.3);

	addLuaSprite('stageback1', false);
	addLuaSprite('stagefront1', false);
	close(true); --For performance reasons, close this script once the stage is fully loaded, as this script won't be used anymore after loading the stage
end