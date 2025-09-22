# PowerShell Fileserver Setup Script

## Übersicht

Dieses Repository enthält ein PowerShell-Skript (`ImportCSV.ps1`) für die automatisierte Einrichtung einer kompletten Fileserver-Infrastruktur mit Active Directory-Integration. Das Skript folgt strikt dem **AGDLP-Prinzip** (Accounts, Global Groups, Domain Local Groups, Permissions) für optimale Sicherheit und Verwaltbarkeit.

## Features

- ✅ **AGDLP-konforme Gruppenstruktur**
- 🏢 **Abteilungsbasierte Benutzer- und Gruppenorganisation**
- 📁 **Automatische Ordnerstruktur-Erstellung**
- 🔐 **NTFS- und SMB-Berechtigungen**
- 🏠 **Home-Verzeichnisse pro Benutzer**
- 👤 **Roaming Profiles-Unterstützung**
- 📊 **CSV-basierter Benutzerimport**

## Dateien im Repository

| Datei | Beschreibung |
|-------|-------------|
| `ImportCSV.ps1` | Haupt-PowerShell-Skript für Fileserver-Setup |
| `Userlist-EchtHamburg.csv` | Beispiel-CSV mit Benutzerdaten |
| `AGDLP-Analysis.md` | Detaillierte AGDLP-Compliance-Analyse |
| `AGDLP-ASCII-Art.md` | AGDLP-Struktur als ASCII-Art-Diagramm |
| `Script-Documentation.md` | Umfassende Mermaid-Dokumentation |
| `README.md` | Diese Datei |

## Schnellstart

### Voraussetzungen

- Windows Server mit Active Directory Domain Services
- PowerShell 5.1 oder höher
- Active Directory PowerShell-Module
- SmbShare PowerShell-Module
- Domain Administrator-Berechtigung

### Installation und Ausführung

1. **Repository klonen:**
   ```bash
   git clone https://github.com/chris738/Powershell2.git
   cd Powershell2
   ```

2. **CSV-Datei anpassen:**
   ```powershell
   # Bearbeiten Sie Userlist-EchtHamburg.csv mit Ihren Benutzerdaten
   # Format: Vorname;Nachname;Abteilung;E-Mail
   ```

3. **Skript ausführen:**
   ```powershell
   # Vollständiges Setup
   .\ImportCSV.ps1

   # Mit angepasster CSV-Datei
   .\ImportCSV.ps1 -CsvFile "C:\Path\To\Your\Users.csv"

   # Nur bestimmte Komponenten (mit Skip-Parametern)
   .\ImportCSV.ps1 -SkipUsers -SkipHomeFolders
   ```

### Parameter

| Parameter | Beschreibung |
|-----------|-------------|
| `-CsvFile` | Pfad zur CSV-Datei (Standard: Userlist-EchtHamburg.csv) |
| `-SkipUsers` | Überspringt Benutzer-Erstellung |
| `-SkipGroups` | Überspringt Gruppen-Erstellung |
| `-SkipFileserver` | Überspringt Ordnerstruktur und NTFS-Rechte |
| `-SkipHomeFolders` | Überspringt Home-Verzeichnis-Erstellung |
| `-SkipNetworkShares` | Überspringt SMB-Share-Erstellung |
| `-SkipSharePermissions` | Überspringt SMB-Berechtigungs-Setup |

## AGDLP-Struktur

Das Skript implementiert eine strikte AGDLP-Hierarchie:

```
Benutzer (A) → Globale Gruppen (G) → Domain Local Gruppen (DL) → Berechtigungen (P)
```

### Beispiel für Abteilung "Bar":
- **Accounts**: marco.peters, marion.wegener, etc.
- **Global Group**: GG_Bar-MA
- **Domain Local Groups**: DL_Bar-FS_RW, DL_Bar-FS_R
- **Permissions**: NTFS/SMB-Rechte auf Bar-Ordner

## Ordnerstruktur

```
F:\Shares\
├── Home\           # Benutzer-Home-Verzeichnisse
├── Profiles\       # Roaming Profiles
├── Global\         # Globale Freigaben
└── Abteilungen\    # Abteilungsordner
    ├── Vorstand\
    ├── Bar\
    ├── Events\
    ├── Shop\
    ├── Verwaltung\
    ├── IT\
    ├── Facility\
    └── Gast\
```

## Spezielle Berechtigungsregeln

### Vorstand (Executive)
- 📖 **Leserechte** auf alle Abteilungsordner
- 📖 **Leserechte** auf Global-Ordner

