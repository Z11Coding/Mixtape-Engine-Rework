package yutautil.clay;

// Experimental Haxe bindings for the Clay UI library.
// I'm working on making it possible to make dynamic UI Elements with Clay, similar to how it works in C++.
// This is a work in progress and may not be fully functional yet.
@:headerCode('#define CLAY_IMPLEMENTATION')
@:include("clay.h")
extern class Clay {
    @:native("Clay_MinMemorySize")
    public static function minMemorySize():Int;

    @:native("Clay_CreateArenaWithCapacityAndMemory")
    public static function createArena(capacity:Int, memory:cpp.RawPointer<Void>):Clay_Arena;

    @:native("Clay_Initialize")
    public static function initialize(arena:Clay_Arena, dimensions:Clay_Dimensions, errorHandler:Clay_ErrorHandler):cpp.Pointer<Clay_Context>;

    @:native("Clay_SetPointerState")
    public static function setPointerState(position:Clay_Vector2, pointerDown:Bool):Void;

    @:native("Clay_BeginLayout")
    public static function beginLayout():Void;

    @:native("Clay_EndLayout")
    public static function endLayout():Clay_RenderCommandArray;

    @:native("Clay_GetElementId")
    public static function getElementId(id:Clay_String):Clay_ElementId;

    @:native("Clay_Hovered")
    public static function hovered():Bool;

    @:native("Clay_SetMeasureTextFunction")
    public static function setMeasureTextFunction(func:cpp.Callable<Clay_StringSlice->cpp.Pointer<Clay_TextElementConfig>->cpp.RawPointer<Void>->Clay_Dimensions>, userData:cpp.RawPointer<Void>):Void;

    @:native("Clay_SetLayoutDimensions")
    public static function setLayoutDimensions(dimensions:Clay_Dimensions):Void;

    // Additional externs from clay.h
    @:native("Clay_GetPointerOverIds")
    public static function getPointerOverIds():Clay_ElementIdArray;

    @:native("Clay__HashString")
    public static function hashString(str:Clay_String, offset:UInt, seed:UInt):Clay_ElementId;

    @:native("Clay__HashNumber")
    public static function hashNumber(offset:UInt, seed:UInt):Clay_ElementId;

    @:native("Clay__FloatEqual")
    public static function floatEqual(left:Float, right:Float):Bool;

    @:native("Clay__PointIsInsideRect")
    public static function pointIsInsideRect(point:Clay_Vector2, rect:Clay_BoundingBox):Bool;

    @:native("Clay__IntToString")
    public static function intToString(integer:Int):Clay_String;

    @:native("Clay__WriteStringToCharBuffer")
    public static function writeStringToCharBuffer(buffer:Clay_CharArray, string:Clay_String):Clay_String;

    @:native("Clay__StoreLayoutConfig")
    public static function storeLayoutConfig(config:Clay_LayoutConfig):cpp.Pointer<Clay_LayoutConfig>;

    @:native("Clay__StoreTextElementConfig")
    public static function storeTextElementConfig(config:Clay_TextElementConfig):cpp.Pointer<Clay_TextElementConfig>;

    @:native("Clay__OpenElement")
    public static function openElement():Void;

    @:native("Clay__CloseElement")
    public static function closeElement():Void;

    @:native("Clay__ConfigureOpenElement")
    public static function configureOpenElement(declaration:Clay_ElementDeclaration):Void;

    @:native("Clay__Context_Allocate_Arena")
    public static function contextAllocateArena(arena:Clay_Arena):cpp.Pointer<Clay_Context>;

    @:native("Clay__CalculateFinalLayout")
    public static function calculateFinalLayout():Void;

    @:native("Clay_GetCurrentContext")
    public static function getCurrentContext():cpp.Pointer<Clay_Context>;
}

// Structs
@:structAccess extern class Clay_Dimensions {
    var width:Float;
    var height:Float;
}

@:structAccess extern class Clay_Vector2 {
    var x:Float;
    var y:Float;
}

@:structAccess extern class Clay_Color {
    var r:Float;
    var g:Float;
    var b:Float;
    var a:Float;
}

@:structAccess extern class Clay_CornerRadius {
    var topLeft:Float;
    var topRight:Float;
    var bottomRight:Float;
    var bottomLeft:Float;
}

@:structAccess extern class Clay_BorderWidth {
    var left:Float;
    var top:Float;
    var right:Float;
    var bottom:Float;
    var outside:Float;
}

@:structAccess extern class Clay_Arena {
    var nextAllocation:cpp.UIntPtr;
    var capacity:cpp.SizeT;
    var memory:cpp.RawPointer<cpp.UInt8>;
}

@:structAccess extern class Clay_String {
    var isStaticallyAllocated:Bool;
    var length:Int;
    var chars:cpp.ConstPointer<cpp.Char>;
}

