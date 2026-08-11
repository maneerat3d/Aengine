@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0"

set "AENGINE_COMMAND=%~1"
if not defined AENGINE_COMMAND set "AENGINE_COMMAND=all"

if /I "%AENGINE_COMMAND%"=="help" goto :help
if /I "%AENGINE_COMMAND%"=="map" goto :map_only
if /I "%AENGINE_COMMAND%"=="debug" goto :debug
if /I "%AENGINE_COMMAND%"=="release" goto :release
if /I "%AENGINE_COMMAND%"=="all" goto :all
if /I "%AENGINE_COMMAND%"=="test" goto :test

echo ERROR: unknown build command "%AENGINE_COMMAND%".
goto :help_error

:map_only
call :update_ai_map
if errorlevel 1 goto :failed
goto :success

:debug
call :update_ai_map
if errorlevel 1 goto :failed
call :setup_msvc
if errorlevel 1 goto :failed
call :build_preset windows-x64-debug
if errorlevel 1 goto :failed
goto :success

:release
call :update_ai_map
if errorlevel 1 goto :failed
call :setup_msvc
if errorlevel 1 goto :failed
call :build_preset windows-x64-release
if errorlevel 1 goto :failed
goto :success

:all
call :update_ai_map
if errorlevel 1 goto :failed
call :setup_msvc
if errorlevel 1 goto :failed
call :build_preset windows-x64-debug
if errorlevel 1 goto :failed
call :build_preset windows-x64-release
if errorlevel 1 goto :failed
goto :success

:test
set "AENGINE_TEST_FILTER=%~2"
if not defined AENGINE_TEST_FILTER (
    echo ERROR: build.bat test requires a CTest regex.
    goto :failed
)
call :update_ai_map
if errorlevel 1 goto :failed
call :setup_msvc
if errorlevel 1 goto :failed
call :configure_and_build windows-x64-debug
if errorlevel 1 goto :failed
ctest --preset windows-x64-debug -R "%AENGINE_TEST_FILTER%"
if errorlevel 1 goto :failed
goto :success

:update_ai_map
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%CD%\tools\ai_map\UpdateAiCodeMap.ps1" -RepoRoot "%CD%" -Mode Update
if errorlevel 1 exit /b %errorlevel%

if /I "%GITHUB_ACTIONS%"=="true" (
    set "AENGINE_AI_MAP_DIRTY="
    for /f "delims=" %%i in ('git status --porcelain -- ".agent/code-map/current"') do set "AENGINE_AI_MAP_DIRTY=1"
    if defined AENGINE_AI_MAP_DIRTY (
        echo ERROR: AI code map is stale. Run .\build.bat map and commit the generated changes.
        git status --short -- ".agent/code-map/current"
        git diff -- ".agent/code-map/current"
        for /f "delims=" %%f in ('git ls-files --others --exclude-standard ".agent/code-map/current"') do (
            echo ----- %%f -----
            type "%%f"
        )
        exit /b 4
    )
)
exit /b 0

:setup_msvc
set "AENGINE_VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%AENGINE_VSWHERE%" (
    echo ERROR: vswhere.exe was not found.
    exit /b 1
)
set "AENGINE_VS2022="
for /f "usebackq tokens=*" %%i in (`"%AENGINE_VSWHERE%" -latest -products * -version [17.0^,18.0^) -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "AENGINE_VS2022=%%i"
if not defined AENGINE_VS2022 (
    echo ERROR: approved Visual Studio 2022 toolchain was not found.
    exit /b 1
)
call "%AENGINE_VS2022%\VC\Auxiliary\Build\vcvarsall.bat" x64 10.0.26100.0 -vcvars_ver=14.44
if errorlevel 1 exit /b %errorlevel%
exit /b 0

:configure_and_build
set "AENGINE_PRESET=%~1"
cmake --preset %AENGINE_PRESET%
if errorlevel 1 exit /b %errorlevel%
cmake --build --preset %AENGINE_PRESET% --parallel
if errorlevel 1 exit /b %errorlevel%
exit /b 0

:build_preset
set "AENGINE_PRESET=%~1"
call :configure_and_build %AENGINE_PRESET%
if errorlevel 1 exit /b %errorlevel%
ctest --preset %AENGINE_PRESET%
if errorlevel 1 exit /b %errorlevel%
exit /b 0

:help
echo A-Engine canonical build entrypoint
echo.
echo   build.bat              Update AI map, Debug build/test, Release build/test
echo   build.bat debug        Update AI map, Debug build/test
echo   build.bat release      Update AI map, Release build/test
echo   build.bat test REGEX   Update AI map, Debug build, focused CTest regex
echo   build.bat map          Update AI code map only when inputs changed
goto :success

:help_error
call :help
exit /b 2

:failed
set "AENGINE_EXIT=%errorlevel%"
if "%AENGINE_EXIT%"=="0" set "AENGINE_EXIT=1"
echo A-Engine build FAILED with exit code %AENGINE_EXIT%.
popd
exit /b %AENGINE_EXIT%

:success
echo A-Engine build PASS.
popd
exit /b 0
