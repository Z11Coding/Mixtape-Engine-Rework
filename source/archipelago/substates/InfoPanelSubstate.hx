package archipelago.substates;

import backend.MusicBeatSubstate;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;

/**
 * A substate that displays info panels as overlays with support for large text,
 * scrolling, pagination, and dynamic resizing
 */
class InfoPanelSubstate extends MusicBeatSubstate {
    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var infoText:FlxText;
    var closeButton:FlxSprite;
    var closeButtonText:FlxText;

    // Navigation elements
    var prevButton:FlxSprite;
    var nextButton:FlxSprite;
    var prevButtonText:FlxText;
    var nextButtonText:FlxText;
    var pageInfo:FlxText;

    // Scrolling elements
    var scrollUpButton:FlxSprite;
    var scrollDownButton:FlxSprite;
    var scrollUpText:FlxText;
    var scrollDownText:FlxText;
    var scrollIndicator:FlxSprite;

    var isAnimating:Bool = false;
    var onCloseCallback:Void->Void;

    // Content management
    var fullContent:String;
    var contentPages:Array<String> = [];
    var currentPage:Int = 0;
    var currentScrollOffset:Float = 0;
    var maxScrollOffset:Float = 0;

    // Dynamic sizing
    var panelWidth:Int;
    var panelHeight:Int;
    var themeColor:FlxColor;
    var maxContentHeight:Int;

    // Constants
    static inline var MIN_WIDTH:Int = 400;
    static inline var MIN_HEIGHT:Int = 300;
    static inline var MAX_WIDTH:Int = 800;
    static inline var MAX_HEIGHT:Int = 600;
    static inline var LINES_PER_PAGE:Int = 20;
    static inline var SCROLL_SPEED:Float = 20;

    public function new(title:String, content:String, ?themeColor:FlxColor, ?onClose:Void->Void) {
        super();

        if (themeColor == null) themeColor = FlxColor.CYAN;
        this.themeColor = themeColor;
        this.onCloseCallback = onClose;
        this.fullContent = content;

        calculateOptimalSize(title, content);
        processContent(content);
        setupBackground();
        setupPanel(title);
        animateIn();
    }

    public static function show(title:String, content:String, ?themeColor:FlxColor, ?onClose:Void->Void) {
        FlxG.state.openSubState(new InfoPanelSubstate(title, content, themeColor, onClose));
    }

    function calculateOptimalSize(title:String, content:String):Void {
        // Create temporary text objects to measure content
        var tempTitle = new FlxText(0, 0, 0, title, 24);
        tempTitle.setFormat(Paths.font("vcr.ttf"), 24);

        var tempContent = new FlxText(0, 0, 0, content, 14);
        tempContent.setFormat(Paths.font("vcr.ttf"), 14);

        // Calculate required width
        var titleWidth = Math.ceil(tempTitle.textField.textWidth) + 40;
        var contentWidth = Math.ceil(tempContent.textField.textWidth);

        // Estimate content width based on longest line
        var lines = content.split('\n');
        var maxLineLength = 0;
        for (line in lines) {
            if (line.length > maxLineLength) maxLineLength = line.length;
        }

        // Use character-based estimation for better width calculation
        contentWidth = Math.ceil(maxLineLength * 8) + 40; // Approximate character width

        panelWidth = Std.int(Math.max(Math.max(titleWidth, contentWidth), MIN_WIDTH));
        panelWidth = Std.int(Math.min(panelWidth, MAX_WIDTH));

        // Calculate required height
        var lineCount = lines.length;
        var estimatedContentHeight = lineCount * 18; // Approximate line height

        panelHeight = Std.int(Math.max(estimatedContentHeight + 120, MIN_HEIGHT)); // +120 for title, buttons, padding
        panelHeight = Std.int(Math.min(panelHeight, MAX_HEIGHT));

        maxContentHeight = panelHeight - 120; // Reserve space for UI elements

        tempTitle.destroy();
        tempContent.destroy();
    }

    function processContent(content:String):Void {
        var lines = content.split('\n');

        // If content fits in one page, don't paginate
        if (lines.length <= LINES_PER_PAGE) {
            contentPages = [content];
            return;
        }

        // Split into pages
        contentPages = [];
        var currentPageLines:Array<String> = [];

        for (line in lines) {
            currentPageLines.push(line);

            if (currentPageLines.length >= LINES_PER_PAGE) {
                contentPages.push(currentPageLines.join('\n'));
                currentPageLines = [];
            }
        }

        // Add remaining lines as last page
        if (currentPageLines.length > 0) {
            contentPages.push(currentPageLines.join('\n'));
        }
    }

