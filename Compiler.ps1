$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

& $csc /target:winexe /out:simulacron.exe /win32icon:DeadPixel.ico /resource:_DeadPixelSimulator.ps1 _Packager.cs