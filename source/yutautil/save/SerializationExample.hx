package yutautil.save;

import yutautil.save.StateSerializer;
import yutautil.save.ObjectSerializer;
import flixel.FlxState;
import flixel.FlxSprite;

/**
 * Test class with nested objects and potential circular references
 */
class ComplexTestObject {
    public var name:String;
    public var value:Int;
    public var nested:NestedObject;
    public var children:Array<NestedObject>;
    public var parent:ComplexTestObject; // Potential circular reference
    
    public function new(name:String, value:Int) {
        this.name = name;
        this.value = value;
        this.children = [];
    }
    
    public function addChild(child:NestedObject):Void {
        children.push(child);
        child.parent = this;
    }
}

/**
 * Nested object class for testing
 */
class NestedObject {
    public var id:String;
    public var data:Map<String, Dynamic>;
    public var parent:ComplexTestObject;
    public var deeply:DeeplyNestedObject;
    
    public function new(id:String) {
        this.id = id;
        this.data = new Map();
    }
}

/**
 * Deeply nested object for testing recursion limits
 */
class DeeplyNestedObject {
    public var level:Int;
    public var description:String;
    public var deeper:DeeplyNestedObject;
    
    public function new(level:Int, description:String) {
        this.level = level;
        this.description = description;
    }
}

/**
 * Examples and tests for the advanced queue-based serialization system.
 * Demonstrates how to use StateSerializer and ObjectSerializer with complex object graphs.
 */
class SerializationExample {
    
    /**
     * Run all serialization examples and tests
     * @param testType Optional specific test to run
     */
    public static function runAllTests(?testType:String):Void {
        trace("=== Running Advanced Serialization Tests ===");
        
        if (testType != null) {
            switch (testType) {
                case "complex":
                    testComplexObjectSerialization();
                case "circular":
                    testCircularReferences();
                case "deep":
                    testDeepNesting();
                case "state":
                    testStateSerialization();
                case "performance":
                    testPerformance();
                case "validation":
                    testValidation();
                case "basic":
                    testBasicSerialization();
                case "clone":
                    testDeepCloning();
                case "mixsave":
                    testMixSaveIntegration();
                case "demo":
                    demonstrateStateSaving();
                default:
                    trace('Unknown test type: ${testType}');
                    return;
            }
        } else {
            trace("Running all test suites...");
            testBasicSerialization();
            testComplexObjectSerialization();
            testCircularReferences();
            testDeepNesting();
            testDeepCloning();
            testMixSaveIntegration();
            testStateSerialization();
            testPerformance();
            testValidation();
            demonstrateStateSaving();
        }
        
        trace("=== All Tests Completed ===");
    }
    
    /**
     * Test serialization of complex objects with nested structures
     */
    public static function testComplexObjectSerialization():Void {
        trace("\n--- Testing Complex Object Serialization ---");
        
        try {
            // Create a complex object
            var mainObj = new ComplexTestObject("MainObject", 42);
            
            // Add nested objects
            var child1 = new NestedObject("child1");
            child1.data.set("type", "child");
            child1.data.set("priority", 1);
            child1.deeply = new DeeplyNestedObject(1, "First level");
            child1.deeply.deeper = new DeeplyNestedObject(2, "Second level");
            
            var child2 = new NestedObject("child2");
            child2.data.set("type", "child");
            child2.data.set("priority", 2);
            child2.deeply = new DeeplyNestedObject(1, "Another first level");
            
            mainObj.addChild(child1);
            mainObj.addChild(child2);
            
            mainObj.nested = new NestedObject("direct_nested");
            mainObj.nested.data.set("direct", true);
            
            // Serialize
            var serialized = ObjectSerializer.serialize(mainObj);
            trace('Serialization successful: ${serialized != null}');
            
            if (serialized != null) {
                var metadata = ObjectSerializer.getMetadata(serialized);
                trace('Objects serialized: ${metadata.queuedObjectCount + 1}');
                trace('Description: ${ObjectSerializer.getDescription(serialized)}');
                
                // Deserialize
                var restored:ComplexTestObject = cast ObjectSerializer.deserialize(serialized);
                trace('Deserialization successful: ${restored != null}');
                
                if (restored != null) {
                    trace('Restored name: ${restored.name}');
                    trace('Restored value: ${restored.value}');
                    trace('Children count: ${restored.children.length}');
                    
                    for (i in 0...restored.children.length) {
                        var child = restored.children[i];
                        trace('Child ${i}: ${child.id}, data keys: ${Lambda.count(child.data)}');
                        if (child.deeply != null) {
                            trace('  Deep level: ${child.deeply.level}, desc: ${child.deeply.description}');
                            if (child.deeply.deeper != null) {
                                trace('  Deeper level: ${child.deeply.deeper.level}');
                            }
                        }
                    }
                }
            }
            
        } catch (e:Dynamic) {
            trace('Error in complex object test: ${e}');
        }
    }
    
