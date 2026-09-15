# Firewall Lockdown Toggle Script
# Usage: .\firewall-lockdown.ps1 on|off|status
param([string]$Action = "status")

# LEAVE BLANK OR $null IF YOU DON'T HAVE A VPS
$VPS_IP = $null 
$ANTHROPIC_IPS = @("160.79.104.10", "34.149.66.165", "2607:6bc0::10")
$ROUTER_IP = "192.168.1.1"

function Enable-Lockdown {
    Write-Host "Enabling lockdown..." -ForegroundColor Yellow

    # Set default outbound to block
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block

    # Create base allow rules
    $rules = @(
        @{Name='Lockdown-Anthropic'; Dir='Outbound'; Addr=$ANTHROPIC_IPS; Proto='TCP'; Port=443},
        @{Name='Lockdown-DNS-UDP'; Dir='Outbound'; Proto='UDP'; Port=53},
        @{Name='Lockdown-DNS-TCP'; Dir='Outbound'; Proto='TCP'; Port=53},
        @{Name='Lockdown-Router'; Dir='Outbound'; Addr=$ROUTER_IP}
    )

    # Only inject VPS rules if $VPS_IP actually has a value
    if ($VPS_IP) {
        $rules += @{Name='Lockdown-VPS'; Dir='Outbound'; Addr=$VPS_IP}
        $rules += @{Name='Lockdown-VPS-In'; Dir='Inbound'; Addr=$VPS_IP}
    }

    foreach ($r in $rules) {
        Remove-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue
        
        $params = @{
            DisplayName = $r.Name
            Direction = $r.Dir
            Action = 'Allow'
        }
        
        if ($r.Addr) { $params.RemoteAddress = $r.Addr }
        if ($r.Proto) { $params.Protocol = $r.Proto }
        if ($r.Port) { $params.RemotePort = $r.Port }

        New-NetFirewallRule @params | Out-Null
    }

    # App-specific rules for Claude CLI
    $claudePath = "$env:USERPROFILE\.local\bin\claude.exe"
    if (Test-Path $claudePath) {
        Remove-NetFirewallRule -DisplayName Lockdown-Claude -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName Lockdown-Claude -Direction Outbound -Program $claudePath -Action Allow | Out-Null
    }

    Write-Host "LOCKDOWN ENABLED" -ForegroundColor Green
    if ($VPS_IP) {
        Write-Host "Allowed: VPS ($VPS_IP), Anthropic, DNS only"
    } else {
        Write-Host "Allowed: Anthropic, DNS only (VPS bypassed)"
    }
}

function Disable-Lockdown {
    Write-Host "Disabling lockdown..." -ForegroundColor Yellow

    # Remove lockdown rules using a wildcard match
    Get-NetFirewallRule -DisplayName "Lockdown-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

    # Set default outbound back to allow
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow

    Write-Host "LOCKDOWN DISABLED" -ForegroundColor Green
    Write-Host "Normal internet access restored"
}

function Get-LockdownStatus {
    $profile = Get-NetFirewallProfile -Name Private
    $lockdownRules = Get-NetFirewallRule -DisplayName "Lockdown-*" -ErrorAction SilentlyContinue

    if ($profile.DefaultOutboundAction -eq 'Block' -and $lockdownRules) {
        Write-Host "Status: LOCKED DOWN" -ForegroundColor Red
        Write-Host "`nActive rules:"
        $lockdownRules | Select-Object DisplayName, Enabled | Format-Table
    } else {
        Write-Host "Status: NORMAL (not locked down)" -ForegroundColor Green
    }
}

switch ($Action.ToLower()) {
    "on"     { Enable-Lockdown }
    "off"    { Disable-Lockdown }
    "status" { Get-LockdownStatus }
    default  { Write-Host "Usage: .\firewall-lockdown.ps1 on|off|status" }
}
