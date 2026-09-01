-- 01_esquema.sql
-- creacion de las tablas base del ejercicio json/xml

-- tabla de categorias, se llena luego desde el json
create table categorias (
    categoria_id serial primary key,
    codigo char(3) not null unique,
    nombre varchar(100) not null,
    descripcion varchar(250)
);

-- tabla temporal para recibir el json crudo antes de normalizar
create table temporal_json (
    data jsonb
);

-- tabla de juegos, se llena luego desde el xml
-- version final, con codigo unico para evitar duplicados
create table juegos (
    juego_id serial primary key,
    codigo char(3) not null unique,
    titulo varchar(150) not null,
    precio numeric(8, 2) not null,
    fecha_lanzamiento date,
    categoria_id int not null
);

-- ejemplo de tabla con columna de tipo arreglo
create table estudiantes (
    id serial primary key,
    codigo char(4),
    nombre varchar(30),
    parciales int[3]
);

-- ejemplo de tabla para guardar archivos binarios (imagenes)
create table imagenes (
    id serial primary key,
    nombre varchar(255),
    archivo bytea
);
