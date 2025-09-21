package archipelago;

import backend.MusicBeatState;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

class APItemsViewerState extends MusicBeatState {
    var AP:archipelago.Client;
    var gameState:archipelago.APGameState;

    var bg:FlxSprite;
    var apLogo:FlxSprite;
    var titleText:FlxText;
    var backText:FlxText;

    // Unauthorized access components
    var unauthorizedText:FlxText;
    var kickTimer:Float = 0;
    var isUnauthorized:Bool = false;

    // Stats display
    var statsGroup:FlxTypedGroup<FlxText>;
    var maxHPText:FlxText;
    var shieldsText:FlxText;
    var ticketsText:FlxText;

    // Items display
    var itemsGroup:FlxTypedGroup<FlxText>;
    var customItemsTitle:FlxText;
    var pendingItemsTitle:FlxText;

    var scrollOffset:Float = 0;
    var maxScrollOffset:Float = 0;

    // Data refresh tracking
    var lastMaxHP:Int = -1;
    var lastShields:Int = -1;
    var lastTickets:Int = -1;
    var lastActiveItems:Array<String> = [];
    var lastWaitingItems:Array<String> = [];

    public function new(gameState:archipelago.APGameState, ?AP:archipelago.Client) {
        super();
        this.gameState = gameState;
        this.AP = gameState.info();
    }

    override function create() {
        super.create();

        // Check if player has Pocket Lens before proceeding
        if (!archipelago.APItem.hasPocketLens) {
            setupUnauthorizedView();
            return;
        }

        setupAuthorizedView();
    }

