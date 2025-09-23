package yutautil.games.stealthmaze.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.path.FlxPath;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import yutautil.games.stealthmaze.backend.MazeData;

enum EnemyState {
    PATROL;      // Following patrol route
    INVESTIGATE; // Checking out suspicious activity
    CHASE;       // Actively pursuing player
    SEARCH;      // Looking for player after losing sight
    RETURN;      // Returning to patrol route
}

/**
 * Enemy AI for stealth maze game
 * Purple squares with vision cones, awareness system, and pathfinding
 */
class MazeEnemy extends FlxSprite {

    // AI State
    public var currentState:EnemyState = PATROL;
    public var previousState:EnemyState = PATROL;

    // Movement properties
    public var baseSpeed:Float = 60.0;
    public var chaseSpeed:Float = 100.0;
    public var currentSpeed:Float = 60.0;

    // Patrol system
    public var patrolPoints:Array<MazePosition>;
    public var currentPatrolIndex:Int = 0;
    public var patrolDirection:Int = 1; // 1 for forward, -1 for backward
    public var waitAtPatrolPoint:Float = 2.0; // Seconds to wait at each point
    private var patrolWaitTimer:Float = 0.0;

    // Vision and awareness
    public var facingDirection:Float = 0.0;
    public var visionCone:MazeEnemyVisionCone;
    public var visionRange:Float = 80.0;
    public var visionAngle:Float = 60.0; // Half-angle in degrees
    public var alertness:Float = 0.5; // 0-1 scale

    // Awareness system
    public var awarenessLevel:Float = 0.0; // 0-1 scale
    public var awarenessDecayRate:Float = 0.3; // Per second
    public var suspicionThreshold:Float = 0.3;
    public var chaseThreshold:Float = 0.7;

    // Sound detection
    public var hearingRange:Float = 60.0;
    public var soundSensitivity:Float = 1.0;

    // Pathfinding
    private var pathfinder:MazePathfinder;
    private var currentPath:Array<FlxPoint>;
    private var pathIndex:Int = 0;
    private var pathfindingTarget:FlxPoint;

    // Floor reference for collision detection and door interaction
    public var currentFloor:MazeFloor = null;

    // Investigation
    private var investigationTarget:FlxPoint;
    private var investigationTimer:Float = 0.0;
    private var maxInvestigationTime:Float = 5.0;

    // Chase system
    public var lastKnownPlayerPosition:FlxPoint;
    private var playerLostTimer:Float = 0.0;
    private var maxChaseTime:Float = 10.0;

    // Search system
    private var searchPoints:Array<FlxPoint>;
    private var currentSearchIndex:Int = 0;
    private var searchTimer:Float = 0.0;
    private var maxSearchTime:Float = 8.0;

    // Reference to maze and player
    public var mazeFloor:MazeFloor;
    public var targetPlayer:MazePlayer;

    // Visual effects
    private var alertIndicator:FlxSprite;

