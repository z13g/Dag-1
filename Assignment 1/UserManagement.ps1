Write-Output "=== Advanced UserManagement Loaded ==="

# Global liste til brugere
$Global:Users = @()

# ---------------------------------------------------
# New-User (Add-User)
# ---------------------------------------------------
function New-User {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateRange(1,120)]
        [int]$Age
    )

    if ($Users.Name -contains $Name) {
        Write-Error "Brugeren '$Name' findes allerede!"
        return
    }

    $userObj = [PSCustomObject]@{
        Name = $Name
        Age  = $Age
    }

    $Global:Users += $userObj
    Write-Output $userObj
}

# ---------------------------------------------------
# Get-User
# ---------------------------------------------------
function Get-User {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    process {
        foreach ($n in $Name) {
            $matches = $Users | Where-Object { $_.Name -like $n }
            if ($matches) {
                $matches | Write-Output
            }
        }
    }
}

# ---------------------------------------------------
# Get-All-Users
# ---------------------------------------------------
function Get-All-Users {
    [CmdletBinding()]
    param()

    return $Users
}

# ---------------------------------------------------
# Set-User (Update-User)
# ---------------------------------------------------
function Set-User {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateRange(1,120)]
        [int]$Age
    )

    process {
        $u = $Users | Where-Object { $_.Name -eq $Name }

        if ($null -eq $u) {
            Write-Error "User '$Name' not found."
            return
        }

        $u.Age = $Age
        Write-Output $u
    }
}

# ---------------------------------------------------
# Remove-User
# ---------------------------------------------------
function Remove-User {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )

    process {
        foreach ($n in $Name) {
            if ($PSCmdlet.ShouldProcess($n, "Delete user")) {
                $Global:Users = $Users | Where-Object { $_.Name -ne $n }
                Write-Output "Deleted user: $n"
            }
        }
    }
}

# ---------------------------------------------------
# Export-Users (JSON)
# ---------------------------------------------------
function Export-Users {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Users | ConvertTo-Json | Set-Content -Path $Path -Encoding UTF8
    Write-Output "Users exported to $Path"
}

# ---------------------------------------------------
# Import-Users (JSON)
# ---------------------------------------------------
function Import-Users {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (!(Test-Path $Path)) {
        Write-Error "File '$Path' not found"
        return
    }

    $jsonData = Get-Content -Raw -Path $Path | ConvertFrom-Json

    # Sikrer at det ALTID er en liste
    if ($jsonData -isnot [System.Collections.IEnumerable]) {
        $jsonData = @($jsonData)
    }

    foreach ($u in $jsonData) {
        if ($Users.Name -contains $u.Name) {
            Write-Verbose "Skipping existing user $($u.Name)"
        }
        else {
            $Global:Users += ,$u
        }
    }

    Write-Output "Import complete"
}


Write-Output "=== READY ==="
