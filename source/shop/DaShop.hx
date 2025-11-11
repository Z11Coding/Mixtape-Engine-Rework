package shop;

import shop.Item;

class DaShop extends MusicBeatState
{
    var shopGroups:FlxTypedGroup<FlxTypedGroup<Item>>;

    var curCategory:Int = 0;
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
    var itemCost:Int = 0;
    var itemDesc:String = '';

    override function create() {
        ShopData.initShop();

        var bg = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.color = 0xff270138;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
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

        shopGroups = new FlxTypedGroup<FlxTypedGroup<Item>>();
        add(shopGroups);

        reloadShop();

        descBG = new FlxSprite(0, 600).makeGraphic(FlxG.width, 100, 0xF8000000);
		descBG.scrollFactor.set(1,1);
        add(descBG);

        var alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
        desc = new undertale.UnderTextParser(250, descBG.y + 30, Std.int(FlxG.width * 0.6), '', 20);
        desc.font = Paths.font("fnf1.ttf");
        for (letter in alphabet) {
			desc.soundOnChars.set(letter, FlxG.sound.load(Paths.sound('ut/uifont'), 1));
			desc.soundOnChars.set(letter.toUpperCase(), FlxG.sound.load(Paths.sound('ut/uifont'), 1));
		}
        desc.alignment = CENTER;
        desc.scrollFactor.set(1,1);
        add(desc);



        super.create();
    }

    var categoryList:Array<String> = [];
    function reloadShop() {
        shopGroups.clear();
        max = 0;
        categoryList = [];
        for (item in ShopData.items.keys()) {
            var curShopItem = ShopData.items.get(item);
            if (!categoryList.contains(curShopItem.category))
                categoryList.push(curShopItem.category);
            else
                continue;
        }

        for (category in categoryList) {
            var curCategory:FlxTypedGroup<Item> = new FlxTypedGroup<Item>();
            for (item in ShopData.items.keys()) {
                var curShopItem = ShopData.items.get(item);
                if (curShopItem.category == category) curCategory.add(curShopItem);
            }
            shopGroups.add(curCategory);
        }

        for (shop in shopGroups.members) {
            for (item in shop.members)
                item.screenCenter(XY);
        }
    }

    /*
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
    */

    override function update(laps)
    {
        var leftP = controls.UI_LEFT_P;
		var rightP = controls.UI_RIGHT_P;
        var upP = controls.UI_LEFT_P;
		var downP = controls.UI_RIGHT_P;
        if (leftP) changeItem(-1);
        if (rightP) changeItem(1);
        if (upP) changeCategory(-1);
        if (downP) changeCategory(1);
        super.update(laps);

        shopGroups.forEach(function(shop:FlxTypedGroup<Item>) {
            shop.forEach(function(item:Item) {
                if (shop.ID != curCategory)
                    item.alpha = 0.2;

                var targetY = FlxMath.lerp(item.y, (FlxG.height - item.height) / 2 + item.posY * 82, CoolUtil.boundTo(laps * 9, 0, 1));
                item.y = targetY;
            });
        });

        shopGroups.members[curCategory].forEach(function(item:Item) {
            if (item.ID == curItem)
                item.alpha = 1;
            else
                item.alpha = 0.5;

            var targetX = FlxMath.lerp(item.x, (FlxG.width - item.width) / 2 + item.posX * 82, CoolUtil.boundTo(laps * 9, 0, 1));
            item.x = targetX;
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
        var curShopItem = shopGroups.members[curCategory].members[curItem];
        var money = PlayerInfo.curMoney;
        trace(curShopItem.price);
        trace(money);

        if (curShopItem.price > money)
        {
            trace('Can\'t Afford!');
            FlxG.sound.play(Paths.sound("badnoise"+FlxG.random.int(1,3)), 1);
            FlxTween.color(curShopItem.priceTxt, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
            FlxTween.color(curShopItem.icon, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
        }
        else if (curShopItem.price <= money)
        {
            trace('Bought!');
            FlxG.sound.play(Paths.sound("confirmMenu"));
            PlayerInfo.curMoney -= curShopItem.price;

            if (curShopItem.amountAllowedToBuy > 0) curShopItem.amountAllowedToBuy--;
            else if (curShopItem.amountAllowedToBuy == 0) curShopItem.isBought = true;
            reloadShop();
        }
    }

    function changeItem(change:Int = 0)
	{
        var curShopItem = shopGroups.members[curCategory].members[curItem];

		curItem += change;

		if (curItem < 0)
			curItem = max-1;
		if (curItem >= max)
			curItem = 0;

        if (shopGroups.members[curCategory].members[curItem] != null)
            noItems.visible = true;

        var i:Int = 0;
        for(item in shopGroups.members[curCategory].members)
			item.posX = i++ - curItem;

        desc.resetText(curShopItem.desc);
        desc.start(0.05, true);
	}

    function changeCategory(change:Int = 0){
        curCategory += change;

		if (curCategory < 0)
			curCategory = categoryList.length-1;
		if (curCategory >= categoryList.length)
			curCategory = 0;

        var i:Int = 0;
		for(shop in shopGroups.members)
			for (item in shop.members)
                item.posY = i++ - curCategory;
    }
}
