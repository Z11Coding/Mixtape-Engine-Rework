package yutautil.crypto;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.crypto.Base64;

class CodeOb {
    public static function encode(input:String):Expr {
        // Step 1: Generate metadata from the input string
        var metadata = {
            length: input.length,
            checksum: input.split('').map(function(c) return c.charCodeAt(0)).reduce(function(a, b) return a + b, 0),
            reversed: input.split('').reverse().join(''),
            uniqueChars: input.split('').toSet().toArray().join('')
        };

        // Step 2: Apply multiple transformations to the input string
        var transformed = input;
        transformed = transformed.split('').map(function(c) return String.fromCharCode(c.charCodeAt(0) + 5)).join('');
        transformed = transformed.split('').reverse().join('');
        transformed = Base64.encode(haxe.io.Bytes.ofString(transformed));
        transformed = transformed.split('').map(function(c) return String.fromCharCode(c.charCodeAt(0) ^ 42)).join('');
        transformed = Base64.encode(haxe.io.Bytes.ofString(transformed));

        // Step 3: Create a decode expression
        var decodeExpr = macro CodeOb.decode($v{transformed}, $v{metadata});

        // Step 4: Trace the expression for replacement
        trace("Replace in-code with this expression to prevent this section from being accessible without proper decoding: \n" 
            + haxe.macro.Tools.exprToString(decodeExpr) 
            + "\n\nLine: " + Context.currentPos());

        return decodeExpr;
    }

    public static function decode(encoded:String, metadata:Dynamic):String {
        // Reverse the transformations to decode the string
        var decoded = Base64.decode(encoded);
        decoded = decoded.split('').map(function(c) return String.fromCharCode(c.charCodeAt(0) ^ 42)).join('');
        decoded = Base64.decode(decoded);
        decoded = decoded.split('').reverse().join('');
        decoded = decoded.split('').map(function(c) return String.fromCharCode(c.charCodeAt(0) - 5)).join('');

        // Validate metadata
        if (decoded.length != metadata.length) {
            throw "Decoded string length mismatch!";
        }
        if (decoded.split('').map(function(c) return c.charCodeAt(0)).reduce(function(a, b) return a + b, 0) != metadata.checksum) {
            throw "Decoded string checksum mismatch!";
        }
        if (decoded.split('').reverse().join('') != metadata.reversed) {
            throw "Decoded string reversed mismatch!";
        }
        if (decoded.split('').toSet().toArray().join('') != metadata.uniqueChars) {
            throw "Decoded string unique characters mismatch!";
        }

        return decoded;
    }
}
