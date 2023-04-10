@echo off
::Config
set p2path=C:\Program Files (x86)\Steam\steamapps\common\Portal 2
set modpath=%~dp0\..\..\
set map_path=puzzlemaker\
set game_executable=chaos.exe


::Do not change anything below
set copypath=%modpath%\maps\%map_path%

::Resolve paths, fixes VBSP crashing
cd "%modpath%"
set modpath=%CD%

cd "%copypath%"
set copypath=%CD%

echo [36mWelcome to PuzzleMaker Compile script, made by Enderek0 for development purposes of Portal: Singularity Collapse.
echo Portal 2 path is: "%p2path%"
echo ModPath is: "%modpath%"
echo Checking for BEE2 installation...
if exist "%p2path%\bin\vbsp_original.exe" (
    goto :BEE2Installed
) else (
    goto :BEE2E
)

:BEE2E
    echo [33mBEE2 is not installed! Cannot proceed further.[0m
    pause
    exit


:BEE2Installed
    echo BEE2 is installed![0m
    
    set /p mode=[32mDo full compile [Y / Else no]: [0m

    echo [33mPlease use "puzzlemaker_export <filename>" command and enter a filename (without the extension) to export the puzzle, then proceed.[0m
    
    set /p puzzle_name=[32mPlease enter the filename (without the extension), leave default for "preview.vmf": [0m

    if not defined puzzle_name (
        set puzzle_name=preview.vmf
    ) else (
        set filename=%puzzle_name%.vmf
    )

    if exist "%p2path%\sdk_content\maps\%filename%" (
        goto :PRECOMPILE
    ) else (
        goto :PUZZLE_ERROR
    )

:PUZZLE_ERROR
    echo [31mCouldn't find "%p2path%\sdk_content\maps\%filename%", please verify if the filename is correct and re-run the script![0m
    pause
    exit


:PRECOMPILE
    echo [36mName is correct, file found.
    echo Precompiling "%p2path%\sdk_content\maps\%filename%"...[0m [90m

    cd "%p2path%\bin"
    vbsp.exe -game ..\portal2 -force_peti -skip_vbsp "%p2path%\sdk_content\maps\%filename%"

    echo [36m
    cd "%modpath%\..\"

    if exist "%p2path%\sdk_content\maps\styled\%filename%" (
        echo Precompiling successful, switching over to P2CE's tools for compile.
        goto :COMPILE
    ) else (
        goto :PRECOMPILE_ERROR
    )

:PRECOMPILE_ERROR
    echo [31mCouldn't find "%p2path%\sdk_content\maps\styled\%filename%", verify the logs above to check if everything went fine. Cannot proceed further.[0m
    pause
    exit

:COMPILE   
    :: Copyfile
    echo Copying file!
    copy "%p2path%\sdk_content\maps\styled\%filename%" "%copypath%"
    ::VBSP
    echo Running VBSP... [90m
    echo bin\win64\vbsp.exe -game "%copypath%" -instancepath "%p2path%/sdk_content/maps/" "%copypath%/%filename%"
    bin\win64\vbsp.exe -game "%copypath%" -instancepath "%p2path%/sdk_content/maps/" "%copypath%/%filename%"
    
    echo [36m
    ::VBSP can't fail no matter the mode
    if not exist "%copypath%\%puzzle_name%.bsp" (
        echo [31mVBSP failed, please check above for errors. Cannot continue, exiting.
        pause
        exit
    )

    if %ERRORLEVEL% NEQ 0 ( 
        echo [31mVBSP failed, please check above for errors. Cannot continue, exiting.
        pause
        exit
    )

    set filename=%puzzle_name%.bsp

    echo VBSP finished!

    :: Post-compiler

    echo Running Postcompiler...[90m
    bin\win64\postcompiler\postcompiler.exe -game "%modpath%" "%copypath%/%filename%"
    echo [36m

    ::Post-compiler also cannot fail
    if %ERRORLEVEL% NEQ 0 ( 
        echo [31mPostcompiler failed, please check above for errors. Cannot continue, exiting.
        pause
        exit
    )

    echo Postcompiler finished!

    :: VVIS
    echo Running VVIS...
    echo bin\win64\vvis.exe -game "%copypath%" "%copypath%/%filename%" [90m
    bin\win64\vvis.exe -game "%copypath%" "%copypath%/%filename%"
    echo [36m

    if "%mode%" == "Y" if %ERRORLEVEL% NEQ 0 ( 
        echo [31mVVIS failed, please check above for errors. Cannot continue, exiting.
        pause
        exit
    )

    echo VVIS finished!
    
    ::VRAD
    echo Running VRAD...
    if "%mode%" == "Y" (
        echo [33mDoing a final compile, your pc might lag!
        echo This can take a while, grab yourself a cup of coffee or tea![90m
        bin\win64\vrad.exe -final -hdr -TextureShadows -StaticPropLighting -StaticPropPolys -PortalTraversalLighting -PortalTraversalAO -lights "%p2path%/portal2/lights.rad" -game "%copypath%" "%copypath%/%filename%"
    ) else (
        echo [90m
        bin\win64\vrad.exe -hdr -StaticPropLighting -StaticPropPolys -lights "%p2path%/portal2/lights.rad" -game "%copypath%" "%copypath%/%filename%"
    )

    echo [32m

    if "%mode%" == "Y" if %ERRORLEVEL% NEQ 0 ( 
        echo [31mVRAD failed, please check above for errors. Cannot continue, exiting.
        pause
        exit
    )

    ::Game launch
    echo Finished! 
    echo [33mLaunching P2CE...
    bin\win64\%game_executable% -game "%modpath%" -novid +map %map_path%\%filename%
    pause
    exit

