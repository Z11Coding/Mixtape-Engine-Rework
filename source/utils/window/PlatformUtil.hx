package utils.window;

#if windows
@:cppFileCode('
#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include <winuser.h>
#include <dwmapi.h>
#include <strsafe.h>
#include <shellapi.h>
#include <iostream>
#include <string>

// Link the required libraries
#pragma comment(lib, "Shell32.lib")

// Function prototype for SetCurrentProcessExplicitAppUserModelID
extern "C" HRESULT WINAPI SetCurrentProcessExplicitAppUserModelID(PCWSTR AppID);

NOTIFYICONDATA m_NID;

// Constants for notification
const int NOTIFICATION_ID = 1001;
const wchar_t* APP_ID = L"com.psychengine.custommod";

// Set a custom AppUserModelID for the game process
void SetAppID() {
    HRESULT hr = SetCurrentProcessExplicitAppUserModelID(APP_ID);
    if (FAILED(hr)) {
        std::cerr << "Error: Failed to set AppUserModelID." << std::endl;
    }
}

// Initialize NOTIFYICONDATA structure
void InitNotifyIconData(HWND hWnd) {
    memset(&m_NID, 0, sizeof(m_NID));
    m_NID.cbSize = sizeof(NOTIFYICONDATA);
    m_NID.hWnd = hWnd;
    m_NID.uID = NOTIFICATION_ID;
    m_NID.uFlags = NIF_MESSAGE | NIF_INFO | NIF_TIP;
    m_NID.uCallbackMessage = WM_USER + 1;
    m_NID.dwInfoFlags = NIIF_INFO;
    m_NID.uVersion = NOTIFYICON_VERSION_4;

    StringCchCopy(m_NID.szTip, sizeof(m_NID.szTip) / sizeof(TCHAR), "Psych Engine Notification");
}

// Show the notification
bool ShowNotification(const std::string& title, const std::string& desc) {
    SetAppID(); // Ensure the custom AppUser ModelID is set

    HWND hWnd = GetForegroundWindow(); // Use the current game window
    InitNotifyIconData(hWnd);

    StringCchCopy(m_NID.szInfoTitle, sizeof(m_NID.szInfoTitle) / sizeof(TCHAR), title.c_str());
    StringCchCopy(m_NID.szInfo, sizeof(m_NID.szInfo) / sizeof(TCHAR), desc.c_str());

    if (!Shell_NotifyIcon(NIM_ADD, &m_NID)) {
        std::cerr << "Error: Failed to add notification icon." << std::endl;
        return false;
    }

    // Modify the notification
    if (!Shell_NotifyIcon(NIM_MODIFY, &m_NID)) {
        std::cerr << "Error: Failed to modify notification." << std::endl;
        return false;
    }

    // Clean up after showing the notification
    return Shell_NotifyIcon(NIM_DELETE, &m_NID);
}
')
#end

class PlatformUtil {
    #if windows
    @:functionCode('
        return ShowNotification(title.c_str(), desc.c_str());
    ')
    #end

    static public function sendWindowsNotification(title:String = "", desc:String = ""):Bool {
        return true; // Actual logic is handled by C++ code
    }
}
