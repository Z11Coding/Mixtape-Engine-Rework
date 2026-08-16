package yutautil.media;

enum abstract MediaPermissionState(String) from String to String {
    var UNKNOWN = "unknown";
    var GRANTED = "granted";
    var DENIED = "denied";
}

typedef MediaSupportSnapshot = {
    var cameraSupported:Bool;
    var microphoneSupported:Bool;
    var cameraPermission:MediaPermissionState;
    var microphonePermission:MediaPermissionState;
    var cameraCount:Int;
    var microphoneCount:Int;
    var defaultCameraName:String;
    var defaultMicrophoneName:String;
}

/**
 * Native camera/microphone support helper with C++ target support.
 * This class does not depend on browser APIs.
 */
class MediaDeviceSupport {
    static var _cameraPermission:MediaPermissionState = UNKNOWN;
    static var _microphonePermission:MediaPermissionState = UNKNOWN;

    #if (windows && cpp)
    @:cppFileCode('
        #include <windows.h>
        #include <mmsystem.h>
        #include <dshow.h>
        #include <string>

        #pragma comment(lib, "winmm.lib")
        #pragma comment(lib, "strmiids.lib")
        #pragma comment(lib, "ole32.lib")

        static std::string __yuta_wide_to_utf8(const wchar_t* source) {
            if (source == nullptr) return "";
            int len = WideCharToMultiByte(CP_UTF8, 0, source, -1, nullptr, 0, nullptr, nullptr);
            if (len <= 0) return "";
            std::string out;
            out.resize((size_t)len - 1);
            WideCharToMultiByte(CP_UTF8, 0, source, -1, &out[0], len, nullptr, nullptr);
            return out;
        }

        static int __yuta_get_microphone_count() {
            UINT count = waveInGetNumDevs();
            return (int)count;
        }

        static std::string __yuta_get_default_microphone_name() {
            WAVEINCAPSW caps;
            MMRESULT result = waveInGetDevCapsW(0, &caps, sizeof(WAVEINCAPSW));
            if (result != MMSYSERR_NOERROR) return "";
            return __yuta_wide_to_utf8(caps.szPname);
        }

        static int __yuta_get_camera_count() {
            int count = 0;

            HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
            bool didInitCom = SUCCEEDED(hr) || hr == RPC_E_CHANGED_MODE;
            if (!didInitCom) return 0;

            ICreateDevEnum* devEnum = nullptr;
            IEnumMoniker* enumMoniker = nullptr;

            hr = CoCreateInstance(CLSID_SystemDeviceEnum, nullptr, CLSCTX_INPROC_SERVER, IID_ICreateDevEnum, (void**)&devEnum);
            if (FAILED(hr) || devEnum == nullptr) {
                if (hr != RPC_E_CHANGED_MODE) CoUninitialize();
                return 0;
            }

            hr = devEnum->CreateClassEnumerator(CLSID_VideoInputDeviceCategory, &enumMoniker, 0);
            if (hr == S_OK && enumMoniker != nullptr) {
                IMoniker* moniker = nullptr;
                while (enumMoniker->Next(1, &moniker, nullptr) == S_OK) {
                    ++count;
                    moniker->Release();
                }
                enumMoniker->Release();
            }

            devEnum->Release();
            if (hr != RPC_E_CHANGED_MODE) CoUninitialize();
            return count;
        }

        static std::string __yuta_get_default_camera_name() {
            std::string name = "";

            HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
            bool didInitCom = SUCCEEDED(hr) || hr == RPC_E_CHANGED_MODE;
            if (!didInitCom) return "";

            ICreateDevEnum* devEnum = nullptr;
            IEnumMoniker* enumMoniker = nullptr;

            hr = CoCreateInstance(CLSID_SystemDeviceEnum, nullptr, CLSCTX_INPROC_SERVER, IID_ICreateDevEnum, (void**)&devEnum);
            if (FAILED(hr) || devEnum == nullptr) {
                if (hr != RPC_E_CHANGED_MODE) CoUninitialize();
                return "";
            }

            hr = devEnum->CreateClassEnumerator(CLSID_VideoInputDeviceCategory, &enumMoniker, 0);
            if (hr == S_OK && enumMoniker != nullptr) {
                IMoniker* moniker = nullptr;
                if (enumMoniker->Next(1, &moniker, nullptr) == S_OK) {
                    IPropertyBag* bag = nullptr;
                    hr = moniker->BindToStorage(nullptr, nullptr, IID_IPropertyBag, (void**)&bag);
                    if (SUCCEEDED(hr) && bag != nullptr) {
                        VARIANT var;
                        VariantInit(&var);
                        hr = bag->Read(L"FriendlyName", &var, nullptr);
                        if (SUCCEEDED(hr) && var.vt == VT_BSTR) {
                            name = __yuta_wide_to_utf8(var.bstrVal);
                        }
                        VariantClear(&var);
                        bag->Release();
                    }
                    moniker->Release();
                }
                enumMoniker->Release();
            }

            devEnum->Release();
            if (hr != RPC_E_CHANGED_MODE) CoUninitialize();
            return name;
        }
    ')
    #end

    public static inline function getCameraPermission():MediaPermissionState {
        return _cameraPermission;
    }

    public static inline function getMicrophonePermission():MediaPermissionState {
        return _microphonePermission;
    }

    public static function isCameraSupported():Bool {
        return getCameraCount() > 0;
    }

    public static function isMicrophoneSupported():Bool {
        return getMicrophoneCount() > 0;
    }

    public static function getCameraCount():Int {
        #if (windows && cpp)
        return nativeGetCameraCount();
        #else
        return 0;
        #end
    }

    public static function getMicrophoneCount():Int {
        #if (windows && cpp)
        return nativeGetMicrophoneCount();
        #else
        return 0;
        #end
    }

    public static function getDefaultCameraName():String {
        #if (windows && cpp)
        return nativeGetDefaultCameraName();
        #else
        return "";
        #end
    }

    public static function getDefaultMicrophoneName():String {
        #if (windows && cpp)
        return nativeGetDefaultMicrophoneName();
        #else
        return "";
        #end
    }

    public static function getSupportSnapshot():MediaSupportSnapshot {
        return {
            cameraSupported: isCameraSupported(),
            microphoneSupported: isMicrophoneSupported(),
            cameraPermission: _cameraPermission,
            microphonePermission: _microphonePermission,
            cameraCount: getCameraCount(),
            microphoneCount: getMicrophoneCount(),
            defaultCameraName: getDefaultCameraName(),
            defaultMicrophoneName: getDefaultMicrophoneName()
        };
    }

    public static function requestCameraPermission(onComplete:MediaPermissionState->Void):Void {
        var state = isCameraSupported() ? GRANTED : DENIED;
        _cameraPermission = state;
        if (onComplete != null) onComplete(state);
    }

    public static function requestMicrophonePermission(onComplete:MediaPermissionState->Void):Void {
        var state = isMicrophoneSupported() ? GRANTED : DENIED;
        _microphonePermission = state;
        if (onComplete != null) onComplete(state);
    }

    public static function requestAllPermissions(onComplete:MediaPermissionState->MediaPermissionState->Void):Void {
        requestCameraPermission(function(cameraState) {
            requestMicrophonePermission(function(microphoneState) {
                if (onComplete != null) onComplete(cameraState, microphoneState);
            });
        });
    }

    #if (windows && cpp)
    @:functionCode('return __yuta_get_camera_count();')
    static function nativeGetCameraCount():Int {
        return 0;
    }

    @:functionCode('return __yuta_get_microphone_count();')
    static function nativeGetMicrophoneCount():Int {
        return 0;
    }

    @:functionCode('return ::String(__yuta_get_default_camera_name().c_str());')
    static function nativeGetDefaultCameraName():String {
        return "";
    }

    @:functionCode('return ::String(__yuta_get_default_microphone_name().c_str());')
    static function nativeGetDefaultMicrophoneName():String {
        return "";
    }
    #end
}
