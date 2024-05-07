set VERSION=%1

cd %HOMEPATH%
echo =====[ Getting Depot Tools ]=====
powershell -command "Invoke-WebRequest https://storage.googleapis.com/chrome-infra/depot_tools.zip -O depot_tools.zip"
7z x depot_tools.zip -o*
set PATH=%CD%\depot_tools;%PATH%
set GYP_MSVS_VERSION=2019
set DEPOT_TOOLS_WIN_TOOLCHAIN=0
call gclient

cd depot_tools
call git reset --hard 8d16d4a
cd ..
set DEPOT_TOOLS_UPDATE=0


mkdir v8
cd v8

echo =====[ Fetching V8 ]=====
call fetch v8
cd v8
call git checkout refs/tags/%VERSION%
cd test\test262\data
call git config --system core.longpaths true
call git restore *
cd ..\..\..\
call gclient sync

if "%VERSION%"=="10.6.194" (
    echo =====[ patch 10.6.194 ]=====
    node %~dp0\node-script\do-gitpatch.js -p %GITHUB_WORKSPACE%\patches\win_msvc_v10.6.194.patch
)

if "%VERSION%"=="9.4.146.24" (
    echo =====[ patch jinja for python3.10+ ]=====
    cd third_party\jinja2
    node %~dp0\node-script\do-gitpatch.js -p %GITHUB_WORKSPACE%\patches\jinja_v9.4.146.24.patch
    cd ..\..
)

@REM echo =====[ Patching V8 ]=====
@REM node %GITHUB_WORKSPACE%\CRLF2LF.js %GITHUB_WORKSPACE%\patches\builtins-puerts.patches
@REM call git apply --cached --reject %GITHUB_WORKSPACE%\patches\builtins-puerts.patches
@REM call git checkout -- .

@REM issue #4
node %~dp0\node-script\do-gitpatch.js -p %GITHUB_WORKSPACE%\patches\intrin.patch

echo =====[ add ArrayBuffer_New_Without_Stl ]=====
node %~dp0\node-script\add_arraybuffer_new_without_stl.js .

echo =====[ Building V8 ]=====
if "%VERSION%"=="10.6.194" (
    call gn gen out.gn\x86.release -args="target_os=""win"" target_cpu=""x86"" v8_use_external_startup_data=false v8_enable_i18n_support=false is_debug=false is_clang=false strip_debug_info=true symbol_level=0 v8_enable_pointer_compression=false v8_enable_sandbox=false"
) else (
    call gn gen out.gn\x86.release -args="target_os=""win"" target_cpu=""x86"" v8_use_external_startup_data=false v8_enable_i18n_support=false is_debug=false is_clang=false strip_debug_info=true symbol_level=0 v8_enable_pointer_compression=false"
)

call ninja -C out.gn\x86.release -t clean
call ninja -C out.gn\x86.release v8

md output\v8\Lib\Win32DLL
copy /Y out.gn\x86.release\v8.dll.lib output\v8\Lib\Win32DLL\
copy /Y out.gn\x86.release\v8_libplatform.dll.lib output\v8\Lib\Win32DLL\
copy /Y out.gn\x86.release\v8.dll output\v8\Lib\Win32DLL\
copy /Y out.gn\x86.release\v8_libbase.dll output\v8\Lib\Win32DLL\
copy /Y out.gn\x86.release\v8_libplatform.dll output\v8\Lib\Win32DLL\
copy /Y out.gn\x86.release\zlib.dll output\v8\Lib\Win32DLL\
copy /Y out.gn\x86.release\v8.dll.pdb output\v8\Lib\Win32DLL\
copy /Y out.gn\x86.release\v8_libbase.dll.pdb output\v8\Lib\Win32DLL\
copy /Y out.gn\x86.release\v8_libplatform.dll.pdb output\v8\Lib\Win32DLL\
copy /Y out.gn\x86.release\zlib.dll.pdb output\v8\Lib\Win32DLL\