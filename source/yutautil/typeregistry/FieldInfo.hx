package yutautil.typeregistry;

#if macro
import haxe.macro.Position;
#end

typedef FieldInfo = {
    name:String,
    type:String,
    isPublic:Bool,
    isStatic:Bool,
    doc:String,
    pos:#if macro Position #else Dynamic #end,
    optional:Bool
}
