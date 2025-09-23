package yutautil.games.stealthmaze.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import yutautil.games.stealthmaze.backend.MazeData.MazeFloor;
import yutautil.games.stealthmaze.backend.MazeData;

/**
 * Player character for the stealth maze game
 * Cyan square with movement, sprinting, direction facing, and stealth mechanics
 */
class MazePlayer extends FlxSprite {

    // Movement properties
    public var walkSpeed:Float = 80.0;
    public var sprintSpeed:Float = 140.0;
    public var currentSpeed:Float = 80.0;
    public var isSprinting:Bool = false;

    // Direction and vision
    public var facingDirection:Float = 0.0; // In degrees
    public var visionCone:MazeVisionCone;
    public var flashlightRange:Float = 100.0;
    public var flashlightAngle:Float = 45.0; // Half-angle of vision cone

    // Stealth mechanics
    public var isHidden:Bool = false;
    public var noiseLevel:Float = 0.0; // 0-1 scale, higher when sprinting
    public var maxNoiseRange:Float = 64.0; // Maximum noise detection distance

    // Tail system (collectibles following the player)
    public var tailSegments:Array<MazeTailSegment>;
    public var maxTailLength:Int = 10;
    public var segmentSpacing:Float = 24.0;

    // Position history for tail
    private var positionHistory:Array<FlxPoint>;
    private var historyUpdateTimer:Float = 0.0;
    private var historyUpdateInterval:Float = 0.1; // Update every 0.1 seconds

    // Visual effects
    private var sprintParticleTimer:Float = 0.0;

    // Input handling
    public var upKey:Int = 87; // W
    public var downKey:Int = 83; // S
    public var leftKey:Int = 65; // A
    public var rightKey:Int = 68; // D
    public var sprintKey:Int = 16; // Shift

