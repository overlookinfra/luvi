@ECHO off

for /f %%i in ('git describe --tags') do set LUVI_TAG=%%i
IF NOT "x%1" == "x" GOTO :%1

GOTO :build

:static32
ECHO "Building static 32"
cmake -DWithOpenSSL=ON -DWithSharedOpenSSL=OFF -DWithZLIB=ON -DWithSharedZLIB=OFF -DWithSqlite=ON -DWithSharedSqlite=OFF -DWithCjson=ON -DWithYaml=ON -DWithSharedYaml=OFF -H. -Bbuild
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:static64
ECHO "Building static 64"
cmake -DWithOpenSSL=ON -DWithSharedOpenSSL=OFF -DWithZLIB=ON -DWithSharedZLIB=OFF -DWithSqlite=ON -DWithSharedSqlite=OFF -DWithCjson=ON -DWithYaml=ON -DWithSharedYaml=OFF -H. -Bbuild -G"Visual Studio 12 Win64"
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:tiny
ECHO "Building tiny"
cmake -T v120_xp -H. -Bbuild
GOTO :end

:build
cmake --build build --config Release -- /maxcpucount
if %errorlevel% neq 0 exit /b %errorlevel%
COPY build\Release\luvi.exe .
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:test
IF NOT EXIST luvi.exe CALL Make.bat
SET LUVI_APP=samples\test.app
luvi.exe
SET LUVI_TARGET=test.exe
luvi.exe
SET "LUVI_APP="
SET "LUVI_TARGET="
test.exe
DEL /Q test.exe
GOTO :end

:winsvc
IF NOT EXIST luvi.exe CALL Make.bat
DEL /Q winsvc.exe
SET LUVI_APP=samples\winsvc.app
SET LUVI_TARGET=winsvc.exe
luvi.exe
SET "LUVI_APP="
SET "LUVI_TARGET="
GOTO :end

:repl
IF NOT EXIST luvi.exe CALL Make.bat
DEL /Q repl.exe
SET LUVI_APP=samples\repl.app
SET LUVI_TARGET=repl.exe
luvi.exe
SET "LUVI_APP="
SET "LUVI_TARGET="
GOTO :end


:clean
IF EXIST build RMDIR /S /Q build
IF EXIST luvi.exe DEL /F /Q luvi.exe
GOTO :end

:reset
git submodule update --init --recursive
if %errorlevel% neq 0 exit /b %errorlevel%
git clean -f -d
if %errorlevel% neq 0 exit /b %errorlevel%
git checkout .
if %errorlevel% neq 0 exit /b %errorlevel%
GOTO :end

:publish64
CALL make.bat reset
if %errorlevel% neq 0 exit /b %errorlevel%
CALL make.bat static64
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

:publish32
CALL make.bat reset
if %errorlevel% neq 0 exit /b %errorlevel%
CALL make.bat static32
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

:end
