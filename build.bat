@echo off
SET DELPHIROOT=C:\Program Files (x86)\Embarcadero\RAD Studio\8.0
SET JVCLROOT=..\..\..\_thirdpartcomponents\Delphi\JVCL340
echo --- Compilation : Squid ---
"%DELPHIROOT%\bin\dcc32.exe" -B -H -W -U"%DELPHIROOT%\lib;%JVCLROOT%\jvcl\lib\d15;%JVCLROOT%\jcl\lib\d15;.\Lib;.\Squid" -R"%JVCLROOT%\jvcl\resources;.\Squid" -E".\Build" "Squid\Squid.dpr" > log.txt
echo --- Compilation : Enjoy ---
"%DELPHIROOT%\bin\dcc32.exe" -B -H -W -U"%DELPHIROOT%\lib;%JVCLROOT%\jvcl\lib\d15;%JVCLROOT%\jcl\lib\d15;.\Lib" -R"%JVCLROOT%\jvcl\resources;.\Enjoy" -E".\Build" ".\Enjoy\Enjoy.dpr" >> log.txt
echo --- Compilation : Hook ---
"%DELPHIROOT%\bin\dcc32.exe" -B -H -W -U"%DELPHIROOT%\lib;%JVCLROOT%\jvcl\lib\d15;%JVCLROOT%\jcl\lib\d15;.\Lib" -R"%JVCLROOT%\jvcl\resources" -E".\Build" ".\Hook\SquidHook.dpr" >> log.txt
echo --- Unit Testing ---
".\Test\Build\SquidTests.exe" > log.txt
grep "err" log.txt
echo --- DxGetText : Assembling ---
"..\..\..\_thirdparttools\dxgettext\assemble.exe" "Build\Squid.exe" --dxgettext
"..\..\..\_thirdparttools\dxgettext\assemble.exe" "Build\Enjoy.exe" --dxgettext
echo --- Packaging ---
"..\..\..\_thirdparttools\Inno Setup 5\iscc.exe" "Install Script\InstallScript.iss" /q
pause