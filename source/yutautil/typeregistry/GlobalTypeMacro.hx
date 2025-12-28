package yutautil.typeregistry;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * Global metadata application macro
 * Automatically applies @:build metadata to all classes for type collection
 */
class GlobalTypeMacro {
    static var tracesEnabled:Bool = #if verbose true #else false #end;

    /**
     * Apply type collection build macro to all classes
     * This is called from Project.xml using --macro
     */
    public static function applyGlobalTypeCollection():Void {
        if (tracesEnabled) trace("GlobalTypeMacro: Starting global type collection application");

        // Handle type not found events with proper return type
        Context.onTypeNotFound(function(typeName:String):haxe.macro.TypeDefinition {
            if (tracesEnabled) trace('GlobalTypeMacro: Type not found: $typeName');
            return null; // Let normal type resolution handle this
        });

        try {
            // Use Compiler.addGlobalMetadata to apply our build macro to all classes
            Compiler.addGlobalMetadata(
                "", // Apply to all types
                "@:autoBuild(yutautil.typeregistry.TypeCollectionMacro.collectTypeInfo())",
                true // Recursive
            );

            if (tracesEnabled) trace("GlobalTypeMacro: Applied type collection build macro globally");

        } catch (e:Dynamic) {
            if (tracesEnabled) trace('GlobalTypeMacro: Error applying global metadata: $e');
        }
    }

    /**
     * Alternative approach - apply only to specific packages
     */
    public static function applyToPackages():Void {
        if (tracesEnabled) trace("GlobalTypeMacro: Starting package-specific type collection");

        var packages = [
            "source",
            "states",
            "objects",
            "backend",
            "substates",
            "yutautil",
            "psychlua",
            "archipelago",
            "games",
            "managers"
        ];

        for (pkg in packages) {
            try {
                Compiler.addGlobalMetadata(
                    pkg,
                    "@:build(yutautil.typeregistry.TypeCollectionMacro.collectTypeInfo())",
                    true // Recursive
                );
                if (tracesEnabled) trace('GlobalTypeMacro: Applied type collection to package: $pkg');
            } catch (e:Dynamic) {
                if (tracesEnabled) trace('GlobalTypeMacro: Error applying to package $pkg: $e');
            }
        }
    }

    /**
     * Selective application - only to user-defined classes, not external libs
     */
    public static function applySelective():Void {
        if (tracesEnabled) trace("GlobalTypeMacro: Starting selective type collection");

        try {
            // Apply to main game packages only - EXCLUDE external libraries
            var gamePackages = [
                "states",
                "objects",
                "backend",
                "substates",
                "yutautil",
                "psychlua",
                "archipelago",
                "games",
                "managers",
                "cutscenes",
                "debug",
                "mechanics",
                "metadata",
                "options",
                "shaders",
                "stages",
                "trolllua",
                "examples"
            ];

            var appliedCount = 0;
            for (pkg in gamePackages) {
                try {
                    Compiler.addGlobalMetadata(
                        pkg,
                        "@:build(yutautil.typeregistry.TypeCollectionMacro.collectTypeInfo())",
                        true // Recursive
                    );
                    appliedCount++;
                    if (tracesEnabled) trace('GlobalTypeMacro: Applied to package: $pkg');
                } catch (e:Dynamic) {
                    if (tracesEnabled) trace('GlobalTypeMacro: Error applying to package $pkg: $e');
                }
            }

            if (tracesEnabled) trace('GlobalTypeMacro: Applied selective type collection to $appliedCount packages');

        } catch (e:Dynamic) {
            if (tracesEnabled) trace('GlobalTypeMacro: Error in selective application: $e');
        }
    }

    /**
     * Minimal application - just core engine packages
     */
    public static function applyMinimal():Void {
        if (tracesEnabled) trace("GlobalTypeMacro: Starting minimal type collection");

        try {
            // Only apply to core user packages - completely avoid external libraries
            var corePackages = [
                "states",
                "objects",
                "backend",
                "yutautil"
            ];

            var appliedCount = 0;
            for (pkg in corePackages) {
                try {
                    Compiler.addGlobalMetadata(
                        pkg,
                        "@:build(yutautil.typeregistry.TypeCollectionMacro.collectTypeInfo())",
                        true
                    );
                    appliedCount++;
                    if (tracesEnabled) trace('GlobalTypeMacro: Applied to core package: $pkg');
                } catch (e:Dynamic) {
                    if (tracesEnabled) trace('GlobalTypeMacro: Error applying to core package $pkg: $e');
                }
            }

            if (tracesEnabled) trace('GlobalTypeMacro: Applied minimal type collection to $appliedCount core packages');

        } catch (e:Dynamic) {
            if (tracesEnabled) trace('GlobalTypeMacro: Error in minimal application: $e');
        }
    }

    /**
     * Very safe application - only essential packages to avoid any library conflicts
     */
    public static function applySafe():Void {
        if (tracesEnabled) trace("GlobalTypeMacro: Starting safe type collection");

        try {
            // Only apply to the most essential user packages
            var safePackages = [
                "states",
                "backend"
            ];

            var appliedCount = 0;
            for (pkg in safePackages) {
                try {
                    Compiler.addGlobalMetadata(
                        pkg,
                        "@:build(yutautil.typeregistry.TypeCollectionMacro.collectTypeInfo())",
                        true
                    );
                    appliedCount++;
                    if (tracesEnabled) trace('GlobalTypeMacro: Applied to safe package: $pkg');
                } catch (e:Dynamic) {
                    if (tracesEnabled) trace('GlobalTypeMacro: Error applying to safe package $pkg: $e');
                }
            }

            if (tracesEnabled) trace('GlobalTypeMacro: Applied safe type collection to $appliedCount packages');

        } catch (e:Dynamic) {
            if (tracesEnabled) trace('GlobalTypeMacro: Error in safe application: $e');
        }
    }
}
