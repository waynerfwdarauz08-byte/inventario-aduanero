-- Laboratorio 3: Inventario aduanero
-- Estudiante: Wayner Jafeth Villalobos Arauz
-- Gestor: MySQL 8.0.46
-- Fecha: 2026-10-23

CREATE DATABASE IF NOT EXISTS aduana_wayner
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE aduana_wayner;

SELECT DATABASE() AS base_actual;


-- =====================================================
-- TABLA: pais
-- Guarda los países de origen de las declaraciones.
-- =====================================================

CREATE TABLE pais (
    id_pais INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    codigo_iso CHAR(2) NOT NULL,

    CONSTRAINT uq_pais_nombre UNIQUE (nombre),
    CONSTRAINT uq_pais_codigo_iso UNIQUE (codigo_iso)
) ENGINE = InnoDB;

-- Comprobar la estructura de la tabla.
DESCRIBE pais;




-- =====================================================
-- TABLA: importador
-- Guarda las empresas responsables de las declaraciones.
-- =====================================================

CREATE TABLE importador (
    id_importador INT AUTO_INCREMENT PRIMARY KEY,
    razon_social VARCHAR(150) NOT NULL,
    identificacion_fiscal VARCHAR(30) NOT NULL,
    direccion VARCHAR(250) NOT NULL,
    telefono VARCHAR(25) NOT NULL,
    correo VARCHAR(150) NOT NULL,

    CONSTRAINT uq_importador_identificacion
        UNIQUE (identificacion_fiscal)
) ENGINE = InnoDB;

DESCRIBE importador;


-- =====================================================
-- TABLA: agente_aduanal
-- Guarda los agentes que tramitan las declaraciones.
-- =====================================================

CREATE TABLE agente_aduanal (
    id_agente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    licencia VARCHAR(30) NOT NULL,
    telefono VARCHAR(25) NOT NULL,
    correo VARCHAR(150) NOT NULL,

    CONSTRAINT uq_agente_licencia UNIQUE (licencia)
) ENGINE = InnoDB;

DESCRIBE agente_aduanal;




-- =====================================================
-- TABLA: partida_arancelaria
-- Clasifica las mercancías y establece su arancel.
-- Los porcentajes serán datos de prueba del laboratorio.
-- =====================================================

