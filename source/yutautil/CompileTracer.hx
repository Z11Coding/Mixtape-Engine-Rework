import haxe.macro.Context;
import haxe.macro.Expr;

class CompileTracer {
	public static macro function traceCompileProcess():Array<Field> {
		var classes = Context.getAllModuleTypes(); // Get all types available in the current compilation context
		for (cls in classes) {
			switch cls {
				case TClassDecl(c):
					trace('Compiling class: ' + c.pack.join(".") + "." + c.name);
				case TEnumDecl(e):
					trace('Compiling enum: ' + e.pack.join(".") + "." + e.name);
				case TAbstract(a):
					trace('Compiling abstract: ' + a.pack.join(".") + "." + a.name);
				case TTypeDecl(t):
					trace('Compiling typedef: ' + t.pack.join(".") + "." + t.name);
				case _:
			}
		}
		return null; // This macro does not modify the AST, so it returns null
	}
}