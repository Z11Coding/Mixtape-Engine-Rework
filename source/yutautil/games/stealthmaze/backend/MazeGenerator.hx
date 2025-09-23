package yutautil.games.stealthmaze.backend;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import yutautil.games.stealthmaze.backend.MazeData;

/**
 * House/building generation using room-based architecture
 */
class MazeGenerator {

    /**
     * Helper function: Get center of a FlxRect
     */
    private static function getRectCenter(rect:FlxRect):FlxPoint {
        return new FlxPoint(rect.x + rect.width / 2, rect.y + rect.height / 2);
    }

    /**
     * Helper function: Get distance from a point to the center of a FlxRect
     */
    private static function getDistanceToRectCenter(rect:FlxRect, point:FlxPoint):Float {
        var center = getRectCenter(rect);
        var dx = center.x - point.x;
        var dy = center.y - point.y;
        return Math.sqrt(dx * dx + dy * dy);
    }

    /**
     * Helper function: Get distance between centers of two FlxRects
     */
    private static function getDistanceBetweenRects(rect1:FlxRect, rect2:FlxRect):Float {
        var center1 = getRectCenter(rect1);
        var center2 = getRectCenter(rect2);
        var dx = center1.x - center2.x;
        var dy = center1.y - center2.y;
        return Math.sqrt(dx * dx + dy * dy);
    }

    /**
     * Generate a complete house/building based on difficulty
     */
    public static function generateMaze(difficulty:MazeDifficulty, ?customSettings:Dynamic):MazeData {
        var settings = MazeData.getDifficultySettings(difficulty);

        var mazeData = new MazeData(difficulty, "Generated " + Std.string(difficulty).toLowerCase() + " house");

        // Generate each floor
        for (floorIndex in 0...settings.floorCount) {
            var floor = generateFloor(
                settings.floorSize.width,
                settings.floorSize.height,
                floorIndex,
                settings
            );
            mazeData.addFloor(floor);
        }

        // Connect floors with stairs
        connectFloorsWithStairs(mazeData, settings);

        // Place collectibles randomly across floors
        placeCollectibles(mazeData, settings);

        // Add exits to make levels beatable
        addExitsToMaze(mazeData, settings);

        return mazeData;
    }

    /**
     * Generate a single floor with rooms
     */
    public static function generateFloor(
        width:Float,
        height:Float,
        floorIndex:Int,
        settings:Dynamic
    ):MazeFloor {
        var floor = new MazeFloor(width, height, floorIndex);

        // Generate rooms based on floor type
        if (floorIndex == 0) {
            generateGroundFloor(floor, settings);
        } else {
            generateUpperFloor(floor, settings);
        }

        // Connect rooms with doors/hallways
        connectRooms(floor);

        // Furnish rooms with obstacles
        furnishRooms(floor, settings);

        return floor;
    }

    /**
     * Generate ground floor layout with main rooms - Direct room connections, NO gaps
     */
    private static function generateGroundFloor(floor:MazeFloor, settings:Dynamic):Void {
        // Create grid-based room layout to ensure no gaps
        var gridWidth = 3; // 3x3 grid of rooms
        var gridHeight = 3;
        var roomWidth = floor.bounds.width / gridWidth;
        var roomHeight = floor.bounds.height / gridHeight;

        var roomTypes = [LIVING_ROOM, KITCHEN, HALLWAY, BEDROOM, BATHROOM, DINING_ROOM, OFFICE, STORAGE, CORRIDOR];
        var roomIndex = 0;

        // Generate rooms in a grid pattern with NO gaps
        for (gridY in 0...gridHeight) {
            for (gridX in 0...gridWidth) {
                var x = gridX * roomWidth;
                var y = gridY * roomHeight;

                var roomType = roomTypes[roomIndex % roomTypes.length];

                // Make center room always a hallway for navigation
                if (gridX == 1 && gridY == 1) {
                    roomType = HALLWAY;
                }

                var room = new Room(x, y, roomWidth, roomHeight, roomType, floor.floorIndex);
                floor.addRoom(room);
                roomIndex++;
            }
        }

        // Set player spawn in center room (hallway)
        var centerRoom = floor.rooms[4]; // Center of 3x3 grid
        floor.playerStartPosition = new MazePosition(
            centerRoom.bounds.x + centerRoom.bounds.width / 2,
            centerRoom.bounds.y + centerRoom.bounds.height / 2,
            0.0
        );

        // Add doors to some rooms (not all - some should be open)
        generateDoorsForRooms(floor);
    }

