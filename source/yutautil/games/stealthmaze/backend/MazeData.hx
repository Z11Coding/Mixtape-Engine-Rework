package yutautil.games.stealthmaze.backend;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import haxe.ds.Vector;

enum MazeTileType {
    WALL;
    FLOOR;
    EXIT;
    FAKE_EXIT;
    CLOSET_1P;  // 1-person closet
    CLOSET_2P;  // 2-person closet
    STAIRS_UP;  // Stairs going up
    STAIRS_DOWN; // Stairs going down
    DOOR;       // Door between rooms
    OBSTACLE;   // Furniture/obstacles within rooms
}

enum RoomType {
    BEDROOM;
    LIVING_ROOM;
    KITCHEN;
    BATHROOM;
    HALLWAY;
    CORRIDOR;
    CLOSET_ROOM;
    STORAGE;
    OFFICE;
    DINING_ROOM;
    BASEMENT;
    ATTIC;
}

/**
 * Represents a door that can be opened/closed
 */
class Door {
    public var bounds:FlxRect;
    public var isOpen:Bool;
    public var side:String; // "top", "bottom", "left", "right"
    public var requiresKey:Bool;
    public var room:Room; // Parent room

    public function new(x:Float, y:Float, width:Float, height:Float, side:String, room:Room, requiresKey:Bool = false) {
        this.bounds = new FlxRect(x, y, width, height);
        this.side = side;
        this.room = room;
        this.isOpen = false;
        this.requiresKey = requiresKey;
    }

    public function toggle():Void {
        if (!requiresKey) {
            isOpen = !isOpen;
        }
    }

    public function open():Void {
        if (!requiresKey) {
            isOpen = true;
        }
    }

    public function close():Void {
        isOpen = false;
    }

    public function canPass():Bool {
        return isOpen;
    }
}

enum MazeDifficulty {
    EASY;     // 1-2 floors, simple rooms, few enemies
    MEDIUM;   // 2-3 floors, moderate layout, some fake exits
    HARD;     // 3-4 floors, complex layout, many enemies
    EXPERT;   // 4-5 floors, very complex, smart enemies
    NIGHTMARE;// 5+ floors, extremely difficult, multiple objectives
}

/**
 * Represents a room in the house
 */
class Room {
    public var bounds:FlxRect;
    public var type:RoomType;
    public var floorIndex:Int;
    public var walls:Array<FlxRect>;      // Wall boundaries for collision
    public var obstacles:Array<FlxRect>;  // Furniture/obstacles
    public var doors:Array<Door>;         // Door objects for opening/closing
    public var entrances:Array<FlxRect>;  // Designated entrance areas
    public var lighting:Float = 1.0;     // Light level (0-1)
    public var connectedRooms:Array<Int>; // IDs of connected rooms

    public function new(x:Float, y:Float, width:Float, height:Float, type:RoomType, floorIndex:Int) {
        this.bounds = new FlxRect(x, y, width, height);
        this.type = type;
        this.floorIndex = floorIndex;
        this.walls = [];
        this.obstacles = [];
        this.doors = [];
        this.entrances = [];
        this.connectedRooms = [];

        // Create perimeter walls with entrance gaps
        createPerimeterWallsWithEntrances();
    }

