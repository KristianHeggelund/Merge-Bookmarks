# Define the paths to the bookmarks JSON files
$bookmarkFilePaths = @(
    "./TestFiles/Edge_bookmarks",
    "./TestFiles/Google_bookmarks"
)
# Define the path for the new bookmarks JSON file
$newBookmarkFilePath = "./TestFiles/bookmarks"

# Check if the bookmarks JSON file already exists
if (-Not (Test-Path -Path $newBookmarkFilePath)) {
    # Create an empty structure if the file does not exist
    $emptyRoots = [PSCustomObject]@{
        bookmark_bar = [PSCustomObject]@{
            type        = "folder"
            name        = "Favorites bar"
            children    = @()
            date_added  = (Get-Date).ToFileTimeUtc().ToString()
            guid        = [guid]::NewGuid().ToString()
            id          = "1"
            date_last_used = "0"
            date_modified = (Get-Date).ToFileTimeUtc().ToString()
            source      = "user"
        }
        other = [PSCustomObject]@{
            type        = "folder"
            name        = "Other favorites"
            children    = @()
            date_added  = (Get-Date).ToFileTimeUtc().ToString()
            guid        = [guid]::NewGuid().ToString()
            id          = "2"
            date_last_used = "0"
            date_modified = "0"
            source      = "user"
        }
        synced = [PSCustomObject]@{
            type        = "folder"
            name        = "Mobile favorites"
            children    = @()
            date_added  = (Get-Date).ToFileTimeUtc().ToString()
            guid        = [guid]::NewGuid().ToString()
            id          = "3"
            date_last_used = "0"
            date_modified = "0"
            source      = "user"
        }
    }
    
    $emptyBookmarksJson = [PSCustomObject]@{
        checksum = ""
        roots    = $emptyRoots
        version  = 1
    } | ConvertTo-Json -Depth 20

    # Save the empty structure to the new file
    $emptyBookmarksJson | Set-Content -Path $newBookmarkFilePath
}

# Load the existing bookmarks JSON file
$bookmarksJson = Get-Content -Path $newBookmarkFilePath -Raw | ConvertFrom-Json

# Initialize an empty array to store the imported children from all files
$allImportedChildren = $bookmarksJson.roots.bookmark_bar.children

# Define a function to recursively copy folders and bookmarks
function Copy-Bookmarks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$children
    )

    $newChildren = @()
    foreach ($child in $children) {
        if ($child.type -eq "url") {
            # If it's a bookmark, copy it to the new structure
            $newChild = [PSCustomObject]@{
                type        = "url"
                name        = $child.name
                url         = $child.url
                date_added  = $child.date_added
                guid        = $child.guid
                id          = $child.id
                date_last_used = $child.date_last_used
                visit_count = $child.visit_count
                source      = $child.source
            }
            $newChildren += $newChild
        } elseif ($child.type -eq "folder") {
            # If it's a folder, copy it and process its children recursively
            $newFolder = [PSCustomObject]@{
                type        = "folder"
                name        = $child.name
                date_added  = $child.date_added
                guid        = $child.guid
                id          = $child.id
                children    = @()
                date_last_used = $child.date_last_used
                date_modified = $child.date_modified
                source      = $child.source
            }
            if ($child.children.Count -gt 0) {
                $newFolder.children = Copy-Bookmarks -children $child.children
            }
            $newChildren += $newFolder
        }
    }
    return $newChildren
}

# Iterate through each bookmark file and parse the structure
foreach ($bookmarkFilePath in $bookmarkFilePaths) {
    # Load and parse the JSON file
    $fileBookmarksJson = Get-Content -Path $bookmarkFilePath -Raw | ConvertFrom-Json

    # Copy the original folder and bookmark structure
    $importedChildren = @()
    $roots = $fileBookmarksJson.roots
    if ($roots.bookmark_bar.children.Count -gt 0) {
        $importedChildren += Copy-Bookmarks -children $roots.bookmark_bar.children
    }
    if ($roots.other.children.Count -gt 0) {
        $importedChildren += Copy-Bookmarks -children $roots.other.children
    }
    if ($roots.synced.children.Count -gt 0) {
        $importedChildren += Copy-Bookmarks -children $roots.synced.children
    }

    # Add a new top-level folder named after the input file
    $newFolderName = [System.IO.Path]::GetFileNameWithoutExtension($bookmarkFilePath)
    $newFolder = [PSCustomObject]@{
        type        = "folder"
        name        = "$newFolderName Imported"
        date_added  = (Get-Date).ToFileTimeUtc().ToString()
        guid        = [guid]::NewGuid().ToString()
        id          = [guid]::NewGuid().ToString()
        children    = $importedChildren
        date_last_used = "0"
        date_modified = (Get-Date).ToFileTimeUtc().ToString()
        source      = "user"
    }

    # Add the imported children from this file to the overall collection
    $allImportedChildren += $newFolder
}

# Update the roots object with the imported folders
$bookmarksJson.roots.bookmark_bar.children = $allImportedChildren

# Create a new JSON object with the updated roots
$newBookmarksJson = $bookmarksJson | ConvertTo-Json -Depth 20

# Save the modified bookmarks JSON to a new file
$newBookmarksJson | Set-Content -Path $newBookmarkFilePath
