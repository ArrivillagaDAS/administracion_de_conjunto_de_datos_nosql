# Carga de datos JSON y XML en PostgreSQL

Trabajo de base de datos donde se cargan datos externos en formato JSON y XML dentro de tablas relacionales de PostgreSQL, y luego se hacen consultas sobre esos datos.

## Base de datos

Se trabajo sobre la base de datos `json`, creada con:

```sql
CREATE DATABASE json;
```

## Estructura del repositorio

- `01_esquema.sql` — creacion de las tablas (`categorias`, `temporal_json`, `juegos`, `estudiantes`, `imagenes`)
- `02_carga_datos.sql` — carga de datos desde los archivos `categorias.json` y `juegos.xml`, mas ejemplos de arreglos e imagenes
- `03_consultas.sql` — consultas de verificacion y ejercicios sobre los datos ya cargados

## Explicacion del proceso

### 1. Categorias desde JSON

Se creo una tabla temporal `temporal_json` con una sola columna `jsonb` para recibir el archivo completo. El archivo se copio usando `\copy ... FROM PROGRAM` con el comando `tr -d "\r\n"`, que elimina saltos de linea antes de que postgres intente parsear el json (sin esto, la copia directa con `\copy` fallaba).

Luego se recorrio el arreglo json con `jsonb_array_elements` y `CROSS JOIN LATERAL` para insertar cada objeto como una fila en `categorias`.

### 2. Juegos desde XML

Mismo procedimiento: se creo una tabla temporal `temporal_xml` con una columna `xml`, y se copio el archivo tambien filtrando saltos de linea con `tr -d "\r\n"` (copiar el xml tal cual daba el error `premature end of data`).

Para convertir cada nodo `<juego>` en una fila se uso `XMLTABLE`, indicando la ruta xpath y el tipo de dato de cada columna. La primera version del insert intentaba usar `xpath()` directamente con cast a `numeric`, pero eso fallaba porque no se puede castear `xml` a `numeric` directamente; hubo que pasar primero por `::text` o, mejor, usar `XMLTABLE` que maneja los tipos de forma mas limpia.

### 3. Errores encontrados y resueltos

- `syntax error at or near "JSONB"` — se intento crear una tabla con `FROM temporal_json(data JSONB)`, sintaxis invalida para un `SELECT`.
- `invalid input syntax for type json` — se intento copiar el archivo xml dentro de una columna `json`.
- `cannot cast type xml to numeric` — no se puede castear de `xml` a `numeric` en un solo paso, se necesita pasar por `text`.
- `null value in column "codigo" violates not-null constraint` — el cast directo desde xpath devolvia nulos, resuelto usando `XMLTABLE`.
- `duplicate key value violates unique constraint "juegos_codigo_key"` — se corrio el insert de juegos mas de una vez sin vaciar la tabla antes.
- `relation "temporal_xml" already exists` / `does not exist` — quedaban tablas temporales de intentos anteriores, se agrego `DROP TABLE IF EXISTS` para limpiar antes de volver a crear.
- `could not open file ... Permission denied` — al insertar una imagen con `pg_read_binary_file`, el usuario de postgres no tenia permiso de lectura sobre la carpeta del archivo.

### 4. Ejercicios adicionales

- Tabla `estudiantes` con una columna de tipo arreglo (`int[3]`) para guardar notas de parciales, y consultas usando `cardinality()` y el operador `ANY()`.
- Tabla `imagenes` con columna `bytea` para guardar archivos binarios usando `pg_read_binary_file`.

## Pruebas realizadas

### Carga de categorias

```
json=# INSERT INTO categorias (codigo, nombre, descripcion)
SELECT
    e->>'codigo',
    e->>'nombre',
    e->>'descripcion'
FROM temporal_json AS t
CROSS JOIN LATERAL jsonb_array_elements(t.data) AS e;
INSERT 0 4
```

### Carga de juegos (version final, sin duplicados)

```
json=# SELECT * FROM juegos;
 juego_id | codigo |              titulo              | precio | fecha_lanzamiento | categoria_id
----------+--------+----------------------------------+--------+-------------------+--------------
        1 | TW3    | The Witcher 3: Wild Hunt         |  39.99 | 2015-05-19        |            1
        2 | ELD    | Elden Ring                       |  59.99 | 2022-02-25        |            1
        3 | CPK    | Cyberpunk 2077                   |  49.99 | 2020-12-10        |            1
        4 | BG3    | Baldurs Gate 3                   |  59.99 | 2023-08-03        |            1
        5 | AOE    | Age of Empires IV                |  39.99 | 2021-10-28        |            2
        6 | CIV    | Sid Meiers Civilization VI       |  29.99 | 2016-10-21        |            2
        7 | SC2    | StarCraft II: Legacy of the Void |  19.99 | 2015-11-10        |            2
        8 | HOI    | Hearts of Iron IV                |  39.99 | 2016-06-06        |            2
        9 | DME    | Doom Eternal                     |  29.99 | 2020-03-20        |            3
       10 | GOW    | God of War Ragnarok              |  59.99 | 2022-11-09        |            3
       11 | RDR    | Red Dead Redemption 2            |  49.99 | 2018-10-26        |            3
       12 | SEK    | Sekiro: Shadows Die Twice        |  39.99 | 2019-03-22        |            3
       13 | FC2    | EA Sports FC 24                  |  69.99 | 2023-09-29        |            4
       14 | NBA    | NBA 2K24                         |  59.99 | 2023-09-08        |            4
       15 | F12    | F1 23                             |  49.99 | 2023-06-16        |            4
       16 | RLG    | Rocket League                    |   0.00 | 2015-07-07        |            4
       17 | SKY    | The Elder Scrolls V: Skyrim      |  19.99 | 2011-11-11        |            1
       18 | XCO    | XCOM 2                            |  24.99 | 2016-02-05        |            2
       19 | DMC    | Devil May Cry 5                   |  29.99 | 2019-03-08        |            3
       20 | PGA    | PGA Tour 2K23                     |  34.99 | 2022-10-14        |            4
(20 rows)
```

