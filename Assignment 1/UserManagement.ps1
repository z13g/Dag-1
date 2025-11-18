Write-Output "=== UserManagement script loaded ==="

# Global liste over brugere
$Global:Users = @()
Write-Output "[INIT] Global user list created."

# Add-User - Tilføj ny bruger til listen
function Add-User {
    param(
        [string]$Name,
        [int]$Age
    )

    Write-Output "[Add-User] Forsøger at tilføje bruger: $Name, Alder: $Age"

    $Global:Users += [PSCustomObject]@{
        Name = $Name
        Age  = $Age
    }

    Write-Output "[Add-User] Bruger '$Name' tilføjet!"
}

# Get-Users - Hent en bruger
function Get-Users {
    param(
        [string]$Name
    )

    Write-Output "[Get-Users] Søger efter bruger: $Name"

    $user = $Users | Where-Object { $_.Name -eq $Name }

    if ($null -eq $user) {
        Write-Output "[Get-Users] Bruger '$Name' IKKE fundet."
    } else {
        Write-Output "[Get-Users] Bruger fundet: $($user | ConvertTo-Json -Compress)"
    }

    return $user
}

# Update-Users – Opdater alder
function Update-Users {
    param(
        [string]$Name,
        [int]$Age
    )

    Write-Output "[Update-Users] Forsøger at opdatere '$Name' til alder $Age"

    $user = $Users | Where-Object { $_.Name -eq $Name }

    if ($null -eq $user) {
        Write-Output "[Update-Users] Bruger '$Name' blev ikke fundet!"
        return
    }

    $oldAge = $user.Age
    $user.Age = $Age

    Write-Output "[Update-Users] '$Name' opdateret fra $oldAge år til $Age år."
}

# Remove-User – Fjern bruger
function Remove-User {
    param(
        [string]$Name
    )

    Write-Output "[Remove-User] Forsøger at fjerne bruger: $Name"

    $before = $Users.Count
    $Global:Users = $Users | Where-Object { $_.Name -ne $Name }
    $after = $Users.Count

    if ($before -eq $after) {
        Write-Output "[Remove-User] Bruger '$Name' blev ikke fundet."
    } else {
        Write-Output "[Remove-User] Bruger '$Name' fjernet."
    }
}

Write-Output "=== UserManagement script ready ==="

# Dette er en test ændring for at tjekke git integration.