package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;

using StringTools;

class TypeResolver {
    public static function build():Array<Field> {
        var pos = Context.currentPos();
        var fields = Context.getBuildFields();
        var typeName = Context.getLocalClass().get().name;
        var typePath = Context.getLocalClass().get().pack.join(".") + "." + typeName;

        // Example: Try to resolve a type by name
        function resolveType(name:String):ComplexType {
            try {
                var t = Context.resolveType({ name: name, pack: [] }, pos);
                return TypeTools.toComplexType(t);
            } catch (e:Dynamic) {
                // Try to find a close match
                var allTypes = Context.getTypes();
                var bestMatch:String = null;
                var bestScore = 0.0;
                for (t in allTypes) {
                    var tName = t.toString();
                    var score = similarity(name, tName);
                    if (score > bestScore) {
                        bestScore = score;
                        bestMatch = tName;
                    }
                }
                if (bestScore > 0.7) { // 70% similarity threshold
                    Context.warning('Type "$name" not found. Using closest match: $bestMatch', pos);
                    return TPath({ name: bestMatch, pack: [] });
                } else {
                    Context.warning('Type "$name" not found. Creating fake type.', pos);
                    return TPath({ name: name + "_Fake", pack: [] });
                }
            }
        }

        // Simple similarity function (Jaccard index on character sets)
        function similarity(a:String, b:String):Float {
            var setA = [for (c in a.toLowerCase()) c].toSet();
            var setB = [for (c in b.toLowerCase()) c].toSet();
            var intersection = setA.intersection(setB).length;
            var union = setA.union(setB).length;
            return union == 0 ? 0 : intersection / union;
        }

        // Example usage: resolve a type called "MyType"
        // var myType = resolveType("MyType");

        return fields;
    }
}
#end