### Verwaltung (Administration)
- ✏️ **Schreibrechte** auf Global-Ordner
- ✏️ **Vollzugriff** auf eigenen Abteilungsordner

### Andere Abteilungen
- 📖 **Leserechte** auf Global-Ordner
- ✏️ **Vollzugriff** auf eigenen Abteilungsordner

### Gast-Benutzer (Spezielle Behandlung)
- ❌ **Keine Home-Verzeichnisse**
- ❌ **Keine Roaming Profiles**
- ❌ **Keine Gruppenmitgliedschaften für Verzeichniszugriff**
- ❌ **Keine Berechtigungen für Abteilungsordner oder Global-Ordner**
- ✅ **Nur Basis-AD-Konto wird erstellt**
- 🔧 **Benutzername: gast1 bis gast10 (nicht firstname.lastname Format)**
- 🔐 **Kennwort muss nicht beim ersten Anmelden geändert werden**

## SMB-Shares

| Share | Pfad | Berechtigung |
|-------|------|-------------|
| `Home$` | F:\Shares\Home | Authenticated Users: Change |
| `Profiles$` | F:\Shares\Profiles | Authenticated Users: Change |
| `Global$` | F:\Shares\Global | DL_Global-FS_RW: Full, DL_Global-FS_R: Read |
| `Abteilungen$` | F:\Shares\Abteilungen | DL_Dept-FS_RW: Full, DL_Dept-FS_R: Read |

### Automatische Bereinigung verwaister Freigaben

⚠️ **Neue Funktion**: Vor der Erstellung neuer Netzwerkfreigaben prüft das Skript automatisch auf verwaiste (nicht mehr benötigte) Freigaben und entfernt diese.

- **Erwartete Freigaben**: Nur die vier oben genannten Shares sind zulässig
- **Ausgeschlossen**: Administrative Shares (C$, D$, IPC$, ADMIN$, NETLOGON, SYSVOL) werden nicht berührt
- **Automatische Entfernung**: Alle anderen Freigaben werden als verwaist betrachtet und entfernt
- **Protokollierung**: Alle Aktionen werden im Setup-Log dokumentiert

## CSV-Format

Die CSV-Datei muss folgende Spalten enthalten:

```csv
Vorname;Nachname;Abteilung;E-Mail
Jan;Janssen;Vorstand;jan.janssen@company.de
Marco;Peters;Bar;marco.peters@company.de
gast1;Nutzer1;Gast;gast_1@company.de
```

**Besondere Namenskonvention für Gast-Benutzer:**
- Gast-Benutzer verwenden `gast1`, `gast2`, etc. als Vorname
- Dies erzeugt Benutzernamen `gast1`, `gast2`, etc. (nicht `gast1.nutzer1`)

### Unterstützte Abteilungen
- Vorstand
- Bar
- Events
- Shop
- Verwaltung
- IT
- Facility
- Gast

## Dokumentation

Detaillierte Dokumentation finden Sie in:

- 📋 **[AGDLP-Analysis.md](AGDLP-Analysis.md)** - Compliance-Analyse
- 🎨 **[AGDLP-ASCII-Art.md](AGDLP-ASCII-Art.md)** - AGDLP-Struktur als ASCII-Art-Diagramm
- 📊 **[Script-Documentation.md](Script-Documentation.md)** - Mermaid-Diagramme und Ablaufpläne

## Sicherheitshinweise

⚠️ **Wichtige Sicherheitsaspekte:**

1. **Domain Administrator erforderlich** für Ausführung
2. **Produktionsumgebung**: Testen Sie das Skript zuerst in einer Testumgebung
3. **Backup**: Erstellen Sie ein AD-Backup vor der Ausführung
4. **Passwort**: Standard-Passwort "Start123!" wird gesetzt (Benutzer müssen es beim ersten Login ändern)

## Troubleshooting

### Häufige Probleme

**Problem**: "CSV nicht gefunden"
```powershell
# Lösung: Vollständigen Pfad angeben
.\ImportCSV.ps1 -CsvFile "C:\Full\Path\To\Users.csv"
```

**Problem**: "Module können nicht geladen werden"
```powershell
# Lösung: AD-Module installieren
Install-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDirectory
```

**Problem**: "Berechtigung verweigert"
```powershell
# Lösung: Als Domain Administrator ausführen
# PowerShell als Administrator starten
```

## Lizenz

Dieses Projekt steht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE) für Details.

## Beitrag

Beiträge sind willkommen! Bitte erstellen Sie einen Pull Request oder öffnen Sie ein Issue.

## Support

Bei Fragen oder Problemen erstellen Sie bitte ein GitHub Issue.