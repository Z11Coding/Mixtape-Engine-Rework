package archipelago.substates;

import archipelago.PlandoData;
import archipelago.PlandoData.PlandoBlock;
import backend.Controls;
import backend.MusicBeatSubstate;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Substate for managing Plando Blocks (location -> item assignments)
 * Full-screen UI with ADD, EDIT, DELETE block buttons
 */
class APPlandoBlocksSubstate extends MusicBeatSubstate
{
	private var blocks:Array<PlandoBlock> = [];
	private var plandoData:PlandoData;
	private var blockButtons:Array<BlockDisplayButton> = [];
	private var hoveredIndex:Int = -1;
	private var selectedIndex:Int = -1;

	private var background:FlxSprite;
	private var titleText:FlxText;
	private var selectedDisplay:FlxText;
	private var instructionText:FlxText;

	private static inline var BLOCK_BUTTON_HEIGHT:Float = 50;
	private static inline var BLOCK_BUTTON_WIDTH:Float = 600;
	private static inline var BLOCK_START_Y:Float = 150;
	private static inline var BLOCK_SPACING:Float = 60;

	public function new(plandoData:PlandoData, ?startingBlocks:Array<PlandoBlock>)
	{
		super();
		this.plandoData = plandoData;
		if (startingBlocks != null)
			blocks = startingBlocks.copy();
	}

	override function create()
	{
		super.create();

		// Full-screen semi-transparent background
		background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.alpha = 0.75;
		add(background);

		// Title
		titleText = new FlxText(20, 15, FlxG.width - 40, "PLANDO BLOCKS: LOCATION -> ITEM ASSIGNMENTS");
		titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		// Instructions
		instructionText = new FlxText(20, 60, FlxG.width - 40,
			"Arrow Keys: Navigate | A: Add Block | E: Edit Block | D: Delete Block | Z/ENTER: Confirm | ESC/X: Cancel");
		instructionText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, CENTER);
		add(instructionText);

		// Create block display buttons
		createBlockButtons();

		// Selected count display
		selectedDisplay = new FlxText(20, FlxG.height - 100, FlxG.width - 40, "Defined Blocks: 0");
		selectedDisplay.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.LIME, LEFT, OUTLINE, FlxColor.BLACK);
		selectedDisplay.borderSize = 1;
		add(selectedDisplay);

		updateSelectedDisplay();
	}

	private function createBlockButtons():Void
	{
		// Clear existing buttons
		for (button in blockButtons)
		{
			if (button != null && button.exists)
				remove(button);
		}
		blockButtons = [];

		var yPos = BLOCK_START_Y;

		for (i in 0...blocks.length)
		{
			var block = blocks[i];
			var button = new BlockDisplayButton(40, yPos, BLOCK_BUTTON_WIDTH, BLOCK_BUTTON_HEIGHT, block, i);
			add(button);
			blockButtons.push(button);
			yPos += BLOCK_SPACING;
		}
	}

	private function updateSelectedDisplay():Void
	{
		selectedDisplay.text = "Defined Blocks: " + blocks.length;
	}

	private function updateButtonVisuals():Void
	{
		for (i in 0...blockButtons.length)
		{
			var button = blockButtons[i];
			var isSelected = (i == selectedIndex);
			var isHovered = (i == hoveredIndex);

			button.setSelected(isSelected);
			button.setHovered(isHovered);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		handleKeyboardInput();
		handleMouseInput();
		updateButtonVisuals();
	}

	private function handleKeyboardInput():Void
	{
		// Arrow navigation
		if (controls.pressed('ui_up'))
		{
			selectedIndex = Std.int(Math.max(-1, selectedIndex - 1));
			if (selectedIndex >= 0)
				hoveredIndex = selectedIndex;
		}
		else if (controls.pressed('ui_down'))
		{
			selectedIndex = Std.int(Math.min(blocks.length - 1, selectedIndex + 1));
			if (selectedIndex >= 0)
				hoveredIndex = selectedIndex;
		}

		// Initialize selection
		if (selectedIndex < 0 && blocks.length > 0)
			selectedIndex = 0;

		// Add block with A
		if (FlxG.keys.justPressed.A)
		{
			addNewBlock();
		}

		// Edit block with E
		if (FlxG.keys.justPressed.E && selectedIndex >= 0 && selectedIndex < blocks.length)
		{
			editBlock(selectedIndex);
		}

		// Delete block with D
		if (FlxG.keys.justPressed.D && selectedIndex >= 0 && selectedIndex < blocks.length)
		{
			deleteBlock(selectedIndex);
		}

		// Confirm
		if (FlxG.keys.justPressed.Z || FlxG.keys.justPressed.ENTER)
		{
			onConfirm();
		}

		// Cancel
		if (controls.justPressed('back'))
		{
			close();
		}
	}

	private function handleMouseInput():Void
	{
		hoveredIndex = -1;

		for (i in 0...blockButtons.length)
		{
			var button = blockButtons[i];
			if (button.overlapsPoint(FlxG.mouse.getWorldPosition()))
			{
				hoveredIndex = i;

				if (FlxG.mouse.justPressed)
				{
					selectedIndex = i;
				}
				else if (FlxG.mouse.justPressedRight)
				{
					editBlock(i);
				}
			}
		}
	}

	private function addNewBlock():Void
	{
		var newBlock = new PlandoBlock();
		newBlock.location = "";
		newBlock.item = "";
		newBlock.player = "";
		blocks.push(newBlock);
		selectedIndex = blocks.length - 1;

		// Open editor
		openSubState(new APPlandoBlockEditorSubstate(newBlock, (_) -> {
			createBlockButtons();
			updateSelectedDisplay();
		}));
	}

	private function editBlock(index:Int):Void
	{
		if (index >= 0 && index < blocks.length)
		{
			var block = blocks[index];
			openSubState(new APPlandoBlockEditorSubstate(block, (_) -> {
				createBlockButtons();
				updateSelectedDisplay();
			}));
		}
	}

	private function deleteBlock(index:Int):Void
	{
		if (index >= 0 && index < blocks.length)
		{
			blocks.splice(index, 1);
			if (selectedIndex >= blocks.length && selectedIndex > 0)
				selectedIndex--;

			createBlockButtons();
			updateSelectedDisplay();
		}
	}

	private function onConfirm():Void
	{
		plandoData.plandoBlocks = blocks.copy();
		close();
	}
}

