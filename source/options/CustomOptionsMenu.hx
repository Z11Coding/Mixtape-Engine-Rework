package options;



class CustomOptionsMenu extends BaseOptionsMenu {

    public static var GlobalOptionsMenuArray:Array<CustomOptionsMenu> = [];
    
	public function new() {
		super();
	}

    public function createCustomMenu(
        title:String, 
        options:Array<Option>, 
        rpcTitle:String = null, 
        openImmediately:Bool = false, 
        registerGlobally:Bool = false
    ):Void {
        this.title = title;
        this.rpcTitle = rpcTitle != null ? rpcTitle : "Custom Options"; // for Discord Rich Presence

        for (option in options) {
            addOption(option);
        }

        if (registerGlobally) {
            // Remove existing menu with the same title
            for (i in 0...GlobalOptionsMenuArray.length) {
                if (GlobalOptionsMenuArray[i].title == title) {
                    GlobalOptionsMenuArray.splice(i, 1);
                    break;
                }
            }
            GlobalOptionsMenuArray.push(this);
        }

        if (openImmediately) {
            openMenu();
        }

        super();
    }

    private function openMenu():Void {
        openSubstate(this);
    }

    public static function openCustomOptionsMenu(title:String):Void {
        for (menu in GlobalOptionsMenuArray) {
            if (menu.title == title) {
                menu.openMenu();
                return;
            }
        }
        trace("Menu with title '" + title + "' not found");
    }
}
		


