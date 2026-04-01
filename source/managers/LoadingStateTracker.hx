package managers;

/**
 * Simple tracker for loading progress UI display.
 * Instantiated by DynamicFreeplayState (NOT a singleton).
 */
class LoadingStateTracker
{
	private var totalItems:Int = 0;
	private var loadedCount:Int = 0;

	public function new()
	{
	}

	/**
	 * Set expected total items.
	 */
	public function initialize(total:Int):Void
	{
		totalItems = total;
		loadedCount = 0;
	}

	/**
	 * Increment loaded count (called by DynamicLoadingQueue callback).
	 */
	public function itemLoaded():Void
	{
		if (loadedCount < totalItems)
		{
			loadedCount++;
		}
	}

	/**
	 * Get progress as Float (0.0 to 1.0).
	 */
	public function getProgress():Float
	{
		if (totalItems <= 0)
			return 1.0;
		return Math.min(1.0, loadedCount / totalItems);
	}

	/**
	 * Get total expected items.
	 */
	public function getTotalItems():Int
	{
		return totalItems;
	}

	/**
	 * Get current loaded count.
	 */
	public function getLoadedItems():Int
	{
		return loadedCount;
	}

	/**
	 * Check if loading is complete.
	 */
	public function isComplete():Bool
	{
		return loadedCount >= totalItems;
	}

	/**
	 * Reset tracker.
	 */
	public function reset():Void
	{
		totalItems = 0;
		loadedCount = 0;
	}
}
