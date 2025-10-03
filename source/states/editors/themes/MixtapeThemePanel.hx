package states.editors.themes;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

/**
 * Base class for all Mixtape Theme panels
 * Provides dragging, resizing, and common panel functionality
 */
class MixtapeThemePanel extends FlxGroup
{
    public var panelBg:FlxSprite;
    public var titleBar:FlxSprite;
    public var titleText:FlxText;
    public var contentArea:FlxGroup;

    public var panelWidth:Float;
    public var panelHeight:Float;
    public var panelX:Float;
    public var panelY:Float;

    public var isDragging:Bool = false;
    public var isResizing:Bool = false;
    public var dragOffsetX:Float = 0;
    public var dragOffsetY:Float = 0;

    public var theme:MixtapeChartTheme;
    public var panelTitle:String;

    // Animation properties
    public var animationProgress:Float = 0;
    public var isAnimatingIn:Bool = false;

    public function new(x:Float, y:Float, width:Float, height:Float, title:String, theme:MixtapeChartTheme)
    {
        super();

        this.panelX = x;
        this.panelY = y;
        this.panelWidth = width;
        this.panelHeight = height;
        this.panelTitle = title;
        this.theme = theme;

        createPanel();
        createTitleBar();
        createContentArea();

        // Start with invisible for animation
        panelBg.alpha = 0;
        animateIn();
    }

    function createPanel():Void
    {
        // Create gradient background for panel
        panelBg = FlxGradient.createGradientFlxSprite(
            Std.int(panelWidth),
            Std.int(panelHeight),
            [FlxColor.fromRGB(
                Std.int(MixtapeChartTheme.panelBg.red * 1.2),
                Std.int(MixtapeChartTheme.panelBg.green * 1.2),
                Std.int(MixtapeChartTheme.panelBg.blue * 1.2)
            ), MixtapeChartTheme.panelBg],
            1,
            90
        );
        panelBg.setPosition(panelX, panelY);

        // Add subtle border
        var border = new FlxSprite(panelX - 2, panelY - 2);
        border.makeGraphic(Std.int(panelWidth + 4), Std.int(panelHeight + 4), MixtapeChartTheme.primaryColor);
        border.alpha = 0.6;
        add(border);

        add(panelBg);
    }

    function createTitleBar():Void
    {
        // Title bar with accent color
        titleBar = new FlxSprite(panelX, panelY);
        titleBar.makeGraphic(Std.int(panelWidth), 30, MixtapeChartTheme.primaryColor);
        add(titleBar);

        // Title text
        titleText = new FlxText(panelX + 10, panelY + 5, panelWidth - 20, panelTitle, 12);
        titleText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT);
        titleText.borderStyle = OUTLINE;
        titleText.borderColor = FlxColor.BLACK;
        add(titleText);

        // Close button (optional)
        var closeBtn = new FlxSprite(panelX + panelWidth - 25, panelY + 5);
        closeBtn.makeGraphic(20, 20, MixtapeChartTheme.accentColor);
        add(closeBtn);

