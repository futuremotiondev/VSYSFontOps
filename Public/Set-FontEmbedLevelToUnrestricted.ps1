<#
.SYNOPSIS
    Converts the font embed level to unrestricted.

.DESCRIPTION
    The Set-FontEmbedLevelToUnrestricted function converts the font embed level to unrestricted using the FontTools library.
    The function supports both wildcard and literal paths.

.PARAMETER Path
    Specifies the paths to process. This parameter accepts pipeline input and can be a string, or an object with a Path, FullName, or PSPath property.

.PARAMETER LiteralPath
    Specifies the literal paths to process. This parameter accepts pipeline input and can be a string, or an object with a PSPath property. Wildcard characters are not acceptable with this parameter.

.EXAMPLE
    Set-FontEmbedLevelToUnrestricted -Path "C:\Fonts\*.ttf"

    This example converts the font embed level to unrestricted for all TrueType font files in the "C:\Fonts" directory.

.AUTHOR
    Futuremotion
    https://www.github.com/fmotion1
#>
function Set-FontEmbedLevelToUnrestricted {

    [cmdletbinding()]
    param(
        [parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Fonts
    )

    begin {

        try {
            & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
        }
        catch {
            throw "Can't activate FontTools environment. Aborting."
        }
    }

    process {

        $CMDftcli = Get-Command ftcli
        foreach ($Font in $Fonts) {
            if (Test-Path -Path $Font) {
                if($Font -match "^.+\.(otf|ttf)$"){
                    $Params = 'os2', 'set-flags', '--embed-level', '0', $Font
                    & $CMDftcli $Params
                }
            }
        }
    }

    end {
        & deactivate
    }
}