    /**
     * Add doors to selected rooms
     */
    private static function generateDoorsForRooms(floor:MazeFloor):Void {
        var roomCount = floor.rooms.length;
        var doorChance = 0.6; // 60% of rooms get doors

        for (i in 0...roomCount) {
            var room = floor.rooms[i];

            // Skip corridor rooms - they should remain open
            if (room.type == CORRIDOR) continue;

            // Random chance to add door
            if (FlxG.random.bool(doorChance)) {
                // Choose a random side for the door
                var sides = ["top", "bottom", "left", "right"];
                var side = FlxG.random.getObject(sides);

                // Some doors require keys (higher security rooms)
                var requiresKey = (room.type == OFFICE || room.type == STORAGE) && FlxG.random.bool(0.3);

                room.addDoor(side, requiresKey);
            }
        }
    }

    /**
     * Generate upper floor layout with bedrooms and offices - Grid-based for direct connections
     */
    private static function generateUpperFloor(floor:MazeFloor, settings:Dynamic):Void {
        // Create grid-based room layout for upper floors
        var gridWidth = 4; // 4x3 grid for upper floors (more rooms)
        var gridHeight = 3;
        var roomWidth = floor.bounds.width / gridWidth;
        var roomHeight = floor.bounds.height / gridHeight;

        var roomTypes = [BEDROOM, OFFICE, BATHROOM, CORRIDOR, BEDROOM, STORAGE, OFFICE, BEDROOM, CORRIDOR, BATHROOM, OFFICE, BEDROOM];
        var roomIndex = 0;

        // Generate rooms in a grid pattern with NO gaps
        for (gridY in 0...gridHeight) {
            for (gridX in 0...gridWidth) {
                var x = gridX * roomWidth;
                var y = gridY * roomHeight;

                var roomType = roomTypes[roomIndex % roomTypes.length];

                // Make some rooms corridors for navigation
                if ((gridX == 1 && gridY == 1) || (gridX == 2 && gridY == 1)) {
                    roomType = CORRIDOR;
                }

                var room = new Room(x, y, roomWidth, roomHeight, roomType, floor.floorIndex);
                floor.addRoom(room);
                roomIndex++;
            }
        }

        // Add doors to upper floor rooms
        generateDoorsForRooms(floor);
    }

    /**
     * Create a room at a specific position relative to a central room
     */
    private static function createRoomAtPosition(floor:MazeFloor, centralRoom:Room, type:RoomType, settings:Dynamic, angle:Float, distance:Float):Room {
        var size = getRoomSize(type, settings);

        var centerX = centralRoom.bounds.x + centralRoom.bounds.width / 2;
        var centerY = centralRoom.bounds.y + centralRoom.bounds.height / 2;

        var angleRad = angle * Math.PI / 180;
        var x = centerX + Math.cos(angleRad) * distance - size.x / 2;
        var y = centerY + Math.sin(angleRad) * distance - size.y / 2;

        // Ensure room stays within floor bounds with generous margin
        x = Math.max(100, Math.min(x, floor.bounds.width - size.x - 100));
        y = Math.max(100, Math.min(y, floor.bounds.height - size.y - 100));

        var newRoom = new Room(x, y, size.x, size.y, type, floor.floorIndex);

        if (!roomOverlapsWithExisting(newRoom, floor.rooms)) {
            return newRoom;
        }

        return null;
    }

