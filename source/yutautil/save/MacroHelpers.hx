package yutautil.save;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Macro helper utilities for function capture system
 */
class MacroHelpers {

    #if macro

    /**
     * Builds the @:captureConstructor metadata
     * Usage: @:build(yutautil.save.MacroHelpers.captureConstructor())
     */
    public static macro function captureConstructor():Array<Field> {
        return FunctionCapture.captureConstructor();
    }

    /**
     * Builds the @:captureFunctions metadata
     * Usage: @:build(yutautil.save.MacroHelpers.captureFunctions())
     */
    public static macro function captureFunctions():Array<Field> {
        return FunctionCapture.captureFunctions();
    }

    /**
     * Builds both constructor and function capture
     * Usage: @:build(yutautil.save.MacroHelpers.captureAll())
     */
    public static macro function captureAll():Array<Field> {
        var fields = FunctionCapture.captureConstructor();
        return FunctionCapture.captureFunctions();
    }

    /**
     * Auto-build macro that can be used with @:autoBuild
     * This will automatically apply function capture to all classes in a package
     */
    public static macro function autoCaptureAll():Array<Field> {
        return captureAll();
    }

    #end
}
