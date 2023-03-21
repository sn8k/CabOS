@echo off
setlocal EnableDelayedExpansion

if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

::for debug only. Activate the line below stop runner from autolaunching when updated from github.
::echo GITHUB PAUSE REQUESTED && pause

:: Must be on top.
set version=1.55-beta
set reboot_command=shutdown -r -t 
title CabOS Launcher Ver. %version% - please Wait.

::part to helper
if "%1"=="help" goto help_part 
if "%1"=="-?" goto help_part 
if "%1"=="?" goto help_part 
if "%1"=="-help" goto help_part
if "%1"=="reboot" goto reboot_part
if "%1"=="noreboot" (set reboot_command=timeout )
if "%update_in_progress%"=="yes" (goto update_install)

::Drive List as stated by ... me.
set System_drive=c:
set Data_Drive=D:
set Roms_Drive=E:
set Alt_drive=F:
set binaries=d:\binaries

::Updater settings
set update_url=https://raw.githubusercontent.com/sn8k/CabOS/main/version.run
set runner_url=https://github.com/sn8k/CabOS/raw/main/runner.cmd
set zipped_url=https://github.com/sn8k/CabOS/archive/refs/heads/main.zip

::Used for error argument.
if exist "%Alt_drive%\" (set F_present=yes)
if "%1"=="error" goto Error_part 

if not exist "%system_drive%\temp\" (
	echo temp folder absent. Creation.
	md "%system_drive%\temp\"
	)
	
if exist "%system_drive%\temp\WritedEnabled.yan" (
	echo fichier WriteEnabled present. Ceci est une erreur.
	timeout 2
	goto error_part
	)


::Emulator name used for pathes
set emul_name=coinops




::path to replacement shell (in fact the cab interface)
set coinops_path=d:\coinops
set coinops_exec=coinOPS.exe




if not exist E:\DATA (
	echo DISQUE DATA ABSENT. QUITTING
	Goto Error_part
	)

GOTO startup

::Startup Windows.

:startup	
color 17
echo Arcade Cabinet Launcher V%version%
echo.
echo.
echo Creating Diagnostics File
echo.
echo %DATE% %TIME%>"%system_drive%\temp\WritedEnabled.yan"
echo.
echo Checking Updates ...
echo.
goto updater_check

echo Looking for missing plugins ..


goto EOF

:updater_check
::1st clean stage .
del c:\temp\version.* /Q
if "%update_in_progress%"=="" ( del c:\temp\updated.cmd )

powershell invoke-webrequest "%update_url%" -outFile "%system_drive%\temp\version.run"
set /P server_version=<%system_drive%\temp\version.run
if "%server_version%"=="%version%" ( goto no_update_found ) ELSE ( powershell invoke-webrequest "%runner_url%" -outFile "%system_drive%\temp\runner.cmd" & goto update_found )

if not exist "%system_drive%\temp\runner.cmd" ( powershell invoke-webrequest "%zipped_url%" -outFile "%system_drive%\temp\zipped.zip" )
if "%update_in_progress%"=="yes" ( goto update_install )
if "%update_in_progress%"=="no" ( del c:\service\updated.cmd /Q )

goto EOF

:update_found
color 34
echo an update has been found !
echo installing it inconditionnaly ...
copy "%system_drive%\temp\runner.cmd" "c:\service\updated.cmd" /Y
set update_in_progress=yes
cmd /c "c:\service\updated.cmd" %1
goto EOF

:update_install
del "c:\service\runner.cmd" /Q
copy "c:\service\updated.cmd" "c:\service\runner.cmd"
set update_in_progress=no
echo Updating process finished. 
echo.
echo now you're at version %version%
echo.
echo Restarting Arcade Cabinet now!

%reboot_command%5
goto EOF

:no_update_found
echo No update has been found.
echo.
echo Killing Explorer process (for best performance)
echo.

taskkill -im explorer.exe /f
taskkill -im x360ce.exe /f

echo unmuting audio
call "%binaries%\nircmd\nircmd.exe" mutesysvolume 0


if not exist "%binaries%\Xbox360ce\X360ce.EXE" (Echo WARNING : X360Ce is absent. Goto Error part ! && goto error_part)

echo Loading X360Ce
echo.
::start /MIN "D:\Xbox360ce\X360ce.EXE"
start "" "%binaries%\Xbox360ce\x360ce.exe.lnk"
timeout 15
if "%1"=="test" goto test

:launch_emul
echo.
Echo going to %emul_name% folder
cd /D "%coinops_path%" 
%coinops_exec%
goto exit_part
goto EOF

:exit_part
if exist "%system_drive%\temp\attempt.run" (
	set /P attempt=<"%system_drive%\temp\attempt.run"
	)

call explorer.exe
echo Relaunching coinOPS ...
if "%attempt%"=="" ( echo 1 > "%system_drive%\temp\attempt.run")
if "%attempt%"=="1" ( echo 2 > "%system_drive%\temp\attempt.run")
if "%attempt%"=="2" ( echo 3 > "%system_drive%\temp\attempt.run")
if "%attempt%"=="3" (goto reboot_part)

echo.
timeout 10
goto launch_emul
goto EOF


:test
call explorer.exe
echo CTRL C to escape . If no key pressed, system will be rebooted
timeout 10
goto reboot_part
goto EOF

:reboot_part
del "%system_drive%\temp\*.*" /Q
%reboot_command% 0
goto EOF

:error_part
cls
color 47
echo An error has been found !
echo.
echo Running Diagnostics....
echo.
echo checking X360ce presence
timeout 2

echo Checking system Files
echo.
SFC /SCannow
echo.
echo Checking DATA Drive
echo.
echo y|chkdsk %Data_Drive% /F
echo.
echo Checking Roms Drive
echo.
echo y|chkdsk %Roms_Drive% /F
echo.
if "%F_present%"=="yes" (
	echo Alternate Drive detected ... Checking
	echo y|chkdsk %Alt_drive% /F
	echo.
	)

echo Checking System Drive Lock
echo.
uwfmgr volume protect c:
timeout 2


if "%1"=="error" (echo End of error script && goto EOF) else (goto reboot_part)
GOTO EOF

:help_part
echo.
echo Runner for Arcade Cabinet V. %version%
echo.
echo Available arguments :
echo ---------------------
echo.
echo help - this screen
echo error - launch diagnostics
echo test - Fake Launch
echo reboot - reboot arcade Cabinet
echo noreboot - disable autoreboot
echo.
echo (c) YanG Soft
echo.
goto EOF


:EOF
::do not add anything after this line !!
