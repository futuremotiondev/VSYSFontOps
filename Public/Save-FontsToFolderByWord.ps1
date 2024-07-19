function Save-FontsToFolderByWord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        $Files,

        [Parameter(Mandatory=$false)]
        [Int32]
        $NumWords = 1,

        [Parameter(Mandatory=$false)]
        [Switch]
        $WholeName,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName)]
        [Int32]
        $MaxThreads = 16
    )

    begin {

        & "D:\Dev\Python\00 VENV\FontTools\Scripts\Activate.ps1"
        $VersionScript = "$env:FM_PY_FONT_SCRIPTS\get_font_version.py"

        $List = [System.Collections.Generic.List[String]]::new()
    }

    process {
        try {
            foreach ($P in $Files) {
                if	 ($P -is [String]) { $List.Add($P) }
                elseif ($P.Path)       { $List.Add($P.Path) }
                elseif ($P.FullName)   { $List.Add($P.FullName) }
                elseif ($P.PSPath)     { $List.Add($P.PSPath) }
                else { Write-Error "Invalid argument passed to files parameter." }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    end {

        try{
            $List | ForEach-Object -Parallel {

                $FontFile = $_

                $FontFileName      = [System.IO.Path]::GetFileName($FontFile)
                $FontDirectory     = [System.IO.Directory]::GetParent($FontFile)

                $FontFileVersion = & python $Using:VersionScript $FontFile

                $doWholeName = $Using:WholeName

                if(!$doWholeName){
                    if($Using:NumWords -eq 1){
                        $RegExWord = '^(\w+)\b'
                        $RegExReplace = '$1\$0'
                    }

                    if($Using:NumWords -eq 2){
                        $RegExWord = '^(\w+)[\s|\-](\w+)\b'
                        $RegExReplace = '$1 $2\$0'
                    }

                    if($Using:NumWords -eq 3){
                        $RegExWord = '^(\w+)[\s|\-](\w+)[\s|\-](\w+)\b'
                        $RegExReplace = '$1 $2 $3\$0'
                    }

                    # Insert the first word occuring in the filename
                    # as a prefixed subdirectory
                    $Step1 = $FontFileName
                    $Step2 = $Step1 -replace $RegExWord, $RegExReplace

                    # Remove everything after the first '\' Leaving
                    # Just the first word.
                    $parts = $Step2 -split '\\'
                    $Step3 = $parts[0]

                    # Whitespace Cleanup
                    $Step4 = $Step3 -replace '\s+', ' '
                    $Step4 = $Step4.Trim()

                    # Camel Case Conversion
                    $Step5 = $Step4 -csplit '(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])', -join ' '
                    Write-Host "`$Step5:" $Step5 -ForegroundColor Green

                    # Edge Case, Rename "Screen Smart" fonts correctly.
                    $Step6 = $Step5 -replace ' S Sm', ' SSm'
                } else {
                    $Step6 = [System.IO.Path]::GetFileNameWithoutExtension($FontFile)
                }

                $FontExt = [IO.Path]::GetExtension($FontFile)
                if($FontExt -eq '.ttf'){
                    $NextPathPart = 'TT'
                }elseif($FontExt -eq '.otf'){
                    $NextPathPart = 'OT'
                }else{
                    if ( $FontExt -match ".eot" -or
                         $FontExt -match ".svg" -or
                         $FontExt -match ".css" -or
                         $FontExt -match ".woff" -or
                         $FontExt -match ".woff2" -or
                         $FontExt -match ".html" ){
                            $NextPathPart = 'WEB'
                         }
                }

                if([String]::IsNullOrWhiteSpace($FontFileVersion)){
                    $PathNoFn = "$FontDirectory\$Step6\$NextPathPart\"
                }else{
                    $PathNoFn = "$FontDirectory\$Step6\$NextPathPart $FontFileVersion\"
                }

                if(!(Test-Path -LiteralPath $PathNoFn -PathType Container)){
                    [IO.Directory]::CreateDirectory($PathNoFn) | Out-Null
                }

                $FinStep = [IO.Path]::Combine($PathNoFn, $FontFileName)
                [IO.File]::Move($FontFile, $FinStep)

            } -ThrottleLimit $MaxThreads
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}