@:structAccess extern class Clay_StringSlice {
    var length:Int;
    var chars:cpp.ConstPointer<cpp.Char>;
    var baseChars:cpp.ConstPointer<cpp.Char>;
}

@:structAccess extern class Clay_ElementId {
    var id:cpp.UInt;
    var offset:cpp.UInt;
    var baseId:cpp.UInt;
    var stringId:Clay_String;
}

@:structAccess extern class Clay_CharArray {
    var capacity:Int;
    var length:Int;
    var internalArray:cpp.Pointer<cpp.Char>;
}

@:structAccess extern class Clay_ElementIdArray {
    var length:Int;
    var internalArray:cpp.Pointer<Clay_ElementId>;
}

@:structAccess extern class Clay_ErrorData {
    var errorType:Int;
    var errorText:Clay_String;
    var userData:cpp.RawPointer<Void>;
}

@:structAccess extern class Clay_ErrorHandler {
    var errorHandlerFunction:cpp.Callable<Clay_ErrorData->Void>;
    var userData:cpp.RawPointer<Void>;
}

@:structAccess extern class Clay_TextElementConfig {
    var userData:cpp.RawPointer<Void>;
    var textColor:Clay_Color;
    var fontId:cpp.UInt16;
    var fontSize:cpp.UInt16;
    var letterSpacing:cpp.UInt16;
    var lineHeight:cpp.UInt16;
    var wrapMode:Int;
    var textAlignment:Int;
}

@:structAccess extern class Clay_BoundingBox {
    var x:Float;
    var y:Float;
    var width:Float;
    var height:Float;
}

@:structAccess extern class Clay_RenderCommandArray {
    var capacity:Int;
    var length:Int;
    var internalArray:cpp.Pointer<Clay_RenderCommand>;
}

@:structAccess extern class Clay_RenderCommand {
    var boundingBox:Clay_BoundingBox;
    var renderData:Clay_RenderData;
    var userData:cpp.RawPointer<Void>;
    var id:cpp.UInt;
    var zIndex:Int;
    var commandType:Int;
}

// Placeholder for union
@:structAccess extern class Clay_RenderData {}

// Additional structs from clay.h
@:structAccess extern class Clay_CornerRadius {
    var topLeft:Float;
    var topRight:Float;
    var bottomRight:Float;
    var bottomLeft:Float;
}

@:structAccess extern class Clay_BorderWidth {
    var left:Float;
    var top:Float;
    var right:Float;
    var bottom:Float;
    var outside:Float;
}

// Enums (as abstracts for type safety)
@:enum abstract ClayTextWrapMode(Int) {
    var NONE = 0;
    var WORD = 1;
    var CHAR = 2;
}

@:enum abstract ClayTextAlignment(Int) {
    var LEFT = 0;
    var CENTER = 1;
    var RIGHT = 2;
}

@:enum abstract ClaySizingType(Int) {
    var FIT = 0;
    var GROW = 1;
    var FIXED = 2;
    var PERCENT = 3;
}

@:enum abstract ClayElementConfigType(Int) {
    var NONE = 0;
    var BORDER = 1;
    var FLOATING = 2;
    var CLIP = 3;
    var ASPECT = 4;
    var IMAGE = 5;
    var TEXT = 6;
    var CUSTOM = 7;
    var SHARED = 8;
}

// Utility types
@:structAccess extern class Clay_PointerData {
    var x:Float;
    var y:Float;
    var pointerDown:Bool;
}

@:structAccess extern class Clay_LayoutConfig {
    // Add fields as needed for your use case
}

@:structAccess extern class Clay_Context {
    var maxElementCount:Int;
    var maxMeasureTextCacheWordCount:Int;
    var warningsEnabled:Bool;
    // ...add more fields as needed for your use case...
}

@:structAccess extern class Clay_LayoutElement {
    var id:UInt;
    var dimensions:Clay_Dimensions;
    // ...add more fields as needed for your use case...
}

@:structAccess extern class Clay_LayoutElementArray {
    var capacity:Int;
    var length:Int;
    var internalArray:cpp.Pointer<Clay_LayoutElement>;
}

@:structAccess extern class Clay_ElementDeclaration {
    var id:Clay_ElementId;
    var backgroundColor:Clay_Color;
    // ...add more fields as needed for your use case...
}

@:structAccess extern class Clay_SharedElementConfig {
    var backgroundColor:Clay_Color;
    var cornerRadius:Clay_CornerRadius;
    var userData:cpp.RawPointer<Void>;
}

@:structAccess extern class Clay_BorderElementConfig {
    var borderWidth:Clay_BorderWidth;
    var borderColor:Clay_Color;
    var userData:cpp.RawPointer<Void>;
}

