<#
Скрипт для полуения расширенной информации о процессах по аналогии с диспетчером задач.
Плюс добавлены некоторые доп. метрики.

Например:
PeriodUTC           : 19.06.2022 8:23:47
HostName            : YY-COMP
ProcessName         : Telegram
PID                 : 4836
StartTime           : 19.06.2022 11:13:48
Status              : Running
UserName            : 
SessionId           : 
CPU                 : 5,78125
CPUPercent          : 0
PrivateMemorySize64 : 228593664
WorkingSet64        : 119939072
Path                : C:\Users\ypermitin\AppData\Roaming\Telegram Desktop\Telegram.exe
CommandLine         : "C:\Users\ypermitin\AppData\Roaming\Telegram Desktop\Telegram.exe"
Description         : Telegram Desktop
WindowTitle         : Telegram (2)
#>

# Регистрация служебных типов для обращения к WinAPI
function RegisterType()
{
    $def = @"
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Text; 

namespace pinvoke {
    public enum GetWindow_Cmd : uint {
        GW_HWNDFIRST = 0,
        GW_HWNDLAST = 1,
        GW_HWNDNEXT = 2,
        GW_HWNDPREV = 3,
        GW_OWNER = 4,
        GW_CHILD = 5,
        GW_ENABLEDPOPUP = 6
    }
    
    public class User32 {
        // ***** Unmanaged DLL Access *****
        private class unmanaged {
            // EnumWindows
            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            internal static extern bool EnumWindows(EnumWindowsProcD lpEnumFunc, ref IntPtr lParam);
    
            // GetWindow
            [DllImport("user32.dll", SetLastError = true)]
            internal static extern IntPtr GetWindow(IntPtr hWnd, GetWindow_Cmd uCmd);
        
            // GetWindowText
            [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            internal static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

            // GetWindowTextLength
            [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
            internal static extern int GetWindowTextLength(IntPtr hWnd);

            // IsWindowEnabled
            [DllImport("user32.dll", SetLastError=true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            internal static extern bool IsWindowEnabled(IntPtr hWnd);

            // IsWindowVisible
            [DllImport("user32.dll")]
            internal static extern bool IsWindowVisible(IntPtr hWnd);

            [DllImport("user32.dll", SetLastError=true)]
            [return: MarshalAs(UnmanagedType.U4)]
            internal static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
        }

        // ***** Callback function delegates *****
        private delegate bool EnumWindowsProcD(IntPtr hWnd, ref IntPtr lItems);       

        // ***** Callback function for EnumChildWindows and EnumWindows *****
        private static bool EnumWindowsProc(IntPtr hWnd, ref IntPtr lItems) {
            if(hWnd != IntPtr.Zero) {
                GCHandle hItems = GCHandle.FromIntPtr(lItems);
                List<IntPtr> items = hItems.Target as List<IntPtr>;
                items.Add(hWnd);
                return true;
            } else {
                return false;
            }
        }

        // ***** Functions *****
        // EnumWindows
        public static List<IntPtr> EnumWindows() {
            try {
                List<IntPtr> items = new List<IntPtr>();
                EnumWindowsProcD CallBackPtr = new EnumWindowsProcD(User32.EnumWindowsProc);
                GCHandle hItems = GCHandle.Alloc(items);
                IntPtr lItems = GCHandle.ToIntPtr(hItems);
                unmanaged.EnumWindows(CallBackPtr, ref lItems);
                return items;
            } catch (Exception ex) {
                throw new Exception("An Error has occured during enumeration: " + ex.Message);
            }
        }
        
        // GetWindowText
        public static string GetWindowText(IntPtr hWnd) {
            int iTextLength = unmanaged.GetWindowTextLength(hWnd);
            if(iTextLength > 0) {
                StringBuilder sb = new StringBuilder(iTextLength);
                unmanaged.GetWindowText(hWnd, sb, iTextLength + 1);
                return sb.ToString();
            } else {
                return String.Empty;
            }
        }

        // IsWindowEnabled
        public static bool IsWindowEnabled(IntPtr hWnd) {
            return IsWindowEnabled(hWnd);
       }

        // IsWindowVisible
        public static bool IsWindowVisible(IntPtr hWnd) {
            return unmanaged.IsWindowVisible(hWnd);
        }

        // GetWindowProcessId
        public static uint GetWindowProcessId(IntPtr hWnd) {
            uint processId;
            unmanaged.GetWindowThreadProcessId(hWnd, out processId);

            return processId;
        }
    }
}
"@

    if(-not ([System.Management.Automation.PSTypeName]"pinvoke.user32").Type) {
        Add-Type -TypeDefinition $def
    }
}

# Функция получения открытых окон в текущей сессии пользователя Windows
function GetOpenWindows()
{
    $procsTitle = new-object "System.Collections.Generic.Dictionary[[int],[string]]"
    
    [pinvoke.User32]::EnumWindows() | ForEach-Object {
        if([pinvoke.User32]::IsWindowVisible($_))
        {
            $windowHandle = $_
            $windowTitle = [pinvoke.User32]::GetWindowText($windowHandle)
            $processId = [pinvoke.User32]::GetWindowProcessId($windowHandle)
            if(![string]::IsNullOrEmpty($windowTitle))
            {            
                if(!$procsTitle.ContainsKey($processId))
                {
                    $procsTitle.Add($processId, $windowTitle)
                }
            }        
        }
    }
    
    $procsTitle
}

# Регистрируем типы для работы с WinAPI
RegisterType


# Служебные параметры
$currentDateUTC = [System.DateTime]::UtcNow
$hostName = [System.Net.Dns]::GetHostName()
$locale = $PSUICulture
$cpuCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
if($locale -eq "ru-RU")
{
    $procIds = (Get-Counter "\Процесс(*)\Идентификатор процесса" -ErrorAction SilentlyContinue).CounterSamples
    $procUsage = (Get-Counter "\Процесс(*)\% загруженности процессора" -ErrorAction SilentlyContinue).CounterSamples
} else
{
    $procIds = (Get-Counter "\Process(*)\ID Process" -ErrorAction SilentlyContinue).CounterSamples
    $procUsage = (Get-Counter "\Process(*)\% Processor Time" -ErrorAction SilentlyContinue).CounterSamples
}

# Список открытых окон
$procsTitle = GetOpenWindows

# Список открытых процессов
$processesInfo = New-Object Collections.Generic.List[object]

try {
    $processes = Get-Process -IncludeUserName | Select ProcessName, Id, Responding, UserName, CPU, PrivateMemorySize64, WorkingSet64, Description, CommandLine, Path, StartTime
}
catch {
    $processes = Get-Process | Select ProcessName, Id, Responding, UserName, CPU, PrivateMemorySize64, WorkingSet64, Description, CommandLine, Path, StartTime
}

$processes | ForEach-Object {
    $windowTitle = ""
    if($procsTitle.ContainsKey($_.Id))
    {
        $windowTitle = $($procsTitle[$_.Id])
    }

    $processId = $_.Id
    $perfCounterProcessIdInfo = $procIds | Where-Object { $_.CookedValue -eq $processId}
    $cpuUsagePercent = -1;
    if($locale -eq "ru-RU")
    {
        $procUsageCounterName = $perfCounterProcessIdInfo.Path -replace "\\идентификатор процесса$", "\% загруженности процессора"
    } else
    {
        $procUsageCounterName = $perfCounterProcessIdInfo.Path -replace "\\id process$", "\% processor time"
    }
    $procUsageInfo = $procUsage | Where-Object { $_.Path -eq $procUsageCounterName }
    $cpuUsagePercent = $procUsageInfo.CookedValue / $cpuCores
    $cpuUsagePercent = [Math]::Round($cpuUsagePercent, 2)

    $processInfo = [PSCustomObject]@{
        PeriodUTC = $currentDateUTC
        HostName = $hostName
        ProcessName = $_.ProcessName
        PID = $_.Id
        StartTime = $_.StartTime   
        Status = $(if($_.Responding) {"Running"} else { "Not Responding" })
        UserName = $_.UserName
        SessionId = $_.SessionId
        CPU = $_.CPU
        CPUPercent = $cpuUsagePercent
        PrivateMemorySize64 = $_.PrivateMemorySize64
        WorkingSet64 = $_.WorkingSet64        
        Path = $_.Path
        CommandLine = $_.CommandLine
        # TODO
        # Платформа 32 или 64
        # С повышенными правами
        # Виртуализация
        Description = $_.Description
        WindowTitle = $windowTitle
    }    
    $processesInfo.Add($processInfo) | Out-Null
}

$processesInfo | Sort-Object -Property WindowTitle # -Descending