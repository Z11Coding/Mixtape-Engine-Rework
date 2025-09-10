package backend.ui;

import backend.ui.PsychUIBox;
import backend.ui.PsychUIEventHandler;
import backend.ui.PsychUITab;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

enum DrawerSide {
    LEFT;
    RIGHT;
    TOP;
    BOTTOM;
}

/**
 * PsychUIDrawer: A UI drawer that attaches to a camera, can be positioned on any side,
 * and contains pullable/clickable tabs for sliding out UI elements. Supports multiple tab sets.
 * Each drawer tab can have its own top tabs like a normal PsychUIBox.
 */
class PsychUIDrawer extends PsychUIBox {
    public var attachedCamera:FlxCamera;
    public var side:DrawerSide;
    public var drawerTabs:Array<DrawerTab>;
    public var activeDrawerTab:Int = -1;
    public var isOpen:Bool = false;
    public var pullTab:FlxSprite;
    public var pullTabText:FlxText;
    public var tabWidth:Int = 32;
    public var drawerWidth:Int = 300;
    public var animationSpeed:Float = 0.3;
    public var animationTween:FlxTween;

    // Original positions for animation
    private var closedX:Float;
    private var closedY:Float;
    private var openX:Float;
    private var openY:Float;

    // Drag tracking for pull tab
    private var _isDragging:Bool = false;
    private var _dragStartPos:FlxPoint;
    private var _dragThreshold:Float = 20;

    public function new(camera:FlxCamera, side:DrawerSide = RIGHT, width:Int = 300) {
        this.attachedCamera = camera;
        this.side = side;
        this.drawerWidth = width;

        drawerTabs = [];

        // Create pull tab
        pullTab = new FlxSprite();
        pullTabText = new FlxText(0, 0, tabWidth, ">");
        pullTabText.alignment = CENTER;
        pullTabText.size = 12;

        // Initialize with camera height for proper sizing
        var drawerHeight = Std.int(camera.height);
        super(0, 0, width, drawerHeight);

        // Add drawer components
        add(pullTab);
        add(pullTabText);

        setupDrawer();
    }

    function setupDrawer() {
        var camWidth = attachedCamera.width;
        var camHeight = attachedCamera.height;
        var camX = attachedCamera.x;
        var camY = attachedCamera.y;

        // Position the drawer based on the side
        switch (side) {
            case LEFT:
                closedX = camX - drawerWidth + tabWidth;
                closedY = camY;
                openX = camX;
                openY = camY;
                bg.makeGraphic(drawerWidth, Std.int(camHeight), 0xFF222222);
                pullTab.makeGraphic(tabWidth, tabHeight * 2, 0xFF444444);
                pullTabText.text = ">";
                pullTabText.fieldWidth = tabWidth;
            case RIGHT:
                closedX = camX + camWidth - tabWidth;
                closedY = camY;
                openX = camX + camWidth - drawerWidth;
                openY = camY;
                bg.makeGraphic(drawerWidth, Std.int(camHeight), 0xFF222222);
                pullTab.makeGraphic(tabWidth, tabHeight * 2, 0xFF444444);
                pullTabText.text = "<";
                pullTabText.fieldWidth = tabWidth;
            case TOP:
                closedX = camX;
                closedY = camY - drawerWidth + tabHeight;
                openX = camX;
                openY = camY;
                bg.makeGraphic(Std.int(camWidth), drawerWidth, 0xFF222222);
                pullTab.makeGraphic(tabWidth * 2, tabHeight, 0xFF444444);
                pullTabText.text = "v";
                pullTabText.fieldWidth = tabWidth * 2;
            case BOTTOM:
                closedX = camX;
                closedY = camY + camHeight - tabHeight;
                openX = camX;
                openY = camY + camHeight - drawerWidth;
                bg.makeGraphic(Std.int(camWidth), drawerWidth, 0xFF222222);
                pullTab.makeGraphic(tabWidth * 2, tabHeight, 0xFF444444);
                pullTabText.text = "^";
                pullTabText.fieldWidth = tabWidth * 2;
        }

        // Set initial position (closed)
        setPosition(closedX, closedY);
        bg.alpha = 0.9;

        // Position pull tab
        updatePullTabPosition();

        // Resize the inherited PsychUIBox to fit the drawer
        resize(Std.int(bg.width), Std.int(bg.height));
    }

