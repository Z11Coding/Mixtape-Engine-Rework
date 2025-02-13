package utils.window;

// enum abstract PriorityDef(T) {
//     var IDLE:PriorityVal = 0;
//     var BELOW_NORMAL:PriorityVal = 1;
//     var NORMAL:PriorityVal = 2;
//     var ABOVE_NORMAL:PriorityVal = 3;
//     var HIGH:PriorityVal = 4;
//     var REALTIME:PriorityVal = 5;
    
// }

// typedef PriorityVal = Int;

class Priority
{

    // private static var priorityMap:Map<PriorityDef, () -> Bool> = [
    //     IDLE => backend.window.WindowsData.setProcessPriorityIdle,
    //     BELOW_NORMAL => backend.window.WindowsData.setProcessPriorityBelowNormal,
    //     NORMAL => backend.window.WindowsData.setProcessPriorityNormal,
    //     ABOVE_NORMAL => backend.window.WindowsData.setProcessPriorityAboveNormal,
    //     HIGH => backend.window.WindowsData.setProcessPriorityHigh,
    //     REALTIME => backend.window.WindowsData.setProcessPriorityRealtime
    // ];
   public static function setPriority(priority:Int):Bool
    {
        #if windows
        return switch (priority)
        {
            case 0:
                utils.window.WindowsData.setProcessPriorityIdle();
            case 1:
                utils.window.WindowsData.setProcessPriorityBelowNormal();
            case 2:
                utils.window.WindowsData.setProcessPriorityNormal();
            case 3:
                utils.window.WindowsData.setProcessPriorityAboveNormal();
            case 4:
                utils.window.WindowsData.setProcessPriorityHigh();
            case 5:
                utils.window.WindowsData.setProcessPriorityRealtime();
            default:
                false;
        }
        #end
        return false;
    }

    public static function getPriority():Int
    {
        #if windows
        return switch (utils.window.WindowsData.getProcessPriority())
        {
            case 0x40:
                0; // IDLE
            case 0x4000:
                1; // BELOW_NORMAL
            case 0x20:
                2; // NORMAL
            case 0x8000:
                3; // ABOVE_NORMAL
            case 0x80:
                4; // HIGH
            case 0x100:
                5; // REALTIME
            default:
                -1; // Unknown priority
        }
        #end
        return -1;
    }

    // public static function setByCPPDefine(priority:PriorityDef):Bool {
    //     return priorityMap.exists(priority) ? priorityMap.get(priority)() : false;
    // }
}