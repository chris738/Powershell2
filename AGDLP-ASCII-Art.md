# AGDLP ASCII Art Diagramm

Dieses Diagramm zeigt die vollständige AGDLP-Implementierung des PowerShell-Skripts in ASCII-Art-Form.

## Vollständige AGDLP-Struktur

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           AGDLP - IMPLEMENTIERUNG                                  │
│                    (Accounts → Global → Domain Local → Permissions)                │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                ACCOUNTS (A)                                        │
├─────────────────┬───────────────┬───────────────┬───────────────┬───────────────────┤
│   VORSTAND      │     BAR       │    EVENTS     │     SHOP      │    VERWALTUNG     │
│                 │               │               │               │                   │
│ jan.janssen     │ marco.peters  │ christine.    │ anna.gebhardt │ julia.schneider   │
│ uta.heinrich    │ marion.wegener│   bauer       │ jutta.        │ anna.winkler      │
│ jesper.haak     │ wiebke.       │ marwin.       │   alstertal   │ esther.hansen     │
│                 │   benndorf    │   schierholz  │ frank.elbufer │                   │
│                 │ christian.doll│ marah.pelzer  │               │                   │
│                 │ heidrun.meyer │               │               │                   │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────────┤
│       IT        │   FACILITY    │     GAST      │               │                   │
│                 │               │               │               │                   │
│ frank.bittner   │ mark.born     │ gast1 - gast10│               │                   │
│ olaf.albers     │ nils.kraft    │ (special      │               │                   │
│                 │               │  handling)    │               │                   │
└─────────────────┴───────────────┴───────────────┴───────────────┴───────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           GLOBAL GROUPS (G)                                        │
├─────────────────┬───────────────┬───────────────┬───────────────┬───────────────────┤
│ GG_Vorstand-MA  │  GG_Bar-MA    │ GG_Events-MA  │  GG_Shop-MA   │GG_Verwaltung-MA   │
│                 │               │               │               │                   │
│ ┌─────────────┐ │ ┌───────────┐ │ ┌───────────┐ │ ┌───────────┐ │ ┌───────────────┐ │
│ │ jan.janssen │ │ │marco.peters│ │ │christine. │ │ │anna.      │ │ │julia.         │ │
│ │ uta.heinrich│ │ │marion.     │ │ │  bauer    │ │ │ gebhardt  │ │ │ schneider     │ │
│ │ jesper.haak │ │ │ wegener   │ │ │marwin.    │ │ │jutta.     │ │ │anna.winkler   │ │
│ └─────────────┘ │ │wiebke.    │ │ │ schierholz│ │ │ alstertal │ │ │esther.hansen  │ │
│                 │ │ benndorf  │ │ │marah.     │ │ │frank.     │ │ └───────────────┘ │
│                 │ │christian. │ │ │ pelzer    │ │ │ elbufer   │ │                   │
│                 │ │ doll      │ │ └───────────┘ │ └───────────┘ │                   │
│                 │ │heidrun.   │ │               │               │                   │
│                 │ │ meyer     │ │               │               │                   │
│                 │ └───────────┘ │               │               │                   │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────────┤
│   GG_IT-MA      │ GG_Facility-MA│  GG_Gast-MA   │               │                   │
│                 │               │               │               │                   │
│ ┌─────────────┐ │ ┌───────────┐ │ ┌───────────┐ │               │                   │
│ │frank.bittner│ │ │mark.born  │ │ │ (empty -  │ │               │                   │
│ │olaf.albers  │ │ │nils.kraft │ │ │ Gäste sind│ │               │                   │
│ └─────────────┘ │ └───────────┘ │ │ nicht in  │ │               │                   │
│                 │               │ │ Gruppen)  │ │               │                   │
│                 │               │ └───────────┘ │               │                   │
└─────────────────┴───────────────┴───────────────┴───────────────┴───────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        DOMAIN LOCAL GROUPS (DL)                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                              ABTEILUNGSGRUPPEN                                     │
├─────────────────┬───────────────┬───────────────┬───────────────┬───────────────────┤
│ DL_Vorstand-FS  │  DL_Bar-FS    │ DL_Events-FS  │  DL_Shop-FS   │DL_Verwaltung-FS   │
│                 │               │               │               │                   │
│ ┌─────────────┐ │ ┌───────────┐ │ ┌───────────┐ │ ┌───────────┐ │ ┌───────────────┐ │
│ │ _RW (Write) │ │ │ _RW       │ │ │ _RW       │ │ │ _RW       │ │ │ _RW           │ │
│ │ _R  (Read)  │ │ │ _R        │ │ │ _R        │ │ │ _R        │ │ │ _R            │ │
│ └─────────────┘ │ └───────────┘ │ └───────────┘ │ └───────────┘ │ └───────────────┘ │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────────┤
│   DL_IT-FS      │ DL_Facility-FS│               │               │                   │
│                 │               │               │               │                   │
│ ┌─────────────┐ │ ┌───────────┐ │               │               │                   │
│ │ _RW         │ │ │ _RW       │ │               │               │                   │
│ │ _R          │ │ │ _R        │ │               │               │                   │
│ └─────────────┘ │ └───────────┘ │               │               │                   │
├─────────────────┴───────────────┴───────────────┴───────────────┴───────────────────┤
│                             GLOBALE GRUPPEN                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ DL_Global-FS_RW  (Schreibzugriff Global)    │ DL_Global-FS_R  (Lesezugriff Global)  │
│ ┌─────────────────────────────────────────┐  │ ┌────────────────────────────────────┐ │
│ │ GG_Verwaltung-MA (spezieller Zugriff)  │  │ │ GG_Vorstand-MA                     │ │
│ └─────────────────────────────────────────┘  │ │ GG_Bar-MA                          │ │
│                                              │ │ GG_Events-MA                       │ │
│                                              │ │ GG_Shop-MA                         │ │
│                                              │ │ GG_IT-MA                           │ │
│                                              │ │ GG_Facility-MA                     │ │
│                                              │ └────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                        ROAMING PROFILE GRUPPE                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ DL_RoamingProfileUsers                                                              │
│ ┌─────────────────────────────────────────────────────────────────────────────────┐ │
│ │ GG_Vorstand-MA → GG_Bar-MA → GG_Events-MA → GG_Shop-MA                         │ │
│ │ GG_Verwaltung-MA → GG_IT-MA → GG_Facility-MA                                   │ │
│ │ (alle Mitarbeiter-Gruppen außer Gast)                                          │ │
│ └─────────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                PERMISSIONS (P)                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                            NTFS-BERECHTIGUNGEN                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ F:\Shares\Abteilungen\                                                              │
│ ├── Vorstand\      [DL_Vorstand-FS_RW: Modify] [DL_Vorstand-FS_R: Read]            │
│ ├── Bar\           [DL_Bar-FS_RW: Modify]     [DL_Bar-FS_R: Read]                  │
│ ├── Events\        [DL_Events-FS_RW: Modify]  [DL_Events-FS_R: Read]               │
│ ├── Shop\          [DL_Shop-FS_RW: Modify]    [DL_Shop-FS_R: Read]                 │
│ ├── Verwaltung\    [DL_Verwaltung-FS_RW: Modify] [DL_Verwaltung-FS_R: Read]        │
│ ├── IT\            [DL_IT-FS_RW: Modify]      [DL_IT-FS_R: Read]                   │
│ ├── Facility\      [DL_Facility-FS_RW: Modify] [DL_Facility-FS_R: Read]            │
│ └── Gast\          [Nur Domain Admins - Keine Benutzerberechtigungen]              │
│                                                                                     │
│ F:\Shares\Global\   [DL_Global-FS_RW: Modify] [DL_Global-FS_R: Read]               │
│ F:\Shares\Home\     [Domain Admins: FullControl] [Users: Modify auf eigenes Home]  │
│ F:\Shares\Profiles\ [SYSTEM/Admins: FullControl] [DL_RoamingProfileUsers: Special] │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                            SMB-BERECHTIGUNGEN                                      │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ \\Server\Home$        [Authenticated Users: Change]                                │
│ \\Server\Profiles$    [Authenticated Users: Change]                                │
│ \\Server\Global$      [DL_Global-FS_RW: Full] [DL_Global-FS_R: Read]               │
│ \\Server\Abteilungen$ [DL_Dept-FS_RW: Full]   [DL_Dept-FS_R: Read]                │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Spezielle Berechtigungsregeln

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        SPEZIELLE ZUGRIFFSRECHTE                                    │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                           VORSTAND (Executive)                                     │
│     ┌─────────────────┐           LESEZUGRIFF AUF ALLE ABTEILUNGEN                 │
│     │ GG_Vorstand-MA  │ ────────┬──→ DL_Bar-FS_R                                   │
│     └─────────────────┘         ├──→ DL_Events-FS_R                                │
│                                 ├──→ DL_Shop-FS_R                                  │
│                                 ├──→ DL_Verwaltung-FS_R                            │
│                                 ├──→ DL_IT-FS_R                                    │
│                                 ├──→ DL_Facility-FS_R                              │
│                                 └──→ DL_Global-FS_R                                │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                         VERWALTUNG (Administration)                                │
│     ┌─────────────────┐          SCHREIBZUGRIFF AUF GLOBAL                        │
│     │GG_Verwaltung-MA │ ────────┬──→ DL_Global-FS_RW (VOLLZUGRIFF)                 │
│     └─────────────────┘         ├──→ DL_Verwaltung-FS_RW                          │
│                                 └──→ DL_Verwaltung-FS_R                           │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                      ANDERE ABTEILUNGEN (Standard)                                 │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│  │ GG_Bar-MA    │   │ GG_Events-MA │   │ GG_Shop-MA   │   │ GG_IT-MA     │        │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘        │
│         │                  │                  │                  │                 │
│         └─────────┬────────┴─────────┬────────┴─────────┬────────┘                 │
│                   │                  │                  │                          │
│                   ▼                  ▼                  ▼                          │
│              DL_Global-FS_R (NUR LESEZUGRIFF AUF GLOBAL)                          │
│                                                                                     │
│  ┌──────────────┐                                                                  │
│  │GG_Facility-MA│                                                                  │
│  └──────┬───────┘                                                                  │
│         │                                                                          │
│         └──────────────────────────────────────────────────────────────────────┐  │
│                                                                                │  │
│                                                                                ▼  │
│                                          DL_Global-FS_R                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                            GAST-BENUTZER (Special)                                 │
│                                                                                     │
│  gast1, gast2, ... gast10: ❌ KEINE GRUPPENMITGLIEDSCHAFTEN                        │
│                            ❌ KEINE HOME-VERZEICHNISSE                             │
│                            ❌ KEINE ROAMING PROFILES                               │
│                            ❌ KEINE DATEISYSTEM-BERECHTIGUNGEN                     │
│                            ✅ NUR BASIS AD-KONTO                                   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## AGDLP-Prinzip Zusammenfassung

