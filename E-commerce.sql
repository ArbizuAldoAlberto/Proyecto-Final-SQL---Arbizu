-- Creación de la base de datos
CREATE DATABASE IF NOT EXISTS GestionInventariosEcommerce;
USE GestionInventariosEcommerce;

-- Creación de tablas

-- Tabla Categoria
CREATE TABLE IF NOT EXISTS Categoria (
    ID_Categoria INT PRIMARY KEY,
    Nombre_Categoria VARCHAR(100),
    Descripcion TEXT
);

-- Tabla Proveedor
CREATE TABLE IF NOT EXISTS Proveedor (
    ID_Proveedor INT PRIMARY KEY,
    Nombre_Proveedor VARCHAR(100),
    Contacto VARCHAR(100),
    Email VARCHAR(100),
    Telefono VARCHAR(20)
);

-- Tabla Producto
CREATE TABLE IF NOT EXISTS Producto (
    ID_Producto INT PRIMARY KEY,
    Nombre_Producto VARCHAR(100),
    Descripcion TEXT,
    Precio DECIMAL(10,2),
    Stock INT,
    ID_Categoria INT,
    ID_Proveedor INT,
    FOREIGN KEY (ID_Categoria) REFERENCES Categoria(ID_Categoria),
    FOREIGN KEY (ID_Proveedor) REFERENCES Proveedor(ID_Proveedor)
);

-- Tabla Cliente
CREATE TABLE IF NOT EXISTS Cliente (
    ID_Cliente INT PRIMARY KEY,
    Nombre_Cliente VARCHAR(100),
    Correo_Electronico VARCHAR(100),
    Direccion VARCHAR(200),
    Telefono VARCHAR(20),
    Fecha_Registro DATE
);

-- Tabla Pedido
CREATE TABLE IF NOT EXISTS Pedido (
    ID_Pedido INT PRIMARY KEY,
    Fecha_Pedido DATE,
    ID_Cliente INT,
    Estado_Pedido ENUM('Pendiente', 'En proceso', 'Enviado', 'Entregado', 'Cancelado'),
    FOREIGN KEY (ID_Cliente) REFERENCES Cliente(ID_Cliente)
);

-- Tabla Detalle_Pedido
CREATE TABLE IF NOT EXISTS Detalle_Pedido (
    ID_Detalle INT PRIMARY KEY,
    ID_Pedido INT,
    ID_Producto INT,
    Cantidad INT,
    Precio_Unitario DECIMAL(10,2),
    FOREIGN KEY (ID_Pedido) REFERENCES Pedido(ID_Pedido),
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID_Producto)
);

-- Tabla Inventario
CREATE TABLE IF NOT EXISTS Inventario (
    ID_Inventario INT PRIMARY KEY,
    ID_Producto INT,
    Cantidad_Actual INT,
    Ubicacion VARCHAR(100),
    Ultima_Actualizacion DATE,
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID_Producto)
);

-- Tabla Empleado
CREATE TABLE IF NOT EXISTS Empleado (
    ID_Empleado INT PRIMARY KEY,
    Nombre_Empleado VARCHAR(100),
    Cargo VARCHAR(50),
    Email VARCHAR(100),
    Telefono VARCHAR(20),
    Fecha_Contratacion DATE
);

-- Tabla Envio
CREATE TABLE IF NOT EXISTS Envio (
    ID_Envio INT PRIMARY KEY,
    ID_Pedido INT,
    Fecha_Envio DATE,
    Metodo_Envio VARCHAR(50),
    Numero_Seguimiento VARCHAR(50),
    FOREIGN KEY (ID_Pedido) REFERENCES Pedido(ID_Pedido)
);

-- Tabla Metodo_Pago
CREATE TABLE IF NOT EXISTS Metodo_Pago (
    ID_Metodo_Pago INT PRIMARY KEY,
    Nombre_Metodo VARCHAR(50),
    Descripcion TEXT
);

