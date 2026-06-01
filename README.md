# 🏥 Sistema de Automatización de Citas Médicas con n8n

> **Proyecto Final — Análisis de Sistemas I**  
> Automatización de procesos con n8n en entorno 100% local usando Docker Compose.

---

## 📋 Descripción

Sistema que automatiza el ciclo completo de una cita médica:
- Paciente agenda cita desde **formulario web local**
- n8n valida, procesa y guarda en **PostgreSQL**
- Doctor recibe **notificación inmediata por Telegram**
- Cada mañana el doctor recibe el **reporte diario de citas por Telegram**
- Registro completo de **auditoría y errores**

---

## 🧩 Stack tecnológico

| Componente | Tecnología | Puerto |
|---|---|---|
| Motor workflows | n8n latest | 5678 |
| Base de datos | PostgreSQL 15 | 5432 |
| Admin DB | Adminer | 8080 |
| Formulario web | Nginx + HTML | 3000 |
| Servidor email | Mailhog (local) | 8025 |
| Notificaciones | Telegram Bot | - |

---

## 🚀 Instalación y ejecución

### Prerrequisitos
- Docker Desktop instalado
- Git

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/AMI199A/citas-medicas-n8n.git
cd citas-medicas-n8n

# 2. Crear archivo de variables de entorno
cp .env.example .env
# Editar .env con tus contraseñas y tokens

# 3. Crear carpetas necesarias
mkdir -p input output logs

# 4. Levantar todos los servicios
docker compose up -d

# 5. Verificar que todo esté corriendo
docker compose ps
```

### Accesos

| Servicio | URL | Credenciales |
|---|---|---|
| n8n | http://localhost:5678 | Ver .env |
| Formulario web | http://localhost:3000 | Público |
| Adminer (DB) | http://localhost:8080 | Ver .env |
| Mailhog (emails) | http://localhost:8025 | Sin credenciales |

---

## 📁 Estructura del repositorio

```
citas-medicas-n8n/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── README.md
├── db/
│   └── init.sql
├── formulario/
│   └── index.html
├── workflows/
│   ├── WF1_Ingesta.json
│   ├── WF2_Procesamiento.json
│   └── WF3_Reportes.json
├── input/
│   └── citas_ejemplo.csv
├── output/
└── logs/
```

---

## ⚙️ Workflows n8n

### WF1 — Ingesta de citas
Recibe solicitudes desde el formulario web:
- **Webhook POST** → recibe datos del formulario
- **Edit Fields** → normaliza los datos
- **IF** → valida campos obligatorios
- **TRUE** → llama al WF2
- **FALSE** → registra error en tabla `errores`
- **Respond to Webhook** → responde al formulario con confirmación

### WF2 — Procesamiento y validación
Valida y guarda la cita:
- **Execute Trigger** → recibe datos del WF1
- **Postgres** → verifica solapamiento de horarios
- **IF** → ¿hay solapamiento?
- **Switch** → enruta por especialidad médica
- **Code** → genera número de cita único
- **Postgres** → inserta cita en tabla `citas`
- **Telegram** → notifica al doctor inmediatamente
- **Postgres** → registra en tabla `auditoria`

### WF3 — Reportes diarios
Envía reporte automático cada mañana:
- **Schedule Trigger** → se ejecuta diariamente a las 8:00 AM
- **Postgres** → obtiene citas del día siguiente
- **IF** → ¿hay citas?
- **Code** → genera mensaje con lista de pacientes
- **Telegram** → envía reporte al doctor

---

## 🗄️ Modelo de datos

### Tabla `citas`
Registro principal de todas las citas médicas.

### Tabla `errores`
Log de errores capturados durante la ejecución de workflows.

### Tabla `auditoria`
Bitácora completa de todas las acciones del sistema.

### Tabla `doctores`
Catálogo de médicos disponibles.

### Tabla `horarios_disponibles`
Horarios de atención por doctor.

---

## 🧪 Casos de prueba

| # | Caso | Entrada | Resultado esperado |
|---|---|---|---|
| 1 | Cita válida | Formulario con todos los campos | Insertada en DB + confirmación + Telegram |
| 2 | Campos faltantes | Sin teléfono | Registrado en tabla errores |
| 3 | Solapamiento | Misma fecha/hora/doctor | Rechazada, registra error |
| 4 | Reporte diario | Cron 8:00 AM | Mensaje Telegram con lista de citas |
| 5 | Sin citas mañana | Cron sin citas | No envía mensaje |

---

## 🔒 Seguridad

- Contraseñas en variables de entorno (`.env`)
- Archivo `.env` excluido del repositorio (`.gitignore`)
- n8n protegido con autenticación
- Logs de errores en tabla `errores`
- Bitácora completa en tabla `auditoria`

---

## 🛑 Detener el entorno

```bash
# Parar servicios (conserva datos)
docker compose down

# Parar Y eliminar volúmenes (borra la BD)
docker compose down -v
```

---

## 📹 Video demo
[Ver en Google Drive](https://drive.google.com/file/d/1iSjY3pEuWmKudCTie8DpZDp0YiSe6Zcr/view?usp=sharing)

---
## DOCUMENTACION TECNICO

[Ver en Google Drive](https://drive.google.com/drive/folders/16OF1SZwFPOLJUf8i3AhKeu5uQBgxW5sN?usp=sharing)

---

## 👤 Autor
**Amilcar Caal**  
Carné: 0902-22-11171  
Curso: Análisis de Sistemas I — 2026

