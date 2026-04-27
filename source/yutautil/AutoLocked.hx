package yutautil;

#if (target.threaded)
import sys.thread.Mutex;
#end

/**
 * Thread-safe abstract wrapper with automatic locking/unlocking semantics.
 *
 * Provides automatic mutual exclusion for shared values across threads.
 * Uses @:from to enable implicit wrapping of values.
 *
 * Usage:
 * ```haxe
 * var counter:AutoLocked<Int> = 0;  // Implicitly wrapped
 * counter.read(function(val) {
 *     trace("Counter is: " + val);
 * });
 * counter.write(function(val) {
 *     return val + 1;
 * });
 * ```
 */
abstract AutoLocked<T>(AutoLockedData<T>) {
	/**
	 * Creates a new AutoLocked value.
	 * @param value The initial value to wrap.
	 */
	public inline function new(value:T) {
		this = new AutoLockedData<T>(value);
	}

	/**
	 * Implicitly converts a value to AutoLocked.
	 */
	@:from
	public static inline function fromValue<T>(value:T):AutoLocked<T> {
		return new AutoLocked<T>(value);
	}

	/**
	 * Reads the value with automatic locking.
	 *
	 * @param callback Function to execute while holding the lock.
	 * @return The result of the callback.
	 */
	public inline function read<R>(callback:T -> R):R {
		return this.read(callback);
	}

	/**
	 * Writes to the value with automatic locking.
	 *
	 * @param callback Function that returns the new value (receives current value).
	 * @return The new value.
	 */
	public inline function write(callback:T -> T):T {
		return this.write(callback);
	}

	/**
	 * Gets the value directly with locking (single operation).
	 * For simple read access without callback overhead.
	 */
	public inline function get():T {
		return this.get();
	}

	/**
	 * Sets the value directly with locking (single operation).
	 * For simple write access without callback overhead.
	 */
	public inline function set(value:T):T {
		return this.set(value);
	}

	/**
	 * Modifies the value in-place with automatic locking.
	 * Useful for mutable types.
	 */
	public inline function modify(callback:T -> Void):Void {
		this.modify(callback);
	}

	/**
	 * Acquires lock, executes callback, then releases lock.
	 * Advanced usage for complex operations.
	 */
	public inline function withLock<R>(callback:T -> R):R {
		return this.withLock(callback);
	}
}

/**
 * Internal implementation of AutoLocked.
 * Not intended for direct use - use AutoLocked<T> instead.
 */
class AutoLockedData<T> {
	private var value:T;

	#if (target.threaded)
	private var mutex:Mutex;
	#end

	public function new(initialValue:T) {
		value = initialValue;
		#if (target.threaded)
		mutex = new Mutex();
		#end
	}

	public function read<R>(callback:T -> R):R {
		#if (target.threaded)
		mutex.acquire();
		#end
		var result:R = null;
		var hasError = false;
		var error:Dynamic = null;
		try {
			result = callback(value);
		} catch (e:Dynamic) {
			hasError = true;
			error = e;
		}
		#if (target.threaded)
		mutex.release();
		#end
		if (hasError) throw error;
		return result;
	}

	public function write(callback:T -> T):T {
		#if (target.threaded)
		mutex.acquire();
		#end
		var result:T = null;
		var hasError = false;
		var error:Dynamic = null;
		try {
			value = callback(value);
			result = value;
		} catch (e:Dynamic) {
			hasError = true;
			error = e;
		}
		#if (target.threaded)
		mutex.release();
		#end
		if (hasError) throw error;
		return result;
	}

	public function get():T {
		#if (target.threaded)
		mutex.acquire();
		#end
		var result:T = value;
		#if (target.threaded)
		mutex.release();
		#end
		return result;
	}

	public function set(newValue:T):T {
		#if (target.threaded)
		mutex.acquire();
		#end
		value = newValue;
		#if (target.threaded)
		mutex.release();
		#end
		return value;
	}

	public function modify(callback:T -> Void):Void {
		#if (target.threaded)
		mutex.acquire();
		#end
		var hasError = false;
		var error:Dynamic = null;
		try {
			callback(value);
		} catch (e:Dynamic) {
			hasError = true;
			error = e;
		}
		#if (target.threaded)
		mutex.release();
		#end
		if (hasError) throw error;
	}

	public function withLock<R>(callback:T -> R):R {
		#if (target.threaded)
		mutex.acquire();
		#end
		var result:R = null;
		var hasError = false;
		var error:Dynamic = null;
		try {
			result = callback(value);
		} catch (e:Dynamic) {
			hasError = true;
			error = e;
		}
		#if (target.threaded)
		mutex.release();
		#end
		if (hasError) throw error;
		return result;
	}
}
