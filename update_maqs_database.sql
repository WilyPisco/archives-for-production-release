--========= ACTUALIZAMOS LA TABLA RECLAMO
BEGIN;

-- 1. MIGRACIÓN DE COLUMNAS EXISTENTES (Preservar datos)
-- Renombramos archivo_reclamo a archivo_digital (según la lógica del nuevo esquema)
ALTER TABLE maqs.t_reclamo 
    RENAME COLUMN srl_id_archivo_reclamo TO srl_id_archivo_digital;

-- Transformamos la fecha de suceso de DATE a TIMESTAMPTZ y la renombramos
ALTER TABLE maqs.t_reclamo 
    ALTER COLUMN dte_fecha_suceso TYPE timestamptz USING dte_fecha_suceso::timestamptz,
    ALTER COLUMN dte_fecha_suceso SET DEFAULT now();

ALTER TABLE maqs.t_reclamo 
    RENAME COLUMN dte_fecha_suceso TO tsp_fecha_suceso;

-- 2. AGREGAR NUEVAS COLUMNAS
ALTER TABLE maqs.t_reclamo
    ADD COLUMN var_numero_reclamo_fisico varchar(20) NULL,
    ADD COLUMN srl_id_archivo_fisico int4 NULL,
    ADD COLUMN int_tipo_registro int4 NOT NULL DEFAULT 1, -- Valor por defecto necesario para registros viejos
    ADD COLUMN bool_es_titulo_personal bool NULL,
    ADD COLUMN var_representa_a varchar(100) NULL,
    ADD COLUMN var_nombre_instancia_representa varchar(255) NULL,
    ADD COLUMN var_cargo_actual varchar(100) NULL,
    ADD COLUMN var_relacion_instancia varchar(255) NULL,
    ADD COLUMN var_motivo_anulacion varchar(250) NULL;

-- 3. AJUSTAR RESTRICCIONES (CONSTRAINTS)
-- Opcional: Quitar el default de int_tipo_registro si el esquema estricto no lo lleva
ALTER TABLE maqs.t_reclamo ALTER COLUMN int_tipo_registro DROP DEFAULT;

-- Asegurar que var_numero_reclamo no tenga nulos antes de aplicar NOT NULL
UPDATE maqs.t_reclamo SET var_numero_reclamo = 'S/N' WHERE var_numero_reclamo IS NULL;
ALTER TABLE maqs.t_reclamo ALTER COLUMN var_numero_reclamo SET NOT NULL;

-- 4. CREACIÓN DE ÍNDICES NUEVOS
CREATE INDEX IF NOT EXISTS idx_reclamo_area_natural ON maqs.t_reclamo USING btree (idarea_suceso);
CREATE INDEX IF NOT EXISTS idx_reclamo_fecha_registro ON maqs.t_reclamo USING btree (tsp_fecha_registro);
CREATE INDEX IF NOT EXISTS idx_reclamo_tipo_registro ON maqs.t_reclamo USING btree (int_tipo_registro);

COMMIT;


--=============== ACTUALIZAMOS LA TABLA RECLAMO_PERSONA
BEGIN;

-- 1. AGREGAR NUEVAS COLUMNAS
ALTER TABLE maqs.t_persona_reclamo
    ADD COLUMN var_correo_alternativo varchar(50) NULL,
    ADD COLUMN var_numero_celular varchar(9) NULL, -- Se crea NULL primero para llenar datos
    ADD COLUMN var_otro_numero varchar(20) NULL,
    ADD COLUMN int_edad int4 NULL,
    ADD COLUMN var_genero varchar(50) NULL,
    ADD COLUMN var_autoidentificacion varchar(100) NULL,
    ADD COLUMN var_idioma_lengua varchar(100) NULL,
    ADD COLUMN var_otro_idioma_lengua varchar NULL,
    ADD COLUMN bool_lee_escribe_idioma bool NULL,
    ADD COLUMN bool_comunidad_campesina bool NULL,
    ADD COLUMN bool_comunidad_nativa bool NULL,
    ADD COLUMN var_nombre_comunidad varchar(100) NULL,
    ADD COLUMN var_anexo varchar(100) NULL,
    ADD COLUMN var_distrito varchar(100) NULL,
    ADD COLUMN var_provincia varchar(100) NULL,
    ADD COLUMN var_departamento varchar(100) NULL,
    ADD COLUMN var_nacionalidad varchar(100) NULL;

