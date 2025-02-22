import js.Node;
import js.Browser;
import haxe.macro.Context;
import haxe.macro.Expr;

class Translate {
// Highly experimental code
    // Regular function to be called at runtime for translating strings
    public static function translate(s:String):String {
        var curlCommand:String = "curl --request GET " +
            "--url 'https://microsoft-translator-text.p.rapidapi.com/languages?api-version=3.0' " +
            "--header 'x-rapidapi-host: microsoft-translator-text.p.rapidapi.com' " +
            "--header 'x-rapidapi-key: Sign Up for Key'";
        Sys.command(curlCommand);
        return s;
    }

    // Macro to process all string literals
    public static macro function processStrings(e:Expr):Expr {
        return process(e);
    }

    // Recursive function to process the AST
    static function process(e:Expr):Expr {
        switch e {
            case EConst(CString(s)):
                // Replace string literal with a call to the translate function
                return macro Translate.translate($v{s});
            case ECall(func, args):
                // Process function arguments
                return macro $func($a{[for (arg in args) process(arg)]});
            case EArrayDecl(items):
                // Process array items
                return macro [$a{[for (item in items) process(item)]}];
            case EObjectDecl(fields):
                // Process object fields
                return macro {$a{[for (field in fields) { field.name => process(field.expr) }] }};
            case _:
                // Recursively process other expressions
                return Context.mapExpr(process, e);
        }
    }
}