    function setupBackground() {
        // Semi-transparent background that covers the entire screen
        background = new FlxSprite(0, 0);
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
        add(background);
    }

    function setupPanel(title:String) {
        // Main info panel with gradient
        panel = FlxGradient.createGradientFlxSprite(panelWidth, panelHeight,
            [FlxColor.fromRGB(30, 30, 50), FlxColor.fromRGB(20, 20, 40)], 1, 90);
        panel.x = (FlxG.width - panelWidth) / 2;
        panel.y = (FlxG.height - panelHeight) / 2;
        add(panel);

        // Title
        titleText = new FlxText(panel.x + 20, panel.y + 20, panelWidth - 40, title, 24);
        titleText.setFormat(Paths.font("vcr.ttf"), 24, themeColor, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        setupContentArea();
        setupNavigationButtons();
        setupScrollButtons();
        updateContentDisplay();
    }

    function setupContentArea():Void {
        // Content area with scrolling support
        var contentY = panel.y + 60;
        var contentHeight = maxContentHeight;

        infoText = new FlxText(panel.x + 20, contentY, panelWidth - 60, "", 14);
        infoText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        infoText.borderSize = 1;
        add(infoText);
    }

    function setupNavigationButtons():Void {
        var buttonY = panel.y + panelHeight - 50;

        // Previous page button
        prevButton = new FlxSprite(panel.x + 20, buttonY);
        prevButton.makeGraphic(60, 30, themeColor);
        add(prevButton);

        prevButtonText = new FlxText(prevButton.x, prevButton.y + 5, prevButton.width, "PREV", 12);
        prevButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
        prevButtonText.borderSize = 1;
        add(prevButtonText);

        // Next page button
        nextButton = new FlxSprite(panel.x + 90, buttonY);
        nextButton.makeGraphic(60, 30, themeColor);
        add(nextButton);

        nextButtonText = new FlxText(nextButton.x, nextButton.y + 5, nextButton.width, "NEXT", 12);
        nextButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
        nextButtonText.borderSize = 1;
        add(nextButtonText);

        // Page info
        pageInfo = new FlxText(panel.x + 160, buttonY + 5, 120, "", 12);
        pageInfo.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        pageInfo.borderSize = 1;
        add(pageInfo);

        // Close button
        closeButton = new FlxSprite(panel.x + panelWidth - 80, buttonY);
        closeButton.makeGraphic(60, 30, themeColor);
        add(closeButton);

        closeButtonText = new FlxText(closeButton.x, closeButton.y + 5, closeButton.width, "CLOSE", 12);
        closeButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
        closeButtonText.borderSize = 1;
        add(closeButtonText);
    }

    function setupScrollButtons():Void {
        var scrollX = panel.x + panelWidth - 40;
        var scrollStartY = panel.y + 60;

        // Scroll up button
        scrollUpButton = new FlxSprite(scrollX, scrollStartY);
        scrollUpButton.makeGraphic(20, 20, themeColor);
        add(scrollUpButton);

        scrollUpText = new FlxText(scrollUpButton.x, scrollUpButton.y + 2, scrollUpButton.width, "↑", 12);
        scrollUpText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, CENTER);
        add(scrollUpText);

        // Scroll down button
        scrollDownButton = new FlxSprite(scrollX, panel.y + panelHeight - 90);
        scrollDownButton.makeGraphic(20, 20, themeColor);
        add(scrollDownButton);

        scrollDownText = new FlxText(scrollDownButton.x, scrollDownButton.y + 2, scrollDownButton.width, "↓", 12);
        scrollDownText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, CENTER);
        add(scrollDownText);