    // Floor reference for collision detection
    public var currentFloor:MazeFloor = null;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);

        // Set up player sprite (cyan square)
        makeGraphic(24, 24, FlxColor.CYAN);

        // Create vision cone
        visionCone = new MazeVisionCone(this);

        // Initialize tail system
        tailSegments = [];
        positionHistory = [];

        // Set physics
        drag.set(400, 400);
        maxVelocity.set(sprintSpeed, sprintSpeed);
    }

    override public function update(elapsed:Float):Void {
        // Handle input FIRST
        handleInput(elapsed);

        // Store position before movement for collision detection
        var oldX = x;
        var oldY = y;

        // Apply physics and movement
        super.update(elapsed);

        // Check for collisions and revert if needed - AFTER movement
        if (currentFloor != null && !currentFloor.isWalkable(x + width/2, y + height/2)) {
            // Collision detected - revert to previous position
            x = oldX;
            y = oldY;
            velocity.set(0, 0);
        }

        // Additional check for corner collision detection
        if (currentFloor != null) {
            var corners = [
                {x: x, y: y},                           // Top-left
                {x: x + width, y: y},                   // Top-right
                {x: x, y: y + height},                  // Bottom-left
                {x: x + width, y: y + height}           // Bottom-right
            ];

            for (corner in corners) {
                if (!currentFloor.isWalkable(corner.x, corner.y)) {
                    // Collision detected - revert to previous position
                    x = oldX;
                    y = oldY;
                    velocity.set(0, 0);
                    break;
                }
            }
        }

        // Update direction based on velocity
        updateFacingDirection();

        // Update noise level
        updateNoiseLevel();

        // Update position history for tail
        updatePositionHistory(elapsed);

        // Update tail segments
        updateTailSegments();

        // Update vision cone
        visionCone.update(elapsed);

        // Sprint particle effects
        if (isSprinting && velocity.length > 20) {
            updateSprintEffects(elapsed);
        }
    }

    /**
     * Handle player input
     */
    private function handleInput(elapsed:Float):Void {
        var moving = false;
        var inputDirection = FlxPoint.get(0, 0);

        // Check movement input - Support both WASD and Arrow Keys
        if (FlxG.keys.pressed.W || FlxG.keys.pressed.UP || FlxG.keys.anyPressed([upKey])) {
            inputDirection.y -= 1;
            moving = true;
        }
        if (FlxG.keys.pressed.S || FlxG.keys.pressed.DOWN || FlxG.keys.anyPressed([downKey])) {
            inputDirection.y += 1;
            moving = true;
        }
        if (FlxG.keys.pressed.A || FlxG.keys.pressed.LEFT || FlxG.keys.anyPressed([leftKey])) {
            inputDirection.x -= 1;
            moving = true;
        }
        if (FlxG.keys.pressed.D || FlxG.keys.pressed.RIGHT || FlxG.keys.anyPressed([rightKey])) {
            inputDirection.x += 1;
            moving = true;
        }

        // Normalize diagonal movement
        if (inputDirection.x != 0 && inputDirection.y != 0) {
            inputDirection.normalize();
        }

        // Check sprint input
        isSprinting = FlxG.keys.anyPressed([sprintKey]) && moving;
        currentSpeed = isSprinting ? sprintSpeed : walkSpeed;

        // Apply movement
        if (moving) {
            velocity.set(inputDirection.x * currentSpeed, inputDirection.y * currentSpeed);
        } else {
            velocity.set(0, 0);
        }

        // Check door interaction (E key to open/close doors)
        if (FlxG.keys.justPressed.E) {
            interactWithNearbyDoors();
        }

        inputDirection.put();
    }

    /**
     * Interact with doors near the player
     */
    private function interactWithNearbyDoors():Void {
        if (currentFloor == null) return;

        var playerCenter = FlxPoint.get(x + width/2, y + height/2);
        var interactionDistance = 40; // How close the player needs to be to a door

        for (room in currentFloor.rooms) {
            for (door in room.doors) {
                var doorCenter = FlxPoint.get(door.bounds.x + door.bounds.width/2, door.bounds.y + door.bounds.height/2);
                var distance = playerCenter.distanceTo(doorCenter);

                if (distance <= interactionDistance) {
                    door.toggle();
                    trace("Door " + (door.isOpen ? "opened" : "closed"));
                    break; // Only interact with one door at a time
                }

                doorCenter.put();
            }
        }

        playerCenter.put();
    }

    /**
     * Update facing direction based on movement
     */
    private function updateFacingDirection():Void {
        if (velocity.length > 10) { // Only update direction when moving significantly
            facingDirection = Math.atan2(velocity.y, velocity.x) * 180 / Math.PI;

            // Update sprite rotation to show direction
            angle = facingDirection;
        }
    }

    /**
     * Update noise level for stealth mechanics
     */
    private function updateNoiseLevel():Void {
        if (isSprinting) {
            noiseLevel = 0.8; // High noise when sprinting
        } else if (velocity.length > 10) {
            noiseLevel = 0.3; // Medium noise when walking
        } else {
            noiseLevel = 0.1; // Low noise when standing
        }

        // Being hidden reduces noise
        if (isHidden) {
            noiseLevel *= 0.2; // 80% noise reduction when hidden
        }
    }

    /**
     * Update position history for tail system
     */
    private function updatePositionHistory(elapsed:Float):Void {
        historyUpdateTimer += elapsed;

        if (historyUpdateTimer >= historyUpdateInterval) {
            historyUpdateTimer = 0.0;

            // Add current position to history
            positionHistory.push(FlxPoint.get(x + width/2, y + height/2));

            // Limit history length
            var maxHistory = Std.int(maxTailLength * (segmentSpacing / (currentSpeed * historyUpdateInterval))) + 10;
            while (positionHistory.length > maxHistory) {
                var removed = positionHistory.shift();
                removed.put();
            }
        }
    }

    /**
     * Update tail segments based on position history
     */
    private function updateTailSegments():Void {
        for (i in 0...tailSegments.length) {
            var segment = tailSegments[i];
            var targetIndex = Std.int((i + 1) * (segmentSpacing / (currentSpeed * historyUpdateInterval)));

            if (targetIndex < positionHistory.length) {
                var targetPos = positionHistory[positionHistory.length - 1 - targetIndex];

                // Smoothly move segment to target position
                FlxTween.tween(segment, {
                    x: targetPos.x - segment.width/2,
                    y: targetPos.y - segment.height/2
                }, 0.2);
            }
        }
    }

    /**
     * Add a tail segment (when collecting items)
     */
    public function addTailSegment(type:CollectibleType):MazeTailSegment {
        if (tailSegments.length >= maxTailLength) {
            return null; // Can't add more segments
        }

        var segment = new MazeTailSegment(x, y, type);
        tailSegments.push(segment);

        return segment;
    }

    /**
     * Remove all tail segments (when caught or reset)
     */
    public function clearTail():Void {
        for (segment in tailSegments) {
            segment.destroy();
        }
        tailSegments = [];
    }

    /**
     * Get current noise detection range
     */
    public function getNoiseRange():Float {
        return maxNoiseRange * noiseLevel;
    }

    /**
     * Check if player is visible to enemies (not hidden and not in closet)
     */
    public function isVisibleToEnemies():Bool {
        return !isHidden;
    }

    /**
     * Hide player (in closet)
     */
    public function hide():Void {
        isHidden = true;
        alpha = 0.5; // Semi-transparent when hidden
    }

    /**
     * Unhide player
     */
    public function unhide():Void {
        isHidden = false;
        alpha = 1.0;
    }

    /**
     * Update sprint visual effects
     */
    private function updateSprintEffects(elapsed:Float):Void {
        sprintParticleTimer += elapsed;

        if (sprintParticleTimer >= 0.1) { // Create particle every 0.1 seconds
            sprintParticleTimer = 0.0;

            // Create dust particle behind player
            var particle = new FlxSprite();
            particle.makeGraphic(4, 4, FlxColor.GRAY);
            particle.x = x + width/2 - 2 - Math.cos(facingDirection * Math.PI / 180) * 16;
            particle.y = y + height/2 - 2 - Math.sin(facingDirection * Math.PI / 180) * 16;
            particle.alpha = 0.6;

            // Add to parent group if available
            if (FlxG.state != null) {
                FlxG.state.add(particle);
            }

            // Fade out particle
            FlxTween.tween(particle, {alpha: 0, y: particle.y + 8}, 0.5, {
                onComplete: function(tween) {
                    particle.destroy();
                }
            });
        }
    }

    /**
     * Reset player to initial state
     */
    public function resetPlayer():Void {
        clearTail();
        unhide();
        velocity.set(0, 0);
        facingDirection = 0;
        noiseLevel = 0.1;
        isSprinting = false;
    }

    override public function destroy():Void {
        if (visionCone != null) {
            visionCone.destroy();
        }

        clearTail();

        // Clean up position history
        if (positionHistory != null)
        for (pos in positionHistory) {
            pos.put();
        }
        positionHistory = null;

        super.destroy();
    }
}