    /**
     * Create a room near the central hallway - More flexible placement
     */
    private static function createRoomNearHallway(floor:MazeFloor, hallway:Room, type:RoomType, settings:Dynamic):Room {
        var size = getRoomSize(type, settings);
        var attempts = 0;

        while (attempts < 50) {  // More attempts for better placement
            // Try positions around the hallway with proper spacing
            var angle = Math.random() * Math.PI * 2;
            var distance = 200 + Math.random() * 100; // Better distance range

            var centerX = hallway.bounds.x + hallway.bounds.width / 2;
            var centerY = hallway.bounds.y + hallway.bounds.height / 2;

            var x = centerX + Math.cos(angle) * distance - size.x / 2;
            var y = centerY + Math.sin(angle) * distance - size.y / 2;

            // Ensure room stays within floor bounds with margin
            x = Math.max(50, Math.min(x, floor.bounds.width - size.x - 50));
            y = Math.max(50, Math.min(y, floor.bounds.height - size.y - 50));

            var newRoom = new Room(x, y, size.x, size.y, type, floor.floorIndex);

            if (!roomOverlapsWithExisting(newRoom, floor.rooms) &&
                getDistanceToRectCenter(newRoom.bounds, getRectCenter(hallway.bounds)) < 400) {
                return newRoom;
            }
            attempts++;
        }

        return null;
    }

    /**
     * Create a room anywhere on the floor when near-hallway placement fails
     */
    private static function createRoomAnywhere(floor:MazeFloor, type:RoomType, settings:Dynamic):Room {
        var size = getRoomSize(type, settings);
        var attempts = 0;

        while (attempts < 30) {
            var x = 50 + Math.random() * (floor.bounds.width - size.x - 100);
            var y = 50 + Math.random() * (floor.bounds.height - size.y - 100);

            var newRoom = new Room(x, y, size.x, size.y, type, floor.floorIndex);

            if (!roomOverlapsWithExisting(newRoom, floor.rooms)) {
                return newRoom;
            }
            attempts++;
        }

        return null;
    }

    /**
     * Create a room along a corridor - Better spacing and sizing
     */
    private static function createRoomAlongCorridor(floor:MazeFloor, corridor:Room, type:RoomType, settings:Dynamic, topSide:Bool):Room {
        var size = getRoomSize(type, settings);
        var spacing:Num = corridor.bounds.width / 6; // Better spacing calculation
        var x:Num = corridor.bounds.x + (Math.random() * (corridor.bounds.width - size.x));
        var y:Num = topSide ?
            corridor.bounds.y - size.y - 40 :  // More spacing from corridor
            corridor.bounds.y + corridor.bounds.height + 40;

        // Ensure room stays within floor bounds
        if (y < 50 || y + size.y > floor.bounds.height - 50) return null;
        x = Math.max(50, Math.min(x, floor.bounds.width - size.x - 50));

        var newRoom = new Room(x, y, size.x, size.y, type, floor.floorIndex);

        if (!roomOverlapsWithExisting(newRoom, floor.rooms)) {
            return newRoom;
        }

        return null;
    }

    /**
     * Get appropriate room size based on type and settings - Much larger for proper gameplay
     */
    private static function getRoomSize(type:RoomType, settings:Dynamic):{x:Float, y:Float} {
        var baseSize:{x:Num, y:Num} = switch (type) {
            case LIVING_ROOM: {x: 1200, y: 900};      // MASSIVE main room - bigger than typical screen
            case KITCHEN: {x: 800, y: 600};           // Very large cooking area
            case BEDROOM: {x: 700, y: 500};           // Big bedroom
            case BATHROOM: {x: 400, y: 350};          // Large bathroom
            case OFFICE: {x: 600, y: 450};            // Good workspace
            case STORAGE: {x: 350, y: 280};           // Storage room
            case HALLWAY: {x: 1400, y: 300};          // VERY long connecting hallway
            case CORRIDOR: {x: 1600, y: 320};         // Extremely wide upper floor corridor
            case DINING_ROOM: {x: 800, y: 600};       // Large dining space
            default: {x: 600, y: 400};                // Default large room
        };

        // Apply size variation based on settings (smaller variation for consistency)
        var variation = 0.2; // +/- 20%
        baseSize.x *= (1 + (Math.random() - 0.5) * variation);
        baseSize.y *= (1 + (Math.random() - 0.5) * variation);

        // Clamp to setting ranges if available, but ensure minimum playable size
        if (settings.roomSizeRange != null) {
            baseSize.x = Math.max(Math.max(settings.roomSizeRange.min, 150), Math.min(baseSize.x, settings.roomSizeRange.max));
            baseSize.y = Math.max(Math.max(settings.roomSizeRange.min, 120), Math.min(baseSize.y, settings.roomSizeRange.max));
        }

        return {x: baseSize.x, y: baseSize.y};
    }

