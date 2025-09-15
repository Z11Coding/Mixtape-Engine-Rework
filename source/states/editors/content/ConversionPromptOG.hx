package states.editors.content;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class ConversionPromptOG extends MusicBeatSubstate
{
	var onSelect:Int->Void;
	var onCancel:Void->Void;

	var bg:FlxSprite;
	var titleText:FlxText;
	var buttons:FlxTypedGroup<FlxButton>;

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
		var panel = new FlxSprite().makeGraphic(600, 420, FlxColor.WHITE);
		panel.screenCenter();
		add(panel);

		var panelBorder = new FlxSprite().makeGraphic(610, 430, FlxColor.BLACK);
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

		// Instructions
		var instructText = new FlxText(0, 0, 580, "Press 1-4 or click to select method", 14);
		instructText.setFormat(null, 14, FlxColor.GRAY, CENTER);
		instructText.screenCenter(X);
		instructText.y = panel.y + 50;
		add(instructText);

		// Method buttons
		buttons = new FlxTypedGroup<FlxButton>();
		add(buttons);

		var startY = panel.y + 80;
		var buttonHeight = 65;
		var spacing = 8;

		for(i in 0...methods.length)
		{
			var method = methods[i];
			var yPos = startY + i * (buttonHeight + spacing);

			// Method button
			var btn = new FlxButton(0, yPos, method.title, function() {
				close();
				onSelect(method.id);
			});
			btn.setGraphicSize(520, buttonHeight);
			btn.updateHitbox();
			btn.screenCenter(X);

			// Style the button
			btn.color = FlxColor.fromRGB(70, 130, 180);
			btn.label.color = FlxColor.WHITE;
			btn.label.size = 14;

			buttons.add(btn);

			// Number label
			var numberLabel = new FlxText(btn.x + 10, btn.y + 10, 30, Std.string(method.id), 16);
			numberLabel.setFormat(null, 16, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
			add(numberLabel);

			// Description text
			var desc = new FlxText(btn.x + 50, btn.y + 35, btn.width - 60, method.desc, 11);
			desc.setFormat(null, 11, FlxColor.WHITE, LEFT);
			add(desc);
		}

		// Cancel button
		var cancelBtn = new FlxButton(0, startY + methods.length * (buttonHeight + spacing) + 15, "Cancel (ESC)", function() {
			close();
			onCancel();
		});
		cancelBtn.setGraphicSize(200, 40);
		cancelBtn.updateHitbox();
		cancelBtn.screenCenter(X);
		cancelBtn.color = FlxColor.RED;
		cancelBtn.label.color = FlxColor.WHITE;
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
