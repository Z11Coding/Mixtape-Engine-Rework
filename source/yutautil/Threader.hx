package yutautil;

// import openfl.utils.QName;
import haxe.Exception;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Printer;

/**
 * Represents a thread baked into compilation.
 */
typedef BakedThread = {
    expr:Expr,
    sleepDuration:Float,
    name:String
};

/**
 * Represents a thread that is running in the background.
 */
typedef QuietThread = String;

/**
 * Manages threading operations, including running expressions in threads and queues.
 * 
 * Used for threading function calls for performance, and for running multiple functions concurrently.
 * Will NOT work with regular expressions.
 */
class Threader {
    public static var threadQueue:ThreadQueue;
    public static var specialThreads:Array<BakedThread> = [];
    public static var quietThreads:Array<QuietThread> = [];
    private static var baked:BakedThread;
    private static var usedthreads:Bool = false;
    private static var generatedThreads:Array<QuietThread> = [];
    private static var bakedThreads:Array<BakedThread> = [];

    /**
     * Runs an expression in a queue with specified concurrency and blocking behavior.
     * @param expr The expression to run.
     * @param maxConcurrent The maximum number of concurrent threads.
     * @param blockUntilFinished Whether to block until all threads are finished.
     * @return The macro expression to run the queue.
     */
    public static macro function runInQueue(expr:Expr, ?maxConcurrent:Int = 1, ?blockUntilFinished:Bool = false):Expr {
        return macro {
            var tq = ThreadQueue.doInQueue(function() {
                $expr;
            }, $v{Context.makeExpr(maxConcurrent, Context.currentPos())}, $v{Context.makeExpr(blockUntilFinished, Context.currentPos())});
        };
    }

    /**
     * Runs multiple expressions in a queue with specified concurrency and blocking behavior.
     * @param exprs The expressions to run.
     * @param maxConcurrent The maximum number of concurrent threads.
     * @param blockUntilFinished Whether to block until all threads are finished.
     * @return The macro expression to run the queue.
     */
    public static macro function runQueue(exprs:Array<Expr>, ?maxConcurrent:Int = 1, ?blockUntilFinished:Bool = false):Expr {
        return macro {
            var tq = ThreadQueue.tempQueue([
                for (e in $a{exprs}) {
                    function() {
                        e;
                    }
                }
            ], $v{Context.makeExpr(maxConcurrent, Context.currentPos())}, $v{Context.makeExpr(blockUntilFinished, Context.currentPos())});
        };
    }

