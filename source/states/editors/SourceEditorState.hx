package states.editors;

import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.StrNameLabel;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import yutautil.typeregistry.EditorFileOrganizer.EditorFile;
import yutautil.typeregistry.EditorFileOrganizer.FileTreeNode;
import yutautil.typeregistry.EditorFileOrganizer;
import yutautil.typeregistry.InGameSourceEditor;
import yutautil.typeregistry.SourceMapper.FunctionInfo;
import yutautil.typeregistry.TypeRegistryAPI;

using StringTools;

/**
 * In-game source code editor state
 * Provides a comprehensive interface for editing source code at runtime
 */
class SourceEditorState extends MusicBeatState {
    // UI Groups
    var filePanel:FlxTypedGroup<FlxSprite>;
    var editorPanel:FlxTypedGroup<FlxSprite>;
    var infoPanel:FlxTypedGroup<FlxSprite>;

    // File management
    var fileListGroup:FlxTypedGroup<FlxText>;
    var fileListItems:Array<String>;
    var fileListScrollY:Int = 0;
    var fileListMaxVisible:Int = 20;
    var folderDropdown:FlxUIDropDownMenu;
    var searchInput:FlxUIInputText;
    var fileTreeNodes:Array<FileTreeItem>;

    // Editor components
    var codeEditor:FlxUIInputText;
    var functionDropdown:FlxUIDropDownMenu;
    var saveButton:FlxButton;
    var revertButton:FlxButton;
    var previewButton:FlxButton;

    // Info display
    var infoText:FlxText;
    var statusText:FlxText;
    var errorText:FlxText;

    // State management
    var sourceEditor:InGameSourceEditor;
    var currentFile:EditorFile;
    var currentFunction:FunctionInfo;
    var unsavedChanges:Bool = false;

    // UI Constants
    static final PANEL_WIDTH:Int = 300;
    static final PANEL_HEIGHT:Int = 600;
    static final MARGIN:Int = 20;

    override function create() {
        super.create();

        forceCursor = true; // Ensure mouse is visible for UI interaction

        // Initialize source editor
        sourceEditor = TypeRegistryAPI.getSourceEditor();

        // Create background
        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(30, 30, 40));
        add(bg);

        // Initialize UI groups
        filePanel = new FlxTypedGroup<FlxSprite>();
        editorPanel = new FlxTypedGroup<FlxSprite>();
        infoPanel = new FlxTypedGroup<FlxSprite>();

        // Create UI panels
        createFilePanel();
        createEditorPanel();
        createInfoPanel();

        // Add groups
        add(filePanel);
        add(editorPanel);
        add(infoPanel);

        // Create navigation
        createNavigation();

        // Load initial data
        refreshFileList();
        updateStatus("Source Editor initialized");

