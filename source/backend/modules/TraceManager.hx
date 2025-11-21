package backend.modules;

import flixel.FlxG;

#if sys
import sys.thread.Mutex;
import sys.thread.Thread;
#end

typedef TraceEntry = {
    var message:String;
    var timestamp:String;
    var source:String;
    var posInfo:haxe.PosInfos;
    var fullText:String;
}

/**
 * Enhanced trace management class with frame-based limiting, queuing, and optional threading
 *
 * Features:
 * - Frame-based console limiting: Limits ONLY console traces per frame to prevent lag spikes
 * - Automatic queue processing: Queued console traces are processed automatically each frame
 * - In-game traces unlimited: In-game trace viewer is never limited and always shows all traces
 * - Optional threading: Process traces on separate thread for better performance (sys targets only)
 *
 * How it works:
 * - When frame limiting is enabled, console traces are queued and processed at max N per frame
 * - In-game traces are always processed immediately and stored without limits
 * - Queue is processed automatically every frame via update() - no waiting for new traces
 * - Threading mode bypasses frame limiting entirely for better performance
 *
 * Settings (in ClientPrefs):
 * - enableFrameTraceLimiting: Enable/disable console frame-based limiting
 * - maxTracesPerFrame: Maximum console traces to output per frame (1-50)
 * - useTraceThreading: Use separate thread for trace processing (experimental)
 * - traceMode: Where traces appear (CONSOLE, GAME, BOTH)
 *
 * Command prompt commands:
 * - traceInfo: Show trace system status and queue information
 * - traceLimit: Control frame limiting settings
 * - traceThread: Control threading settings (sys targets only)
 * - stressTrace: Test the trace limiting system
 * - flushTraces: Immediately flush all queued traces (bypasses frame limits)
 */
class TraceManager
{
    private static var traces:Array<String> = [];
    private static var viewerGroup:flixel.group.FlxGroup;
    public static var isShowing:Bool = false;
    private static var traceText:flixel.text.FlxText;
    private static var background:flixel.FlxSprite;
    private static var maxTraces:Int = 100;

    // Store original trace function to prevent recursion
    private static var originalTrace:Dynamic -> ?haxe.PosInfos -> Void;

    // Frame-based trace limiting system
    private static var traceQueue:Array<TraceEntry> = [];
    private static var currentFrameTraces:Int = 0;
    private static var lastFrameCount:Int = 0;
    private static var maxTracesPerFrame:Int = 5;

    // Threading system
    #if sys
    private static var traceMutex:Mutex;
    private static var traceThread:Thread;
    private static var threadActive:Bool = false;
    private static var threadQueue:Array<TraceEntry> = [];
    #end

    private static var initialized:Bool = false;

    public static function setOriginalTrace(originalTraceFunc:Dynamic -> ?haxe.PosInfos -> Void):Void
    {
        originalTrace = originalTraceFunc;
    }

    private static function initialize():Void
    {
        if (initialized) return;
        initialized = true;

        #if sys
        traceMutex = new Mutex();
        #end

        // Reset frame tracking
        lastFrameCount = FlxG.game.ticks;
    }

    public static function addTrace(message:String, ?posInfo:haxe.PosInfos):Void
    {
        if (!initialized) initialize();

        updateMaxTraces(); // Update from settings

        var timestamp = Date.now().toString().substr(11, 8);
        var source = posInfo != null ? '${posInfo.fileName}:${posInfo.lineNumber}' : 'Unknown';
        var entry:TraceEntry = {
            message: message,
            timestamp: timestamp,
            source: source,
            posInfo: posInfo,
            fullText: '[$timestamp] $source: $message'
        };

        // Check if we should use threading
        if (backend.ClientPrefs.data.useTraceThreading) {
            #if sys
            addTraceThreaded(entry);
            #else
            // Fallback to regular processing on non-sys targets
            addTraceRegular(entry);
            #end
        } else {
            addTraceRegular(entry);
        }
    }

    private static function addTraceRegular(entry:TraceEntry):Void
    {
        // Check if we should apply frame limiting to console output
        var traceMode = backend.ClientPrefs.data.traceMode;
        var affectsConsole = (traceMode == "CONSOLE" || traceMode == "BOTH");

        if (backend.ClientPrefs.data.enableFrameTraceLimiting && affectsConsole) {
            // Frame limiting applies - queue the trace for console processing
            traceQueue.push(entry);
        } else {
            // No frame limiting, or doesn't affect console - process immediately
            processTrace(entry);
        }
    }

