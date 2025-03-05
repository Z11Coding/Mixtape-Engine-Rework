package yutautil.save;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import sys.io.File;

class TestMixSaveWrapper extends TestCase {
    public function new() {
        super();
    }

    public function testSaveAndLoad():Void {
        var wrapper = new MixSaveWrapper();
        wrapper.addItem("testKey", "testValue");
        wrapper.save();

        var loadedWrapper = new MixSaveWrapper();
        loadedWrapper.load();
        assertEquals("testValue", loadedWrapper.getItem("testKey"));
    }

    public function testAddAndRemoveItem():Void {
        var wrapper = new MixSaveWrapper();
        wrapper.addItem("testKey", "testValue");
        assertTrue(wrapper.hasItem("testKey"));
        wrapper.removeItem("testKey");
        assertFalse(wrapper.hasItem("testKey"));
    }

    public function testEditItem():Void {
        var wrapper = new MixSaveWrapper();
        wrapper.addItem("testKey", "testValue");
        wrapper.editItem("testKey", "newValue");
        assertEquals("newValue", wrapper.getItem("testKey"));
    }

    public function testClear():Void {
        var wrapper = new MixSaveWrapper();
        wrapper.addItem("testKey", "testValue");
        wrapper.clear();
        assertFalse(wrapper.hasItem("testKey"));
    }

    public function testIsEmpty():Void {
        var wrapper = new MixSaveWrapper();
        assertTrue(wrapper.isEmpty());
        wrapper.addItem("testKey", "testValue");
        assertFalse(wrapper.isEmpty());
    }

    public function testToString():Void {
        var wrapper = new MixSaveWrapper();
        wrapper.addItem("testKey", "testValue");
        assertEquals("{testKey => testValue}", wrapper.toString());
    }

    public function testToMap():Void {
        var wrapper = new MixSaveWrapper();
        wrapper.addItem("testKey", "testValue");
        var map = wrapper.toMap();
        assertEquals("testValue", map.get("testKey"));
    }

    public function testToDynamic():Void {
        var wrapper = new MixSaveWrapper();
        wrapper.addItem("testKey", "testValue");
        var dyn = wrapper.toDynamic();
        assertEquals("testValue", Reflect.field(dyn, "testKey"));
    }

    public function testSaveToFile():Void {
        var filePath = "test_save_file.txt";
        var wrapper = new MixSaveWrapper();
        wrapper.addItem("testKey", "testValue");
        wrapper.saveToFile(filePath);

        var fileContent = File.getContent(filePath);
        assertTrue(fileContent.indexOf("testKey") != -1);
        assertTrue(fileContent.indexOf("testValue") != -1);

        File.deleteFile(filePath);
    }

    public function testLoadFromFile():Void {
        var filePath = "test_load_file.txt";
        var fileContent = '{"testKey":"testValue"}';
        File.saveContent(filePath, fileContent);

        var wrapper = new MixSaveWrapper();
        wrapper.loadFromFile(filePath);
        assertEquals("testValue", wrapper.getItem("testKey"));

        File.deleteFile(filePath);
    }

    public static function main() {
        var runner = new TestRunner();
        runner.add(new TestMixSaveWrapper());
        runner.run();
    }
}