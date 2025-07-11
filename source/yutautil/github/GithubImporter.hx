package yutautil.github;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.Http;
#end

#if !macro
import hscript.Parser;
import hscript.Interp;
import haxe.Http;
import haxe.Timer;
#end

class GithubImporter {
    private static var verbose:Bool = true;
    
    /**
     * Enable or disable verbose tracing.
     * @param enabled Whether to enable verbose tracing.
     */
    public static function setVerbose(enabled:Bool):Void {
        verbose = enabled;
    }
    
    private static function trace(message:String):Void {
        if (verbose) {
            #if macro
            Context.warning('[GithubImporter] $message', Context.currentPos());
            #else
            trace('[GithubImporter] $message');
            #end
        }
    }
    /**
     * Imports an entire GitHub repository at macro time.
     * @param repoUrl The URL of the GitHub repository.
     */
    #if macro
    public static function importRepo(repoUrl:String):Void {
        // Only supports raw.githubusercontent.com URLs for simplicity
        Context.warning('importRepo is not fully implemented yet: $repoUrl', Context.currentPos());
        // You could list files via GitHub API and import each, but that's complex.
    }

    /**
     * Imports a single file from a GitHub repository at macro time.
     * @param fileUrl The URL of the file in the GitHub repository (raw.githubusercontent.com).
     */
    public static function importFile(fileUrl:String):Void {
        trace('Starting macro import of: $fileUrl');
        try {
            var http = new Http(fileUrl);
            var content = "";
            var completed = false;
            var error:String = null;
            
            http.onData = function(data) {
                trace('Successfully fetched file content (${data.length} characters)');
                content = data;
                completed = true;
            };
            
            http.onError = function(e) {
                trace('HTTP error occurred: $e');
                error = 'Failed to fetch file: $e';
                completed = true;
            };
            
            http.request(true);
            
            // Wait for completion (macro context allows blocking)
            var timeout = 0;
            while (!completed && timeout < 30000) { // 30 second timeout
                Sys.sleep(0.001); // 1ms sleep
                timeout++;
            }
            
            if (!completed) {
                throw 'Request timeout after 30 seconds';
            }
            
            if (error != null) {
                throw error;
            }
            
            if (content.length == 0) {
                throw 'Received empty content';
            }
            
            trace('Parsing and injecting file content into compilation');
            // Inject the file content as a macro
            // Parse the fetched content as a type definition
            var parsedType = Context.parseType(content, Context.currentPos());
            // Use the file name (without extension) as the module name
            var moduleName = fileUrl.split("/").pop().split(".")[0];
            // Define the type in the current compilation context
            Context.defineType({
                name: moduleName,
                pack: Context.getLocalModule().split(".").slice(0, -1),
                pos: Context.currentPos(),
                kind: TDClass(),
                fields: [],
                meta: [],
                params: [],
                isExtern: false
            });
            // Now inject the parsed type
            Context.defineType(parsedType);
            trace('Successfully imported file at macro time');
            
        } catch (e:Dynamic) {
            var errorMsg = 'importFile failed: $e';
            trace(errorMsg);
            Context.error(errorMsg, Context.currentPos());
        }
    }
    #end

    /**
     * Imports and executes a Haxe file from GitHub at runtime using HScript.
     * @param fileUrl The URL of the raw Haxe file.
     * @param ?vars Optional variables to inject into the script context.
     * @return The result of the script execution.
     */
    #if !macro
    public static function importFileRuntime(fileUrl:String, ?vars:Map<String, Dynamic>):Dynamic {
        var http = new Http(fileUrl);
        var result:Dynamic = null;
        http.onData = function(data) {
            var parser = new Parser();
            var expr = parser.parseString(data);
            var interp = new Interp();
            if (vars != null) {
                for (k in vars.keys()) interp.variables.set(k, vars[k]);
            }
            result = interp.execute(expr);
        }
        http.onError = function(e) throw 'Failed to fetch file: $e';
        http.request(true);
        return result;
    }
    #end
}
