package yutautil;

import haxe.CallStack;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;
import flixel.FlxG;
import flixel.util.FlxTimer;

/**
 * Crash Reporter - Runtime component that logs engine activity and detects crashes
 */
class CrashReporter {
    private static var instance:CrashReporter;
    private static var logBuffer:Array<LogEntry> = [];
    private static var registeredInstances:Map<String, Array<Dynamic>> = new Map();
    
    // Function execution tracking
    private static var functionExecutionStack:Array<FunctionExecutionEntry> = [];
    private static var functionExecutionBuffer:Array<FunctionExecutionEntry> = [];
    private static var maxFunctionExecutionBuffer:Int = 500;
    
    // Expression execution tracking
    private static var expressionExecutionBuffer:Array<ExpressionExecutionEntry> = [];
    private static var maxExpressionExecutionBuffer:Int = 100;
    
    // Variable access tracking
    private static var variableAccessBuffer:Array<VariableAccessEntry> = [];
    private static var maxVariableAccessBuffer:Int = 200;
    
    /**
     * Simple date formatting function since DateTools.format is not available
     */
    private static function formatDate(date:Date, includeTime:Bool = true):String {
        var year = date.getFullYear();
        var month = StringTools.lpad(Std.string(date.getMonth() + 1), "0", 2);
        var day = StringTools.lpad(Std.string(date.getDate()), "0", 2);
        
        if (!includeTime) {
            return '$year-$month-$day';
        }
        
        var hour = StringTools.lpad(Std.string(date.getHours()), "0", 2);
        var minute = StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
        var second = StringTools.lpad(Std.string(date.getSeconds()), "0", 2);
        
        return '$year-$month-$day - $hour-$minute-$second';
    }
    
    /**
     * Simple time formatting for log entries
     */
    private static function formatTime(date:Date):String {
        var hour = StringTools.lpad(Std.string(date.getHours()), "0", 2);
        var minute = StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
        var second = StringTools.lpad(Std.string(date.getSeconds()), "0", 2);
        return '$hour:$minute:$second';
    }
    private static var maxLogEntries:Int = 1000;
    private static var lastHeartbeat:Float = 0;
    private static var heartbeatInterval:Float = 1.0; // Check every second
    private static var crashDetectionEnabled:Bool = true;
    private static var logFile:String;
    private static var lockFile:String;
    private static var initialized:Bool = false;
    
    // Asynchronous logging system
    private static var asyncLogQueue:Array<LogEntry> = [];
    private static var asyncLoggingEnabled:Bool = true;
    private static var maxAsyncQueueSize:Int = 5000;
    private static var asyncFlushTimer:flixel.util.FlxTimer;
    private static var asyncFlushInterval:Float = 0.1; // Flush async queue every 100ms
    
    public static function init():Void {
        if (initialized) return;
        initialized = true;
        
        instance = new CrashReporter();
        
        // Set up log file path
        var loggerDir = "logger";
        if (!FileSystem.exists(loggerDir)) {
            FileSystem.createDirectory(loggerDir);
        }
        
        // Check for previous unexpected crashes
        checkForUnexpectedCrash(loggerDir);
        
        var timestamp = formatDate(Date.now());
        logFile = Path.join([loggerDir, 'engine_activity_$timestamp.log']);
        lockFile = Path.join([loggerDir, 'engine_running.lock']);
        
        // Create lock file to indicate engine is running
        createLockFile();
        
        // Start monitoring
        startHeartbeatMonitor();
        
        // Start async log processing
        startAsyncLogProcessor();
        
        // Log initialization
        logActivity("CrashReporter", "init", "Crash tracking initialized");
        
        trace('CrashReporter: Initialized with log file: $logFile');
    }
    
