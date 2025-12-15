package yutautil.typeregistry;

/**
 * Advanced abstract type recognition system
 * Uses runtime value analysis to identify possible abstract types
 */
class AbstractRecognizer {
    private static var registry:RuntimeRegistry;

    static function __init__() {
        registry = RuntimeRegistry.get();
    }

    /**
     * Attempt to recognize abstract types from a value using advanced heuristics
     */
    public static function recognize(value:Dynamic):Array<AbstractCandidate> {
        registry.initialize();

        var candidates = [];
        var abstracts = registry.getAllAbstracts();

        for (abstractName in abstracts) {
            var abstractInfo = registry.getAbstractInfo(abstractName);
            var candidate = analyzeAbstractCandidate(value, abstractInfo);

            if (candidate != null && candidate.confidence > 0) {
                candidates.push(candidate);
            }
        }

        // Sort by confidence
        candidates.sort(function(a, b) {
            return Std.int((b.confidence - a.confidence) * 100);
        });

        return candidates;
    }

    /**
     * Get the most likely abstract type for a value
     */
    public static function getBestMatch(value:Dynamic):AbstractCandidate {
        var candidates = recognize(value);
        return candidates.length > 0 ? candidates[0] : null;
    }

    /**
     * Check if a value can be recognized as a specific abstract type
     */
    public static function canRecognizeAs(value:Dynamic, abstractTypeName:String):AbstractCandidate {
        registry.initialize();

        var abstractInfo = registry.getAbstractInfo(abstractTypeName);
        if (abstractInfo == null) return null;

        return analyzeAbstractCandidate(value, abstractInfo);
    }

    private static function analyzeAbstractCandidate(value:Dynamic, abstractInfo:AbstractInfo):AbstractCandidate {
        if (abstractInfo == null) return null;

        var confidence = 0.0;
        var reasons = [];
        var warnings = [];

        // Check underlying type compatibility
        if (abstractInfo.couldBeType(value)) {
            confidence += 0.6;
            reasons.push("Value type matches underlying type: " + abstractInfo.getUnderlyingType());
        }

        // Analyze value patterns specific to common abstract types
        confidence += analyzeValuePatterns(value, abstractInfo, reasons, warnings);

        // Check for cast compatibility
        confidence += analyzeCastCompatibility(value, abstractInfo, reasons);

        // Check naming conventions and patterns
        confidence += analyzeNamingPatterns(value, abstractInfo, reasons);

        if (confidence > 0) {
            return new AbstractCandidate(
                abstractInfo,
                value,
                confidence,
                reasons,
                warnings
            );
        }

        return null;
    }

    private static function analyzeValuePatterns(value:Dynamic, abstractInfo:AbstractInfo, reasons:Array<String>, warnings:Array<String>):Float {
        var boost = 0.0;
        var underlyingType = abstractInfo.getUnderlyingType().toLowerCase();

        // Special pattern analysis based on abstract name and type
        var abstractName = abstractInfo.name.toLowerCase();

        // Numeric abstracts with special ranges or properties
        if (underlyingType == "int" || underlyingType == "float") {
            if (abstractName.indexOf("positive") >= 0 && Std.parseFloat(Std.string(value)) > 0) {
                boost += 0.2;
                reasons.push("Value is positive as expected for " + abstractName);
            }

            if (abstractName.indexOf("percent") >= 0) {
                var numVal = Std.parseFloat(Std.string(value));
                if (numVal >= 0 && numVal <= 100) {
                    boost += 0.3;
                    reasons.push("Value is in valid percentage range");
                } else if (numVal >= 0 && numVal <= 1) {
                    boost += 0.2;
                    reasons.push("Value might be normalized percentage");
                }
            }
        }

        // String abstracts with pattern matching
        if (underlyingType == "string") {
            var strVal = Std.string(value);

            if (abstractName.indexOf("path") >= 0 || abstractName.indexOf("url") >= 0) {
                if (strVal.indexOf("/") >= 0 || strVal.indexOf("\\") >= 0) {
                    boost += 0.2;
                    reasons.push("String contains path-like separators");
                }
            }

            if (abstractName.indexOf("id") >= 0 || abstractName.indexOf("uuid") >= 0) {
                if (strVal.length > 0 && ~/^[a-zA-Z0-9\-_]+$/.match(strVal)) {
                    boost += 0.1;
                    reasons.push("String matches ID pattern");
                }
            }
        }

        return Math.min(boost, 0.3); // Cap pattern boost at 0.3
    }