CREATE TABLE partida_arancelaria (
    id_partida INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(15) NOT NULL,
    descripcion VARCHAR(250) NOT NULL,
    porcentaje_arancel DECIMAL(5,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT uq_partida_codigo UNIQUE (codigo),

    CONSTRAINT chk_partida_arancel
        CHECK (porcentaje_arancel BETWEEN 0 AND 100)
) ENGINE = InnoDB;

DESCRIBE partida_arancelaria;






-- =====================================================
-- TABLA: producto
-- Guarda las mercancías y su clasificación arancelaria.
-- =====================================================

CREATE TABLE producto (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    descripcion VARCHAR(200) NOT NULL,
    unidad_medida VARCHAR(20) NOT NULL,
    valor_unitario DECIMAL(14,2) NOT NULL,
    id_partida INT NOT NULL,

    CONSTRAINT chk_producto_valor
        CHECK (valor_unitario >= 0),

    CONSTRAINT fk_producto_partida
        FOREIGN KEY (id_partida)
        REFERENCES partida_arancelaria (id_partida)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

DESCRIBE producto;


-- =====================================================
-- TABLA: bodega
-- Guarda los depósitos y su capacidad en metros cúbicos.
-- =====================================================

CREATE TABLE bodega (
    id_bodega INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ubicacion VARCHAR(200) NOT NULL,
    capacidad_m3 DECIMAL(12,2) NOT NULL,

    CONSTRAINT uq_bodega_nombre UNIQUE (nombre),

    CONSTRAINT chk_bodega_capacidad
        CHECK (capacidad_m3 > 0)
) ENGINE = InnoDB;

DESCRIBE bodega;


-- =====================================================
-- TABLA: funcionario
-- Guarda los funcionarios y sus supervisores.
-- Incluye una relación recursiva.
-- =====================================================

CREATE TABLE funcionario (
    id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    cargo VARCHAR(80) NOT NULL,
    id_supervisor INT NULL,

    CONSTRAINT fk_funcionario_supervisor
        FOREIGN KEY (id_supervisor)
        REFERENCES funcionario (id_funcionario)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
) ENGINE = InnoDB;

DESCRIBE funcionario;




-- =====================================================
-- TABLA: declaracion
-- Guarda los trámites aduaneros.
-- =====================================================

CREATE TABLE declaracion (
    id_declaracion INT AUTO_INCREMENT PRIMARY KEY,
    numero VARCHAR(30) NOT NULL,
    fecha DATE NOT NULL,
    regimen VARCHAR(20) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Retenida',
    id_importador INT NOT NULL,
    id_agente INT NOT NULL,
    id_pais_origen INT NOT NULL,

    CONSTRAINT uq_declaracion_numero UNIQUE (numero),

    CONSTRAINT chk_declaracion_regimen
        CHECK (
            regimen IN (
                'Importacion',
                'Exportacion',
                'Transito',
                'Deposito'
            )
        ),

    CONSTRAINT chk_declaracion_estado
        CHECK (
            estado IN (
                'Retenida',
                'En revision',
                'Liberada',
                'Rechazada'
            )
        ),

    CONSTRAINT fk_declaracion_importador
        FOREIGN KEY (id_importador)
        REFERENCES importador (id_importador)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_declaracion_agente
        FOREIGN KEY (id_agente)
        REFERENCES agente_aduanal (id_agente)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_declaracion_pais
        FOREIGN KEY (id_pais_origen)
        REFERENCES pais (id_pais)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

DESCRIBE declaracion;




-- =====================================================
-- TABLA: detalle_declaracion
-- Resuelve la relación N:M entre declaración y producto.
-- El valor declarado es el total de la línea en USD.
-- =====================================================

CREATE TABLE detalle_declaracion (
    id_declaracion INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(14,3) NOT NULL,
    valor_declarado DECIMAL(16,2) NOT NULL,

    PRIMARY KEY (id_declaracion, id_producto),

    CONSTRAINT chk_detalle_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_detalle_valor
        CHECK (valor_declarado >= 0),

    CONSTRAINT fk_detalle_declaracion
        FOREIGN KEY (id_declaracion)
        REFERENCES declaracion (id_declaracion)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto (id_producto)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

DESCRIBE detalle_declaracion;






-- =====================================================
-- TABLA: contenedor
-- Guarda los contenedores de cada declaración.
-- El peso se expresa en kilogramos.
-- =====================================================

CREATE TABLE contenedor (
    id_contenedor INT AUTO_INCREMENT PRIMARY KEY,
    numero VARCHAR(20) NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    peso_kg DECIMAL(12,3) NOT NULL,
    id_declaracion INT NOT NULL,

    CONSTRAINT uq_contenedor_numero UNIQUE (numero),

    CONSTRAINT chk_contenedor_peso
        CHECK (peso_kg > 0),

    CONSTRAINT fk_contenedor_declaracion
        FOREIGN KEY (id_declaracion)
        REFERENCES declaracion (id_declaracion)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

DESCRIBE contenedor;




-- =====================================================
-- TABLA: inventario
-- Guarda las existencias por lote y bodega.
-- Cada lote pertenece a un detalle de declaración.
-- =====================================================

CREATE TABLE inventario (
    id_inventario INT AUTO_INCREMENT PRIMARY KEY,
    id_bodega INT NOT NULL,
    id_declaracion INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(14,3) NOT NULL DEFAULT 0,
    fecha_ingreso DATETIME NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Retenido',

    CONSTRAINT chk_inventario_cantidad
        CHECK (cantidad >= 0),

    CONSTRAINT chk_inventario_estado
        CHECK (
            estado IN (
                'Retenido',
                'En revision',
                'Liberado'
            )
        ),

    CONSTRAINT fk_inventario_bodega
        FOREIGN KEY (id_bodega)
        REFERENCES bodega (id_bodega)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_inventario_detalle
        FOREIGN KEY (id_declaracion, id_producto)
        REFERENCES detalle_declaracion (
            id_declaracion,
            id_producto
        )
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

DESCRIBE inventario;






-- =====================================================
-- TABLA: movimiento
-- Registra entradas, salidas y traslados entre lotes.
-- =====================================================

CREATE TABLE movimiento (
    id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(10) NOT NULL,
    fecha DATETIME NOT NULL,
    cantidad DECIMAL(14,3) NOT NULL,
    id_inventario INT NOT NULL,
    id_inventario_destino INT NULL,
    observaciones VARCHAR(250) NULL,

    CONSTRAINT chk_movimiento_tipo
        CHECK (tipo IN ('Entrada', 'Salida', 'Traslado')),

    CONSTRAINT chk_movimiento_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_movimiento_destino
        CHECK (
            (
                tipo = 'Traslado'
                AND id_inventario_destino IS NOT NULL
                AND id_inventario_destino <> id_inventario
            )
            OR
            (
                tipo IN ('Entrada', 'Salida')
                AND id_inventario_destino IS NULL
            )
        ),

    CONSTRAINT fk_movimiento_inventario
        FOREIGN KEY (id_inventario)
        REFERENCES inventario (id_inventario)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT,

    CONSTRAINT fk_movimiento_destino
        FOREIGN KEY (id_inventario_destino)
        REFERENCES inventario (id_inventario)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
) ENGINE = InnoDB;

DESCRIBE movimiento;


-- =====================================================
-- TABLA: inspeccion
-- Guarda las revisiones realizadas a las declaraciones.
-- =====================================================

CREATE TABLE inspeccion (
    id_inspeccion INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATETIME NOT NULL,
    resultado VARCHAR(25) NOT NULL,
    observaciones VARCHAR(500) NULL,
    id_declaracion INT NOT NULL,
    id_funcionario INT NOT NULL,

    CONSTRAINT chk_inspeccion_resultado
        CHECK (
            resultado IN (
                'Sin observaciones',
                'Con observaciones',
                'No conforme'
            )
        ),

    CONSTRAINT fk_inspeccion_declaracion
        FOREIGN KEY (id_declaracion)
        REFERENCES declaracion (id_declaracion)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_inspeccion_funcionario
        FOREIGN KEY (id_funcionario)
        REFERENCES funcionario (id_funcionario)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

DESCRIBE inspeccion;




-- Comprobar la base de datos y sus tablas.
USE aduana_wayner;

SHOW TABLES;






-- =====================================================
-- DATOS: pais
-- =====================================================

INSERT INTO pais (id_pais, nombre, codigo_iso) VALUES
(1, 'China', 'CN'),
(2, 'Estados Unidos', 'US'),
(3, 'Mexico', 'MX'),
(4, 'Costa Rica', 'CR'),
(5, 'Panama', 'PA'),
(6, 'Colombia', 'CO'),
(7, 'Brasil', 'BR'),
(8, 'Alemania', 'DE'),
(9, 'Japon', 'JP'),
(10, 'Corea del Sur', 'KR'),
(11, 'Espana', 'ES'),
(12, 'Italia', 'IT'),
(13, 'Canada', 'CA'),
(14, 'Chile', 'CL'),
(15, 'Guatemala', 'GT');

-- Verificar los datos.
SELECT * FROM pais ORDER BY id_pais;

SELECT COUNT(*) AS total_paises FROM pais;





-- =====================================================
-- DATOS: importador
-- Empresas e identificaciones ficticias para pruebas.
-- =====================================================

INSERT INTO importador (
    id_importador,
    razon_social,
    identificacion_fiscal,
    direccion,
    telefono,
    correo
) VALUES
(1, 'Comercial del Pacifico', 'PRUEBA-001',
 'Puntarenas, Chacarita', '2200-0001', 'contacto@pacifico.example'),
(2, 'Tecnologia Central', 'PRUEBA-002',
 'San Jose, Montes de Oca', '2200-0002', 'contacto@tecnocentral.example'),
(3, 'Alimentos del Valle', 'PRUEBA-003',
 'Cartago, El Guarco', '2200-0003', 'contacto@alimentosvalle.example'),
(4, 'Textiles Guanacaste', 'PRUEBA-004',
 'Guanacaste, Liberia', '2200-0004', 'contacto@textiles.example'),
(5, 'Repuestos del Caribe', 'PRUEBA-005',
 'Limon, canton central', '2200-0005', 'contacto@repuestoscaribe.example'),
(6, 'Hogar y Estilo', 'PRUEBA-006',
 'Heredia, San Francisco', '2200-0006', 'contacto@hogarestilo.example'),
(7, 'Suministros Industriales Ticos', 'PRUEBA-007',
 'Alajuela, El Coyol', '2200-0007', 'contacto@industriales.example'),
(8, 'Distribuidora Salud Integral', 'PRUEBA-008',
 'San Jose, Goicoechea', '2200-0008', 'contacto@saludintegral.example'),
(9, 'Agrocomercial del Norte', 'PRUEBA-009',
 'Alajuela, San Carlos', '2200-0009', 'contacto@agronorte.example'),
(10, 'Electrodomesticos del Este', 'PRUEBA-010',
 'Cartago, La Union', '2200-0010', 'contacto@electroeste.example'),
(11, 'Papeleria Empresarial', 'PRUEBA-011',
 'San Jose, Tibas', '2200-0011', 'contacto@papeleria.example'),
(12, 'Ferreteria Horizonte', 'PRUEBA-012',
 'Heredia, Belen', '2200-0012', 'contacto@horizonte.example'),
(13, 'Deportes y Aventura', 'PRUEBA-013',
 'San Jose, Escazu', '2200-0013', 'contacto@deportes.example'),
(14, 'Empaques Sostenibles', 'PRUEBA-014',
 'Alajuela, Grecia', '2200-0014', 'contacto@empaques.example'),
(15, 'Distribuidora Buen Cafe', 'PRUEBA-015',
 'Guanacaste, Nicoya', '2200-0015', 'contacto@buencafe.example');

-- Verificar los datos.
SELECT * FROM importador ORDER BY id_importador;

SELECT COUNT(*) AS total_importadores FROM importador;


-- =====================================================
-- DATOS: agente_aduanal
-- Personas y licencias ficticias para pruebas.
-- =====================================================

INSERT INTO agente_aduanal (
    id_agente,
    nombre,
    licencia,
    telefono,
    correo
) VALUES
(1, 'Ana Sofia Mora', 'LIC-PRUEBA-001',
 '2300-0001', 'ana.mora@aduana.example'),
(2, 'Carlos Alberto Rojas', 'LIC-PRUEBA-002',
 '2300-0002', 'carlos.rojas@aduana.example'),
(3, 'Maria Fernanda Solano', 'LIC-PRUEBA-003',
 '2300-0003', 'maria.solano@aduana.example'),
(4, 'Jose Daniel Vargas', 'LIC-PRUEBA-004',
 '2300-0004', 'jose.vargas@aduana.example'),
(5, 'Laura Isabel Castro', 'LIC-PRUEBA-005',
 '2300-0005', 'laura.castro@aduana.example'),
(6, 'Andres Felipe Jimenez', 'LIC-PRUEBA-006',
 '2300-0006', 'andres.jimenez@aduana.example'),
(7, 'Daniela Patricia Perez', 'LIC-PRUEBA-007',
 '2300-0007', 'daniela.perez@aduana.example'),
(8, 'Luis Fernando Herrera', 'LIC-PRUEBA-008',
 '2300-0008', 'luis.herrera@aduana.example'),
(9, 'Gabriela Elena Salas', 'LIC-PRUEBA-009',
 '2300-0009', 'gabriela.salas@aduana.example'),
(10, 'Diego Alejandro Campos', 'LIC-PRUEBA-010',
 '2300-0010', 'diego.campos@aduana.example'),
(11, 'Valeria Cristina Leon', 'LIC-PRUEBA-011',
 '2300-0011', 'valeria.leon@aduana.example'),
(12, 'Marco Antonio Cordero', 'LIC-PRUEBA-012',
 '2300-0012', 'marco.cordero@aduana.example'),
(13, 'Natalia Beatriz Arias', 'LIC-PRUEBA-013',
 '2300-0013', 'natalia.arias@aduana.example'),
(14, 'Pablo Andres Vega', 'LIC-PRUEBA-014',
 '2300-0014', 'pablo.vega@aduana.example'),
(15, 'Camila Andrea Mendez', 'LIC-PRUEBA-015',
 '2300-0015', 'camila.mendez@aduana.example');

-- Verificar los datos.
SELECT * FROM agente_aduanal ORDER BY id_agente;

SELECT COUNT(*) AS total_agentes FROM agente_aduanal;



-- =====================================================
-- DATOS: partida_arancelaria
-- Códigos y porcentajes simulados para fines educativos.
-- No representan clasificaciones ni tarifas oficiales.
-- =====================================================

INSERT INTO partida_arancelaria (
    id_partida,
    codigo,
    descripcion,
    porcentaje_arancel
) VALUES
(1, 'SIM-001', 'Computadoras portatiles', 5.00),
(2, 'SIM-002', 'Telefonos inteligentes', 5.00),
(3, 'SIM-003', 'Prendas de vestir de algodon', 15.00),
(4, 'SIM-004', 'Calzado deportivo', 15.00),
(5, 'SIM-005', 'Arroz para consumo humano', 10.00),
(6, 'SIM-006', 'Cafe tostado', 10.00),
(7, 'SIM-007', 'Refrigeradores domesticos', 12.00),
(8, 'SIM-008', 'Hornos de microondas', 12.00),
(9, 'SIM-009', 'Neumaticos para automoviles', 10.00),
(10, 'SIM-010', 'Herramientas manuales', 8.00),
(11, 'SIM-011', 'Papel para impresion', 6.00),
(12, 'SIM-012', 'Muebles de oficina', 12.00),
(13, 'SIM-013', 'Guantes de uso medico', 0.00),
(14, 'SIM-014', 'Fertilizantes agricolas', 3.00),
(15, 'SIM-015', 'Envases de carton', 6.00);

-- Verificar los datos.
SELECT * FROM partida_arancelaria ORDER BY id_partida;

SELECT COUNT(*) AS total_partidas
FROM partida_arancelaria;


-- =====================================================
-- DATOS: producto
-- Valores unitarios de prueba expresados en USD.
-- =====================================================

INSERT INTO producto (
    id_producto,
    descripcion,
    unidad_medida,
    valor_unitario,
    id_partida
) VALUES
(1, 'Computadora portatil de 15 pulgadas',
 'Unidad', 650.00, 1),
(2, 'Telefono inteligente de 128 GB',
 'Unidad', 280.00, 2),
(3, 'Camiseta de algodon',
 'Unidad', 8.00, 3),
(4, 'Calzado deportivo para adulto',
 'Par', 35.00, 4),
(5, 'Arroz blanco',
 'Kilogramo', 1.20, 5),
(6, 'Cafe tostado en grano',
 'Kilogramo', 9.50, 6),
(7, 'Refrigerador domestico de 300 litros',
 'Unidad', 420.00, 7),
(8, 'Horno de microondas de 25 litros',
 'Unidad', 85.00, 8),
(9, 'Neumatico para automovil aro 15',
 'Unidad', 55.00, 9),
(10, 'Juego de herramientas manuales',
 'Juego', 28.00, 10),
(11, 'Papel para impresion tamano carta',
 'Resma', 4.50, 11),
(12, 'Escritorio de oficina',
 'Unidad', 120.00, 12),
(13, 'Guantes de nitrilo de uso medico, caja de 100',
 'Caja', 6.00, 13),
(14, 'Fertilizante agricola granulado',
 'Kilogramo', 0.80, 14),
(15, 'Caja de carton corrugado',
 'Unidad', 0.65, 15);

-- Verificar los datos.
SELECT * FROM producto ORDER BY id_producto;

SELECT COUNT(*) AS total_productos FROM producto;








-- =====================================================
-- DATOS: bodega
-- Depósitos ficticios para pruebas.
-- Capacidad expresada en metros cúbicos.
-- =====================================================

INSERT INTO bodega (
    id_bodega,
    nombre,
    ubicacion,
    capacidad_m3
) VALUES
(1, 'Bodega 1 - Caldera',
 'Puntarenas, Esparza', 5000.00),
(2, 'Bodega 2 - Moin',
 'Limon, Moin', 6500.00),
(3, 'Bodega 3 - Central',
 'San Jose, canton central', 3200.00),
(4, 'Bodega 4 - Aeropuerto',
 'Alajuela, canton central', 2800.00),
(5, 'Bodega 5 - Penas Blancas',
 'Guanacaste, La Cruz', 4000.00),
(6, 'Bodega 6 - Paso Canoas',
 'Puntarenas, Corredores', 3800.00),
(7, 'Bodega 7 - Cartago',
 'Cartago, El Guarco', 2500.00),
(8, 'Bodega 8 - Heredia',
 'Heredia, Belen', 3000.00),
(9, 'Bodega 9 - Liberia',
 'Guanacaste, Liberia', 2700.00),
(10, 'Bodega 10 - San Carlos',
 'Alajuela, San Carlos', 3500.00),
(11, 'Bodega 11 - Grecia',
 'Alajuela, Grecia', 2200.00),
(12, 'Bodega 12 - Guapiles',
 'Limon, Pococi', 3100.00),
(13, 'Bodega 13 - Perez Zeledon',
 'San Jose, Perez Zeledon', 2400.00),
(14, 'Bodega 14 - Nicoya',
 'Guanacaste, Nicoya', 2000.00),
(15, 'Bodega 15 - Orotina',
 'Alajuela, Orotina', 4200.00);

-- Verificar los datos.
SELECT * FROM bodega ORDER BY id_bodega;

SELECT COUNT(*) AS total_bodegas FROM bodega;



-- =====================================================
-- DATOS: funcionario
-- Personal ficticio para pruebas.
-- Se insertan primero los supervisores.
-- =====================================================

-- Directora sin supervisor.
INSERT INTO funcionario (
    id_funcionario, nombre, cargo, id_supervisor
) VALUES
(1, 'Adriana Maria Molina', 'Directora de aduana', NULL);

-- Jefaturas supervisadas por la directora.
INSERT INTO funcionario (
    id_funcionario, nombre, cargo, id_supervisor
) VALUES
(2, 'Roberto Carlos Sanchez', 'Jefe de inspecciones', 1),
(3, 'Monica Isabel Navarro', 'Jefa de inventario', 1),
(4, 'Esteban Jose Ramirez', 'Jefe de operaciones', 1);

-- Inspectores y personal operativo.
INSERT INTO funcionario (
    id_funcionario, nombre, cargo, id_supervisor
) VALUES
(5, 'Sofia Elena Vargas', 'Inspectora aduanera', 2),
(6, 'Daniel Andres Mora', 'Inspector aduanero', 2),
(7, 'Paula Andrea Castro', 'Inspectora aduanera', 2),
(8, 'Jorge Luis Solano', 'Inspector aduanero', 2),
(9, 'Valentina Rojas Perez', 'Inspectora aduanera', 2),
(10, 'Gabriel Antonio Leon', 'Inspector aduanero', 2),
(11, 'Lucia Fernanda Campos', 'Encargada de inventario', 3),
(12, 'Miguel Angel Arias', 'Auxiliar de inventario', 3),
(13, 'Carolina Beatriz Vega', 'Encargada de bodega', 3),
(14, 'Ricardo Alberto Mendez', 'Coordinador de operaciones', 4),
(15, 'Natalia Cristina Herrera', 'Asistente de operaciones', 4);

-- Verificar los datos.
SELECT * FROM funcionario ORDER BY id_funcionario;

SELECT COUNT(*) AS total_funcionarios FROM funcionario;





-- =====================================================
-- DATOS: declaracion
-- Trámites ficticios de septiembre y octubre de 2026.
-- =====================================================

INSERT INTO declaracion (
    id_declaracion,
    numero,
    fecha,
    regimen,
    estado,
    id_importador,
    id_agente,
    id_pais_origen
) VALUES
(1, 'DUA-2026-0001', '2026-10-01',
 'Importacion', 'Retenida', 2, 1, 1),

(2, 'DUA-2026-0002', '2026-10-02',
 'Importacion', 'En revision', 2, 2, 10),

(3, 'DUA-2026-0003', '2026-10-03',
 'Importacion', 'Liberada', 4, 3, 3),

(4, 'DUA-2026-0004', '2026-10-04',
 'Importacion', 'Retenida', 13, 4, 1),

(5, 'DUA-2026-0005', '2026-10-05',
 'Importacion', 'Liberada', 3, 5, 2),

(6, 'DUA-2026-0006', '2026-10-06',
 'Exportacion', 'Liberada', 15, 6, 4),

(7, 'DUA-2026-0007', '2026-10-07',
 'Importacion', 'En revision', 10, 7, 10),

(8, 'DUA-2026-0008', '2026-10-08',
 'Deposito', 'Retenida', 10, 8, 1),

(9, 'DUA-2026-0009', '2026-10-09',
 'Importacion', 'Liberada', 5, 9, 9),

(10, 'DUA-2026-0010', '2026-10-10',
 'Transito', 'En revision', 7, 10, 8),

(11, 'DUA-2026-0011', '2026-10-11',
 'Importacion', 'Liberada', 11, 11, 13),

(12, 'DUA-2026-0012', '2026-10-12',
 'Importacion', 'Retenida', 6, 12, 12),

(13, 'DUA-2026-0013', '2026-10-13',
 'Importacion', 'Retenida', 8, 13, 1),

(14, 'DUA-2026-0014', '2026-09-25',
 'Importacion', 'Liberada', 9, 14, 7),

(15, 'DUA-2026-0015', '2026-09-28',
 'Deposito', 'Retenida', 14, 15, 6);

-- Verificar los datos.
SELECT * FROM declaracion ORDER BY id_declaracion;

SELECT COUNT(*) AS total_declaraciones FROM declaracion;

-- =====================================================
-- DATOS: detalle_declaracion
-- valor_declarado: total de cada línea en USD.
-- =====================================================

INSERT INTO detalle_declaracion (
    id_declaracion,
    id_producto,
    cantidad,
    valor_declarado
) VALUES
(1, 1, 100, 65000.00),
(1, 2, 200, 56000.00),

(2, 2, 150, 42000.00),

(3, 3, 1000, 8000.00),

(4, 4, 500, 17500.00),

(5, 5, 10000, 12000.00),

(6, 6, 2000, 19000.00),

(7, 7, 80, 33600.00),
(7, 8, 120, 10200.00),

(8, 8, 200, 17000.00),

(9, 9, 400, 22000.00),

(10, 10, 300, 8400.00),

(11, 11, 1500, 6750.00),

(12, 12, 100, 12000.00),

(13, 13, 2000, 12000.00),

(14, 14, 15000, 12000.00),

(15, 15, 5000, 3250.00),
(15, 11, 500, 2250.00);

-- Verificar los datos.
SELECT *
FROM detalle_declaracion
ORDER BY id_declaracion, id_producto;

SELECT COUNT(*) AS total_detalles
FROM detalle_declaracion;




-- =====================================================
-- DATOS: contenedor
-- Identificadores ficticios para pruebas.
-- Peso de la carga expresado en kilogramos.
-- =====================================================

INSERT INTO contenedor (
    id_contenedor,
    numero,
    tipo,
    peso_kg,
    id_declaracion
) VALUES
(1, 'CONT-PRUEBA-001', 'Seco 20 pies', 1800.000, 1),
(2, 'CONT-PRUEBA-002', 'Seco 20 pies', 1200.000, 1),
(3, 'CONT-PRUEBA-003', 'Seco 20 pies', 900.000, 2),
(4, 'CONT-PRUEBA-004', 'Seco 20 pies', 1500.000, 3),
(5, 'CONT-PRUEBA-005', 'Seco 20 pies', 2200.000, 4),
(6, 'CONT-PRUEBA-006', 'Seco 20 pies', 10000.000, 5),
(7, 'CONT-PRUEBA-007', 'Seco 20 pies', 2000.000, 6),
(8, 'CONT-PRUEBA-008', 'Seco 40 pies', 5000.000, 7),
(9, 'CONT-PRUEBA-009', 'Seco 40 pies', 3000.000, 7),
(10, 'CONT-PRUEBA-010', 'Seco 20 pies', 3200.000, 8),
(11, 'CONT-PRUEBA-011', 'Seco 40 pies', 4000.000, 9),
(12, 'CONT-PRUEBA-012', 'Seco 20 pies', 2400.000, 10),
(13, 'CONT-PRUEBA-013', 'Seco 20 pies', 7500.000, 11),
(14, 'CONT-PRUEBA-014', 'Seco 40 pies', 4500.000, 12),
(15, 'CONT-PRUEBA-015', 'Seco 20 pies', 1800.000, 13),
(16, 'CONT-PRUEBA-016', 'Seco 20 pies', 15000.000, 14),
(17, 'CONT-PRUEBA-017', 'Seco 40 pies', 2000.000, 15),
(18, 'CONT-PRUEBA-018', 'Seco 20 pies', 2500.000, 15);

-- Verificar los datos.
SELECT * FROM contenedor ORDER BY id_contenedor;

SELECT COUNT(*) AS total_contenedores FROM contenedor;




-- =====================================================
-- DATOS: inventario
-- Cantidades actuales por lote y bodega.
-- =====================================================

INSERT INTO inventario (
    id_inventario,
    id_bodega,
    id_declaracion,
    id_producto,
    cantidad,
    fecha_ingreso,
    estado
) VALUES
(1, 2, 1, 1, 80, '2026-10-01 08:00:00', 'Retenido'),
(2, 2, 1, 2, 200, '2026-10-01 08:30:00', 'Retenido'),

(3, 4, 2, 2, 150, '2026-10-02 09:00:00', 'En revision'),

(4, 3, 3, 3, 600, '2026-10-03 08:00:00', 'Liberado'),

(5, 2, 4, 4, 500, '2026-10-04 10:00:00', 'Retenido'),

(6, 5, 5, 5, 8000, '2026-10-05 08:00:00', 'Liberado'),

(7, 1, 6, 6, 0, '2026-10-06 07:00:00', 'Liberado'),

(8, 6, 7, 7, 80, '2026-10-07 09:00:00', 'En revision'),
(9, 6, 7, 8, 120, '2026-10-07 09:30:00', 'En revision'),

(10, 7, 8, 8, 200, '2026-10-08 08:00:00', 'Retenido'),

(11, 9, 9, 9, 400, '2026-10-09 10:00:00', 'Liberado'),

(12, 10, 10, 10, 300, '2026-10-10 08:00:00', 'En revision'),

(13, 11, 11, 11, 1500, '2026-10-11 09:00:00', 'Liberado'),

(14, 12, 12, 12, 100, '2026-10-12 08:00:00', 'Retenido'),

(15, 13, 13, 13, 2000, '2026-10-13 09:00:00', 'Retenido'),

(16, 14, 14, 14, 15000, '2026-09-25 08:00:00', 'Liberado'),

(17, 15, 15, 15, 5000, '2026-09-28 09:00:00', 'Retenido'),
(18, 15, 15, 11, 500, '2026-09-28 09:30:00', 'Retenido'),

-- Lotes receptores de traslados.
(19, 1, 1, 1, 20, '2026-10-02 14:00:00', 'Retenido'),
(20, 8, 3, 3, 200, '2026-10-04 14:00:00', 'Liberado');

-- Verificar los datos.
SELECT * FROM inventario ORDER BY id_inventario;

SELECT COUNT(*) AS total_lotes FROM inventario;





-- =====================================================
-- DATOS: movimiento
-- Historial que explica los saldos actuales de inventario.
-- Las cantidades de inventario ya están registradas:
-- estos INSERT no deben volver a sumarlas ni restarlas.
-- =====================================================

INSERT INTO movimiento (
    id_movimiento,
    tipo,
    fecha,
    cantidad,
    id_inventario,
    id_inventario_destino,
    observaciones
) VALUES
-- Entradas iniciales.
(1, 'Entrada', '2026-10-01 08:00:00', 100, 1, NULL,
 'Ingreso de computadoras de la declaracion 1'),

(2, 'Entrada', '2026-10-01 08:30:00', 200, 2, NULL,
 'Ingreso de telefonos de la declaracion 1'),

(3, 'Entrada', '2026-10-02 09:00:00', 150, 3, NULL,
 'Ingreso de telefonos de la declaracion 2'),

(4, 'Entrada', '2026-10-03 08:00:00', 1000, 4, NULL,
 'Ingreso de camisetas'),

(5, 'Entrada', '2026-10-04 10:00:00', 500, 5, NULL,
 'Ingreso de pares de calzado'),

(6, 'Entrada', '2026-10-05 08:00:00', 10000, 6, NULL,
 'Ingreso de arroz en kilogramos'),

(7, 'Entrada', '2026-10-06 07:00:00', 2000, 7, NULL,
 'Ingreso de cafe para exportacion'),

(8, 'Entrada', '2026-10-07 09:00:00', 80, 8, NULL,
 'Ingreso de refrigeradores'),

(9, 'Entrada', '2026-10-07 09:30:00', 120, 9, NULL,
 'Ingreso de microondas de la declaracion 7'),

(10, 'Entrada', '2026-10-08 08:00:00', 200, 10, NULL,
 'Ingreso de microondas de la declaracion 8'),

(11, 'Entrada', '2026-10-09 10:00:00', 400, 11, NULL,
 'Ingreso de neumaticos'),

(12, 'Entrada', '2026-10-10 08:00:00', 300, 12, NULL,
 'Ingreso de juegos de herramientas'),

(13, 'Entrada', '2026-10-11 09:00:00', 1500, 13, NULL,
 'Ingreso de resmas de papel'),

(14, 'Entrada', '2026-10-12 08:00:00', 100, 14, NULL,
 'Ingreso de escritorios'),

(15, 'Entrada', '2026-10-13 09:00:00', 2000, 15, NULL,
 'Ingreso de cajas de guantes'),

(16, 'Entrada', '2026-09-25 08:00:00', 15000, 16, NULL,
 'Ingreso de fertilizante en kilogramos'),

(17, 'Entrada', '2026-09-28 09:00:00', 5000, 17, NULL,
 'Ingreso de envases de carton'),

(18, 'Entrada', '2026-09-28 09:30:00', 500, 18, NULL,
 'Ingreso de resmas de papel de la declaracion 15'),

-- Traslados: descuentan del lote principal y
-- suman al lote destino al calcular el saldo.
(19, 'Traslado', '2026-10-02 14:00:00', 20, 1, 19,
 'Traslado de computadoras de bodega 2 a bodega 1'),

(20, 'Traslado', '2026-10-04 14:00:00', 200, 4, 20,
 'Traslado de camisetas de bodega 3 a bodega 8'),

-- Salidas de mercancia liberada.
(21, 'Salida', '2026-10-05 16:00:00', 200, 4, NULL,
 'Entrega parcial de camisetas al importador'),

(22, 'Salida', '2026-10-07 15:00:00', 2000, 6, NULL,
 'Entrega parcial de arroz al importador'),

(23, 'Salida', '2026-10-08 16:00:00', 2000, 7, NULL,
 'Salida total de cafe para exportacion');

-- Verificar los datos.
SELECT * FROM movimiento ORDER BY fecha, id_movimiento;

SELECT COUNT(*) AS total_movimientos FROM movimiento;


-- =====================================================
-- DATOS: inspeccion
-- Revisiones ficticias realizadas por los inspectores.
-- =====================================================

INSERT INTO inspeccion (
    id_inspeccion,
    fecha,
    resultado,
    observaciones,
    id_declaracion,
    id_funcionario
) VALUES
(1, '2026-10-01 11:00:00', 'Con observaciones',
 'Pendiente verificar documentos de valor de las computadoras.',
 1, 5),

(2, '2026-10-02 11:00:00', 'Con observaciones',
 'Revision de numeros de serie de los telefonos en proceso.',
 2, 6),

(3, '2026-10-03 14:00:00', 'Sin observaciones',
 'Cantidad y descripcion de las camisetas verificadas.',
 3, 7),

(4, '2026-10-04 13:00:00', 'Con observaciones',
 'Pendiente completar la documentacion del calzado.',
 4, 8),

(5, '2026-10-05 12:00:00', 'Sin observaciones',
 'Documentacion y carga de arroz verificadas.',
 5, 9),

(6, '2026-10-06 11:00:00', 'Sin observaciones',
 'Carga de cafe revisada para su exportacion.',
 6, 10),

(7, '2026-10-07 13:00:00', 'Con observaciones',
 'Verificacion tecnica de refrigeradores y microondas en proceso.',
 7, 5),

(8, '2026-10-08 12:00:00', 'Con observaciones',
 'Pendiente presentar documentacion complementaria del deposito.',
 8, 6),

(9, '2026-10-09 14:00:00', 'Sin observaciones',
 'Neumaticos y documentos coinciden con lo declarado.',
 9, 7),

(10, '2026-10-10 11:00:00', 'Con observaciones',
 'Verificacion de documentos de transito en proceso.',
 10, 8),

(11, '2026-10-11 13:00:00', 'Sin observaciones',
 'Cantidad de resmas de papel verificada.',
 11, 9),

(12, '2026-10-12 12:00:00', 'Con observaciones',
 'Pendiente aclarar la descripcion de los escritorios.',
 12, 10),

(13, '2026-10-13 14:00:00', 'No conforme',
 'Diferencias en el etiquetado de los guantes; carga retenida.',
 13, 5),

(14, '2026-09-25 13:00:00', 'Sin observaciones',
 'Documentacion y carga de fertilizante verificadas.',
 14, 6),

(15, '2026-09-28 14:00:00', 'Con observaciones',
 'Pendiente completar documentos de la mercancia en deposito.',
 15, 7);

-- Verificar los datos.
SELECT * FROM inspeccion ORDER BY id_inspeccion;

SELECT COUNT(*) AS total_inspecciones FROM inspeccion;



-- =====================================================
-- VERIFICACION: cantidad de registros por tabla
-- =====================================================

SELECT 'pais' AS tabla, COUNT(*) AS registros FROM pais
UNION ALL
SELECT 'importador', COUNT(*) FROM importador
UNION ALL
SELECT 'agente_aduanal', COUNT(*) FROM agente_aduanal
UNION ALL
SELECT 'partida_arancelaria', COUNT(*) FROM partida_arancelaria
UNION ALL
SELECT 'producto', COUNT(*) FROM producto
UNION ALL
SELECT 'bodega', COUNT(*) FROM bodega
UNION ALL
SELECT 'funcionario', COUNT(*) FROM funcionario
UNION ALL
SELECT 'declaracion', COUNT(*) FROM declaracion
UNION ALL
SELECT 'detalle_declaracion', COUNT(*) FROM detalle_declaracion
UNION ALL
SELECT 'contenedor', COUNT(*) FROM contenedor
UNION ALL
SELECT 'inventario', COUNT(*) FROM inventario
UNION ALL
SELECT 'movimiento', COUNT(*) FROM movimiento
UNION ALL
SELECT 'inspeccion', COUNT(*) FROM inspeccion
ORDER BY tabla;










-- =====================================================
-- VERIFICACION: conciliar inventario y movimientos
-- =====================================================

SELECT
    i.id_inventario,
    p.descripcion AS producto,
    b.nombre AS bodega,
    i.cantidad AS stock_guardado,
    COALESCE(s.saldo, 0) AS stock_calculado,
    i.cantidad - COALESCE(s.saldo, 0) AS diferencia
FROM inventario AS i
JOIN producto AS p
    ON p.id_producto = i.id_producto
JOIN bodega AS b
    ON b.id_bodega = i.id_bodega
LEFT JOIN (
    SELECT
        eventos.id_inventario,
        SUM(eventos.cambio) AS saldo
    FROM (
        -- Entradas suman; salidas y traslados de origen restan.
        SELECT
            id_inventario,
            CASE
                WHEN tipo = 'Entrada' THEN cantidad
                ELSE -cantidad
            END AS cambio
        FROM movimiento

        UNION ALL

        -- Los traslados suman al lote de destino.
        SELECT
            id_inventario_destino AS id_inventario,
            cantidad AS cambio
        FROM movimiento
        WHERE tipo = 'Traslado'
    ) AS eventos
    GROUP BY eventos.id_inventario
) AS s
    ON s.id_inventario = i.id_inventario
ORDER BY i.id_inventario;







-- =====================================================
-- VERIFICACION: coherencia de los traslados
-- Solo muestra traslados con errores.
-- =====================================================

SELECT
    m.id_movimiento,
    m.fecha,
    origen.id_inventario AS lote_origen,
    destino.id_inventario AS lote_destino
FROM movimiento AS m
JOIN inventario AS origen
    ON origen.id_inventario = m.id_inventario
JOIN inventario AS destino
    ON destino.id_inventario = m.id_inventario_destino
JOIN declaracion AS d
    ON d.id_declaracion = origen.id_declaracion
WHERE m.tipo = 'Traslado'
  AND (
      origen.id_producto <> destino.id_producto
      OR origen.id_declaracion <> destino.id_declaracion
      OR origen.id_bodega = destino.id_bodega
      OR m.fecha < origen.fecha_ingreso
      OR m.fecha < destino.fecha_ingreso
      OR DATE(m.fecha) < d.fecha
  );
  
  
  
  
  -- =====================================================
-- CONSULTA 1: importaciones de octubre por país de origen
-- =====================================================

SELECT
    p.nombre AS pais_origen,
    COUNT(*) AS total_declaraciones
FROM declaracion AS d
JOIN pais AS p
    ON p.id_pais = d.id_pais_origen
WHERE d.regimen = 'Importacion'
  AND d.fecha >= '2026-10-01'
  AND d.fecha < '2026-11-01'
GROUP BY p.id_pais, p.nombre
ORDER BY total_declaraciones DESC, p.nombre ASC;





-- =====================================================
-- CONSULTA 2: mercancías retenidas con stock disponible
-- =====================================================

SELECT
    i.id_inventario AS lote,
    p.descripcion AS producto,
    i.cantidad AS stock_actual,
    p.unidad_medida,
    b.nombre AS bodega,
    d.numero AS declaracion,
    pais.nombre AS pais_origen,
    imp.razon_social AS importador
FROM inventario AS i
JOIN producto AS p
    ON p.id_producto = i.id_producto
JOIN bodega AS b
    ON b.id_bodega = i.id_bodega
JOIN detalle_declaracion AS dd
    ON dd.id_declaracion = i.id_declaracion
   AND dd.id_producto = i.id_producto
JOIN declaracion AS d
    ON d.id_declaracion = dd.id_declaracion
JOIN pais
    ON pais.id_pais = d.id_pais_origen
JOIN importador AS imp
    ON imp.id_importador = d.id_importador
WHERE i.estado = 'Retenido'
  AND i.cantidad > 0
ORDER BY b.nombre, p.descripcion, i.id_inventario;





-- =====================================================
-- CONSULTA 3: contenedores recibidos por país de origen
-- Se excluyen las exportaciones.
-- =====================================================

SELECT
    p.nombre AS pais_origen,
    COUNT(c.id_contenedor) AS total_contenedores
FROM contenedor AS c
JOIN declaracion AS d
    ON d.id_declaracion = c.id_declaracion
JOIN pais AS p
    ON p.id_pais = d.id_pais_origen
WHERE d.regimen IN ('Importacion', 'Transito', 'Deposito')
GROUP BY p.id_pais, p.nombre
ORDER BY total_contenedores DESC, p.nombre ASC;




-- =====================================================
-- CONSULTA 4: valor total importado por empresa, en USD
-- =====================================================

SELECT
    imp.razon_social AS importador,
    COUNT(DISTINCT d.id_declaracion) AS total_declaraciones,
    SUM(dd.valor_declarado) AS valor_total_usd
FROM importador AS imp
JOIN declaracion AS d
    ON d.id_importador = imp.id_importador
JOIN detalle_declaracion AS dd
    ON dd.id_declaracion = d.id_declaracion
WHERE d.regimen = 'Importacion'
GROUP BY imp.id_importador, imp.razon_social
ORDER BY valor_total_usd DESC, imp.razon_social ASC;




-- =====================================================
-- CONSULTA 5: inspecciones con observaciones
-- =====================================================

SELECT
    ins.id_inspeccion,
    ins.fecha,
    d.numero AS declaracion,
    imp.razon_social AS importador,
    f.nombre AS funcionario,
    ins.resultado,
    ins.observaciones
FROM inspeccion AS ins
JOIN declaracion AS d
    ON d.id_declaracion = ins.id_declaracion
JOIN importador AS imp
    ON imp.id_importador = d.id_importador
JOIN funcionario AS f
    ON f.id_funcionario = ins.id_funcionario
WHERE ins.resultado = 'Con observaciones'
ORDER BY ins.fecha DESC, ins.id_inspeccion DESC;




-- =====================================================
-- CONSULTA 6: stock de computadoras por bodega
-- =====================================================

SELECT
    p.descripcion AS producto,
    b.nombre AS bodega,
    p.unidad_medida,
    SUM(i.cantidad) AS stock_actual
FROM inventario AS i
JOIN producto AS p
    ON p.id_producto = i.id_producto
JOIN bodega AS b
    ON b.id_bodega = i.id_bodega
WHERE p.id_producto = 1
GROUP BY
    p.id_producto,
    p.descripcion,
    b.id_bodega,
    b.nombre,
    p.unidad_medida
HAVING SUM(i.cantidad) > 0
ORDER BY stock_actual DESC, b.nombre ASC;


-- =====================================================
-- CONSULTA 7: valor declarado por país de origen, en USD
-- Incluye todos los regímenes aduaneros.
-- =====================================================

SELECT
    p.nombre AS pais_origen,
    COUNT(DISTINCT d.id_declaracion) AS total_declaraciones,
    SUM(dd.valor_declarado) AS valor_total_usd
FROM pais AS p
JOIN declaracion AS d
    ON d.id_pais_origen = p.id_pais
JOIN detalle_declaracion AS dd
    ON dd.id_declaracion = d.id_declaracion
GROUP BY p.id_pais, p.nombre
ORDER BY valor_total_usd DESC, p.nombre ASC;




-- =====================================================
-- CONSULTA 8: inspecciones por funcionario y supervisor
-- =====================================================

SELECT
    f.nombre AS inspector,
    supervisor.nombre AS supervisor,
    COUNT(ins.id_inspeccion) AS total_inspecciones
FROM funcionario AS f
JOIN funcionario AS supervisor
    ON supervisor.id_funcionario = f.id_supervisor
JOIN inspeccion AS ins
    ON ins.id_funcionario = f.id_funcionario
WHERE f.cargo IN ('Inspector aduanero', 'Inspectora aduanera')
GROUP BY
    f.id_funcionario,
    f.nombre,
    supervisor.id_funcionario,
    supervisor.nombre
ORDER BY total_inspecciones DESC, f.nombre ASC;