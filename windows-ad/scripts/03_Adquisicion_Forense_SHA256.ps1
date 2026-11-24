# 03_Adquisicion_Forense_SHA256.ps1 - Exportación de registros y sellado SHA-256
$evDir = "C:\Herramientas_AVE\Evidencia_Forense"
New-Item -Path $evDir -ItemType Directory -Force | Out-Null
wevtutil epl Security "$evDir\Security_WIN-SRV22-EN.evtx" /ow:true
wevtutil epl "Microsoft-Windows-Sysmon/Operational" "$evDir\Sysmon_WIN-SRV22-EN.evtx" /ow:true
Get-ADGroupMember "Domain Admins" | Select-Object Name, SamAccountName, ObjectClass | Export-Csv "$evDir\Domain_Admins_Snapshot.csv" -NoTypeInformation -Encoding UTF8
Get-GPO -All | Select-Object DisplayName, GpoStatus, ModificationTime | Export-Csv "$evDir\GPOs_Snapshot.csv" -NoTypeInformation -Encoding UTF8
Get-ChildItem -Path $evDir -File | ForEach-Object {
    $h = Get-FileHash -Path $_.FullName -Algorithm SHA256
    [PSCustomObject]@{ Archivo=$_.Name; Tamano_MB=[math]::Round($_.Length/1MB,2); SHA256=$h.Hash; Fecha_UTC5=(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz") }
} | Export-Csv "$evDir\Cadena_Custodia_SHA256.csv" -NoTypeInformation -Encoding UTF8