    /**
     * Test handling of circular references
     */
    public static function testCircularReferences():Void {
        trace("\n--- Testing Circular References ---");
        
        try {
            var obj1 = new ComplexTestObject("Object1", 1);
            var obj2 = new ComplexTestObject("Object2", 2);
            
            // Create circular reference
            obj1.parent = obj2;
            obj2.parent = obj1;
            
            var nested = new NestedObject("circular_nested");
            obj1.nested = nested;
            nested.parent = obj1; // Another circular reference
            
            // Serialize
            var serialized = ObjectSerializer.serialize(obj1);
            trace('Circular reference serialization: ${serialized != null}');
            
            if (serialized != null) {
                var metadata = ObjectSerializer.getMetadata(serialized);
                if (metadata.metadata != null && Reflect.hasField(metadata.metadata, "hasCircularRefs")) {
                    trace('Circular references detected: ${Reflect.field(metadata.metadata, "hasCircularRefs")}');
                }
                
                // Deserialize
                var restored:ComplexTestObject = cast ObjectSerializer.deserialize(serialized);
                trace('Circular reference deserialization: ${restored != null}');
                
                if (restored != null) {
                    trace('Restored object name: ${restored.name}');
                    trace('Has parent: ${restored.parent != null}');
                    if (restored.parent != null) {
                        trace('Parent name: ${restored.parent.name}');
                        trace('Parent has parent: ${restored.parent.parent != null}');
                        // Check if circular reference is properly restored
                        if (restored.parent.parent != null) {
                            trace('Circular reference restored: ${restored.parent.parent.name == restored.name}');
                        }
                    }
                }
            }
            
        } catch (e:Dynamic) {
            trace('Error in circular reference test: ${e}');
        }
    }
    
    /**
     * Test deep nesting with queue-based processing
     */
    public static function testDeepNesting():Void {
        trace("\n--- Testing Deep Nesting ---");
        
        try {
            var root = new DeeplyNestedObject(0, "Root");
            var current = root;
            
            // Create a chain of 20 nested objects
            for (i in 1...20) {
                current.deeper = new DeeplyNestedObject(i, 'Level ${i}');
                current = current.deeper;
            }
            
            var serialized = ObjectSerializer.serialize(root);
            trace('Deep nesting serialization: ${serialized != null}');
            
            if (serialized != null) {
                var metadata = ObjectSerializer.getMetadata(serialized);
                trace('Max depth: ${Reflect.field(metadata.metadata, "maxDepth")}');
                
                var restored:DeeplyNestedObject = cast ObjectSerializer.deserialize(serialized);
                trace('Deep nesting deserialization: ${restored != null}');
                
                if (restored != null) {
                    var depth = 0;
                    var curr = restored;
                    while (curr != null) {
                        depth++;
                        curr = curr.deeper;
                    }
                    trace('Restored depth: ${depth}');
                }
            }
            
        } catch (e:Dynamic) {
            trace('Error in deep nesting test: ${e}');
        }
    }
    
    /**
     * Test state serialization
     */
    public static function testStateSerialization():Void {
        trace("\n--- Testing State Serialization ---");
        // Note: This would require an actual FlxState instance
        trace("State serialization tests require a running FlxG.state");
    }
    