-- Tabla Valoracion
CREATE TABLE IF NOT EXISTS Valoracion (
    ID_Valoracion INT PRIMARY KEY,
    ID_Producto INT,
    ID_Cliente INT,
    Puntuacion INT,
    Comentario TEXT,
    Fecha_Valoracion DATE,
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID_Producto),
    FOREIGN KEY (ID_Cliente) REFERENCES Cliente(ID_Cliente)
);

-- Tabla Descuento
CREATE TABLE IF NOT EXISTS Descuento (
    ID_Descuento INT PRIMARY KEY,
    Codigo_Descuento VARCHAR(20),
    Porcentaje DECIMAL(5,2),
    Fecha_Inicio DATE,
    Fecha_Fin DATE
);

-- Tabla Carrito_Compra
CREATE TABLE IF NOT EXISTS Carrito_Compra (
    ID_Carrito INT PRIMARY KEY,
    ID_Cliente INT,
    Fecha_Creacion DATE,
    FOREIGN KEY (ID_Cliente) REFERENCES Cliente(ID_Cliente)
);

-- Tabla Log_Transacciones (tabla de hechos)
CREATE TABLE IF NOT EXISTS Log_Transacciones (
    ID_Log INT PRIMARY KEY,
    Tipo_Transaccion VARCHAR(50),
    Fecha_Transaccion DATETIME,
    ID_Usuario INT,
    Detalles TEXT
);

-- Tabla Ventas_Diarias (tabla transaccional)
CREATE TABLE IF NOT EXISTS Ventas_Diarias (
    Fecha DATE PRIMARY KEY,
    Total_Ventas DECIMAL(10,2),
    Cantidad_Pedidos INT,
    Promedio_Venta DECIMAL(10,2)
);

-- Creación de vistas

-- Vista de productos disponibles
CREATE OR REPLACE VIEW vw_productos_disponibles AS
SELECT p.ID_Producto, p.Nombre_Producto, p.Precio, p.Stock, c.Nombre_Categoria
FROM Producto p
JOIN Categoria c ON p.ID_Categoria = c.ID_Categoria
WHERE p.Stock > 0;

-- Vista de resumen de pedidos
CREATE OR REPLACE VIEW vw_resumen_pedidos AS
SELECT p.ID_Pedido, p.Fecha_Pedido, c.Nombre_Cliente, 
       SUM(dp.Cantidad * dp.Precio_Unitario) AS Total_Pedido
FROM Pedido p
JOIN Cliente c ON p.ID_Cliente = c.ID_Cliente
JOIN Detalle_Pedido dp ON p.ID_Pedido = dp.ID_Pedido
GROUP BY p.ID_Pedido, p.Fecha_Pedido, c.Nombre_Cliente;

-- Vista de productos por proveedor
CREATE OR REPLACE VIEW vw_productos_por_proveedor AS
SELECT pr.ID_Proveedor, pr.Nombre_Proveedor, p.ID_Producto, p.Nombre_Producto, p.Stock
FROM Proveedor pr
JOIN Producto p ON pr.ID_Proveedor = p.ID_Proveedor;

-- Vista de mejores clientes
CREATE OR REPLACE VIEW vw_mejores_clientes AS
SELECT c.ID_Cliente, c.Nombre_Cliente, COUNT(p.ID_Pedido) AS Total_Pedidos,
       SUM(dp.Cantidad * dp.Precio_Unitario) AS Total_Gastado
FROM Cliente c
JOIN Pedido p ON c.ID_Cliente = p.ID_Cliente
JOIN Detalle_Pedido dp ON p.ID_Pedido = dp.ID_Pedido
GROUP BY c.ID_Cliente, c.Nombre_Cliente
ORDER BY Total_Gastado DESC
LIMIT 10;

-- Vista de productos más vendidos
CREATE OR REPLACE VIEW vw_productos_mas_vendidos AS
SELECT p.ID_Producto, p.Nombre_Producto, SUM(dp.Cantidad) AS Total_Vendido,
       SUM(dp.Cantidad * dp.Precio_Unitario) AS Total_Ingresos
