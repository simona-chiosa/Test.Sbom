# CDXGEN tool doesn't generate the Dependency Graph correctly for WPF/.NET solutions - Issue Reproduction #2553

## Summary
### Support Project
To help reproduce the issue, a support WPF single-project application has been added to the repository. Two PowerShell scripts are included to generate SBOMs for this application:
* _generate-sbom-using-cdxgen-tool.ps1_ ➡️ generates the SBOM using CDXGEN.
* _generate-sbom-using-dotnet-cyclonedx-tool.ps1_ ➡️ generates the SBOM using dotnet-cyclonedx.

### Single-Project WPF Solutions
When generating the SBOM of a .NET WPF single-project solution using CDXGEN v11.10.0, the dependency graph is not constructed correctly. OWASP Dependency-Track fails to display the dependency graph entirely after uploading the SBOM.

In contrast, SBOMs generated using dotnet-cyclonedx have the dependency graph constructed correctly. OWASP Dependency-Track displays the dependency graph and distinguishes between direct and transitive dependencies in the _Dependency Graph_ and _Component_ tabs.

The issue is caused by **mismatched _bom-ref_ and _ref_ identifiers** in the SBOM. Additionally, CDXGEN incorrectly treats the project DLL and EXE files as dependencies. A temporary workaround is to manually edit the SBOM after generation.


### Multi-Project WPF Solutions
For multi-project solutions, the issue is more severe. CDXGEN treats **all project DLLs and EXEs, including test projects, as NuGet packages**. It includes **2 versions** of the same project DLLs, one with version **1.0.0** and one with **@latest**, adds references to interdependent projects, and leaves the application package empty under the dependencies element.

In contrast, SBOMs generated using dotnet-cyclonedx have the dependency graph constructed correctly. OWASP Dependency-Track displays the dependency graph and distinguishes between direct and transitive dependencies in the _Dependency Graph_ and _Component_ tabs.

Example command:
```sh
cdxgen --type dotnet --output "app.sbom.json" --project-name "App.Client" --project-version 1.0.0 --author "Author" --profile "appsec" --deep --fail-on-error
```

Example warnings in logs:
```xml
Querying nuget for WixSharp.wix.bin
MaxListenersExceededWarning: Possible event memory leak detected. 232 error listeners added. Use setMaxListeners() to increase limit.
Found 183 csharp packages at C:\Repositories\app-client\App.Client
Obtained 183 components and 191 dependencies after dedupe.
===== WARNINGS =====
[ 'BOM likey has too many framework components. Count: 35' ]
===== WARNINGS =====
[
  'Invalid ref in dependencies pkg:nuget/UpdateManager@latest',
  'Invalid ref in dependencies pkg:nuget/App.UpdateManager@latest?output_type=WinExe',
  'Invalid ref in dependencies pkg:nuget/App.Module.Module2.Test@latest',
  'Invalid ref in dependencies pkg:nuget/App.Module.Module2@latest',
  'Invalid ref in dependencies pkg:nuget/App.Module.Module1.Test@latest',
  'Invalid ref in dependencies pkg:nuget/App.Module.Module1@latest',
  'Invalid ref in dependencies pkg:nuget/App.Module..Test@latest',
  'Invalid ref in dependencies pkg:nuget/App.Module.@latest',
  'Invalid ref in dependencies pkg:nuget/App.Common.Test@latest',
  'Invalid ref in dependencies pkg:nuget/App.Common@latest',
  'Invalid ref in dependencies pkg:nuget/App.Client.Test@latest',
  'Invalid ref in dependencies pkg:nuget/App.Client.Installer@latest?output_type=Exe',
  'Invalid ref in dependencies pkg:nuget/App.Client@latest?output_type=WinExe',
  "Parent component pkg:application/App.Client@1.0.0 doesn't have any children. The dependency tree must contain dangling nodes, which are unsupported by tools such as Dependency-Track."
]
```

