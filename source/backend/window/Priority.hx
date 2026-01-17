package backend.window;

import flixel.FlxG;
import haxe.Timer;

/**
 * Provides functionality for setting and getting process priority levels.
 * This allows the game to run at different priority levels for performance control.
 * Priority levels: IDLE < BELOW_NORMAL < NORMAL < ABOVE_NORMAL < HIGH < REALTIME
 *
 * Higher priorities give the process more CPU time but can affect system responsiveness.
 * Use carefully, especially REALTIME priority which can freeze the system.
 */
class Priority
{
    // Monitoring and force-lock variables
    private static var _monitorTimer:Timer;
    private static var _isMonitoring:Bool = false;
    private static var _targetPriority:Int = 2; // Default to Normal
    private static var _forceLockEnabled:Bool = false;
    private static var _lastKnownPriority:Int = 2;
    private static var _monitorInterval:Float = 1000; // Check every 1 second
    /**
     * Sets the process priority level.
     * @param priority Priority level (0=IDLE, 1=BELOW_NORMAL, 2=NORMAL, 3=ABOVE_NORMAL, 4=HIGH, 5=REALTIME)
     * @return Bool indicating if the operation was successful
     */
    public static function setPriority(priority:Int):Bool
    {
        #if windows
        return switch (priority)
        {
            case 0:
                backend.window.WindowsData.setProcessPriorityIdle();
            case 1:
                backend.window.WindowsData.setProcessPriorityBelowNormal();
            case 2:
                backend.window.WindowsData.setProcessPriorityNormal();
            case 3:
                backend.window.WindowsData.setProcessPriorityAboveNormal();
            case 4:
                backend.window.WindowsData.setProcessPriorityHigh();
            case 5:
                backend.window.WindowsData.setProcessPriorityRealtime();
            default:
                false;
        }
        #end
        return false;
    }

    /**
     * Gets the current process priority level.
     * @return Int representing the current priority level (-1 if unknown/unsupported)
     */
    public static function getPriority():Int
    {
        #if windows
        return switch (backend.window.WindowsData.getProcessPriority())
        {
            case 0x40:      // IDLE_PRIORITY_CLASS
                0;
            case 0x4000:    // BELOW_NORMAL_PRIORITY_CLASS
                1;
            case 0x20:      // NORMAL_PRIORITY_CLASS
                2;
            case 0x8000:    // ABOVE_NORMAL_PRIORITY_CLASS
                3;
            case 0x80:      // HIGH_PRIORITY_CLASS
                4;
            case 0x100:     // REALTIME_PRIORITY_CLASS
                5;
            default:
                -1; // Unknown priority
        }
        #end
        return -1;
    }

    /**
     * Gets a human-readable string representation of the current priority level.
     * @return String describing the current priority
     */
    public static function getPriorityString():String
    {
        return getPriorityStringFromLevel(getPriority());
    }

    /**
     * Sets the priority using a string description.
     * @param priorityString The priority level as a string
     * @return Bool indicating if the operation was successful
     */
    public static function setPriorityString(priorityString:String):Bool
    {
        var priority = switch (priorityString.toLowerCase())
        {
            case "idle":
                0;
            case "below normal", "belownormal", "below_normal":
                1;
            case "normal":
                2;
            case "above normal", "abovenormal", "above_normal":
                3;
            case "high":
                4;
            case "realtime", "real time", "real_time":
                5;
            default:
                -1;
        }

        return priority != -1 ? setPriority(priority) : false;
    }

    /**
     * Checks if the current priority has been changed externally (by Task Manager, etc.)
     * and returns the new priority level. Useful for monitoring external changes.
     * @param lastKnownPriority The last known priority level to compare against
     * @return Int representing the current priority, or -1 if no change detected
     */
    public static function checkForExternalChanges(lastKnownPriority:Int):Int
    {
        var currentPriority = getPriority();
        return (currentPriority != lastKnownPriority) ? currentPriority : -1;
    }

    /**
     * Resets the process priority to Normal (default system priority).
     * @return Bool indicating if the operation was successful
     */
    public static function resetToNormal():Bool
    {
        return setPriority(2); // NORMAL priority
    }

    // ========================================
    // Advanced Monitoring & Force-Lock Features
    // ========================================