    function updatePullTabPosition() {
        switch (side) {
            case LEFT:
                pullTab.x = x + drawerWidth;
                pullTab.y = y + 50;
            case RIGHT:
                pullTab.x = x - tabWidth;
                pullTab.y = y + 50;
            case TOP:
                pullTab.x = x + 50;
                pullTab.y = y + drawerWidth;
            case BOTTOM:
                pullTab.x = x + 50;
                pullTab.y = y - tabHeight;
        }

        pullTabText.x = pullTab.x + pullTab.width/2 - pullTabText.width/2;
        pullTabText.y = pullTab.y + pullTab.height/2 - pullTabText.height/2;
    }

    public function addDrawerTab(name:String):DrawerTab {
        var drawerTab = new DrawerTab(name, this);
        drawerTabs.push(drawerTab);
        add(drawerTab);
        updateDrawerTabPositions();

        if (activeDrawerTab == -1) {
            activeDrawerTab = 0;
        }

        return drawerTab;
    }

    function updateDrawerTabPositions() {
        for (i in 0...drawerTabs.length) {
            var tab = drawerTabs[i];
            switch (side) {
                case LEFT:
                    tab.x = x + drawerWidth + 5;
                    tab.y = y + 80 + i * (tabHeight + 5);
                case RIGHT:
                    tab.x = x - tabWidth - 5;
                    tab.y = y + 80 + i * (tabHeight + 5);
                case TOP:
                    tab.x = x + 80 + i * (tabWidth + 5);
                    tab.y = y + drawerWidth + 5;
                case BOTTOM:
                    tab.x = x + 80 + i * (tabWidth + 5);
                    tab.y = y - tabHeight - 5;
            }
        }
    }

    public function toggleDrawer(?tabIndex:Int = -1) {
        if (animationTween != null) {
            animationTween.cancel();
            animationTween = null;
        }

        if (tabIndex >= 0 && tabIndex < drawerTabs.length) {
            activeDrawerTab = tabIndex;
        }

        if (isOpen) {
            closeDrawer();
        } else {
            openDrawer();
        }
    }

    public function openDrawer() {
        if (isOpen) return;

        isOpen = true;
        updatePullTabText();

        animationTween = FlxTween.tween(this, {x: openX, y: openY}, animationSpeed, {
            ease: FlxEase.quartOut,
            onUpdate: function(tween:FlxTween) {
                updatePullTabPosition();
                updateDrawerTabPositions();
            },
            onComplete: function(tween:FlxTween) {
                animationTween = null;
            }
        });
    }

    public function closeDrawer() {
        if (!isOpen) return;

        isOpen = false;
        updatePullTabText();

        animationTween = FlxTween.tween(this, {x: closedX, y: closedY}, animationSpeed, {
            ease: FlxEase.quartOut,
            onUpdate: function(tween:FlxTween) {
                updatePullTabPosition();
                updateDrawerTabPositions();
            },
            onComplete: function(tween:FlxTween) {
                animationTween = null;
            }
        });
    }

