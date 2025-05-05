package yutautil;

// import yutautil.SyncUtils;

class PointerTools {
    public function new() {
        // Constructor for the PointerTools class
    }

    // public function getPointerAddress<T>(pointer:cpp.RawConstPointer<T>):Int {
    //     return pointer.addressOf(); // Get the address of the pointer
    // }

    // public function getPointerValue<T>(pointer:cpp.RawConstPointer<T>):T {
    //     return pointer[0]; // Get the value at the pointer address
    // }

    // public function setPointerValue<T>(pointer:cpp.RawConstPointer<T>, value:T):Void {
    //     pointer[0] = value; // Set the value at the pointer address
    // }

    // public function isPointerNull<T>(pointer:cpp.RawConstPointer<T>):Bool {
    //     return pointer == null; // Check if the pointer is null
    // }

    // public function isPointerValid<T>(pointer:cpp.RawConstPointer<T>):Bool {
    //     return pointer != null; // Check if the pointer is valid (not null)
    // }

    // public function getPointerSize<T>(raw:T):Int {
    //     return cpp.RawConstPointer<T>.size(); // Get the size of the pointer type
    // }

    public static inline function pointer<T>(e:T)
    {
        return cpp.RawPointer.addressOf(e); // Get the address of the pointer
    }
}