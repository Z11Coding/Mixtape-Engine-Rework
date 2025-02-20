package states.stages;

import states.stages.objects.*;
import objects.Character;
import states.stages.gimmicks.Week1Gimmick;

class StageWeek1 extends BaseStage
{
	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleFog:DadBattleFog;
	var crowdPleaser:Week1Gimmick;
	override function create()
	{
		var bg:BGSprite = new BGSprite('stages/stage/stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stages/stage/stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);
		if(!ClientPrefs.data.lowQuality) {
			var stageLight:BGSprite = new BGSprite('stages/stage/stage_light', -125, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			add(stageLight);
			var stageLight:BGSprite = new BGSprite('stages/stage/stage_light', 1225, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			stageLight.flipX = true;
			add(stageLight);

			var stageCurtains:BGSprite = new BGSprite('stages/stage/stagecurtains', -500, -300, 1.3, 1.3);
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			add(stageCurtains);
		}
	}

	override function createPost() {
        super.createPost();
       	if(ClientPrefs.data.gimmicksAllowed) {
			crowdPleaser = new Week1Gimmick();
			crowdPleaser.cameras = [camHUD];
			add(crowdPleaser);
			switch(songName.toLowerCase().replace('-', ' '))
			{
				case 'bopeebo':
					crowdPleaser.crowdAttentionLoss = 0.04;
				case 'fresh':
					crowdPleaser.crowdAttentionLoss = 0.03;
				case 'dad':
					crowdPleaser.crowdAttentionLoss = 0.04;
				case 'small argument':
					crowdPleaser.crowdAttentionLoss = 0.004;
				case 'beat battle':
					crowdPleaser.crowdAttentionLoss = 0.04;
				case 'beat battle 2':
					crowdPleaser.crowdAttentionLoss = 0.04;
			}
		}
    }

	override function startSong()
		if (ClientPrefs.data.gimmicksAllowed) crowdPleaser.startGimmick();

	override function goodNoteHit(note:Note, field:PlayField) {
		if (ClientPrefs.data.gimmicksAllowed) crowdPleaser.crowdAppeasment += 1;
		super.goodNoteHit(note, field);
	}
	
	override function noteMiss(note:Note, field:PlayField) {
		if (ClientPrefs.data.gimmicksAllowed) crowdPleaser.crowdAppeasment -= 5;
		super.noteMiss(note, field);
	}

	override function beatHit() {
		if (ClientPrefs.data.gimmicksAllowed) crowdPleaser.doClap(curBeat);
		super.beatHit();
	}

	override function eventPushed(event:objects.Note.EventNote)
	{
		switch(event.event)
		{
			case "Dadbattle Spotlight":
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('stages/stage/spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				add(dadbattleLight);

				dadbattleFog = new DadBattleFog();
				dadbattleFog.visible = false;
				add(dadbattleFog);
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Dadbattle Spotlight":
				if(flValue1 == null) flValue1 = 0;
				var val:Int = Math.round(flValue1);

				switch(val)
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleFog.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
						FlxTween.tween(dadbattleFog, {alpha: 0.7}, 1.5, {ease: FlxEase.quadInOut});

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleFog, {alpha: 0}, 0.7, {onComplete: function(twn:FlxTween) dadbattleFog.visible = false});
				}
		}
	}
}