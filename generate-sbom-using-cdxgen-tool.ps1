$scriptRoot = Get-Location
$script:CdxgenPath = Join-Path $scriptRoot "node_modules/.bin/cdxgen.cmd"
$env:CDXGEN_PLUGINS_DIR = Join-Path $scriptRoot "node_modules/@cyclonedx/cdxgen-plugins-bin"
$env:CDXGEN_IN_CONTAINER = "true"
$env:FETCH_LICENSE = "true"

$script:ProjectName = "Test.Sbom"
$script:ProjectVersion = "1.2.3"
$script:BomProfile = "appsec"
$script:Author = "Author"

function Install-Cdxgen-Locally () {
	npm install --no-package-lock --save-dev @cyclonedx/cdxgen@11.10.0 @cyclonedx/cdxgen-plugins-bin@1.7.0
    
	$cdxgenPackageJsonPath = Join-Path $scriptRoot "node_modules/@cyclonedx/cdxgen/package.json"
    $cdxgenPackageJson = Get-Content $cdxgenPackageJsonPath | ConvertFrom-Json
    $cdxgenVersion = $cdxgenPackageJson.version

    Write-Host "The cdxgen version installed locally is $cdxgenVersion and path is $script:CdxgenPath"
}

function Generate-Sbom {
    $outputFile = "sbom-$script:ProjectName-$script:ProjectVersion-CDXGEN.json"
    
    try {
        Write-Host "Project version is: $script:ProjectVersion"

        $cdxgenArgs = @(
            "--type", "dotnet",
            "--output", $outputFile,
            "--project-name", $script:ProjectName,
            "--project-version", $script:ProjectVersion,
            "--author", $script:Author,
            "--profile", $script:BomProfile,
            "--deep",
            "--fail-on-error"
        )  
		
		& $script:CdxgenPath @cdxgenArgs
        Write-Host "SBOM successfully generated: $outputFile"
    }
    catch {
        Write-Host "Error generating SBOM: $_"
        exit 1
    }
}

function Invoke-SbomGeneration {
    try {
    	Install-Cdxgen-Locally
        Generate-Sbom
    }
    catch {
        Write-Host "Fatal error in SBOM generation: $_"
        throw
    }
}

Invoke-SbomGeneration