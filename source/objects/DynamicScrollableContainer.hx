package objects;

import flixel.FlxBasic;
import flixel.math.FlxMath;

/**
 * Generic container for dynamically loaded scrollable items with sparse array and compact layout.
 * T must implement Scrollable interface (has targetY, distancePerItem, startPosition, snapToPosition()).
 *
 * Items are stored in a sparse array where unloaded items are represented as null placeholders.
 * When items are added/removed, position recalculation ensures remaining items shift to fill gaps
 * (compact layout with no visual gaps in the UI).
 */
class DynamicScrollableContainer<T:(flixel.FlxBasic)> extends FlxTypedGroup<T>
{
	/**
	 * Sparse array storing items. index -> item or null if unloaded.
	 */
	public var items:Array<Null<T>> = [];

	/**
	 * Total pre-allocated capacity (should match final song list size).
	 */
	public var totalCapacity:Int = 0;

	/**
	 * Track which indices have been marked as dirty and need position recalculation.
	 */
	private var dirtyIndices:Array<Int> = [];

	/**
	 * Cache of loaded item count for optimization.
	 */
	private var loadedCount:Int = 0;

	public function new(initialCapacity:Int = 0)
	{
		super();
		if (initialCapacity > 0)
		{
			setCapacity(initialCapacity);
		}
	}

	/**
	 * Pre-allocate index space for expected total items.
	 */
	public function setCapacity(size:Int):Void
	{
		totalCapacity = size;
		// Reinitialize sparse array with nulls
		items = [];
		for (i in 0...size)
		{
			items.push(null);
		}
		loadedCount = 0;
		dirtyIndices = [];
	}

	/**
	 * Add an item at a specific index.
	 * Updates targetY of item and marks higher indices as dirty for position recalculation.
	 */
	public function addItemAt(item:T, index:Int):Void
	{
		if (index < 0 || index >= totalCapacity)
		{
			trace('WARNING: DynamicScrollableContainer.addItemAt() - index $index out of bounds (capacity: $totalCapacity)');
			return;
		}

		// If slot was empty, increment loaded count
		if (items[index] == null)
		{
			loadedCount++;
		}
		else
		{
			// Remove old item if replacing
			var oldItem = items[index];
			remove(oldItem);
		}

		items[index] = item;

		// Set targetY to the compact layout index (position among loaded items)
		updateCompactTargetY(index);

		// Mark this and all higher indices as dirty
		for (i in index...totalCapacity)
		{
			if (!dirtyIndices.contains(i))
			{
				dirtyIndices.push(i);
			}
		}

		// Add to display group
		add(item);

		// Recalculate positions immediately
		recalculatePositions();
	}

	/**
	 * Check if an item exists at the given index.
	 */
	public function hasItemAt(index:Int):Bool
	{
		return index >= 0 && index < items.length && items[index] != null;
	}

	/**
	 * Get item at index, or null if unloaded.
	 */
	public function getItemAt(index:Int):Null<T>
	{
		if (index < 0 || index >= items.length)
			return null;
		return items[index];
	}

	/**
	 * Remove item at index.
	 * Marks higher indices as dirty for position recalculation.
	 */
	public function removeItemAt(index:Int):Void
	{
		if (index < 0 || index >= items.length || items[index] == null)
			return;

		var item = items[index];
		items[index] = null;
		loadedCount--;

		// Mark this and higher indices as dirty
		for (i in index...totalCapacity)
		{
			if (!dirtyIndices.contains(i))
			{
				dirtyIndices.push(i);
			}
		}

		// Remove from display group
		remove(item);

		// Recalculate positions
		recalculatePositions();
	}

	/**
	 * Return the first unloaded index, or -1 if all loaded.
	 */
	public function getNextUnloadedIndex():Int
	{
		for (i in 0...items.length)
		{
			if (items[i] == null)
				return i;
		}
		return -1;
	}

	/**
	 * Return count of loaded (non-null) items.
	 */
	public function getLoadedCount():Int
	{
		return loadedCount;
	}

	/**
	 * Return total capacity.
	 */
	public function getTotalCapacity():Int
	{
		return totalCapacity;
	}

	/**
	 * Get estimated memory usage of loaded items.
	 * For now, returns 0. Can be extended to sum item sizes.
	 */
	public function getMemoryUsage():Int
	{
		// TODO: Implement if needed for memory-based unloading
		return 0;
	}

	/**
	 * Clear all items.
	 */
	override public function clear():Void
	{
		super.clear();
		items = [];
		loadedCount = 0;
		dirtyIndices = [];
		totalCapacity = 0;
	}

	/**
	 * Update viewport: hide items outside [viewportMin, viewportMax].
	 * This controls visibility based on scroll position.
	 */
	public function updateViewport(viewportMin:Int, viewportMax:Int):Void
	{
		for (i in 0...items.length)
		{
			var item = items[i];
			if (item != null)
			{
				var visible = (i >= viewportMin && i <= viewportMax);
				cast(item, FlxBasic).visible = visible;
				cast(item, FlxBasic).active = visible;
			}
		}
	}

	/**
	 * Recalculate positions of all dirty items using compact layout.
	 * Each item's visual position is based on its targetY within the sparse array.
	 * This is called automatically after addItemAt() or removeItemAt().
	 */
	public function recalculatePositions():Void
	{
		// Sort dirty indices for efficient iteration
		dirtyIndices.sort((a, b) -> a - b);

		for (dirtyIdx in dirtyIndices)
		{
			updateCompactTargetY(dirtyIdx);
		}

		// Call snapToPosition on all items to update their visual positions
		for (item in items)
		{
			if (item != null)
			{
				var scrollable = cast(item, Scrollable);
				scrollable.snapToPosition();
			}
		}

		dirtyIndices = [];
	}

	/**
	 * Internal: Calculate the compact targetY for an item.
	 * targetY should be the item's sequential position among all loaded items (compacting gaps).
	 */
	private function updateCompactTargetY(index:Int):Void
	{
		if (items[index] == null)
			return;

		var scrollable = cast(items[index], Scrollable);

		// Count loaded items before this index to determine compact position
		var compactIndex = 0;
		for (i in 0...index)
		{
			if (items[i] != null)
				compactIndex++;
		}

		scrollable.targetY = compactIndex;
	}

	/**
	 * DEBUG: Get string representation of container state.
	 */
	public function debugState():String
	{
		var result = 'DynamicScrollableContainer[capacity=$totalCapacity, loaded=$loadedCount]\n';
		result += 'Items: ';
		for (i in 0...items.length)
		{
			result += items[i] != null ? 'X' : '_';
		}
		return result;
	}
}
