<# 
Check-WinUI3-Env.ps1
Vérifie l’environnement pour développer/compilier une appli WinUI 3 + Windows App SDK
- OS : Windows 10 1809+ (build >= 17763)
- Windows SDK : présence du Windows 10/11 SDK (et, si possible, 10.0.26100.*)
- .NET SDK : 9.x (recommandé) ou 8.x
- Visual Studio 2022 + MSBuild (optionnel si tu compiles via CLI, mais conseillé)
- WebView2 Runtime Evergreen (utile pour le contrôle WebView2)
- NuGet : présence des packages Microsoft.WindowsAppSDK 1.8.* et Microsoft.WindowsAppSDK.WinUI 1.8.*
- (Option) Validation du .csproj : <UseWinUI>true</UseWinUI>, TargetFramework net8/9 -windows10.0.19041.0
#>

param(
  [string]$ProjectCsprojPath = ""
)

# ---------------- Helpers ----------------
$global:FAIL = 0
function Write-Result {
  param([string]$Name,[string]$Status,[string]$Detail="")
  $prefix = switch ($Status) {
    "PASS" { "[OK]   " }
    "WARN" { "[WARN] " }
    "FAIL" { "[FAIL] " }
    default { "[INFO] " }
  }
  if ($Status -eq "FAIL") { $global:FAIL++ }
  if ([string]::IsNullOrWhiteSpace($Detail)) {
    Write-Host ($prefix + $Name)
  } else {
    Write-Host ($prefix + $Name + " - " + $Detail)
  }
}

function Test-Command { param([string]$Cmd) try { $null = Get-Command $Cmd -ErrorAction Stop; $true } catch { $false } }
function Test-PathSafe { param([string]$p) try { Test-Path $p } catch { $false } }

# ---------------- OS ----------------
$os = Get-CimInstance Win32_OperatingSystem
$build = [int]$os.BuildNumber
$releaseId = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
if ($build -ge 17763) {
  Write-Result "Windows version" "PASS" "Build $build (ok pour WinAppSDK)"
} else {
  Write-Result "Windows version" "FAIL" "Build $build < 17763 (Windows 10 1809+ requis)"
}

# ---------------- Windows SDK ----------------
$kitsRootKey = "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots"
$kitsRoot = (Get-ItemProperty -Path $kitsRootKey -ErrorAction SilentlyContinue)
$haveKits = $false
$have26100 = $false
if ($kitsRoot -and $kitsRoot.KitsRoot10) {
  $root = $kitsRoot.KitsRoot10
  if (Test-PathSafe $root) {
    $includeDir = Join-Path $root "Include"
    $haveKits = Test-PathSafe $includeDir
    if ($haveKits) {
      $sdks = Get-ChildItem $includeDir -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
      if ($sdks) {
        if ($sdks -match "^10\.0\.26100") { $have26100 = $true }
        Write-Result "Windows SDK (Include)" "PASS" ("Trouvés: " + ($sdks -join ", "))
      }
    }
  }
}
if (-not $haveKits) { Write-Result "Windows SDK" "FAIL" "Non trouvé dans $kitsRootKey / KitsRoot10" }
elseif (-not $have26100) { Write-Result "Windows SDK 10.0.26100" "WARN" "Recommandé (Win11 24H2), mais d’autres versions peuvent suffire" }
else { Write-Result "Windows SDK 10.0.26100" "PASS" }

# ---------------- .NET SDK ----------------
if (Test-Command "dotnet") {
  $sdks = (& dotnet --list-sdks) 2>$null
  if ($sdks) {
    $hasNet9 = $sdks -match "^\s*9\."
    $hasNet8 = $sdks -match "^\s*8\."
    if ($hasNet9) { Write-Result ".NET SDK 9.x" "PASS" }
    else { Write-Result ".NET SDK 9.x" "WARN" "Recommandé pour WinUI3 (mais 8.x fonctionne aussi)" }
    if ($hasNet8) { Write-Result ".NET SDK 8.x" "PASS" }
    else { Write-Result ".NET SDK 8.x" "WARN" "Optionnel" }
  } else {
    Write-Result ".NET SDK" "FAIL" "dotnet installé mais aucune SDK listée"
  }
} else {
  Write-Result "dotnet CLI" "FAIL" "Non trouvé"
}

# ---------------- Visual Studio & MSBuild ----------------
# vswhere pour VS 2022
$vswhere = "$Env:ProgramFiles(x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-PathSafe $vswhere) {
  $vsInfo = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath 2>$null
  if ($vsInfo) {
    Write-Result "Visual Studio" "PASS" $vsInfo
    $msbuild = Join-Path $vsInfo "MSBuild\Current\Bin\MSBuild.exe"
    if (Test-PathSafe $msbuild) { Write-Result "MSBuild" "PASS" $msbuild } else { Write-Result "MSBuild" "FAIL" "Introuvable dans $vsInfo" }
  } else {
    Write-Result "Visual Studio" "WARN" "Non trouvé par vswhere (ok si build 100% CLI)"
  }
} else {
  Write-Result "vswhere" "WARN" "Non trouvé (installer Visual Studio 2022 pour MSBuild/Designer)"
}

