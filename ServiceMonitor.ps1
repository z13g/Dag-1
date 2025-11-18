<#
.SYNOPSIS
    Overvåger Windows-tjenester og deres procesforbrug.

.DESCRIPTION
    Scriptet:
    - Henter alle kørende tjenester
    - Finder bagvedliggende processer via WMI (Win32_Service)
    - Indsamler CPU- og RAM-forbrug
    - Sorterer efter mest ressourceforbrug
    - Viser det i en pæn tabel
    - Gemmer resultatet i en logfil med tidsstempel
    - Understøtter -Top parameter
#>

param(
    [int]$Top = 10   # Bonus: Brugeren kan vælge hvor mange der vises
)

Write-Output "=== Henter kørende tjenester og procesdata ==="

# ----------------------------------------------------------
# 1. Hent alle kørende tjenester
# ----------------------------------------------------------
$services = Get-Service | Where-Object { $_.Status -eq "Running" }

# ----------------------------------------------------------
# 2. Hent data via WMI for at få PID (ProcessId)
# ----------------------------------------------------------
$wmiServices = Get-WmiObject Win32_Service | Where-Object { $_.State -eq "Running" }

# Hash table til hurtig lookup
$wmiLookup = @{}
foreach ($s in $wmiServices) {
    $wmiLookup[$s.Name] = $s
}

# ----------------------------------------------------------
# 3. Byg objekt med CPU, RAM, PID osv.
# ----------------------------------------------------------
$results = foreach ($svc in $services) {

    # Find match i WMI (for at få PID)
    $w = $wmiLookup[$svc.Name]
    if ($null -eq $w) { continue }

    $processId = $w.ProcessId

    # Hent procesdata
    $p = Get-Process -Id $processId -ErrorAction SilentlyContinue

    if ($null -eq $p) { continue }

    # CPU = total CPU seconds (Process CPU time)
    # $cpu = $p.CPU
    $cpu = [math]::Round($p.CPU, 2)


    # RAM = WorkingSet i bytes → konverter til MB
    $ramMB = [math]::Round($p.WorkingSet64 / 1MB, 2)

    # Returner PowerShell-objekt
    [PSCustomObject]@{
        ServiceName = $svc.Name
        PID         = $processId
        CPU         = $cpu
        MemoryMB    = $ramMB
    }
}

# ----------------------------------------------------------
# 4. Sorter efter mest ressourceforbrug
#    (først RAM, derefter CPU)
# ----------------------------------------------------------
$sorted = $results |
    Sort-Object -Property @{Expression="MemoryMB";Descending=$true}, @{Expression="CPU";Descending=$true} |
    Select-Object -First $Top

# ----------------------------------------------------------
# 5. Gem resultat i en tidsstemplet logfil
# ----------------------------------------------------------
$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$logFile = ".\ServiceLog_$timestamp.txt"

$sorted | Out-File -FilePath $logFile -Encoding UTF8

Write-Output "Log gemt som: $logFile"

# ----------------------------------------------------------
# 6. Vis en pæn tabel i konsollen
# ----------------------------------------------------------
Write-Output ""
Write-Output "=== Top $Top mest ressourcekrævende tjenester ==="
$sorted | Format-Table -AutoSize