    #if sys
    private static function addTraceThreaded(entry:TraceEntry):Void
    {
        traceMutex.acquire();
        threadQueue.push(entry);
        traceMutex.release();

        if (!threadActive) {
            startTraceThread();
        }
    }

    private static function startTraceThread():Void
    {
        if (threadActive) return;
        threadActive = true;

        traceThread = Thread.create(function() {
            while (threadActive) {
                var entries:Array<TraceEntry> = [];

                // Get queued traces
                traceMutex.acquire();
                if (threadQueue.length > 0) {
                    entries = threadQueue.copy();
                    threadQueue = [];
                }
                traceMutex.release();

                // Process entries
                for (entry in entries) {
                    // For threaded processing, we bypass frame limiting for console output
                    // since we're on a separate thread
                    processTraceThreadSafe(entry);
                }

                // Small delay to prevent excessive CPU usage
                Sys.sleep(0.001);
            }
        });
    }

    private static function processTraceThreadSafe(entry:TraceEntry):Void
    {
        // Add to traces array (thread-safe)
        traceMutex.acquire();
        traces.push(entry.fullText);

        // Keep only recent traces
        while (traces.length > maxTraces) {
            traces.shift();
        }
        traceMutex.release();

        // Output to console using original trace function (thread-safe)
        if (originalTrace != null) {
            originalTrace(entry.message, entry.posInfo);
        }
    }

    public static function stopTraceThread():Void
    {
        if (!threadActive) return;
        threadActive = false;

        if (traceThread != null) {
            // Thread will stop on next iteration
        }
    }
    #end

    private static function processTrace(entry:TraceEntry):Void
    {
        // Always add to in-game trace storage (never limited)
        traces.push(entry.fullText);

        // Keep only recent traces
        while (traces.length > maxTraces) {
            traces.shift();
        }

        // Output to console based on trace mode (this is where frame limiting applies)
        var traceMode = backend.ClientPrefs.data.traceMode;
        if (traceMode == "CONSOLE" || traceMode == "BOTH") {
            // Use stored original trace function to avoid recursion
            if (originalTrace != null) {
                originalTrace(entry.message, entry.posInfo);
            }
        }

        // Always update in-game display (never limited)
        updateDisplay();
    }



    private static function processQueuedTraces():Void
    {
        // Process as many queued traces as frame limit allows for console output
        while (traceQueue.length > 0 && currentFrameTraces < maxTracesPerFrame) {
            var entry = traceQueue.shift();

            // Add to in-game trace storage immediately (not limited)
            traces.push(entry.fullText);
            while (traces.length > maxTraces) {
                traces.shift();
            }

            // Output to console (this is the limited part)
            var traceMode = backend.ClientPrefs.data.traceMode;
            if (traceMode == "CONSOLE" || traceMode == "BOTH") {
                if (originalTrace != null) {
                    originalTrace(entry.message, entry.posInfo);
                }
                currentFrameTraces++; // Only increment for console output
            }
        }

        // Always update display after processing queued traces
        updateDisplay();
    }

    public static function update():Void
    {
        if (!initialized) return;

        // Update frame limiting system - process queue automatically each frame
        if (backend.ClientPrefs.data.enableFrameTraceLimiting) {
            var currentFrame = FlxG.game.ticks;
            if (currentFrame != lastFrameCount) {
                // New frame detected - reset counter and process queued traces
                lastFrameCount = currentFrame;
                currentFrameTraces = 0;
                processQueuedTraces();
            }
            maxTracesPerFrame = backend.ClientPrefs.data.maxTracesPerFrame;
        }

        // Update threading settings
        #if sys
        if (backend.ClientPrefs.data.useTraceThreading && !threadActive) {
            startTraceThread();
        } else if (!backend.ClientPrefs.data.useTraceThreading && threadActive) {
            stopTraceThread();
        }
        #end
    }

