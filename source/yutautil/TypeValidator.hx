package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

class TypeValidator {
    public static macro function check():ComplexType {
        // Trace the local type at compile time
        trace("Huh, this is a macro function that checks the local type at compile time.");
        trace("TypeValidator initialized at: " + Context.getLocalType());
        return Context.getExpr(); // Return null as this is just a check
    }
        }