    /**
     * Log an activity in the engine (asynchronous for performance)
     */
    public static function logActivity(className:String, method:String, action:String):Void {
        if (!initialized) init();
        
        var entry:LogEntry = {
            timestamp: Date.now(),
            className: className,
            method: method,
            action: action,
            thread: "main", // Haxe is single-threaded, but keeping for future
            stackTrace: getSimpleStackTrace()
        };
        
        if (asyncLoggingEnabled) {
            // Add to async queue for background processing
            asyncLogQueue.push(entry);
            
            // Prevent queue from growing too large
            if (asyncLogQueue.length > maxAsyncQueueSize) {
                asyncLogQueue.splice(0, asyncLogQueue.length - maxAsyncQueueSize);
            }
        } else {
            // Fallback to synchronous logging
            logBuffer.push(entry);
            
            // Trim buffer if too large
            if (logBuffer.length > maxLogEntries) {
                logBuffer.splice(0, logBuffer.length - maxLogEntries);
            }
            
            // Write to file periodically
            if (logBuffer.length % 50 == 0) {
                flushLogToFile();
            }
        }
        
        // Update heartbeat (this is lightweight)
        lastHeartbeat = haxe.Timer.stamp();
    }
    
    /**
     * Begin function execution tracking (for function wrapping)
     */
    public static function beginFunctionExecution(className:String, methodName:String):Void {
        if (!initialized) init();
        
        var entry:FunctionExecutionEntry = {
            className: className,
            methodName: methodName,
            startTime: Date.now(),
            endTime: null,
            successful: null,
            stackDepth: functionExecutionStack.length
        };
        
        functionExecutionStack.push(entry);
        functionExecutionBuffer.push(entry);
        
        // Trim buffer if too large
        if (functionExecutionBuffer.length > maxFunctionExecutionBuffer) {
            functionExecutionBuffer.splice(0, functionExecutionBuffer.length - maxFunctionExecutionBuffer);
        }
        
        logActivity(className, methodName, "begin_execution");
    }
    
    /**
     * End function execution tracking
     */
    public static function endFunctionExecution(className:String, methodName:String, successful:Bool):Void {
        if (!initialized) init();
        
        // Find the matching entry in the stack
        var entry = null;
        for (i in 0...functionExecutionStack.length) {
            var stackEntry = functionExecutionStack[functionExecutionStack.length - 1 - i];
            if (stackEntry.className == className && stackEntry.methodName == methodName) {
                entry = stackEntry;
                functionExecutionStack.splice(functionExecutionStack.length - 1 - i, 1);
                break;
            }
        }
        
        if (entry != null) {
            entry.endTime = Date.now();
            entry.successful = successful;
        }
        
        logActivity(className, methodName, successful ? "end_execution_success" : "end_execution_failure");
    }
    
    /**
     * Log expression execution (for detailed tracking)
     */
    public static function logExpressionExecution(className:String, methodName:String, expressionAction:String):Void {
        if (!initialized) init();
        
        var entry:ExpressionExecutionEntry = {
            className: className,
            methodName: methodName,
            expressionAction: expressionAction,
            timestamp: Date.now(),
            stackDepth: functionExecutionStack.length
        };
        
        expressionExecutionBuffer.push(entry);
        
        // Trim buffer if too large
        if (expressionExecutionBuffer.length > maxExpressionExecutionBuffer) {
            expressionExecutionBuffer.splice(0, expressionExecutionBuffer.length - maxExpressionExecutionBuffer);
        }
        
        // Only log expression details if we're in detailed mode, but don't spam the main log
        if (yutautil.CrashTracker.ENABLE_DETAILED_EXPRESSION_TRACKING) {
            logActivity(className, methodName, 'expr: $expressionAction');
        }
    }
    
    /**
     * Get current function execution stack
     */
    public static function getCurrentFunctionStack():Array<String> {
        var stack = [];
        for (entry in functionExecutionStack) {
            stack.push('${entry.className}.${entry.methodName}');
        }
        return stack;
    }
    
    /**
     * Get recent function executions
     */
    public static function getRecentFunctionExecutions(count:Int = 10):Array<FunctionExecutionEntry> {
        return functionExecutionBuffer.slice(-count);
    }
    