    /**
     * Test performance with large object graphs
     */
    public static function testPerformance():Void {
        trace("\n--- Testing Performance ---");
        
        try {
            var startTime = haxe.Timer.stamp();
            
            // Create a large object graph
            var root = new ComplexTestObject("PerformanceRoot", 0);
            for (i in 0...100) {
                var child = new NestedObject('child_${i}');
                child.data.set("index", i);
                child.data.set("data", 'Large data string for child ${i}');
                root.addChild(child);
            }
            
            var createTime = haxe.Timer.stamp();
            trace('Object creation time: ${Math.round((createTime - startTime) * 1000)}ms');
            
            // Serialize
            var serialized = ObjectSerializer.serialize(root);
            var serializeTime = haxe.Timer.stamp();
            trace('Serialization time: ${Math.round((serializeTime - createTime) * 1000)}ms');
            
            // Deserialize
            var restored = ObjectSerializer.deserialize(serialized);
            var deserializeTime = haxe.Timer.stamp();
            trace('Deserialization time: ${Math.round((deserializeTime - serializeTime) * 1000)}ms');
            
            trace('Total time: ${Math.round((deserializeTime - startTime) * 1000)}ms');
            
        } catch (e:Dynamic) {
            trace('Error in performance test: ${e}');
        }
    }
    
    /**
     * Test validation functions
     */
    public static function testValidation():Void {
        trace("\n--- Testing Validation ---");
        
        try {
            var testObj = new ComplexTestObject("ValidationTest", 42);
            
            // Test canSerialize
            var canSerialize = ObjectSerializer.canSerialize(testObj);
            trace('Can serialize test object: ${canSerialize}');
            
            // Test serialization validation
            var serialized = ObjectSerializer.serialize(testObj);
            if (serialized != null) {
                var isValid = ObjectSerializer.validateSerialization(serialized);
                trace('Serialization is valid: ${isValid}');
                
                var metadata = ObjectSerializer.getMetadata(serialized);
                trace('Metadata retrieved: ${metadata != null}');
            }
            
        } catch (e:Dynamic) {
            trace('Error in validation test: ${e}');
        }
    }
    
    /**
     * Test basic serialization functionality
     */
    public static function testBasicSerialization():Void {
        trace("\n--- Testing Basic Serialization ---");
        
        try {
            // Test simple object
            var simpleObj = new ComplexTestObject("SimpleTest", 123);
            simpleObj.nested = new NestedObject("simple_nested");
            simpleObj.nested.data.set("test", "value");
            
            var serialized = ObjectSerializer.serialize(simpleObj);
            trace('Basic serialization successful: ${serialized != null}');
            
            if (serialized != null) {
                var restored:ComplexTestObject = cast ObjectSerializer.deserialize(serialized);
                trace('Basic deserialization successful: ${restored != null}');
                
                if (restored != null) {
                    trace('Name matches: ${restored.name == simpleObj.name}');
                    trace('Value matches: ${restored.value == simpleObj.value}');
                    trace('Nested data matches: ${restored.nested != null && restored.nested.data.get("test") == "value"}');
                }
            }
            
        } catch (e:Dynamic) {
            trace('Error in basic serialization test: ${e}');
        }
    }
    
    /**
     * Test deep cloning functionality
     */
    public static function testDeepCloning():Void {
        trace("\n--- Testing Deep Cloning ---");
        
        try {
            var original = new ComplexTestObject("Original", 456);
            var child = new NestedObject("child");
            child.data.set("original", true);
            original.addChild(child);
            
            // Test deep clone
            var clone = ObjectSerializer.deepClone(original);
            trace('Deep clone successful: ${clone != null}');
            
            if (clone != null) {
                var clonedObj:ComplexTestObject = cast clone;
                trace('Clone name matches: ${clonedObj.name == original.name}');
                trace('Clone value matches: ${clonedObj.value == original.value}');
                trace('Clone is different object: ${clonedObj != original}');
                trace('Clone children count: ${clonedObj.children.length}');
                
                // Modify original to test independence
                original.name = "Modified";
                original.children[0].data.set("modified", true);
                
                trace('Original modified, clone unchanged: ${clonedObj.name == "Original"}');
                trace('Clone child data unchanged: ${!clonedObj.children[0].data.exists("modified")}');
            }
            
        } catch (e:Dynamic) {
            trace('Error in deep cloning test: ${e}');
        }
    }
    