    private function createPerimeterWallsWithEntrances():Void {
        var entranceSize = 80; // Size of entrance gaps
        var wallThickness = 20;

        // Top wall with potential entrance
        var topEntranceX = bounds.x + bounds.width * 0.5 - entranceSize/2;
        walls.push(new FlxRect(bounds.x, bounds.y, topEntranceX - bounds.x, wallThickness));
        walls.push(new FlxRect(topEntranceX + entranceSize, bounds.y, bounds.x + bounds.width - (topEntranceX + entranceSize), wallThickness));
        entrances.push(new FlxRect(topEntranceX, bounds.y, entranceSize, wallThickness));

        // Bottom wall with potential entrance
        var bottomEntranceX = bounds.x + bounds.width * 0.5 - entranceSize/2;
        walls.push(new FlxRect(bounds.x, bounds.y + bounds.height - wallThickness, bottomEntranceX - bounds.x, wallThickness));
        walls.push(new FlxRect(bottomEntranceX + entranceSize, bounds.y + bounds.height - wallThickness, bounds.x + bounds.width - (bottomEntranceX + entranceSize), wallThickness));
        entrances.push(new FlxRect(bottomEntranceX, bounds.y + bounds.height - wallThickness, entranceSize, wallThickness));

        // Left wall with potential entrance
        var leftEntranceY = bounds.y + bounds.height * 0.5 - entranceSize/2;
        walls.push(new FlxRect(bounds.x, bounds.y, wallThickness, leftEntranceY - bounds.y));
        walls.push(new FlxRect(bounds.x, leftEntranceY + entranceSize, wallThickness, bounds.y + bounds.height - (leftEntranceY + entranceSize)));
        entrances.push(new FlxRect(bounds.x, leftEntranceY, wallThickness, entranceSize));

        // Right wall with potential entrance
        var rightEntranceY = bounds.y + bounds.height * 0.5 - entranceSize/2;
        walls.push(new FlxRect(bounds.x + bounds.width - wallThickness, bounds.y, wallThickness, rightEntranceY - bounds.y));
        walls.push(new FlxRect(bounds.x + bounds.width - wallThickness, rightEntranceY + entranceSize, wallThickness, bounds.y + bounds.height - (rightEntranceY + entranceSize)));
        entrances.push(new FlxRect(bounds.x + bounds.width - wallThickness, rightEntranceY, wallThickness, entranceSize));
    }

    public function createDoorway(side:String):FlxRect {
        var entranceSize = 80;
        var wallThickness = 20;

        switch(side) {
            case "top":
                var x = bounds.x + bounds.width * 0.5 - entranceSize/2;
                return new FlxRect(x, bounds.y, entranceSize, wallThickness);
            case "bottom":
                var x = bounds.x + bounds.width * 0.5 - entranceSize/2;
                return new FlxRect(x, bounds.y + bounds.height - wallThickness, entranceSize, wallThickness);
            case "left":
                var y = bounds.y + bounds.height * 0.5 - entranceSize/2;
                return new FlxRect(bounds.x, y, wallThickness, entranceSize);
            case "right":
                var y = bounds.y + bounds.height * 0.5 - entranceSize/2;
                return new FlxRect(bounds.x + bounds.width - wallThickness, y, wallThickness, entranceSize);
        }
        return null;
    }

    public function addObstacle(x:Float, y:Float, width:Float, height:Float):Void {
        obstacles.push(new FlxRect(x, y, width, height));
    }

    public function addDoor(side:String, requiresKey:Bool = false):Door {
        var entranceSize = 80;
        var wallThickness = 20;
        var door:Door = null;

        switch(side) {
            case "top":
                var x = bounds.x + bounds.width * 0.5 - entranceSize/2;
                door = new Door(x, bounds.y, entranceSize, wallThickness, side, this, requiresKey);
            case "bottom":
                var x = bounds.x + bounds.width * 0.5 - entranceSize/2;
                door = new Door(x, bounds.y + bounds.height - wallThickness, entranceSize, wallThickness, side, this, requiresKey);
            case "left":
                var y = bounds.y + bounds.height * 0.5 - entranceSize/2;
                door = new Door(bounds.x, y, wallThickness, entranceSize, side, this, requiresKey);
            case "right":
                var y = bounds.y + bounds.height * 0.5 - entranceSize/2;
                door = new Door(bounds.x + bounds.width - wallThickness, y, wallThickness, entranceSize, side, this, requiresKey);
        }

        if (door != null) {
            doors.push(door);
            // Remove wall section where door is placed so we can walk through when open
            removeWallSection(door.bounds.x - 5, door.bounds.y - 5, door.bounds.width + 10, door.bounds.height + 10);
        }

        return door;
    }

    public function removeWallSection(x:Float, y:Float, width:Float, height:Float):Void {
        var doorArea = new FlxRect(x, y, width, height);

        // Remove walls that intersect with door area
        walls = walls.filter(function(wall) {
            return !wall.overlaps(doorArea);
        });
    }

    public function isPointInRoom(x:Float, y:Float):Bool {
        return bounds.containsPoint(new FlxPoint(x, y));
    }

