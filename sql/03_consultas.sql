-- 03_consultas.sql
-- consultas de verificacion y ejercicios sobre los datos cargados

-- total de juegos cargados
select count(*) as juegos_cargados
from juegos;

-- primeros 5 juegos cargados
select codigo, titulo, precio
from juegos
order by juego_id limit 5;

-- juegos con precio mayor al precio promedio
select codigo, titulo, precio
from juegos
where precio > (
    select avg(precio) from juegos
);

-- listado de juegos con el nombre de su categoria
select j.titulo, c.nombre as categoria, j.precio
from juegos as j
inner join categorias as c
on c.categoria_id = j.categoria_id
order by c.nombre, j.titulo;

-- cantidad de juegos por categoria (incluye categorias sin juegos)
select c.codigo, c.nombre, count(j.juego_id) as juegos
from categorias as c
left join juegos as j
on j.categoria_id = c.categoria_id
group by c.categoria_id, c.codigo, c.nombre
order by c.categoria_id;

-- ejemplo de manejo de columna tipo arreglo
select
    nombre,
    parciales[1] as parcial_1,
    cardinality(parciales) as cantidad,
    95 = any(parciales) as obtuvo_95
from estudiantes;

-- verificacion de imagenes guardadas (tamano en bytes)
select nombre, octet_length(archivo) as bytes
from imagenes;
