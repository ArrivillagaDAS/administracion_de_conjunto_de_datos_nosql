
-- ================== DEMOSTRAR QUE HAY 20 JUEGOS =====================

-- paso 1. CREAR TABLA TEMPORAL
CREATE TABLE temporal_xml(data XML);


-- paso2. Imoportar datos hacia la tabla temporal.
\copy temporal_xml(data) FROM '/ruta/al/archivo';

 -- paso3. Insertar datos en Las tablas
 INSERT INTO juegos (codigo, titulo, precio, fecha_lanzamiento, categoria_id)
SELECT 
    x.codigo,
    x.titulo,
    x.precio,
    x.fecha_lanzamiento,x
    x.categoria_id
FROM temporal_xml AS t
CROSS JOIN LATERAL XMLTABLE(
    '/juegos/juego'
    PASSING BY REF t.data
    COLUMNS
        codigo CHAR(3) PATH 'codigo',
        titulo VARCHAR(150) PATH 'titulo',
        precio NUMERIC(8, 2) PATH 'precio',
        fecha_lanzamiento DATE PATH 'fecha_lanzamiento',
        categoria_id INT PATH 'categoria_id'
) AS x;

-- paso4. Codigo para contar la cantidad de juegos (solucion esperada 20)

SELECT COUNT(titulo) FROM juegos;


-- =================== CANTIDAD DE JUEGOS POR CATEGORIA =========================

-- paso 1. crear la tabla temporal

CREATE TABLE temporal_json(data JSONB);

-- Paso 2. Importar los datos del archivo json.

\copy temporal_json(data) FROM '/ruta/al/archivo.json';


INSERT INTO categorias (codigo, nombre, descripcion)
SELECT
    (elem->>'codigo')::CHAR(3) AS codigo,
    (elem->>'nombre')::VARCHAR(100) AS nombre,
    (elem->>'descripcion')::VARCHAR(250) AS descripcion
FROM temporal_json,
LATERAL jsonb_array_elements(data) AS elem;

SELECT
    c.nombre AS categoria,
    COUNT(j.categoria_id) AS total_juegos
FROM
    categorias c
LEFT JOIN
    juegos j ON c.categoria_id = j.categoria_id
GROUP BY
    c.categoria_id, c.nombre;