    /**
     * Log variable access (for detailed tracking)
     */
    public static function logVariableAccess(className:String, methodName:String, variableName:String, accessType:String, value:Dynamic, position:String):Void {
        if (!initialized) init();
        
        var valueStr = "null";
        try {
            if (value != null) {
                valueStr = Std.string(value);
                // Truncate very long values
                if (valueStr.length > 100) {
                    valueStr = valueStr.substr(0, 97) + "...";
                }
            }
        } catch (e:Dynamic) {
            valueStr = "[error_converting_value]";
        }
        
        var entry:VariableAccessEntry = {
            className: className,
            methodName: methodName,
            variableName: variableName,
            accessType: accessType,
            variableValue: valueStr,
            timestamp: Date.now(),
            position: position,
            stackDepth: functionExecutionStack.length
        };
        
        variableAccessBuffer.push(entry);
        
        // Trim buffer if too large
        if (variableAccessBuffer.length > maxVariableAccessBuffer) {
            variableAccessBuffer.splice(0, variableAccessBuffer.length - maxVariableAccessBuffer);
        }
        
        // Only log variable details if we're in detailed mode
        if (yutautil.CrashTracker.ENABLE_DETAILED_EXPRESSION_TRACKING) {
            logActivity(className, methodName, '$accessType $variableName = $valueStr at $position');
        }
    }
    
    /**
     * Get recent variable accesses
     */
    public static function getRecentVariableAccesses(count:Int = 30):Array<VariableAccessEntry> {
        return variableAccessBuffer.slice(-count);
    }
    
    /**
     * Clear function execution buffer when function completes
     */
    public static function clearFunctionBuffer(className:String, methodName:String):Void {
        // Remove completed function entries from the buffer
        functionExecutionBuffer = functionExecutionBuffer.filter(function(entry) {
            return !(entry.className == className && entry.methodName == methodName && entry.successful == true);
        });
    }
    
    /**
     * Check for command exit and log it
     */
    public static function checkCommandExit():Void {
        if (yutautil.CrashTracker.ENABLE_COMMAND_EXIT_TRACKING) {
            logActivity("System", "commandExit", "Game was force closed by $exit command");
            generateEnhancedCrashReport("Game force closed by user command ($exit)");
        }
    }
    
    /**
     * Get recent expression executions
     */
    public static function getRecentExpressionExecutions(count:Int = 20):Array<ExpressionExecutionEntry> {
        return expressionExecutionBuffer.slice(-count);
    }
    
    /**
     * Check for unexpected crash and throw custom exception
     */
    public static function checkForUnexpectedCrashAndThrow():Void {
        try {
            var loggerDir = "logger";
            ensureDirectoryExists(loggerDir);
            
            var potentialLockFile = Path.join([loggerDir, 'engine_running.lock']);
            
            if (FileSystem.exists(potentialLockFile)) {
                var lockContent = File.getContent(potentialLockFile);
                var lockInfo = haxe.Json.parse(lockContent);
                
                // Remove the lock file first
                FileSystem.deleteFile(potentialLockFile);
                
                // Throw custom exception
                throw new UnexpectedCrashException("Engine crashed unexpectedly in previous session", lockInfo);
            }
        } catch (e:UnexpectedCrashException) {
            // Re-throw our custom exception
            throw e;
        } catch (e:Dynamic) {
            trace('CrashReporter: Failed to check for unexpected crash: $e');
        }
    }
    
    /**
     * Enhanced crash report generation with detailed tracking data
     */
    public static function generateEnhancedCrashReport(reason:String = "Unexpected crash detected"):Void {
        if (!initialized) init();
        
        var crashInfo = {
            reason: reason,
            timestamp: Date.now(),
            lastHeartbeat: lastHeartbeat,
            timeSinceHeartbeat: haxe.Timer.stamp() - lastHeartbeat,
            recentActivity: getRecentActivity(50),
            recentFunctionExecutions: getRecentFunctionExecutions(20),
            recentExpressionExecutions: getRecentExpressionExecutions(30),
            recentVariableAccesses: getRecentVariableAccesses(40),
            currentFunctionStack: getCurrentFunctionStack(),
            registeredInstances: getInstanceSummary(),
            stackTrace: getDetailedStackTrace(),
            systemInfo: getSystemInfo(),
            trackingConfiguration: {
                detailedExpressionTracking: yutautil.CrashTracker.ENABLE_DETAILED_EXPRESSION_TRACKING,
                functionWrapping: yutautil.CrashTracker.ENABLE_FUNCTION_WRAPPING,
                commandExitTracking: yutautil.CrashTracker.ENABLE_COMMAND_EXIT_TRACKING
            }
        };
        
        writeEnhancedCrashReport(crashInfo);
        
        trace('CrashReporter: Generated enhanced crash report - $reason');
    }
    