    function setupUnauthorizedView() {
        isUnauthorized = true;

        // Background
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(bg);

        // Big red "Unavailable" text
        unauthorizedText = new FlxText(0, 0, FlxG.width, "UNAVAILABLE", 72);
        unauthorizedText.setFormat(Paths.font("vcr.ttf"), 72, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        unauthorizedText.borderSize = 4;
        unauthorizedText.screenCenter();
        unauthorizedText.y -= 50;
        add(unauthorizedText);

        // Explanation text
        var explanationText = new FlxText(0, unauthorizedText.y + 100, FlxG.width, "You need a Pocket Lens to view this information.\nReturning to title screen...", 24);
        explanationText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        explanationText.borderSize = 2;
        add(explanationText);

        // Start the kick timer
        kickTimer = 3.0; // 3 seconds before kicking to title screen
    }

    function setupAuthorizedView() {
        // Background
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xFF270138; // Purple tint like main menu
        bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        // AP Logo - using the same icon as APItem prompt
        apLogo = new FlxSprite();
        try {
            // Try to load the colored archipelago logo
            apLogo.loadGraphic(Paths.image('globalIcons/archColor'));
        } catch (e:haxe.Exception) {
            // Fallback to a basic logo if not found
            apLogo.makeGraphic(100, 100, FlxColor.CYAN);
        }
        apLogo.setGraphicSize(120, 120);
        apLogo.updateHitbox();
        apLogo.x = 50;
        apLogo.y = 50;
        add(apLogo);

        // Title
        titleText = new FlxText(180, 60, FlxG.width - 200, "Archipelago Items Viewer", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Back instruction
        backText = new FlxText(50, FlxG.height - 80, FlxG.width - 100, "Press ESCAPE or BACKSPACE to go back", 20);
        backText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.GRAY, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        backText.borderSize = 1;
        add(backText);

        // Initialize groups
        statsGroup = new FlxTypedGroup<FlxText>();
        add(statsGroup);

        itemsGroup = new FlxTypedGroup<FlxText>();
        add(itemsGroup);

        // Create initial display
        refreshData();
    }

    function refreshData() {
        // Clear existing items
        statsGroup.clear();
        itemsGroup.clear();

        var yPos:Float = 150;

        // Stats Section
        var statsTitle = new FlxText(50, yPos, FlxG.width - 100, "=== CURRENT STATS ===", 24);
        statsTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        statsTitle.borderSize = 1;
        statsGroup.add(statsTitle);
        yPos += 40;

        // Max HP
        maxHPText = new FlxText(70, yPos, FlxG.width - 140, "Max HP Upgrades: " + archipelago.APItem.maxHPUp, 18);
        maxHPText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        maxHPText.borderSize = 1;
        statsGroup.add(maxHPText);
        yPos += 25;

        // Shields
        shieldsText = new FlxText(70, yPos, FlxG.width - 140, "Shields: " + archipelago.APItem.shields, 18);
        shieldsText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        shieldsText.borderSize = 1;
        statsGroup.add(shieldsText);
        yPos += 25;

        // Tickets
        ticketsText = new FlxText(70, yPos, FlxG.width - 140, "Tickets: " + archipelago.APInfo.ticketCount, 18);
        ticketsText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        ticketsText.borderSize = 1;
        statsGroup.add(ticketsText);
        yPos += 50;

        // Active Items Section
        var activeTitle = new FlxText(50, yPos, FlxG.width - 100, "=== ACTIVE ITEMS ===", 24);
        activeTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.GREEN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        activeTitle.borderSize = 1;
        itemsGroup.add(activeTitle);
        yPos += 40;

        // Get active items
        var activeItems = archipelago.APItem.getItems();
        if (activeItems.length > 0) {
            for (item in activeItems) {
                var itemText = new FlxText(70, yPos, FlxG.width - 140, "• " + item.name, 16);
                itemText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.LIME, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                itemText.borderSize = 1;
                itemsGroup.add(itemText);
                yPos += 22;
            }
        } else {
            var noItemsText = new FlxText(70, yPos, FlxG.width - 140, "No active items", 16);
            noItemsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            noItemsText.borderSize = 1;
            itemsGroup.add(noItemsText);
            yPos += 22;
        }

        yPos += 30;

        // Pending Items Section
        pendingItemsTitle = new FlxText(50, yPos, FlxG.width - 100, "=== PENDING ITEMS ===", 24);
        pendingItemsTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.YELLOW, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        pendingItemsTitle.borderSize = 1;
        itemsGroup.add(pendingItemsTitle);
        yPos += 40;

        // Get pending items (these would be items that haven't been triggered yet)
        var pendingCount = 0;
        if (archipelago.APItem.activeItem != null) {
            var pendingText = new FlxText(70, yPos, FlxG.width - 140, "• " + archipelago.APItem.activeItem.name + " (Ready to trigger)", 16);
            pendingText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.ORANGE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            pendingText.borderSize = 1;
            itemsGroup.add(pendingText);
            yPos += 22;
            pendingCount++;
        }

        if (pendingCount == 0) {
            var noPendingText = new FlxText(70, yPos, FlxG.width - 140, "No pending items", 16);
            noPendingText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            noPendingText.borderSize = 1;
            itemsGroup.add(noPendingText);
            yPos += 22;
        }

        // Calculate max scroll offset
        maxScrollOffset = Math.max(0, yPos - (FlxG.height - 100));

        // Update last known values for change detection
        lastMaxHP = archipelago.APItem.maxHPUp;
        lastShields = archipelago.APItem.shields;
        lastTickets = archipelago.APInfo.ticketCount;
        lastActiveItems = [for (item in activeItems) item.name];
        // Note: lastWaitingItems would need to be implemented based on your AP system's pending items
    }

    function checkForChanges():Bool {
        // Check if any values have changed
        if (lastMaxHP != archipelago.APItem.maxHPUp) return true;
        if (lastShields != archipelago.APItem.shields) return true;
        if (lastTickets != archipelago.APInfo.ticketCount) return true;

        var currentActiveItems = [for (item in archipelago.APItem.getItems()) item.name];
        if (currentActiveItems.length != lastActiveItems.length) return true;

        for (i in 0...currentActiveItems.length) {
            if (i >= lastActiveItems.length || currentActiveItems[i] != lastActiveItems[i]) {
                return true;
            }
        }

        return false;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle unauthorized access
        if (isUnauthorized) {
            kickTimer -= elapsed;
            if (kickTimer <= 0) {
                // Kick to title screen
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new states.TitleState());
            }
            return;
        }

        // Check for changes every 0.5 seconds and refresh if needed
        if (FlxG.game.ticks % 30 == 0 && checkForChanges()) {
            refreshData();
        }

        // Handle scrolling
        var scrollSpeed:Float = 300;
        if (controls.UI_UP || controls.UI_UP_P) {
            scrollOffset = Math.max(0, scrollOffset - scrollSpeed * elapsed);
        }
        if (controls.UI_DOWN || controls.UI_DOWN_P) {
            scrollOffset = Math.min(maxScrollOffset, scrollOffset + scrollSpeed * elapsed);
        }

        // Apply scroll offset to groups
        if (statsGroup != null) {
            statsGroup.forEach(function(text:FlxText) {
                text.y -= scrollOffset - (scrollOffset * 0.1); // Slightly slower scroll for parallax effect
            });
        }
        if (itemsGroup != null) {
            itemsGroup.forEach(function(text:FlxText) {
                text.y -= scrollOffset;
            });
        }

        // Handle back navigation
        if (controls.BACK || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new archipelago.APCategoryState(gameState, AP));
        }

        // Poll AP for updates
        if (AP != null) {
            AP.poll();
        }
    }
}
