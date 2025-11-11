package shop;

typedef MiniItem = {
  var icon:FlxSprite;
  var name:String;
  var image:String;
  var desc:String;
  var price:Int;
  var isHidden:Bool;
  var isBought:Bool;
  var inShop:Bool;
  var amountOwned:Int;
  var extraData:Map<String, Dynamic>;
  var globalEXData:Map<String, Dynamic>;
  var category:String;
  var priceTxt:FlxText;
  var amountAllowedToBuy:Int;
  var apItemID:Int;
  var apItemName:String;
  var apLocID:Int;
  var apLocName:String;
}

class Item extends FlxObject {
    //Per-Item Variables
    public var name:String;
    public var icon:FlxSprite;
    public var image:String;
    public var desc:String;
    public var price:Int;
    public var isHidden:Bool = false;
    public var isBought:Bool = false;
    public var inShop(default, set):Bool = false;
    public var amountOwned:Int = 0;
    public var extraData:Map<String, Dynamic> = [];
    public var alpha:Float = 1;

    private function set_inShop(value:Bool):Bool {
      if (!value && priceTxt != null) {
        FlxG.state.remove(priceTxt);
        priceTxt.destroy();
      } else {
        priceTxt = new FlxText(x + 50, y + 150, 0, "$"+price, 15);
        priceTxt.setFormat(Paths.font("comboFont.ttf"), 25, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        FlxG.state.add(priceTxt);
      }
      return value;
    }

    //Global Variables
    public static var globalEXData:Map<String, Dynamic> = [];

    //Shop-Specific Variables
    public var category:String = 'base';
    public var priceTxt:FlxText;
    public var amountAllowedToBuy:Int = 1;
    public var posX:Int;
    public var posY:Int;

    //AP-Specific Variables
    public var apItemID:Int;
    public var apItemName:String;
    public var apLocID:Int;
    public var apLocName:String;

    public function new(name:String, desc:String, price:Int, image:String, ?isHidden:Bool) {
      super();

      icon = new FlxSprite().loadGraphic(Paths.image('shop/'+(image != null ? image : 'unknownItem')));
      FlxG.state.add(icon);
      this.image = image;
      this.name = name;
      this.desc = desc;
      this.price = price;
      this.isHidden = isHidden;
    }

    public static function makeItemFromMini(miniItem:MiniItem):Item {
      var newItem = new Item(miniItem.name, miniItem.desc, miniItem.price, miniItem.image, miniItem.isHidden);
      newItem.isBought = miniItem.isBought;
      newItem.amountOwned = miniItem.amountOwned;
      newItem.extraData = miniItem.extraData;
      newItem.category = miniItem.category;
      newItem.priceTxt = miniItem.priceTxt;
      newItem.amountAllowedToBuy = miniItem.amountAllowedToBuy;
      newItem.apItemID = miniItem.apItemID;
      newItem.apItemName = miniItem.apItemName;
      newItem.apLocID = miniItem.apLocID;
      newItem.apLocName = miniItem.apLocName;
      return newItem;
    }

    public static function makeMiniItemFromItem(item:Item):MiniItem {
      var newMiniItem:MiniItem = {
        name: item.name,
        desc: item.desc,
        price: item.price,
        icon: item.icon,
        isHidden: item.isHidden,
        isBought: item.isBought,
        amountOwned: item.amountOwned,
        extraData: item.extraData,
        category: item.category,
        priceTxt: item.priceTxt,
        amountAllowedToBuy: item.amountAllowedToBuy,
        apItemID: item.apItemID,
        apItemName: item.apItemName,
        apLocID: item.apLocID,
        apLocName: item.apLocName,
        inShop: item.inShop,
        image: item.image,
        globalEXData: globalEXData,
      };
      return newMiniItem;
    }

    override function update(elapsed:Float) {
      super.update(elapsed);
      icon.alpha = alpha;
      if (priceTxt != null) priceTxt.alpha = alpha;
    }
}
