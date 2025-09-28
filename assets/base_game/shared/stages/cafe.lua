function onCreate()
	-- background shit
	makeLuaSprite('cafe', 'stages/caffe/bgg', -600, -450);

	addLuaSprite('cafe', false);

	close(true); --For performance reasons, close this script once the stage is fully loaded, as this script won't be used anymore after loading the stage
end