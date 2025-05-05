package states.editors;

import flixel.FlxState;
import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import sys.io.File;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.FileReference;
import haxe.xml.Parser;

class XMLEditorState extends MusicBeatState
{
    private var xmlData:Xml;
    private var filePathDisplay:FlxText;
    private var treeView:FlxGroup;
    private var saveButton:PsychUIButton;
    private var editGroup:FlxGroup; // For editing nodes/attributes

    override public function create():Void
    {
        super.create();

        // Initialize UI components
        setupUI();

        // Initialize the tree view
        treeView = new FlxGroup();
        add(treeView);

        // Initialize the edit group
        editGroup = new FlxGroup();
        add(editGroup);
    }

    // Sets up the UI components (buttons, text fields, etc.)
    private function setupUI():Void
    {
        // Button to load XML
        var loadXMLButton:PsychUIButton = new PsychUIButton(10, 10, "Load XML", onLoadXML);
        add(loadXMLButton);

        // Display the file path of the loaded XML
        filePathDisplay = new FlxText(10, 50, 500, "No XML file loaded.");
        add(filePathDisplay);

        // Save button
        saveButton = new PsychUIButton(10, 80, "Save XML", onSaveXML);
        saveButton.visible = false;  // Only show when an XML is loaded
        add(saveButton);
    }

    // Function for loading an XML file using OpenFL's FileReference
    private function onLoadXML():Void
    {
        var fileRef:FileReference = new FileReference();
        fileRef.addEventListener(Event.SELECT, onFileSelected);
        fileRef.addEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
        fileRef.browse();
    }

    // When a file is selected from the file dialog
    private function onFileSelected(event:Event):Void
    {
        var fileRef:FileReference = cast(event.currentTarget, FileReference);
        fileRef.addEventListener(Event.COMPLETE, onFileLoadComplete);
        fileRef.load();
    }

    // When the file is loaded successfully
    private function onFileLoadComplete(event:Event):Void
    {
        var fileRef:FileReference = cast(event.currentTarget, FileReference);
        try
        {
            var fileContent:String = fileRef.data.toString();
            xmlData = Parser.parse(fileContent);

            // Update UI with loaded XML data
            filePathDisplay.text = "Loaded: " + fileRef.name;
            saveButton.visible = true;

            // Parse and display XML structure here (build tree view)
            buildXMLTreeView(xmlData.firstElement());

        }
        catch (e:Dynamic)
        {
            trace("Error parsing XML: " + e);
        }
    }

    // Handle file load errors
    private function onFileLoadError(event:IOErrorEvent):Void
    {
        trace("Error loading file: " + event.text);
    }

    // Save the modified XML back to disk
    private function onSaveXML():Void
    {
        if (xmlData != null)
        {
            var fileRef:FileReference = new FileReference();
            fileRef.save(xmlData.toString(), "modified_file.xml");
        }
    }

    // Build the XML tree view and display nodes/attributes
    private function buildXMLTreeView(node:Xml):Void
    {
        treeView.clear();
        buildXMLNodeView(node, 0);
    }

    // Recursively builds the tree view for the XML nodes
    private function buildXMLNodeView(node:Xml, depth:Int):Void
    {
        if (node == null) return;
    
        var yPos:Int = 150 + depth * 20;
    
        // Display the node text
        @:privateAccess
        var nodeText:FlxText = new FlxText(20 + depth * 20, yPos, 400, "<" + node.get_nodeName() + ">");
        treeView.add(nodeText);
    
        // Edit button for the node
        var editButton:PsychUIButton = new PsychUIButton(nodeText.x + 200, yPos, "Edit", function() { 
            editNode(node); // Pass the node directly to the edit function
        });
        treeView.add(editButton);
    
        // Recursively add child nodes
        for (child in node.elements())
        {
            buildXMLNodeView(child, depth + 1);
        }
    }

    // Edit an XML node or attribute
    private function editNode(node:Xml):Void
    {
        // Clear any previous edit UI
        editGroup.clear();
    
        // Display the node being edited
        @:privateAccess {
        var editText:FlxText = new FlxText(20, 300, 200, "Edit node: <" + node.get_nodeName() + ">");
        editGroup.add(editText);
        }
    
        // Input field for editing the node's value
        var input:PsychUIInputText = new PsychUIInputText(20, 340, 200, node.toString());
        editGroup.add(input);
    
        // Save changes button
        var saveEditButton:PsychUIButton = new PsychUIButton(20, 380, "Save Changes", function() {
            @:privateAccess {
            node.set_nodeValue(input.text);  // Update the node with new value
            editGroup.clear();  // Clear the edit group after saving
            }
        });
        editGroup.add(saveEditButton);
    }
}