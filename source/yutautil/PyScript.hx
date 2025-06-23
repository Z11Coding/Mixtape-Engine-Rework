
package yutautil;

#if cpp
import cpp.Lib;
import cpp.Pointer;
import cpp.Native;
import haxe.Json;
import sys.io.File;

class Pycript {
    // Python version info
    public static var pythonVersion(default, null):String;
    public static var pythonInitialized(default, null):Bool = false;
    
    // Script management
    private var moduleName:String;
    private var module:Dynamic;
    private var callbacks:Map<String, String> = new Map();
    private var transformCallbackNames:Bool = true;

    // Initialize Python interpreter
    public static function initPython() {
        if (pythonInitialized) return;
        
        untyped __cpp__("
            Py_Initialize();
            PyEval_InitThreads(); // Initialize and acquire GIL
        ");
        
        // Get Python version
        untyped __cpp__("
            char version[128];
            snprintf(version, sizeof(version), \"Python %d.%d.%d\", 
                PY_MAJOR_VERSION, PY_MINOR_VERSION, PY_MICRO_VERSION);
        ");
        pythonVersion = untyped __cpp__('version');
        
        pythonInitialized = true;
        trace('Python initialized: $pythonVersion');
    }

    // Constructor - Loads Python script
    public function new(scriptPath:String, moduleName:String) {
        if (!pythonInitialized) initPython();
        this.moduleName = moduleName;
        
        // Execute script in isolated module
        var scriptContent = File.getContent(scriptPath);
        untyped __cpp__('
            // Create new module
            PyObject *module = PyModule_New("{0}");
            PyModule_AddStringConstant(module, "__file__", "{1}");
            
            // Add to sys.modules
            PyObject *sys_modules = PyImport_GetModuleDict();
            PyDict_SetItemString(sys_modules, "{0}", module);
            
            // Execute script in module context
            PyObject *globals = PyModule_GetDict(module);
            PyRun_StringFlags(
                {2}, Py_file_input, 
                globals, globals, NULL
            );
            
            // Store module reference
            {3} = module;
        ', moduleName, scriptPath, scriptContent, cpp.Pointer.addressOf(module));
        
        // Call main function if exists
        if (functionExists("main")) {
            callFunction("main", []);
        }
    }

    // Set callback name transformation (onNoteHit -> on_note_hit)
    public function setTransformCallbackNames(transform:Bool) {
        transformCallbackNames = transform;
    }

    // Expose Haxe object to Python
    public function expose(name:String, obj:Dynamic) {
        var json = Json.stringify(obj);
        untyped __cpp__('
            PyObject *pyObj = PyUnicode_FromString({0});
            PyObject *module = {1};
            PyObject *dict = PyModule_GetDict(module);
            PyDict_SetItemString(dict, {2}, pyObj);
            Py_DECREF(pyObj);
        ', json, module, name);
    }

    // Call Python function
    public function callFunction(funcName:String, args:Array<Dynamic>):Dynamic {
        if (!functionExists(funcName)) return null;
        
        var jsonArgs = Json.stringify(args);
        var result:Dynamic = null;
        
        untyped __cpp__('
            PyGILState_STATE gstate = PyGILState_Ensure();
            
            try {
                PyObject *module = {0};
                PyObject *func = PyObject_GetAttrString(module, {1});
                
                if (func && PyCallable_Check(func)) {
                    // Convert Haxe args to Python tuple
                    PyObject *pyArgs = PyTuple_New({2});
                    for (int i = 0; i < {2}; i++) {
                        PyObject *item = PyUnicode_FromString({3}[i]);
                        PyTuple_SetItem(pyArgs, i, item);
                    }
                    
                    // Call function
                    PyObject *pyResult = PyObject_CallObject(func, pyArgs);
                    
                    // Convert result to JSON string
                    if (pyResult) {
                        PyObject *json = PyObject_CallMethod(pyResult, "__str__", NULL);
                        {4} = PyUnicode_AsUTF8(json);
                        Py_DECREF(json);
                        Py_DECREF(pyResult);
                    }
                    
                    Py_DECREF(pyArgs);
                    Py_DECREF(func);
                }
            } catch (...) {
                PyErr_Print();
            }
            
            PyGILState_Release(gstate);
        ', module, funcName, args.length, jsonArgs, cpp.Pointer.addressOf(result));
        
        try {
            return Json.parse(result);
        } catch (e:Dynamic) {
            return result;
        }
    }

    // Register callback handler
    public function registerCallback(eventName:String, ?pyFunctionName:String) {
        if (pyFunctionName == null) {
            pyFunctionName = transformCallbackNames ? 
                StringTools.replace(eventName, "on", "on_").toLowerCase() : 
                eventName;
        }
        callbacks.set(eventName, pyFunctionName);
    }

    // Trigger callback
    public function triggerCallback(eventName:String, args:Array<Dynamic>) {
        var funcName = callbacks.get(eventName);
        if (funcName != null && functionExists(funcName)) {
            callFunction(funcName, args);
        }
    }

    // Check if function exists
    public function functionExists(funcName:String):Bool {
        var exists = false;
        untyped __cpp__('
            PyObject *module = {0};
            exists = (PyObject_HasAttrString(module, {1}) == 1;
        ', module, funcName, cpp.Pointer.addressOf(exists));
        return exists;
    }

    // Clean up resources
    public function destroy() {
        untyped __cpp__('
            PyGILState_STATE gstate = PyGILState_Ensure();
            Py_DECREF({0});
            PyGILState_Release(gstate);
        ', module);
    }
}
#end