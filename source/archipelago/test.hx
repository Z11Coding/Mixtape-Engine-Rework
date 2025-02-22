package archipelago;



function doEffect(effect:String)
{
	if (paused || endingSong) return;
    
	if (effectMap.exists(effect)) {
		effectMap.get(effect)();
	}
}

function applyEffect(ttl:Float, onEnd:(Void->Void), playSound:String, playSoundVol:Float, noIcon:Bool, alwaysEnd:Bool = false)
{
	effectsActive[effect] = (effectsActive[effect] == null ? 0 : effectsActive[effect] + 1);

	if (playSound != "") {
		FlxG.sound.play(Paths.sound("streamervschat/" + playSound), playSoundVol);
	}

	new FlxTimer().start(ttl, function(tmr:FlxTimer) {
		effectsActive[effect]--;
		if (effectsActive[effect] < 0)
			effectsActive[effect] = 0;

		if (onEnd != null && (effectsActive[effect] <= 0 || alwaysEnd))
			onEnd();

		FlxDestroyUtil.destroy(tmr);
	});

	if (!noIcon) {
		var icon = new FlxSprite().loadGraphic(Paths.image("streamervschat/effectIcons/" + effect));
		icon.cameras = [camOther];
		icon.screenCenter(X);
		icon.y = (effectiveDownScroll ? FlxG.height - icon.frameHeight - 10 : 10);
		icon.scale.x = icon.scale.y = 0.5;
		icon.updateHitbox();
		FlxTween.tween(icon, {"scale.x": 1, "scale.y": 1}, 0.1, {
			onUpdate: function(tween) {
				icon.updateHitbox();
				icon.screenCenter(X);
				icon.y = (effectiveDownScroll ? FlxG.height - icon.frameHeight - 10 : 10);
			}
		});
		add(icon);
		new FlxTimer().start(2, function(tmr:FlxTimer) {
			icon.kill();
			remove(icon);
			FlxDestroyUtil.destroy(icon);
			FlxDestroyUtil.destroy(tmr);
		});
	}
}