    public static function getQueueInfo():String
    {
        var info = 'Trace System Status:\n';
        info += '- Queued traces: ${traceQueue.length}\n';
        info += '- Current frame traces: $currentFrameTraces / $maxTracesPerFrame\n';
        info += '- Current frame: ${FlxG.game.ticks}\n';
        info += '- Last processed frame: $lastFrameCount\n';
        info += '- Frame limiting: ${backend.ClientPrefs.data.enableFrameTraceLimiting ? "ON" : "OFF"}\n';
        info += '- Trace mode: ${backend.ClientPrefs.data.traceMode}\n';
        info += '- Total traces stored: ${traces.length}\n';
        #if sys
        info += '- Threading: ${backend.ClientPrefs.data.useTraceThreading ? "ON" : "OFF"}\n';
        info += '- Thread active: ${threadActive ? "YES" : "NO"}\n';
        info += '- Thread queue: ${threadQueue.length}\n';
        #else
        info += '- Threading: UNAVAILABLE (non-sys target)\n';
        #end

        if (traceQueue.length > 0) {
            info += '\nNext queued trace: "${traceQueue[0].message}"';
        }

        return info;
    }

    /**
     * Flushes all queued traces immediately - useful for exit/shutdown scenarios
     * This bypasses frame limiting and processes ALL queued traces at once
     */
    public static function flushAllQueuedTraces():Void
    {
        if (!initialized) return;

        var flushedCount = 0;

        // Process all queued traces immediately, ignoring frame limits
        while (traceQueue.length > 0) {
            var entry = traceQueue.shift();

            // Add to in-game trace storage
            traces.push(entry.fullText);
            while (traces.length > maxTraces) {
                traces.shift();
            }

            // Output to console immediately
            var traceMode = backend.ClientPrefs.data.traceMode;
            if (traceMode == "CONSOLE" || traceMode == "BOTH") {
                if (originalTrace != null) {
                    originalTrace(entry.message, entry.posInfo);
                }
            }

            flushedCount++;
        }

        // Update display after flushing
        updateDisplay();

        // Reset frame counter since we bypassed limits
        currentFrameTraces = 0;

        if (flushedCount > 0) {
            trace("TraceManager: Flushed " + flushedCount + " queued traces on exit");
        }

        #if sys
        // Also flush thread queue if threading is active
        if (threadActive && threadQueue.length > 0) {
            traceMutex.acquire();
            var threadFlushedCount = threadQueue.length;
            for (entry in threadQueue) {
                // Process thread queued traces immediately
                traces.push(entry.fullText);
                while (traces.length > maxTraces) {
                    traces.shift();
                }
                if (originalTrace != null) {
                    originalTrace(entry.message, entry.posInfo);
                }
            }
            threadQueue = [];
            traceMutex.release();

            if (threadFlushedCount > 0) {
                trace("TraceManager: Flushed " + threadFlushedCount + " thread-queued traces on exit");
            }
        }
        #end
    }

    private static function updateMaxTraces():Void
    {
        maxTraces = backend.ClientPrefs.data.maxInGameTraces;
    }

    public static function toggleViewer():Void
    {
        if (isShowing)
            hideViewer();
        else
            showViewer();
    }

    public static function showViewer():Void
    {
        if (isShowing) return;

        createViewer();
        flixel.FlxG.state.add(viewerGroup);
        isShowing = true;
        updateDisplay();
    }

    public static function hideViewer():Void
    {
        if (!isShowing) return;

        if (viewerGroup != null)
        {
            flixel.FlxG.state.remove(viewerGroup);
        }
        isShowing = false;
    }

    private static function createViewer():Void
    {
        if (viewerGroup != null) return;

        viewerGroup = new flixel.group.FlxGroup();

        // Background
        background = new flixel.FlxSprite(10, 10);
        background.makeGraphic(800, 400, flixel.util.FlxColor.BLACK);
        background.alpha = 0.8;
        background.scrollFactor.set(0, 0);

        // Text display
        traceText = new flixel.text.FlxText(20, 20, 760, "Trace Viewer - F3: Toggle | ESC: Close");
        traceText.setFormat(null, 12, flixel.util.FlxColor.WHITE, flixel.text.FlxText.FlxTextAlign.LEFT);
        traceText.scrollFactor.set(0, 0);

        viewerGroup.add(background);
        viewerGroup.add(traceText);
    }

    private static function updateDisplay():Void
    {
        if (!isShowing || traceText == null) return;

        var displayText = "Trace Viewer - F3: Toggle | ESC: Close\n\n";

        // Show last 20 traces
        var startIndex = Std.int(Math.max(0, traces.length - 20));
        for (i in startIndex...traces.length)
        {
            displayText += traces[i] + "\n";
        }

        traceText.text = displayText;
    }
}