    private static function analyzeCastCompatibility(value:Dynamic, abstractInfo:AbstractInfo, reasons:Array<String>):Float {
        var boost = 0.0;

        // Check if we can conceptually cast from this value to any of the "from" types
        for (fromType in abstractInfo.fromCasts) {
            if (typeMatches(value, fromType)) {
                boost += 0.1;
                reasons.push("Value compatible with from-cast: " + fromType);
            }
        }

        return Math.min(boost, 0.2); // Cap cast boost at 0.2
    }

    private static function analyzeNamingPatterns(value:Dynamic, abstractInfo:AbstractInfo, reasons:Array<String>):Float {
        var boost = 0.0;

        // If the abstract is from the yutautil package (like Num), give slight boost for yutautil context
        if (abstractInfo.pack != null && abstractInfo.pack.length > 0 && abstractInfo.pack[0] == "yutautil") {
            boost += 0.05;
            reasons.push("Abstract from yutautil package");
        }

        return boost;
    }

    private static function typeMatches(value:Dynamic, typeName:String):Bool {
        var valueType = Type.typeof(value);

        return switch (typeName.toLowerCase()) {
            case "int" | "integer": Type.typeof(value).match(TInt);
            case "float" | "number": Type.typeof(value).match(TFloat) || Type.typeof(value).match(TInt);
            case "string": Type.typeof(value).match(TClass(String));
            case "bool" | "boolean": Type.typeof(value).match(TBool);
            case "array": Type.typeof(value).match(TClass(Array));
            case _: false;
        };
    }

    /**
     * Create a runtime cast attempt for an abstract type
     */
    public static function attemptCast(value:Dynamic, abstractTypeName:String):Dynamic {
        var candidate = canRecognizeAs(value, abstractTypeName);

        if (candidate != null && candidate.confidence > 0.5) {
            // For abstracts, we return the original value since the abstract wrapper is compile-time
            // But we could potentially create a wrapper object that remembers the abstract type
            return createAbstractWrapper(value, candidate.abstractInfo);
        }

        return null;
    }

    private static function createAbstractWrapper(value:Dynamic, abstractInfo:AbstractInfo):AbstractWrapper {
        return new AbstractWrapper(value, abstractInfo);
    }
}

/**
 * Represents a potential abstract type match
 */
class AbstractCandidate {
    public var abstractInfo(default, null):AbstractInfo;
    public var value(default, null):Dynamic;
    public var confidence(default, null):Float;
    public var reasons(default, null):Array<String>;
    public var warnings(default, null):Array<String>;

    public function new(abstractInfo:AbstractInfo, value:Dynamic, confidence:Float, reasons:Array<String>, warnings:Array<String>) {
        this.abstractInfo = abstractInfo;
        this.value = value;
        this.confidence = confidence;
        this.reasons = reasons != null ? reasons : [];
        this.warnings = warnings != null ? warnings : [];
    }

    public function getTypeName():String {
        return abstractInfo.getFullName();
    }

    public function toString():String {
        return '${getTypeName()} (${Math.round(confidence * 100)}% confidence)';
    }
}

/**
 * Runtime wrapper for abstract values that preserves type information
 */
class AbstractWrapper {
    public var value(default, null):Dynamic;
    public var abstractInfo(default, null):AbstractInfo;
    public var typeName(default, null):String;

    public function new(value:Dynamic, abstractInfo:AbstractInfo) {
        this.value = value;
        this.abstractInfo = abstractInfo;
        this.typeName = abstractInfo.getFullName();
    }

    public function getValue():Dynamic {
        return value;
    }

    public function getAbstractTypeName():String {
        return typeName;
    }

    public function canCastTo(targetTypeName:String):Bool {
        return abstractInfo.canCastTo(targetTypeName);
    }

    public function toString():String {
        return '${typeName}(${value})';
    }
}
