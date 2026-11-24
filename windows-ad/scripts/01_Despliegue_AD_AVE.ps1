# 01_Despliegue_AD_AVE.ps1 - Creación reproducible de OUs, Grupos, Usuarios y Honeytoken (ave.local)
Import-Module ActiveDirectory

$baseDN = "OU=Alcaldia_Valle_Escondido,DC=ave,DC=local"
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Alcaldia_Valle_Escondido'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Alcaldia_Valle_Escondido" -Path "DC=ave,DC=local"
}

$ous = @("Tecnologia_TI","Despacho_Alcalde","Finanzas_y_Planilla","Recursos_Humanos","Atencion_Contribuyente","Grupos_Municipales")
foreach ($ou in $ous) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -SearchBase $baseDN -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ou -Path $baseDN
    }
}

$grpPath = "OU=Grupos_Municipales,$baseDN"
foreach ($g in @("GRP_TI_Soporte","GRP_Alcaldia_Empleados","GRP_Acceso_RDP","GRP_RRHH_Planilla")) {
    if (-not (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path $grpPath
    }
}

$pass = ConvertTo-SecureString "AlcaldiaAVE2026!#" -AsPlainText -Force
$usuarios = @(
    @{Sam="g.wright"; Name="Gilberto Wright"; OU="Tecnologia_TI"; Dept="Tecnologia TI"},
    @{Sam="d.vallarino"; Name="Diego Vallarino"; OU="Tecnologia_TI"; Dept="Tecnologia TI"},
    @{Sam="svc.respaldo_ad"; Name="Cuenta Senuelo Respaldo AD"; OU="Tecnologia_TI"; Dept="Honeytoken SOC"},
    @{Sam="j.ballesteros"; Name="Jeremy Ballesteros"; OU="Despacho_Alcalde"; Dept="Despacho Alcalde"},
    @{Sam="a.caballero"; Name="Ana Caballero"; OU="Despacho_Alcalde"; Dept="Despacho Alcalde"},
    @{Sam="m.solis"; Name="Mery Solis"; OU="Finanzas_y_Planilla"; Dept="Finanzas y Planilla"},
    @{Sam="g.frias"; Name="Gabriela Frias"; OU="Recursos_Humanos"; Dept="Recursos Humanos"},
    @{Sam="n.perea"; Name="Nicolas Perea"; OU="Atencion_Contribuyente"; Dept="Atencion Contribuyente"},
    @{Sam="j.leon"; Name="Jorge Leon"; OU="Atencion_Contribuyente"; Dept="Atencion Contribuyente"}
)

foreach ($u in $usuarios) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.Sam)'" -ErrorAction SilentlyContinue)) {
        New-ADUser -Name $u.Name -SamAccountName $u.Sam -UserPrincipalName "$($u.Sam)@ave.local" `
            -Path "OU=$($u.OU),$baseDN" -Department $u.Dept -AccountPassword $pass -Enabled $true
    }
    Add-ADGroupMember -Identity "GRP_Alcaldia_Empleados" -Members $u.Sam -ErrorAction SilentlyContinue
}
Add-ADGroupMember -Identity "GRP_TI_Soporte" -Members "g.wright","d.vallarino" -ErrorAction SilentlyContinue
Add-ADGroupMember -Identity "GRP_Acceso_RDP" -Members "m.solis" -ErrorAction SilentlyContinue
Add-ADGroupMember -Identity "GRP_RRHH_Planilla" -Members "g.frias" -ErrorAction SilentlyContinue
Add-ADGroupMember -Identity "Remote Desktop Users" -Members "GRP_Acceso_RDP" -ErrorAction SilentlyContinue
Write-Host "Estructura AD ave.local desplegada correctamente." -ForegroundColor Green
