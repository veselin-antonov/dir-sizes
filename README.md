# dir-sizes

# Directory Size Analyzer

A PowerShell script to analyze and display the sizes of directories within a specified path. The script can sort the output, provide detailed debug information, and even display the total size of all directories combined.

## Features

- Calculate and display the size of all directories within a specified path.
- Sort the results in ascending or descending order.
- Option to display the total size of all directories combined.
- Debug mode to provide detailed output and error handling.
- Customizable output with color coding based on directory size.

## Usage

```powershell
.\dir-sizes.ps1 [[-Path] <string>] [-Sort {Asc | Desc}] [-Current] [-Debug] [-Total] [-?]
