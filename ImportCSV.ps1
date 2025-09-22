<#
.SYNOPSIS
  Komplettes Fileserver-Setup (Gruppen, Benutzer, Ordner, NTFS, Shares, Home & Profile).
  Profile-Ordner werden NICHT pro User angelegt; Windows erstellt sie automatisch.

.SONDERRECHTE / BERECHTIGUNGEN
  - Global:
      DL_Global-FS_RW : Vollzugriff (SMB + NTFS) auf Global
      DL_Global-FS_R  : Leserechte  (SMB + NTFS) auf Global
      GG_Verwaltung-MA → zusätzlich in DL_Global-FS_RW (RW)
      Alle anderen GG_<dep>-MA → zusätzlich in DL_Global-FS_R (R)
  - Abteilungen:
      DL_<Abteilung>-FS_RW : RW auf Abteilungsordner/Shares
      DL_<Abteilung>-FS_R  : R  auf Abteilungsordner/Shares
      GG_Vorstand-MA → immer zusätzlich in alle DL_<Abteilung>-FS_R (Vorstand Leserechte)
  - Home:
      Root: nur Domain Admins (FullControl)
      Benutzer: Modify auf eigenes Home
      Authenticated Users: Change auf SMB-Share Home$
  - Profiles (Root-Stammordner!):
      SYSTEM: Vollzugriff (Ordner/Unterordner/Dateien)
      Administrators: Vollzugriff (nur dieser Ordner)
      Creator Owner: Vollzugriff (nur Unterordner/Dateien)
      GG_RoamingProfileUsers: List/Read + CreateFolder/Append (nur dieser Ordner)
      Share "Profiles$": Authenticated Users → Change
      AD-ProfilePath: \\$server\Profiles$\%username%   (Suffix .V6 setzt OS selbst)
#>

param(
    [string]$CsvFile,
    [switch]$SkipUsers,
    [switch]$SkipGroups,
    [switch]$SkipFileserver,
    [switch]$SkipHomeFolders,
    [switch]$SkipNetworkShares,
    [switch]$SkipSharePermissions
)

# =========================
# MODULES
# =========================
Import-Module ActiveDirectory -ErrorAction Stop
Import-Module SmbShare      -ErrorAction Stop

# =========================
# HELFERFUNKTIONEN (inline)
# =========================

