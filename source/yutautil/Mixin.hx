package yutautil;
import haxe.macro.Context;
import haxe.macro.Expr;


class Mixin {
    public static function mixin<T>(target: T, source: T): T {
        for (field in Reflect.fields(source)) {
            Reflect.setField(target, field, Reflect.field(source, field));
        }
        return target;
    }
}


class Inject {
    /**
     * Annotation for code injection.
     * Usage: @InjectInto(SomeClass)
     * W.I.P Java-like Mixins.
     */
    macro public static function buildInject():Array<Field> {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        var meta = cls.meta.extract(":injectInto");
        if (meta == null || meta.length == 0) return fields;

        for (m in meta) {
            var targetType = m.params[0];
            for (field in fields) {
                if (field.meta != null && field.meta.has(":inject")) {
                    // Find the target class and inject this field/method
                    var target = Context.resolveType(targetType, Context.currentPos());
                }
            }
        }
        return fields;
    }
}

/**
 * Usage:
 * @injectInto(TargetClass)
 * class MyMixin {
 *   @inject
 *   public function injectedMethod() {
 *     // code to inject
 *   }
 * }
 */
#end