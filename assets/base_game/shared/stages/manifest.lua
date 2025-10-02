function onCreate()
	makeAnimatedLuaSprite('bg','stages/sky/bg_normal',-212,-200)
	addAnimationByPrefix('bg','bg','bg',24,false)
	playAnim('bg','bg',true)
	addLuaSprite('bg',false)
	setScrollFactor('bg',0,0.9)

	makeAnimatedLuaSprite("shift", "stages/sky/bg_manifest", -388.05, -232);
    addAnimationByIndices("shift", "idle", "bg_manifest", "5", 24);
    addAnimationByPrefix('shift', 'bop', 'bg_manifest', 24, false);
	objectPlayAnimation('shift', 'idle');
    makeAnimatedLuaSprite("floor", "stages/sky/floorManifest", -1053.1, -464.7);
    addAnimationByIndices("floor", "idle", "floorManifest", "5", 24);
    addAnimationByPrefix('floor', 'bop', 'floorManifest', 24, false);
	objectPlayAnimation('floor', 'idle');
    addLuaSprite("shift", false);
    addLuaSprite("floor", false);

	if songName == 'Fangirl Frenzy' then
		setProperty('shift.alpha', 0)
		setProperty('floor.alpha', 0)
	else
		setProperty('bg.alpha', 0)
	end
end

function onBeatHit()
	if curBeat % getProperty("gfSpeed") == 0 then
		playAnim('bg',    'bg', true)
		playAnim('shift', 'bop',true);
        playAnim('floor', 'bop',true);
	end
end