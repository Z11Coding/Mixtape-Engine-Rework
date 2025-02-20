package shop;

class DaShop extends MusicBeatState
{
    private var icons:FlxTypedGroup<FlxSprite>;
    var curItem:Int = 0;
    var descBG:FlxSprite;
    var desc:undertale.UnderTextParser;
    var max = 0;
    var canLerp:Bool = true;
    var money:FlxSprite;
    var popupBG:FlxSprite;
    var theText:FlxText;
    var lerpScore:Int = 0;
    var noItems:FlxText;

    //Item Stuff
    var itemArray:Array<Dynamic> = [];
    var itemName:String = '';
    var itemCost:Int = 0;
    var itemDesc:String = '';
    
    override function create() {
        ShopData.initShop();

        var bg = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.color = 0xff270138;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		add(bg);

        popupBG = new FlxSprite(FlxG.width - 300, 0).makeGraphic(300, 100, 0xF8000000);
		popupBG.scrollFactor.set(1,1);
        add(popupBG);

        money = new FlxSprite(0, 0).loadGraphic(Paths.image('globalIcons/Coin'));
        money.setGraphicSize(Std.int(money.width * 0.1));
        money.setPosition(popupBG.getGraphicMidpoint().x - 90, popupBG.getGraphicMidpoint().y - (money.height / 2));
        money.antialiasing = true;
        money.updateHitbox(); 
        money.scrollFactor.set(1,1);
		add(money);	

        theText = new FlxText(popupBG.x + 90, popupBG.y + 35, 200, Std.string(PlayerInfo.curMoney), 35);
		theText.setFormat(Paths.font("comboFont.ttf"), 35, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        theText.setPosition(popupBG.getGraphicMidpoint().x - 10, popupBG.getGraphicMidpoint().y - (theText.height / 2));
        theText.updateHitbox();
		theText.borderSize = 3;
        theText.scrollFactor.set(1,1);
        theText.antialiasing = true;
        add(theText);

        noItems = new FlxText(0, 0, 200, 'NO ITEMS TO BUY!', 35);
		noItems.setFormat(Paths.font("comboFont.ttf"), 35, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        noItems.screenCenter();
        noItems.updateHitbox();
		noItems.borderSize = 3;
        noItems.scrollFactor.set(1,1);
        noItems.antialiasing = true;
        noItems.visible = false;
        add(noItems);

        icons = new FlxTypedGroup<FlxSprite>();
	    add(icons);

        reloadShop();

        descBG = new FlxSprite(0, 600).makeGraphic(FlxG.width, 100, 0xF8000000);
		descBG.scrollFactor.set(1,1);
        add(descBG);

        desc = new undertale.UnderTextParser(250, descBG.y + 30, Std.int(FlxG.width * 0.6), '', 20);
        desc.font = Paths.font("fnf1.ttf");
        desc.sounds = [FlxG.sound.load(Paths.sound('ut/monsterfont'), 0.6)];
        desc.alignment = CENTER;
        desc.scrollFactor.set(1,1);
        add(desc);
        super.create();
    }

    function reloadShop() {
        icons.clear();
        itemArray = [];
        max = 0;
        for (i in ShopData.items.keys())
        {
            if (!ShopData.items.get(i)[3] || !ShopData.items.get(i)[4])
            {
                trace(i);
                var imageFile:String = ShopData.items.get(i)[2];
                var image:FlxSprite = new FlxSprite().loadGraphic(Paths.image('shop/'+imageFile));
                image.screenCenter(Y);
                image.x += 150 * max;
                image.ID = max;
                icons.add(image);
                max++;  
                var text:FlxText = new FlxText(image.x + 50, image.y + 150, 0, ShopData.items.get(i)[1], 15);
                text.setFormat(Paths.font("comboFont.ttf"), 25, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                text.ID = max-1;
                icons.add(text);
                itemArray.push([i, ShopData.items.get(i)[0], ShopData.items.get(i)[1], ShopData.items.get(i)[2], ShopData.items.get(i)[3], ShopData.items.get(i)[4]]);
            }
        }
    }

    override function update(laps)
    {
        var upP = controls.UI_LEFT_P;
		var downP = controls.UI_RIGHT_P;
        if (upP) changeItem(-1);
        if (downP) changeItem(1);
        super.update(laps);
        icons.forEach(function(spr:FlxSprite)
        {
            if (spr.ID == curItem) 
            {
                spr.alpha = 1;
            }
            else
            {
                spr.alpha = 0.5;
            }

        });

        if(canLerp){
            lerpScore = Math.floor(FlxMath.lerp(lerpScore, PlayerInfo.curMoney, CoolUtil.boundTo(laps * 4, 0, 1)/1.5));
            if(Math.abs(0 - lerpScore) < 10) lerpScore = 0;
        }

        if (controls.BACK)
        {
            PlayerInfo.saveInfo();
            TransitionState.transitionState(states.MainMenuState, {transitionType: "stickers"});
        }

        if (controls.ACCEPT)
        {
            buyItem(curItem);
        }

        theText.text = Std.string(lerpScore);
        money.setPosition(popupBG.getGraphicMidpoint().x - 90, popupBG.getGraphicMidpoint().y - (money.height / 2));
        theText.setPosition(popupBG.getGraphicMidpoint().x - 10, popupBG.getGraphicMidpoint().y - (theText.height / 2));
    }

    function buyItem(item:Int)
    {
        var itemName = itemArray[item][0];
        var cost = itemArray[item][2];
        var money = PlayerInfo.curMoney;
        trace(cost);
        trace(money);

        if (cost > money)
        {
            trace('Can\'t Afford!');
            FlxG.sound.play(Paths.sound("badnoise"+FlxG.random.int(1,3)), 1);
            FlxTween.color(theText, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
            icons.forEach(function(spr:FlxSprite)
            {
                if (spr.ID == item) FlxTween.color(spr, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
            });
        }
        else if (cost <= money)
        {
            trace('Bought!');
            FlxG.sound.play(Paths.sound("confirmMenu"));
            PlayerInfo.curMoney -= cost;
            ShopData.items.get(itemName)[3] = true;
            reloadShop();
        }
    }

    function changeItem(change:Int = 0)
	{
		curItem += change;

		if (curItem < 0)
			curItem = max-1;
		if (curItem >= max)
			curItem = 0;



        if (itemArray[curItem] != null)
        {
            itemName = itemArray[curItem][0];
            itemCost = itemArray[curItem][2];
            itemDesc = itemArray[curItem][1];
        }
        else noItems.visible = true;

        desc.resetText(itemDesc);
        desc.start(0.05, true);
	}
}