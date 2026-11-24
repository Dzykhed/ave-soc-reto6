# Homelab Istmo SOC — Reto 6: «Credenciales en venta» (Alcaldía de Valle Escondido)

Repositorio técnico reproducible del proyecto final de **Técnicas de Seguridad Informática I (EID1067)** — Instituto Técnico Superior Especializado (ITSE), Escuela de Innovación Digital, Grupo **D-CS-4-1** (III Cuatrimestre 2026).

> **Pregunta Esencial (ABR):** *¿Cómo detectar que un atacante usa credenciales legítimas, cuando para el sistema «parece un empleado»?*

---

## Equipo y Roles de Liderazgo

| Integrante | Rol Oficial | Frente Técnico en el Repositorio |
| :--- | :--- | :--- |
| **Gilberto Wright** | Ingeniero de Infraestructura Defensiva | `docker/`, `windows-ad/`, `fortigate/`, `deploy_soc_ubuntu.sh` |
| **Diego Vallarino** | Analista SOC | `siem-soc/`, `auditoria/` (Wazuh UEBA, Sysmon, PingCastle, Policy Analyzer, Lynis) |
| **Jeremy Ballesteros** | Líder de Respuesta y GRC | `dfir-forense/`, `bitacora/`, `entregables/` (IRP, FTK/SHA-256, Tabletop, Ley 81, GoPhish) |

**Docente:** Juan Pablo Zelayandia | **Organización Ficticia:** Alcaldía de Valle Escondido (`ave.local`)

---

## Arquitectura del Homelab Istmo SOC

```text
+-------------------------------+       VIP (445/3389 temp.       +------------------------------------+
|    Kali Linux (WAN / VMnet8)  |        y 8080/8443 WAF/SOC)     |         FortiGate VM (Evaluación)  |
|   172.16.116.0/24 (NAT DHCP)  | ------------------------------> | port1 WAN: 172.16.116.128          |
|  Atacante externo (en pruebas)|                                 | port2 LAN: 10.10.10.1              |
+-------------------------------+                                 | port3 DMZ: 172.16.10.0/24 (VMnet3) |
                                                                  | Máx. 3 políticas | Syslog 514/UDP  |
                                                                  +------------------+-----------------+
                                                                                     | port2 (LAN)
                                                                                     v
+------------------------------------------------------------------------------------------------------+
|                 SEGMENTO LAN CORPORATIVO — VMnet2 (Host-only, sin DHCP) — 10.10.10.0/24              |
|                                                                                                      |
|  +-------------------------------------------+      1514/TCP       +------------------------------+  |
|  |       WIN-SRV22 (10.10.10.10)             | <-----------------> |     UBU-SOC (10.10.10.20)    |  |
|  | Windows Server 2022 Standard Eval (EN)    |  Windows + Sysmon   | Ubuntu 24.04 LTS + Docker    |  |
|  | - AD DS (ave.local): 6 OUs, 4 grupos,     |                     | - Wazuh SIEM/XDR 4.9.0 :8443 |  |
|  |   8 usuarios + Honeytoken svc.respaldo_ad |                     | - Reglas UEBA 100600-100609  |  |
|  | - 3 GPOs + 10 controles CIS (SCA 39%)     |                     | - ModSecurity CRS -> DVWA    |  |
|  | - Agentes: Wazuh, Sysmon64, GLPI Agent    |                     | - Suricata 7.0.6 IDS + GLPI  |  |
|  +-------------------------------------------+                     | - GoPhish (:3333) + MailHog  |  |
|                                                                    +------------------------------+  |
+------------------------------------------------------------------------------------------------------+
```

---

## Estructura del Repositorio

```text
ave-soc-reto6/
├── README.md                                 # Documentación maestra y guía de despliegue
├── .gitignore                                # Excluye binarios forenses (>100 MB), .evtx y secretos
├── deploy_soc_ubuntu.sh                      # Orquestación reproducible de todos los stacks Docker
├── docker/                                   # Stacks Docker Compose (Wazuh, WAF/DVWA, Suricata, GLPI, GoPhish/MailHog)
├── siem-soc/
│   ├── wazuh/                                # local_rules.xml / ave_identidad_rules.xml (100600-100609) y ossec.conf
│   └── sysmon/                               # Configuración SwiftOnSecurity (sysmonconfig-export.xml)
├── windows-ad/
│   ├── scripts/                              # Scripts PowerShell reproducibles (AD, Hardening CIS, Forense SHA-256)
│   └── backups/                              # Respaldos reales de GPOs, estructura AD y AuditPol
├── fortigate/
│   ├── fortigate_ave_sanitized.conf          # Respaldo sanitizado del firewall (sin hashes de contraseñas)
│   └── politicas_y_vips.md                   # Matriz de las 3 políticas, VIPs y Syslog 514/UDP
├── auditoria/
│   ├── pingcastle/                           # Reporte HTML ad_hc_ave.local.html (Domain Risk 55/100)
│   ├── policy-analyzer/                      # Comparativa de 363 ítems (.tsv y .PolicyRules) vs MS Baseline
│   └── lynis/                                # Auditoría de UBU-SOC (Hardening Index 61)
├── dfir-forense/                             # Cadena_Custodia_SHA256.csv y snapshots de Domain Admins / GPOs
├── bitacora/
│   └── BITACORA_SEMANAL.md                   # Registro semanal ABR y bitácora ética de pruebas
└── entregables/                              # Índice y documentos oficiales del proyecto (Entregables 00 a 11)
```

---

## Resumen de Resultados Verificados

