param (
    [string]$Path,
    [switch]$Current,
    [switch]$Debug,
    [switch]$Total,
    [ValidateSet("Asc", "Desc")]
    [string]$Sort = "Asc",
	[Alias("?", "Help")][switch]$ShowUsage  
)

if ($ShowUsage) {
    @"
NAME
    Dir-Sizes

SYNOPSIS
    Displays the sizes of directories in the specified path.

SYNTAX
    Dir-Sizes [[-Path] <string>] [-Sort {Asc | Desc}] [-Current] [-Debug] [-Total] [-?]

DESCRIPTION
    This script calculates and displays the sizes of directories in the specified path. It supports sorting,
    debugging, and scanning the current directory.

PARAMETERS
    -Path <string>
        The path to the directory you want to scan. If not specified, use -Current to scan the current directory.

    -Sort {Asc | Desc}
        Sort the output by size in ascending (Asc) or descending (Desc) order. Default is Desc.
        If provided without a value, defaults to 'Desc' with a warning.

    -Current
        Scan the current directory instead of specifying a path.

    -Debug
        Enable debug output to show detailed processing information.

    -Total
        Display the total size of all directories combined.

    -?, -Help
        Display this help message.

EXAMPLES
    Dir-Sizes "C:\MyFolder" -Sort Asc
    Dir-Sizes -Current -Debug
    Dir-Sizes -?

REMARKS
    This script is custom-built for directory size analysis. For additional details, refer to the script's documentation.
"@
    exit
}

# Validate the Sort parameter
if ($Sort -notin @("Asc", "Desc")) {
    Write-Host "Error: Invalid value for -Sort. Use 'Asc' or 'Desc'."
    exit 1
}

# Determine the target directory
if ($Current -and $Path) {
	Write-Host "Error: Can't use the `"-Current`" flag when a path is specified."
	exit 1
} elseif ($Current) {
    $TARGET_DIR = Get-Location
} elseif ($Path) {
    if (Test-Path -Path $Path -PathType Container) {
        $TARGET_DIR = $Path
    } else {
        Write-Host "Error: Invalid directory path provided."
        exit 1
    }
} else {
    Write-Host "No path specified. Type `"-?`" or `"-Help`" for usage."
    exit 1
}

if (-not $Sort) {
	$Sort = "Asc"
}

# Function to convert bytes to appropriate units
function Convert-Size {
    param (
        [float]$bytes
    )
	
    switch ($bytes) {
        { $_ -ge 1GB } { return ("{0:N2} GB" -f ($bytes / 1GB)) }
        { $_ -ge 1MB } { return ("{0:N2} MB" -f ($bytes / 1MB)) }
        { $_ -ge 1KB } { return ("{0:N2} KB" -f ($bytes / 1KB)) }
        default { return ("{0:N2} B" -f $bytes) }
    }
}

# Function to get a color for the respective size
function Color-By-Size {
    param (
		[float]$sizeInBytes
	)
	
    switch ($sizeInBytes) {
        { $_ -ge 5GB } { return "DarkMagenta" }
        { $_ -ge 1GB } { return "DarkYellow" }
        { $_ -ge 100MB } { return "Yellow" }
        default { return "Green" }
    }
}

# Initialize the hashtable to store directory sizes
$dir_sizes = @{}
# Variable to store the length of the longest directory name
$max_name_length = 0
# Variable to store the total size
$total_size = 0

# Get a list of subdirectories and calculate their sizes
Get-ChildItem -Path $TARGET_DIR -Directory | ForEach-Object {
	$dir_name = $_.Name
	
	# Update the maximum name length if the current directory name is longer
	if ($dir_name.Length -gt $max_name_length) {
		$max_name_length = $dir_name.Length
	}
	
	$errors = @()
	
	$dir_size = (Get-ChildItem -Path $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue -ErrorVariable errors | Measure-Object -Property Length -Sum).Sum

	$total_size += $dir_size

	# Add to the hashtable
	$dir_sizes[$dir_name] = $dir_size
	
	$color = Color-By-Size $dir_size
	
	if ($Debug) {
		# Print the size immediately after calculation
		$formatted_size = Convert-Size -bytes $dir_size
		Write-Host "${dir_name}: ${formatted_size}" -ForegroundColor $color
		
		# Report any captured errors
		if ($errors) {
			Write-Host "    Skipped files:" -ForegroundColor DarkRed
			foreach ($error in $errors) {
				Write-Host "        $($error.TargetObject) - Access denied." -ForegroundColor DarkRed
			}
		}
	}
}

if ($Total) {
	$dir_sizes["Total"] = $total_size
}

$name_width=[Math]::Max(9, $max_name_length) + 3

# Sort the directory sizes based on the -Sort option
$sorted_dirs = if ($Sort -eq "Desc") {
    $dir_sizes.GetEnumerator() | Sort-Object Value -Descending
} else {
    $dir_sizes.GetEnumerator() | Sort-Object Value
}

# Display the results in a table format sorted by size in descending order
Write-Host ("`n{0,-$name_width}Size" -f "Directory") -ForegroundColor White
Write-Host ("{0,-$name_width}----" -f "---------") -ForegroundColor White
foreach ($entry in $sorted_dirs) {
    $dir_name = $entry.Key
    $dir_size = $entry.Value
	
    $formatted_size = Convert-Size -bytes $dir_size
    
    # Determine the color based on the size
    $color = Color-By-Size $dir_size

    # Manual table formatting with color
    $output = "{0,-$name_width}[$formatted_size]" -f $dir_name
    Write-Host $output -ForegroundColor $color
}