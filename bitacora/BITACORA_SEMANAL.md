# Bitácora Semanal de Decisiones, Aprendizajes y Registro Ético de Pruebas

**Proyecto:** Reto 6 — «Credenciales en venta» (Alcaldía de Valle Escondido, `ave.local`)  
**Asignatura:** Técnicas de Seguridad Informática I (EID1067) | **Grupo:** D-CS-4-1 | **Docente:** Juan Pablo Zelayandia  
**Equipo:** Gilberto Wright (Infraestructura Defensiva), Diego Vallarino (Analista SOC), Jeremy Ballesteros (Líder de Respuesta y GRC)

---

## Compromiso de Reglas de Enfrentamiento Ético

1. Toda prueba ofensiva o emulación MITRE ATT&CK se ejecutó exclusivamente contra el homelab aislado propio (*Homelab Istmo SOC*), desde `Kali Linux` en `VMnet8 (NAT)` o de forma local controlada en `WIN-SRV22`.
2. Quedó estrictamente prohibido cualquier escaneo, prueba de credenciales o envío de correos contra la red institucional del ITSE, equipos de otros grupos o servicios en Internet (GoPhish operó 100 % aislado con MailHog).
3. Las exposiciones temporales en FortiGate (`WAN_a_LAN`, puertos `445/TCP` y `3389/TCP`) fueron deshabilitadas al finalizar las pruebas, `Kali Linux` fue apagada y las cuentas de prueba bloqueadas o creadas (`atomic.backdoor`) fueron limpiadas y restauradas.

---

## Registro Semanal de Avances (Eje Transversal Reflexionar — ABR)

### Semana 9 (10/11/2026 – 12/11/2026) — Sprint 0: Lanzamiento (*Involucrar*)
- **Responsables:** Gilberto Wright, Diego Vallarino, Jeremy Ballesteros.
- **Actividades:** Análisis del caso *Credenciales en venta*, formulación de la pregunta esencial, asignación de roles de liderazgo y configuración base en VMware Workstation (`VMnet8` WAN, `VMnet2` LAN `10.10.10.0/24` sin DHCP). Despliegue inicial de `FortiGate VM` (`port1` `172.16.116.128`, `port2` `10.10.10.1`) y preparación de `UBU-SOC` con 8 GB de Swap y `vm.max_map_count=262144`.
- **Decisiones y aprendizajes:** Se limitó la memoria del Wazuh Indexer y se añadió Swap para estabilizar Docker en el host. Se confirmó el tope de 3 políticas y 3 interfaces de la licencia de evaluación permanente de FortiGate-VM, delegando la inspección IDS a Suricata.

### Semana 10 (13/11/2026 – 18/11/2026) — Sprint 1: Núcleo y Línea Base (*Investigar*)
- **Responsables:** Gilberto Wright, Diego Vallarino.
- **Actividades:** Despliegue en `UBU-SOC` (`10.10.10.20`) de Wazuh 4.9.0 single-node, Nginx + ModSecurity OWASP CRS + DVWA, Suricata 7.0.6 IDS y GLPI + MariaDB. Promoción de `WIN-SRV22` (`10.10.10.10`) a Controlador de Dominio `ave.local` (6 OUs, 4 grupos, 8 funcionarios), instalación de Sysmon64, Wazuh Agent y GLPI Agent. Medición inicial: **Wazuh SCA `31 %` (113 Passed / 246 Failed)** en Windows; **CIS-CAT Lite `60.57 %` (`61 %`)** y **Lynis `Index 61`** en Ubuntu.
- **Error resuelto y aprendizaje:** En Windows Server en español, el motor SCA de Wazuh generaba falsos fallos al evaluar la salida localizada de `net accounts`. Se estandarizó el DC en Windows Server 2022 Evaluation en inglés (`WIN-SRV22-EN`) y se sincronizó UTC-5 (América/Panamá) en toda la LAN.

### Semana 11 (19/11/2026 – 22/11/2026) — Sprint 2: Controles del Reto y Validación (*Actuar*)
- **Responsables:** Gilberto Wright, Diego Vallarino.
- **Actividades:** Aplicación de `GPO-01` (contraseñas $\ge 14$ caracteres, historial 24), `GPO-02` (bloqueo 5 intentos / 30 min) y `GPO-03` (auditoría avanzada), más endurecimiento CIS (SMB Signing, SMBv1 deshabilitado, NTLMv2 nivel 5, `RestrictAnonymous=1`, `RunAsPPL=1`, RDP NLA). Reevaluación SCA: **salto de `31 %` a `39 %` (`142` Passed, `+29` controles)** y 10/10 controles verificados en `CUMPLE`. Auditorías de excelencia con **PingCastle (`55/100`)** y **Microsoft Policy Analyzer (`363` ítems)**. Despliegue de `ave_identidad_rules.xml` (`100600`–`100609`) y Honeytoken `svc.respaldo_ad`.
- **Error resuelto y aprendizaje:** Al hacer ping desde Kali (`VMnet8`) directo a `10.10.10.10`, el tráfico salía por `172.16.116.2` (~210 ms) saltándose el FortiGate. Se diagnosticó con `traceroute` y se corrigió dirigiendo las pruebas exclusivamente a las VIPs del FortiGate (`172.16.116.128:445` y `:3389`).

