package yutautil;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.Http;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
using StringTools;
#end

/**
 * GithubSource - A macro for grabbing raw GitHub files and integrating them into source code
 * 
 * Features:
 * - Download raw files from GitHub repositories
 * - Parse and integrate Haxe source files
 * - Automatically resolve and download dependencies
 * - Support for custom branches and path resolution
 */
class GithubSource {
    #if macro
    
    private static var downloadedFiles:Map<String, String> = new Map();
    private static var processedImports:Map<String, Bool> = new Map();
    private static var tempDir:String = "temp_github_sources";
    
    /**
     * Download a raw file from GitHub
     * @param repo Repository name in format "owner/repo"
     * @param filePath File path using package-like notation (e.g., "backend.MusicBeatState")
     * @param branch Optional branch name (defaults to "main")
     * @return The raw file content as a String
     */
    public static macro function getRawFile(repo:String, filePath:String, ?branch:String = "main"):Expr {
        var url = buildGitHubRawUrl(repo, filePath, branch);
        var cacheKey = repo + "/" + branch + "/" + filePath;
        
        if (downloadedFiles.exists(cacheKey)) {
            var content = downloadedFiles.get(cacheKey);
            return macro $v{content};
        }
        
        var content = downloadFromUrl(url);
        if (content == null) {
            // Try with source/ prefix
            var sourceUrl = buildGitHubRawUrl(repo, "source." + filePath, branch);
            content = downloadFromUrl(sourceUrl);
            
            if (content == null) {
                // Try with src/ prefix
                var srcUrl = buildGitHubRawUrl(repo, "src." + filePath, branch);
                content = downloadFromUrl(srcUrl);
            }
        }
        
        if (content != null) {
            downloadedFiles.set(cacheKey, content);
            return macro $v{content};
        }
        
        Context.warning('Failed to download file: ${repo}/${filePath} (branch: ${branch})', Context.currentPos());
        return macro null;
    }
    
    /**
     * Helper function to get raw file content (for internal use)
     */
    private static function getRawFileContent(repo:String, filePath:String, ?branch:String = "main"):String {
        var url = buildGitHubRawUrl(repo, filePath, branch);
        var cacheKey = repo + "/" + branch + "/" + filePath;
        
        if (downloadedFiles.exists(cacheKey)) {
            return downloadedFiles.get(cacheKey);
        }
        
        var content = downloadFromUrl(url);
        if (content == null) {
            // Try with source/ prefix
            var sourceUrl = buildGitHubRawUrl(repo, "source." + filePath, branch);
            content = downloadFromUrl(sourceUrl);
            
            if (content == null) {
                // Try with src/ prefix
                var srcUrl = buildGitHubRawUrl(repo, "src." + filePath, branch);
                content = downloadFromUrl(srcUrl);
            }
        }
        
        if (content != null) {
            downloadedFiles.set(cacheKey, content);
        }
        
        return content;
    }
    
    /**
     * Download and integrate a Haxe source file from GitHub
     * @param repo Repository name in format "owner/repo"
     * @param filePath File path using package-like notation (e.g., "backend.MusicBeatState")
     * @param branch Optional branch name (defaults to "main")
     * @return Path to the temporary file or null if failed
     */
    public static macro function getHaxeFile(repo:String, filePath:String, ?branch:String = "main"):Expr {
        var content = getRawFileContent(repo, filePath, branch);
        if (content == null) {
            Context.warning('Failed to download Haxe file: ${repo}/${filePath} (branch: ${branch})', Context.currentPos());
            return macro null;
        }
        
        if (!isValidHaxeSource(content)) {
            Context.warning('Downloaded file is not valid Haxe source: ${repo}/${filePath}', Context.currentPos());
            return macro null;
        }
        
        // Process imports in the downloaded file
        processHaxeImports(content, repo, branch);
        
        // Save to temporary file
        var tempFilePath = saveToTempFile(content, filePath);
        
        return macro $v{tempFilePath};
    }
    
    /**
     * Macro to automatically download and include a Haxe file
     * Usage: @:build(yutautil.GithubSource.includeFromGithub("owner/repo", "package.ClassName"))
     */
    public static function includeFromGithub(repo:String, filePath:String, ?branch:String = "main"):Array<Field> {
        var content = getRawFileContent(repo, filePath, branch);
        if (content == null) {
            Context.error('Failed to include file from GitHub: ${repo}/${filePath}', Context.currentPos());
        }
        
        if (!isValidHaxeSource(content)) {
            Context.error('Downloaded file is not valid Haxe source: ${repo}/${filePath}', Context.currentPos());
        }
        
        // Process imports in the downloaded file
        processHaxeImports(content, repo, branch);
        
        // Save to temporary file
        var tempFilePath = saveToTempFile(content, filePath);
        
        // Parse the downloaded file and extract its fields
        try {
            var fileContent = File.getContent(tempFilePath);
            var parsed = Context.parseInlineString(fileContent, Context.currentPos());
            
            // Extract class definition and return fields
            switch (parsed.expr) {
                case EBlock(exprs):
                    for (expr in exprs) {
                        switch (expr.expr) {
                            case EClass(c):
                                return c.fields;
                            default:
                        }
                    }
                default:
            }
        } catch (e:Dynamic) {
            Context.error('Failed to parse downloaded Haxe file: ${e}', Context.currentPos());
        }
        
        return Context.getBuildFields();
    }
    