/**
 * Helper class for displaying a single plando block button
 */
class BlockDisplayButton extends FlxSprite
{
	private var block:PlandoBlock;
	private var blockIndex:Int;
	private var blockLabel:FlxText;
	private var isSelected:Bool = false;
	private var isHovered:Bool = false;

	public function new(x:Float, y:Float, width:Float, height:Float, block:PlandoBlock, index:Int)
	{
		super(x, y);

		this.block = block;
		this.blockIndex = index;

		makeGraphic(Std.int(width), Std.int(height), FlxColor.fromRGB(80, 80, 80));

		var displayText = block.location + " -> " + block.item;
		if (block.player != null && block.player.length > 0)
			displayText += " (Player: " + block.player + ")";

		blockLabel = new FlxText(0, 0, width - 10, displayText);
		blockLabel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		blockLabel.borderSize = 1;
		blockLabel.x = x + 10;
		blockLabel.y = y + Std.int(Math.max(5, (height - blockLabel.height) / 2));
	}

	public function setSelected(selected:Bool):Void
	{
		isSelected = selected;
		updateColor();
	}

	public function setHovered(hovered:Bool):Void
	{
		isHovered = hovered;
		updateColor();
	}

	private function updateColor():Void
	{
		if (isSelected)
		{
			color = FlxColor.GREEN;
		}
		else if (isHovered)
		{
			color = FlxColor.YELLOW;
		}
		else
		{
			color = FlxColor.fromRGB(80, 80, 80);
		}
	}

	override function draw()
	{
		super.draw();
		if (blockLabel != null)
		{
			blockLabel.draw();
		}
	}
}

/**
 * Editor substate for creating/editing plando blocks
 */
class APPlandoBlockEditorSubstate extends MusicBeatSubstate
{
	private var block:PlandoBlock;
	private var onComplete:(PlandoBlock) -> Void;

	private var currentField:Int = 0; // 0 = location, 1 = item, 2 = player
	private var locationText:FlxText;
	private var itemText:FlxText;
	private var playerText:FlxText;

