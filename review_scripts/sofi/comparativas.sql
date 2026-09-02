-- 04_comparativas.sql
-- import de categorias desde json + consultas comparativas de precios

-- 1. importar json y demostrar que hay 4 categorias =====

-- se limpia por si ya existian datos de una corrida anterior
truncate table temporal_json;

-- se carga el json crudo (igual que en 02_carga_datos.sql, quitando saltos de linea)
\copy temporal_json(data) FROM PROGRAM 'tr -d "\r\n" < /home/camper/Escritorio/sofi/postgres/categorias.json'

-- se recorre el arreglo json y se insertan las categorias
-- (si ya existen, se omiten para no duplicar codigo unico)
insert into categorias (codigo, nombre, descripcion)
select
    e->>'codigo',
    e->>'nombre',
    e->>'descripcion'
from temporal_json as t
cross join lateral jsonb_array_elements(t.data) as e
on conflict (codigo) do nothing;

-- demostracion: deben ser exactamente 4 categorias
select count(*) as total_categorias
from categorias;

-- listado de las 4 categorias cargadas desde el json
select codigo, nombre, descripcion
from categorias
order by categoria_id;


-- 2. juegos por encima del promedio global de precio
-- resultado esperado: 8 juegos

select codigo, titulo, precio
from juegos
where precio > (select avg(precio) from juegos)
order by precio desc;

-- cantidad de juegos por encima del promedio global (verificacion)
select count(*) as juegos_sobre_promedio_global
from juegos
where precio > (select avg(precio) from juegos);


-- 3. juegos por encima del promedio de su propia categoria
-- resultado esperado: 10 juegos

select j.codigo, j.titulo, j.precio, c.nombre as categoria
from juegos as j
inner join categorias as c
    on c.categoria_id = j.categoria_id
where j.precio > (
    select avg(j2.precio)
    from juegos as j2
    where j2.categoria_id = j.categoria_id
)
order by c.nombre, j.precio desc;

-- cantidad de juegos por encima del promedio de su categoria (verificacion)
select count(*) as juegos_sobre_promedio_categoria
from juegos as j
where j.precio > (
    select avg(j2.precio)
    from juegos as j2
    where j2.categoria_id = j.categoria_id
);