    private static function buildGitHubRawUrl(repo:String, filePath:String, branch:String):String {
        var pathParts = filePath.split(".");
        var actualPath = pathParts.join("/") + ".hx";
        return 'https://raw.githubusercontent.com/${repo}/${branch}/${actualPath}';
    }
    
    private static function downloadFromUrl(url:String):String {
        try {
            var http = new Http(url);
            var result:String = null;
            var error:String = null;
            
            http.onData = function(data:String) {
                result = data;
            };
            
            http.onError = function(err:String) {
                error = err;
            };
            
            http.request(false);
            
            if (error != null) {
                return null;
            }
            
            return result;
        } catch (e:Dynamic) {
            return null;
        }
    }
    
    private static function isValidHaxeSource(source:String):Bool {
        if (source == null || source.length == 0) {
            return false;
        }
        
        try {
            // Basic validation - check for package declaration or class/interface/enum declaration
            var lines = source.split("\n");
            var hasValidDeclaration = false;
            
            for (line in lines) {
                var trimmed = line.trim();
                if (trimmed.startsWith("package ") || 
                    trimmed.startsWith("class ") || 
                    trimmed.startsWith("interface ") || 
                    trimmed.startsWith("enum ") ||
                    trimmed.startsWith("abstract ") ||
                    trimmed.startsWith("typedef ")) {
                    hasValidDeclaration = true;
                    break;
                }
            }
            
            return hasValidDeclaration;
        } catch (e:Dynamic) {
            return false;
        }
    }
    
    private static function processHaxeImports(content:String, repo:String, branch:String):Void {
        var lines = content.split("\n");
        var imports:Array<String> = [];
        
        // Extract import statements
        for (line in lines) {
            var trimmed = line.trim();
            if (trimmed.startsWith("import ")) {
                var importPath = trimmed.substring(7).replace(";", "").trim();
                if (!importPath.startsWith("haxe.") && 
                    !importPath.startsWith("sys.") && 
                    !importPath.startsWith("flash.") &&
                    !importPath.startsWith("openfl.") &&
                    !importPath.startsWith("flixel.") &&
                    !importPath.startsWith("lime.")) {
                    imports.push(importPath);
                }
            }
        }
        
        // Try to download missing imports from the same repository
        for (importPath in imports) {
            var cacheKey = repo + "/" + branch + "/" + importPath;
            if (!processedImports.exists(cacheKey)) {
                processedImports.set(cacheKey, true);
                
                // Check if this import exists locally first
                if (!doesImportExistLocally(importPath)) {
                    // Try to download from GitHub
                    var importContent = getRawFileContent(repo, importPath, branch);
                    if (importContent != null && isValidHaxeSource(importContent)) {
                        var tempPath = saveToTempFile(importContent, importPath);
                        // Recursively process imports in the downloaded file
                        processHaxeImports(importContent, repo, branch);
                    }
                }
            }
        }
    }
    
    private static function doesImportExistLocally(importPath:String):Bool {
        var pathParts = importPath.split(".");
        var relativePath = pathParts.join("/") + ".hx";
        
        // Check common source directories
        var possiblePaths = [
            "source/" + relativePath,
            "src/" + rejhgjlativePath,
            relativePath
        ];
        
        for (path in possiblePaths) {
            if (FileSystem.exists(path)) {
                return true;
            }
        }
        
        return false;
    }
    
    private static function saveToTempFile(content:String, filePath:String):String {
        if (!FileSystem.exists(tempDir)) {
            FileSystem.createDirectory(tempDir);
        }
        
        var pathParts = filePath.split(".");
        var fileName = pathParts[pathParts.length - 1] + ".hx";
        var fullPath = tempDir + "/" + fileName;
        
        // Create subdirectories if needed
        var dir = Path.directory(fullPath);
        if (dir != "" && !FileSystem.exists(dir)) {
            FileSystem.createDirectory(dir);
        }
        
        File.saveContent(fullPath, content);
        return fullPath;
    }
    
    /**
     * Clean up temporary files created by GithubSource
     */
    public static macro function cleanup():Expr {
        if (FileSystem.exists(tempDir)) {
            try {
                removeDirectory(tempDir);
            } catch (e:Dynamic) {
                // Ignore cleanup errors
            }
        }
        downloadedFiles.clear();
        processedImports.clear();
        return macro null;
    }
    
    private static function removeDirectory(path:String):Void {
        if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
            for (file in FileSystem.readDirectory(path)) {
                var fullPath = path + "/" + file;
                if (FileSystem.isDirectory(fullPath)) {
                    removeDirectory(fullPath);
                } else {
                    FileSystem.deleteFile(fullPath);
                }
            }
            FileSystem.deleteDirectory(path);
        }
    }
    
    #end
}