    /**
     * Write enhanced crash report with all tracking data
     */
    private static function writeEnhancedCrashReport(info:Dynamic):Void {
        try {
            var loggerDir = "logger";
            ensureDirectoryExists(loggerDir);
            
            var timestamp = formatDate(Date.now());
            var crashFile = Path.join([loggerDir, 'enhanced_crash_$timestamp.json']);
            
            var jsonContent = haxe.Json.stringify(info, "  ");
            File.saveContent(crashFile, jsonContent);
            
            // Also create a human-readable summary
            var summaryFile = Path.join([loggerDir, 'crash_summary_$timestamp.txt']);
            var summary = generateCrashSummary(info);
            File.saveContent(summaryFile, summary);
            
            // Also flush current log
            flushLogToFile();
            
            trace('CrashReporter: Enhanced crash report written to $crashFile');
            trace('CrashReporter: Human-readable summary written to $summaryFile');
        } catch (e:Dynamic) {
            trace('CrashReporter: Failed to write enhanced crash report: $e');
        }
    }
    
    /**
     * Generate human-readable crash summary
     */
    private static function generateCrashSummary(crashInfo:Dynamic):String {
        var summary = "=== CRASH REPORT SUMMARY ===\n\n";
        summary += 'Crash Reason: ${crashInfo.reason}\n';
        summary += 'Timestamp: ${crashInfo.timestamp}\n';
        summary += 'Time Since Last Heartbeat: ${crashInfo.timeSinceHeartbeat}s\n\n';
        
        summary += "=== CURRENT FUNCTION STACK ===\n";
        if (crashInfo.currentFunctionStack != null && crashInfo.currentFunctionStack.length > 0) {
            for (i in 0...crashInfo.currentFunctionStack.length) {
                var func = crashInfo.currentFunctionStack[i];
                summary += '  ${i + 1}. $func\n';
            }
        } else {
            summary += "  (empty)\n";
        }
        summary += "\n";
        
        summary += "=== RECENT VARIABLE ACCESSES ===\n";
        if (crashInfo.recentVariableAccesses != null && crashInfo.recentVariableAccesses.length > 0) {
            var varAccesses = crashInfo.recentVariableAccesses;
            for (i in 0...Std.int(Math.min(10, varAccesses.length))) {
                var access = varAccesses[Std.int(varAccesses.length - 1 - i)];
                summary += '  ${access.className}.${access.methodName}: ${access.accessType} ${access.variableName} = ${access.variableValue} (${access.position})\n';
            }
        } else {
            summary += "  (none recorded)\n";
        }
        summary += "\n";
        
        summary += "=== RECENT FUNCTION EXECUTIONS ===\n";
        if (crashInfo.recentFunctionExecutions != null && crashInfo.recentFunctionExecutions.length > 0) {
            var funcExecs = crashInfo.recentFunctionExecutions;
            for (i in 0...Std.int(Math.min(5, funcExecs.length))) {
                var exec = funcExecs[Std.int(funcExecs.length - 1 - i)];
                summary += '  ${exec.className}.${exec.methodName} (${exec.successful != null ? (exec.successful ? "completed" : "failed") : "running"})\n';
            }
        } else {
            summary += "  (none recorded)\n";
        }
        summary += "\n";
        
        summary += "=== RECENT ACTIVITY ===\n";
        if (crashInfo.recentActivity != null && crashInfo.recentActivity.length > 0) {
            var activities = crashInfo.recentActivity;
            for (i in 0...Std.int(Math.min(10, activities.length))) {
                var activity = activities[Std.int(activities.length - 1 - i)];
                summary += '  [${formatTime(activity.timestamp)}] ${activity.className}.${activity.method}: ${activity.action}\n';
            }
        } else {
            summary += "  (no recent activity)\n";
        }
        summary += "\n";
        
        summary += "=== SYSTEM INFO ===\n";
        if (crashInfo.systemInfo != null) {
            summary += '  Platform: ${crashInfo.systemInfo.platform}\n';
            summary += '  Current State: ${crashInfo.systemInfo.currentState}\n';
            summary += '  Game Time: ${crashInfo.systemInfo.gameTime}\n';
        }
        summary += "\n";
        
        summary += "=== TRACKING CONFIGURATION ===\n";
        if (crashInfo.trackingConfiguration != null) {
            summary += '  Detailed Expression Tracking: ${crashInfo.trackingConfiguration.detailedExpressionTracking}\n';
            summary += '  Function Wrapping: ${crashInfo.trackingConfiguration.functionWrapping}\n';
            summary += '  Command Exit Tracking: ${crashInfo.trackingConfiguration.commandExitTracking}\n';
        }
        
        summary += "\n=== END OF SUMMARY ===\n";
        
        return summary;
    }
    
