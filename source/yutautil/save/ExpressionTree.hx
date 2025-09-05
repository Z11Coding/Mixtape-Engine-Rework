package yutautil.save;

/**
 * Expression tree representation for captured functions
 * This mirrors Haxe's Expr enum but simplified for serialization
 */
enum ExpressionTree {
    ENull;
    EConst(c:ConstantTree);
    EArray(e1:ExpressionTree, e2:ExpressionTree);
    EBinop(op:String, e1:ExpressionTree, e2:ExpressionTree);
    EField(e:ExpressionTree, field:String);
    EObjectDecl(fields:Array<{field:String, expr:ExpressionTree}>);
    EArrayDecl(values:Array<ExpressionTree>);
    ECall(e:ExpressionTree, params:Array<ExpressionTree>);
    ENew(name:String, pack:Array<String>, params:Array<ExpressionTree>);
    EUnop(op:String, postFix:Bool, e:ExpressionTree);
    EVars(vars:Array<{name:String, type:Null<String>, expr:ExpressionTree}>);
    EFunction(kind:String, func:FunctionTree);
    EBlock(exprs:Array<ExpressionTree>);
    EFor(it:ExpressionTree, expr:ExpressionTree);
    EIf(econd:ExpressionTree, eif:ExpressionTree, eelse:ExpressionTree);
    EWhile(econd:ExpressionTree, e:ExpressionTree, normalWhile:Bool);
    ESwitch(e:ExpressionTree, cases:Array<CaseTree>, edef:ExpressionTree);
    ETry(e:ExpressionTree, catches:Array<CatchTree>);
    EReturn(e:ExpressionTree);
    EBreak;
    EContinue;
    EThrow(e:ExpressionTree);
    ECast(e:ExpressionTree, t:Null<String>);
    ETernary(econd:ExpressionTree, eif:ExpressionTree, eelse:ExpressionTree);
    ECheckType(e:ExpressionTree, t:String);
    EIs(e:ExpressionTree, t:String);
}

enum ConstantTree {
    CInt(v:String);
    CFloat(f:String);
    CString(s:String);
    CIdent(s:String);
    CRegexp(r:String, opt:String);
}

typedef FunctionTree = {
    var args:Array<{name:String, type:String, opt:Bool, value:Null<String>}>;
    var ret:String;
    var expr:ExpressionTree;
}

typedef CaseTree = {
    var values:Array<ExpressionTree>;
    var guard:ExpressionTree;
    var expr:ExpressionTree;
}

typedef CatchTree = {
    var name:String;
    var type:Null<String>;
    var expr:ExpressionTree;
}
