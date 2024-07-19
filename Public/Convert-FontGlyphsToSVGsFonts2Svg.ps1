function Convert-FontGlyphsToSVGsFonts2Svg {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [String[]] $Fonts,

        [Int32] $MaxThreads = 16
    )

    begin {

        & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"

        try {
            $CMDFonts2SVG = Get-Command "$env:FM_PY_VENV\FontTools\Scripts\fonts2svg.exe"
        }
        catch {
            throw "Can't find fonts2svg.exe. Aborting."
        }

        $FontList = [System.Collections.Generic.List[String]]@()
    }

    process {
        foreach ($Font in $Fonts) {
            if (Test-Path -Path $Font) {
                # Match by extension
                if($Font -match "^.+\.(ttf|otf)$"){
                    $FontList.Add($Font)
                }
                else {
                    Write-Error "Passed file is not a font. ($Font)"
                }

            } else {
                Write-Warning "Passed file does not exist on disk. ($Font)"
            }
        }
    }

    end {

        $FontList | ForEach-Object -Parallel {

            $CMDFonts2SVG = $Using:CMDFonts2SVG
            $CurrentFont = $_

            $DestPath = [System.IO.Path]::Combine(
                [System.IO.Path]::GetDirectoryName($CurrentFont),
                [System.IO.Path]::GetFileNameWithoutExtension($CurrentFont)) + " Fonts2SVG"

            if(!(Test-Path -LiteralPath $DestPath -PathType Container)){
                New-Item -Path $DestPath -ItemType Directory -Force
            }

            $Prams = $CurrentFont, "-o", $DestPath
            & $CMDFonts2SVG $Prams

        } -ThrottleLimit $MaxThreads
    }
}