    /**
     * Check if room overlaps with any existing rooms
     */
    private static function roomOverlapsWithExisting(newRoom:Room, existingRooms:Array<Room>):Bool {
        for (room in existingRooms) {
            if (newRoom.bounds.overlaps(room.bounds)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Connect rooms with doors and hallways - Ensure ALL rooms are connected
     */
    private static function connectRooms(floor:MazeFloor):Void {
        if (floor.rooms.length < 2) return;

        // Connect each room to at least one other room
        for (i in 0...floor.rooms.length) {
            var room = floor.rooms[i];
            var hasConnection = false;

            // Check if room already has connections
            for (connectedId in room.connectedRooms) {
                if (connectedId < floor.rooms.length) {
                    hasConnection = true;
                    break;
                }
            }

            if (!hasConnection) {
                var nearestRoom = findNearestUnconnectedRoom(room, floor.rooms);
                if (nearestRoom != null) {
                    connectTwoRooms(room, nearestRoom);
                    room.connectedRooms.push(floor.rooms.indexOf(nearestRoom));
                    nearestRoom.connectedRooms.push(floor.rooms.indexOf(room));
                } else {
                    // Force connection to closest room even if it's already connected
                    var closestRoom = findClosestRoom(room, floor.rooms);
                    if (closestRoom != null && closestRoom != room) {
                        connectTwoRooms(room, closestRoom);
                        room.connectedRooms.push(floor.rooms.indexOf(closestRoom));
                        closestRoom.connectedRooms.push(floor.rooms.indexOf(room));
                    }
                }
            }
        }

        // Ensure main navigation rooms (HALLWAY/CORRIDOR) connect to multiple rooms
        for (room in floor.rooms) {
            if ((room.type == HALLWAY || room.type == CORRIDOR) && room.connectedRooms.length < 3) {
                var nearbyRooms = findNearbyRooms(room, floor.rooms, 500); // Within 500 pixels
                for (nearbyRoom in nearbyRooms) {
                    if (room.connectedRooms.indexOf(floor.rooms.indexOf(nearbyRoom)) == -1 &&
                        room.connectedRooms.length < Math.min(5, floor.rooms.length - 1)) {
                        connectTwoRooms(room, nearbyRoom);
                        room.connectedRooms.push(floor.rooms.indexOf(nearbyRoom));
                        nearbyRoom.connectedRooms.push(floor.rooms.indexOf(room));
                    }
                }
            }
        }
    }

    /**
     * Check if two rooms can be connected
     */
    private static function roomsCanConnect(room1:Room, room2:Room):Bool {
        var distance = getDistanceBetweenRects(room1.bounds, room2.bounds);
        return distance < 150; // Maximum connection distance
    }

    /**
     * Connect two rooms with doors - Not needed with grid system
     */
    private static function connectTwoRooms(room1:Room, room2:Room):Void {
        // Grid system creates directly connected rooms, no doorway creation needed
        // Doors are added separately in generateDoorsForRooms()
    }

    /**
     * Find the best place to put a door between rooms
     */
    private static function findBestDoorPlacement(room1:Room, room2:Room):FlxPoint {
        // Find the closest edges and place door there
        var center1 = getRectCenter(room1.bounds);
        var center2 = getRectCenter(room2.bounds);

        // Determine which sides are facing each other
        var dx = center2.x - center1.x;
        var dy = center2.y - center1.y;

        // Place door on the side facing the other room
        if (Math.abs(dx) > Math.abs(dy)) {
            // Horizontal connection
            if (dx > 0) {
                // Room2 is to the right of Room1
                var x = room1.bounds.x + room1.bounds.width;
                var y = center1.y;
                return new FlxPoint(x, y);
            } else {
                // Room2 is to the left of Room1
                var x = room1.bounds.x;
                var y = center1.y;
                return new FlxPoint(x, y);
            }
        } else {
            // Vertical connection
            if (dy > 0) {
                // Room2 is below Room1
                var x = center1.x;
                var y = room1.bounds.y + room1.bounds.height;
                return new FlxPoint(x, y);
            } else {
                // Room2 is above Room1
                var x = center1.x;
                var y = room1.bounds.y;
                return new FlxPoint(x, y);
            }
        }
    }

    /**
     * Find nearest room that isn't already connected
     */
    private static function findNearestUnconnectedRoom(room:Room, allRooms:Array<Room>):Room {
        var nearest:Room = null;
        var nearestDistance = Math.POSITIVE_INFINITY;

        for (other in allRooms) {
            if (other == room || room.connectedRooms.indexOf(allRooms.indexOf(other)) >= 0) continue;

            var distance = getDistanceBetweenRects(room.bounds, other.bounds);
            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearest = other;
            }
        }

        return nearest;
    }

    /**
     * Find the closest room regardless of connection status
     */
    private static function findClosestRoom(room:Room, allRooms:Array<Room>):Room {
        var closest:Room = null;
        var closestDistance = Math.POSITIVE_INFINITY;

        for (other in allRooms) {
            if (other == room) continue;

            var distance = getDistanceBetweenRects(room.bounds, other.bounds);
            if (distance < closestDistance) {
                closestDistance = distance;
                closest = other;
            }
        }

        return closest;
    }

    /**
     * Find all rooms within a certain distance
     */
    private static function findNearbyRooms(room:Room, allRooms:Array<Room>, maxDistance:Float):Array<Room> {
        var nearbyRooms:Array<Room> = [];

        for (other in allRooms) {
            if (other == room) continue;

            var distance = getDistanceBetweenRects(room.bounds, other.bounds);
            if (distance <= maxDistance) {
                nearbyRooms.push(other);
            }
        }

        return nearbyRooms;
    }

    /**
     * Add furniture and obstacles to rooms
     */
    private static function furnishRooms(floor:MazeFloor, settings:Dynamic):Void {
        for (room in floor.rooms) {
            addFurniture(room, settings);
        }
    }

    /**
     * Add furniture to a specific room
     */
    private static function addFurniture(room:Room, settings:Dynamic):Void {
        var furnitureCount = switch (room.type) {
            case LIVING_ROOM: 4;
            case KITCHEN: 3;
            case BEDROOM: 2;
            case BATHROOM: 1;
            case OFFICE: 2;
            default: 1;
        };

        for (i in 0...furnitureCount) {
            // Place furniture randomly, avoiding doors
            var attempts = 0;
            while (attempts < 10) {
                var fWidth = 30 + Math.random() * 40;
                var fHeight = 20 + Math.random() * 30;
                var fX = room.bounds.x + 20 + Math.random() * (room.bounds.width - fWidth - 40);
                var fY = room.bounds.y + 20 + Math.random() * (room.bounds.height - fHeight - 40);

                // Check if furniture placement conflicts with doors
                var conflictsWithDoor = false;
                for (door in room.doors) {
                    if (Math.abs(door.bounds.x - (fX + fWidth/2)) < 50 && Math.abs(door.bounds.y - (fY + fHeight/2)) < 50) {
                        conflictsWithDoor = true;
                        break;
                    }
                }

                if (!conflictsWithDoor) {
                    room.addObstacle(fX, fY, fWidth, fHeight);
                    break;
                }
                attempts++;
            }
        }
    }

    /**
     * Connect floors with stairs
     */
    private static function connectFloorsWithStairs(mazeData:MazeData, settings:Dynamic):Void {
        for (i in 0...(mazeData.floors.length - 1)) {
            var lowerFloor = mazeData.floors[i];
            var upperFloor = mazeData.floors[i + 1];

            // Find suitable locations for stairs
            var stairsRoom = lowerFloor.getRandomRoomOfType(HALLWAY);
            if (stairsRoom == null) stairsRoom = lowerFloor.getRandomRoom();

            if (stairsRoom != null) {
                var stairsPoint = stairsRoom.getRandomPointInRoom();
                lowerFloor.addStairsUp(stairsPoint.x, stairsPoint.y);
                upperFloor.addStairsDown(stairsPoint.x, stairsPoint.y);
            }
        }
    }

    /**
     * Place collectibles across all floors
     */
    private static function placeCollectibles(mazeData:MazeData, settings:Dynamic):Void {
        for (i in 0...mazeData.floors.length) {
            var floor = mazeData.floors[i];
            var isGroundFloor = (i == 0);

            // Place red objective only on ground floor
            if (isGroundFloor) {
                var objectiveRoom = floor.getRandomRoom();
                if (objectiveRoom != null) {
                    var point = objectiveRoom.getRandomPointInRoom();
                    floor.addCollectible(point.x, point.y, RED_OBJECTIVE);
                }
            }

            // Place golden collectibles on each floor
            for (j in 0...settings.goldenCount) {
                var collectibleRoom = floor.getRandomRoom();
                if (collectibleRoom != null) {
                    var point = collectibleRoom.getRandomPointInRoom();
                    floor.addCollectible(point.x, point.y, GOLDEN_BONUS);
                }
            }
        }
    }

    /**
     * Add exits to make the maze beatable
     */
    private static function addExitsToMaze(mazeData:MazeData, settings:Dynamic):Void {
        var groundFloor = mazeData.floors[0];
        if (groundFloor == null) return;

        // Add main exit to ground floor - place it in an accessible room
        var exitRoom = groundFloor.getRandomRoomOfType(HALLWAY);
        if (exitRoom == null) exitRoom = groundFloor.getRandomRoom();

        if (exitRoom != null) {
            // Place exit near the edge of the room, accessible from inside
            var exitX = exitRoom.bounds.x + exitRoom.bounds.width - 50;
            var exitY = exitRoom.bounds.y + exitRoom.bounds.height / 2;

            // Mark this area as an exit in the room's cell grid
            var tileX = Math.floor(exitX / 32);
            var tileY = Math.floor(exitY / 32);
            if (tileX >= 0 && tileX < groundFloor.width && tileY >= 0 && tileY < groundFloor.height) {
                groundFloor.setCell(tileX, tileY, EXIT);
            }

            // Remove wall to create actual exit
            exitRoom.removeWallSection(exitX - 30, exitY - 30, 60, 60);
        }

        // Add fake exits based on difficulty
        var fakeExitCount = settings.fakeExitCount;
        for (i in 0...fakeExitCount) {
            var fakeExitRoom = groundFloor.getRandomRoom();
            if (fakeExitRoom != null && fakeExitRoom != exitRoom) {
                var fakeExitPoint = fakeExitRoom.getRandomPointInRoom();
                var fakeTileX = Math.floor(fakeExitPoint.x / 32);
                var fakeTileY = Math.floor(fakeExitPoint.y / 32);
                if (fakeTileX >= 0 && fakeTileX < groundFloor.width && fakeTileY >= 0 && fakeTileY < groundFloor.height) {
                    groundFloor.setCell(fakeTileX, fakeTileY, FAKE_EXIT);
                }
            }
        }

        // Ensure all rooms are properly connected
        ensureRoomConnectivity(groundFloor);
    }

    /**
     * Ensure all rooms are connected through doorways
     */
    private static function ensureRoomConnectivity(floor:MazeFloor):Void {
        var rooms = floor.rooms;
        if (rooms.length < 2) return;

        // First pass: Connect adjacent rooms
        for (i in 0...rooms.length) {
            var room1 = rooms[i];
            for (j in (i + 1)...rooms.length) {
                var room2 = rooms[j];
                if (roomsAreAdjacent(room1, room2)) {
                    createConnection(room1, room2);
                }
            }
        }

        // Second pass: Ensure every room has at least one connection
        for (i in 0...rooms.length) {
            var room = rooms[i];
            var hasConnection = room.connectedRooms.length > 0;

            if (!hasConnection) {
                // Find the three nearest rooms and try to connect
                var nearestRooms = findNearestRooms(room, rooms, 3);
                for (nearRoom in nearestRooms) {
                    if (nearRoom != null) {
                        createConnection(room, nearRoom);
                        break; // Only need one connection
                    }
                }
            }
        }

        // Third pass: Create some extra connections for better flow
        createAdditionalConnections(floor);
    }

    /**
     * Find multiple nearest rooms to a target room
     */
    private static function findNearestRooms(targetRoom:Room, rooms:Array<Room>, count:Int):Array<Room> {
        var roomDistances = [];

        for (room in rooms) {
            if (room == targetRoom) continue;

            var distance = Math.sqrt(
                Math.pow(room.bounds.x + room.bounds.width/2 - (targetRoom.bounds.x + targetRoom.bounds.width/2), 2) +
                Math.pow(room.bounds.y + room.bounds.height/2 - (targetRoom.bounds.y + targetRoom.bounds.height/2), 2)
            );

            roomDistances.push({room: room, distance: distance});
        }

        // Sort by distance
        roomDistances.sort(function(a, b) return a.distance < b.distance ? -1 : (a.distance > b.distance ? 1 : 0));

        var result = [];
        for (i in 0...new Num(Math.min(count, roomDistances.length))) {
            result.push(roomDistances[i].room);
        }

        return result;
    }

    /**
     * Create additional connections for better room flow
     */
    private static function createAdditionalConnections(floor:MazeFloor):Void {
        var rooms = floor.rooms;
        var connectionCount = 0;
        var maxAdditionalConnections = Math.floor(rooms.length * 0.3); // 30% more connections

        for (i in 0...rooms.length) {
            if (connectionCount >= maxAdditionalConnections) break;

            var room1 = rooms[i];
            for (j in (i + 1)...rooms.length) {
                if (connectionCount >= maxAdditionalConnections) break;

                var room2 = rooms[j];

                // Don't connect if already connected
                if (room1.connectedRooms.indexOf(j) >= 0) continue;

                // Check if they're reasonably close (not too far apart)
                var distance = Math.sqrt(
                    Math.pow(room1.bounds.x + room1.bounds.width/2 - (room2.bounds.x + room2.bounds.width/2), 2) +
                    Math.pow(room1.bounds.y + room1.bounds.height/2 - (room2.bounds.y + room2.bounds.height/2), 2)
                );

                if (distance < 800) { // Within reasonable distance for massive rooms
                    createConnection(room1, room2);
                    connectionCount++;
                }
            }
        }
    }

    /**
     * Check if two rooms are adjacent (share a wall)
     */
    private static function roomsAreAdjacent(room1:Room, room2:Room):Bool {
        var margin = 50; // Larger margin for massive rooms

        // Check horizontal adjacency (rooms side by side)
        var horizontalAdjacent = (Math.abs(room1.bounds.right - room2.bounds.x) < margin) ||
                                (Math.abs(room2.bounds.right - room1.bounds.x) < margin);

        // Check vertical adjacency (rooms above/below each other)
        var verticalAdjacent = (Math.abs(room1.bounds.bottom - room2.bounds.y) < margin) ||
                              (Math.abs(room2.bounds.bottom - room1.bounds.y) < margin);

        // Check if rooms overlap enough in the other dimension to connect
        var xOverlap = Math.max(0, Math.min(room1.bounds.right, room2.bounds.right) - Math.max(room1.bounds.x, room2.bounds.x));
        var yOverlap = Math.max(0, Math.min(room1.bounds.bottom, room2.bounds.bottom) - Math.max(room1.bounds.y, room2.bounds.y));

        // Need significant overlap to create a meaningful connection
        var minOverlap = 100; // Minimum overlap for connection

        return (horizontalAdjacent && yOverlap >= minOverlap) || (verticalAdjacent && xOverlap >= minOverlap);
    }

    /**
     * Find nearest room to given room
     */
    private static function findNearestRoom(targetRoom:Room, rooms:Array<Room>):Room {
        var nearestRoom:Room = null;
        var nearestDistance = Math.POSITIVE_INFINITY;

        for (room in rooms) {
            if (room == targetRoom) continue;

            var distance = Math.sqrt(
                Math.pow(room.bounds.x + room.bounds.width/2 - (targetRoom.bounds.x + targetRoom.bounds.width/2), 2) +
                Math.pow(room.bounds.y + room.bounds.height/2 - (targetRoom.bounds.y + targetRoom.bounds.height/2), 2)
            );

            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearestRoom = room;
            }
        }

        return nearestRoom;
    }

    /**
     * Create connection between two rooms - Not needed with grid system
     */
    private static function createConnection(room1:Room, room2:Room):Void {
        // Grid system creates directly connected rooms automatically
        // Room connections are inherent in the grid layout
    }

    /**
     * Determine which sides of two rooms should connect
     */
    private static function determineConnectionSides(room1:Room, room2:Room):{room1Side:String, room2Side:String} {
        var center1 = new FlxPoint(room1.bounds.x + room1.bounds.width/2, room1.bounds.y + room1.bounds.height/2);
        var center2 = new FlxPoint(room2.bounds.x + room2.bounds.width/2, room2.bounds.y + room2.bounds.height/2);

        var dx = center2.x - center1.x;
        var dy = center2.y - center1.y;

        // Determine primary direction
        if (Math.abs(dx) > Math.abs(dy)) {
            // Horizontal connection
            if (dx > 0) {
                return {room1Side: "right", room2Side: "left"};
            } else {
                return {room1Side: "left", room2Side: "right"};
            }
        } else {
            // Vertical connection
            if (dy > 0) {
                return {room1Side: "bottom", room2Side: "top"};
            } else {
                return {room1Side: "top", room2Side: "bottom"};
            }
        }
    }

    /**
     * Find the best point to connect two rooms
     */
    private static function findBestConnectionPoint(room1:Room, room2:Room):MazePosition {
        // Simple approach - find the midpoint of the shared wall
        var margin = 10;

        // Check if rooms share a horizontal wall
        if (Math.abs(room1.bounds.right - room2.bounds.x) < margin) {
            // room1 is to the left of room2
            var sharedY = Math.max(room1.bounds.y, room2.bounds.y);
            var sharedHeight = Math.min(room1.bounds.bottom, room2.bounds.bottom) - sharedY;
            if (sharedHeight > 0) {
                return new MazePosition(room1.bounds.right, sharedY + sharedHeight/2, 0);
            }
        }

        if (Math.abs(room2.bounds.right - room1.bounds.x) < margin) {
            // room2 is to the left of room1
            var sharedY = Math.max(room1.bounds.y, room2.bounds.y);
            var sharedHeight = Math.min(room1.bounds.bottom, room2.bounds.bottom) - sharedY;
            if (sharedHeight > 0) {
                return new MazePosition(room2.bounds.right, sharedY + sharedHeight/2, 0);
            }
        }

        // Check if rooms share a vertical wall
        if (Math.abs(room1.bounds.bottom - room2.bounds.y) < margin) {
            // room1 is above room2
            var sharedX = Math.max(room1.bounds.x, room2.bounds.x);
            var sharedWidth = Math.min(room1.bounds.right, room2.bounds.right) - sharedX;
            if (sharedWidth > 0) {
                return new MazePosition(sharedX + sharedWidth/2, room1.bounds.bottom, 0);
            }
        }

        if (Math.abs(room2.bounds.bottom - room1.bounds.y) < margin) {
            // room2 is above room1
            var sharedX = Math.max(room1.bounds.x, room2.bounds.x);
            var sharedWidth = Math.min(room1.bounds.right, room2.bounds.right) - sharedX;
            if (sharedWidth > 0) {
                return new MazePosition(sharedX + sharedWidth/2, room2.bounds.bottom, 0);
            }
        }

        return null;
    }
}
