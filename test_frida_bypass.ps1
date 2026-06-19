$FridaScripts = "C:\Users\jenry\AppData\Local\Python\pythoncore-3.14-64\Scripts"
$env:Path += ";$FridaScripts"

$ScriptPath = "C:\Users\jenry\Downloads\demo_viteQ\frida_bypass_usb_debug.js"
$PackageName = "com.example.secure_app_demo"
$Adb = "C:\Users\jenry\AppData\Local\Android\Sdk\platform-tools\adb.exe"

Write-Host "[1] Killing any running instance of the app..." -ForegroundColor Cyan
& $Adb shell am force-stop $PackageName

Write-Host "[2] Starting Frida in background (await mode)..." -ForegroundColor Cyan
$Job = Start-Job -ScriptBlock {
    param($Path, $Script)
    $env:Path += ";$Path"
    frida -U -W "com.example.secure_app_demo" -l $Script -q -t 20 2>&1
} -ArgumentList $FridaScripts, $ScriptPath

Start-Sleep -Seconds 3

Write-Host "[3] Launching the app..." -ForegroundColor Cyan
& $Adb shell monkey -p $PackageName 1

Write-Host "[4] Waiting for Frida to attach and hook..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Host "[5] Frida output:" -ForegroundColor Cyan
$Output = Receive-Job -Job $Job -ErrorAction SilentlyContinue
Write-Host $Output -ForegroundColor Yellow

Stop-Job -Job $Job -ErrorAction SilentlyContinue
Remove-Job -Job $Job -ErrorAction SilentlyContinue

Write-Host "[6] Done! Check your phone." -ForegroundColor Green
