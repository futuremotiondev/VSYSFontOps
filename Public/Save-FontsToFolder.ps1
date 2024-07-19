function Save-FontsToFolder {

    [CmdletBinding()]
    param (
        [parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [String[]] $Fonts,

        [Int32] $MaxThreads = 16,
        [Switch] $Versioned,
        [Switch] $WFR
    )

    begin {

        $FontList = [System.Collections.Generic.List[String]]@()

        try {
            & "$env:FM_PY_VENV\FontTools\Scripts\Activate.ps1"
        } catch {
            throw "Can't activate FontTools environment. Aborting."
        }

        if($Versioned){
            $GetFontVersionScript = "$env:FM_PY_FONT_SCRIPTS\get_font_version.py"
            if(-not(Test-Path -Path $GetFontVersionScript)){
                throw "Can't find get_font_version.py. Aborting."
            }
        }
    }

    process {
        foreach ($Font in $Fonts) {
            $FontList.Add($Font)
        }
    }

    end {

        $FontList | ForEach-Object -Parallel {

            $FontFile = $_

            $Versioned            = $Using:Versioned
            $WFR                  = $Using:WFR
            $FileName             = [System.IO.Path]::GetFileName($FontFile)
            $FileDirectory        = [System.IO.Directory]::GetParent($FontFile)
            $FileExtension        = [System.IO.Path]::GetExtension($FontFile).TrimStart('.')
            $ExtVersionedFonts    = "ttf", "otf", "woff", "woff2"
            $FontFileVersion      = ''

            if ($Versioned) {

                if ($ExtVersionedFonts -contains $FileExtension) {
                    $FontFileVersion = & python "$env:FM_PY_FONT_SCRIPTS\get_font_version.py" $FontFile

                    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
                    $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
                    $FontFileVersion = $FontFileVersion -replace $re

                    if ([string]::IsNullOrWhiteSpace($FontFileVersion)) { $FontFileVersion = '' }
                    elseif ($FontFileVersion -match '^(0.)(.*)$') { $FontFileVersion = '' }
                    elseif ($FontFileVersion -match '^(version\s)(.*)$') { $FontFileVersion = $Matches[2] }
                    elseif ($FontFileVersion -match '^(\d)\.(\d{1,2})$') { $FontFileVersion = $Matches[1] + '.' + $Matches[2] + '0'  }
                    elseif ($FontFileVersion -match '^(\d\.\d{3})(.*)$') { $FontFileVersion = $Matches[1]  }
                    elseif ($FontFileVersion -match '^(0{1,5})(\d*)\.(.*)') { $FontFileVersion = $Matches[2] + '.' + $Matches[3]  }
                }
            }

            $ExtWebFiles = "svg", "eot", "css", "html", "htm"
            $WFRLabel = ($WFR) ? 'WFR' : ''

            $Subfolder = switch ($FileExtension) {
                "otf" { "OT $FontFileVersion $WFRLabel" }
                "ttf" { "TT $FontFileVersion $WFRLabel" }
                "woff" { "WOFF $FontFileVersion $WFRLabel" }
                "woff2" { "WOFF2 $FontFileVersion $WFRLabel" }
                "vfc" { 'VFC' }
                { $ExtWebFiles -contains $_ } { 'WEB' }
                default { '00 Supplimental' }
            }

            $Subfolder = $Subfolder.Trim()

            $LicenseFiles = @("UFL.txt", "OFL.txt")
            if ($FileName -match "LICENSE" -or $LicenseFiles -contains $FileName) {
                $Subfolder = '00 License'
            }

            $DestDir = ([IO.Path]::Combine($FileDirectory, $Subfolder)).Trim()

            if (-not(Test-Path -LiteralPath $DestDir -PathType Container)) {
                [IO.Directory]::CreateDirectory($DestDir) | Out-Null
            }

            [IO.File]::Move($FontFile, [IO.Path]::Combine($DestDir, $FileName))

        } -ThrottleLimit $MaxThreads
    }
}