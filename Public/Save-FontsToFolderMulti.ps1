function Save-FontsToFolderMulti {
    [CmdletBinding()]
    param (
        [parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Folders,
        [Switch] $Versioned,
        [Switch] $WFR,
        [Int32] $MaxThreads = 16

    )

    begin {
        $FontFolderList = [System.Collections.Generic.List[String]]@()
    }

    process {

        foreach ($Folder in $Folders) {

            $RootHasFiles = Get-ChildItem -LiteralPath $Folder | Where-Object { $_ | Get-ChildItem -File | Select-Object -First 1 }
            if($RootHasFiles){
                $FontFolderList.Add($Folder)
            }

            $InnerFolders = Get-ChildItem -LiteralPath $Folder -Directory -Recurse | Where-Object { $_ | Get-ChildItem -File | Select-Object -First 1 }
            if($InnerFolders){
                foreach ($Item in $InnerFolders) {
                    $FontFolderList.Add($Item)
                }
            }
        }
    }

    end {

        $FontFolderList | ForEach-Object -Parallel {
            $Versioned        = $Using:Versioned
            $WFR              = $Using:WFR
            $MaxThreads       = $Using:MaxThreads
            $CurrentFolder    = $_

            $Fonts = Get-ChildItem $CurrentFolder -File -Recurse | ForEach-Object {$_.FullName}
            Save-FontsToFolder -Fonts $Fonts -Versioned:$Versioned -WFR:$WFR -MaxThreads $MaxThreads | Out-Null

        } -ThrottleLimit 8
    }
}