    /**
     * Register an instance for tracking
     */
    public static function registerInstance(className:String, instance:Dynamic):Void {
        if (!initialized) init();
        
        if (!registeredInstances.exists(className)) {
            registeredInstances.set(className, []);
        }
        
        var instances = registeredInstances.get(className);
        if (instances.indexOf(instance) == -1) {
            instances.push(instance);
            logActivity("CrashReporter", "registerInstance", 'Registered instance of $className');
        }
    }
    
    /**
     * Handle an exception that was caught
     */
    public static function handleException(className:String, method:String, exception:Dynamic):Void {
        var exceptionInfo = {
            className: className,
            method: method,
            exception: Std.string(exception),
            stackTrace: getDetailedStackTrace(),
            timestamp: Date.now(),
            recentActivity: getRecentActivity(20)
        };
        
        logActivity("CrashReporter", "handleException", 'Exception in $className.$method: $exception');
        
        // Write exception report immediately
        writeExceptionReport(exceptionInfo);
    }
    
    /**
     * Generate a crash report for unexpected crashes
     */
    public static function generateCrashReport(reason:String = "Unexpected crash detected"):Void {
        if (!initialized) init();
        
        var crashInfo = {
            reason: reason,
            timestamp: Date.now(),
            lastHeartbeat: lastHeartbeat,
            timeSinceHeartbeat: haxe.Timer.stamp() - lastHeartbeat,
            recentActivity: getRecentActivity(50),
            registeredInstances: getInstanceSummary(),
            stackTrace: getDetailedStackTrace(),
            systemInfo: getSystemInfo()
        };
        
        writeCrashReport(crashInfo);
        
        trace('CrashReporter: Generated crash report - $reason');
    }
    
    /**
     * Get recent activity from the log buffer
     */
    public static function getRecentActivity(count:Int = 10):Array<LogEntry> {
        var recent = logBuffer.slice(-count);
        return recent;
    }
    
    /**
     * Start the async log processor to handle logging off the main thread
     */
    private static function startAsyncLogProcessor():Void {
        if (!asyncLoggingEnabled) return;
        
        // Use FlxTimer for async processing
        asyncFlushTimer = new FlxTimer().start(asyncFlushInterval, function(timer:FlxTimer) {
            processAsyncLogQueue();
        }, 0); // Loop infinitely
        
        trace('CrashReporter: Async log processor started');
    }
    
    /**
     * Process the async log queue in the background
     */
    private static function processAsyncLogQueue():Void {
        if (asyncLogQueue.length == 0) return;
        
        // Move entries from async queue to main log buffer
        var entriesToProcess = asyncLogQueue.splice(0, asyncLogQueue.length);
        
        for (entry in entriesToProcess) {
            logBuffer.push(entry);
        }
        
        // Trim buffer if too large
        if (logBuffer.length > maxLogEntries) {
            logBuffer.splice(0, logBuffer.length - maxLogEntries);
        }
        
        // Write to file if buffer is getting large
        if (logBuffer.length > 50) {
            flushLogToFile();
        }
    }
    