    public function new(x:Float, y:Float, spawn:EnemySpawnPoint) {
        super(x, y);

        // Set up enemy sprite (purple square)
        makeGraphic(22, 22, FlxColor.PURPLE);

        // Copy patrol points from spawn
        patrolPoints = [];
        for (point in spawn.patrolPoints) {
            patrolPoints.push(point.copy());
        }

        // Set properties from spawn
        alertness = spawn.alertness;
        baseSpeed = spawn.speed * 60; // Convert to pixels per second
        chaseSpeed = baseSpeed * 1.6;
        currentSpeed = baseSpeed;

        // Adjust properties based on alertness
        visionRange *= (0.8 + alertness * 0.4); // 80% to 120% of base range
        hearingRange *= (0.7 + alertness * 0.6); // 70% to 130% of base range
        soundSensitivity = alertness;

        // Create vision cone
        visionCone = new MazeEnemyVisionCone(this);

        // Create alert indicator
        alertIndicator = new FlxSprite();
        alertIndicator.makeGraphic(8, 8, FlxColor.YELLOW);
        alertIndicator.visible = false;

        // Initialize pathfinder (will be set by maze game)
        pathfinder = null;

        // Set physics
        drag.set(300, 300);
        maxVelocity.set(chaseSpeed, chaseSpeed);

        // Start patrol if points available
        if (patrolPoints.length > 0) {
            startPatrol();
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Update AI state
        updateAI(elapsed);

        // Update facing direction
        updateFacingDirection();

        // Update vision cone
        if (visionCone != null) {
            visionCone.update(elapsed);
        }

        // Update alert indicator
        updateAlertIndicator();

        // Handle door interaction for AI
        handleAIDoorInteraction();

        // Decay awareness over time
        awarenessLevel = Math.max(0, awarenessLevel - awarenessDecayRate * elapsed);
    }

    /**
     * AI automatically opens doors when moving through them
     */
    private function handleAIDoorInteraction():Void {
        if (currentFloor == null) return;

        var enemyCenter = FlxPoint.get(x + width/2, y + height/2);
        var interactionDistance = 30; // AI interaction distance

        for (room in currentFloor.rooms) {
            for (door in room.doors) {
                var doorCenter = FlxPoint.get(door.bounds.x + door.bounds.width/2, door.bounds.y + door.bounds.height/2);
                var distance = enemyCenter.distanceTo(doorCenter);

                if (distance <= interactionDistance && !door.isOpen && !door.requiresKey) {
                    door.open(); // AI automatically opens non-key doors

                    // AI closes door after passing through (delayed)
                    new FlxTimer().start(2.0, function(timer:FlxTimer) {
                        if (enemyCenter.distanceTo(doorCenter) > interactionDistance * 2) {
                            door.close();
                        }
                    });

                    break;
                }

                doorCenter.put();
            }
        }

        enemyCenter.put();
    }

    /**
     * Main AI update loop
     */
    private function updateAI(elapsed:Float):Void {
        // Check for player detection
        checkPlayerDetection();

        // Update state machine
        switch (currentState) {
            case PATROL:
                updatePatrolState(elapsed);
            case INVESTIGATE:
                updateInvestigateState(elapsed);
            case CHASE:
                updateChaseState(elapsed);
            case SEARCH:
                updateSearchState(elapsed);
            case RETURN:
                updateReturnState(elapsed);
        }
    }

    /**
     * Check if player is detected through vision or sound
     */
    private function checkPlayerDetection():Void {
        if (targetPlayer == null) return;

        var playerDetected = false;
        var detectionStrength = 0.0;

        // Visual detection
        if (canSeePlayer()) {
            playerDetected = true;
            detectionStrength += 0.8;
            lastKnownPlayerPosition = FlxPoint.get(targetPlayer.x + targetPlayer.width/2, targetPlayer.y + targetPlayer.height/2);
        }

        // Sound detection
        var soundDetection = checkSoundDetection();
        if (soundDetection > 0) {
            playerDetected = true;
            detectionStrength += soundDetection * 0.6;

            // If we don't have visual, estimate player position based on sound
            if (lastKnownPlayerPosition == null) {
                lastKnownPlayerPosition = FlxPoint.get(targetPlayer.x + targetPlayer.width/2, targetPlayer.y + targetPlayer.height/2);
            }
        }

        // Update awareness
        if (playerDetected) {
            awarenessLevel = Math.min(1.0, awarenessLevel + detectionStrength * FlxG.elapsed * 2);

            // State transitions based on awareness
            if (awarenessLevel >= chaseThreshold) {
                if (currentState != CHASE) {
                    transitionToChase();
                }
            } else if (awarenessLevel >= suspicionThreshold) {
                if (currentState == PATROL) {
                    transitionToInvestigate();
                }
            }
        }
    }

    /**
     * Check if player is visible to this enemy
     */
    private function canSeePlayer():Bool {
        if (targetPlayer == null || !targetPlayer.isVisibleToEnemies()) return false;

        var playerCenter = FlxPoint.get(targetPlayer.x + targetPlayer.width/2, targetPlayer.y + targetPlayer.height/2);
        var enemyCenter = FlxPoint.get(x + width/2, y + height/2);

        // Check distance
        var distance = enemyCenter.distanceTo(playerCenter);
        if (distance > visionRange) {
            playerCenter.put();
            enemyCenter.put();
            return false;
        }

        // Check if player is within vision cone
        var angleToPlayer = enemyCenter.angleBetween(playerCenter);
        var angleDiff = Math.abs(angleToPlayer - facingDirection);
        if (angleDiff > 180) angleDiff = 360 - angleDiff;

        playerCenter.put();
        enemyCenter.put();

        if (angleDiff > visionAngle) return false;

        // TODO: Add line-of-sight check for walls
        // For now, assume clear line of sight

        return true;
    }

    /**
     * Check sound detection and return detection strength
     */
    private function checkSoundDetection():Float {
        if (targetPlayer == null) return 0.0;

        var playerCenter = FlxPoint.get(targetPlayer.x + targetPlayer.width/2, targetPlayer.y + targetPlayer.height/2);
        var enemyCenter = FlxPoint.get(x + width/2, y + height/2);

        var distance = enemyCenter.distanceTo(playerCenter);
        var playerNoiseRange = targetPlayer.getNoiseRange();

        playerCenter.put();
        enemyCenter.put();

        if (distance > hearingRange || playerNoiseRange == 0) return 0.0;

        // Sound detection strength decreases with distance
        var soundStrength = (1.0 - distance / hearingRange) * soundSensitivity;

        // Player's noise level affects detection
        soundStrength *= (targetPlayer.noiseLevel / playerNoiseRange) * playerNoiseRange;

        return Math.min(1.0, soundStrength);
    }

    /**
     * Update patrol state
     */
    private function updatePatrolState(elapsed:Float):Void {
        if (patrolPoints.length == 0) return;

        var currentTarget = patrolPoints[currentPatrolIndex];
        var targetPoint = FlxPoint.get(currentTarget.x, currentTarget.y);
        var myCenter = FlxPoint.get(x + width/2, y + height/2);

        // Check if reached patrol point
        if (myCenter.distanceTo(targetPoint) < 16) {
            // Wait at patrol point
            patrolWaitTimer += elapsed;
            velocity.set(0, 0);

            // Set facing direction to patrol point direction
            facingDirection = currentTarget.direction;

            if (patrolWaitTimer >= waitAtPatrolPoint) {
                patrolWaitTimer = 0;
                moveToNextPatrolPoint();
            }
        } else {
            // Move towards patrol point
            var direction = myCenter.angleBetween(targetPoint);
            velocity.set(
                Math.cos(direction * Math.PI / 180) * currentSpeed,
                Math.sin(direction * Math.PI / 180) * currentSpeed
            );
        }

        targetPoint.put();
        myCenter.put();
    }

    /**
     * Move to next patrol point
     */
    private function moveToNextPatrolPoint():Void {
        if (patrolPoints.length <= 1) return;

        currentPatrolIndex += patrolDirection;

        // Handle patrol bounds
        if (currentPatrolIndex >= patrolPoints.length) {
            currentPatrolIndex = patrolPoints.length - 2;
            patrolDirection = -1;
        } else if (currentPatrolIndex < 0) {
            currentPatrolIndex = 1;
            patrolDirection = 1;
        }
    }

    /**
     * Update investigate state
     */
    private function updateInvestigateState(elapsed:Float):Void {
        investigationTimer += elapsed;

        if (investigationTarget != null) {
            var myCenter = FlxPoint.get(x + width/2, y + height/2);

            // Move towards investigation target
            if (myCenter.distanceTo(investigationTarget) > 12) {
                var direction = myCenter.angleBetween(investigationTarget);
                velocity.set(
                    Math.cos(direction * Math.PI / 180) * currentSpeed,
                    Math.sin(direction * Math.PI / 180) * currentSpeed
                );
            } else {
                velocity.set(0, 0);
                // Look around
                facingDirection += 90 * elapsed; // Slow rotation
                if (facingDirection >= 360) facingDirection -= 360;
            }

            myCenter.put();
        }

        // Return to patrol after investigation time
        if (investigationTimer >= maxInvestigationTime || awarenessLevel < suspicionThreshold * 0.5) {
            transitionToReturn();
        }
    }

    /**
     * Update chase state
     */
    private function updateChaseState(elapsed:Float):Void {
        if (lastKnownPlayerPosition == null) {
            transitionToSearch();
            return;
        }

        var myCenter = FlxPoint.get(x + width/2, y + height/2);
        currentSpeed = chaseSpeed;

        // If we can see the player, chase directly
        if (canSeePlayer()) {
            lastKnownPlayerPosition.set(targetPlayer.x + targetPlayer.width/2, targetPlayer.y + targetPlayer.height/2);
            playerLostTimer = 0;
        } else {
            playerLostTimer += elapsed;
        }

        // Move towards last known position
        if (myCenter.distanceTo(lastKnownPlayerPosition) > 16) {
            var direction = myCenter.angleBetween(lastKnownPlayerPosition);
            velocity.set(
                Math.cos(direction * Math.PI / 180) * currentSpeed,
                Math.sin(direction * Math.PI / 180) * currentSpeed
            );
        } else {
            velocity.set(0, 0);

            // If we reached the last known position but can't see player, start searching
            if (playerLostTimer > 1.0) {
                transitionToSearch();
            }
        }

        myCenter.put();

        // Give up chase after too long
        if (playerLostTimer >= maxChaseTime) {
            transitionToReturn();
        }
    }

    /**
     * Update search state
     */
    private function updateSearchState(elapsed:Float):Void {
        searchTimer += elapsed;

        if (searchPoints == null || searchPoints.length == 0) {
            generateSearchPoints();
        }

        if (searchPoints.length > 0 && currentSearchIndex < searchPoints.length) {
            var target = searchPoints[currentSearchIndex];
            var myCenter = FlxPoint.get(x + width/2, y + height/2);

            if (myCenter.distanceTo(target) < 16) {
                // Reached search point, look around
                velocity.set(0, 0);
                facingDirection += 120 * elapsed; // Faster rotation during search
                if (facingDirection >= 360) facingDirection -= 360;

                // Move to next search point after a moment
                new FlxTimer().start(1.5, function(timer) {
                    currentSearchIndex++;
                });
            } else {
                // Move towards search point
                var direction = myCenter.angleBetween(target);
                velocity.set(
                    Math.cos(direction * Math.PI / 180) * currentSpeed,
                    Math.sin(direction * Math.PI / 180) * currentSpeed
                );
            }

            myCenter.put();
        }

        // Give up search after time limit or all points checked
        if (searchTimer >= maxSearchTime || currentSearchIndex >= searchPoints.length) {
            transitionToReturn();
        }
    }

    /**
     * Update return state
     */
    private function updateReturnState(elapsed:Float):Void {
        if (patrolPoints.length == 0) {
            currentState = PATROL;
            return;
        }

        var nearestPatrolPoint = findNearestPatrolPoint();
        var targetPoint = FlxPoint.get(nearestPatrolPoint.x, nearestPatrolPoint.y);
        var myCenter = FlxPoint.get(x + width/2, y + height/2);

        // Move towards nearest patrol point
        if (myCenter.distanceTo(targetPoint) > 16) {
            var direction = myCenter.angleBetween(targetPoint);
            velocity.set(
                Math.cos(direction * Math.PI / 180) * currentSpeed,
                Math.sin(direction * Math.PI / 180) * currentSpeed
            );
        } else {
            // Reached patrol route, resume patrol
            currentState = PATROL;
            velocity.set(0, 0);
        }

        targetPoint.put();
        myCenter.put();
    }

    /**
     * State transition methods
     */
    private function transitionToInvestigate():Void {
        previousState = currentState;
        currentState = INVESTIGATE;
        investigationTimer = 0;
        currentSpeed = baseSpeed;

        // Set investigation target to last known player position or random nearby point
        if (lastKnownPlayerPosition != null) {
            investigationTarget = lastKnownPlayerPosition.copyTo();
        } else {
            // Investigate in the direction we're facing
            investigationTarget = FlxPoint.get(
                x + Math.cos(facingDirection * Math.PI / 180) * 60,
                y + Math.sin(facingDirection * Math.PI / 180) * 60
            );
        }
    }

    private function transitionToChase():Void {
        previousState = currentState;
        currentState = CHASE;
        playerLostTimer = 0;
        currentSpeed = chaseSpeed;
    }

    private function transitionToSearch():Void {
        previousState = currentState;
        currentState = SEARCH;
        searchTimer = 0;
        currentSearchIndex = 0;
        currentSpeed = baseSpeed;
        generateSearchPoints();
    }

    private function transitionToReturn():Void {
        previousState = currentState;
        currentState = RETURN;
        currentSpeed = baseSpeed;
        awarenessLevel *= 0.5; // Reduce awareness when returning

        // Clean up search points
        if (searchPoints != null) {
            for (point in searchPoints) {
                point.put();
            }
            searchPoints = null;
        }
    }

    private function startPatrol():Void {
        currentState = PATROL;
        currentPatrolIndex = 0;
        patrolDirection = 1;
        currentSpeed = baseSpeed;
    }

    /**
     * Generate search points around last known player location
     */
    private function generateSearchPoints():Void {
        if (searchPoints != null) {
            for (point in searchPoints) {
                point.put();
            }
        }

        searchPoints = [];

        var centerX = x + width/2;
        var centerY = y + height/2;

        if (lastKnownPlayerPosition != null) {
            centerX = lastKnownPlayerPosition.x;
            centerY = lastKnownPlayerPosition.y;
        }

        // Create search points in a circle around the center
        var searchRadius = 80.0;
        var pointCount = 6;

        for (i in 0...pointCount) {
            var angle = (i / pointCount) * Math.PI * 2;
            var px = centerX + Math.cos(angle) * searchRadius;
            var py = centerY + Math.sin(angle) * searchRadius;
            searchPoints.push(FlxPoint.get(px, py));
        }

        // Shuffle search order
        FlxG.random.shuffle(searchPoints);
    }

    /**
     * Find nearest patrol point
     */
    private function findNearestPatrolPoint():MazePosition {
        if (patrolPoints.length == 0) return null;

        var myCenter = FlxPoint.get(x + width/2, y + height/2);
        var nearest = patrolPoints[0];
        var nearestDistance = Math.POSITIVE_INFINITY;

        for (i in 0...patrolPoints.length) {
            var point = patrolPoints[i];
            var pointPos = FlxPoint.get(point.x, point.y);
            var distance = myCenter.distanceTo(pointPos);

            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearest = point;
                currentPatrolIndex = i;
            }

            pointPos.put();
        }

        myCenter.put();
        return nearest;
    }

