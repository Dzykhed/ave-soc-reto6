# Documentación Perimetral: FortiGate-VM64 (Homelab Istmo SOC — Reto 6)

**Organización:** Alcaldía de Valle Escondido (`ave.local`)  
**Responsable de Infraestructura:** Gilberto Wright  
**Restricciones de Licencia (Evaluación Permanente):** 1 vCPU, 2 GB RAM, máximo **3 interfaces**, **3 políticas de firewall** y **3 rutas estáticas**. Por diseño oficial, la inspección IDS/IPS se delega a Suricata en `UBU-SOC` y las VIPs se consolidan para respetar estrictamente el tope de 3 políticas.

---

## 1. Interfaces y Enrutamiento

| Interfaz | Zona / Red VMware | IP / Máscara | Acceso Administrativo | Rol en la Topología |
| :--- | :--- | :--- | :--- | :--- |
| **`port1`** | WAN — `VMnet8 (NAT)` | `172.16.116.128/24` (DHCP/Reservada) | HTTPS, SSH, PING | Lado externo (`Kali Linux` durante ventanas de prueba) y publicación de VIPs. |
| **`port2`** | LAN — `VMnet2 (Host-only, sin DHCP)` | `10.10.10.1/24` | HTTPS, SSH, PING | Gateway de la LAN corporativa (`WIN-SRV22` `10.10.10.10` y `UBU-SOC` `10.10.10.20`). |
| **`port3`** | DMZ — `VMnet3` (Reservada) | `172.16.10.0/24` | Reservada | Segmento reservado para servicios desmilitarizados o honeypot separado. |

### Ruta Estática Activa
- **Destino:** `0.0.0.0/0` $\to$ **Gateway:** `172.16.116.2` (Gateway NAT de VMware) por interfaz **`port1`**.

---

## 2. Objetos Virtual IP (VIPs — Port Forwarding)

Todas las VIPs traducen desde la IP WAN del FortiGate (`172.16.116.128` en `port1`) hacia el servidor correspondiente en `VMnet2`:

| Nombre de VIP | Interfaz | IP / Puerto Externo (`port1`) | IP / Puerto Mapeado (`port2`) | Estado Post-Prueba | Propósito |
| :--- | :---: | :--- | :--- | :---: | :--- |
| **`VIP-Wazuh`** | `port1` | `172.16.116.128` (`TCP: 8443`) | `10.10.10.20` (`TCP: 8443`) | Activa | Acceso administrativo al Dashboard de Wazuh SIEM. |
| **`VIP-ModSecurity`** | `port1` | `172.16.116.128` (`TCP: 8080`) | `10.10.10.20` (`TCP: 8080`) | Activa | Acceso externo al proxy inverso WAF (Nginx + ModSecurity OWASP CRS). |
| **`VIP-WAF`** | `port1` | `172.16.116.128` (`TCP: 8000`) | `10.10.10.20` (`TCP: 8000`) | Activa | Servicio web publicado tras el WAF. |
| **`VIP-SMB-AD`** | `port1` | `172.16.116.128` (`TCP: 445`) | `10.10.10.10` (`TCP: 445`) | **Cerrada (política deshabilitada)** | Uso exclusivo en ventana controlada de validación *Password Spraying* desde Kali. |
| **`VIP-RDP-AD`** | `port1` | `172.16.116.128` (`TCP: 3389`) | `10.10.10.10` (`TCP: 3389`) | **Cerrada (política deshabilitada)** | Uso exclusivo en ventana controlada de validación RDP fuera de horario desde Kali. |

---

## 3. Matriz de Políticas de Firewall (Máximo 3 Políticas + Implicit Deny)

| ID | Nombre | Flujo | Origen $\to$ Destino | Servicio | Acción | NAT Origen | Logging | Estado Actual |
| :-: | :--- | :---: | :--- | :--- | :---: | :---: | :---: | :---: |
| **1** | `Permite_LAN_Internet` | `port2` $\to$ `port1` | `all` $\to$ `all` | `ALL` | `ACCEPT` | **Enabled** | **All Sessions** | **Habilitada** |
| **2** | `Entrada_WAF_y_Servicios` | `port1` $\to$ `port2` | `all` $\to$ `VIP-WAF`, `VIP-ModSecurity`, `VIP-Wazuh` | `ALL` | `ACCEPT` | **Disabled** | **All Sessions** | **Habilitada** |
| **3** | `WAN_a_LAN` | `port1` $\to$ `port2` | `all` $\to$ `VIP-SMB-AD`, `VIP-RDP-AD` | `SMB`, `RDP` | `ACCEPT` | **Disabled** | **All Sessions** | **Deshabilitada (Post-Prueba)** |
| — | `Implicit Deny` | Cualquiera | `all` $\to$ `all` | `ALL` | `DENY` | — | Enabled | Activa por defecto |

> **Justificación técnica de `NAT: Disabled` en políticas entrantes (`2` y `3`):** Deshabilitar el NAT de origen en tráfico `port1 -> port2` garantiza que `WIN-SRV22` y `Wazuh SIEM` reciban la dirección IP real del origen externo en `VMnet8` en lugar de enmascararla tras `10.10.10.1`, preservando la trazabilidad forense y las reglas UEBA.

---

## 4. Integración Syslog hacia Wazuh SIEM (`514/UDP`)

El envío de registros se realiza desde el plano local del FortiGate directamente hacia `10.10.10.20` sin consumir ninguna de las 3 políticas de firewall:

```text
config log syslogd setting
    set status enable
    set server "10.10.10.20"
    set mode udp
    set port 514
    set facility local7
end
```

**Validación en Wazuh:** Recepción confirmada de **29 eventos FortiGate** en Threat Hunting (incluyendo reglas `81620` y `81638`).

---

## 5. Procedimiento de Sanitización y Cierre Post-Prueba

1. **Cierre de exposición temporal AD:** En FortiGate GUI $\to$ *Policy & Objects* $\to$ *Firewall Policy* $\to$ clic derecho sobre **`WAN_a_LAN (3)`** $\to$ **Set Status $\to$ Disable**.
2. **Sanitización del respaldo `.conf` antes de subir a GitHub:** Exportar configuración en *admin $\to$ Configuration $\to$ Backup $\to$ Local PC* y reemplazar todas las líneas `set password ENC ...` y claves privadas por `<REDACTED>` antes de guardar como `fortigate/fortigate_ave_sanitized.conf`.