Snippet from the SBOM from "dependencies" key-value pair:
```xml
    {
      "ref": "pkg:nuget/App.Module2@1.0.0",
      "dependsOn": [
        "pkg:nuget/App.Common@1.0.0",
        "pkg:nuget/QRCoder@1.6.0"
      ]
    },
    {
      "ref": "pkg:nuget/App.Module2@latest",
      "dependsOn": [
        "pkg:nuget/QRCoder@1.6.0",
        "pkg:nuget/iTextSharp-4.1.6"
      ]
    },
    {
      "ref": "pkg:nuget/App.Client.Installer@latest?output_type=Exe",
      "dependsOn": [
        "pkg:nuget/WixSharp.bin@1.20.2",
        "pkg:nuget/WixSharp.wix.bin@3.11.2"
      ]
    },
    {
      "ref": "pkg:nuget/App.Client@latest?output_type=WinExe",
      "dependsOn": [
        "pkg:nuget/Microsoft.EntityFrameworkCore.Design@8.0.11",
        "pkg:nuget/QRCoder@1.6.0"
      ]
    },
    {
      "ref": "pkg:application/App.Client@1.0.0",
      "dependsOn": []
    }
```


## Related Issue  
- [cdxgen Issue ](https://github.com/CycloneDX/cdxgen/issues/2553)  

## Environment     
- **cdxgen** v11.10.0
- **cdxgen-plugins-bin** v1.7.0
- **dotnet-cyclonedx** v5.5.0
- **OWASP Dependency-Track** v4.12.2
- **Host OS:** Windows 11

## Steps to Reproduce (Single-Project)

1. Clone this repository and navigate to the project directory.  
2. Open a Windows PowerShell terminal and execute the script:
    ```sh
    generate-sbom-using-cdxgen-tool.ps1
3. The script downloads the CDXGEN tool locally and generates the SBOM: _sbom-Test.Sbom-1.2.3.0-CDXGEN.json_.
4. Create a _Test CDXGEN_ project of type Application in the OWASP Dependency-Track.
5. Upload the generated SBOM.

**Observed Behavior:**
- This error is logged when the SBOM is generated:
    ```xml
    ===== WARNINGS =====
    [
    'Invalid ref in dependencies pkg:nuget/Test.Sbom@latest?output_type=WinExe'
    ]
    ```
- The SBOM is uploaded successfully
- The Direct Only toggle in the Component tab does not work.
- The Dependency Graph tab does not display any graph.


## Steps to Reproduce (Using dotnet-cyclonedx)
1. Clone this repository and navigate to the project directory.  
2. Open a Windows PowerShell terminal and execute the script:
    ```sh
    generate-sbom-using-dotnet-cyclonedx-tool.ps1
3. The script downloads the dotnet-cyclonedx tool locally and generates the SBOM for the WPF application: _sbom-Test.Sbom-1.2.3.0.DOTNET-CYCLONEDX.json_.
4. Create a _Test DOTNET CYCLONEDX_ project of type Application in the OWASP Dependency-Track.
5. Upload the generated SBOM.

**Observed Behavior**
- The SBOM is uploaded successfully.
- The Direct Only toggle works correctly.
- The Dependency Graph tab displays the full graph with direct and transitive dependencies.


## Workaround for Single-Project Solutions
1. The probem is caused by the mismatched _bom-ref_ and _ref_ identifiers.
2. After generting the SBOM, change the line 747 FROM
    ```xml
    "ref": "pkg:nuget/Test.Sbom@1.2.3",
    ```
    TO
    ```xml
    "ref": "pkg:application/Test.Sbom@1.2.3",
    ```

Please notice that the cdxgen tool treats the **DLL** and **EXE** files generated for the project as a dependency. See lines 55-63 and 805-812:
```xml
  "components": [
    {
      "group": "",
      "name": "Test.Sbom",
      "version": "1.2.3",
      "purl": "pkg:nuget/Test.Sbom@1.2.3",
      "type": "application",
      "bom-ref": "pkg:nuget/Test.Sbom@1.2.3"
    },
```
```xml
    {
      "ref": "pkg:nuget/Test.Sbom@latest?output_type=WinExe",
      "dependsOn": [
        "pkg:nuget/Newtonsoft.Json@13.0.3",
        "pkg:nuget/PdfSharpCore@1.3.67",
        "pkg:nuget/SQLitePCLRaw.bundle_e_sqlite3@2.1.11"
      ]
    }
```