    public function getRandomPointInRoom():FlxPoint {
        // Get random point avoiding obstacles
        var attempts = 0;
        while (attempts < 50) {
            var testX = bounds.x + 50 + Math.random() * (bounds.width - 100);
            var testY = bounds.y + 50 + Math.random() * (bounds.height - 100);

            var blocked = false;
            for (obstacle in obstacles) {
                if (obstacle.containsPoint(new FlxPoint(testX, testY))) {
                    blocked = true;
                    break;
                }
            }

            if (!blocked) {
                return new FlxPoint(testX, testY);
            }
            attempts++;
        }

        // Fallback to center if no free space found
        return new FlxPoint(bounds.x + bounds.width/2, bounds.y + bounds.height/2);
    }
}

/**
 * Represents a single cell in the maze
 */
class MazeCell {
    public var type:MazeTileType;
    public var x:Int;
    public var y:Int;
    public var isVisited:Bool = false;
    public var hasLight:Bool = false; // Whether this cell is lit up

    public function new(x:Int, y:Int, type:MazeTileType = FLOOR) {
        this.x = x;
        this.y = y;
        this.type = type;
    }
}

/**
 * Represents a position and direction for entities
 */
class MazePosition {
    public var x:Float;
    public var y:Float;
    public var direction:Float; // Rotation in degrees (0 = right, 90 = down, 180 = left, 270 = up)

    public function new(x:Float = 0, y:Float = 0, direction:Float = 0) {
        this.x = x;
        this.y = y;
        this.direction = direction;
    }

    public function copy():MazePosition {
        return new MazePosition(x, y, direction);
    }

    public function distanceTo(other:MazePosition):Float {
        var dx = x - other.x;
        var dy = y - other.y;
        return Math.sqrt(dx * dx + dy * dy);
    }

    public function getDirectionTo(other:MazePosition):Float {
        var dx = other.x - x;
        var dy = other.y - y;
        return Math.atan2(dy, dx) * 180 / Math.PI;
    }
}

/**
 * Represents an enemy spawn point
 */
class EnemySpawnPoint {
    public var position:MazePosition;
    public var patrolPoints:Array<MazePosition>;
    public var alertness:Float = 0.5; // 0-1 scale, higher means more alert
    public var speed:Float = 1.0;

    public function new(x:Float, y:Float, ?patrolPoints:Array<MazePosition>) {
        this.position = new MazePosition(x, y, 0);
        this.patrolPoints = patrolPoints != null ? patrolPoints : [];
    }
}

/**
 * Represents a collectible item in the maze
 */
class Collectible {
    public var position:MazePosition;
    public var type:CollectibleType;
    public var collected:Bool = false;

    public function new(x:Float, y:Float, type:CollectibleType) {
        this.position = new MazePosition(x, y);
        this.type = type;
    }
}

enum CollectibleType {
    RED_OBJECTIVE;   // Main objective to collect
    GOLDEN_BONUS;    // Bonus collectibles for extra score/rewards
}

/**
 * Represents a single floor of the house/building
 */
class MazeFloor {
    public var bounds:FlxRect;                      // Total floor area
    public var rooms:Array<Room>;                   // All rooms on this floor
    public var playerStartPosition:MazePosition;    // Where player spawns
    public var enemySpawns:Array<EnemySpawnPoint>; // Enemy spawn points
    public var collectibles:Array<Collectible>;    // Collectibles on this floor
    public var floorIndex:Int;                     // Which floor this is (0=ground)
    public var stairsUp:Array<FlxPoint>;           // Stairs going up
    public var stairsDown:Array<FlxPoint>;         // Stairs going down

    // Grid properties for pathfinding compatibility
    public var width:Int;
    public var height:Int;
    private var cells:Array<Array<MazeCell>>;

    public function new(width:Float, height:Float, floorIndex:Int = 0) {
        this.bounds = new FlxRect(0, 0, width, height);
        this.floorIndex = floorIndex;
        this.rooms = [];
        this.enemySpawns = [];
        this.collectibles = [];
        this.stairsUp = [];
        this.stairsDown = [];

        // Set up grid dimensions (convert to tile coordinates)
        this.width = Math.ceil(width / 32);  // 32 pixels per tile
        this.height = Math.ceil(height / 32);

        // Initialize cells array
        cells = [];
        for (y in 0...this.height) {
            cells[y] = [];
            for (x in 0...this.width) {
                cells[y][x] = new MazeCell(x, y, WALL);
            }
        }

        // Default spawn position (will be overridden during generation)
        playerStartPosition = new MazePosition(100, 100);
    }