    function updatePullTabText() {
        switch (side) {
            case LEFT:
                pullTabText.text = isOpen ? "<" : ">";
            case RIGHT:
                pullTabText.text = isOpen ? ">" : "<";
            case TOP:
                pullTabText.text = isOpen ? "^" : "v";
            case BOTTOM:
                pullTabText.text = isOpen ? "v" : "^";
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle pull tab interaction
        if (FlxG.mouse.overlaps(pullTab, attachedCamera)) {
            pullTab.alpha = 0.8;

            if (FlxG.mouse.justPressed) {
                _dragStartPos = FlxG.mouse.getPositionInCameraView(attachedCamera);
                _isDragging = true;
            }

            if (FlxG.mouse.justReleased && !_isDragging) {
                toggleDrawer();
            }
        } else {
            pullTab.alpha = 1.0;
        }

        // Handle dragging
        if (_isDragging && FlxG.mouse.pressed) {
            var currentPos = FlxG.mouse.getPositionInCameraView(attachedCamera);
            var dragDistance = 0.0;

            switch (side) {
                case LEFT:
                    dragDistance = currentPos.x - _dragStartPos.x;
                case RIGHT:
                    dragDistance = _dragStartPos.x - currentPos.x;
                case TOP:
                    dragDistance = currentPos.y - _dragStartPos.y;
                case BOTTOM:
                    dragDistance = _dragStartPos.y - currentPos.y;
            }

            if (Math.abs(dragDistance) > _dragThreshold) {
                if (dragDistance > 0 && !isOpen) {
                    openDrawer();
                } else if (dragDistance < 0 && isOpen) {
                    closeDrawer();
                }
                _isDragging = false;
            }
        }

        if (FlxG.mouse.justReleased) {
            _isDragging = false;
        }

        // Handle drawer tab clicks
        for (i in 0...drawerTabs.length) {
            var tab = drawerTabs[i];
            if (FlxG.mouse.overlaps(tab, attachedCamera)) {
                tab.alpha = 0.8;
                if (FlxG.mouse.justReleased) {
                    if (activeDrawerTab == i && isOpen) {
                        closeDrawer();
                    } else {
                        activeDrawerTab = i;
                        if (!isOpen) openDrawer();
                    }
                }
            } else {
                tab.alpha = (activeDrawerTab == i) ? 1.0 : 0.6;
            }
        }

        // Update active drawer tab content
        if (isOpen && activeDrawerTab >= 0 && activeDrawerTab < drawerTabs.length) {
            var activeTab = drawerTabs[activeDrawerTab];
            activeTab.updateContent(elapsed);
        }
    }

    override function draw() {
        super.draw();

        // Draw active drawer tab content
        if (isOpen && activeDrawerTab >= 0 && activeDrawerTab < drawerTabs.length) {
            var activeTab = drawerTabs[activeDrawerTab];
            activeTab.drawContent();
        }
    }

    override function destroy() {
        if (animationTween != null) {
            animationTween.cancel();
            animationTween = null;
        }

        drawerTabs = null;
        pullTab = null;
        pullTabText = null;
        _dragStartPos = null;

        super.destroy();
    }
}

/**
 * DrawerTab: Represents a pullable/clickable tab for the drawer.
 * Each drawer tab acts like its own PsychUIBox with top tabs.
 */
class DrawerTab extends FlxSprite {
    public var tabName:String;
    public var topTabBox:PsychUIBox;
    public var parentDrawer:PsychUIDrawer;
    public var tabText:FlxText;

    public function new(name:String, parent:PsychUIDrawer) {
        super();
        this.tabName = name;
        this.parentDrawer = parent;

        makeGraphic(parent.tabWidth, parent.tabHeight, 0xFF444444);

        tabText = new FlxText(0, 0, width, name);
        tabText.size = 8;
        tabText.alignment = CENTER;

        // Create the top tab box for this drawer tab
        topTabBox = new PsychUIBox(0, 0, parent.drawerWidth - 20, parent.drawerWidth - 100);
        topTabBox.canMove = false;
        topTabBox.canMinimize = false;
    }

    public function addTopTab(name:String) {
        topTabBox.addTab(name);
    }

    public function getTopTab(name:String):PsychUITab {
        return topTabBox.getTab(name);
    }

    public function updateContent(elapsed:Float) {
        if (topTabBox != null) {
            topTabBox.x = parentDrawer.x + 10;
            topTabBox.y = parentDrawer.y + parentDrawer.tabHeight + 10;
            topTabBox.update(elapsed);
        }
    }

    public function drawContent() {
        if (topTabBox != null) {
            topTabBox.draw();
        }
    }

    override function draw() {
        super.draw();

        if (tabText != null) {
            tabText.x = x;
            tabText.y = y + height/2 - tabText.height/2;
            tabText.draw();
        }
    }

    override function destroy() {
        topTabBox = null;
        tabText = null;
        parentDrawer = null;
        super.destroy();
    }
}