### Semana 12 (22/11/2026 – 24/11/2026) — Sprint 3: Incidente Simulado, Concienciación y Forense (*Actuar*)
- **Responsables:** Jeremy Ballesteros, Gilberto Wright, Diego Vallarino.
- **Actividades:** Validación controlada de *Password Spraying* con NetExec (alertas `100600`, `100601` N12 y bloqueo `60115` sobre `g.frias`), RDP nocturno con `xfreerdp3` (`m.solis` $\to$ regla `100603`), activación del Honeytoken `svc.respaldo_ad` (5 hits N15 `100609`) y Atomic Red Team (`T1087.002`/`T1136.002` $\to$ `100605` N11 y `100607` N15). Despliegue aislado de **GoPhish + MailHog** (`Simulacro_Phishing_AVE`: `3/3` enviados, `3/3` abiertos, `3/3` clics). Adquisición forense con **Exterro FTK Imager 8.3.1.6** (`WIN-SRV22-EN_RAM.mem`, 2,048 MB), exportación `.evtx` y sellado **SHA-256**.
- **Decisiones y aprendizajes:** Se deshabilitó `WAN_a_LAN` en FortiGate, se apagó Kali y se ejecutó `Unlock-ADAccount`. El 100 % de clics en GoPhish demostró la necesidad crítica de la cápsula de 5 minutos, política anti-smishing y MFA por aplicación TOTP.

### Semana 13 (24/11/2026 – 27/11/2026) — Sprint 4: Mejora, Documentación y Defensa (*Actuar + Reflexionar*)
- **Responsables:** Gilberto Wright, Diego Vallarino, Jeremy Ballesteros.
- **Actividades:** Consolidación del repositorio Git reproducible (`ave-soc-reto6`), redacción de los entregables oficiales (Ficha/RACI, Arquitectura/Criticidad, Postura y 10 Controles, IRP/Playbook/Ley 81/Anexo Móvil, Informe Forense, Acta Tabletop con `MTTD 1.5 / MTTC 8 / MTTR 22 min`, Informe Ejecutivo y Programa de Concienciación), grabación del video de evidencias y ensayo de defensa en vivo.
- **Reflexión final:** El reparto por roles aceleró la entrega, mientras que las revisiones cruzadas garantizaron que los tres integrantes dominen la defensa integral de red, AD, SIEM y marco legal panameño.

---

## Registro Ético de Pruebas de Validación Controlada

| # | Fecha / Hora (UTC-5) | Herramienta | Objetivo Controlado | Resultado Esperado | Evidencia Verificada |
| :-: | :--- | :--- | :--- | :--- | :--- |
| 1 | 22/11/2026 17:27 | Prueba local sobre señuelo | `svc.respaldo_ad` (`WIN-SRV22-EN`) | Alerta crítica N15 (`100609`, `T1078`/`T1110`) | 5 hits N15 (`CAPTURA #19`) |
| 2 | 22/11/2026 ~18:00 | Atomic Red Team (`T1087.002`, `T1136.002`) | Dominio `ave.local` (`10.10.10.10`) | Detectar enumeración, creación `atomic.backdoor` (`100605`) y escalada `Domain Admins` (`100607`) con limpieza | Reglas `100605` N11 y `100607` N15 (`Screenshot_6/7/8.png`) |
| 3 | 22/11/2026 23:48 | NetExec (`nxc smb`) + `smbclient` (Kali) | VIP FortiGate `172.16.116.128:445` $\to$ `10.10.10.10` | Password Spraying (`Verano2026!`) $\to$ alertas `100600`, `100601` N12 y bloqueo `60115` (`g.frias`) | `STATUS_ACCOUNT_LOCKED_OUT` + `100601`/`60115` (`Screenshot_9/10/11.png`) |
| 4 | 22/11/2026 ~00:00 | FreeRDP (`xfreerdp3`, Kali) | VIP FortiGate `172.16.116.128:3389` $\to$ `10.10.10.10` | RDP válido fuera de horario (`m.solis`) $\to$ alerta UEBA `100603` (`4624` tipo 10) | 15 alertas UEBA (`evidencia rdp kali.png`, `CAPTURA #12`) |
| 5 | 22/11/2026 ~00:15 | Asignación privilegios (`soporte.ext`) | `WIN-SRV22-EN` (`10.10.10.10`) | Alerta `100608` N9 por Event ID `4672` | Alerta `100608` N9 (`CAPTURA 13C.png`) |
| 6 | 23/11/2026 18:24–18:45 | GoPhish + MailHog (Docker aislado) | `Funcionarios_Prueba_AVE` (3 cuentas) | Medir clics sin tráfico SMTP externo y mostrar página educativa | `3/3` enviados, `3/3` abiertos, `3/3` clics (`Screenshot_13..18.png`) |
| 7 | 23/11/2026 19:28 | Exterro FTK Imager 8.3.1.6 + PowerShell | `WIN-SRV22-EN` (`10.10.10.10`) | Adquirir RAM (`2048 MB`), logs `.evtx`, snapshots AD/GPO y sellar SHA-256 | 5 artefactos sellados (`CAPTURA #25a`, `#25b`) |