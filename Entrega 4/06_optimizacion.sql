-- ==============================================================================
-- ANÁLISIS DE RENDIMIENTO Y OPTIMIZACIÓN DE CONSULTAS
-- ==============================================================================

-- Para analizar la eficiencia de las consultas usamos "EXPLAIN ANALYZE"

-- ==============================================================================
-- CONSULTA N301 - ORIGINAL
-- ==============================================================================
EXPLAIN ANALYZE
SELECT 
    pu.id_vendedor, 
    u.nombre_completo, 
    SUM(co.monto_total) AS ingreso_total
FROM COMPRA co
JOIN PUBLICACION pu 
    ON co.id_publicacion = pu.id_publicacion
JOIN USUARIO u 
    ON pu.id_vendedor = u.id_usuario
GROUP BY 
    pu.id_vendedor, 
    u.nombre_completo
HAVING SUM(co.monto_total) > 10000;


-- ==============================================================================
-- CONSULTA N301 - OPTIMIZADA
-- ==============================================================================

-- 1. Creación de índices en llaves foráneas
CREATE INDEX idx_compra_id_publicacion 
    ON COMPRA (id_publicacion);

CREATE INDEX idx_publicacion_id_vendedor 
    ON PUBLICACION (id_vendedor);

-- 2. Consulta refactorizada usando pre-agregación
EXPLAIN ANALYZE
SELECT 
    vendedores_top.id_vendedor,
    u.nombre_completo,
    vendedores_top.ingreso_total
FROM (
    SELECT 
        pu.id_vendedor, 
        SUM(co.monto_total) AS ingreso_total
    FROM COMPRA co
    JOIN PUBLICACION pu 
        ON co.id_publicacion = pu.id_publicacion
    GROUP BY 
        pu.id_vendedor
    HAVING SUM(co.monto_total) > 10000
) AS vendedores_top
JOIN USUARIO u 
    ON vendedores_top.id_vendedor = u.id_usuario;


-- ==============================================================================
-- CONSULTA N404 - ORIGINAL
-- Lista los vendedores que actualmente no tienen ninguna publicación activa.
-- ==============================================================================
EXPLAIN ANALYZE
WITH VendedoresPublicadores AS (
    SELECT id_vendedor 
    FROM PUBLICACION 
    WHERE estado_publicacion = 'Activa'
)
SELECT u.nombre_completo
FROM USUARIO u 
JOIN VENDEDOR v 
    ON u.id_usuario = v.id_vendedor
WHERE NOT EXISTS (
    SELECT 1 
    FROM VendedoresPublicadores vp 
    WHERE vp.id_vendedor = v.id_vendedor
);


-- ==============================================================================
-- CONSULTA N404 - OPTIMIZADA
-- ==============================================================================

-- 1. Índice compuesto para habilitar un 'Covering index scan'
CREATE INDEX idx_pub_vendedor_estado 
    ON PUBLICACION (id_vendedor, estado_publicacion);

-- 2. Consulta refactorizada eliminando el bloque WITH
EXPLAIN ANALYZE
SELECT u.nombre_completo
FROM USUARIO u
JOIN VENDEDOR v 
    ON u.id_usuario = v.id_vendedor
WHERE NOT EXISTS (
    SELECT 1
    FROM PUBLICACION p
    WHERE p.id_vendedor = v.id_vendedor
      AND p.estado_publicacion = 'Activa'
);