    /**
     * Update facing direction based on movement
     */
    private function updateFacingDirection():Void {
        if (velocity.length > 10 && currentState != INVESTIGATE && currentState != SEARCH) {
            facingDirection = Math.atan2(velocity.y, velocity.x) * 180 / Math.PI;
        }

        // Update sprite rotation to show direction
        angle = facingDirection;
    }

    /**
     * Update alert indicator
     */
    private function updateAlertIndicator():Void {
        if (alertIndicator != null) {
            alertIndicator.x = x + width/2 - alertIndicator.width/2;
            alertIndicator.y = y - alertIndicator.height - 4;

            // Show indicator when suspicious or chasing
            alertIndicator.visible = awarenessLevel > suspicionThreshold;

            // Change color based on awareness level
            if (awarenessLevel >= chaseThreshold) {
                alertIndicator.color = FlxColor.RED; // Chasing
            } else if (awarenessLevel >= suspicionThreshold) {
                alertIndicator.color = FlxColor.ORANGE; // Suspicious
            } else {
                alertIndicator.color = FlxColor.YELLOW; // Normal
            }
        }
    }

    /**
     * Check if enemy has caught the player
     */
    public function isCollidingWithPlayer():Bool {
        if (targetPlayer == null) return false;

        // Simple bounding box collision
        return overlaps(targetPlayer);
    }

