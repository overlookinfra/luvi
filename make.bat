@ECHO off

set LUVI_PUBLISH_USER=luvit
set LUVI_PUBLISH_REPO=luvi
set EXTRA_FLAGS=-DWithZLIB=ON -DWithSharedZLIB=OFF -DWithSqlite=ON -DWithSharedSqlite=OFF -DWithCjson=ON -DWithYaml=ON -DWithSharedYaml=OFF

set GENERATOR=Visual Studio 12
reg query HKEY_CLASSES_ROOT\VisualStudio.DTE.14.0 >nul 2>nul
IF %errorlevel%==0 set GENERATOR=Visual Studio 14
set GENERATOR64=%GENERATOR% Win64

for /f %%i in ('git describe --tags') do set LUVI_TAG=%%i
IF NOT "x%1" == "x" GOTO :%1

GOTO :build

:regular
ECHO "Building regular64"
cmake -DWithOpenSSL=ON -DWithSharedOpenSSL=OFF -DWithPCRE=ON -DWithLPEG=ON -DWithSharedPCRE=OFF %EXTRA_FLAGS% -H. -Bbuild  -G"%GENERATOR64%"
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:regular-asm
ECHO "Building regular64 asm"
cmake -DWithOpenSSLASM=ON -DWithOpenSSL=ON -DWithSharedOpenSSL=OFF -DWithPCRE=ON -DWithLPEG=ON -DWithSharedPCRE=OFF %EXTRA_FLAGS% -H. -Bbuild  -G"%GENERATOR64%"
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:regular32
ECHO "Building regular32"
cmake -DWithOpenSSL=ON -DWithSharedOpenSSL=OFF -DWithPCRE=ON -DWithLPEG=ON -DWithSharedPCRE=OFF %EXTRA_FLAGS% -H. -Bbuild  -G"%GENERATOR%"
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:regular32-asm
ECHO "Building regular32 asm"
cmake -DWithOpenSSLASM=ON -DWithOpenSSL=ON -DWithSharedOpenSSL=OFF -DWithPCRE=ON -DWithLPEG=ON -DWithSharedPCRE=OFF %EXTRA_FLAGS% -H. -Bbuild  -G"%GENERATOR%"
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:tiny
ECHO "Building tiny64"
cmake -H. -Bbuild -G"%GENERATOR64%"
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:tiny32
ECHO "Building tiny32"
cmake -H. -Bbuild -G"%GENERATOR%"
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:build
IF NOT EXIST build CALL Make.bat regular
cmake --build build --config Release -- /maxcpucount
if %errorlevel% neq 0 exit /b %errorlevel%
COPY build\Release\luvi.exe .
GOTO :end

:test
IF NOT EXIST luvi.exe CALL Make.bat
luvi.exe samples\test.app -- 1 2 3 4
luvi.exe samples\test.app -o test.exe
test.exe 1 2 3 4
DEL /Q test.exe
GOTO :end

:winsvc
IF NOT EXIST luvi.exe CALL Make.bat
DEL /Q winsvc.exe
luvi.exe samples\winsvc.app -o winsvc.exe
GOTO :end

:repl
IF NOT EXIST luvi.exe CALL Make.bat
DEL /Q repl.exe
luvi.exe samples/repl.app -o repl.exe
GOTO :end


:clean
IF EXIST build RMDIR /S /Q build
IF EXIST luvi.exe DEL /F /Q luvi.exe
GOTO :end

:reset
git submodule update --init --recursive
git clean -f -d
git checkout .
GOTO :end

:publish-tiny
CALL make.bat reset
CALL make.bat tiny
CALL make.bat test
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file luvi.exe --name luvi-tiny-Windows-amd64.exe
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file build\Release\luvi.lib --name luvi-tiny-Windows-amd64.lib
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file build\Release\luvi_renamed.lib --name luvi_renamed-tiny-Windows-amd64.lib
GOTO :end

:publish-tiny32
CALL make.bat reset
CALL make.bat tiny32
CALL make.bat test
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file luvi.exe --name luvi-tiny-Windows-ia32.exe
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file build\Release\luvi.lib --name luvi-tiny-Windows-ia32.lib
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file build\Release\luvi_renamed.lib --name luvi_renamed-tiny-Windows-ia32.lib
GOTO :end

:publish-regular
CALL make.bat reset
CALL make.bat regular-asm
CALL make.bat test
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file luvi.exe --name luvi-regular-Windows-amd64.exe
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file build\Release\luvi.lib --name luvi-regular-Windows-amd64.lib
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file build\Release\luvi_renamed.lib --name luvi_renamed-regular-Windows-amd64.lib
GOTO :end

:publish-regular32
CALL make.bat reset
CALL make.bat regular32-asm
CALL make.bat test
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file luvi.exe --name luvi-regular-Windows-ia32.exe
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file build\Release\luvi.lib --name luvi-regular-Windows-ia32.lib
github-release upload --user %LUVI_PUBLISH_USER% --repo %LUVI_PUBLISH_REPO% --tag %LUVI_TAG% --file build\Release\luvi_renamed.lib --name luvi_renamed-regular-Windows-ia32.lib
GOTO :end

:publish
CALL make.bat clean
CALL make.bat publish32
if %errorlevel% neq 0 exit /b %errorlevel%
CALL make.bat clean
CALL make.bat publish64
if %errorlevel% neq 0 exit /b %errorlevel%

:publish64
CALL make.bat reset
if %errorlevel% neq 0 exit /b %errorlevel%
CALL make.bat regular
if %errorlevel% neq 0 exit /b %errorlevel%
CALL make.bat test
if %errorlevel% neq 0 exit /b %errorlevel%
setlocal
for /f %%i in ('git describe --tags "--abbrev=0"') do set VERSION=%%i
set FNAME="luvi.Windows-AMD64-%VERSION%.gz"
7za a -tgzip "%FNAME%" luvi.exe
if %errorlevel% neq 0 exit /b %errorlevel%
aws --profile distelli-mvn-repo s3 cp "%FNAME%" "s3://distelli-mvn-repo/exe/Windows-AMD64/%FNAME%"
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:publish32
CALL make.bat reset
if %errorlevel% neq 0 exit /b %errorlevel%
CALL make.bat regular32
if %errorlevel% neq 0 exit /b %errorlevel%
CALL make.bat test
if %errorlevel% neq 0 exit /b %errorlevel%
setlocal
for /f %%i in ('git describe --tags "--abbrev=0"') do set VERSION=%%i
set FNAME="luvi.Windows-x86-%VERSION%.gz"
7za a -tgzip "%FNAME%" luvi.exe
if %errorlevel% neq 0 exit /b %errorlevel%
aws --profile distelli-mvn-repo s3 cp "%FNAME%" "s3://distelli-mvn-repo/exe/Windows-x86/%FNAME%"
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:end
