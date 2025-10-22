$script:ProjectName = "Test.Sbom"
$script:ProjectVersion = "1.2.3"
$script:Type = "Application"
$script:Author = "Author"

function Install-Dotnet-Cyclonedx-Locally () {
	if (-Not (Test-Path ".config/dotnet-tools.json")) {
		Write-Host "Creating dotnet tool manifest..."
		dotnet new tool-manifest
	} else {
		Write-Host "Tool manifest already exists."
	}

	Write-Host "Installing dotnet-cyclonedx version 5.5.0..."
	dotnet tool install --local CycloneDX --version 5.5.0

	Write-Host "Installed tools:"
	dotnet tool list
}

function Generate-Sbom (){
    $outputFile = "sbom-$script:ProjectName-$script:ProjectVersion.DOTNET-CYCLONEDX.json"
    
    try {
        Write-Host "Project version is: $script:ProjectVersion"

        $dotnetCyclonedxArgs = @(
            "--filename", $outputFile,
            "--output-format", "Json",
            "--set-name", $script:ProjectName,
            "--set-version", $script:ProjectVersion,
            "--set-type", $script:Type,
            "--recursive"
        )  
		
		& dotnet tool run dotnet-cyclonedx "./Test.Sbom.sln" @dotnetCyclonedxArgs
        Write-Host "SBOM successfully generated: $outputFile"
    }
    catch {
        Write-Host "Error generating SBOM: $_"
        exit 1
    }
}

function Invoke-SbomGeneration {
    try {
    	Install-Dotnet-Cyclonedx-Locally
        Generate-Sbom
    }
    catch {
        Write-Host "Fatal error in SBOM generation: $_"
        throw
    }
}

Invoke-SbomGeneration