FROM Producto p
JOIN Detalle_Pedido dp ON p.ID_Producto = dp.ID_Producto
GROUP BY p.ID_Producto, p.Nombre_Producto
ORDER BY Total_Vendido DESC
LIMIT 10;

-- Creación de funciones

DELIMITER //

-- Función para calcular el total de un pedido
CREATE FUNCTION fn_calcular_total_pedido(pedido_id INT) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT SUM(Cantidad * Precio_Unitario) INTO total
    FROM Detalle_Pedido
    WHERE ID_Pedido = pedido_id;
    RETURN COALESCE(total, 0);
END //

-- Función para obtener el stock de un producto
CREATE FUNCTION fn_obtener_stock_producto(producto_id INT) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE stock_actual INT;
    SELECT Stock INTO stock_actual
    FROM Producto
    WHERE ID_Producto = producto_id;
    RETURN COALESCE(stock_actual, 0);
END //

DELIMITER ;

-- Creación de procedimientos almacenados

DELIMITER //

-- Procedimiento para actualizar el stock de un producto
CREATE PROCEDURE sp_actualizar_stock(IN producto_id INT, IN cantidad INT)
BEGIN
    UPDATE Producto
    SET Stock = Stock - cantidad
    WHERE ID_Producto = producto_id;
END //

-- Procedimiento para crear un nuevo pedido
CREATE PROCEDURE sp_crear_pedido(
    IN cliente_id INT,
    IN producto_id INT,
    IN cantidad INT,
    OUT nuevo_pedido_id INT
)
BEGIN
    DECLARE precio_producto DECIMAL(10,2);
    
    START TRANSACTION;
    
    -- Crear nuevo pedido
    INSERT INTO Pedido (Fecha_Pedido, ID_Cliente, Estado_Pedido) 
    VALUES (CURDATE(), cliente_id, 'Pendiente');
    SET nuevo_pedido_id = LAST_INSERT_ID();
    
    -- Obtener precio del producto
    SELECT Precio INTO precio_producto FROM Producto WHERE ID_Producto = producto_id;
    
    -- Agregar detalle del pedido
    INSERT INTO Detalle_Pedido (ID_Pedido, ID_Producto, Cantidad, Precio_Unitario)
    VALUES (nuevo_pedido_id, producto_id, cantidad, precio_producto);
    
    -- Actualizar stock
    CALL sp_actualizar_stock(producto_id, cantidad);
    
    COMMIT;
END //

DELIMITER ;

-- Creación de triggers

DELIMITER //

-- Trigger para actualizar el stock después de un pedido
CREATE TRIGGER tr_actualizar_stock_despues_pedido
AFTER INSERT ON Detalle_Pedido
FOR EACH ROW
BEGIN
    UPDATE Producto
    SET Stock = Stock - NEW.Cantidad
    WHERE ID_Producto = NEW.ID_Producto;
END //

-- Trigger para verificar el stock antes de un pedido
CREATE TRIGGER tr_verificar_stock_antes_pedido
BEFORE INSERT ON Detalle_Pedido
FOR EACH ROW
BEGIN
    DECLARE stock_disponible INT;
    SELECT Stock INTO stock_disponible
    FROM Producto
    WHERE ID_Producto = NEW.ID_Producto;
    
    IF stock_disponible < NEW.Cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente para completar el pedido';
    END IF;
END //

DELIMITER ;

-- Inserción de datos de ejemplo

-- Insertar categorías
INSERT INTO Categoria (ID_Categoria, Nombre_Categoria, Descripcion) VALUES
(1, 'Electrónica', 'Productos electrónicos y gadgets'),
(2, 'Ropa', 'Prendas de vestir y accesorios'),
(3, 'Hogar', 'Artículos para el hogar');