    /**
     * Set maze and pathfinding data
     */
    public function setMazeData(floor:MazeFloor, pathfinder:MazePathfinder):Void {
        this.mazeFloor = floor;
        this.pathfinder = pathfinder;
    }

    override public function destroy():Void {
        if (visionCone != null) {
            visionCone.destroy();
        }

        if (alertIndicator != null) {
            alertIndicator.destroy();
        }

        if (lastKnownPlayerPosition != null) {
            lastKnownPlayerPosition.put();
        }

        if (investigationTarget != null) {
            investigationTarget.put();
        }

        if (pathfindingTarget != null) {
            pathfindingTarget.put();
        }

        if (searchPoints != null) {
            for (point in searchPoints) {
                point.put();
            }
        }

        super.destroy();
    }
}

/**
 * Enemy vision cone visualization
 */
class MazeEnemyVisionCone extends FlxSprite {

    private var enemy:MazeEnemy;

    public function new(enemy:MazeEnemy) {
        super();
        this.enemy = enemy;

        makeGraphic(300, 300, FlxColor.TRANSPARENT, true);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (enemy != null) {
            x = enemy.x + enemy.width/2 - width/2;
            y = enemy.y + enemy.height/2 - height/2;

            drawVisionCone();
        }
    }

    private function drawVisionCone():Void {
        graphic.bitmap.fillRect(graphic.bitmap.rect, 0x00000000);

        if (enemy == null) return;

        var centerX = width / 2;
        var centerY = height / 2;
        var direction = enemy.facingDirection * Math.PI / 180;
        var range = enemy.visionRange;
        var halfAngle = enemy.visionAngle * Math.PI / 180;

        // Choose color based on enemy state
        var coneColor = switch (enemy.currentState) {
            case CHASE: 0x60FF0000; // Red when chasing
            case INVESTIGATE: 0x60FFAA00; // Orange when investigating
            case SEARCH: 0x60FFFF00; // Yellow when searching
            default: 0x60AA00AA; // Purple when patrolling
        }

        // Draw cone
        var vertices = [];
        vertices.push(FlxPoint.get(centerX, centerY));

        var steps = 15;
        for (i in 0...steps + 1) {
            var angle = direction - halfAngle + (halfAngle * 2 * i / steps);
            var px = centerX + Math.cos(angle) * range;
            var py = centerY + Math.sin(angle) * range;
            vertices.push(FlxPoint.get(px, py));
        }

        drawTriangleFan(vertices, coneColor);

        for (vertex in vertices) {
            vertex.put();
        }
    }