```
        A (Accounts)         G (Global Groups)      DL (Domain Local)         P (Permissions)
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │ jan.janssen     │───▶│ GG_Vorstand-MA  │───▶│ DL_Vorstand-FS  │───▶│ NTFS: Vorstand\ │
    │ uta.heinrich    │    │                 │    │ _RW / _R        │    │ SMB: Shares     │
    │ jesper.haak     │    │                 │    │                 │    │                 │
    └─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
            │                        │                        │                        │
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │ marco.peters    │───▶│ GG_Bar-MA       │───▶│ DL_Bar-FS       │───▶│ NTFS: Bar\      │
    │ marion.wegener  │    │                 │    │ _RW / _R        │    │ SMB: Shares     │
    │ ...             │    │                 │    │                 │    │                 │
    └─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
            │                        │                        │                        │
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │ ALL MA GROUPS   │───▶│ ALL GG_*-MA     │───▶│ DL_Roaming      │───▶│ NTFS: Profiles\ │
    │ (except Gast)   │    │ (except Gast)   │    │ ProfileUsers    │    │ Special Perms   │
    └─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘

    ✅ ACCOUNTS werden in GLOBAL GROUPS organisiert
    ✅ GLOBAL GROUPS werden zu DOMAIN LOCAL GROUPS hinzugefügt  
    ✅ PERMISSIONS werden auf DOMAIN LOCAL GROUPS vergeben
    ✅ Saubere Trennung zwischen Benutzerverwaltung und Ressourcenverwaltung
```