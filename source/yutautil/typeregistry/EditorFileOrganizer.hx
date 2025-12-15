package yutautil.typeregistry;

import haxe.io.Path;
import yutautil.typeregistry.SourceEditor;
import yutautil.typeregistry.SourceMapper;

/**
 * File organization system for the in-game source code editor
 * Organizes source files by folders and provides hierarchical navigation
 */
class EditorFileOrganizer {
    private static var _instance:EditorFileOrganizer;
    private var fileTree:FileTreeNode;
    private var flatFileList:Array<EditorFile>;

    public static function get():EditorFileOrganizer {
        if (_instance == null) {
            _instance = new EditorFileOrganizer();
        }
        return _instance;
    }

    private function new() {
        fileTree = new FileTreeNode("root", "", true);
        flatFileList = [];
        buildFileTree();
    }

    /**
     * Build the complete file tree from all source files
     */
    public function buildFileTree():Void {
        fileTree = new FileTreeNode("root", "", true);
        flatFileList = [];

        var sourceFiles = SourceMapper.getAllSourceFiles();

        for (sourceFile in sourceFiles) {
            var editorFile = new EditorFile(sourceFile);
            flatFileList.push(editorFile);

            // Add to tree structure
            addFileToTree(editorFile);
        }

        // Sort everything
        sortFileTree(fileTree);

        trace('EditorFileOrganizer: Built tree with ${flatFileList.length} files');
    }

    /**
     * Add a file to the tree structure
     */
    private function addFileToTree(editorFile:EditorFile):Void {
        var pathParts = editorFile.getRelativePath().split("/");
        var currentNode = fileTree;

        // Navigate/create folder structure
        for (i in 0...pathParts.length - 1) {
            var folderName = pathParts[i];
            var folderNode = currentNode.getChild(folderName);

            if (folderNode == null) {
                folderNode = new FileTreeNode(folderName, currentNode.fullPath + "/" + folderName, true);
                currentNode.addChild(folderNode);
            }

            currentNode = folderNode;
        }

        // Add the file
        var fileName = pathParts[pathParts.length - 1];
        var fileNode = new FileTreeNode(fileName, editorFile.sourceFile.filePath, false);
        fileNode.editorFile = editorFile;
        currentNode.addChild(fileNode);
    }

    /**
     * Sort the file tree alphabetically
     */
    private function sortFileTree(node:FileTreeNode):Void {
        node.children.sort(function(a, b) {
            // Folders first, then files
            if (a.isFolder && !b.isFolder) return -1;
            if (!a.isFolder && b.isFolder) return 1;

            // Then alphabetically
            return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1;
        });

        for (child in node.children) {
            sortFileTree(child);
        }
    }

    /**
     * Get the root file tree
     */
    public function getFileTree():FileTreeNode {
        return fileTree;
    }

    /**
     * Get all files as a flat list
     */
    public function getAllFiles():Array<EditorFile> {
        return flatFileList.copy();
    }

    /**
     * Get files in a specific folder
     */
    public function getFilesInFolder(folderPath:String):Array<EditorFile> {
        var results = [];

        for (file in flatFileList) {
            if (file.getRelativePath().indexOf(folderPath) == 0) {
                results.push(file);
            }
        }

        return results;
    }

    /**
     * Get editable files only
     */
    public function getEditableFiles():Array<EditorFile> {
        return flatFileList.filter(file -> file.hasEditableFunctions());
    }

    /**
     * Get files with modifications
     */
    public function getModifiedFiles():Array<EditorFile> {
        return flatFileList.filter(file -> file.hasModifications());
    }

    /**
     * Find a file by path
     */
    public function findFile(filePath:String):EditorFile {
        for (file in flatFileList) {
            if (file.sourceFile.filePath == filePath) {
                return file;
            }
        }
        return null;
    }

    /**
     * Find files by name pattern
     */
    public function findFilesByName(pattern:String):Array<EditorFile> {
        var results = [];
        var lowerPattern = pattern.toLowerCase();

        for (file in flatFileList) {
            if (file.getFileName().toLowerCase().indexOf(lowerPattern) >= 0) {
                results.push(file);
            }
        }

        return results;
    }

    /**
     * Get folder structure as a hierarchical list
     */
    public function getFolderStructure():Array<FolderInfo> {
        return buildFolderInfo(fileTree, 0);
    }

    private function buildFolderInfo(node:FileTreeNode, depth:Int):Array<FolderInfo> {
        var results = [];

        for (child in node.children) {
            if (child.isFolder) {
                var info = new FolderInfo(child.name, child.fullPath, depth);

                // Count files in this folder
                info.fileCount = countFilesInFolder(child);
                info.editableCount = countEditableFilesInFolder(child);
                info.modifiedCount = countModifiedFilesInFolder(child);

                results.push(info);

                // Add subfolders
                var subFolders = buildFolderInfo(child, depth + 1);
                results = results.concat(subFolders);
            }
        }

        return results;
    }

    private function countFilesInFolder(folderNode:FileTreeNode):Int {
        var count = 0;

        for (child in folderNode.children) {
            if (child.isFolder) {
                count += countFilesInFolder(child);
            } else {
                count++;
            }
        }

        return count;
    }

    private function countEditableFilesInFolder(folderNode:FileTreeNode):Int {
        var count = 0;

        for (child in folderNode.children) {
            if (child.isFolder) {
                count += countEditableFilesInFolder(child);
            } else if (child.editorFile != null && child.editorFile.hasEditableFunctions()) {
                count++;
            }
        }

        return count;
    }

    private function countModifiedFilesInFolder(folderNode:FileTreeNode):Int {
        var count = 0;

        for (child in folderNode.children) {
            if (child.isFolder) {
                count += countModifiedFilesInFolder(child);
            } else if (child.editorFile != null && child.editorFile.hasModifications()) {
                count++;
            }
        }

        return count;
    }