/**
 * Player's vision cone for stealth mechanics
 */
class MazeVisionCone extends FlxSprite {

    private var player:MazePlayer;
    private var coneVertices:Array<FlxPoint>;

    public function new(player:MazePlayer) {
        super();
        this.player = player;
        this.coneVertices = [];

        // Create a larger canvas for the vision cone
        makeGraphic(400, 400, FlxColor.TRANSPARENT, true);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (player != null) {
            // Position cone relative to player
            x = player.x + player.width/2 - width/2;
            y = player.y + player.height/2 - height/2;

            // Redraw vision cone
            drawVisionCone();
        }
    }

    /**
     * Draw the vision cone based on player's facing direction
     */
    private function drawVisionCone():Void {
        graphic.bitmap.fillRect(graphic.bitmap.rect, 0x00000000); // Clear with transparent

        if (player == null) return;

        var centerX = width / 2;
        var centerY = height / 2;

        var direction = player.facingDirection * Math.PI / 180;
        var range = player.flashlightRange;
        var halfAngle = player.flashlightAngle * Math.PI / 180;

        // Calculate cone vertices
        var vertices = [];
        vertices.push(new FlxPoint(centerX, centerY)); // Center point

        // Add cone arc points
        var steps = 20;
        for (i in 0...steps + 1) {
            var angle = direction - halfAngle + (halfAngle * 2 * i / steps);
            var px = centerX + Math.cos(angle) * range;
            var py = centerY + Math.sin(angle) * range;
            vertices.push(new FlxPoint(px, py));
        }

        // Draw cone using simple triangle fan approach
        drawTriangleFan(vertices, 0x40FFFF00); // Semi-transparent yellow

        // Clean up
        for (vertex in vertices) {
            vertex.put();
        }
    }

