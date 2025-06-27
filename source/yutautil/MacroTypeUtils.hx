package yutautil;

import haxe.macro.Expr;
import haxe.macro.Context;

// abstract Not<T>(Dynamic) {
//     public inline function new(value:Dynamic) {
//         this = value;
//     }

//     @:macro public static function ensureNotType(expr:Expr, typePath:String):Expr {
//         var expectedType = Context.resolveType(TPath({ pack: [], name: typePath, params: [] }), Context.currentPos());
//         var actualType = Context.typeof(expr);
//         if (Context.unify(actualType, expectedType)) {
//             Context.error('Value must NOT be of type $typePath', expr.pos);
//         }
//         return expr;
//     }

//     macro public static function make<T>(expr:Expr, typePath:String):Expr {
//         return macro @:pos(expr.pos) new Not(${ensureNotType(expr, typePath)});
//     }
// }

// abstract Code({
//     var run: Void -> Dynamic;
//     var exprString: String;
//     var file: String;
//     var min: Int;
//     var max: Int;
//     var kind: Dynamic;
// }) {
//     public function new(expr:Dynamic) {
//         if (expr == null) {
//             expr = macro null;
//         }
//         this = Code.make(macro expr);
//     }

//     public static macro function makeCodeVar(expr:Suggestion<Expr>):Expr {
//         var pos = expr.pos;
//         var posInfos = haxe.macro.Context.getPosInfos(pos);
//         var exprStr = new haxe.macro.Printer().printExpr(expr);
//         var file = posInfos.file;
//         var min = posInfos.min;
//         var max = posInfos.max;
//         var kind = expr.expr;
//         var customExpr = macro {
//             var _expr = $expr;
//             {
//                 run: function() return _expr,
//                 exprString: $v{exprStr},
//                 file: $v{file},
//                 min: $v{min},
//                 max: $v{max},
//                 kind: $v{kind}
//             };
//         };
//         return customExpr;
//     }
// }