    /**
     * Test MixSave integration
     */
    public static function testMixSaveIntegration():Void {
        trace("\n--- Testing MixSave Integration ---");
        
        try {
            // Create test objects
            var testObj1 = new ComplexTestObject("MixSaveTest1", 789);
            var testObj2 = new ComplexTestObject("MixSaveTest2", 012);
            
            // Test saving to MixSave
            var mixSave = new backend.MixSave();
            var savedMixSave1 = ObjectSerializer.saveToMixSave(testObj1, "test_obj_1", mixSave);
            var savedMixSave2 = ObjectSerializer.saveToMixSave(testObj2, "test_obj_2", savedMixSave1);
            
            trace('MixSave integration save successful: ${savedMixSave2 != null}');
            
            if (savedMixSave2 != null) {
                // Test loading from MixSave
                var loaded1:ComplexTestObject = cast ObjectSerializer.loadFromMixSave("test_obj_1", savedMixSave2);
                var loaded2:ComplexTestObject = cast ObjectSerializer.loadFromMixSave("test_obj_2", savedMixSave2);
                
                trace('MixSave load 1 successful: ${loaded1 != null && loaded1.name == "MixSaveTest1"}');
                trace('MixSave load 2 successful: ${loaded2 != null && loaded2.name == "MixSaveTest2"}');
                
                // Test file saving
                var success = ObjectSerializer.saveToFile(testObj1, "file_test", "save/test_serialization.json");
                trace('File save successful: ${success}');
                
                if (success) {
                    var loadedFromFile:ComplexTestObject = cast ObjectSerializer.loadFromFile("file_test", "save/test_serialization.json");
                    trace('File load successful: ${loadedFromFile != null && loadedFromFile.name == "MixSaveTest1"}');
                }
            }
            
        } catch (e:Dynamic) {
            trace('Error in MixSave integration test: ${e}');
        }
    }
    
    /**
     * Demonstrate state saving functionality
     */
    public static function demonstrateStateSaving():Void {
        trace("\n--- Demonstrating State Saving ---");
        
        try {
            // Create a complex demo object
            var demoState = new ComplexTestObject("DemoState", 999);
            
            // Add multiple nested objects
            for (i in 0...5) {
                var child = new NestedObject('demo_child_${i}');
                child.data.set("index", i);
                child.data.set("description", 'Demo child number ${i}');
                child.deeply = new DeeplyNestedObject(i, 'Demo deep level ${i}');
                demoState.addChild(child);
            }
            
            // Serialize and show information
            var serialized = ObjectSerializer.serialize(demoState);
            trace('Demo state serialization: ${serialized != null}');
            
            if (serialized != null) {
                var metadata = ObjectSerializer.getMetadata(serialized);
                var description = ObjectSerializer.getDescription(serialized);
                
                trace('Demo State Information:');
                trace('  ${description}');
                trace('  Class: ${metadata.className}');
                trace('  Total Objects: ${metadata.queuedObjectCount + 1}');
                trace('  Object Types: ${metadata.metadata.objectTypes.join(", ")}');
                trace('  Has Circular References: ${metadata.metadata.hasCircularRefs}');
                trace('  Serializer Version: ${metadata.version}');
                
                // Test restoration
                var restored:ComplexTestObject = cast ObjectSerializer.deserialize(serialized);
                trace('Demo state restoration: ${restored != null}');
                
                if (restored != null) {
                    trace('  Restored children: ${restored.children.length}');
                    for (i in 0...restored.children.length) {
                        var child = restored.children[i];
                        trace('    Child ${i}: ${child.id} (${child.data.get("description")})');
                    }
                }
                
                // Show validation
                var isValid = ObjectSerializer.validateSerialization(serialized);
                trace('Serialization validation: ${isValid ? "PASSED" : "FAILED"}');
            }
            
        } catch (e:Dynamic) {
            trace('Error in state saving demonstration: ${e}');
        }
    }
    
    /**
     * Get a summary of all test results
     * @return Test summary string
     */
    public static function getTestSummary():String {
        return "Serialization system tests include:\n" +
               "- Complex object serialization with nested structures\n" +
               "- Circular reference detection and handling\n" +
               "- Deep nesting with queue-based processing\n" +
               "- State serialization and file operations\n" +
               "- Performance testing with large object graphs\n" +
               "- Validation and compatibility testing\n" +
               "\nUse 'testSerialization <type>' to run specific tests.";
    }
}
