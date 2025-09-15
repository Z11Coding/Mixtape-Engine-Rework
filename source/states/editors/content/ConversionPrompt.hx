package states.editors.content;

import backend.ui.PsychUIButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class ConversionPrompt extends MusicBeatSubstate
{
	var onSelect:Int->Void;
	var onCancel:Void->Void;

	var bg:FlxSprite;
	var titleText:FlxText;
	var buttons:FlxTypedGroup<PsychUIButton>;

	var methods:Array<{id:Int, title:String, desc:String}> = [
		{id: 1, title: "Standard BPM Changes", desc: "Convert tweens to regular BPM changes with smart splitting"},
		{id: 2, title: "HScript Generation", desc: "Generate HScript code for real-time BPM tweens"},
		{id: 3, title: "Lua Script Generation", desc: "Generate Lua script for Psych Engine compatibility"},
		{id: 4, title: "Custom Section Split", desc: "Split sections intelligently at meaningful BPM points"}
	];

	public function new(selectCallback:Int->Void, cancelCallback:Void->Void)
	{
		super();
		onSelect = selectCallback;
		onCancel = cancelCallback;

		// Background
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.7;
		add(bg);

		// Panel
		var panel = new FlxSprite().makeGraphic(600, 400, FlxColor.WHITE);
		panel.screenCenter();
		add(panel);

		var panelBorder = new FlxSprite().makeGraphic(610, 410, FlxColor.BLACK);
		panelBorder.screenCenter();
		panelBorder.x -= 5;
		panelBorder.y -= 5;
		insert(1, panelBorder);

		// Title
		titleText = new FlxText(0, 0, 580, "Choose BPM Tween Conversion Method", 20);
		titleText.setFormat(null, 20, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
		titleText.screenCenter(X);
		titleText.y = panel.y + 20;
		add(titleText);

		// Method buttons
		buttons = new FlxTypedGroup<PsychUIButton>();
		add(buttons);

		var startY = panel.y + 80;
		var buttonHeight = 60;
		var spacing = 10;

		for(i in 0...methods.length)
		{
			var method = methods[i];
			var yPos = startY + i * (buttonHeight + spacing);

			// Method button
			var btn = new PsychUIButton(0, yPos, method.title, function() {
				close();
				onSelect(method.id);
			});
			btn.setGraphicSize(500, buttonHeight);
			btn.updateHitbox();
			btn.screenCenter(X);

			// Style the button
			btn.normalStyle.bgColor = FlxColor.fromRGB(70, 130, 180);
			btn.normalStyle.textColor = FlxColor.WHITE;
			btn.hoverStyle.bgColor = FlxColor.fromRGB(100, 150, 200);
			btn.clickStyle.bgColor = FlxColor.fromRGB(50, 110, 160);

			buttons.add(btn);

			// Description text
			var desc = new FlxText(btn.x + 10, btn.y + 25, btn.width - 20, method.desc, 12);
			desc.setFormat(null, 12, FlxColor.WHITE, LEFT);
			add(desc);
		}

		// Cancel button
		var cancelBtn = new PsychUIButton(0, startY + methods.length * (buttonHeight + spacing) + 20, "Cancel", function() {
			close();
			onCancel();
		});
		cancelBtn.setGraphicSize(200, 40);
		cancelBtn.updateHitbox();
		cancelBtn.screenCenter(X);
		cancelBtn.normalStyle.bgColor = FlxColor.RED;
		cancelBtn.normalStyle.textColor = FlxColor.WHITE;
		cancelBtn.hoverStyle.bgColor = FlxColor.fromRGB(200, 50, 50);
		buttons.add(cancelBtn);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// ESC to cancel
		if(FlxG.keys.justPressed.ESCAPE)
		{
			close();
			onCancel();
		}

		// Number key shortcuts
		if(FlxG.keys.justPressed.ONE) { close(); onSelect(1); }
		else if(FlxG.keys.justPressed.TWO) { close(); onSelect(2); }
		else if(FlxG.keys.justPressed.THREE) { close(); onSelect(3); }
		else if(FlxG.keys.justPressed.FOUR) { close(); onSelect(4); }
	}
}
