# PowerShell script to parse bookmarks.html and add a 'Path' property to each bookmark using regex

# Read the content of the bookmarks.html file
$htmlContent = Get-Content -Path ".\TestFiles\bookmarks.html" -Raw

# Function to recursively parse the bookmarks structure using regex
function Parse-FFBookmarks {
    param (
        [string]$html,
        [string]$currentPath
    )

    $bookmarks = @()
    $folderRegex = '<H3[^>]*>(?<folderName>[^<]+)</H3>'
    $bookmarkRegex = '<A HREF="(?<url>[^"]+)"[^>]*>(?<title>[^<]+)</A>'

    # Parse folders
    $folderMatches = [regex]::Matches($html, $folderRegex)
    foreach ($folderMatch in $folderMatches) {
        $folderName = $folderMatch.Groups['folderName'].Value.Trim()
        $folderPath = if ($currentPath) { "$currentPath/$folderName" } else { "Bookmarks Toolbar" }

        # Get the content inside the folder
        $folderContentStart = $folderMatch.Index + $folderMatch.Length
        $folderContentEnd = $html.IndexOf('</DL>', $folderContentStart)
        if ($folderContentEnd -gt $folderContentStart) {
            $folderContentLength = $folderContentEnd - $folderContentStart
            $folderContent = $html.Substring($folderContentStart, $folderContentLength)

            # Recursively parse nested bookmarks within this folder
            $bookmarks += Parse-FFBookmarks -html $folderContent -currentPath $folderPath
        }
    }

    # Parse bookmarks within the current level only if the current path is not empty
    if ($currentPath -ne "") {
        $bookmarkMatches = [regex]::Matches($html, $bookmarkRegex)
        foreach ($bookmarkMatch in $bookmarkMatches) {
            $title = $bookmarkMatch.Groups['title'].Value.Trim()
            $url = $bookmarkMatch.Groups['url'].Value

            # Add the bookmark, including multiple instances if in different folders
            $bookmark = [PSCustomObject]@{
                Title = $title
                URL = $url
                Path = $currentPath
            }
            $bookmarks += $bookmark
        }
    }

    return $bookmarks
}

# Start parsing from the top-level DL tag
$allBookmarks = Parse-FFBookmarks -html $htmlContent -currentPath "Bookmarks Toolbar"

# Display the bookmarks with paths
foreach ($bookmark in $allBookmarks) {
    Write-Output "Title: $($bookmark.Title), URL: $($bookmark.URL), Path: $($bookmark.Path)"
}