    /**
     * Start the heartbeat monitor to detect crashes
     */
    private static function startHeartbeatMonitor():Void {
        if (!crashDetectionEnabled) return;
        
        // Use FlxTimer for regular monitoring
        new FlxTimer().start(heartbeatInterval, function(timer:FlxTimer) {
            var currentTime = haxe.Timer.stamp();
            var timeSinceHeartbeat = currentTime - lastHeartbeat;
            
            // If more than 5 seconds since last activity, something might be wrong
            if (timeSinceHeartbeat > 5.0 && logBuffer.length > 0) {
                logActivity("CrashReporter", "heartbeatMonitor", 'Potential hang detected - ${timeSinceHeartbeat}s since last activity');
            }
            
            // If more than 30 seconds, generate a crash report
            if (timeSinceHeartbeat > 30.0 && logBuffer.length > 0) {
                generateCrashReport('Engine hang detected - ${timeSinceHeartbeat}s without activity');
            }
        }, 0); // Loop infinitely
    }
    
    /**
     * Get a simple stack trace for regular logging
     */
    private static function getSimpleStackTrace():String {
        var stack = CallStack.callStack();
        if (stack.length > 0) {
            var topFrame = stack[0];
            return switch (topFrame) {
                case FilePos(_, file, line): Path.withoutDirectory(file) + ":" + line;
                case Method(className, method): className + "." + method;
                case _: "unknown";
            };
        }
        return "no_stack";
    }
    
    /**
     * Get a detailed stack trace for exception/crash reports
     */
    private static function getDetailedStackTrace():Array<String> {
        var stack = CallStack.callStack();
        var traces:Array<String> = [];
        
        for (frame in stack) {
            var frameStr = switch (frame) {
                case FilePos(innerStack, file, line):
                    var inner = switch (innerStack) {
                        case Method(className, method): '$className.$method';
                        case _: "unknown";
                    };
                    '$inner at ${Path.withoutDirectory(file)}:$line';
                case Method(className, method): '$className.$method';
                case _: "unknown frame";
            };
            traces.push(frameStr);
        }
        
        return traces;
    }
    
    /**
     * Get summary of registered instances
     */
    private static function getInstanceSummary():Map<String, Int> {
        var summary = new Map<String, Int>();
        
        for (className => instances in registeredInstances) {
            summary.set(className, instances.length);
        }
        
        return summary;
    }
    
    /**
     * Get system information
     */
    private static function getSystemInfo():Dynamic {
        return {
            platform: Sys.systemName(),
            haxeVersion: "4.x", // Static since macro context isn't available at runtime
            flixelVersion: "5.x", // Static since FlxVersion may not exist
            memoryUsage: #if cpp "available" #else "unavailable" #end,
            currentState: FlxG.state != null ? Type.getClassName(Type.getClass(FlxG.state)) : "null",
            gameTime: FlxG.game != null ? FlxG.game.ticks : 0
        };
    }
    
    /**
     * Ensure a directory exists, creating it if necessary
     */
    private static function ensureDirectoryExists(dirPath:String):Void {
        try {
            if (!FileSystem.exists(dirPath)) {
                FileSystem.createDirectory(dirPath);
                trace('CrashReporter: Created directory: $dirPath');
            }
        } catch (e:Dynamic) {
            trace('CrashReporter: Failed to create directory $dirPath: $e');
        }
    }

    /**
     * Write log buffer to file
     */
    private static function flushLogToFile():Void {
        if (logFile == null || logBuffer.length == 0) return;
        
        try {
            // Ensure the logger directory exists (explicitly)
            ensureDirectoryExists("logger");
            
            var content = "";
            
            // If file doesn't exist, add header
            if (!FileSystem.exists(logFile)) {
                content += "# Engine Activity Log - Generated by CrashReporter\n";
                content += "# Format: [TIMESTAMP] CLASS.METHOD: ACTION (STACK)\n\n";
            }
            
            // Add recent entries
            var entriesToWrite = logBuffer.slice(-50); // Write last 50 entries
            for (entry in entriesToWrite) {
                var timestamp = formatTime(entry.timestamp);
                content += '[$timestamp] ${entry.className}.${entry.method}: ${entry.action} (${entry.stackTrace})\n';
            }
            
            // Append to file
            if (FileSystem.exists(logFile)) {
                var existing = File.getContent(logFile);
                File.saveContent(logFile, existing + content);
            } else {
                File.saveContent(logFile, content);
            }
        } catch (e:Dynamic) {
            trace('CrashReporter: Failed to write log file: $e');
        }
    }
    
