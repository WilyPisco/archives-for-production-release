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