| Indicador / Capacidad | Resultado Medido | Herramienta / Evidencia |
| :--- | :--- | :--- |
| **Postura CIS en `WIN-SRV22-EN`** | **31 % $\to$ 39 %** (`113` $\to$ `142` Passed, `+29` controles) | Wazuh SCA (*CIS WS2022 v2.0.0*) |
| **10 Controles Priorizados** | **10/10** en estado `CUMPLE` (antes `NO CUMPLE`) | PowerShell + GPMC (`GPO-01/02/03`) |
| **Postura en `UBU-SOC` (Ubuntu 24.04)** | **60.57 % / 61 %** (CIS-CAT) y **Index 61** (Lynis) | CIS-CAT Lite v4.68.0 + Lynis (255 pruebas) |
| **Salud Active Directory** | **Domain Risk Level: 55 / 100** (`Trusts: 0/100`) | PingCastle (`ad_hc_ave.local.html`) |
| **Análisis de Brechas GPO** | **363 ítems** comparados vs `MS-WS2022-Baseline` | Microsoft Policy Analyzer (SCT) |
| **Detección SIEM / UEBA** | Reglas `100600`–`100609`, `60115`, `92652` validadas | Wazuh 4.9.0 + NetExec + FreeRDP + Atomic Red Team |
| **Simulacro Concienciación** | **3/3** enviados, **3/3** abiertos, **3/3** clics (`100 %`) | GoPhish + MailHog (`Simulacro_Phishing_AVE`) |
| **Evidencia Forense DFIR** | **5 artefactos** sellados con SHA-256 (`RAM 2048 MB`) | Exterro FTK Imager 8.3.1.6 + `Get-FileHash` |
| **Métricas Tabletop (CISA)** | **MTTD:** `1.5 min` \| **MTTC:** `8.0 min` \| **MTTR:** `22.0 min` | Cumple SLA (`<5` / `<15` / `<60` min) |

---

## Despliegue Reproducible Rápido

### 1. En `UBU-SOC` (Ubuntu Server 24.04 LTS — `10.10.10.20`)
```bash
# Ajustar memoria virtual requerida por Wazuh Indexer
sudo sysctl -w vm.max_map_count=262144

# Clonar repositorio y levantar todos los stacks Docker
git clone https://github.com/<usuario>/ave-soc-reto6.git
cd ave-soc-reto6
chmod +x deploy_soc_ubuntu.sh
./deploy_soc_ubuntu.sh
```

### 2. En `WIN-SRV22` (Windows Server 2022 — `10.10.10.10`, PowerShell como Administrador)
```powershell
# Aplicar endurecimiento CIS reproducible sobre ave.local
.\windows-ad\scripts\02_Hardening_CIS_AVE.ps1

# Ejecutar exportación forense (.evtx, snapshots AD/GPO) y sellado SHA-256
.\windows-ad\scripts\03_Adquisicion_Forense_SHA256.ps1
```

---

## Índice Oficial de los 11 Entregables

| # | Entregable Oficial | Archivo / Ubicación |
| :-: | :--- | :--- |
| **00** | Bitácora semanal y reglas de enfrentamiento (6 % rúbrica) | `bitacora/BITACORA_SEMANAL.md` y `00_Bitacora_Semanal_y_Registro_Pruebas_AVE.docx` |
| **01** | Ficha del reto (pregunta esencial, alcance, RACI) | `01_Ficha_del_Reto_y_RACI_Alcaldia_Valle_Escondido.docx` |
| **02** | Diagrama de red e inventario con matriz de criticidad | `02_Arquitectura_Inventario_y_Criticidad_AVE.docx` |
| **03** | Repositorio Git (`docker-compose`, reglas, configs, scripts) | Este repositorio (`ave-soc-reto6`) |
| **04** | Informe de postura inicial/final + 10 controles priorizados | `04_Informe_Postura_y_10_Controles_Hardening_AVE.docx` |
| **05** | IRP, Playbook del reto, Triage (10 alertas), Ley 81 y Anexo Móvil | `05_IRP_Playbook_y_Politicas_AVE.docx` |
| **06** | Informe forense inicial (FTK Imager, SHA-256, custodia) | `06_Informe_Forense_y_Cadena_Custodia_AVE.docx` |
| **07** | Acta del tabletop con línea de tiempo, MTTD y MTTR | `07_Acta_Tabletop_MTTD_MTTR_AVE.docx` |
| **08** | Informe ejecutivo (máx. 2 páginas) y lecciones aprendidas | `08_Informe_Ejecutivo_y_Lecciones_Aprendidas_AVE.docx` |
| **09** | Programa y cápsula de concienciación de 5 minutos | `09_Programa_y_Capsula_Concienciacion_AVE.docx` |
| **10** | Video de evidencias (5 a 8 minutos) y guion cronometrado | `10_Guion_Video_Evidencias_AVE.md` + archivo `.mp4` |
| **11** | Defensa en vivo (20 minutos) + banco de preguntas individuales | `11_Guion_Defensa_y_Preguntas_AVE.md` + presentación |

---

## Reglas de Enfrentamiento Ético

Todas las pruebas ofensivas y de simulación fueron ejecutadas **exclusivamente dentro del homelab aislado en VMware Workstation** (`VMnet8` hacia VIPs del FortiGate y pruebas locales en `WIN-SRV22`). No se ejecutó tráfico intrusivo contra la red del ITSE ni servicios de terceros, y los binarios forenses pesados (`.mem`, `.evtx`) se excluyen del control de versiones conservando sus hashes criptográficos SHA-256 en `dfir-forense/Cadena_Custodia_SHA256.csv`.