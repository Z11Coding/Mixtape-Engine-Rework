package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxText;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxPoint;

class RTXEditor extends MusicBeatState {
	var sliders:Array<Dynamic>;
	var mouse:FlxSprite;
	var copyText:FlxText;
	var useEditor:Bool = true;
	var mouseWidth:Int = 10;
	var sliderWidth:Int = 100;
    var shader:RTX;

	public function new() {
		super();
	}

	override public function create() {
		super.create();
        shader = new RTX();
		createEditorHUD();
	}

	function createEditorHUD() {
		sliders = [
            { name: 'overlayR', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFFFF0000" },
            { name: 'overlayG', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFF00FF00" },
            { name: 'overlayB', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFF0000FF" },
            { name: 'overlayA', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFFAAAAAA" },
            { name: 'satinR', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFFFF0000" },
            { name: 'satinG', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFF00FF00" },
            { name: 'satinB', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFF0000FF" },
            { name: 'satinA', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFFAAAAAA" },
            { name: 'innerR', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFFFF0000" },
            { name: 'innerG', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFF00FF00" },
            { name: 'innerB', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFF0000FF" },
            { name: 'innerA', min: 0, max: 1, value: 0.5, step: 0.01, color: "0xFFAAAAAA" },
            { name: 'innerAngle', min: 0, max: 360, value: 0, step: 1, color: "0xFFAAAAAA" },
            { name: 'innerDistance', min: 0, max: 50, value: 20, step: 1, color: "0xFFCCCCCC" }
		];

		for (data in sliders) {
			var back:FlxSprite = new FlxSprite(data.x, data.y).makeGraphic(data.width, data.height, data.color);
			back.scrollFactor.set();
			add(back);

			var slider:FlxSprite = new FlxSprite(data.x, data.y - (data.height * 0.5)).makeGraphic(sliderWidth, data.height * 2, FlxColor.WHITE);
			slider.scrollFactor.set();
			add(slider);

			var text:FlxText = new FlxText(data.x, data.y - 20, data.width, "test");
			text.scrollFactor.set();
			add(text);

			data.back = back;
			data.slider = slider;
			data.text = text;
		}

		copyText = new FlxText(50, 650, 0, "Click Here to copy data to clipboard");
		copyText.scrollFactor.set();
		add(copyText);

		mouse = new FlxSprite(0, 0).makeGraphic(mouseWidth, mouseWidth, 0xFFAAAAAA);
		mouse.scrollFactor.set();
		add(mouse);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		if (useEditor) {
			updateEditor(elapsed);
		}
	}

	function updateEditor(elapsed:Float) {
		FlxG.camera.zoom = 1;

		var mouseX = FlxG.mouse.screenX;
		var mouseY = FlxG.mouse.screenY;
		var justClicked = FlxG.mouse.justPressed;
		var justReleased = FlxG.mouse.justReleased;
		var mousePressed = FlxG.mouse.pressed;

		mouse.setPosition(mouseX, mouseY);

		for (data in sliders) {
			data.slider.x = remapToRange(data.value, data.min, data.max, data.x, data.x + data.width);

			var overlapsSlider = pointOverlaps(data.slider, mouseX, mouseY);
			var overlapsBack = pointOverlaps(data.back, mouseX, mouseY);

			if (overlapsSlider || overlapsBack) {
				data.slider.color = 0xFFAAAAAA;
			} else {
				data.slider.color = 0xFFFFFFFF;
			}

			if ((overlapsSlider || overlapsBack) && justClicked) {
				data.dragging = true;
			} else if (justReleased) {
				data.dragging = false;
			}

			if (data.dragging) {
				var newPos = mouseX;
				if (mouseX <= data.x) {
					newPos = data.x;
				} else if (mouseX >= data.x + data.width) {
					newPos = data.x + data.width;
				}

				data.slider.x = newPos;
				data.value = remapToRange(newPos, data.x, data.x + data.width, data.min, data.max);
			}

			data.text.text = data.name + ": " + (Math.floor(data.value * 100) / 100);
		}

		if (pointOverlaps(copyText, mouseX, mouseY)) {
			copyText.color = 0xFFAAAAAA;

			if (justClicked) {
				var dataStr = "";
				for (data in sliders) {
					dataStr += data.value;
					if (data != sliders[sliders.length - 1]) {
						dataStr += ",";
					}
				}

				Clipboard.text = dataStr;
				FlxG.sound.play(Paths.sound("confirmMenu"));
			}
		} else {
			copyText.color = 0xFFFFFFFF;
		}

		updateShader();
	}

	function pointOverlaps(obj:FlxSprite, mouseX:Float, mouseY:Float):Bool {
		return (mouseX + mouseWidth > obj.x) && (mouseX < obj.x + obj.width) && (mouseY + mouseWidth > obj.y) && (mouseY < obj.y + obj.height);
	}

	function remapToRange(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float {
		return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1));
	}

	function updateShader() {
    shader.updateShader();
	}
}

