package yutautil.games.stealthmaze.backend;

import flixel.math.FlxPoint;
import yutautil.games.stealthmaze.backend.MazeData;

/**
 * A* pathfinding implementation for maze navigation
 */
class MazePathfinder {

    private var maze:MazeFloor;
    private var tileSize:Int = 32;

    public function new(maze:MazeFloor) {
        this.maze = maze;
    }

    /**
     * Find path from start to goal using A* algorithm
     */
    public function findPath(start:FlxPoint, goal:FlxPoint):Array<FlxPoint> {
        var startTile = worldToTile(start);
        var goalTile = worldToTile(goal);

        if (!isValidTile(Std.int(startTile.x), Std.int(startTile.y)) || !isValidTile(Std.int(goalTile.x), Std.int(goalTile.y))) {
            return [];
        }

        var openList:Array<PathNode> = [];
        var closedList:Array<PathNode> = [];
        var allNodes:Map<String, PathNode> = new Map();

        // Create start node
        var startNode = new PathNode(Std.int(startTile.x), Std.int(startTile.y));
        startNode.gCost = 0;
        startNode.hCost = getDistance(startTile, goalTile);
        startNode.fCost = startNode.gCost + startNode.hCost;

        openList.push(startNode);
        allNodes.set(nodeKey(startNode.x, startNode.y), startNode);

        while (openList.length > 0) {
            // Find node with lowest F cost
            var currentNode = getLowestFCostNode(openList);

            // Remove from open list, add to closed list
            openList.remove(currentNode);
            closedList.push(currentNode);

            // Check if we reached the goal
            if (currentNode.x == goalTile.x && currentNode.y == goalTile.y) {
                return reconstructPath(currentNode);
            }

            // Check neighbors
            var neighbors = getNeighbors(currentNode.x, currentNode.y);
            for (neighbor in neighbors) {
                var key = nodeKey(Std.int(neighbor.x), Std.int(neighbor.y));

                // Skip if in closed list
                if (isInClosedList(neighbor, closedList)) {
                    continue;
                }

                var tentativeGCost = currentNode.gCost + 1; // Movement cost is 1

                var neighborNode:PathNode;
                if (allNodes.exists(key)) {
                    neighborNode = allNodes.get(key);
                } else {
                    neighborNode = new PathNode(Std.int(neighbor.x), Std.int(neighbor.y));
                    allNodes.set(key, neighborNode);
                }

                // Check if this path to neighbor is better
                if (tentativeGCost < neighborNode.gCost || !isInOpenList(neighborNode, openList)) {
                    neighborNode.gCost = tentativeGCost;
                    neighborNode.hCost = getDistance(neighbor, goalTile);
                    neighborNode.fCost = neighborNode.gCost + neighborNode.hCost;
                    neighborNode.parent = currentNode;

                    if (!isInOpenList(neighborNode, openList)) {
                        openList.push(neighborNode);
                    }
                }
            }
        }

        // No path found
        return [];
    }

    /**
     * Get walkable neighbor positions
     */
    private function getNeighbors(x:Int, y:Int):Array<FlxPoint> {
        var neighbors:Array<FlxPoint> = [];

        var directions = [
            {x: 0, y: -1}, // Up
            {x: 1, y: 0},  // Right
            {x: 0, y: 1},  // Down
            {x: -1, y: 0}  // Left
        ];

        for (dir in directions) {
            var newX = x + dir.x;
            var newY = y + dir.y;

            if (isWalkable(newX, newY)) {
                neighbors.push(new FlxPoint(newX, newY));
            }
        }

        return neighbors;
    }

    /**
     * Check if a tile position is walkable using room-based collision
     */
    private function isWalkable(x:Int, y:Int):Bool {
        if (!isValidTile(x, y)) {
            return false;
        }

        // Convert tile coordinates to world coordinates
        var worldX = x * tileSize + tileSize * 0.5;
        var worldY = y * tileSize + tileSize * 0.5;

        // Use room-based walkability check
        return maze.isWalkable(worldX, worldY);
    }

    /**
     * Check if tile coordinates are valid
     */
    private function isValidTile(x:Int, y:Int):Bool {
        return x >= 0 && x < maze.width && y >= 0 && y < maze.height;
    }

    /**
     * Convert world position to tile coordinates
     */
    private function worldToTile(worldPos:FlxPoint):FlxPoint {
        return new FlxPoint(
            Math.floor(worldPos.x / tileSize),
            Math.floor(worldPos.y / tileSize)
        );
    }

