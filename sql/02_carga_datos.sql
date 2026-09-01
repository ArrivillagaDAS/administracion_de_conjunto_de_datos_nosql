-- 02_carga_datos.sql
-- carga de datos desde archivos externos json y xml

-- ===== carga de categorias desde json =====

-- se usa PROGRAM con tr para quitar saltos de linea antes de copiar,
-- esto evita errores de "premature end of data" al leer el json
\copy temporal_json(data) FROM PROGRAM 'tr -d "\r\n" < /home/camper/Escritorio/sofi/postgres/categorias.json'

-- se recorre el arreglo json y se insertan las categorias
insert into categorias (codigo, nombre, descripcion)
select
    e->>'codigo',
    e->>'nombre',
    e->>'descripcion'
from temporal_json as t
cross join lateral jsonb_array_elements(t.data) as e;


-- ===== carga de juegos desde xml =====

-- tabla temporal para el xml, se puede crear como temporal (temp table)
-- para que se borre sola al cerrar la sesion
create temp table temporal_xml (data xml);

-- igual que con el json, se quitan saltos de linea con tr antes de copiar
-- (copiar el xml tal cual, sin el tr, da error de "premature end of data")
\copy temporal_xml(data) FROM PROGRAM 'tr -d "\r\n" < /home/camper/Escritorio/sofi/postgres/juegos.xml'

-- se usa xmltable para convertir cada nodo <juego> en una fila
insert into juegos (codigo, titulo, precio, fecha_lanzamiento, categoria_id)
select
    x.codigo,
    x.titulo,
    x.precio,
    x.fecha_lanzamiento,
    x.categoria_id
from temporal_xml as t,
xmltable(
    '/juegos/juego'
    passing t.data
    columns
        codigo char(3) path 'codigo',
        titulo varchar(150) path 'titulo',
        precio numeric(8,2) path 'precio',
        fecha_lanzamiento date path 'fecha_lanzamiento',
        categoria_id int path 'categoria_id'
) as x;

-- se limpia la tabla temporal despues de usarla
drop table if exists temporal_xml;


-- ===== ejemplo de columna tipo arreglo =====

insert into estudiantes (codigo, nombre, parciales)
values ('E001', 'Pedro', array[90, 95, 97]);


-- ===== ejemplo de carga de archivo binario (imagen) =====
-- nota: este insert fallo en la sesion original por permisos del
-- sistema de archivos (permission denied), se deja documentado
-- para referencia y para corregirlo mas adelante

insert into imagenes (nombre, archivo)
select
    '_.jpeg',
    pg_read_binary_file('/ruta/al/archivo/_.jpeg');
