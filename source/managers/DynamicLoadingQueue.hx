package managers;

/**
 * Task structure for queued item creation.
 */
private typedef Task = {
	container:Dynamic, // DynamicScrollableContainer<Dynamic>
	index:Int,
	factory:Void->Dynamic, // Factory function that creates the item
	onComplete:Dynamic->Void // Callback after item is added
};

/**
 * Singleton queue system for frame-by-frame item creation.
 * Process 1-2 items per frame from a pending queue.
 * Supports pause/resume for critical gameplay moments.
 */
class DynamicLoadingQueue
{
	private static var _instance:DynamicLoadingQueue;

	private var pending:Array<Task> = [];
	private var paused:Bool = false;
	private var itemsPerFrame:Int = 1; // Process 1-2 items per frame
	private var processedThisFrame:Int = 0;

	private function new()
	{
	}

	public static function instance():DynamicLoadingQueue
	{
		if (_instance == null)
		{
			_instance = new DynamicLoadingQueue();
		}
		return _instance;
	}

	/**
	 * Enqueue item creation.
	 * @param container The DynamicScrollableContainer to add the item to
	 * @param index The index to add the item at
	 * @param factory Function that creates and returns the item
	 * @param onComplete Callback fired after item added to container
	 */
	public function enqueueCreation(container:Dynamic, index:Int, factory:Void->Dynamic, ?onComplete:Dynamic->Void):Void
	{
		pending.push({
			container: container,
			index: index,
			factory: factory,
			onComplete: onComplete != null ? onComplete : (item:Dynamic) -> {}
		});
	}

	/**
	 * Process queued items (called every frame by DynamicFreeplayState).
	 */
	public function update(elapsed:Float):Void
	{
		// Reset frame counter at start of frame
		processedThisFrame = 0;

		if (paused || pending.length == 0)
			return;

		// Process up to itemsPerFrame items
		while (processedThisFrame < itemsPerFrame && pending.length > 0)
		{
			var task = pending.shift();

			try
			{
				// Create item via factory
				var item = task.factory();

				// Add to container
				task.container.addItemAt(item, task.index);

				// Fire callback
				task.onComplete(item);

				processedThisFrame++;
			}
			catch (e:Dynamic)
			{
				trace('ERROR in DynamicLoadingQueue.update(): $e');
			}
		}
	}

	/**
	 * Get number of items pending processing.
	 */
	public function getQueueLength():Int
	{
		return pending.length;
	}

	/**
	 * Get number of items processed this frame.
	 */
	public function getProcessedCount():Int
	{
		return processedThisFrame;
	}

	/**
	 * Check if queue is paused.
	 */
	public function isPaused():Bool
	{
		return paused;
	}

	/**
	 * Pause processing (keep tasks in queue).
	 */
	public function pause():Void
	{
		paused = true;
	}

	/**
	 * Resume processing.
	 */
	public function resume():Void
	{
		paused = false;
	}

	/**
	 * Clear all pending tasks.
	 */
	public function clear():Void
	{
		pending = [];
		processedThisFrame = 0;
	}

	/**
	 * Set items processed per frame (default 1).
	 */
	public function setItemsPerFrame(count:Int):Void
	{
		itemsPerFrame = Std.int(Math.max(1, count));
	}
}