    /**
     * Convert tile coordinates to world position
     */
    public function tileToWorld(tilePos:FlxPoint):FlxPoint {
        return new FlxPoint(
            tilePos.x * tileSize + tileSize * 0.5,
            tilePos.y * tileSize + tileSize * 0.5
        );
    }

    /**
     * Get Manhattan distance between two points
     */
    private function getDistance(a:FlxPoint, b:FlxPoint):Int {
        return Math.floor(Math.abs(a.x - b.x) + Math.abs(a.y - b.y));
    }

    /**
     * Get node with lowest F cost from open list
     */
    private function getLowestFCostNode(openList:Array<PathNode>):PathNode {
        var lowest = openList[0];
        for (node in openList) {
            if (node.fCost < lowest.fCost ||
                (node.fCost == lowest.fCost && node.hCost < lowest.hCost)) {
                lowest = node;
            }
        }
        return lowest;
    }

    /**
     * Check if node is in open list
     */
    private function isInOpenList(node:PathNode, openList:Array<PathNode>):Bool {
        for (openNode in openList) {
            if (openNode.x == node.x && openNode.y == node.y) {
                return true;
            }
        }
        return false;
    }

    /**
     * Check if node is in closed list
     */
    private function isInClosedList(point:FlxPoint, closedList:Array<PathNode>):Bool {
        for (closedNode in closedList) {
            if (closedNode.x == point.x && closedNode.y == point.y) {
                return true;
            }
        }
        return false;
    }

    /**
     * Generate unique key for node map
     */
    private function nodeKey(x:Int, y:Int):String {
        return x + "," + y;
    }

    /**
     * Reconstruct path from goal node to start
     */
    private function reconstructPath(goalNode:PathNode):Array<FlxPoint> {
        var path:Array<FlxPoint> = [];
        var currentNode = goalNode;

        while (currentNode != null) {
            path.unshift(tileToWorld(new FlxPoint(currentNode.x, currentNode.y)));
            currentNode = currentNode.parent;
        }

        return path;
    }

    /**
     * Find nearest walkable position to a target
     */
    public function findNearestWalkable(target:FlxPoint):FlxPoint {
        var targetTile = worldToTile(target);

        if (isWalkable(Std.int(targetTile.x), Std.int(targetTile.y))) {
            return target;
        }

        // Search in expanding rings around target
        for (radius in 1...10) {
            for (x in Std.int(targetTile.x - radius)...Std.int(targetTile.x + radius + 1)) {
                for (y in Std.int(targetTile.y - radius)...Std.int(targetTile.y + radius + 1)) {
                    if (Math.abs(x - targetTile.x) == radius || Math.abs(y - targetTile.y) == radius) {
                        if (isWalkable(x, y)) {
                            return tileToWorld(new FlxPoint(x, y));
                        }
                    }
                }
            }
        }

        // Fallback: return original position
        return target;
    }

    /**
     * Check if there's a clear line of sight between two points
     */
    public function hasLineOfSight(start:FlxPoint, end:FlxPoint):Bool {
        var startTile = worldToTile(start);
        var endTile = worldToTile(end);

        var dx = Math.abs(endTile.x - startTile.x);
        var dy = Math.abs(endTile.y - startTile.y);

        var x = Std.int(startTile.x);
        var y = Std.int(startTile.y);

        var xInc = (endTile.x > startTile.x) ? 1 : -1;
        var yInc = (endTile.y > startTile.y) ? 1 : -1;

        var error = dx - dy;

        dx *= 2;
        dy *= 2;

        while (true) {
            if (!isWalkable(x, y)) {
                return false;
            }

            if (x == endTile.x && y == endTile.y) {
                break;
            }

            if (error > 0) {
                x += xInc;
                error -= dy;
            } else {
                y += yInc;
                error += dx;
            }
        }

        return true;
    }
}

/**
 * Node class for A* pathfinding
 */
class PathNode {
    public var x:Int;
    public var y:Int;
    public var gCost:Int = 0;  // Distance from start
    public var hCost:Int = 0;  // Distance to goal (heuristic)
    public var fCost:Int = 0;  // Total cost (g + h)
    public var parent:PathNode = null;

    public function new(x:Int, y:Int) {
        this.x = x;
        this.y = y;
        this.gCost = 999999; // High initial value
    }
}