    /**
     * Write exception report
     */
    private static function writeExceptionReport(info:Dynamic):Void {
        try {
            var loggerDir = "logger";
            ensureDirectoryExists(loggerDir);
            
            var timestamp = formatDate(Date.now());
            var exceptionFile = Path.join([loggerDir, 'exception_$timestamp.json']);
            
            var jsonContent = haxe.Json.stringify(info, "  ");
            File.saveContent(exceptionFile, jsonContent);
            
            trace('CrashReporter: Exception report written to $exceptionFile');
        } catch (e:Dynamic) {
            trace('CrashReporter: Failed to write exception report: $e');
        }
    }
    
    /**
     * Write crash report
     */
    private static function writeCrashReport(info:Dynamic):Void {
        try {
            var loggerDir = "logger";
            ensureDirectoryExists(loggerDir);
            
            var timestamp = formatDate(Date.now());
            var crashFile = Path.join([loggerDir, 'crash_$timestamp.json']);
            
            var jsonContent = haxe.Json.stringify(info, "  ");
            File.saveContent(crashFile, jsonContent);
            
            // Also flush current log
            flushLogToFile();
            
            trace('CrashReporter: Crash report written to $crashFile');
        } catch (e:Dynamic) {
            trace('CrashReporter: Failed to write crash report: $e');
        }
    }
    
    /**
     * Create lock file to indicate engine is running
     */
    private static function createLockFile():Void {
        try {
            var lockInfo = {
                pid: #if sys Sys.getEnv("PID") #else "unknown" #end,
                startTime: Date.now().toString(),
                version: "Mixtape Engine Rework"
            };
            
            var lockContent = haxe.Json.stringify(lockInfo, "  ");
            File.saveContent(lockFile, lockContent);
        } catch (e:Dynamic) {
            trace('CrashReporter: Failed to create lock file: $e');
        }
    }
    
    /**
     * Remove lock file when engine exits normally
     */
    public static function cleanupOnExit():Void {
        try {
            logActivity("CrashReporter", "cleanupOnExit", "Engine exiting normally - removing lock file");
            flushLogToFile();
            
            if (FileSystem.exists(lockFile)) {
                FileSystem.deleteFile(lockFile);
                trace('CrashReporter: Lock file removed - normal exit');
            }
        } catch (e:Dynamic) {
            trace('CrashReporter: Failed to cleanup on exit: $e');
        }
    }
    
    /**
     * Check for unexpected crashes from previous sessions
     */
    private static function checkForUnexpectedCrash(loggerDir:String):Void {
        try {
            ensureDirectoryExists(loggerDir);
            
            var potentialLockFile = Path.join([loggerDir, 'engine_running.lock']);
            
            if (FileSystem.exists(potentialLockFile)) {
                // Engine didn't exit cleanly last time
                var lockContent = File.getContent(potentialLockFile);
                var lockInfo = haxe.Json.parse(lockContent);
                
                trace('=================================');
                trace('UNEXPECTED CRASH DETECTED!');
                trace('The engine did not exit cleanly in the previous session.');
                trace('Previous session started at: ${lockInfo.startTime}');
                trace('Check the logger folder for crash reports and activity logs.');
                trace('=================================');
                
                // Generate a crash report for the previous session
                var crashInfo = {
                    reason: "Unexpected crash detected from previous session",
                    timestamp: Date.now(),
                    previousSession: lockInfo,
                    detectedAt: "Engine startup",
                    lockFileExists: true
                };
                
                var timestamp = formatDate(Date.now());
                var crashFile = Path.join([loggerDir, 'unexpected_crash_$timestamp.json']);
                var jsonContent = haxe.Json.stringify(crashInfo, "  ");
                File.saveContent(crashFile, jsonContent);
                
                // Remove the old lock file
                FileSystem.deleteFile(potentialLockFile);
                
                trace('CrashReporter: Unexpected crash report generated: $crashFile');
            } else {
                trace('CrashReporter: No unexpected crash detected - engine exited cleanly last time');
            }
        } catch (e:Dynamic) {
            trace('CrashReporter: Failed to check for unexpected crash: $e');
        }
    }
    