    public function addRoom(room:Room):Int {
        rooms.push(room);
        return rooms.length - 1; // Return room ID
    }

    public function getRoomAt(x:Float, y:Float):Room {
        for (room in rooms) {
            if (room.isPointInRoom(x, y)) {
                return room;
            }
        }
        return null;
    }

    public function isWalkable(x:Float, y:Float):Bool {
        var point = new FlxPoint(x, y);

        // First check if we're inside any room
        var insideRoom = false;
        for (room in rooms) {
            if (room.bounds.containsPoint(point)) {
                insideRoom = true;

                // If inside room, check obstacles only (not walls)
                for (obstacle in room.obstacles) {
                    if (obstacle.containsPoint(point)) {
                        return false; // Blocked by obstacle
                    }
                }

                // Check if we're hitting actual wall sections (not doorways)
                for (wall in room.walls) {
                    if (wall.containsPoint(point)) {
                        return false; // Blocked by wall
                    }
                }

                // Check doors - if closed, they block movement
                for (door in room.doors) {
                    if (door.bounds.containsPoint(point) && !door.canPass()) {
                        return false; // Blocked by closed door
                    }
                }

                break; // Found the room we're in
            }
        }

        // Check if we're at a door between rooms
        for (room in rooms) {
            for (door in room.doors) {
                if (door.bounds.containsPoint(point) && !door.canPass()) {
                    return false; // Blocked by closed door
                }
            }
        }

        // If not inside any room, we're in open space - that's walkable
        return true;
    }

    public function addEnemySpawn(x:Float, y:Float, ?patrolPoints:Array<MazePosition>):Void {
        enemySpawns.push(new EnemySpawnPoint(x, y, patrolPoints));
    }

    public function addCollectible(x:Float, y:Float, type:CollectibleType):Void {
        collectibles.push(new Collectible(x, y, type));
    }

    public function addStairsUp(x:Float, y:Float):Void {
        stairsUp.push(new FlxPoint(x, y));
    }

    public function addStairsDown(x:Float, y:Float):Void {
        stairsDown.push(new FlxPoint(x, y));
    }

    public function getRandomRoomOfType(type:RoomType):Room {
        var roomsOfType = rooms.filter(function(room) return room.type == type);
        if (roomsOfType.length == 0) return null;
        return roomsOfType[Math.floor(Math.random() * roomsOfType.length)];
    }

    public function getRandomRoom():Room {
        if (rooms.length == 0) return null;
        return rooms[Math.floor(Math.random() * rooms.length)];
    }

    /**
     * Get cell at tile coordinates (for pathfinding compatibility)
     */
    public function getCell(x:Int, y:Int):MazeCell {
        if (x < 0 || x >= width || y < 0 || y >= height) {
            return null;
        }
        return cells[y][x];
    }

    /**
     * Set cell type at tile coordinates
     */
    public function setCell(x:Int, y:Int, type:MazeTileType):Void {
        if (x < 0 || x >= width || y < 0 || y >= height) {
            return;
        }
        cells[y][x].type = type;
    }
}

/**
 * Complete maze data including all floors and metadata
 */
class MazeData {
    public var floors:Array<MazeFloor>;
    public var difficulty:MazeDifficulty;
    public var currentFloor:Int = 0;
    public var name:String;
    public var isCustom:Bool = false;

    // Generation settings
    public var roomCount:Int = 5; // Number of rooms to generate
    public var corridorWidth:Int = 3; // Width of corridors
    public var enemyCount:Int = 3; // Enemies per floor
    public var goldenCollectibleCount:Int = 1; // Golden collectibles per floor

    public function new(difficulty:MazeDifficulty = MEDIUM, name:String = "Generated Maze") {
        this.difficulty = difficulty;
        this.name = name;
        this.floors = [];
    }

    public function addFloor(floor:MazeFloor):Void {
        floors.push(floor);
    }

    public function getCurrentFloor():MazeFloor {
        if (currentFloor < 0 || currentFloor >= floors.length) return null;
        return floors[currentFloor];
    }

    public function nextFloor():Bool {
        if (currentFloor + 1 < floors.length) {
            currentFloor++;
            return true;
        }
        return false;
    }

    public function previousFloor():Bool {
        if (currentFloor > 0) {
            currentFloor--;
            return true;
        }
        return false;
    }

