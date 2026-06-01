-- ═══════════════════════════════════════════════════════════
-- SISTEMA DE AUTOMATIZACIÓN DE CITAS MÉDICAS
-- Script de inicialización de la base de datos
-- ═══════════════════════════════════════════════════════════

-- ── Extensiones ──
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ═══════════════════════════════════════════════════════════
-- TABLA PRINCIPAL: citas
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS citas (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_cita     VARCHAR(20) UNIQUE NOT NULL,
    paciente_nombre VARCHAR(150) NOT NULL,
    paciente_dpi    VARCHAR(20),
    paciente_tel    VARCHAR(20) NOT NULL,
    paciente_email  VARCHAR(150),
    especialidad    VARCHAR(80) NOT NULL,
    doctor          VARCHAR(150),
    fecha_cita      DATE NOT NULL,
    hora_cita       TIME NOT NULL,
    motivo          TEXT,
    estado          VARCHAR(30) NOT NULL DEFAULT 'pendiente'
                    CHECK (estado IN ('pendiente', 'confirmada', 'cancelada', 'completada', 'no_presentado')),
    canal_ingreso   VARCHAR(30) DEFAULT 'formulario'
                    CHECK (canal_ingreso IN ('formulario', 'whatsapp', 'telegram', 'csv', 'webhook')),
    recordatorio_enviado BOOLEAN DEFAULT FALSE,
    creado_en       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- TABLA: errores (registro de fallos capturados por n8n)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS errores (
    id              SERIAL PRIMARY KEY,
    workflow_nombre VARCHAR(100),
    nodo_nombre     VARCHAR(100),
    tipo_error      VARCHAR(100),
    mensaje         TEXT NOT NULL,
    datos_entrada   JSONB,
    resuelto        BOOLEAN DEFAULT FALSE,
    creado_en       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- TABLA: auditoria (bitácora de todas las ejecuciones)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS auditoria (
    id              BIGSERIAL PRIMARY KEY,
    accion          VARCHAR(100) NOT NULL,
    entidad         VARCHAR(50),
    entidad_id      VARCHAR(100),
    datos           JSONB,
    canal           VARCHAR(50),
    resultado       VARCHAR(20) DEFAULT 'exitoso'
                    CHECK (resultado IN ('exitoso', 'fallido', 'parcial')),
    creado_en       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- TABLA: doctores (catálogo)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS doctores (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(150) NOT NULL,
    especialidad    VARCHAR(80) NOT NULL,
    email           VARCHAR(150),
    telegram_id     VARCHAR(50),
    activo          BOOLEAN DEFAULT TRUE
);

-- ═══════════════════════════════════════════════════════════
-- TABLA: horarios_disponibles (para validar solapamiento)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS horarios_disponibles (
    id              SERIAL PRIMARY KEY,
    doctor_id       INTEGER REFERENCES doctores(id),
    dia_semana      SMALLINT CHECK (dia_semana BETWEEN 1 AND 7),
    hora_inicio     TIME NOT NULL,
    hora_fin        TIME NOT NULL
);

-- ═══════════════════════════════════════════════════════════
-- ÍNDICES para consultas frecuentes
-- ═══════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_citas_fecha     ON citas (fecha_cita);
CREATE INDEX IF NOT EXISTS idx_citas_estado    ON citas (estado);
CREATE INDEX IF NOT EXISTS idx_citas_doctor    ON citas (doctor);
CREATE INDEX IF NOT EXISTS idx_citas_solapam   ON citas (doctor, fecha_cita, hora_cita);
CREATE INDEX IF NOT EXISTS idx_auditoria_fecha ON auditoria (creado_en);

-- ═══════════════════════════════════════════════════════════
-- FUNCIÓN: actualizar campo updated_at automáticamente
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_citas_updated
    BEFORE UPDATE ON citas
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- ═══════════════════════════════════════════════════════════
-- DATOS DE EJEMPLO (catálogo de doctores)
-- ═══════════════════════════════════════════════════════════
INSERT INTO doctores (nombre, especialidad, email, activo) VALUES
    ('Dr. Carlos Méndez',    'Medicina General', 'cmendez@clinica.local', TRUE),
    ('Dra. Ana López',       'Pediatría',        'alopez@clinica.local',  TRUE),
    ('Dr. Roberto Sánchez',  'Odontología',      'rsanchez@clinica.local',TRUE),
    ('Dra. María García',    'Ginecología',      'mgarcia@clinica.local', TRUE)
ON CONFLICT DO NOTHING;

-- Vista útil para el reporte semanal
CREATE OR REPLACE VIEW v_resumen_semanal AS
SELECT
    especialidad,
    COUNT(*) FILTER (WHERE estado = 'confirmada')   AS confirmadas,
    COUNT(*) FILTER (WHERE estado = 'cancelada')    AS canceladas,
    COUNT(*) FILTER (WHERE estado = 'no_presentado') AS no_presentados,
    COUNT(*) FILTER (WHERE estado = 'completada')   AS completadas,
    COUNT(*)                                         AS total
FROM citas
WHERE fecha_cita >= DATE_TRUNC('week', NOW())
  AND fecha_cita <  DATE_TRUNC('week', NOW()) + INTERVAL '7 days'
GROUP BY especialidad;
