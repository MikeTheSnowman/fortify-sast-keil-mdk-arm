Param(
	[Parameter(Mandatory=$true)][string]$buildId,
	[Parameter(Mandatory=$true)][string]$sourceFileRelativePath,
	[Parameter(Mandatory=$true)][string]$outputObjDirPath
)

###############
# DOCUMENTATION:
# This script is was written to work with Fortify SCA version 24.2.x and newer.
# The intent of this script is to provide a way to integrate Fortify SAST scanning 
# with Keil uVision where the ArmCC compiler is being used.
# The reason why this script is needed is because uVision will generate a collection
# of files with at ".__i" extension, which contains all the compiler options needed
# to compile each source file. This script will find that file, extract the compiler
# options, and construct a call to sourceanalyzer.
#
# INSTALLATION & SETUP:
# 1.) Add the following property to the Fortify settings file (<fortify_install_dir>\Core\config\fortify-sca.properties):
#     com.fortify.sca.compilers.armcc  = com.fortify.sca.util.compilers.UnsupportedCCompiler
# 2.) In the same properties file, comment the following property:
#     #com.fortify.sca.compilers.armcc  = com.fortify.sca.util.compilers.ArmCcCompiler
#
# 3.) Copy this script (fsca-translate) to the same directory as where the armcc.exe
#     is located. Ensure that directory directory has also been added to the system's
#     PATH environment variable.
# 4.) Restart uVision.
# 5.) Open uVision and populate the pre-build, pre-compile, and post-build scripts 
#     that need to be run in the "Options for target" settings.
#
#     # "Before Compile C/C++ File" script:
#     Example command to be provided to uVisions "Before Compile C/C++ File" script:
#     powershell -C C:\Keil-5.18a\Keil_v5\ARM\ARMCC\bin\fsca-translate.ps1 "CHANGE_ME_BUILD_ID" !F $L
#
#     # "Before Build/Rebuild" script:
#     Example command to be provided to uVisions "Before Build/Rebuild" script:
#     sourceanalyzer -b CHANGE_ME_BUILD_ID -clean
#
#     # "After Build/Rebuild" script:
#     Example command to be provided to uVisions "After Build/Rebuild" script:
#     sourceanalyzer -b CHANGE_ME_BUILD_ID -scan -f scan.fpr
#
# 6.) Run a "Rebuild" and wait for uVision to complete the translation and scan of
#     the project.
#
###############

$supportedExtensions = $(".c",".cc",".cpp")

function print-debug(){
	
	Write-Output "=========="
	Write-Output "  Build ID:                    $buildId"
	Write-Output "  Source file (relative path): $sourceFileRelativePath"
	Write-Output "  Output obj dir:              $outputObjDirPath"
	Write-Output "=========="
	
}

# Searches through all of the via files to find the correct one.
function getViaFile(){
    # The hashmap that we will return
    $viaFile = @{}

    # Getting just the base file name, without extension
	$srcFileBaseName = $sourceFileRelativePath.Split("\")[-1]
	$extensionPos = $srcFileBaseName.LastIndexOf(".")
	if($extensionPos -gt 0){$srcFileBaseName = $srcFileBaseName.SubString(0, $extensionPos)}

    # Then we get all the via files that might be the correct one
	$candidates = ls "$outputObjDirPath\$srcFileBaseName*.__i"
    
    if($candidates.Count -eq 0){
        throw "No valid source file was specified"
        exit 1
    }elseif($candidates.Count -eq 1){
        # If there's only one candidate, then we just assume it's the correct via file
        $viaFile["path"] = $candidates[0]
        $viaFile["contents"] = [string] (Get-Content $candidates[0])
    }elseif($candidates.Count -ge 2){
        # If there's more than one candidate, then we evaluate each on to see if one of them contains a string that matches $sourceFileRelativePath
        foreach($file in $candidates){
            # Get contents of candidate via file and test to see if there's a string that matches $sourceFileRelativePath
            $tViaContents = gc $file
            if($tViaContents -like "*`"$sourceFileRelativePath`"*"){
                $viaFile["path"] = $f
                $viaFile["contents"] = [string]$tViaContents
            }
        }
    }

    # Quick sanity check
    if($viaFile["contents"].Length -le 0 -or $viaFile["contents"] -eq $null){    
        throw "Couldn't find the correct via file."
        exit 1
    }else{
        #Write-Host "VIA FILE FOUND!"
    }
    return $viaFile
}

# Quick check to make sure that we're working with a supported file 
#print-debug
$isSupportedFileType = $false
foreach($extension in $supportedExtensions){
    if($sourceFileRelativePath.EndsWith($extension)){
        $isSupportedFileType = $true
        break
    }
}

if(-not $isSupportedFileType){
    Write-Output "Source file is not a supported type. ($($sourceFileRelativePath.Split("\")[-1]))"
    exit 0
}

$foundViaFile = getViaFile
$fScaCommand = "sourceanalyzer `"-Dcom.fortify.sca.ctran.clang-args=''`" -b $buildId armcc.exe " + $foundViaFile["contents"]
# Uncomment the line below if you need the debug log files from running translation.
#$fScaCommand = "sourceanalyzer -debug -logfile log.txt `"-Dcom.fortify.sca.ctran.clang-args=''`" -b $buildId armcc.exe " + $foundViaFile["contents"]
Write-Output "Fortify Translation: $fScaCommand"
Invoke-Expression $fScaCommand