# ---------------- WebView2 Runtime Evergreen ----------------
# On cherche un client EdgeUpdate contenant "WebView2 Runtime"
$edgeClients = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients","HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients"
$wv2Found = $false
foreach ($k in $edgeClients) {
  if (Test-PathSafe $k) {
    Get-ChildItem $k -ErrorAction SilentlyContinue | ForEach-Object {
      $name = (Get-ItemProperty $_.PsPath -ErrorAction SilentlyContinue).name
      if ($name -and $name -like "*WebView2*Runtime*") { $wv2Found = $true }
    }
  }
}
if ($wv2Found) { Write-Result "WebView2 Runtime (Evergreen)" "PASS" } else { Write-Result "WebView2 Runtime (Evergreen)" "WARN" "Recommandé pour exécution; pas obligatoire pour compiler" }

# ---------------- NuGet packages Windows App SDK 1.8.* ----------------
$nugetHome = Join-Path $Env:USERPROFILE ".nuget\packages"
$pkgCore = Get-ChildItem (Join-Path $nugetHome "microsoft.windowsappsdk") -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "1.8.*" }
$pkgWinUI = Get-ChildItem (Join-Path $nugetHome "microsoft.windowsappsdk.winui") -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "1.8.*" }

if ($pkgCore) { Write-Result "NuGet Microsoft.WindowsAppSDK 1.8.*" "PASS" (($pkgCore | Select-Object -ExpandProperty Name) -join ", ") } else { Write-Result "NuGet Microsoft.WindowsAppSDK 1.8.*" "WARN" "Sera téléchargé au premier 'dotnet restore'" }
if ($pkgWinUI) { Write-Result "NuGet Microsoft.WindowsAppSDK.WinUI 1.8.*" "PASS" (($pkgWinUI | Select-Object -ExpandProperty Name) -join ", ") } else { Write-Result "NuGet Microsoft.WindowsAppSDK.WinUI 1.8.*" "WARN" "Sera téléchargé au premier 'dotnet restore'" }

# ---------------- (Option) Valider le .csproj ----------------
if ($ProjectCsprojPath) {
  if (Test-PathSafe $ProjectCsprojPath) {
    $xml = [xml](Get-Content -LiteralPath $ProjectCsprojPath -Raw)
    $tfm = ($xml.Project.PropertyGroup.TargetFramework | Select-Object -First 1)
    $useWinUI = ($xml.Project.PropertyGroup.UseWinUI | Select-Object -First 1)
    $okTfm = ($tfm -match "^net(8|9)\.0\-windows10\.0\.19041\.0$")
    if ($tfm) {
      if ($okTfm) { Write-Result "TargetFramework" "PASS" $tfm }
      else { Write-Result "TargetFramework" "WARN" "$tfm (recommandé: net9.0-windows10.0.19041.0 ou net8.0-windows10.0.19041.0)" }
    } else {
      Write-Result "TargetFramework" "FAIL" "Non défini"
    }
    if ($useWinUI -and $useWinUI -eq "true") { Write-Result "UseWinUI" "PASS" }
    else { Write-Result "UseWinUI" "FAIL" "Ajoute <UseWinUI>true</UseWinUI> dans <PropertyGroup>" }

    # Vérifie la présence des PackageReference 1.8.*
    $pkgRefs = $xml.Project.ItemGroup.PackageReference
    $refCore = $pkgRefs | Where-Object { $_.Include -eq "Microsoft.WindowsAppSDK" }
    $refWinUI = $pkgRefs | Where-Object { $_.Include -eq "Microsoft.WindowsAppSDK.WinUI" }
    if ($refCore) {
      if ($refCore.Version -match "^1\.8\.") { Write-Result "PackageReference Microsoft.WindowsAppSDK" "PASS" $refCore.Version }
      else { Write-Result "PackageReference Microsoft.WindowsAppSDK" "WARN" ("Version: " + $refCore.Version + " (recommandé: 1.8.*)") }
    } else { Write-Result "PackageReference Microsoft.WindowsAppSDK" "FAIL" "Non trouvé" }

    if ($refWinUI) {
      if ($refWinUI.Version -match "^1\.8\.") { Write-Result "PackageReference Microsoft.WindowsAppSDK.WinUI" "PASS" $refWinUI.Version }
      else { Write-Result "PackageReference Microsoft.WindowsAppSDK.WinUI" "WARN" ("Version: " + $refWinUI.Version + " (recommandé: 1.8.*)") }
    } else { Write-Result "PackageReference Microsoft.WindowsAppSDK.WinUI" "FAIL" "Non trouvé" }

  } else {
    Write-Result "Chemin .csproj" "FAIL" "Fichier introuvable: $ProjectCsprojPath"
  }
} else {
  Write-Result "Validation .csproj" "INFO" "Passe un chemin via -ProjectCsprojPath pour valider le projet"
}

# ---------------- Résumé ----------------
if ($global:FAIL -gt 0) {
  Write-Host ""
  Write-Host "=== Résumé : $global:FAIL échec(s). Voir les éléments [FAIL] ci-dessus. ==="
  Write-Host "Correctifs rapides suggérés :"
  Write-Host " - Installer/mettre à jour Windows SDK (via Visual Studio Installer) si absent."
  Write-Host " - Installer .NET SDK 9.x : https://dotnet.microsoft.com/download/dotnet/9.0"
  Write-Host " - Installer Visual Studio 2022 (ou msbuild) si besoin."
  Write-Host " - Installer WebView2 Runtime Evergreen si nécessaire : https://developer.microsoft.com/microsoft-edge/webview2/"
  Write-Host " - Ajuster ton .csproj : TargetFramework net9.0-windows10.0.19041.0, <UseWinUI>true</UseWinUI>, packages 1.8.*"
  exit 1
} else {
  Write-Host ""
  Write-Host "=== Tout est OK ou acceptable pour WinUI 3 + Windows App SDK. ==="
  exit 0
}
