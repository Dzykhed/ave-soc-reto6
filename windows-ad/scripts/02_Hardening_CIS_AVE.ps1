# 02_Hardening_CIS_AVE.ps1 - Endurecimiento CIS reproducible para WIN-SRV22 (ave.local)
# Reto 6: Alcaldía de Valle Escondido
Set-ADDefaultDomainPasswordPolicy -Identity "ave.local" `
    -MinPasswordLength 14 -PasswordHistoryCount 24 -ComplexityEnabled $true `
    -MaxPasswordAge (New-TimeSpan -Days 90) -MinPasswordAge (New-TimeSpan -Days 1) `
    -LockoutThreshold 5 -LockoutDuration (New-TimeSpan -Minutes 30) -LockoutObservationWindow (New-TimeSpan -Minutes 30)

Set-SmbServerConfiguration -RequireSecuritySignature $true -EnableSMB1Protocol $false -Force
Set-SmbClientConfiguration -RequireSecuritySignature $true -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -Value 5
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymous" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymousSAM" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1
Disable-ADAccount -Identity "Guest" -ErrorAction SilentlyContinue
Write-Host "Hardening CIS aplicado correctamente en ave.local." -ForegroundColor Green
