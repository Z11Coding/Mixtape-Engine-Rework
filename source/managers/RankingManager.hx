package managers;

import substates.RankingSubstate;
/**
 RANKING MANAGER INFO
 * This bad boy not only manages the ranking, but is also the ranking image itself!
 * Anything that needs the ranking to be present will use this manager to do so.
 * ya know, for consistancy sake
 * that and it beats having to make a new one every time.
 * Here's what this manager does:
 
  ** Manages the image that displays the ranking
  ** saves and loads the ranking
  ** can be either big (RankingSubState) or small (Freeplay)

  if this needs to do literally anything else, it'll be added here.
**/
class RankingManager extends FlxSprite {
    public static var instance:RankingManager;
    public var rankTable:Array<String> = [
		'P', 'X', 'X-', 'SS+', 'SS-', 'SS-', 'S+', 'S', 'S-', 'A+', 'A', 'A-', 'B', 'C', 'D', 'E', 'NA', 'F'
	];

    var size:String = 'small';

    override public function new(size:String, ?defalutRank:String = 'NA') {
        this.size = size;
        instance = this;
        super();

        switch (size) {
            case "small":
                loadGraphic(Paths.image('rankings/$defalutRank-small'));    
                scale.x = scale.y = 80 / height;
                updateHitbox();
                antialiasing = true;
                scrollFactor.set();
                y = 690 - height;
                x = -200 + FlxG.width - 50;
                alpha = 0;
            case "big":
                loadGraphic(Paths.image('rankings/$defalutRank'));
                scrollFactor.set();
                antialiasing = true;
                setGraphicSize(0, 450);
                updateHitbox();
                screenCenter();
                alpha = 0;
        }
    }

    public function doTween(tween:String, ?time:Float = 0.5, ?amount:Float = 1) {
        switch (tween) {
            case 'in':
                FlxTween.tween(this, {alpha: amount}, 0.5, {ease: FlxEase.quartInOut});
            case 'out':
                FlxTween.tween(this, {alpha: 0}, 0.5, {ease: FlxEase.quartInOut});
        }
    }

    var rankingNum:Int = 15;
    var wifeConditions:Array<Bool> = [];
    override public function update(elapsed:Float) {
        super.update(elapsed);
        el = elapsed;
    }

    // TODO: Make this better lol
    public static function grabLimits(grade:String, accuracy:String) {
        switch (grade) {
            case 'Any':
                RankingSubstate.comboRankSetLimit = 0;
            case "MFC":
                RankingSubstate.comboRankSetLimit = 1;
            case "SFC":
                RankingSubstate.comboRankSetLimit = 2;
            case "GFC":
                RankingSubstate.comboRankSetLimit = 3;
            case "AFC":
                RankingSubstate.comboRankSetLimit = 4;
            case "FC":
                RankingSubstate.comboRankSetLimit = 5;
            case "SDCB":
                RankingSubstate.comboRankSetLimit = 6;
        }

        switch (accuracy) {
            case "Any":
                RankingSubstate.accRankSetLimit = 0;
            case "P":
                RankingSubstate.accRankSetLimit = 1;
            case "X":
                RankingSubstate.accRankSetLimit = 2;
            case "X-":
                RankingSubstate.accRankSetLimit = 3;
            case "SS+":
                RankingSubstate.accRankSetLimit = 4;
            case "SS":
                RankingSubstate.accRankSetLimit = 5;
            case "SS-":
                RankingSubstate.accRankSetLimit = 6;
            case "S+":
                RankingSubstate.accRankSetLimit = 7;
            case "S":
                RankingSubstate.accRankSetLimit = 8;
            case "S-":
                RankingSubstate.accRankSetLimit = 9;
            case "A+":
                RankingSubstate.accRankSetLimit = 10;
            case "A":
                RankingSubstate.accRankSetLimit = 11;
            case "A-":
                RankingSubstate.accRankSetLimit = 12;
            case "B":
                RankingSubstate.accRankSetLimit = 13;
            case "C":
                RankingSubstate.accRankSetLimit = 14;
            case "D":
                RankingSubstate.accRankSetLimit = 15;
            case "E":
                RankingSubstate.accRankSetLimit = 16;
        }
    }

    var intendedRating:Int = 0;
    var lerpRating:Int = 0;
    var el:Float = 0;
    public var rankOverride:Bool = true;
    public function updateRank() {
        var acc = CoolUtil.floorDecimal(PlayState.instance.comboManager.ratingPercent * 100, 2);
        wifeConditions = [
            acc >= 99.9935, // P
            acc >= 99.980, // X
            acc >= 99.950, // X-
            acc >= 99.90, // SS+
            acc >= 99.80, // SS
            acc >= 99.70, // SS-
            acc >= 99.50, // S+
            acc >= 99, // S
            acc >= 96.50, // S-
            acc >= 93, // A+
            acc >= 90, // A
            acc >= 85, // A-
            acc >= 80, // B
            acc >= 70, // C
            acc >= 69, // Nice
            acc >= 60, // D
            acc < 60 // E
        ];
        for (i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];
			if (b)
			{
				rankingNum = i;
                if (PlayState.deathCounter >= 30 || acc == 0)
					rankingNum = 17;
                break;
			}
		}
        switch (size) {
            case 'small':
                loadGraphic(Paths.image('rankings/${rankTable[rankingNum]}-small'));
                scale.x = scale.y = 140 / height;
                updateHitbox();
                antialiasing = true;
                scrollFactor.set();
            case 'big':
                loadGraphic(Paths.image('rankings/${rankTable[rankingNum]}'));
                scrollFactor.set();
                setGraphicSize(0, 450);
                updateHitbox();
                screenCenter();
        }
    }
    
    public function setRank(rankNum:Int, ?instant:Bool = false) {
        rankOverride = true;
        intendedRating = rankNum;
        lerpRating = Std.int(FlxMath.lerp(intendedRating, lerpRating, Math.exp(-el * 12)));
        if (Math.abs(lerpRating - intendedRating) <= 0 || instant)
			lerpRating = intendedRating;

        switch (size) {
            case 'small':
                loadGraphic(Paths.image('rankings/${rankTable[lerpRating]}-small'));
                scale.x = scale.y = 140 / height;
                updateHitbox();
                antialiasing = true;
                scrollFactor.set();
                y = 690 - height;
                x = -200 + FlxG.width - 50;
            case 'big':
                loadGraphic(Paths.image('rankings/${rankTable[lerpRating]}'));
                scrollFactor.set();
                setGraphicSize(0, 450);
                updateHitbox();
                screenCenter();
        }
    }
}