function Get-DefaultCsvPath {
    if ($PSScriptRoot) { return (Join-Path $PSScriptRoot 'Userlist-EchtHamburg.csv') }
    else { return (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Userlist-EchtHamburg.csv') }
}

function Test-CsvFile {
    param([Parameter(Mandatory=$true)][string]$CsvPath)
    if (-not (Test-Path $CsvPath)) { Write-Error "CSV nicht gefunden: $CsvPath"; return $false }
    try {
        $sample = Import-Csv -Path $CsvPath -Delimiter ';' | Select-Object -First 1
        foreach ($col in @('Vorname','Nachname','Abteilung','E-Mail')) {
            if (-not $sample.PSObject.Properties.Name.Contains($col)) {
                Write-Error "Erforderliche Spalte fehlt: $col"; return $false
            }
        }
        return $true
    } catch { Write-Error "CSV-Validierung fehlgeschlagen: $_"; return $false }
}

function Get-DepartmentsFromCSV {
    param([Parameter(Mandatory=$true)][string]$CsvPath)
    try {
        (Import-Csv -Path $CsvPath -Delimiter ';' | Where-Object { $_.Abteilung } | Select-Object -Expand Abteilung -Unique)
    } catch { @() }
}

function Get-SamAccountName {
    param([Parameter(Mandatory=$true)][string]$Vorname,
          [Parameter(Mandatory=$true)][string]$Nachname)
    $v = ($Vorname -replace '\s+','').Trim()
    $n = ($Nachname -replace '\s+','').Trim()
    if (-not $v -or -not $n) { throw "Vorname/Nachname leer" }
    return "$v.$n".ToLower()
}

function Write-ErrorMessage {
    param([string]$Message,[ValidateSet('NotFound','AlreadyExists','Error')][string]$Type='Error',[string]$AdditionalInfo)
    $color = if ($Type -eq 'AlreadyExists') {'Yellow'} else {'Red'}
    Write-Host $Message -ForegroundColor $color
    if ($AdditionalInfo) { Write-Host $AdditionalInfo -ForegroundColor $color }
}

function Get-SafeDomainAdminsIdentity {
    try {
        $ga = Get-ADGroup -Identity 'Domänen-Admins' -ErrorAction SilentlyContinue
        if ($ga) { return New-Object System.Security.Principal.SecurityIdentifier $ga.SID }
        $ga = Get-ADGroup -Identity 'Domain Admins' -ErrorAction SilentlyContinue
        if ($ga) { return New-Object System.Security.Principal.SecurityIdentifier $ga.SID }
        $dom = Get-ADDomain
        $sid = "$($dom.DomainSID)-512"
        return New-Object System.Security.Principal.SecurityIdentifier $sid
    } catch { throw "Domain Admins SID konnte nicht ermittelt werden: $_" }
}

function Get-LocalizedAccountName {
    param([Parameter(Mandatory=$true)][string]$WellKnownAccount)
    $map = @{
        "Everyone"             = @("Jeder","Everyone","S-1-1-0")
        "Authenticated Users"  = @("Authentifizierte Benutzer","Authenticated Users","S-1-5-11")
        "Users"                = @("Benutzer","Users","S-1-5-32-545")
        "Administrators"       = @("Administratoren","Administrators","S-1-5-32-544")
    }
    if (-not $map.ContainsKey($WellKnownAccount)) { return $WellKnownAccount }
    foreach ($name in $map[$WellKnownAccount]) {
        try {
            if ($name -like 'S-*') {
                $sid = New-Object System.Security.Principal.SecurityIdentifier $name
                $acc = $sid.Translate([System.Security.Principal.NTAccount])
                return $acc.Value
            } else {
                $nt  = New-Object System.Security.Principal.NTAccount $name
                [void]$nt.Translate([System.Security.Principal.SecurityIdentifier])
                return $name
            }
        } catch { continue }
    }
    return $WellKnownAccount
}

# =========================
# INITIALISIERUNG
# =========================
if (-not $CsvFile) { $CsvFile = Get-DefaultCsvPath }
if (-not (Test-CsvFile -CsvPath $CsvFile)) { exit 1 }

$departments = Get-DepartmentsFromCSV -CsvPath $CsvFile
if (-not $departments -or $departments.Count -eq 0) { Write-Error "Keine Abteilungen in CSV."; exit 1 }

$domain   = Get-ADDomain
$dcPath   = "DC=$($domain.DNSRoot.Replace('.',',DC='))"
$server   = (Get-ADDomainController -Discover -Service "PrimaryDC").HostName[0]
$basePath = "F:\Shares"
$adminSid = Get-SafeDomainAdminsIdentity

# =========================
# FUNKTIONEN (KERN)
# =========================

function Setup-Groups {
    Write-Host "== Gruppen anlegen ==" -ForegroundColor Cyan

    # Globale DL-Gruppen
    foreach ($grp in 'DL_Global-FS_RW','DL_Global-FS_R') {
        if (-not (Get-ADGroup -Filter "Name -eq '$grp'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $grp -GroupScope DomainLocal -GroupCategory Security -Path $dcPath -Description 'DL Global FS'
            Write-Host "Gruppe erstellt: $grp" -ForegroundColor Green
        } else {
            Write-Host "Gruppe vorhanden: $grp" -ForegroundColor Yellow
        }
    }

    # Abteilungsgruppen
    foreach ($dep in $departments) {
        $ouPath = "OU=$dep,$dcPath"
        $gg   = "GG_${dep}-MA"
        $dlRW = "DL_${dep}-FS_RW"
        $dlR  = "DL_${dep}-FS_R"

        if (-not (Get-ADGroup -Filter "Name -eq '$gg'" -SearchBase $ouPath -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $gg -GroupScope Global -GroupCategory Security -Path $ouPath -Description "GG Mitarbeiter $dep"
            Write-Host "Gruppe erstellt: $gg" -ForegroundColor Green
        } else {
            Write-Host "Gruppe vorhanden: $gg" -ForegroundColor Yellow
        }

        foreach ($dl in @($dlRW,$dlR)) {
            if (-not (Get-ADGroup -Filter "Name -eq '$dl'" -SearchBase $ouPath -ErrorAction SilentlyContinue)) {
                New-ADGroup -Name $dl -GroupScope DomainLocal -GroupCategory Security -Path $ouPath -Description "DL FS $dep"
                Write-Host "Gruppe erstellt: $dl" -ForegroundColor Green
            } else {
                Write-Host "Gruppe vorhanden: $dl" -ForegroundColor Yellow
            }
        }

        Add-ADGroupMember -Identity $dlRW -Members $gg -ErrorAction SilentlyContinue
        Add-ADGroupMember -Identity $dlR  -Members $gg -ErrorAction SilentlyContinue
    }

    # Roaming Profile Gruppe (als DL!)
    $rpGroup = "DL_RoamingProfileUsers"
    if (-not (Get-ADGroup -Filter "Name -eq '$rpGroup'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $rpGroup -GroupScope DomainLocal -GroupCategory Security -Path "CN=Users,$dcPath" -Description "Roaming Profile Stammordnerberechtigung"
        Write-Host "Gruppe erstellt: $rpGroup" -ForegroundColor Green
    } else {
        Write-Host "Gruppe vorhanden: $rpGroup" -ForegroundColor Yellow
    }
}

function Create-Users {
    Write-Host "== Benutzer anlegen ==" -ForegroundColor Cyan
    $users = Import-Csv -Path $CsvFile -Delimiter ';'
    foreach ($u in $users) {
        $sam = Get-SamAccountName -Vorname $u.Vorname -Nachname $u.Nachname
        if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) { continue }
        $ouPath = "OU=$($u.Abteilung),$dcPath"
        # ProfilePath OHNE Suffix – OS hängt .Vx selbst an
        $profilePath = "\\$server\Profiles$\$sam"
        try {
            New-ADUser -Name "$($u.Vorname) $($u.Nachname)" `
                       -SamAccountName $sam `
                       -UserPrincipalName "$sam@$($domain.DNSRoot)" `
                       -GivenName $u.Vorname -Surname $u.Nachname -EmailAddress $u.'E-Mail' `
                       -Path $ouPath -ProfilePath $profilePath `
                       -AccountPassword (ConvertTo-SecureString 'Start123!' -AsPlainText -Force) `
                       -ChangePasswordAtLogon $true -Enabled $true
            Write-Host "Benutzer erstellt: $sam"
        } catch {
            if ($_.Exception.Message -match 'already exists|bereits vorhanden') {
                Write-ErrorMessage -Message 'Konto bereits vorhanden.' -Type 'AlreadyExists' -AdditionalInfo $sam
            } else {
                Write-ErrorMessage -Message "Benutzer $sam Fehler: $($_.Exception.Message)" -Type 'Error'
            }
        }
    }
}

function Setup-GG-Membership {
    Write-Host "== Gruppenmitgliedschaften ==" -ForegroundColor Cyan

    $rpGroup = "DL_RoamingProfileUsers"

    foreach ($dep in $departments) {
        $ouPath = "OU=$dep,$dcPath"
        $gg   = "GG_${dep}-MA"
        $dlRW = "DL_${dep}-FS_RW"
        $dlR  = "DL_${dep}-FS_R"

        Write-Host "Abteilung: $dep"
        Write-Host "  Basisgruppe: $gg"
        Write-Host "  DL_RW:       $dlRW"
        Write-Host "  DL_R:        $dlR"

        # Benutzer in ihre GG-Gruppe aufnehmen
        Get-ADUser -SearchBase $ouPath -Filter * -ErrorAction SilentlyContinue | ForEach-Object {
            Add-ADGroupMember -Identity $gg -Members $_ -ErrorAction SilentlyContinue
            Write-Host "    Benutzer $($_.SamAccountName) → $gg"
        }

        # GG in DLs aufnehmen
        Add-ADGroupMember -Identity $dlRW -Members $gg -ErrorAction SilentlyContinue
        Write-Host "    $gg → $dlRW"
        Add-ADGroupMember -Identity $dlR -Members $gg -ErrorAction SilentlyContinue
        Write-Host "    $gg → $dlR"

        # Vorstand bekommt Leserechte
        $vorstand = 'GG_Vorstand-MA'
        if (Get-ADGroup -Filter "Name -eq '$vorstand'" -ErrorAction SilentlyContinue) {
            Add-ADGroupMember -Identity $dlR -Members $vorstand -ErrorAction SilentlyContinue
            Write-Host "    $vorstand → $dlR"
        }

        # jede Abteilungs-GG auch in DL_RoamingProfileUsers aufnehmen
        Add-ADGroupMember -Identity $rpGroup -Members $gg -ErrorAction SilentlyContinue
        Write-Host "    $gg → $rpGroup"
    }

    foreach ($dep in $departments) {
        $gg = "GG_${dep}-MA"
        if ($dep -eq 'Verwaltung') {
            Add-ADGroupMember -Identity 'DL_Global-FS_RW' -Members $gg -ErrorAction SilentlyContinue
            Write-Host "  $gg → DL_Global-FS_RW (Verwaltung RW)"
        } else {
            Add-ADGroupMember -Identity 'DL_Global-FS_R' -Members $gg -ErrorAction SilentlyContinue
            Write-Host "  $gg → DL_Global-FS_R (Abt. Read)"
        }
    }
}

function Setup-Fileserver {
    Write-Host "== Ordnerstruktur ==" -ForegroundColor Cyan
    foreach ($folder in 'Home','Profiles','Global','Abteilungen') {
        $path = Join-Path $basePath $folder
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory | Out-Null
            Write-Host "  Ordner erstellt: $path"
        } else {
            Write-Host "  Ordner vorhanden: $path"
        }
    }
    foreach ($dep in $departments) {
        $path = "$basePath\Abteilungen\$dep"
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory | Out-Null
            Write-Host "  Abteilungsordner erstellt: $path"
        } else {
            Write-Host "  Abteilungsordner vorhanden: $path"
        }
    }
}

function Setup-Fileserver-Rights {
  Write-Host "== NTFS-Rechte ==" -ForegroundColor Cyan

  function SetAcl($path,[string[]]$groupsRW,[string[]]$groupsR) {
    Write-Host "  Bearbeite Ordner: $path"

    $acl = Get-Acl $path
    $acl.SetAccessRuleProtection($true,$false)

    $acl.SetAccessRule((
      New-Object System.Security.AccessControl.FileSystemAccessRule(
        $adminSid,'FullControl','ContainerInherit,ObjectInherit','None','Allow'
      )
    ))
    Write-Host "    Domain Admins → FullControl"

    foreach ($g in $groupsRW) {
      $grp = Get-ADGroup -Identity $g -ErrorAction SilentlyContinue
      if ($grp) {
        $sid = New-Object System.Security.Principal.SecurityIdentifier $grp.SID
        $acl.AddAccessRule((
          New-Object System.Security.AccessControl.FileSystemAccessRule(
            $sid,'Modify','ContainerInherit,ObjectInherit','None','Allow'
          )
        ))
        Write-Host "    $g → Modify"
      } else { Write-Host "    Gruppe nicht gefunden: $g" -ForegroundColor Yellow }
    }

    foreach ($g in $groupsR) {
      $grp = Get-ADGroup -Identity $g -ErrorAction SilentlyContinue
      if ($grp) {
        $sid = New-Object System.Security.Principal.SecurityIdentifier $grp.SID
        $acl.AddAccessRule((
          New-Object System.Security.AccessControl.FileSystemAccessRule(
            $sid,'ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow'
          )
        ))
        Write-Host "    $g → ReadAndExecute"
      } else { Write-Host "    Gruppe nicht gefunden: $g" -ForegroundColor Yellow }
    }

    $builtinAdminSid = New-Object System.Security.Principal.SecurityIdentifier "$($domain.DomainSID)-500"
    $acl.AddAccessRule((
      New-Object System.Security.AccessControl.FileSystemAccessRule(
        $builtinAdminSid,'FullControl','ContainerInherit,ObjectInherit','None','Allow'
      )
    ))
    Write-Host "    Administrator (RID 500) → FullControl"

    Set-Acl -Path $path -AclObject $acl
    Write-Host "    ACL gesetzt für: $path"
  }

  foreach ($dep in $departments) {
    SetAcl "$basePath\Abteilungen\$dep" @("DL_${dep}-FS_RW") @("DL_${dep}-FS_R")
  }
  SetAcl "$basePath\Global"   @('DL_Global-FS_RW') @('DL_Global-FS_R')
  SetAcl "$basePath\Home"     @() @()
  # Profiles-Root NICHT hier anfassen → macht Setup-RoamingProfilesSecurity
}

function Setup-NetworkShares {
    Write-Host "== SMB-Shares ==" -ForegroundColor Cyan
    $everyone = Get-LocalizedAccountName 'Everyone'
    function EnsureShare($name,$path,$desc) {
        if (-not (Get-SmbShare -Name $name -ErrorAction SilentlyContinue)) {
            New-SmbShare -Name $name -Path $path -Description $desc -FullAccess $env:USERNAME | Out-Null
            Revoke-SmbShareAccess -Name $name -AccountName $everyone -Force -ErrorAction SilentlyContinue
        }
    }
    EnsureShare 'Home$'      "$basePath\Home"     'Homeverzeichnisse'
    EnsureShare 'Profiles$'  "$basePath\Profiles" 'Profile'
    EnsureShare 'Global$'    "$basePath\Global"   'Global'
    EnsureShare 'Abteilungen$' "$basePath\Abteilungen" 'Abteilungen'

    $authUsers = Get-LocalizedAccountName 'Authenticated Users'
    Grant-SmbShareAccess -Name 'Home$'     -AccountName $authUsers -AccessRight Change -Force -ErrorAction SilentlyContinue
    Grant-SmbShareAccess -Name 'Profiles$' -AccountName $authUsers -AccessRight Change -Force -ErrorAction SilentlyContinue
    Grant-SmbShareAccess -Name 'Global$'   -AccountName 'DL_Global-FS_RW' -AccessRight Change -Force -ErrorAction SilentlyContinue
    foreach ($dep in $departments) {
        Grant-SmbShareAccess -Name 'Abteilungen$' -AccountName "DL_${dep}-FS_RW" -AccessRight Change -Force -ErrorAction SilentlyContinue
    }
}

function Create-HomeAndProfileFolders {
    Write-Host "== Home pro User (Profile NICHT manuell) ==" -ForegroundColor Cyan
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-18'
    foreach ($dep in $departments) {
        $searchBase = "OU=$dep,$dcPath"
        Get-ADUser -SearchBase $searchBase -Filter * -Properties SamAccountName,SID,Department,Enabled | Where-Object {
            $_.Enabled -and $_.Department -ne 'Gast'
        } | ForEach-Object {
            $sam = $_.SamAccountName

            # --- HOME ---
            $homeFolder = "$basePath\Home\$sam"
            $homeUNC    = "\\$server\Home$\$sam"
            if (-not (Test-Path $homeFolder)) { New-Item -Path $homeFolder -ItemType Directory | Out-Null }

            $hacl = Get-Acl $homeFolder
            $hacl.SetAccessRuleProtection($true,$false)
            foreach ($sid in @($adminSid,$systemSid,$_.SID)) {
                $rights = if ($sid -eq $_.SID) { 'Modify' } else { 'FullControl' }
                $hacl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($sid,$rights,'ContainerInherit,ObjectInherit','None','Allow')))
            }
            Set-Acl -Path $homeFolder -AclObject $hacl

            Set-ADUser $_ -HomeDirectory $homeUNC -HomeDrive 'H:' -ScriptPath $null

            # --- PROFILE ---
            # NICHT erstellen. OS legt \\$server\Profiles$\<sam>.Vx selbst an.
            $profUNC = "\\$server\Profiles$\$sam"
            Set-ADUser $_ -ProfilePath $profUNC
        }
    }
}