	private static inline var INPUT_Y_START:Float = 150;
	private static inline var INPUT_Y_SPACING:Float = 100;
	private static inline var INPUT_WIDTH:Float = 600;

	public function new(block:PlandoBlock, onComplete:(PlandoBlock) -> Void)
	{
		super();
		this.block = block;
		this.onComplete = onComplete;
	}

	override function create()
	{
		super.create();

		// Background
		var bg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.85;
		add(bg);

		// Title
		var titleText = new FlxText(20, 20, FlxG.width - 40, "EDIT PLANDO BLOCK");
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		// Location label
		var locLabel = new FlxText(40, INPUT_Y_START, 200, "LOCATION NAME:");
		locLabel.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		add(locLabel);

		// Location input
		locationText = new FlxText(40, INPUT_Y_START + 35, INPUT_WIDTH, block.location != null ? block.location : "");
		locationText.setFormat(Paths.font("vcr.ttf"), 20, currentField == 0 ? FlxColor.YELLOW : FlxColor.LIME, LEFT, OUTLINE, FlxColor.BLACK);
		locationText.borderSize = 2;
		add(locationText);

		// Item label
		var itemLabel = new FlxText(40, INPUT_Y_START + INPUT_Y_SPACING, 200, "ITEM NAME:");
		itemLabel.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		add(itemLabel);

		// Item input
		itemText = new FlxText(40, INPUT_Y_START + INPUT_Y_SPACING + 35, INPUT_WIDTH, block.item != null ? block.item : "");
		itemText.setFormat(Paths.font("vcr.ttf"), 20, currentField == 1 ? FlxColor.YELLOW : FlxColor.LIME, LEFT, OUTLINE, FlxColor.BLACK);
		itemText.borderSize = 2;
		add(itemText);

		// Player label
		var playerLabel = new FlxText(40, INPUT_Y_START + (INPUT_Y_SPACING * 2), 200, "PLAYER NUMBER (optional):");
		playerLabel.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		add(playerLabel);

		// Player input
		playerText = new FlxText(40, INPUT_Y_START + (INPUT_Y_SPACING * 2) + 35, INPUT_WIDTH, block.player != null ? block.player : "");
		playerText.setFormat(Paths.font("vcr.ttf"), 20, currentField == 2 ? FlxColor.YELLOW : FlxColor.LIME, LEFT, OUTLINE, FlxColor.BLACK);
		playerText.borderSize = 2;
		add(playerText);

		// Instructions
		var instrText = new FlxText(20, FlxG.height - 80, FlxG.width - 40,
			"TAB: Switch Field | Type: Edit | Z/ENTER: Save | ESC/X: Cancel");
		instrText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.YELLOW, CENTER);
		add(instrText);

		updateFieldVisuals();
	}

	private function updateFieldVisuals():Void
	{
		locationText.color = currentField == 0 ? FlxColor.YELLOW : FlxColor.LIME;
		itemText.color = currentField == 1 ? FlxColor.YELLOW : FlxColor.LIME;
		playerText.color = currentField == 2 ? FlxColor.YELLOW : FlxColor.LIME;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Tab to switch fields
		if (FlxG.keys.justPressed.TAB)
		{
			currentField = (currentField + 1) % 3;
			updateFieldVisuals();
		}

		// Shift+Tab to go back
		if (FlxG.keys.justPressed.SHIFT)
		{
			currentField = (currentField - 1 + 3) % 3;
			updateFieldVisuals();
		}

		// Type to edit (simplified - just allow basic input)
		handleTextInput();

		// Confirm
		if (FlxG.keys.justPressed.Z || FlxG.keys.justPressed.ENTER)
		{
			block.location = locationText.text;
			block.item = itemText.text;
			block.player = playerText.text;

			if (onComplete != null)
				onComplete(block);
			close();
		}

		// Cancel
		if (controls.justPressed('back'))
		{
			close();
		}
	}

	private function handleTextInput():Void
	{
		var currentField = this.currentField == 0 ? locationText : (this.currentField == 1 ? itemText : playerText);

		// Handle backspace
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			var text = currentField.text;
			if (text.length > 0)
				currentField.text = text.substring(0, text.length - 1);
		}

		// Handle character input (simplified)
		var inputChar = FlxG.keys.getIsDown();
		// This is a simplified version - in production, you'd want proper text input handling
	}
}
