-- =============================================
-- SCRIPT DE INFLADO PARA ESQUEMA UnTrade
-- Utilizando CTE Recursivas (MySQL 8.0+)
-- =============================================

USE UnTrade;

-- Aumentar limite de recursión
SET SESSION cte_max_recursion_depth = 100000;

-- ---------------------------------------------
-- 1. ENTIDADES FUERTES (Universidades y Categorías)
-- ---------------------------------------------

-- Poblar 100 Universidades
INSERT INTO UNIVERSIDAD (nombre, pais, dominio_correo)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 100
)
SELECT 
    CONCAT('Universidad ', x),
    ELT(1 + FLOOR(RAND() * 5), 'Colombia', 'México', 'Argentina', 'Chile', 'Perú'),
    CONCAT('@univ', x, '.edu.co') -- Respeta CHECK(dominio_correo LIKE '%@%.%')
FROM numeros;

-- Poblar 50 Categorías
INSERT INTO CATEGORIA (nombre)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 50
)
SELECT CONCAT('Categoría ', x) FROM numeros;

-- ---------------------------------------------
-- 2. USUARIOS Y SUPERCLASES (10,000 en total)
-- ---------------------------------------------

-- Poblar 10,000 Usuarios
INSERT INTO USUARIO (id_universidad, nombre_completo, correo_estudiantil, password_hash, fecha_registro)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 10000
)
SELECT 
    1 + FLOOR(RAND() * 100),
    CONCAT('Usuario ', x),
    CONCAT('usr', x, '_', FLOOR(RAND()*999), '@univ', 1 + FLOOR(RAND() * 100), '.edu.co'),
    SHA2(CONCAT('pass', x), 256),
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 730) DAY)
FROM numeros;

-- Subclase: 500 Administradores (IDs 1 al 500 de USUARIO)
INSERT INTO ADMINISTRADOR (id_administrador, nivel_permiso, fecha_asignacion, area_soporte)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 500
)
SELECT 
    x,
    ELT(1 + FLOOR(RAND() * 3), 'SuperAdmin', 'Moderador', 'Soporte'),
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365) DAY),
    ELT(1 + FLOOR(RAND() * 4), 'Técnica', 'Usuarios', 'Finanzas', 'General')
FROM numeros;

-- Subclase: 4,000 Vendedores (IDs 501 al 4500 de USUARIO)
INSERT INTO VENDEDOR (id_vendedor, calificacion, ventas_completadas)
WITH RECURSIVE numeros(x) AS (
    SELECT 501 UNION ALL SELECT x + 1 FROM numeros WHERE x < 4500
)
SELECT 
    x,
    ROUND(RAND() * 10, 1),
    FLOOR(RAND() * 200)
FROM numeros;

-- Subclase: 5,500 Compradores (IDs 4501 al 10000 de USUARIO)
INSERT INTO COMPRADOR (id_comprador, preferencias_busqueda)
WITH RECURSIVE numeros(x) AS (
    SELECT 4501 UNION ALL SELECT x + 1 FROM numeros WHERE x < 10000
)
SELECT 
    x,
    ELT(1 + FLOOR(RAND() * 4), 'Tecnología', 'Libros', 'Servicios', 'Tutorías')
FROM numeros;

-- ---------------------------------------------
-- 3. CATÁLOGO E ÍTEMS
-- ---------------------------------------------

-- Poblar 500 Materias
INSERT INTO MATERIA (id_universidad, nombre_materia, creditos)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 500
)
SELECT 
    1 + FLOOR(RAND() * 100),
    CONCAT('Materia ', x),
    1 + FLOOR(RAND() * 5)
FROM numeros;

