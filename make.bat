@ECHO off

for /f %%i in ('git describe --tags') do set LUVI_TAG=%%i
IF NOT "x%1" == "x" GOTO :%1

GOTO :build

:static
ECHO "Building static"
cmake -DWithOpenSSL=ON -DWithSharedOpenSSL=OFF -DWithZLIB=ON -DWithSharedZLIB=OFF -DWithSqlite=ON -DWithSharedSqlite=OFF -DWithCjson=ON -DWithYaml=ON -DWithSharedYaml=OFF -H. -Bbuild
GOTO :end

:tiny
ECHO "Building tiny"
cmake -T v120_xp -H. -Bbuild
GOTO :end

:build
IF NOT EXIST build CALL Make.bat static
cmake --build build --config Release -- /maxcpucount
COPY build\Release\luvi.exe .
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
git clean -f -d
git checkout .
GOTO :end

:publish
CALL make.bat reset
CALL make.bat static
CALL make.bat test

setlocal

for /f %%i in ('git describe --tags "--abbrev=0"') do set VERSION=%%i

set FNAME="luvi.Windows-%PROCESSOR_ARCHITECTURE%-%VERSION%.zip"
7z a "%FNAME%" luvi.exe

aws --profile distelli-mvn-repo s3 cp "%FNAME%" "s3://distelli-mvn-repo/exe/Windows-%PROCESSOR_ARCHITECTURE%/%FNAME%"


:end