function Setup-SharePermissions {
    Write-Host "== SMB-Berechtigungen (Absicherung) ==" -ForegroundColor Cyan
    function EnsurePerm($share,$acc,$right){
        $cur = Get-SmbShareAccess -Name $share -ErrorAction SilentlyContinue | Where-Object { $_.AccountName -eq $acc }
        if (-not $cur) { Grant-SmbShareAccess -Name $share -AccountName $acc -AccessRight $right -Force -ErrorAction SilentlyContinue }
    }
    EnsurePerm 'Global$' 'DL_Global-FS_RW' Full
    EnsurePerm 'Global$' 'DL_Global-FS_R'  Read
    foreach ($dep in $departments) {
        EnsurePerm 'Abteilungen$' "DL_${dep}-FS_RW" Full
        EnsurePerm 'Abteilungen$' "DL_${dep}-FS_R"  Read
    }
    $authUsers = Get-LocalizedAccountName 'Authenticated Users'
    EnsurePerm 'Home$'     $authUsers Change
    EnsurePerm 'Profiles$' $authUsers Change
}

# ========= NEU =========
function Setup-RoamingProfilesSecurity {
    Write-Host "== Roaming Profiles: Gruppe, ACL & Share ==" -ForegroundColor Cyan

    # DL_RoamingProfileUsers wird bereits in Setup-Groups erstellt
    # Alle MA-Gruppen werden bereits in Setup-GG-Membership hinzugefügt
    $dlRoamingGroup = "DL_RoamingProfileUsers"
    
    Write-Host "Verwende bereits existierende Gruppe: $dlRoamingGroup"

    # NTFS am Profiles-ROOT (F:\Shares\Profiles) nach MS-Best Practice
    $profilesRoot = Join-Path $basePath 'Profiles'
    if (-not (Test-Path $profilesRoot)) { New-Item -Path $profilesRoot -ItemType Directory | Out-Null }

    $acl = Get-Acl $profilesRoot
    $acl.SetAccessRuleProtection($true,$false)

    $sidSystem   = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-18'
    $sidAdmins   = $adminSid                    # Domain Admins (DomainSID-512)
    $sidGroup    = (New-Object System.Security.Principal.NTAccount("$($domain.NetBIOSName)\$dlRoamingGroup")).Translate([System.Security.Principal.SecurityIdentifier])

    # Bestehende ACEs entfernen (optional sicherer Reset)
    foreach ($rule in @($acl.Access)) { [void]$acl.RemoveAccessRule($rule) }

    # SYSTEM: Full (OI,CI)
    $acl.AddAccessRule((
        New-Object System.Security.AccessControl.FileSystemAccessRule(
            $sidSystem,'FullControl','ContainerInherit,ObjectInherit','None','Allow'
        )
    ))
    # Administrators: Full (nur dieser Ordner)
    $acl.AddAccessRule((
        New-Object System.Security.AccessControl.FileSystemAccessRule(
            $sidAdmins,'FullControl','None','None','Allow'
        )
    ))
	# Creator Owner: Full (nur Unterordner/Dateien, InheritOnly)
	# CREATOR OWNER als SID definieren
	$creatorOwnerSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-3-0'

	# ACL-Eintrag hinzufügen: FullControl, nur vererbt (OI/CI, InheritOnly)
	$acl.AddAccessRule((
		New-Object System.Security.AccessControl.FileSystemAccessRule(
			$creatorOwnerSid,
			'FullControl',
			'ContainerInherit,ObjectInherit',
			'InheritOnly',
			'Allow'
		)
	))

    # DL_RoamingProfileUsers: List/Read + CreateFolder/Append (nur dieser Ordner)
    $rights = [System.Security.AccessControl.FileSystemRights]::ListDirectory `
            -bor [System.Security.AccessControl.FileSystemRights]::Read `
            -bor [System.Security.AccessControl.FileSystemRights]::CreateDirectories `
            -bor [System.Security.AccessControl.FileSystemRights]::AppendData
    $acl.AddAccessRule((
        New-Object System.Security.AccessControl.FileSystemAccessRule(
            $sidGroup,$rights,'None','None','Allow'
        )
    ))

    Set-Acl -Path $profilesRoot -AclObject $acl
    Write-Host "NTFS am Profiles-ROOT gesetzt: $profilesRoot"

    # Share-Rechte (Profiles$): Authenticated Users → Change
    $authUsers = Get-LocalizedAccountName 'Authenticated Users'
    if (-not (Get-SmbShare -Name 'Profiles$' -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name 'Profiles$' -Path $profilesRoot -Description 'Profile' -FullAccess $env:USERNAME | Out-Null
    }
    Grant-SmbShareAccess -Name 'Profiles$' -AccountName $authUsers -AccessRight Change -Force -ErrorAction SilentlyContinue
    Write-Host "Share-Rechte Profiles$ geprüft/gesetzt (Authenticated Users → Change)."
}

# =========================
# AUSFÜHRUNG
# =========================
if (-not $SkipGroups)            { Setup-Groups }
if (-not $SkipUsers)             { Create-Users }
if (-not $SkipGroups)            { Setup-GG-Membership }
if (-not $SkipFileserver)        { Setup-Fileserver; Setup-Fileserver-Rights }
if (-not $SkipNetworkShares)     { Setup-NetworkShares }

# Profile: keine Ordneranlage pro User – nur Home!
if (-not $SkipHomeFolders)       { Create-HomeAndProfileFolders }

if (-not $SkipSharePermissions)  { Setup-SharePermissions }

# WICHTIG: Roaming-Profile Sicherheit/Gruppe/Share zuletzt setzen
Setup-RoamingProfilesSecurity

Write-Host "Setup abgeschlossen!" -ForegroundColor Green