    private function drawTriangleFan(vertices:Array<FlxPoint>, color:Int):Void {
        if (vertices.length < 3) return;

        var graphics = graphic.bitmap;

        for (i in 1...(vertices.length - 1)) {
            drawTriangle(graphics, vertices[0], vertices[i], vertices[i + 1], color);
        }
    }

    private function drawTriangle(graphics:openfl.display.BitmapData, p1:FlxPoint, p2:FlxPoint, p3:FlxPoint, color:Int):Void {
        var lineColor = color | 0xFF000000;

        drawLine(graphics, Std.int(p1.x), Std.int(p1.y), Std.int(p2.x), Std.int(p2.y), lineColor);
        drawLine(graphics, Std.int(p2.x), Std.int(p2.y), Std.int(p3.x), Std.int(p3.y), lineColor);
        drawLine(graphics, Std.int(p3.x), Std.int(p3.y), Std.int(p1.x), Std.int(p1.y), lineColor);
    }

    private function drawLine(graphics:openfl.display.BitmapData, x0:Int, y0:Int, x1:Int, y1:Int, color:Int):Void {
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
 * Simple pathfinding for maze navigation
 */
class MazePathfinder {

    private var mazeFloor:MazeFloor;
    private var tileSize:Int = 32;

    public function new(floor:MazeFloor) {
        this.mazeFloor = floor;
    }

    /**
     * Find path from start to end using A* algorithm
     */
    public function findPath(startX:Float, startY:Float, endX:Float, endY:Float):Array<FlxPoint> {
        if (mazeFloor == null) return [];

        // Convert world coordinates to grid coordinates
        var startGridX = Std.int(startX / tileSize);
        var startGridY = Std.int(startY / tileSize);
        var endGridX = Std.int(endX / tileSize);
        var endGridY = Std.int(endY / tileSize);

        // Simple pathfinding - for now just return direct line
        // TODO: Implement proper A* pathfinding
        var path:Array<FlxPoint> = [];

        // Add waypoints along the path
        var steps = 5;
        for (i in 0...steps + 1) {
            var t = i / steps;
            var x = startX + (endX - startX) * t;
            var y = startY + (endY - startY) * t;
            path.push(FlxPoint.get(x, y));
        }

        return path;
    }
}