        trace("SourceEditorState: Created successfully");
    }

    function createFilePanel():Void {
        var panelBg = new FlxSprite(MARGIN, MARGIN).makeGraphic(PANEL_WIDTH, PANEL_HEIGHT, FlxColor.fromRGB(40, 40, 50));
        filePanel.add(panelBg);

        // Title
        var title = new FlxText(MARGIN + 10, MARGIN + 10, PANEL_WIDTH - 20, "Source Files");
        title.setFormat(null, 16, FlxColor.WHITE, LEFT);
        filePanel.add(title);

        // Search input
        searchInput = new FlxUIInputText(MARGIN + 10, MARGIN + 40, Std.int(PANEL_WIDTH - 20));
        filePanel.add(searchInput);

        // Folder filter dropdown
        folderDropdown = new FlxUIDropDownMenu(MARGIN + 10, MARGIN + 75, FlxUIDropDownMenu.makeStrIdLabelArray(["All Folders"]), function(folder:String) {
            filterByFolder(folder);
        });
        filePanel.add(folderDropdown);

        // File list (using FlxTypedGroup of FlxText items)
        fileListGroup = new FlxTypedGroup<FlxText>();
        fileListItems = [];
        filePanel.add(cast fileListGroup);

        // Quick actions
        var refreshBtn = new FlxButton(MARGIN + 10, PANEL_HEIGHT - 30, "Refresh", function() {
            refreshFileList();
        });
        refreshBtn.color = FlxColor.fromRGB(70, 130, 180);
        filePanel.add(refreshBtn);

        var exportBtn = new FlxButton(MARGIN + 80, PANEL_HEIGHT - 30, "Export", function() {
            exportModifications();
        });
        exportBtn.color = FlxColor.fromRGB(100, 150, 100);
        filePanel.add(exportBtn);

        var importBtn = new FlxButton(MARGIN + 150, PANEL_HEIGHT - 30, "Import", function() {
            importModifications();
        });
        importBtn.color = FlxColor.fromRGB(150, 100, 100);
        filePanel.add(importBtn);
    }

    function createEditorPanel():Void {
        var editorX = MARGIN * 2 + PANEL_WIDTH;
        var editorWidth = FlxG.width - PANEL_WIDTH - MARGIN * 3 - 300; // Leave space for info panel

        var panelBg = new FlxSprite(editorX, MARGIN).makeGraphic(editorWidth, PANEL_HEIGHT, FlxColor.fromRGB(20, 20, 25));
        editorPanel.add(panelBg);

        // Title with function selector
        var title = new FlxText(editorX + 10, MARGIN + 10, editorWidth - 100, "Code Editor");
        title.setFormat(null, 16, FlxColor.WHITE, LEFT);
        editorPanel.add(title);

        // Function dropdown
        functionDropdown = new FlxUIDropDownMenu(editorX + editorWidth - 200, MARGIN + 10, FlxUIDropDownMenu.makeStrIdLabelArray(["Select Function"]), function(funcName:String) {
            selectFunction(funcName);
        });
        editorPanel.add(functionDropdown);

        // Code editor (large text area)
        codeEditor = new FlxUIInputText(Std.int(editorX + 10), Std.int(MARGIN + 45), Std.int(editorWidth - 20));
        codeEditor.text = "// Select a function to edit";
        editorPanel.add(codeEditor);

        // Editor controls
        var buttonY = PANEL_HEIGHT - 30;

        saveButton = new FlxButton(editorX + 10, buttonY, "Save", function() {
            saveCurrentFunction();
        });
        saveButton.color = FlxColor.fromRGB(100, 150, 100);
        editorPanel.add(saveButton);

        revertButton = new FlxButton(editorX + 80, buttonY, "Revert", function() {
            revertCurrentFunction();
        });
        revertButton.color = FlxColor.fromRGB(180, 100, 100);
        editorPanel.add(revertButton);

        previewButton = new FlxButton(editorX + 150, buttonY, "Validate", function() {
            validateCurrentFunction();
        });
        previewButton.color = FlxColor.fromRGB(100, 100, 180);
        editorPanel.add(previewButton);

        var testButton = new FlxButton(editorX + 220, buttonY, "Test", function() {
            testCurrentFunction();
        });
        testButton.color = FlxColor.fromRGB(150, 100, 150);
        editorPanel.add(testButton);
    }

    function createInfoPanel():Void {
        var infoX = FlxG.width - 290;
        var infoPanelBg = new FlxSprite(infoX, MARGIN).makeGraphic(270, PANEL_HEIGHT, FlxColor.fromRGB(35, 35, 45));
        infoPanel.add(infoPanelBg);

        // Info title
        var infoTitle = new FlxText(infoX + 10, MARGIN + 10, 250, "Function Info");
        infoTitle.setFormat(null, 14, FlxColor.WHITE, LEFT);
        infoPanel.add(infoTitle);

        // Function information display
        infoText = new FlxText(infoX + 10, MARGIN + 35, 250, "No function selected");
        infoText.setFormat(null, 10, FlxColor.GRAY, LEFT);
        infoText.wordWrap = true;
        infoPanel.add(infoText);

        // Status display
        var statusTitle = new FlxText(infoX + 10, PANEL_HEIGHT - 150, 250, "Status");
        statusTitle.setFormat(null, 12, FlxColor.WHITE, LEFT);
        infoPanel.add(statusTitle);

        statusText = new FlxText(infoX + 10, PANEL_HEIGHT - 130, 250, "Ready");
        statusText.setFormat(null, 10, FlxColor.GREEN, LEFT);
        statusText.wordWrap = true;
        infoPanel.add(statusText);

        // Error display
        errorText = new FlxText(infoX + 10, PANEL_HEIGHT - 80, 250, "");
        errorText.setFormat(null, 9, FlxColor.RED, LEFT);
        errorText.wordWrap = true;
        infoPanel.add(errorText);

        // Statistics button
        var statsBtn = new FlxButton(infoX + 10, PANEL_HEIGHT - 30, "Statistics", function() {
            showStatistics();
        });
        statsBtn.color = FlxColor.fromRGB(100, 100, 150);
        infoPanel.add(statsBtn);

        // Help button
        var helpBtn = new FlxButton(infoX + 85, PANEL_HEIGHT - 30, "Help", function() {
            showHelp();
        });
        helpBtn.color = FlxColor.fromRGB(150, 150, 100);
        infoPanel.add(helpBtn);
    }

    function createNavigation():Void {
        // Back button
        var backBtn = new FlxButton(FlxG.width - 80, 10, "Back", function() {
            if (unsavedChanges) {
                confirmExit();
            } else {
                exitEditor();
            }
        });
        backBtn.color = FlxColor.fromRGB(180, 80, 80);
        add(backBtn);
    }

    // === File Management ===

    function refreshFileList():Void {
        var editableFiles = sourceEditor.getEditableFiles();
        var modifiedFiles = sourceEditor.getModifiedFiles();

        fileTreeNodes = [];
        var fileNames = [];

        for (file in editableFiles) {
            var isModified = modifiedFiles.indexOf(file) >= 0;
            var displayName = file.getFileName() + (isModified ? " *" : "");
            fileNames.push(displayName);
            fileTreeNodes.push(new FileTreeItem(file, displayName));
        }

        updateFileListDisplay(fileNames);
        updateFolderDropdown(editableFiles);
        updateStatus('Loaded ${editableFiles.length} editable files');
    }

    function updateFolderDropdown(files:Array<EditorFile>):Void {
        var folders = ["All Folders"];
        var folderSet = new Map<String, Bool>();

        for (file in files) {
            var folder = file.getFolderPath();
            if (folder.length > 0 && !folderSet.exists(folder)) {
                folderSet.set(folder, true);
                folders.push(folder);
            }
        }

        folderDropdown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(folders));
    }

    function selectFile(fileName:String):Void {
        var cleanName = fileName.replace(" *", ""); // Remove modification marker

        for (item in fileTreeNodes) {
            if (item.displayName.replace(" *", "") == cleanName) {
                currentFile = item.file;
                loadFileFunctions(currentFile);
                updateInfo("File selected: " + currentFile.getFileName());
                break;
            }
        }
    }

    function loadFileFunctions(file:EditorFile):Void {
        var functions = file.getEditableFunctions();
        var functionNames = ["Select Function"];

        for (func in functions) {
            var displayName = func.name;
            if (func.isModified) displayName += " *";
            functionNames.push(displayName);
        }

        functionDropdown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(functionNames));

        // Clear editor
        codeEditor.text = "// Select a function to edit";
        currentFunction = null;
        updateFunctionInfo(null);
    }

    function selectFunction(funcName:String):Void {
        if (currentFile == null || funcName == "Select Function") return;

        var cleanName = funcName.replace(" *", "");
        currentFunction = currentFile.sourceFile.getFunctionByName(cleanName);

        if (currentFunction != null) {
            codeEditor.text = currentFunction.getEffectiveSource();
            updateFunctionInfo(currentFunction);
            updateStatus("Function loaded: " + currentFunction.name);
        }
    }

    // === Editor Operations ===

    function onCodeChange():Void {
        if (currentFunction != null) {
            unsavedChanges = true;
            updateStatus("Unsaved changes");
        }
    }

    function saveCurrentFunction():Void {
        if (currentFunction == null || currentFile == null) {
            showError("No function selected");
            return;
        }

        var newSource = codeEditor.text;
        if (newSource == currentFunction.getEffectiveSource()) {
            updateStatus("No changes to save");
            return;
        }

        if (sourceEditor.editFunction(currentFunction.name, newSource, currentFile.sourceFile.filePath)) {
            unsavedChanges = false;
            updateStatus("Function saved successfully");
            refreshFileList(); // Update modification markers
            updateFunctionInfo(currentFunction); // Refresh info
        } else {
            showError("Failed to save function");
        }
    }

    function revertCurrentFunction():Void {
        if (currentFunction == null) {
            showError("No function selected");
            return;
        }

        if (sourceEditor.revertFunction(currentFunction.name, currentFile.sourceFile.filePath)) {
            codeEditor.text = currentFunction.sourceCode; // Original source
            unsavedChanges = false;
            updateStatus("Function reverted to original");
            refreshFileList();
            updateFunctionInfo(currentFunction);
        } else {
            showError("Failed to revert function");
        }
    }

    function validateCurrentFunction():Void {
        if (currentFunction == null) {
            showError("No function selected");
            return;
        }

        var source = codeEditor.text;
        if (sourceEditor.validateFunctionSource(currentFunction.name, source, currentFile.sourceFile.filePath)) {
            updateStatus("Function syntax is valid");
            errorText.text = "";
        } else {
            showError("Function syntax validation failed");
        }
    }

    function testCurrentFunction():Void {
        updateStatus("Function testing not implemented yet");
        // TODO: Implement function testing mechanism
    }

    // === UI Updates ===

    function updateFunctionInfo(func:FunctionInfo):Void {
        if (func == null) {
            infoText.text = "No function selected";
            return;
        }

        var info = new StringBuf();
        info.add('Function: ${func.name}\n');
        info.add('Signature: ${func.getSignature()}\n');
        info.add('File: ${func.filePath}\n');
        info.add('Lines: ${func.startLine}-${func.endLine}\n');
        info.add('Editable: ${func.isEditable()}\n');
        info.add('Modified: ${func.isModified}\n');

        if (func.documentation.length > 0) {
            info.add('\nDocumentation:\n');
            for (doc in func.documentation.slice(0, 3)) {
                info.add('${doc.replace("/**", "").replace("*/", "").replace("*", "").trim()}\n');
            }
        }

        infoText.text = info.toString();
    }

    function updateStatus(message:String):Void {
        statusText.text = message;
        statusText.color = FlxColor.GREEN;
        errorText.text = "";
        trace('SourceEditorState: $message');
    }

    function showError(message:String):Void {
        errorText.text = "Error: " + message;
        statusText.color = FlxColor.RED;
        statusText.text = "Error occurred";
        trace('SourceEditorState Error: $message');
    }

    function updateInfo(message:String):Void {
        statusText.text = message;
        statusText.color = FlxColor.YELLOW;
    }

    // === Search and Filter ===

    function searchFiles():Void {
        var searchTerm = searchInput.text.toLowerCase();
        if (searchTerm.length == 0) {
            refreshFileList();
            return;
        }

        var results = sourceEditor.searchFiles(searchTerm);
        var fileNames = [];
        fileTreeNodes = [];

        for (file in results) {
            var isModified = file.hasModifications();
            var displayName = file.getFileName() + (isModified ? " *" : "");
            fileNames.push(displayName);
            fileTreeNodes.push(new FileTreeItem(file, displayName));
        }

        updateFileListDisplay(fileNames);
        updateStatus('Found ${results.length} files matching "${searchTerm}"');
    }

    function filterByFolder(folder:String):Void {
        if (folder == "All Folders") {
            refreshFileList();
            return;
        }

        var files = EditorFileOrganizer.get().getFilesInFolder(folder);
        var fileNames = [];
        fileTreeNodes = [];

        for (file in files) {
            if (file.hasEditableFunctions()) {
                var isModified = file.hasModifications();
                var displayName = file.getFileName() + (isModified ? " *" : "");
                fileNames.push(displayName);
                fileTreeNodes.push(new FileTreeItem(file, displayName));
            }
        }

        updateFileListDisplay(fileNames);
        updateStatus('Showing ${fileNames.length} files in folder: $folder');
    }

    // === Import/Export ===

    function exportModifications():Void {
        var json = sourceEditor.exportModifications();
        // Show export info via status text
        updateStatus("Modifications exported. Total: " + Std.string(json.length) + " chars");
        trace("SourceEditorState: Export data: " + json.substr(0, 200));
    }

    function importModifications():Void {
        // Import is handled via file - not interactive prompt
        updateStatus("Import: Place modifications JSON in source_editor_modifications.json and restart");
    }

    // === Dialogs ===

    function showStatistics():Void {
        var stats = sourceEditor.getEditorStatistics();
        var statsMsg = 'Files: ${stats.files.totalFiles} total, ${stats.files.editableFiles} editable\n';
        statsMsg += 'Functions: ${stats.files.totalFunctions} total, ${stats.files.editableFunctions} editable\n';
        statsMsg += 'Modifications: ${stats.modifications.active} active, ${stats.modifications.reverted} reverted';
        updateStatus(statsMsg);
    }

    function showHelp():Void {
        var helpMsg = "Select files > Choose functions > Edit > Save. Ctrl+S=Save, Ctrl+R=Revert, Ctrl+F=Search, Esc=Exit";
        updateStatus(helpMsg);
    }

    function confirmExit():Void {
        // Just exit - unsaved changes warning via status text
        updateStatus("WARNING: Unsaved changes will be lost!");
        exitEditor();
    }

    function exitEditor():Void {
        trace("SourceEditorState: Exiting editor");
        FlxG.switchState(new states.MainMenuState());
    }

    /**
     * Rebuild the file list display from an array of names
     */
    function updateFileListDisplay(names:Array<String>):Void {
        // Clear existing items
        fileListGroup.clear();
        fileListItems = names;

        // Create visible text items
        var startY = MARGIN + 110;
        var lineHeight = 18;
        var maxItems = Std.int(Math.min(names.length, fileListMaxVisible));

        for (i in 0...maxItems) {
            var idx = i + fileListScrollY;
            if (idx >= names.length) break;

            var label = new FlxText(MARGIN + 10, startY + i * lineHeight, PANEL_WIDTH - 20, names[idx]);
            label.setFormat(null, 10, FlxColor.WHITE, LEFT);
            fileListGroup.add(label);
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle file list item clicks
        if (FlxG.mouse.justPressed) {
            var mouseX = FlxG.mouse.screenX;
            var mouseY = FlxG.mouse.screenY;
            var startY = MARGIN + 110;
            var lineHeight = 18;

            if (mouseX >= MARGIN + 10 && mouseX <= MARGIN + PANEL_WIDTH - 10) {
                var clickedIndex = Std.int((mouseY - startY) / lineHeight) + fileListScrollY;
                if (clickedIndex >= 0 && clickedIndex < fileListItems.length) {
                    selectFile(fileListItems[clickedIndex]);
                }
            }
        }

        // Handle keyboard shortcuts
        if (FlxG.keys.justPressed.ESCAPE) {
            if (unsavedChanges) {
                confirmExit();
            } else {
                exitEditor();
            }
        }

        if (FlxG.keys.pressed.CONTROL) {
            if (FlxG.keys.justPressed.S) {
                saveCurrentFunction();
            }
            if (FlxG.keys.justPressed.R) {
                revertCurrentFunction();
            }
            if (FlxG.keys.justPressed.F) {
                // Focus search
                searchFiles();
            }
        }

        // Handle Enter in search
        if (FlxG.keys.justPressed.ENTER) {
            searchFiles();
        }
    }
}

/**
 * Helper class for file tree items
 */
class FileTreeItem {
    public var file:EditorFile;
    public var displayName:String;

    public function new(file:EditorFile, displayName:String) {
        this.file = file;
        this.displayName = displayName;
    }
}