-- 2. MANEJO DE DATOS EXISTENTES PARA COLUMNAS NOT NULL
-- Llenamos el celular con ceros para registros antiguos (ajusta esto si prefieres migrar el teléfono fijo aquí)
UPDATE maqs.t_persona_reclamo 
SET var_numero_celular = '000000000' 
WHERE var_numero_celular IS NULL;

-- 3. APLICAR RESTRICCIONES (CONSTRAINTS)
ALTER TABLE maqs.t_persona_reclamo 
    ALTER COLUMN var_numero_celular SET NOT NULL;

-- 4. CREACIÓN DE ÍNDICES
CREATE INDEX IF NOT EXISTS idx_persona_departamento ON maqs.t_persona_reclamo USING btree (var_departamento);
CREATE INDEX IF NOT EXISTS idx_persona_documento ON maqs.t_persona_reclamo USING btree (int_tipo_doc, var_char_numero_doc);

COMMIT;


-- ================= ACTUALIZAMOS LAS RUTAS DE T_ARCHIVO ====================
BEGIN;

-- 1. ACTUALIZAR RUTAS DE ARCHIVOS DIGITALES (Origen: srl_id_archivo_digital)
-- Establece la ruta fija 'var/www/html/documentos/maqs/digital'
UPDATE sernanp.t_archivo a
SET var_archivo_ruta_almacen = 'var/www/html/documentos/maqs/digital'
FROM maqs.t_reclamo r
WHERE a.srl_id_archivo = r.srl_id_archivo_digital;

-- 2. ACTUALIZAR RUTAS DE ARCHIVOS DE RESPUESTA (Origen: srl_id_archivo_respuesta)
-- Establece la ruta dinámica 'var/www/html/documentos/maqs/respuesta/{idreclamo}/'
UPDATE sernanp.t_archivo a
SET var_archivo_ruta_almacen = 'var/www/html/documentos/maqs/respuesta/' || r.srl_id_reclamo || '/'
FROM maqs.t_reclamo r
WHERE a.srl_id_archivo = r.srl_id_archivo_respuesta;

COMMIT;


-- ============= VERIFICAMOS LOS CAMBIOS===============================
SELECT 
    r.srl_id_reclamo,
    r.var_numero_reclamo,
    
    -- ARCHIVO DIGITAL
    ad.srl_id_archivo           AS id_archivo_digital,
    ad.var_nombre_archivo       AS nombre_digital,
    ad.var_archivo_ruta_almacen AS ruta_digital, -- ¡Verifica aquí la ruta fija!
    
    -- ARCHIVO RESPUESTA (La carta de respuesta)
    ar.srl_id_archivo           AS id_archivo_respuesta,
    ar.var_nombre_archivo       AS nombre_respuesta,
    ar.var_archivo_ruta_almacen AS ruta_respuesta -- ¡Verifica aquí la ruta con ID!

FROM maqs.t_reclamo r

LEFT JOIN sernanp.t_archivo ad 
    ON r.srl_id_archivo_digital = ad.srl_id_archivo
LEFT JOIN sernanp.t_archivo ar 
    ON r.srl_id_archivo_respuesta = ar.srl_id_archivo
WHERE r.srl_id_archivo_digital IS NOT NULL 
   OR r.srl_id_archivo_respuesta IS NOT NULL

ORDER BY r.srl_id_reclamo DESC;