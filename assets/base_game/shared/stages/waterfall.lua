function onCreate()

	makeLuaSprite('background', 'stages/waterfall/rest_of_the_bg_2', -700, -100);
	scaleObject('background', 1.0, 1.0);
	setScrollFactor('background', 1.0, 1.0);
	addLuaSprite('background', false)

		makeAnimatedLuaSprite('water', 'stages/waterfall/rest_of_the_bg_1', -500,-250)
	addAnimationByPrefix('water','Idle','smokey rest of bg','24',true)
	objectPlayAnimation('water','Idle',false)
	setScrollFactor('water', 1.0, 1.0);
	scaleObject('water', 1.0, 1.0);
	addLuaSprite('water', false)


	makeLuaSprite('walls1', 'stages/waterfall/walls_part_1', -900, -400);
	scaleObject('walls1', 1.5, 1.5);
	setScrollFactor('walls1', 1.0, 1.0);
	addLuaSprite('walls1', false)

	makeLuaSprite('walls2', 'stages/waterfall/walls_part_2', 1400, -400);
	scaleObject('walls2', 1.5, 1.5);
	setScrollFactor('walls2', 1.0, 1.0);
	addLuaSprite('walls2', false)

	makeLuaSprite('glow', 'stages/waterfall/glow_shards_purple', -900, -300);
	scaleObject('glow', 1.1, 1.1);
	setScrollFactor('glow', 1.0, 1.0);
	addLuaSprite('glow', true)

	makeLuaSprite('bridge', 'stages/waterfall/bridge_part', -600, 550);
	scaleObject('bridge', 1.0, 1.0);
	setScrollFactor('bridge', 1.0, 1.0);
	addLuaSprite('bridge', false)

	makeLuaSprite('bones', 'stages/waterfall/BlueBones', 950, 280);
	scaleObject('bones', 1.0, 1.0);
	setScrollFactor('bones', 1.0, 1.0);
	addLuaSprite('bones', true)

	makeLuaSprite('crack', 'stages/waterfall/cracks', 1000, 750);
	scaleObject('crack', 1.0, 1.0);
	setScrollFactor('crack', 1.0, 1.0);
	addLuaSprite('crack', false)

end
