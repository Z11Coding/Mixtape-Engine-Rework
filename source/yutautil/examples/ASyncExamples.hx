package yutautil.examples;

import haxe.Timer;
import yutautil.modules.ASync.AResult;
import yutautil.modules.ASync.ASyncHelper;
import yutautil.modules.ASync;

/**
 * Examples of how to use the ASync system for asynchronous programming
 * The ASync type wraps functions to run them in threads, returning AResult objects
 * that automatically convert to the expected type when ready
 */
class ASyncExamples {

    public static function example1_BasicUsage() {
        trace("=== ASync Basic Usage ===");

        // Regular function
        function slowCalculation(n:Int):Int {
            Sys.sleep(1.0); // Simulate 1 second of work
            return n * n;
        }

        // Wrap it in ASync - automatic conversion
        var asyncCalc:ASync<Int -> Int> = slowCalculation;

        // Call it asynchronously using operator overloading - returns immediately
        var result:AResult<Dynamic> = asyncCalc(10);

        trace("Started async calculation...");
        trace("Status: " + result.status); // Pending

        // The result automatically converts when ready
        // This will block until done
        var finalValue:Int = result; // Implicit conversion via @:to
        trace("Result: " + finalValue); // 100
    }

    public static function example2_WithCallbacks() {
        trace("=== ASync With Callbacks ===");

        function networkRequest(url:String):String {
            Sys.sleep(0.5); // Simulate network delay
            return "Response from " + url;
        }

        var asyncRequest:ASync<String -> String> = networkRequest;
        var result = asyncRequest("https://api.example.com");

        // Add callbacks instead of blocking
        result.onReady(function(response) {
            trace("Got response: " + response);
        });

        result.onError(function(error) {
            trace("Request failed: " + error);
        });

        trace("Request sent, continuing other work...");
        trace("Status: " + result.status); // Pending
        trace("Elapsed: " + result.elapsedTime + "s");

        // Do other things while waiting
        for (i in 0...5) {
            trace("Doing other work... " + i);
            Sys.sleep(0.1);
        }
    }

    public static function example3_TypedHelpers() {
        trace("=== ASync Type-Safe Helpers ===");

        // Using ASyncHelper for better type safety
        function addNumbers(a:Int, b:Int):Int {
            Sys.sleep(0.2);
            return a + b;
        }

        function processString(text:String):String {
            Sys.sleep(0.3);
            return text.toUpperCase();
        }

        // Create typed async functions
        var asyncAdd = ASyncHelper.async2(addNumbers);
        var asyncProcess = ASyncHelper.async1(processString);

        // Call them
        var sum = asyncAdd(5, 3);
        var processed = asyncProcess("hello world");

        // Use tryGet to check without blocking
        while (sum.tryGet() == null) {
            trace("Still calculating sum...");
            Sys.sleep(0.1);
        }

        trace("Sum: " + sum.tryGet()); // 8
        trace("Processed: " + processed); // "HELLO WORLD" (blocks until ready)
    }

    public static function example4_ParallelOperations() {
        trace("=== ASync Parallel Operations ===");

        function expensiveTask(id:Int):String {
            Sys.sleep(1.0); // Each takes 1 second
            return "Task " + id + " completed";
        }

        var asyncTask = ASyncHelper.async1(expensiveTask);

        // Create async functions that will be called by helper
        var task1Func = function() { return asyncTask(1); };
        var task2Func = function() { return asyncTask(2); };
        var task3Func = function() { return asyncTask(3); };

        // Convert to ASync functions
        var asyncTask1:ASync<Void -> Dynamic> = task1Func;
        var asyncTask2:ASync<Void -> Dynamic> = task2Func;
        var asyncTask3:ASync<Void -> Dynamic> = task3Func;

        trace("Started 3 parallel tasks...");
        var startTime = Timer.stamp();

        // Wait for all to complete using ASyncHelper.all
        var allResults = ASyncHelper.all([asyncTask1, asyncTask2, asyncTask3]);
        var results:Array<String> = allResults; // Blocks until all are done

        var elapsed = Timer.stamp() - startTime;
        trace("All tasks completed in " + elapsed + " seconds"); // ~1 second (not 3!)

        for (result in results) {
            trace(result);
        }
    }