    /**
     * Get statistics about the file organization
     */
    public function getStatistics():{
        totalFiles:Int,
        editableFiles:Int,
        modifiedFiles:Int,
        totalFolders:Int,
        totalFunctions:Int,
        editableFunctions:Int,
        modifiedFunctions:Int
    } {
        var totalFunctions = 0;
        var editableFunctions = 0;
        var modifiedFunctions = 0;

        for (file in flatFileList) {
            totalFunctions += file.sourceFile.functions.length;
            editableFunctions += file.getEditableFunctions().length;
            modifiedFunctions += file.getModifiedFunctions().length;
        }

        return {
            totalFiles: flatFileList.length,
            editableFiles: getEditableFiles().length,
            modifiedFiles: getModifiedFiles().length,
            totalFolders: countTotalFolders(fileTree),
            totalFunctions: totalFunctions,
            editableFunctions: editableFunctions,
            modifiedFunctions: modifiedFunctions
        };
    }

    private function countTotalFolders(node:FileTreeNode):Int {
        var count = node.isFolder ? 1 : 0;

        for (child in node.children) {
            count += countTotalFolders(child);
        }

        return count;
    }

    /**
     * Refresh the file tree (call after modifications)
     */
    public function refresh():Void {
        buildFileTree();
    }
}

/**
 * Represents a source file in the editor
 */
class EditorFile {
    public var sourceFile(default, null):SourceFile;
    public var relativePath(default, null):String;

    public function new(sourceFile:SourceFile) {
        this.sourceFile = sourceFile;
        this.relativePath = calculateRelativePath(sourceFile.filePath);
    }

    private function calculateRelativePath(fullPath:String):String {
        // Remove common project paths to make relative
        var pathToRemove = [
            "source/",
            "src/",
            "/source/",
            "/src/"
        ];

        var result = fullPath;
        for (pathPrefix in pathToRemove) {
            var index = result.indexOf(pathPrefix);
            if (index >= 0) {
                result = result.substring(index + pathPrefix.length);
                break;
            }
        }

        return result.replace("\\", "/");
    }

    public function getFileName():String {
        return Path.withoutDirectory(sourceFile.filePath);
    }

    public function getRelativePath():String {
        return relativePath;
    }

    public function getFolderPath():String {
        var parts = relativePath.split("/");
        parts.pop(); // Remove filename
        return parts.join("/");
    }

    public function getEditableFunctions():Array<FunctionInfo> {
        return sourceFile.getEditableFunctions();
    }

    public function getViewOnlyFunctions():Array<FunctionInfo> {
        return sourceFile.getViewOnlyFunctions();
    }

    public function getAllFunctions():Array<FunctionInfo> {
        return sourceFile.functions;
    }

    public function getModifiedFunctions():Array<FunctionInfo> {
        return sourceFile.functions.filter(func -> func.isModified);
    }

    public function hasEditableFunctions():Bool {
        return getEditableFunctions().length > 0;
    }

    public function hasModifications():Bool {
        return getModifiedFunctions().length > 0;
    }

    public function getFileInfo():{
        name:String,
        path:String,
        packageName:String,
        totalFunctions:Int,
        editableFunctions:Int,
        modifiedFunctions:Int,
        imports:Int,
        typeDeclarations:Int
    } {
        return {
            name: getFileName(),
            path: relativePath,
            packageName: sourceFile.packageName,
            totalFunctions: sourceFile.functions.length,
            editableFunctions: getEditableFunctions().length,
            modifiedFunctions: getModifiedFunctions().length,
            imports: sourceFile.imports.length,
            typeDeclarations: sourceFile.typeDeclarations.length
        };
    }
}

/**
 * File tree node for hierarchical organization
 */
class FileTreeNode {
    public var name(default, null):String;
    public var fullPath(default, null):String;
    public var isFolder(default, null):Bool;
    public var children(default, null):Array<FileTreeNode>;
    public var parent(default, null):FileTreeNode;
    public var editorFile(default, null):EditorFile; // Only for file nodes

    public function new(name:String, fullPath:String, isFolder:Bool) {
        this.name = name;
        this.fullPath = fullPath;
        this.isFolder = isFolder;
        this.children = [];
    }

    public function addChild(child:FileTreeNode):Void {
        child.parent = this;
        children.push(child);
    }

    public function getChild(name:String):FileTreeNode {
        for (child in children) {
            if (child.name == name) {
                return child;
            }
        }
        return null;
    }

    public function getFiles():Array<FileTreeNode> {
        return children.filter(child -> !child.isFolder);
    }

    public function getFolders():Array<FileTreeNode> {
        return children.filter(child -> child.isFolder);
    }

    public function getDepth():Int {
        var depth = 0;
        var current = parent;

        while (current != null) {
            depth++;
            current = current.parent;
        }

        return depth;
    }
}

/**
 * Folder information for the editor UI
 */
class FolderInfo {
    public var name(default, null):String;
    public var path(default, null):String;
    public var depth(default, null):Int;
    public var fileCount(default, null):Int;
    public var editableCount(default, null):Int;
    public var modifiedCount(default, null):Int;

    public function new(name:String, path:String, depth:Int) {
        this.name = name;
        this.path = path;
        this.depth = depth;
        this.fileCount = 0;
        this.editableCount = 0;
        this.modifiedCount = 0;
    }

    public function toString():String {
        var indent = "";
        for (i in 0...depth) {
            indent += "  ";
        }

        var status = "";
        if (modifiedCount > 0) status += " [Modified: " + modifiedCount + "]";
        if (editableCount > 0) status += " [Editable: " + editableCount + "]";

        return '$indent$name ($fileCount files)$status';
    }
}
