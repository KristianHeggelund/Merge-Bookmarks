function Process-Bookmarks{
    param (
        [Parameter(Mandatory = $true)]
        [array]$Children,
        
        [Parameter(Mandatory = $true)]
        [string]$CurrentPath
    )

    foreach ($Child in $Children){
        $NewPath = if ($CurrentPath -ne "") {
                        "$CurrentPath\$($child.Name)"
                    }
                    else{
                        $child.Name
                    }
        
        if ($child.type -eq "folder" -and $Child.Children){
            Process-Bookmarks -Children $Child.Children -CurrentPath $NewPath
        }
        elseif ($child.type -eq "url"){
            $Child | Add-Member -NotePropertyName "Path" -NotePropertyValue $CurrentPath -Force
            [void]$AllBookmarks.add($Child)
        }
    }
}

#Import stuff
$BookmarksFile = ".\Google_Bookmarks"
$BookmarksData = Get-Content -Path $BookmarksFile | ConvertFrom-Json 
$AllBookmarks = New-Object System.Collections.ArrayList
foreach ($RootKey in $BookmarksData.roots.PSObject.Properties.Name){
    $Root = $BookmarksData.roots.$RootKey
   
    if ($root.children -ne $null) {
        Process-Bookmarks -Children $Root.Children -CurrentPath $Root.Name
    }
}
