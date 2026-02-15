package yutautil.typeregistry;

#if macro
import haxe.macro.Position;
#end

typedef ConstructorInfo = {
    args:Array<{name:String, type:String, opt:Bool}>,
    doc:String,
    pos:#if macro Position #else Dynamic #end
}
