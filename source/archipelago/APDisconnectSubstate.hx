package archipelago;

import archipelago.Client;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import lime.app.Event;

using flixel.util.FlxSpriteUtil;

class APDisconnectSubstate extends FlxSubState
{
	public var onCancel(default, null) = new Event<Void->Void>();
	public var onReconnect(default, null) = new Event<Void->Void>();

	private var _ap:Client;
	private var _seed:String;

	public function new(ap:Client)
	{
		super(FlxColor.fromRGBFloat(0, 0, 0, .5));
		_ap = ap;
		Cursor.show();
	}

	public function setSeed(seed:String):Void {
		_seed = seed;
	}

    function onSlotConnected(slotData:Dynamic):Void
    {
        trace("Connected - returning to game state");
        _ap.onRoomInfo.remove(onRoomInfo);
        _ap.onSlotRefused.remove(onSlotRefused);
        _ap.onSocketDisconnected.remove(onSocketDisconnected);
        _ap.onSlotConnected.remove(onSlotConnected);
        onReconnect.dispatch();
        close();
    }

    function onSocketDisconnected():Void {
        onCancel.dispatch();
    }

    function onSlotRefused(a:Array<String>):Void
        onCancel.dispatch();

    function onRoomInfo():Void
    {
        if (_seed != _ap.seed)
        {
            trace("Seed mismatch; aborting connection");
            _ap.disconnect_socket();
            onCancel.dispatch();
            close();
        }
        else
        {
            trace("Got room info - sending connect packet");

            #if debug
            var tags = ["AP", "Testing"];
            #else
            var tags = ["AP"];
            #end
            _ap.ConnectSlot(_ap.slot, null, 0x7, tags, {major: 0, minor: 3, build: 8}); // HACK: this is not retransmitting the password
        }
    }

	override function create()
	{
		var dcText = new FlxText(0, 0, 0, "Disconnected! Attempting to Reconnect...\n(It might lag a bit. Don't worry, that's normal!)", 20);
		dcText.color = FlxColor.WHITE;

		var dcCaption = new FlxText(0, 0, 0, 
            "You got disconnected from the server.
            \nWe're trying to get you back on now.
            \nIf you cancel, you'll be sent back to the connect screen,
            \nbut your game is saved up to the last song you've beaten.");
		dcCaption.color = FlxColor.WHITE;

		var cancelButton = new FlxButton(0, 0, "Cancel", () ->
		{
			onCancel.dispatch();
			close();
		});
		cancelButton.scrollFactor.set(1, 1);

        var backdrop = new FlxSprite(-11, -11);
		backdrop.makeGraphic(Math.round(dcText.width + 22), Math.round(dcText.height + cancelButton.height + 27), FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(1, 1, dcCaption.width - 2, dcCaption.height - 2, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});
		backdrop.screenCenter();
		for (item in [dcText, dcCaption, cancelButton])
			item.screenCenter(X);

		dcText.y = backdrop.y + 5;
		dcCaption.y = dcText.y + dcText.height + 5;
		cancelButton.y = dcCaption.y + dcCaption.height + 5;

		for (item in [backdrop, dcText, dcCaption, cancelButton])
		{
			item.x = Math.round(item.x);
			item.y = Math.round(item.y);
			add(item);
		}

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_ap.poll();
	}
}