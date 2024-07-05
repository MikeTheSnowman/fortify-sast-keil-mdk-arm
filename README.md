# DOCUMENTATION:

This script is was written to work with Fortify SCA version 24.2.x and newer.
The intent of this script is to provide a way to integrate Fortify SAST scanning 
with Keil uVision where the ArmCC compiler is being used.
The reason why this script is needed is because uVision will generate a collection
of files with at ".__i" extension, which contains all the compiler options needed
to compile each source file. This script will find that file, extract the compiler
options, and construct a call to sourceanalyzer.

# INSTALLATION & SETUP:

1. Add the following property to the Fortify settings file (`<fortify_install_dir>\Core\config\fortify-sca.properties`):

    `com.fortify.sca.compilers.armcc  = com.fortify.sca.util.compilers.UnsupportedCCompiler`
   
2. In the same properties file, comment the following property:

   `#com.fortify.sca.compilers.armcc  = com.fortify.sca.util.compilers.ArmCcCompiler`
   
3. Copy this script (`fsca-translate.ps1`) to the same directory as where the armcc.exe
    is located. Ensure that directory directory has also been added to the system's
    PATH environment variable.
   
4. Restart uVision.

5. Open uVision and populate the pre-build, pre-compile, and post-build scripts 
    that need to be run in the "Options for target" settings.
   - Example command to be provided to uVisions "Before Compile C/C++ File" script:
     - `powershell -C C:\Keil-5.18a\Keil_v5\ARM\ARMCC\bin\fsca-translate.ps1 "CHANGE_ME_BUILD_ID" !F $L`
   - Example command to be provided to uVisions "Before Build/Rebuild" script:
     - `sourceanalyzer -b CHANGE_ME_BUILD_ID -clean`
   - Example command to be provided to uVisions "After Build/Rebuild" script:
     - `sourceanalyzer -b CHANGE_ME_BUILD_ID -scan -f scan.fpr`

6. Run a "Rebuild" and wait for uVision to complete the translation and scan of
    the project.

# Other Important Notes:
- This new integration will not work with versions of Fortify that are older than 24.2.
- The new integration uses a new Fortify feature that's currently only available with Fortify version 24.2. This new Fortify feature is not documented and is currently not supported.
- This integration only requires the use of one powershell script to be "installed".
- I've only tested this integration with about 5 simple projects. I do not consider this to be a lot of testing, and because of that, there still might be bugs.
- The speed of completing the "translation step" is still slow. This is because sourceanalyzer gets called on every source file to compile and translate it.
- Scan results with this new integration method and because the scan is being done with a much newer version of Fortify, the scan results have more accurate findings.