        // Scroll indicator
        scrollIndicator = new FlxSprite(scrollX + 2, scrollStartY + 25);
        scrollIndicator.makeGraphic(16, 10, FlxColor.YELLOW);
        add(scrollIndicator);
    }

    function getCurrentPageContent():String {
        if (contentPages.length == 0) return "";
        return contentPages[currentPage];
    }

    function updateContentDisplay():Void {
        infoText.text = getCurrentPageContent();
        infoText.y = panel.y + 60 - currentScrollOffset;

        // Recalculate max scroll offset for current page content
        var tempText = new FlxText(0, 0, panelWidth - 60, getCurrentPageContent(), 14);
        tempText.setFormat(Paths.font("vcr.ttf"), 14);
        maxScrollOffset = Math.max(0, tempText.textField.textHeight - maxContentHeight);
        tempText.destroy();

        // Update page info
        if (contentPages.length > 1) {
            pageInfo.text = '${currentPage + 1}/${contentPages.length}';
        } else {
            pageInfo.text = "";
        }

        // Update button visibility
        prevButton.visible = prevButtonText.visible = (contentPages.length > 1 && currentPage > 0);
        nextButton.visible = nextButtonText.visible = (contentPages.length > 1 && currentPage < contentPages.length - 1);

        // Update scroll elements visibility
        var needsScrolling = maxScrollOffset > 0;
        scrollUpButton.visible = scrollUpText.visible = needsScrolling;
        scrollDownButton.visible = scrollDownText.visible = needsScrolling;
        scrollIndicator.visible = needsScrolling;

        if (needsScrolling) {
            // Update scroll indicator position
            var scrollRatio = currentScrollOffset / maxScrollOffset;
            var indicatorRange = (scrollDownButton.y - scrollUpButton.y - scrollUpButton.height - scrollIndicator.height);
            scrollIndicator.y = scrollUpButton.y + scrollUpButton.height + (scrollRatio * indicatorRange);
        }
    }

    function animateIn() {
        isAnimating = true;

        // Hide all elements initially (alpha only, no scaling)
        var allElements = [panel, titleText, infoText, closeButton, closeButtonText,
                          prevButton, nextButton, prevButtonText, nextButtonText, pageInfo,
                          scrollUpButton, scrollDownButton, scrollUpText, scrollDownText, scrollIndicator];

        for (element in allElements) {
            if (element != null) {
                element.alpha = 0;
            }
        }

        // Scale only the panel for the main animation effect
        panel.scale.set(0.5, 0.5);

        // Animate panel first
        FlxTween.tween(panel, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.4, {
            ease: FlxEase.backOut
        });

        // Animate title
        FlxTween.tween(titleText, {alpha: 1}, 0.5, {
            ease: FlxEase.sineOut,
            startDelay: 0.1
        });

        // Animate content
        FlxTween.tween(infoText, {alpha: 1}, 0.5, {
            ease: FlxEase.sineOut,
            startDelay: 0.2
        });

        // Always animate the close button (it's always visible)
        FlxTween.tween(closeButton, {alpha: 1}, 0.3, {
            ease: FlxEase.sineOut,
            startDelay: 0.3
        });

        FlxTween.tween(closeButtonText, {alpha: 1}, 0.3, {
            ease: FlxEase.sineOut,
            startDelay: 0.3,
            onComplete: function(_) {
                // Animation is complete, now animate visible navigation elements
                animateVisibleElements();
            }
        });
    }

    function animateVisibleElements():Void {
        // Animate only visible navigation elements
        var visibleElements:Array<FlxSprite> = [];

        if (prevButton.visible) {
            visibleElements.push(prevButton);
            visibleElements.push(cast prevButtonText);
        }
        if (nextButton.visible) {
            visibleElements.push(nextButton);
            visibleElements.push(cast nextButtonText);
        }
        if (pageInfo.visible && pageInfo.text != "") {
            visibleElements.push(cast pageInfo);
        }
        if (scrollUpButton.visible) {
            visibleElements.push(scrollUpButton);
            visibleElements.push(cast scrollUpText);
        }
        if (scrollDownButton.visible) {
            visibleElements.push(scrollDownButton);
            visibleElements.push(cast scrollDownText);
        }
        if (scrollIndicator.visible) {
            visibleElements.push(scrollIndicator);
        }

        if (visibleElements.length == 0) {
            // No additional elements to animate
            isAnimating = false;
            return;
        }

        var animationsCompleted = 0;

        for (i in 0...visibleElements.length) {
            var element = visibleElements[i];
            FlxTween.tween(element, {alpha: 1}, 0.3, {
                ease: FlxEase.sineOut,
                startDelay: i * 0.02,
                onComplete: function(_) {
                    animationsCompleted++;
                    if (animationsCompleted >= visibleElements.length) {
                        isAnimating = false;
                    }
                }
            });
        }
    }

    function animateOut(onComplete:Void->Void) {
        if (isAnimating) return;
        isAnimating = true;

        FlxTween.tween(panel, {"scale.x": 0.5, "scale.y": 0.5, alpha: 0}, 0.3, {
            ease: FlxEase.backIn,
            onComplete: function(_) {
                onComplete();
            }
        });

        FlxTween.tween(background, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Safety: Force end animation after 3 seconds
        if (isAnimating) {
            if (!isClosing) {
                // Add a timer to force end animation if it gets stuck
                new FlxTimer().start(3.0, function(_) {
                    if (isAnimating && !isClosing) {
                        trace("InfoPanel: Force ending stuck animation");
                        isAnimating = false;
                    }
                });
            }
        }

        // Close on back/escape (allow even during animation for safety)
        if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            closePanel();
            return;
        }

        // Return early if still animating (but allow close above)
        if (isAnimating) return;

        // Keyboard navigation
        if (FlxG.keys.justPressed.LEFT && currentPage > 0) {
            previousPage();
        }
        if (FlxG.keys.justPressed.RIGHT && currentPage < contentPages.length - 1) {
            nextPage();
        }

        // Scroll with arrow keys or mouse wheel
        if (FlxG.keys.pressed.UP || FlxG.mouse.wheel > 0) {
            scrollUp();
        }
        if (FlxG.keys.pressed.DOWN || FlxG.mouse.wheel < 0) {
            scrollDown();
        }

        // Button hover and click handling - Simplified approach
        // Close button (always available)
        if (FlxG.mouse.overlaps(closeButton)) {
            closeButton.color = FlxColor.WHITE;
            closeButtonText.color = FlxColor.BLACK;
            if (FlxG.mouse.justPressed) {
                FlxG.sound.play(Paths.sound('confirmMenu'));
                closePanel();
            }
        } else {
            closeButton.color = themeColor;
            closeButtonText.color = FlxColor.BLACK;
        }

        // Navigation buttons
        if (prevButton.visible && FlxG.mouse.overlaps(prevButton)) {
            prevButton.color = FlxColor.WHITE;
            prevButtonText.color = FlxColor.BLACK;
            if (FlxG.mouse.justPressed) {
                FlxG.sound.play(Paths.sound('scrollMenu'));
                previousPage();
            }
        } else if (prevButton.visible) {
            prevButton.color = themeColor;
            prevButtonText.color = FlxColor.BLACK;
        }

        if (nextButton.visible && FlxG.mouse.overlaps(nextButton)) {
            nextButton.color = FlxColor.WHITE;
            nextButtonText.color = FlxColor.BLACK;
            if (FlxG.mouse.justPressed) {
                FlxG.sound.play(Paths.sound('scrollMenu'));
                nextPage();
            }
        } else if (nextButton.visible) {
            nextButton.color = themeColor;
            nextButtonText.color = FlxColor.BLACK;
        }

        // Scroll buttons
        if (scrollUpButton.visible && FlxG.mouse.overlaps(scrollUpButton)) {
            scrollUpButton.color = FlxColor.WHITE;
            scrollUpText.color = FlxColor.BLACK;
            if (FlxG.mouse.pressed) {
                scrollUp();
            }
        } else if (scrollUpButton.visible) {
            scrollUpButton.color = themeColor;
            scrollUpText.color = FlxColor.BLACK;
        }

        if (scrollDownButton.visible && FlxG.mouse.overlaps(scrollDownButton)) {
            scrollDownButton.color = FlxColor.WHITE;
            scrollDownText.color = FlxColor.BLACK;
            if (FlxG.mouse.pressed) {
                scrollDown();
            }
        } else if (scrollDownButton.visible) {
            scrollDownButton.color = themeColor;
            scrollDownText.color = FlxColor.BLACK;
        }

        // Close if clicking outside the panel
        if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(panel)) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            closePanel();
        }
    }

    function previousPage():Void {
        if (currentPage > 0) {
            currentPage--;
            currentScrollOffset = 0;
            updateContentDisplay();
        }
    }

    function nextPage():Void {
        if (currentPage < contentPages.length - 1) {
            currentPage++;
            currentScrollOffset = 0;
            updateContentDisplay();
        }
    }

    function scrollUp():Void {
        currentScrollOffset = Math.max(0, currentScrollOffset - SCROLL_SPEED);
        updateContentDisplay();
    }

    function scrollDown():Void {
        currentScrollOffset = Math.min(maxScrollOffset, currentScrollOffset + SCROLL_SPEED);
        updateContentDisplay();
    }

    var isClosing:Bool = false;

    function closePanel() {
        if (isClosing) return;
        isClosing = true;

        // Force end any stuck animations
        isAnimating = false;

        animateOut(function() {
            forceClose();
        });
    }

    function forceClose() {
        if (onCloseCallback != null) {
            onCloseCallback();
        }
        super.close();
    }
}