    public function getFloorCount():Int {
        return floors.length;
    }

    /**
     * Get difficulty-based settings for room generation
     */
    public static function getDifficultySettings(difficulty:MazeDifficulty):{
        floorSize: {width: Float, height: Float},
        floorCount: Int,
        roomCount: Int,
        enemyCount: Int,
        goldenCount: Int,
        fakeExitCount: Int,
        closetRatio: Float, // Percentage of 1-person closets vs 2-person
        enemySpeed: Float,
        enemyAlertness: Float,
        roomSizeRange: {min: Float, max: Float}
    } {
        return switch (difficulty) {
            case EASY: {
                floorSize: {width: 4000, height: 3000},    // MASSIVE floors
                floorCount: 1,
                roomCount: 6,
                enemyCount: 2,
                goldenCount: 1,
                fakeExitCount: 0,
                closetRatio: 0.3, // 30% are 1-person
                enemySpeed: 0.8,
                enemyAlertness: 0.3,
                roomSizeRange: {min: 350, max: 1500}       // Much larger room range
            }
            case MEDIUM: {
                floorSize: {width: 5000, height: 4000},    // Enormous floors
                floorCount: 2,
                roomCount: 8,
                enemyCount: 3,
                goldenCount: 2,
                fakeExitCount: 1,
                closetRatio: 0.5, // 50% are 1-person
                enemySpeed: 1.0,
                enemyAlertness: 0.5,
                roomSizeRange: {min: 400, max: 1800}
            }
            case HARD: {
                floorSize: {width: 6000, height: 5000},    // Gigantic floors
                floorCount: 3,
                roomCount: 12,
                enemyCount: 4,
                goldenCount: 2,
                fakeExitCount: 2,
                closetRatio: 0.7, // 70% are 1-person
                enemySpeed: 1.2,
                enemyAlertness: 0.7,
                roomSizeRange: {min: 450, max: 2000}
            }
            case EXPERT: {
                floorSize: {width: 7000, height: 6000},    // Colossal floors
                floorCount: 4,
                roomCount: 16,
                enemyCount: 5,
                goldenCount: 3,
                fakeExitCount: 3,
                closetRatio: 0.8, // 80% are 1-person
                enemySpeed: 1.4,
                enemyAlertness: 0.8,
                roomSizeRange: {min: 500, max: 2200}
            }
            case NIGHTMARE: {
                floorSize: {width: 8000, height: 7000},    // INSANE floors
                floorCount: 6,
                roomCount: 20,
                enemyCount: 7,
                goldenCount: 4,
                fakeExitCount: 5,
                closetRatio: 0.9, // 90% are 1-person
                enemySpeed: 1.6,
                enemyAlertness: 0.9,
                roomSizeRange: {min: 550, max: 2500}
            }
        };
    }
}

/**
 * Maze save/load data structure
 */
class MazeSaveData {
    public var name:String;
    public var difficulty:MazeDifficulty;
    public var isCustom:Bool;
    public var createdDate:String;
    public var floors:Array<MazeFloorSaveData>;

    public function new() {
        floors = [];
    }
}

/**
 * Floor save data structure
 */
class MazeFloorSaveData {
    public var width:Int;
    public var height:Int;
    public var cells:Array<Array<Int>>; // Store tile types as integers
    public var playerStartX:Float;
    public var playerStartY:Float;
    public var playerStartDir:Float;
    public var enemySpawns:Array<EnemySpawnSaveData>;
    public var collectibles:Array<CollectibleSaveData>;

    public function new() {
        cells = [];
        enemySpawns = [];
        collectibles = [];
    }
}

/**
 * Enemy spawn save data
 */
class EnemySpawnSaveData {
    public var x:Float;
    public var y:Float;
    public var patrolPointsX:Array<Float>;
    public var patrolPointsY:Array<Float>;
    public var patrolPointsDirs:Array<Float>;
    public var alertness:Float;
    public var speed:Float;

    public function new() {
        patrolPointsX = [];
        patrolPointsY = [];
        patrolPointsDirs = [];
    }
}

/**
 * Collectible save data
 */
class CollectibleSaveData {
    public var x:Float;
    public var y:Float;
    public var type:Int; // CollectibleType as integer

    public function new() {}
}
