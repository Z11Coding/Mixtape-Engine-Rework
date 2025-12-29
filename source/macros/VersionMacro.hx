package macros;

#if macro
import Date;
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;

using StringTools;
#end

/**
 * Semantic Version abstract for proper version comparison
 */
abstract SemanticVersion(String) from String to String {
    public function new(version:String) {
        this = version;
    }

    public var major(get, never):Int;
    public var minor(get, never):Int;
    public var patch(get, never):Int;
    public var beta(get, never):String;

    function get_major():Int {
        var parts = getParts();
        return parts.major;
    }

    function get_minor():Int {
        var parts = getParts();
        return parts.minor;
    }

    function get_patch():Int {
        var parts = getParts();
        return parts.patch;
    }

    function get_beta():String {
        var parts = getParts();
        return parts.beta;
    }

    private function getParts():{major:Int, minor:Int, patch:Int, beta:String} {
        var version:String = this;
        var beta = "";

        // Split beta version if exists
        if (version.indexOf(":") != -1) {
            var split = version.split(":");
            version = split[0];
            beta = split[1];
        }

        var parts = version.split(".");
        var major = parts.length > 0 ? Std.parseInt(parts[0]) ?? 0 : 0;
        var minor = parts.length > 1 ? Std.parseInt(parts[1]) ?? 0 : 0;
        var patch = parts.length > 2 ? Std.parseInt(parts[2]) ?? 0 : 0;

        return {major: major, minor: minor, patch: patch, beta: beta};
    }

    public function compare(other:SemanticVersion):Int {
        var thisParts = getParts();
        var otherParts = (cast other : SemanticVersion).getParts();

        // Compare major
        if (thisParts.major != otherParts.major)
            return thisParts.major - otherParts.major;

        // Compare minor
        if (thisParts.minor != otherParts.minor)
            return thisParts.minor - otherParts.minor;

        // Compare patch
        if (thisParts.patch != otherParts.patch)
            return thisParts.patch - otherParts.patch;

        // Compare beta (empty beta > non-empty beta, lexicographical otherwise)
        if (thisParts.beta == "" && otherParts.beta != "") return 1;
        if (thisParts.beta != "" && otherParts.beta == "") return -1;
        if (thisParts.beta == "" && otherParts.beta == "") return 0;

        return thisParts.beta < otherParts.beta ? -1 : (thisParts.beta > otherParts.beta ? 1 : 0);
    }

    @:op(A > B) public function gt(other:SemanticVersion):Bool return compare(other) > 0;
    @:op(A >= B) public function gte(other:SemanticVersion):Bool return compare(other) >= 0;
    @:op(A < B) public function lt(other:SemanticVersion):Bool return compare(other) < 0;
    @:op(A <= B) public function lte(other:SemanticVersion):Bool return compare(other) <= 0;
    @:op(A == B) public function eq(other:SemanticVersion):Bool return compare(other) == 0;
    @:op(A != B) public function neq(other:SemanticVersion):Bool return compare(other) != 0;

    public function toString():String {
        return this;
    }
}

class VersionMacro {
    #if macro
    private static var BUILD_FILE = "build.txt";
    private static var VERSION_FILE = "gitVersion.txt";

    public static function build():Array<Field> {
        var fields = Context.getBuildFields();

        // Get version info
        var versionInfo = getVersionInfo();
        var buildInfo = getBuildInfo(versionInfo.version + (versionInfo.beta != "" ? ":" + versionInfo.beta : ""));

        // Add version constants
        fields.push({
            name: "ENGINE_VERSION",
            doc: "Engine version string",
            meta: [],
            access: [APublic, AStatic, AInline],
            kind: FVar(macro : String, macro $v{versionInfo.version}),
            pos: Context.currentPos()
        });

        fields.push({
            name: "ENGINE_BETA",
            doc: "Engine beta version string",
            meta: [],
            access: [APublic, AStatic, AInline],
            kind: FVar(macro : String, macro $v{versionInfo.beta}),
            pos: Context.currentPos()
        });

        fields.push({
            name: "BUILD_NUMBER",
            doc: "Build number for this compilation",
            meta: [],
            access: [APublic, AStatic, AInline],
            kind: FVar(macro : Int, macro $v{buildInfo.buildNumber}),
            pos: Context.currentPos()
        });

        fields.push({
            name: "BUILD_DATE",
            doc: "Build date as timestamp",
            meta: [],
            access: [APublic, AStatic, AInline],
            kind: FVar(macro : String, macro $v{buildInfo.buildDate}),
            pos: Context.currentPos()
        });

        fields.push({
            name: "SEMANTIC_VERSION",
            doc: "Semantic version for comparison",
            meta: [],
            access: [APublic, AStatic, AInline],
            kind: FVar(macro : macros.VersionMacro.SemanticVersion, macro $v{versionInfo.version + (versionInfo.beta != "" ? ":" + versionInfo.beta : "")}),
            pos: Context.currentPos()
        });

        fields.push({
            name: "getVersionString",
            doc: "Get formatted version string with build number",
            meta: [],
            access: [APublic, AStatic],
            kind: FFun({
                args: [{name: "includeBuild", type: macro : Bool, value: macro true}],
                ret: macro : String,
                expr: macro {
                    var base = ENGINE_VERSION + (ENGINE_BETA != "" ? ":" + ENGINE_BETA : "");
                    return includeBuild ? base + " [Build " + BUILD_NUMBER + "]" : base;
                }
            }),
            pos: Context.currentPos()
        });

        fields.push({
            name: "getFullVersionInfo",
            doc: "Get full version information including build date",
            meta: [],
            access: [APublic, AStatic],
            kind: FFun({
                args: [],
                ret: macro : String,
                expr: macro {
                    return getVersionString(true) + " (" + BUILD_DATE + ")";
                }
            }),
            pos: Context.currentPos()
        });

        fields.push({
            name: "compareVersion",
            doc: "Compare current version with another version string",
            meta: [],
            access: [APublic, AStatic],
            kind: FFun({
                args: [{name: "otherVersion", type: macro : String}],
                ret: macro : Int,
                expr: macro {
                    return SEMANTIC_VERSION.compare(otherVersion);
                }
            }),
            pos: Context.currentPos()
        });

        return fields;
    }