    /**
     * Starts monitoring the process priority for external changes.
     * If force-lock is enabled, will automatically restore the target priority.
     * @param targetPriority The desired priority to maintain (0-5)
     * @param forceLock Whether to automatically restore priority when it changes
     * @param monitorIntervalMs How often to check priority (in milliseconds)
     */
    public static function startPriorityMonitoring(?targetPriority:Int = 2, ?forceLock:Bool = false, ?monitorIntervalMs:Float = 1000):Void
    {
        // Stop any existing monitoring
        stopPriorityMonitoring();

        _targetPriority = targetPriority;
        _forceLockEnabled = forceLock;
        _monitorInterval = monitorIntervalMs;
        _lastKnownPriority = getPriority();
        _isMonitoring = true;

        trace('Starting priority monitoring: Target=${_targetPriority}, ForceLock=${_forceLockEnabled}, Interval=${_monitorInterval}ms');

        // Create timer for continuous monitoring
        _monitorTimer = new Timer(Std.int(_monitorInterval));
        _monitorTimer.run = monitorPriorityLoop;

        // Set initial priority if different from current
        var currentPriority = getPriority();
        if (currentPriority != _targetPriority)
        {
            trace('Setting initial priority from ${currentPriority} to ${_targetPriority}');
            setPriority(_targetPriority);
            _lastKnownPriority = _targetPriority;
        }
    }

    /**
     * Stops priority monitoring and cleanup timer resources.
     */
    public static function stopPriorityMonitoring():Void
    {
        if (_monitorTimer != null)
        {
            _monitorTimer.stop();
            _monitorTimer = null;
        }
        _isMonitoring = false;
        trace('Priority monitoring stopped');
    }

    /**
     * Internal monitoring loop that checks for priority changes.
     */
    private static function monitorPriorityLoop():Void
    {
        if (!_isMonitoring) return;

        var currentPriority = getPriority();

        // Check if priority has been changed externally
        if (currentPriority != _lastKnownPriority)
        {
            #if verbose //I dont wanna be notified every 2 seconds dawg my mf terminal
            trace('Priority change detected: ${getPriorityStringFromLevel(_lastKnownPriority)} -> ${getPriorityStringFromLevel(currentPriority)}');
            #end

            if (_forceLockEnabled && currentPriority != _targetPriority)
            {
                #if verbose
                trace('Force-lock enabled: Restoring priority to ${getPriorityStringFromLevel(_targetPriority)}');
                #end
                setPriority(_targetPriority);
                _lastKnownPriority = _targetPriority;
            }
            else
            {
                _lastKnownPriority = currentPriority;
            }
        }
    }

    /**
     * Enables or disables force-lock functionality.
     * When enabled, the target priority will be automatically restored if changed externally.
     * @param enabled Whether to enable force-lock
     * @param targetPriority The priority to maintain when force-lock is active
     */
    public static function setForceLock(enabled:Bool, ?targetPriority:Int):Void
    {
        _forceLockEnabled = enabled;
        if (targetPriority != null)
        {
            _targetPriority = targetPriority;
        }

        trace('Force-lock ${enabled ? "enabled" : "disabled"}' + (enabled ? ' for priority ${getPriorityStringFromLevel(_targetPriority)}' : ''));

        // If enabling force-lock and monitoring isn't running, start it
        if (enabled && !_isMonitoring)
        {
            startPriorityMonitoring(_targetPriority, true);
        }
    }

    /**
     * Gets whether priority monitoring is currently active.
     * @return Bool indicating if monitoring is running
     */
    public static function isMonitoring():Bool
    {
        return _isMonitoring;
    }

    /**
     * Gets whether force-lock is currently enabled.
     * @return Bool indicating if force-lock is active
     */
    public static function isForceLockEnabled():Bool
    {
        return _forceLockEnabled;
    }

    /**
     * Gets the current target priority for monitoring/force-lock.
     * @return Int representing the target priority level
     */
    public static function getTargetPriority():Int
    {
        return _targetPriority;
    }

    /**
     * Sets the target priority for monitoring/force-lock without restarting monitoring.
     * @param priority The new target priority (0-5)
     */
    public static function setTargetPriority(priority:Int):Void
    {
        if (priority >= 0 && priority <= 5)
        {
            _targetPriority = priority;
            trace('Target priority updated to ${getPriorityStringFromLevel(_targetPriority)}');
        }
    }

    /**
     * Gets a human-readable string representation of a priority level.
     * @param priority The priority level to convert (0-5)
     * @return String describing the priority
     */
    public static function getPriorityStringFromLevel(priority:Int):String
    {
        return switch (priority)
        {
            case 0: "Idle";
            case 1: "Below Normal";
            case 2: "Normal";
            case 3: "Above Normal";
            case 4: "High";
            case 5: "Realtime";
            default: "Unknown";
        }
    }
}
