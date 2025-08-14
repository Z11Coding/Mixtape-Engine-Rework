package yutautil;

/**
 * Custom exception type for unexpected crashes detected by the CrashReporter
 */
class UnexpectedCrashException {
    public var message:String;
    public var originalException:Dynamic;
    public var crashDetails:Dynamic;
    public var timestamp:Date;
    public var functionStack:Array<String>;
    
    public function new(message:String, ?originalException:Dynamic, ?crashDetails:Dynamic) {
        this.message = message;
        this.originalException = originalException;
        this.crashDetails = crashDetails;
        this.timestamp = Date.now();
        this.functionStack = CrashReporter.getCurrentFunctionStack();
    }
    
    public function toString():String {
        var result = 'UnexpectedCrashException: $message';
        if (originalException != null) {
            result += '\nOriginal Exception: $originalException';
        }
        if (functionStack.length > 0) {
            result += '\nFunction Stack: ${functionStack.join(" -> ")}';
        }
        return result;
    }
    
    public function getFullReport():String {
        var report = toString();
        if (crashDetails != null) {
            report += '\n\nCrash Details:\n${haxe.Json.stringify(crashDetails, "  ")}';
        }
        return report;
    }
}
