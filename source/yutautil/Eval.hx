package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.crypto.Base64;

class Eval {
    /**
     * Simple XOR encryption with a key.
     */
    static function xorEncrypt(input:String, key:String):String {
        var output = new StringBuf();
        for (i in 0...input.length) {
            var c = input.charCodeAt(i);
            var k = key.charCodeAt(i % key.length);
            output.addChar(c ^ k);
        }
        return output.toString();
    }

    static function xorDecrypt(input:String, key:String):String {
        // XOR is symmetric
        return xorEncrypt(input, key);
    }

    /**
     * Macro that converts an expression into a string, encrypts it (XOR + base64),
     * and emits a warning recommending to replace it with the decryption macro.
     */
    public static macro function encryptAndEval(expr:Expr):Expr {
        var key = "mySecretKey"; // You can change this key
        var exprStr = ExprTools.toString(expr);

        // XOR encrypt then base64 encode
        var encrypted = Base64.encode(haxe.io.Bytes.ofString(xorEncrypt(exprStr, key)));

        var decryptCode = 'yutautil.Eval.decryptAndEval("${encrypted}")';

        Context.warning('Replace this macro call with: ' + decryptCode, Context.currentPos());

        return expr;
    }

    /**
     * Macro that decrypts the encrypted string and recreates the original expression at compile time.
     */
    public static macro function decryptAndEval(encrypted:String):Expr {
        var key = "mySecretKey"; // Must match the key used in encryptAndEval
        var decoded = Base64.decode(encrypted).toString();
        var exprStr = xorDecrypt(decoded, key);
        var parsedExpr = Context.parse(exprStr, Context.currentPos());
        return parsedExpr;
    }
}