    /**
     * Enable or disable crash detection
     */
    public static function setCrashDetectionEnabled(enabled:Bool):Void {
        crashDetectionEnabled = enabled;
        logActivity("CrashReporter", "setCrashDetectionEnabled", 'Crash detection ${enabled ? "enabled" : "disabled"}');
    }
    
    /**
     * Set the heartbeat interval
     */
    public static function setHeartbeatInterval(interval:Float):Void {
        heartbeatInterval = interval;
        logActivity("CrashReporter", "setHeartbeatInterval", 'Heartbeat interval set to ${interval}s');
    }
    
    /**
     * Manually trigger crash report generation (for testing)
     */
    public static function triggerTestCrashReport():Void {
        generateCrashReport("Manual test crash report");
    }
    
    /**
     * Get current log buffer size
     */
    public static function getLogBufferSize():Int {
        return logBuffer.length;
    }
    
    /**
     * Clear log buffer (use with caution)
     */
    public static function clearLogBuffer():Void {
        logActivity("CrashReporter", "clearLogBuffer", 'Clearing log buffer (${logBuffer.length} entries)');
        logBuffer = [];
        asyncLogQueue = []; // Also clear async queue
    }
    
    /**
     * Async logging system controls
     */
    public static function setAsyncLoggingEnabled(enabled:Bool):Void {
        asyncLoggingEnabled = enabled;
        trace('CrashReporter: Async logging ${enabled ? "enabled" : "disabled"}');
        
        if (enabled && asyncFlushTimer == null && initialized) {
            startAsyncLogProcessor();
        }
    }
    
    public static function setAsyncFlushInterval(interval:Float):Void {
        asyncFlushInterval = interval;
        trace('CrashReporter: Async flush interval set to ${interval}s');
        
        // Restart timer with new interval
        if (asyncFlushTimer != null) {
            asyncFlushTimer.cancel();
            startAsyncLogProcessor();
        }
    }
    
    public static function setMaxAsyncQueueSize(size:Int):Void {
        maxAsyncQueueSize = size;
        trace('CrashReporter: Max async queue size set to $size entries');
    }
    
    /**
     * Force immediate processing of async queue
     */
    public static function forceAsyncFlush():Void {
        processAsyncLogQueue();
        flushLogToFile();
    }
    
    /**
     * Get async queue status
     */
    public static function getAsyncQueueSize():Int {
        return asyncLogQueue.length;
    }
    
    private function new() {
        // Private constructor - use static methods
    }
}

/**
 * Log entry structure
 */
typedef LogEntry = {
    var timestamp:Date;
    var className:String;
    var method:String;
    var action:String;
    var thread:String;
    var stackTrace:String;
}

/**
 * Function execution tracking entry
 */
typedef FunctionExecutionEntry = {
    var className:String;
    var methodName:String;
    var startTime:Date;
    var endTime:Null<Date>;
    var successful:Null<Bool>;
    var stackDepth:Int;
}

/**
 * Expression execution tracking entry
 */
typedef ExpressionExecutionEntry = {
    var className:String;
    var methodName:String;
    var expressionAction:String;
    var timestamp:Date;
    var stackDepth:Int;
}

/**
 * Variable access tracking entry
 */
typedef VariableAccessEntry = {
    var className:String;
    var methodName:String;
    var variableName:String;
    var accessType:String; // "read", "write", "declare"
    var variableValue:String; // String representation of value
    var timestamp:Date;
    var position:String; // File:Line information
    var stackDepth:Int;
}

/**
 * Custom exception for unexpected crashes
 */
class UnexpectedCrashException extends haxe.Exception {
    public var previousCrashData:Dynamic;
    public var detectionTime:Date;
    
    public function new(message:String, ?previousCrashData:Dynamic) {
        super(message);
        this.previousCrashData = previousCrashData;
        this.detectionTime = Date.now();
    }
    
    public override function toString():String {
        return 'UnexpectedCrashException: $message at ${detectionTime.toString()}';
    }
}
