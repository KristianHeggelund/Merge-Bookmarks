# Function to process bookmarks and add them to a unified collection
function Process-Bookmarks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Children,
        
        [Parameter(Mandatory = $true)]
        [string]$CurrentPath
    )

    foreach ($Child in $Children) {
        $NewPath = if ($CurrentPath -ne "") {
                        "$CurrentPath\$($child.Name)"
                    }
                    else {
                        $child.Name
                    }
        
        if ($child.type -eq "folder" -and $Child.Children) {
            Process-Bookmarks -Children $Child.Children -CurrentPath $NewPath
        }
        elseif ($child.type -eq "url") {
            $Child | Add-Member -NotePropertyName "Path" -NotePropertyValue $CurrentPath -Force
            [void]$AllBookmarks.Add($Child)
        }
    }
}

# Function to merge bookmarks into the Edge default bookmark file
function Merge-Bookmarks {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile
    )

    # Set default Edge bookmarks file path
    #$OutputFile = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"
    $OutputFile = ".\TestFiles\Bookmarks"

    # Create a bookmarks file with default folder structure if it doesn't exist
    if (-not (Test-Path -Path $OutputFile)) {
        $EmptyBookmarks = [ordered]@{
            checksum = "";
            roots = [ordered]@{
                bookmark_bar = [ordered]@{
                    children = @();
                    name = "Bookmarks bar";
                    type = "folder"
                };
                other = [ordered]@{
                    children = @();
                    name = "Other bookmarks";
                    type = "folder"
                };
                synced = [ordered]@{
                    children = @();
                    name = "Mobile bookmarks";
                    type = "folder"
                }
            };
            version = 1
        }
        $EmptyBookmarks | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile
    }

    # Read the input bookmarks file
    if (Test-Path -Path $InputFile) {
        $BookmarksData = Get-Content -Path $InputFile | ConvertFrom-Json 
        $AllBookmarks = New-Object System.Collections.ArrayList
        
        foreach ($RootKey in $BookmarksData.roots.PSObject.Properties.Name) {
            $Root = $BookmarksData.roots.$RootKey
            
            if ($Root.children -ne $null) {
                Process-Bookmarks -Children $Root.Children -CurrentPath $Root.Name
            }
        }
    }
    else {
        Write-Warning "File $InputFile not found. Exiting..."
        return
    }

    # Convert the collected bookmarks into a new JSON structure with "Imported Bookmarks!"
    $ExistingBookmarks = Get-Content -Path $OutputFile | ConvertFrom-Json
    $ImportedFolder = [ordered]@{
        name = [System.IO.Path]::GetFileNameWithoutExtension($InputFile);
        type = "folder";
        children = $AllBookmarks
    }
    $ExistingBookmarks.roots.bookmark_bar.children += ,$ImportedFolder

    # Export the merged bookmarks to the output file
    $ExistingBookmarks | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile
    Write-Output "Bookmarks imported successfully into $OutputFile"
}

# Example usage
$InputFile = ".\TestFiles\Google_Bookmarks"
Merge-Bookmarks -InputFile $InputFile