-- Poblar 20,000 Publicaciones (50% Productos, 50% Servicios)
INSERT INTO PUBLICACION (id_vendedor, id_administrador_moderador, tipo_item, titulo, descripcion, fecha_publicacion, estado_publicacion)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 20000
)
SELECT 
    501 + FLOOR(RAND() * 4000), -- IDs de Vendedores
    1 + FLOOR(RAND() * 500),    -- IDs de Administradores
    IF(x % 2 = 0, 'Producto', 'Servicio'),
    CONCAT('Publicación Comercial ', x),
    'Descripción autogenerada para pruebas de rendimiento y estrés.',
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365) DAY),
    ELT(1 + FLOOR(RAND() * 4), 'Activa', 'Pausada', 'Bloqueada', 'Finalizada')
FROM numeros;

-- Subclase de Publicación: Poblar Productos dinámicamente usando INSERT...SELECT
INSERT INTO PRODUCTO (id_publicacion, precio, calificacion, estado_fisico, stock)
SELECT 
    id_publicacion,
    ROUND(10 + RAND() * 990, 2),
    ROUND(RAND() * 10, 1),
    IF(RAND() > 0.5, 'NUEVO', 'USADO'),
    FLOOR(RAND() * 100)
FROM PUBLICACION WHERE tipo_item = 'Producto';

-- Subclase de Publicación: Poblar Servicios dinámicamente usando INSERT...SELECT
INSERT INTO SERVICIO (id_publicacion, modalidad, tarifa_por_hora, disponibilidad_horaria, calificacion)
SELECT 
    id_publicacion,
    IF(RAND() > 0.5, 'Presencial', 'Virtual'),
    ROUND(15 + RAND() * 150, 2),
    ELT(1 + FLOOR(RAND() * 4), 'Lunes a Viernes', 'Fines de Semana', 'Nocturno', 'Flexible'),
    ROUND(RAND() * 10, 1)
FROM PUBLICACION WHERE tipo_item = 'Servicio';

-- ---------------------------------------------
-- 4. TABLAS ASOCIATIVAS (M:N)
-- ---------------------------------------------

-- Generar relaciones Categoría-Producto (aprox. 2 por producto)
-- Usamos IGNORE para evitar duplicados por la aletoriedad
INSERT IGNORE INTO CATEGORIA_PRODUCTO (id_categoria, id_producto)
SELECT 
    1 + FLOOR(RAND() * 50),
    id_producto
FROM PRODUCTO
CROSS JOIN (SELECT 1 UNION SELECT 2) AS n;

-- Generar relaciones Materia-Producto (aprox. 1 por cada producto filtrado)
INSERT IGNORE INTO MATERIA_PRODUCTO (id_materia, id_producto)
SELECT 
    1 + FLOOR(RAND() * 500),
    id_producto
FROM PRODUCTO
WHERE RAND() > 0.4;

-- ---------------------------------------------
-- 5. TRANSACCIONES
-- ---------------------------------------------

-- Poblar 30,000 Ofertas
INSERT INTO OFERTA (id_comprador, id_publicacion, monto_ofertado, fecha_oferta, estado_oferta)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 30000
)
SELECT 
    4501 + FLOOR(RAND() * 5500),
    1 + FLOOR(RAND() * 20000),
    ROUND(5 + RAND() * 500, 2),
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 300) DAY),
    ELT(1 + FLOOR(RAND() * 3), 'Pendiente', 'Aceptada', 'Rechazada')
FROM numeros;

-- Poblar 15,000 Préstamos (Respetando orden lógico de fechas mediante rangos disjuntos)
INSERT INTO PRESTAMO (id_comprador, id_publicacion, fecha_solicitud, fecha_inicio, fecha_devolucion_pactada, fecha_devolucion_real, estado_prestamo)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 15000
)
SELECT 
    4501 + FLOOR(RAND() * 5500),
    1 + FLOOR(RAND() * 20000),
    DATE_SUB(CURDATE(), INTERVAL (40 + FLOOR(RAND() * 60)) DAY), -- Solicitud hace 40-100 días
    DATE_SUB(CURDATE(), INTERVAL (20 + FLOOR(RAND() * 19)) DAY), -- Inicio hace 20-39 días
    DATE_SUB(CURDATE(), INTERVAL (10 + FLOOR(RAND() * 9)) DAY),  -- Pactada hace 10-19 días
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 9) DAY),         -- Real hace 0-9 días
    ELT(1 + FLOOR(RAND() * 4), 'Solicitado', 'Activo', 'Devuelto', 'Demorado')