### Conteo total y primeros 5 registros

```
json=# SELECT COUNT(*) AS juegos_cargados FROM juegos;
 juegos_cargados
-----------------
              20
(1 row)

json=# SELECT codigo, titulo, precio FROM juegos ORDER BY juego_id LIMIT 5;
 codigo |          titulo          | precio
--------+--------------------------+--------
 TW3    | The Witcher 3: Wild Hunt |  39.99
 ELD    | Elden Ring               |  59.99
 CPK    | Cyberpunk 2077           |  49.99
 BG3    | Baldurs Gate 3           |  59.99
 AOE    | Age of Empires IV        |  39.99
(5 rows)
```

### Juegos con precio mayor al promedio

```
json=# SELECT codigo, titulo, precio
FROM juegos
WHERE precio > (SELECT AVG(precio) FROM juegos);
 codigo |        titulo          | precio
--------+------------------------+--------
 ELD    | Elden Ring              |  59.99
 CPK    | Cyberpunk 2077          |  49.99
 BG3    | Baldurs Gate 3          |  59.99
 GOW    | God of War Ragnarok     |  59.99
 RDR    | Red Dead Redemption 2   |  49.99
 FC2    | EA Sports FC 24         |  69.99
 NBA    | NBA 2K24                |  59.99
 F12    | F1 23                   |  49.99
(8 rows)
```

### Juegos con su categoria (join)

```
json=# SELECT j.titulo, c.nombre AS categoria, j.precio
FROM juegos AS j
INNER JOIN categorias AS c ON c.categoria_id = j.categoria_id
ORDER BY c.nombre, j.titulo;
              titulo              |   categoria   | precio
----------------------------------+---------------+--------
 Devil May Cry 5                  | Accion        |  29.99
 Doom Eternal                     | Accion        |  29.99
 God of War Ragnarok              | Accion        |  59.99
 Red Dead Redemption 2            | Accion        |  49.99
 Sekiro: Shadows Die Twice        | Accion        |  39.99
 EA Sports FC 24                  | Deportes      |  69.99
 F1 23                            | Deportes      |  49.99
 NBA 2K24                         | Deportes      |  59.99
 PGA Tour 2K23                    | Deportes      |  34.99
 Rocket League                    | Deportes      |   0.00
 Age of Empires IV                | Estrategia    |  39.99
 Hearts of Iron IV                | Estrategia    |  39.99
 Sid Meiers Civilization VI       | Estrategia    |  29.99
 StarCraft II: Legacy of the Void | Estrategia    |  19.99
 XCOM 2                           | Estrategia    |  24.99
 Baldurs Gate 3                   | Juegos de Rol |  59.99
 Cyberpunk 2077                   | Juegos de Rol |  49.99
 Elden Ring                       | Juegos de Rol |  59.99
 The Elder Scrolls V: Skyrim      | Juegos de Rol |  19.99
 The Witcher 3: Wild Hunt         | Juegos de Rol |  39.99
(20 rows)
```

### Cantidad de juegos por categoria

```
json=# SELECT c.codigo, c.nombre, COUNT(j.juego_id) AS juegos
FROM categorias AS c
LEFT JOIN juegos AS j ON j.categoria_id = c.categoria_id
GROUP BY c.categoria_id, c.codigo, c.nombre
ORDER BY c.categoria_id;
 codigo |    nombre     | juegos
--------+---------------+--------
 RPG    | Juegos de Rol |      5
 EST    | Estrategia    |      5
 ACC    | Accion        |      5
 DEP    | Deportes      |      5
(4 rows)
```

### Columna tipo arreglo (estudiantes)

```
json=# SELECT * FROM Estudiantes;
 id | codigo | nombre | parciales
----+--------+--------+------------
  1 | E001   | Pedro  | {90,95,97}
(1 row)

json=# SELECT nombre,
parciales[1] AS parcial_1,
cardinality(parciales) AS cantidad,
95 = ANY(parciales) AS obtuvo_95
FROM Estudiantes;
 nombre | parcial_1 | cantidad | obtuvo_95
--------+-----------+----------+-----------
 Pedro  |        90 |        3 | t
(1 row)
```

### Carga de imagen (bytea) — pendiente

```
json=# INSERT INTO imagenes (nombre, archivo)
SELECT '_.jpeg', pg_read_binary_file('/home/camper/Escritorio/sofi/postgres/_.jpeg');
ERROR:  could not open file "/home/camper/Escritorio/sofi/postgres/_.jpeg" for reading: Permission denied
```

Este paso quedo pendiente por un problema de permisos del sistema operativo sobre el archivo/carpeta, no es un error de la consulta sql en si. Para la proxima corrida, hay que darle permisos de lectura al usuario de postgres sobre esa ruta, o mover el archivo a una carpeta accesible (por ejemplo `/tmp`).