    public static function example5_RaceCondition() {
        trace("=== ASync Race Condition ===");

        function randomDelayTask(name:String):String {
            var delay = Math.random() * 2.0; // 0-2 seconds
            Sys.sleep(delay);
            return name + " finished in " + delay + "s";
        }

        var asyncTask = ASyncHelper.async1(randomDelayTask);

        // Create async functions that will be called by helper
        var fastFunc = function() { return asyncTask("FastRunner"); };
        var mediumFunc = function() { return asyncTask("MediumRunner"); };
        var slowFunc = function() { return asyncTask("SlowRunner"); };

        // Convert to ASync functions
        var asyncFast:ASync<Void -> Dynamic> = fastFunc;
        var asyncMedium:ASync<Void -> Dynamic> = mediumFunc;
        var asyncSlow:ASync<Void -> Dynamic> = slowFunc;

        // Get the first one to finish
        var winner = ASyncHelper.race([asyncFast, asyncMedium, asyncSlow]);

        trace("Winner: " + winner.get()); // First to complete
    }

    public static function example6_ErrorHandling() {
        trace("=== ASync Error Handling ===");

        function riskyOperation(shouldFail:Bool):String {
            Sys.sleep(0.5);
            if (shouldFail) {
                throw "Operation failed!";
            }
            return "Success!";
        }

        var asyncRisky = ASyncHelper.async1(riskyOperation);

        // Start a failing operation
        var result = asyncRisky(true);

        result.onReady(function(value) {
            trace("Unexpected success: " + value);
        });

        result.onError(function(error) {
            trace("Caught error as expected: " + error);
        });

        // Try to get result (will throw)
        try {
            var value = result.get();
            trace("Should not reach here");
        } catch (e:Dynamic) {
            trace("Exception caught: " + e);
        }
    }

    public static function example7_TimeoutAndStatus() {
        trace("=== ASync Status and Timeout ===");

        function verySlowTask():String {
            Sys.sleep(5.0); // 5 seconds
            return "Finally done";
        }

        var asyncSlow = ASyncHelper.async0(verySlowTask);
        var result = asyncSlow();

        trace("Status: " + result.status); // Pending
        trace("Is ready: " + result.isReady); // false
        trace("Is failed: " + result.isFailed); // false

        // Try with timeout
        try {
            var value = result.getWithTimeout(1.0); // 1 second timeout
            trace("Got value: " + value);
        } catch (e:Dynamic) {
            trace("Timeout occurred: " + e);
        }

        trace("Elapsed time: " + result.elapsedTime + "s");
    }

    public static function example8_ChainedOperations() {
        trace("=== ASync Chained Operations ===");

        function step1():Int {
            Sys.sleep(0.3);
            return 42;
        }

        function step2(input:Int):String {
            Sys.sleep(0.3);
            return "Number is: " + input;
        }

        function step3(input:String):String {
            Sys.sleep(0.3);
            return input.toUpperCase() + "!";
        }

        // Chain operations using callbacks
        var asyncStep1 = ASyncHelper.async0(step1);
        var asyncStep2 = ASyncHelper.async1(step2);
        var asyncStep3 = ASyncHelper.async1(step3);

var result1 = asyncStep1();

        result1.onReady(function(value1) {
            var result2 = asyncStep2(value1);

            result2.onReady(function(value2) {
                var result3 = asyncStep3(value2);

                result3.onReady(function(finalValue) {
                    trace("Final chained result: " + finalValue);
                });
            });
        });

        trace("Chained operations started...");

        // Give time for chain to complete
        Sys.sleep(1.5);
    }

    public static function runAllExamples() {
        trace("Starting ASync Examples...\n");

        try {
            example1_BasicUsage();
            trace("");

            example2_WithCallbacks();
            trace("");

            example3_TypedHelpers();
            trace("");

            example4_ParallelOperations();
            trace("");

            example5_RaceCondition();
            trace("");

            example6_ErrorHandling();
            trace("");

            example7_TimeoutAndStatus();
            trace("");

            example8_ChainedOperations();
            trace("");

            trace("All ASync examples completed!");

        } catch (e:Dynamic) {
            trace("Error running examples: " + e);
        }
    }
}