    /**
     * Runs an expression in a thread with optional sleep duration and name.
     * @param expr The expression to run.
     * @param sleepDuration The sleep duration after running the expression.
     * @param name The name of the thread.
     * @return The macro expression to run the thread.
     */
    public static macro function runInThread(expr:Expr, ?sleepDuration:Float = 0, ?name:String = ""):Expr {
        if (!usedthreads) {
            trace("Initializing Threader...");
            Context.onAfterGenerate(function() {
            trace("All threads are generated: " + generatedThreads);
            // remove threads from array that have finished
            for (thread in generatedThreads) {
                if (generatedThreads.indexOf(thread) == -1) {
                quietThreads.remove(thread);
                trace("Finished generation of " + thread);
                }
            }
            });
            baked = { expr: expr, sleepDuration: sleepDuration, name: name };
            bakedThreads.push(baked);
        }
        usedthreads = !usedthreads ? true : usedthreads;
        var sleepExpr = Context.makeExpr(sleepDuration, Context.currentPos());
        var nameExpr = Context.makeExpr(name != "" && name != null ? name : "Thread_" + Std.random(1000000) + "_" + (stringRandomizer(8)), Context.currentPos());
        var generatedName:String = ExprTools.toString(nameExpr);
        generatedThreads.push(generatedName);
        trace("Preparing a threaded section of code:\n" + expr + " \nwith sleep duration: " + sleepDuration + " and name: " + generatedName);
        var threadExpr = macro {
            #if sys
            yutautil.Threader.quietThreads.push($nameExpr);
            var thrd = Thread.create(function() {
                try {
                    trace("Set command to run in a thread...");
                    if ($nameExpr != "") {
                        trace("Thread name: " + $nameExpr);
                    }
                    $expr;
                    if ($sleepExpr > 0) {
                        Sys.sleep($sleepExpr);
                    }
                    trace("Thread finished running command: " + $nameExpr);
                    yutautil.Threader.quietThreads.remove($nameExpr);
                } catch (e:Dynamic) {
                    trace("Exception in thread: " + e + " ... " + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
                    if ($nameExpr != "") {
                        trace("Errored Thread name: " + $nameExpr);
                    }
                    yutautil.Threader.quietThreads.remove($nameExpr);
                }
            });
            #else
            $expr;
            #end
        };
        return macro yutautil.Threader.ThreadChecker.safeThread($threadExpr, $nameExpr);
        trace("Threaded section of code prepared.");
    }

    /**
     * Generates a random string of the specified length.
     * @param length The length of the string.
     * @return The generated random string.
     */
    private static function stringRandomizer(length:Int):String {
        var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        var str = "";
        for (i in 0...length) {
            str += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return str;
    }

    /**
     * Waits for all quiet threads to finish. This may cause permanent blocking if a thread is stuck, or is meant to run indefinitely.
     * 
     * This function is not recommended for production use, as it may cause permanent blocking.
     * 
     * This function is intended for debugging purposes only.
     * 
     * Use with caution.
     * Will cause a compiler error if used as a threaded expression.
     * @see waitForThread
     * 
     */
    public static function waitForThreads():Void {
        while (quietThreads.length > 0) {
            // Busy wait
        }
    }

    /**
     * Waits for a specific thread to finish.
     * 
     * You cannot wait for unnamed threads. If you need to wait for an unnamed thread, you should name it.
     * @param name The name of the thread.
     */
    public static function waitForThread(name:String):Void {
        if (quietThreads.indexOf(name) == -1) {
            trace("Thread " + name + " does not exist.");
            return;
        }
        trace("Waiting for thread: " + name);
        while (quietThreads.indexOf(name) != -1) {
            // Busy wait
        }
        trace("Freedom! Thread " + name + " has finished, or ceased to exist.");
    }
}

/**
 * Manages a queue of functions to be executed in threads.
 */
class ThreadQueue {
    private var queue:Array<() -> Void>;
    private var maxConcurrent:Int;
    public var running:Int;
    private var blockUntilFinished:Bool;
    public var done:Bool = true;
    public var length(get, never):Int;
    
    function get_length():Int {
        return queue.length;
    }

    /**
     * Creates a new ThreadQueue.
     * @param maxConcurrent The maximum number of concurrent threads.
     * @param blockUntilFinished Whether to block until all threads are finished.
     */
    public function new(maxConcurrent:Int = 1, blockUntilFinished:Bool = false) {
        this.queue = [];
        this.maxConcurrent = maxConcurrent;
        this.running = 0;
        this.blockUntilFinished = blockUntilFinished;
    }
    
    /**
     * Runs the queue, if there is anything to run. Only should be used if you preloaded functions while it wasn't already running.
     * 
     * This function checks if the queue is already running or if there are no threads available to run.
     * If the queue is already running, it logs a message and returns without doing anything.
     * If there are no threads available, it logs a message and throws an exception.
     * Otherwise, it proceeds to process the queue.
     * 
     * @throws NoThread if there are no threads available to run.
     */
    public function run():Void {
        if (!done) {
            trace("Attempted a thread queue run while already running a queue in " + this);
            return;
        }
        if (queue.length == 0) {
            trace("Attempted a thread queue run with no threads available.");
            // throw new Exception("Attempted a thread queue run with no threads available.");
        }
        processQueue();
    }

    /**
     * Returns a string representation of the ThreadQueue.
     * @return The string representation.
     */
    public function toString():String {
        return "ThreadQueue: " + queue.length + " functions in queue, " + running + " functions running, maxConcurrent: " + maxConcurrent + ", blockUntilFinished: " + blockUntilFinished;
    }

    /**
     * Creates a new ThreadQueue.
     * @param maxConcurrent The maximum number of concurrent threads.
     * @param blockUntilFinished Whether to block until all threads are finished.
     * @return The created ThreadQueue.
     */
    public static function create(maxConcurrent:Int = 1, blockUntilFinished:Bool = false):ThreadQueue {
        return new ThreadQueue(maxConcurrent, blockUntilFinished);
    }

    /**
     * Adds a function to the queue.
     * @param func The function to add.
     */
    public function add(func:() -> Void):Void {
        addFunction(func);
    }

    /**
     * Adds a function to the queue and runs it immediately if possible.
     * @param func The function to add.
     */
    public function softAdd(func:() -> Void):Void {
        if (running < maxConcurrent) {
            running++;
            sys.thread.Thread.create(function() {
                func();
                running--;
                processQueue();
            });
        } else {
            queue.push(func);
        }
    }

    /**
     * Preloads multiple functions into the queue.
     * 
     * Warning: If currently running functions, these will be added to the same CURRENT queue.
     * @param funcs The functions to preload.
     */
    public function preloadMulti(funcs:Array<() -> Void>):Void {
        for (func in funcs) {
            queue.push(func);
        }
    }

    /**
     * Preloads a function into the queue.
     * 
     * Warning: If currently running functions, this will be added to the same CURRENT queue.
     * @param func The function to preload.
     */
    public function preload(func:() -> Void):Void {
        queue.push(func);
    }

    /**
     * Adds a function to the queue and processes the queue.
     * @param func The function to add.
     */
    public function addFunction(func:() -> Void):Void {
        queue.push(func);
        processQueue();
    }

    /**
     * Adds multiple functions to the queue and processes the queue.
     * @param funcs The functions to add.
     */
    public function addFunctions(funcs:Array<() -> Void>):Void {
        for (func in funcs) {
            queue.push(func);
        }
        processQueue();
    }

    /**
     * Processes the queue, running functions in threads.
    /**
     * Processes the queue, running functions in threads.
     */
    private function processQueue():Void {
        if (done && queue.length > 0) {
            done = false;
            trace("Processing queue...");
        }
        while (running < maxConcurrent && queue.length > 0) {
            var func = queue.shift();
            if (func == null) {
                trace("Encountered a null function in the queue. Skipping...");
                continue;
            }
            running++;
            try {
                sys.thread.Thread.create(function() {
                    try {
                        // trace("Running thread function...");
                        func();
                        // trace("Thread function finished.");
                    } catch (e:Dynamic) {
                        trace("Exception in thread function: " + e + " ... " + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
                    }
                    running--;
                    processQueue();
                });
            } catch (e:Dynamic) {
                trace("Failed to create thread: " + e);
                running--;
            }
        }

        while (blockUntilFinished && queue.length == 0 && running == 0 && !done) {
            // All functions are finished
            trace("All functions are finished.");
            done = true;
        }
        if (queue.length == 0 && running == 0) {
            trace("Queue is empty.");
            done = true;
        }
    }

    /**
     * Waits until all functions in the queue are finished.
     */
    public function waitUntilFinished():Void {
        while (queue.length == 0 || running == 0 || !done) {
            // Busy wait
        }
    }

    /**
     * Creates a temporary queue with functions to run.
     * @param funcs The functions to run.
     * @param maxConcurrent The maximum number of concurrent threads.
     * @param blockUntilFinished Whether to block until all threads are finished.
     * @return The created ThreadQueue.
     */

    // public static function tempQueue(funcs:Array<() -> Void>, maxConcurrent:Int = 1, blockUntilFinished:Bool = false):ThreadQueue {
    //     var tq = new ThreadQueue(maxConcurrent, blockUntilFinished);
    //     tq.addFunctions(funcs);
    //     return tq;

    public function kill():Void {
        queue = [];
        running = 0;
        done = true;
    }

    public function reset(?autoStart:Bool):Void {
    var newQ = queue.copy();

        this.kill();
    queue = newQ;
    if (autoStart) {
        this.run();
    }
    this.processQueue();
    }
}

/**
 * Manages a queue of functions to be executed in threads with memory limit considerations.
 */
class MemLimitThreadQ {
    public var queue:ThreadQueue;
    private var items:Array<Dynamic>;
    private var action:Dynamic -> Void;
    private var limit:Int;
    private var hasty:Bool;
    public var queueLength(get, never):Int;

    public var running(get, never):Int;
    public var length(get, never):Int;

    function get_running():Int {
        return queue.running;
    }

    function get_length():Int {
        return items.length;
    }

    
    function get_queueLength():Int {
        return queue.length;
    }

    /**
     * Creates a new MemLimitThreadQ.
     * @param items The items to process.
     * @param action The action to perform on each item.
     * @param limit The maximum number of items in the queue.
     * @param hasty Whether to use softAdd or regular add.
     */
    public function new(items:Array<Dynamic>, action:Dynamic -> Void, limit:Int, ?hasty:Bool, ?hijackQueue:ThreadQueue) {
        this.queue = hijackQueue != null ? hijackQueue : new ThreadQueue(limit, false);
        this.items = items;
        this.action = action;
        this.limit = limit;
        this.hasty = hasty != null ? hasty : false;
        trace("Creating MemLimitThreadQ with " + items.length + " items, limit: " + limit + ", hasty: " + hasty);
        preloadItems();
        if (hijackQueue != null && (!hijackQueue.done || hijackQueue.length != 0 || hijackQueue.running != 0)) {
            trace("Queue is already processing. Hooking into it...");
            run();
        }
    }

    public static function create(items:Array<Dynamic>, action:Dynamic -> Void, limit:Int, ?hasty:Bool):MemLimitThreadQ {
        return new MemLimitThreadQ(items, action, limit, hasty);
    }

    /**
     * Preloads items into the queue.
     */
    private function preloadItems():Void {
        while (items.length > 0 && queue.length < limit) {
            var item = items.shift();
            if (hasty) {
                queue.softAdd(() -> action(item));
            } else {
                queue.add(() -> action(item));
            }
        }
    }

    /**
     * Runs the queue.
     */
    public function run():Void {
        if (queue.done) {
            queue.run();
        }
        autoAddMoreItems();
    }

    /**
     * Automatically adds more items to the queue if there is space.
     */
    private function autoAddMoreItems():Void {
        trace("Auto-Allocation started...");
        sys.thread.Thread.create(function() {
            while (items.length > 0) {
                if (queue.length < limit && items.length > 0) {
                    var item = items.shift();
                    if (hasty) {
                        queue.softAdd(() -> action(item));
                    } else {
                        queue.add(() -> action(item));
                    }
                    if (queue.done && queue.length != 0) {
                        trace("Queue has emptied... Running...");
                        queue.run();
                    }
                }
                // trace("Items remaining: " + items.length);
            }
            trace("Ended allocation of items.");
            if (queue.done && queue.length != 0) {
                trace("Queue has emptied... Running...");
                queue.run();
            }
        });
    }

    /**
     * Adds more items to the queue if there is space.
     */
    public function addMoreItems(newItems:Array<Dynamic>):Void {
        items = items.concat(newItems);
        autoAddMoreItems();
    }
}

/**
 * Checks for safe threading operations.
 */
class ThreadChecker {
    /**
     * Ensures that a thread does not contain an infinite waiting loop.
     * @param expr The expression to check.
     * @param thread The name of the thread.
     * @return The checked expression.
     */
    public static macro function safeThread(expr:Expr, ?thread:QuietThread):Expr {
        var hasWaitForThreads = containsWaitForThreads(expr);
        if (hasWaitForThreads) {
            Context.error("You can't create an infinite waiting thread." + (thread != null ? " (" + thread + ")" : ""), expr.pos);
        }
        return expr;
    }

    /**
     * Checks if an expression contains a call to waitForThreads.
     * @param expr The expression to check.
     * @return Whether the expression contains a call to waitForThreads.
     */
    private static function containsWaitForThreads(expr:Expr):Bool {
        switch (expr.expr) {
            case ECall(e, _):
                switch (e.expr) {
                    case EField(_, "waitForThreads"):
                        return true;
                    default:
                        return false;
                }
            case EBlock(exprs):
                for (e in exprs) {
                    if (containsWaitForThreads(e)) {
                        return true;
                    }
                }
                return false;
            default:
                return false;
        }
    }
}

/**
 * An extension of ThreadQueue that waits for the queue to be empty before adding more to it.
 */
class PatientThreadQueue extends ThreadQueue {

    var waiting:Bool = false;

    var curQueue:Array<() -> Void> = [];

    public function new(maxConcurrent:Int = 1, blockUntilFinished:Bool = false) {
        super(maxConcurrent, blockUntilFinished);
        // curQueue = [];
    }

    override private function processQueue():Void {
        if (done && queue.length > 0) {
            done = false;
            trace("Processing queue...");
        }
        while (queue.length > 0 || curQueue.length > 0) {
            if (curQueue.length == 0) {
                for (i in 0...maxConcurrent) {
                    if (queue.length > 0) {
                        var func = queue.shift();
                        if (func != null) {
                            curQueue.push(func);
                        }
                    }
                }
            }

            while (curQueue.length > 0) {
                var func = curQueue.shift();
                if (func == null) {
                    trace("Encountered a null function in the curQueue. Skipping...");
                    continue;
                }
                running++;
                try {
                    sys.thread.Thread.create(function() {
                        try {
                            func();
                        } catch (e:Dynamic) {
                            trace("Exception in thread function: " + e + " ... " + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
                        }
                        running--;
                        processQueue();
                    });
                } catch (e:Dynamic) {
                    trace("Failed to create thread: " + e);
                    running--;
                }
            }

            if (queue.length == 0 && curQueue.length == 0 && running == 0) {
                trace("Queue is empty.");
                done = true;
                waiting = false;
                break;
            }
        }
    }
}