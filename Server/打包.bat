cd ..
md .\Release
cd .\Release
rd /s /q .\pack
md .\pack
md .\pack\log
xcopy .\..\server\skynet\lualib\* .\pack\skynet\lualib\ /s /d
xcopy .\..\server\skynet\bin\* .\pack\skynet\bin\ /s /d
xcopy .\..\server\skynet\service\* .\pack\skynet\service\ /s /d
copy .\..\server\start_ykserver_gate.sh .\pack\start_ykserver_gate.sh
xcopy .\..\server\ykserver\* .\pack\ykserver\ /s /d
for /r .\pack %%i in (*.lua) do (
.\..\luac5.3.5\luac_64.exe -o %%i %%i
)
pause