-- Insertar proveedores
INSERT INTO Proveedor (ID_Proveedor, Nombre_Proveedor, Contacto, Email, Telefono) VALUES
(1, 'TechSupply', 'Juan Pérez', 'juan@techsupply.com', '123-456-7890'),
(2, 'FashionWholesale', 'María García', 'maria@fashionwholesale.com', '987-654-3210'),
(3, 'HomeGoods', 'Carlos López', 'carlos@homegoods.com', '456-789-0123');

-- Insertar productos
INSERT INTO Producto (ID_Producto, Nombre_Producto, Descripcion, Precio, Stock, ID_Categoria, ID_Proveedor) VALUES
(1, 'Smartphone X', 'Último modelo de smartphone', 799.99, 50, 1, 1),
(2, 'Camiseta Básica', 'Camiseta de algodón', 19.99, 100, 2, 2),
(3, 'Lámpara LED', 'Lámpara de escritorio LED', 39.99, 30, 3, 3);

-- Insertar clientes
INSERT INTO Cliente (ID_Cliente, Nombre_Cliente, Correo_Electronico, Direccion, Telefono, Fecha_Registro) VALUES
(1, 'Ana Martínez', 'ana@email.com', 'Calle Principal 123', '555-1234', '2024-01-01'),
(2, 'Pedro Sánchez', 'pedro@email.com', 'Avenida Central 456', '555-5678', '2024-01-15');

-- Insertar pedidos
INSERT INTO Pedido (ID_Pedido, Fecha_Pedido, ID_Cliente, Estado_Pedido) VALUES
(1, '2024-02-01', 1, 'Entregado'),
(2, '2024-02-15', 2, 'En proceso');

-- Insertar detalles de pedido
INSERT INTO Detalle_Pedido (ID_Detalle, ID_Pedido, ID_Producto, Cantidad, Precio_Unitario) VALUES
(1, 1, 1, 1, 799.99),
(2, 1, 2, 2, 19.99),
(3, 2, 3, 1, 39.99);

-- Insertar datos en otras tablas...

-- Ejemplos de consultas para generar informes

-- Ventas totales por categoría de producto
SELECT c.Nombre_Categoria, SUM(dp.Cantidad * dp.Precio_Unitario) AS Total_Ventas
FROM Categoria c
JOIN Producto p ON c.ID_Categoria = p.ID_Categoria
JOIN Detalle_Pedido dp ON p.ID_Producto = dp.ID_Producto
GROUP BY c.Nombre_Categoria
ORDER BY Total_Ventas DESC;

-- Productos más vendidos
SELECT p.Nombre_Producto, SUM(dp.Cantidad) AS Cantidad_Vendida
FROM Producto p
JOIN Detalle_Pedido dp ON p.ID_Producto = dp.ID_Producto
GROUP BY p.Nombre_Producto
ORDER BY Cantidad_Vendida DESC
LIMIT 5;

-- Clientes con mayor volumen de compras
SELECT c.Nombre_Cliente, COUNT(p.ID_Pedido) AS Numero_Pedidos, 
       SUM(dp.Cantidad * dp.Precio_Unitario) AS Total_Compras
FROM Cliente c
JOIN Pedido p ON c.ID_Cliente = p.ID_Cliente
JOIN Detalle_Pedido dp ON p.ID_Pedido = dp.ID_Pedido
GROUP BY c.ID_Cliente, c.Nombre_Cliente
ORDER BY Total_Compras DESC
LIMIT 10;

-- Análisis de tendencias de ventas a lo largo del tiempo
SELECT DATE_FORMAT(p.Fecha_Pedido, '%Y-%m') AS Mes, 
       SUM(dp.Cantidad * dp.Precio_Unitario) AS Total_Ventas
FROM Pedido p
JOIN Detalle_Pedido dp ON p.ID_Pedido = dp.ID_Pedido
GROUP BY Mes
ORDER BY Mes;

-- Rendimiento de proveedores
SELECT pr.Nombre_Proveedor, COUNT(DISTINCT p.ID_Pedido) AS Numero_Pedidos,
       SUM(dp.Cantidad) AS Total_Productos_Vendidos,
       SUM(dp.Cantidad * dp.Precio_Unitario) AS Total_Ventas