        var closeText = new FlxText(closeBtn.x, closeBtn.y, 20, "×", 16);
        closeText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        closeText.borderStyle = OUTLINE;
        closeText.borderColor = FlxColor.BLACK;
        add(closeText);
    }

    function createContentArea():Void
    {
        contentArea = new FlxGroup();
        add(contentArea);
    }

    public function makeDraggable():Void
    {
        // This will be handled in the update function
    }

    function animateIn():Void
    {
        isAnimatingIn = true;
        panelBg.alpha = 0;
        panelBg.y -= 20;

        FlxTween.tween(panelBg, {alpha: 1, y: panelY}, MixtapeChartTheme.ANIMATION_DURATION, {
            ease: FlxEase.backOut,
            onComplete: function(_) {
                isAnimatingIn = false;
                animationProgress = 1.0;
            }
        });

        // Stagger animation for visual elements
        for (i in 0...members.length)
        {
            var member = members[i];
            if (member != null && Std.isOfType(member, FlxSprite))
            {
                var sprite:FlxSprite = cast member;
                sprite.alpha = 0;
                FlxTween.tween(sprite, {alpha: 1}, MixtapeChartTheme.ANIMATION_DURATION * 0.8, {
                    ease: FlxEase.sineOut,
                    startDelay: i * 0.1
                });
            }
        }
    }

    public function updatePanel(elapsed:Float):Void
    {
        handleDragging();
        handleResizing();
        updateAnimations(elapsed);
    }

    function handleDragging():Void
    {
        // Check if mouse is over title bar
        if (FlxG.mouse.overlaps(titleBar) && FlxG.mouse.justPressed)
        {
            isDragging = true;
            dragOffsetX = FlxG.mouse.x - panelX;
            dragOffsetY = FlxG.mouse.y - panelY;
        }

        if (isDragging)
        {
            if (FlxG.mouse.pressed)
            {
                // Update position
                panelX = FlxG.mouse.x - dragOffsetX;
                panelY = FlxG.mouse.y - dragOffsetY;

                // Constrain to screen bounds
                panelX = FlxMath.bound(panelX, 0, FlxG.width - panelWidth);
                panelY = FlxMath.bound(panelY, 0, FlxG.height - panelHeight);

                updatePositions();
            }
            else
            {
                isDragging = false;
                // Save new position to layout config
                savePanelPosition();
            }
        }
    }

    function handleResizing():Void
    {
        // Simple resize handle in bottom-right corner
        var resizeArea = 15;
        var resizeX = panelX + panelWidth - resizeArea;
        var resizeY = panelY + panelHeight - resizeArea;

        if (FlxG.mouse.x >= resizeX && FlxG.mouse.x <= resizeX + resizeArea &&
            FlxG.mouse.y >= resizeY && FlxG.mouse.y <= resizeY + resizeArea)
        {
            // Change cursor visual indicator (would need custom cursor)
            if (FlxG.mouse.justPressed)
            {
                isResizing = true;
            }
        }

        if (isResizing)
        {
            if (FlxG.mouse.pressed)
            {
                // Update size
                panelWidth = Math.max(200, FlxG.mouse.x - panelX);
                panelHeight = Math.max(150, FlxG.mouse.y - panelY);

                // Recreate panel with new size
                recreatePanel();
            }
            else
            {
                isResizing = false;
                savePanelSize();
            }
        }
    }

    function updateAnimations(elapsed:Float):Void
    {
        // Override in subclasses for custom animations
    }

    function updatePositions():Void
    {
        // Update all child positions
        for (member in members)
        {
            if (member == panelBg && Std.isOfType(member, FlxSprite))
            {
                var sprite:FlxSprite = cast member;
                sprite.setPosition(panelX, panelY);
            }
            else if (member == titleBar && Std.isOfType(member, FlxSprite))
            {
                var sprite:FlxSprite = cast member;
                sprite.setPosition(panelX, panelY);
            }
            else if (member == titleText && Std.isOfType(member, FlxText))
            {
                var text:FlxText = cast member;
                text.setPosition(panelX + 10, panelY + 5);
            }
        }
    }

    function recreatePanel():Void
    {
        // Remove old panel elements
        remove(panelBg);
        remove(titleBar);

        // Recreate with new size
        createPanel();
        createTitleBar();

        updateContentLayout();
    }

    function updateContentLayout():Void
    {
        // Override in subclasses to handle content repositioning
    }

    function savePanelPosition():Void
    {
        // This would save to the theme's layout config
        // Implementation depends on panel type
    }

    function savePanelSize():Void
    {
        // This would save to the theme's layout config
        // Implementation depends on panel type
    }

    public function refreshData():Void
    {
        // Override in subclasses to update panel content
    }
}