    private static function getVersionInfo():{version:String, beta:String} {
        var version = "0.0.0";
        var beta = "";

        try {
            // Try to read gitVersion.txt first
            if (FileSystem.exists(VERSION_FILE)) {
                var content = File.getContent(VERSION_FILE).trim();
                if (content.indexOf(":") != -1) {
                    var parts = content.split(":");
                    version = parts[0];
                    beta = parts[1];
                } else {
                    version = content;
                }
            } else {
                // Fallback to Project.xml version
                if (FileSystem.exists("Project.xml")) {
                    var projectXml = File.getContent("Project.xml");
                    var versionRegex = ~/version="([^"]+)"/;
                    if (versionRegex.match(projectXml)) {
                        version = versionRegex.matched(1);
                    }
                }
            }
        } catch (e:Dynamic) {
            Context.warning("Failed to read version info: " + e, Context.currentPos());
        }

        return {version: version, beta: beta};
    }

    private static function getBuildInfo(currentVersion:String):{buildNumber:Int, buildDate:String} {
        var buildNumber = 1;
        var buildDate = DateTools.format(Date.now(), "%Y-%m-%d %H:%M:%S");
        var lastVersion = "";
        var shouldResetBuild = false;

        try {
            if (FileSystem.exists(BUILD_FILE)) {
                var content = File.getContent(BUILD_FILE).trim();
                var lines:Array<String> = content.split("\n");

                // Parse existing build info
                for (line in lines) {
                    if (line.indexOf("BUILD_NUMBER=") == 0) {
                        var buildStr = line.split("=")[1];
                        var parsedBuild = Std.parseInt(buildStr);
                        if (parsedBuild != null) buildNumber = parsedBuild;
                    } else if (line.indexOf("LAST_VERSION=") == 0) {
                        lastVersion = line.split("=")[1];
                    }
                }

                // Check version comparison
                if (lastVersion != "") {
                    var lastSemVer = new SemanticVersion(lastVersion);
                    var currentSemVer = new SemanticVersion(currentVersion);
                    var comparison = currentSemVer.compare(lastSemVer);

                    if (comparison < 0) {
                        Context.warning('Version downgrade detected: ${currentVersion} < ${lastVersion}. This may cause issues!', Context.currentPos());
                    } else if (comparison > 0) {
                        // Version upgrade - reset build number
                        buildNumber = 1;
                        shouldResetBuild = true;
                        Context.info('Version upgrade detected: ${lastVersion} -> ${currentVersion}. Build number reset to 1.', Context.currentPos());
                    } else {
                        // Same version - increment build
                        buildNumber++;
                    }
                } else {
                    // No previous version found - start fresh
                    buildNumber = 1;
                }
            } else {
                // No build file exists - start fresh
                buildNumber = 1;
            }

            // Write updated build info
            var buildContent = "BUILD_NUMBER=" + buildNumber + "\n";
            buildContent += "BUILD_DATE=" + buildDate + "\n";
            buildContent += "LAST_COMPILE=" + Date.now().getTime() + "\n";
            buildContent += "LAST_VERSION=" + currentVersion + "\n";

            if (shouldResetBuild) {
                buildContent += "# Build number reset due to version upgrade\n";
            }

            File.saveContent(BUILD_FILE, buildContent);

        } catch (e:Dynamic) {
            Context.warning("Failed to update build info: " + e, Context.currentPos());
        }

        return {buildNumber: buildNumber, buildDate: buildDate};
    }
    #end
}