FROM Proveedor pr
JOIN Producto prod ON pr.ID_Proveedor = prod.ID_Proveedor
JOIN Detalle_Pedido dp ON prod.ID_Producto = dp.ID_Producto
JOIN Pedido p ON dp.ID_Pedido = p.ID_Pedido
GROUP BY pr.ID_Proveedor, pr.Nombre_Proveedor
ORDER BY Total_Ventas DESC;

-- Eficiencia de envíos
SELECT e.Metodo_Envio,
       AVG(DATEDIFF(e.Fecha_Envio, p.Fecha_Pedido)) AS Promedio_Dias_Envio,
       COUNT(*) AS Total_Envios
FROM Envio e
JOIN Pedido p ON e.ID_Pedido = p.ID_Pedido
GROUP BY e.Metodo_Envio
ORDER BY Promedio_Dias_Envio;

-- Análisis de valoraciones de productos
SELECT p.Nombre_Producto, 
       AVG(v.Puntuacion) AS Puntuacion_Promedio,
       COUNT(v.ID_Valoracion) AS Numero_Valoraciones
FROM Producto p
LEFT JOIN Valoracion v ON p.ID_Producto = v.ID_Producto
GROUP BY p.ID_Producto, p.Nombre_Producto
HAVING Numero_Valoraciones > 0
ORDER BY Puntuacion_Promedio DESC;

-- Efectividad de descuentos
SELECT d.Codigo_Descuento,
       COUNT(DISTINCT p.ID_Pedido) AS Pedidos_Con_Descuento,
       SUM(dp.Cantidad * dp.Precio_Unitario * (1 - d.Porcentaje/100)) AS Total_Ventas_Con_Descuento
FROM Descuento d
JOIN Pedido p ON p.Fecha_Pedido BETWEEN d.Fecha_Inicio AND d.Fecha_Fin
JOIN Detalle_Pedido dp ON p.ID_Pedido = dp.ID_Pedido
GROUP BY d.ID_Descuento, d.Codigo_Descuento
ORDER BY Total_Ventas_Con_Descuento DESC;

-- Análisis de carrito de compras abandonados
SELECT COUNT(*) AS Carritos_Abandonados,
       AVG(DATEDIFF(CURDATE(), cc.Fecha_Creacion)) AS Promedio_Dias_Abandono
FROM Carrito_Compra cc
LEFT JOIN Pedido p ON cc.ID_Cliente = p.ID_Cliente AND cc.Fecha_Creacion = p.Fecha_Pedido
WHERE p.ID_Pedido IS NULL;

-- Rendimiento de empleados en ventas
SELECT e.Nombre_Empleado, e.Cargo,
       COUNT(DISTINCT p.ID_Pedido) AS Pedidos_Procesados,
       SUM(dp.Cantidad * dp.Precio_Unitario) AS Total_Ventas
FROM Empleado e
JOIN Pedido p ON e.ID_Empleado = p.ID_Cliente  -- Asumiendo que el empleado está asociado al pedido
JOIN Detalle_Pedido dp ON p.ID_Pedido = dp.ID_Pedido
GROUP BY e.ID_Empleado, e.Nombre_Empleado, e.Cargo
ORDER BY Total_Ventas DESC;

-- Análisis de métodos de pago preferidos
SELECT mp.Nombre_Metodo,
       COUNT(DISTINCT p.ID_Pedido) AS Numero_Pedidos,
       SUM(dp.Cantidad * dp.Precio_Unitario) AS Total_Ventas
FROM Metodo_Pago mp
JOIN Pedido p ON mp.ID_Metodo_Pago = p.ID_Pedido  -- Asumiendo que el método de pago está asociado al pedido
JOIN Detalle_Pedido dp ON p.ID_Pedido = dp.ID_Pedido
GROUP BY mp.ID_Metodo_Pago, mp.Nombre_Metodo
ORDER BY Total_Ventas DESC;