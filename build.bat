@echo off

pushd %~dp0

if "%1" == "" (
  git tag
  echo Choose a valid version tag: build.bat [tagname]
  goto end
)

if "%1" == "stub" (
  shift
  goto stub_run
)

copy /Y build.bat build-stub.bat
call build-stub.bat stub %*
exit

:stub_run
echo %1
git checkout tags/%1
if "%errorlevel%" neq "0" (
  goto end
) 

if not exist build (
  mkdir build
)

pushd build

set ISA=ASTCENC_ISA_AVX2
set CONFIG_NAME=RelWithDebInfo

if "%2" == "" (
  set ISA=ASTCENC_ISA_AVX2
  set ISA_NAME=avx2
)
if "%2" == "avx2" (
  set ISA=ASTCENC_ISA_AVX2
)
if "%2" == "sse41" (
  set ISA=ASTCENC_ISA_SSE41
)
if "%2" == "sse2" (
  set ISA=ASTCENC_ISA_SSE2
)
if "%2" == "neon" (
  set ISA=ASTCENC_ISA_NEON
)
if "%2" == "native" (
  set ISA=ASTCENC_ISA_NATIVE
)

cmake .. --fresh -DASTCENC_SHAREDLIB=ON -DBUILD_TESTING=OFF -DASTCENC_CLI=OFF -D%ISA%=ON 
if "%errorlevel%" neq "0" (
  popd
  goto end
) 

pushd Source\%CONFIG_NAME%
del /Q /F *
popd

msbuild astcencoder.sln -property:Configuration=%CONFIG_NAME% /t:astcenc-%ISA_NAME%-shared -verbosity:minimal

if "%errorlevel%" neq "0" (
  popd
  goto end
) 

pushd Source\%CONFIG_NAME%

set "DLL_FILENAME="

for /f "delims=" %%F in ('dir /b "*.dll" 2^>nul') do (
    set "DLL_FILENAME=%%F"
    goto :found_dll
)

:found_dll
rename %DLL_FILENAME% astcenc-%ISA_NAME%-%1.dll

set "PDB_FILENAME="
for /f "delims=" %%F in ('dir /b "*.pdb" 2^>nul') do (
    set "PDB_FILENAME=%%F"
    goto :found_pdb
)
:found_pdb
rename %PDB_FILENAME% astcenc-%ISA_NAME%-%1.pdb

del /Q *.lib
del /Q *.exp

start explorer .

popd
popd

:end
git checkout -
popd