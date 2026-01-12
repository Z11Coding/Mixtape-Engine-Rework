package backend.window;

#if EFFICIENCY_MODE_ALLOWED
#if windows
import backend.window.Priority;
#end

/**
 * Windows Efficiency Mode implementation for Mixtape Engine
 * Reduces CPU usage and power consumption for better battery life and thermal performance
 */
class EfficiencyMode {
    #if windows
    @:functionCode('
        #include <windows.h>
        #include <powersetting.h>
        #include <winbase.h>

        // SetThreadExecutionState to prevent sleep while maintaining efficiency
        EXECUTION_STATE WINAPI SetThreadExecutionState(EXECUTION_STATE esFlags);

        // Thread execution state flags
        #define ES_AWAYMODE_REQUIRED    0x00000040
        #define ES_CONTINUOUS           0x80000000
        #define ES_DISPLAY_REQUIRED     0x00000002
        #define ES_SYSTEM_REQUIRED      0x00000001

        bool setEfficiencyMode(bool enable) {
            HANDLE hProcess = GetCurrentProcess();
            if (hProcess == NULL) return false;

            if (enable) {
                // Set process priority to below normal for efficiency
                if (!SetPriorityClass(hProcess, BELOW_NORMAL_PRIORITY_CLASS)) {
                    return false;
                }

                // Set execution state to allow system to sleep/hibernate
                SetThreadExecutionState(ES_CONTINUOUS);

                return true;
            } else {
                // Restore normal priority
                if (!SetPriorityClass(hProcess, NORMAL_PRIORITY_CLASS)) {
                    return false;
                }

                // Prevent system from sleeping during gameplay
                SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);

                return true;
            }
        }

        bool isEfficiencyModeAvailable() {
            // Windows 11 22H2 and later have native efficiency mode
            OSVERSIONINFOEXW osvi = {};
            osvi.dwOSVersionInfoSize = sizeof(osvi);

            // Get version info
            HMODULE hMod = GetModuleHandleW(L"ntdll.dll");
            if (hMod) {
                typedef LONG (WINAPI* RtlGetVersionPtr)(PRTL_OSVERSIONINFOW);
                RtlGetVersionPtr fxPtr = (RtlGetVersionPtr)GetProcAddress(hMod, "RtlGetVersion");
                if (fxPtr != nullptr) {
                    RTL_OSVERSIONINFOW rovi = {};
                    rovi.dwOSVersionInfoSize = sizeof(rovi);
                    if (fxPtr(&rovi) == 0) {
                        // Windows 11 is version 10.0 build 22000+
                        return (rovi.dwMajorVersion >= 10 && rovi.dwBuildNumber >= 22000);
                    }
                }
            }
            return false;
        }

        bool setProcessEfficiencyMode(bool enable) {
            HANDLE hProcess = GetCurrentProcess();
            if (hProcess == NULL) return false;

            // Try to use newer Windows 11 efficiency APIs if available
            HMODULE hKernel32 = GetModuleHandleA("kernel32.dll");
            if (hKernel32) {
                // This is a simplified approach - real implementation would use
                // SetProcessInformation with ProcessPowerThrottling
                typedef BOOL (WINAPI* SetProcessInformationProc)(HANDLE, PROCESS_INFORMATION_CLASS, LPVOID, DWORD);
                SetProcessInformationProc pSetProcessInformation =
                    (SetProcessInformationProc)GetProcAddress(hKernel32, "SetProcessInformation");

                if (pSetProcessInformation) {
                    // Note: This requires proper PROCESS_POWER_THROTTLING_STATE structure
                    // For now, fall back to priority adjustment
                }
            }

            return setEfficiencyMode(enable);
        }
    ')
    private static function setEfficiencyModeNative(enable:Bool):Bool {
        return false;
    }

    @:functionCode('
        return isEfficiencyModeAvailable();
    ')
    private static function isEfficiencyModeAvailableNative():Bool {
        return false;
    }
    #end

    private static var _efficiencyModeActive:Bool = false;
    private static var _originalPriority:String = "Normal";

    /**
     * Check if Efficiency Mode is supported on this system
     */
    public static function isSupported():Bool {
        #if windows
        return isEfficiencyModeAvailableNative();
        #else
        return false;
        #end
    }

    /**
     * Enable or disable Efficiency Mode
     * @param enable Whether to enable efficiency mode
     * @return Success status
     */
    public static function setEfficiencyMode(enable:Bool):Bool {
        #if windows
        if (enable == _efficiencyModeActive) {
            return true; // Already in requested state
        }

        if (enable) {
            // Store current priority for restoration
            _originalPriority = Priority.getPriorityString();
            trace('EfficiencyMode: Storing original priority: $_originalPriority');

            // Enable efficiency mode
            var success = setEfficiencyModeNative(true);
            if (success) {
                _efficiencyModeActive = true;
                trace('EfficiencyMode: Enabled - reduced CPU usage and power consumption');

                // Additional efficiency measures
                Priority.setPriorityString("Below Normal");

                return true;
            } else {
                trace('EfficiencyMode: Failed to enable');
                return false;
            }
        } else {
            // Disable efficiency mode
            var success = setEfficiencyModeNative(false);
            if (success) {
                _efficiencyModeActive = false;
                trace('EfficiencyMode: Disabled - restored normal performance mode');

                // Restore original priority
                if (_originalPriority != null && _originalPriority != "") {
                    Priority.setPriorityString(_originalPriority);
                    trace('EfficiencyMode: Restored priority to $_originalPriority');
                }

                return true;
            } else {
                trace('EfficiencyMode: Failed to disable');
                return false;
            }
        }
        #else
        trace('EfficiencyMode: Not supported on this platform');
        return false;
        #end
    }

    /**
     * Get current efficiency mode status
     */
    public static function isActive():Bool {
        return _efficiencyModeActive;
    }

    /**
     * Toggle efficiency mode on/off
     */
    public static function toggle():Bool {
        return setEfficiencyMode(!_efficiencyModeActive);
    }

    /**
     * Get a description of what efficiency mode does
     */
    public static function getDescription():String {
        return "Reduces CPU usage and power consumption by lowering process priority and enabling system power management.\n" +
               "Ideal for laptop users or when running on battery power.\n" +
               "May slightly reduce performance but improves battery life and reduces heat generation.";
    }

    /**
     * Get current efficiency status as a readable string
     */
    public static function getStatusString():String {
        if (!isSupported()) {
            return "Not supported on this system";
        }

        return _efficiencyModeActive ? "Active (Power Saving)" : "Inactive (Normal Performance)";
    }
}
#else
// Efficiency Mode is disabled - provide stub class
class EfficiencyMode {
    public static function isSupported():Bool { return false; }
    public static function setEfficiencyMode(enable:Bool):Bool { return false; }
    public static function isActive():Bool { return false; }
    public static function toggle():Bool { return false; }
    public static function getDescription():String { return "Efficiency Mode is disabled in this build."; }
    public static function getStatusString():String { return "Feature disabled"; }
}
#end
