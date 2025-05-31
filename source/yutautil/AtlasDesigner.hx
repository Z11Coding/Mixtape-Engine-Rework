package yutautil;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.utils.Bytes;
import haxe.xml.Printer;
import yutautil.AtlasSchema;

// WIP// A simple atlas designer for packing images into a single spritesheet
class AtlasDesigner {
    public var images:Array<{name:String, image:Image, x:Int, y:Int, width:Int, height:Int}> = [];
    public var sheetWidth:Int;
    public var sheetHeight:Int;
    public var schema:AtlasSchema = null;

    public function new(?schema:AtlasSchema) {
        this.schema = schema;
    }

    public function loadImagesFromFolder(folder:String):Void {
        images = [];
        var files = FileSystem.readDirectory(folder);
        if (schema != null) {
            if (!schema.validate(folder, files)) {
                throw 'Folder does not match schema requirements.';
            }
            if (schema != null) {
                files = schema.filterFiles(files);
            }
        }
        for (file in files) {
            var ext = Path.extension(file).toLowerCase();
            if (ext == "png" || ext == "jpg" || ext == "jpeg") {
                var img = Image.fromFile(Path.join([folder, file]));
                images.push({
                    name: Path.withoutExtension(file),
                    image: img,
                    x: 0,
                    y: 0,
                    width: img.width,
                    height: img.height
                });
            }
        }
    }

    public function packImages():Void {
        // Simple packing: arrange images in a single row
        var x = 0;
        var maxHeight = 0;
        for (img in images) {
            img.x = x;
            img.y = 0;
            x += img.width;
            if (img.height > maxHeight) maxHeight = img.height;
        }
        sheetWidth = x;
        sheetHeight = maxHeight;
    }

    public function createSpritesheet():Image {
        var buffer = new ImageBuffer(sheetWidth, sheetHeight, null, 0x00000000);
        var sheet = new Image(buffer);
        for (img in images) {
            sheet.draw(img.image, img.x, img.y);
        }
        return sheet;
    }

    public function saveSpritesheet(path:String):Void {
        var sheet = createSpritesheet();
        sheet.encode("png").saveToFile(path);
    }

    public function saveXML(path:String):Void {
        var xml = '<TextureAtlas imagePath="' + Path.withoutDirectory(path) + '">';
        for (img in images) {
            xml += '<SubTexture name="' + img.name + '" x="' + img.x + '" y="' + img.y + '" width="' + img.width + '" height="' + img.height + '"/>';
        }
        xml += '</TextureAtlas>';
        File.saveContent(path, xml);
    }

    public static function convertFolderToSpritesheet(folder:String, outputPath:String, ?schema:AtlasSchema):Void {
        var designer = new AtlasDesigner(schema);
        designer.loadImagesFromFolder(folder);
        designer.packImages();
        designer.saveSpritesheet(outputPath + ".png");
        designer.saveXML(outputPath + ".xml");
    }

    public function buildAtlas(folder:String, outputPath:String):Void {
        loadImagesFromFolder(folder);
        packImages();
        saveSpritesheet(outputPath + ".png");
        saveXML(outputPath + ".xml");
    }

    // Turns the completed Atlas in the Designer into a FlxSprite
    public function toFlxSprite():flixel.FlxSprite {
        var sheet = createSpritesheet();
        // Convert lime.graphics.Image to flixel.graphics.frames.FlxAtlasFrames
        var bitmapData = sheet.toBitmapData();
        var frames = flixel.graphics.frames.FlxAtlasFrames.fromTexturePackerXml(bitmapData, saveXMLToString());
        return new flixel.FlxSprite().loadGraphic(frames);
    }

    // Helper to get XML as string (without saving to file)
    private function saveXMLToString():String {
        var xml = '<TextureAtlas imagePath="spritesheet.png">';
        for (img in images) {
            xml += '<SubTexture name="' + img.name + '" x="' + img.x + '" y="' + img.y + '" width="' + img.width + '" height="' + img.height + '"/>';
        }
        xml += '</TextureAtlas>';
        return xml;
    }

    // Static function: does all steps and returns a FlxSprite, no files saved
    public static function buildFlxSpriteFromFolder(folder:String, ?schema:AtlasSchema):flixel.FlxSprite {
        var designer = new AtlasDesigner(schema);
        designer.loadImagesFromFolder(folder);
        designer.packImages();
        var sheet = designer.createSpritesheet();
        var bitmapData = sheet.toBitmapData();
        var frames = flixel.graphics.frames.FlxAtlasFrames.fromTexturePackerXml(bitmapData, designer.saveXMLToString());
        return new flixel.FlxSprite().loadGraphic(frames);
    }
}