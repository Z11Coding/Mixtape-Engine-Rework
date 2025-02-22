package shop;
import shaders.ColorShader;

class MoneyPopup extends FlxSpriteGroup {
	public var onFinish:Void->Void = null;
	var alphaTween:FlxTween;
    var money:FlxSprite;
    var popupBG:FlxSprite;
    var theText:FlxText;
    var lerpScore:Int = 0;
    var canLerp:Bool = false;
	public function new(amount:Int, ?camera:FlxCamera = null)
	{
		super(x, y);
        this.y -= 100;
        lerpScore = amount;

        PlayerInfo.curMoney += amount;
        PlayerInfo.saveInfo();

        var colorShader:ColorShader = new ColorShader(0);
		popupBG = new FlxSprite(FlxG.width - 300, 0).makeGraphic(300, 100, 0xF8000000);
        popupBG.visible = false;
		popupBG.scrollFactor.set();
        add(popupBG);

        money = new FlxSprite(0, 0).loadGraphic(Paths.image('globalIcons/Coin'));
        money.setGraphicSize(Std.int(money.width * 0.1));
        money.setPosition(popupBG.getGraphicMidpoint().x - 90, popupBG.getGraphicMidpoint().y - (money.height / 2));
        money.antialiasing = true;
        money.updateHitbox(); 
        money.scrollFactor.set();
		add(money);	

        theText = new FlxText(popupBG.x + 90, popupBG.y + 35, 200, Std.string(amount), 35);
		theText.setFormat(Paths.font("comboFont.ttf"), 35, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        theText.setPosition(popupBG.getGraphicMidpoint().x - 10, popupBG.getGraphicMidpoint().y - (theText.height / 2));
        theText.updateHitbox();
		theText.borderSize = 3;
        theText.scrollFactor.set();
        theText.antialiasing = true;
        add(theText);

        money.shader = colorShader.shader;
        theText.shader = colorShader.shader;

        FlxTween.tween(this, {y: 0}, 0.35, {ease: FlxEase.circOut});

        new FlxTimer().start(0.9, function(tmr:FlxTimer)
		{
            canLerp = true;
            colorShader.amount = 1;
            FlxTween.tween(colorShader, {amount: 0}, 0.8, {ease: FlxEase.expoOut});
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.9);
        });

		var cam:Array<FlxCamera> = FlxCamera.defaultCameras;
		if(camera != null) {
			cam = [camera];
		}
		alpha = 0;
		money.cameras = cam;
		theText.cameras = cam;
		popupBG.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {onComplete: function (twn:FlxTween) {
			alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
				startDelay: 2.5,
				onComplete: function(twn:FlxTween) {
					alphaTween = null;
					remove(this);
					if(onFinish != null) onFinish();
				}
			});
		}});
	}

    override function update(elapsed:Float){
        super.update(elapsed);
        if(canLerp){
            lerpScore = Math.floor(FlxMath.lerp(lerpScore, 0, CoolUtil.boundTo(elapsed * 4, 0, 1)/1.5));
            if(Math.abs(0 - lerpScore) < 10) lerpScore = 0;
        }

        theText.text = Std.string(lerpScore);
        money.setPosition(popupBG.getGraphicMidpoint().x - 90, popupBG.getGraphicMidpoint().y - (money.height / 2));
        theText.setPosition(popupBG.getGraphicMidpoint().x - 10, popupBG.getGraphicMidpoint().y - (theText.height / 2));
    }

	override function destroy() {
		if(alphaTween != null) {
			alphaTween.cancel();
		}
		super.destroy();
	}
}

class ShopData {
    public static var items:Map<String, Dynamic> = new Map<String, Dynamic>();
    public static function reloadShop()
    {
        //items.set('Item Name', ['Description', Cost (Int), 'Image Name', Is Hidden (Bool), Is Bought (Bool), Is one-time buy (Bool)]);
        items.set('Perma Extra HP',  ['Permanantly ups the amount of health you have.', 100000, 'emptyAchievement', false, false, false]);
        items.set('Anti-Tutorial',   ['Makes you immune to the "Tutorial Swap" effect per amount owned', 50000, 'emptyAchievement', false, false, false]);
        items.set('+1 Life',         ['Allows you to not only not die, but doesn\'t trigger deathlink too.\n(You can still die to deathlink, though!)', 20000, 'emptyAchievement', false, false, false]);
        items.set('Dylan Special',   ['Makes it so that for 8 seconds, Botplay is enabled with no consiquence.', 5500, 'emptyAchievement', false, false, false]);
        items.set('Bottle of Water', ['Drink some water to heal mid-song!\n(HEAL keybind)', 1200, 'emptyAchievement', false, false, false]);
    }
}