    /**
     * Draw triangle fan for vision cone
     */
    private function drawTriangleFan(vertices:Array<FlxPoint>, color:Int):Void {
        if (vertices.length < 3) return;

        var graphics = graphic.bitmap;

        // Simple filled polygon approximation
        for (i in 1...(vertices.length - 1)) {
            drawTriangle(graphics, vertices[0], vertices[i], vertices[i + 1], color);
        }
    }

    /**
     * Draw a filled triangle (basic implementation)
     */
    private function drawTriangle(graphics:openfl.display.BitmapData, p1:FlxPoint, p2:FlxPoint, p3:FlxPoint, color:Int):Void {
        // Basic triangle rasterization would go here
        // For now, we'll use simple line drawing to approximate
        var lineColor = color | 0xFF000000; // Ensure alpha

        // Draw lines between points
        drawLine(graphics, Std.int(p1.x), Std.int(p1.y), Std.int(p2.x), Std.int(p2.y), lineColor);
        drawLine(graphics, Std.int(p2.x), Std.int(p2.y), Std.int(p3.x), Std.int(p3.y), lineColor);
        drawLine(graphics, Std.int(p3.x), Std.int(p3.y), Std.int(p1.x), Std.int(p1.y), lineColor);
    }

    /**
     * Draw line between two points
     */
    private function drawLine(graphics:openfl.display.BitmapData, x0:Int, y0:Int, x1:Int, y1:Int, color:Int):Void {
        // Bresenham's line algorithm
        var dx = Math.abs(x1 - x0);
        var dy = Math.abs(y1 - y0);
        var sx = x0 < x1 ? 1 : -1;
        var sy = y0 < y1 ? 1 : -1;
        var err = dx - dy;

        var x = x0;
        var y = y0;

        while (true) {
            if (x >= 0 && x < graphics.width && y >= 0 && y < graphics.height) {
                graphics.setPixel32(x, y, color);
            }

            if (x == x1 && y == y1) break;

            var e2 = 2 * err;
            if (e2 > -dy) {
                err -= dy;
                x += sx;
            }
            if (e2 < dx) {
                err += dx;
                y += sy;
            }
        }
    }
}

/**
 * Tail segment that follows the player
 */
class MazeTailSegment extends FlxSprite {

    public var segmentType:CollectibleType;
    public var segmentIndex:Int = 0;

    public function new(x:Float, y:Float, type:CollectibleType) {
        super(x, y);
        this.segmentType = type;

        // Set appearance based on type
        switch (type) {
            case RED_OBJECTIVE:
                makeGraphic(20, 20, FlxColor.RED);
            case GOLDEN_BONUS:
                makeGraphic(16, 16, FlxColor.YELLOW);
        }

        // Add slight transparency to show it's a tail
        alpha = 0.8;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Add subtle floating animation
        y += Math.sin(elapsed * 5 + segmentIndex) * 0.5;
    }
}
