package trolllua.os;

#if windows
import backend.util.NativeAPI.FileAttribute;

enum abstract MessageBoxOptions(Int) to Int {
	var OK					= 0x00000000;
	var OKCANCEL			= 0x00000001;
	var ABORTRETRYIGNORE	= 0x00000002;
	var YESNOCANCEL			= 0x00000003;
	var YESNO				= 0x00000004;
	var RETRYCANCEL			= 0x00000005;
	var CANCELTRYCONTINUE	= 0x00000006;
	//var HELP				= 0x00004000;
}

enum abstract MessageBoxIcon(Int) to Int {
	var NONE		= 0x00000000;
	var STOP		= 0x00000010;
	var ERROR		= 0x00000010;
	var HAND		= 0x00000010;
	var QUESTION	= 0x00000020;
	var EXCLAMATION	= 0x00000030;
	var WARNING		= 0x00000030;
	var INFORMATION	= 0x00000040;
	var ASTERISK	= 0x00000040;
}

enum abstract MessageBoxDefaultButton(Int) to Int {
	var BUTTON1 = 0x00000000;
	var BUTTON2 = 0x00000100;
	var BUTTON3 = 0x00000200;
	var BUTTON4 = 0x00000300;
}

enum abstract MessageBoxReturnValue(Int) from Int to Int {
	var OK = 1;
	var CANCEL = 2;
	var ABORT = 3;
	var RETRY = 4;
	var IGNORE = 5;
	var YES = 6;
	var NO = 7;
	var TRYAGAIN = 10;
	var CONTINUE = 11;
}

@:buildXml('
<target id="haxe">
	<lib name="dwmapi.lib" if="windows" />
	<lib name="shell32.lib" if="windows" />
	<lib name="gdi32.lib" if="windows" />
	<lib name="ole32.lib" if="windows" />
	<lib name="uxtheme.lib" if="windows" />
</target>
')

// majority is taken from microsofts doc
@:cppFileCode('
#include "mmdeviceapi.h"
#include "combaseapi.h"
#include <iostream>
#include <Windows.h>
#include <cstdio>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <Shlobj.h>
#include <wingdi.h>
#include <shellapi.h>
#include <uxtheme.h>

#define SAFE_RELEASE(punk)  \\
			  if ((punk) != NULL)  \\
				{ (punk)->Release(); (punk) = NULL; }

static long lastDefId = 0;

class AudioFixClient : public IMMNotificationClient {
	LONG _cRef;
	IMMDeviceEnumerator *_pEnumerator;

	public:
	AudioFixClient() :
		_cRef(1),
		_pEnumerator(NULL)
	{
		HRESULT result = CoCreateInstance(__uuidof(MMDeviceEnumerator),
							  NULL, CLSCTX_INPROC_SERVER,
							  __uuidof(IMMDeviceEnumerator),
							  (void**)&_pEnumerator);
		if (result == S_OK) {
			_pEnumerator->RegisterEndpointNotificationCallback(this);
		}
	}

	~AudioFixClient()
	{
		SAFE_RELEASE(_pEnumerator);
	}

	ULONG STDMETHODCALLTYPE AddRef()
	{
		return InterlockedIncrement(&_cRef);
	}

	ULONG STDMETHODCALLTYPE Release()
	{
		ULONG ulRef = InterlockedDecrement(&_cRef);
		if (0 == ulRef)
		{
			delete this;
		}
		return ulRef;
	}

	HRESULT STDMETHODCALLTYPE QueryInterface(
								REFIID riid, VOID **ppvInterface)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceAdded(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	};

	HRESULT STDMETHODCALLTYPE OnDeviceRemoved(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceStateChanged(
								LPCWSTR pwstrDeviceId,
								DWORD dwNewState)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnPropertyValueChanged(
								LPCWSTR pwstrDeviceId,
								const PROPERTYKEY key)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDefaultDeviceChanged(
		EDataFlow flow, ERole role,
		LPCWSTR pwstrDeviceId)
	{
		::Main_obj::audioDisconnected = true;
		return S_OK;
	};
};

AudioFixClient *curAudioFix;
')
@:dox(hide)
class Windows {

	public static var __audioChangeCallback:Void->Void = function() {
		trace("test");
	};


	@:functionCode('
	if (!curAudioFix) curAudioFix = new AudioFixClient();
	')
	public static function registerAudio() {
		Main.audioDisconnected = false;
	}

	@:functionCode('
		int darkMode = enable ? 1 : 0;

		HWND window = FindWindowA(NULL, title.c_str());
		// Look for child windows if top level aint found
		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());

		if (window != NULL && S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
			DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
		}
	')
	public static function setDarkMode(title:String, enable:Bool) {}

	@:functionCode('
	// https://stackoverflow.com/questions/15543571/allocconsole-not-displaying-cout

	if (!AllocConsole())
		return;

	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);
	')
	public static function allocConsole() {
	}

	@:functionCode('
		return GetFileAttributes(path);
	')
	public static function getFileAttributes(path:String):FileAttribute
	{
		return NORMAL;
	}

	@:functionCode('
		return SetFileAttributes(path, attrib);
	')
	public static function setFileAttributes(path:String, attrib:FileAttribute):Int
	{
		return 0;
	}


	@:functionCode('
		HANDLE console = GetStdHandle(STD_OUTPUT_HANDLE);
		SetConsoleTextAttribute(console, color);
	')
	public static function setConsoleColors(color:Int) {

	}

	@:functionCode('
		system("CLS");
		std::cout<< "" <<std::flush;
	')
	public static function clearScreen() {

	}

	@:functionCode('
		SetProcessDPIAware();
	')
	public static function registerAsDPICompatible() {}

	@:functionCode("
		// simple but effective code
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return (allocatedRAM / 1024);
	")
	public static function getTotalRam():Float
	{
		return 0;
	}

	public static function msgBox(message:String = "", title:String = "", sowyType:Int = 0):MessageBoxReturnValue
		return untyped MessageBox(NULL, message, title, sowyType | 0x00010000);
}
#end