FROM numeros;

-- Poblar 25,000 Compras
INSERT INTO COMPRA (id_comprador, id_publicacion, monto_total, fecha_transaccion, metodo_pago)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 25000
)
SELECT 
    4501 + FLOOR(RAND() * 5500),
    1 + FLOOR(RAND() * 20000),
    ROUND(10 + RAND() * 2000, 2),
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365) DAY),
    ELT(1 + FLOOR(RAND() * 4), 'Tarjeta', 'PSE', 'Efectivo', 'Cripto')
FROM numeros;

-- Poblar 10,000 Trueques (Evita que el ID de publicación deseada y ofrecida sean el mismo)
INSERT INTO TRUEQUE (id_comprador_iniciador, id_publicacion_deseada, id_publicacion_ofrecida, fecha_propuesta, estado_trueque)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 10000
)
SELECT 
    4501 + FLOOR(RAND() * 5500),
    1 + FLOOR(RAND() * 10000),     -- Segmento A
    10001 + FLOOR(RAND() * 10000), -- Segmento B (Garantiza diferencia)
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365) DAY),
    ELT(1 + FLOOR(RAND() * 3), 'Pendiente', 'Aceptado', 'Rechazado')
FROM numeros;

-- Poblar 5,000 Sanciones (fecha fin >= fecha inicio)
INSERT INTO SANCION (id_usuario, id_prestamo, id_administrador, motivo, monto_multa, fecha_inicio, fecha_fin, estado_sancion)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 5000
)
SELECT 
    1 + FLOOR(RAND() * 10000),
    IF(RAND() > 0.5, 1 + FLOOR(RAND() * 15000), NULL),
    1 + FLOOR(RAND() * 500),
    'Violación de términos y condiciones del portal',
    ROUND(RAND() * 500, 2),
    DATE_SUB(CURDATE(), INTERVAL (60 + FLOOR(RAND()*30)) DAY), -- Inicio hace 60-90 días
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*50) DAY),        -- Fin hace 0-50 días
    ELT(1 + FLOOR(RAND() * 3), 'Vigente', 'Pagada', 'Expirada')
FROM numeros;

-- ---------------------------------------------
-- 6. AUDITORÍA
-- ---------------------------------------------

-- Poblar 10,000 logs de auditoría 
INSERT INTO AUDITORIA_TRANSACCIONES (id_compra, id_trueque, id_prestamo, id_administrador, tipo_evento, detalle_evento, fecha_registro, usuario_auditor)
WITH RECURSIVE numeros(x) AS (
    SELECT 1 UNION ALL SELECT x + 1 FROM numeros WHERE x < 10000
)
SELECT 
    IF(RAND() > 0.6, 1 + FLOOR(RAND() * 25000), NULL),
    IF(RAND() > 0.6, 1 + FLOOR(RAND() * 10000), NULL),
    IF(RAND() > 0.6, 1 + FLOOR(RAND() * 15000), NULL),
    1 + FLOOR(RAND() * 500),
    ELT(1 + FLOOR(RAND() * 3), 'Modificación Estado', 'Reversión', 'Consulta Privilegiada'),
    'Transacción auditada automáticamente por reglas de negocio.',
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 365) DAY),
    'Sistema Core'
FROM numeros;

-- ---------------------------------------------
-- 7. REFRESCAR ESTADÍSTICAS DEL OPTIMIZADOR
-- ---------------------------------------------
ANALYZE TABLE UNIVERSIDAD, USUARIO, ADMINISTRADOR, VENDEDOR, COMPRADOR, MATERIA, PUBLICACION, CATEGORIA, PRODUCTO, CATEGORIA_PRODUCTO, SERVICIO, OFERTA, PRESTAMO, COMPRA, SANCION, MATERIA_PRODUCTO, TRUEQUE, AUDITORIA_TRANSACCIONES;