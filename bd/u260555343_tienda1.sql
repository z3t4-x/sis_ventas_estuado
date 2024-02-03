-- phpMyAdmin SQL Dump
-- version 4.8.5
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 03-02-2024 a las 21:15:14
-- Versión del servidor: 10.1.38-MariaDB
-- Versión de PHP: 7.3.2

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `u260555343_tienda1`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_2021_entradas` (IN `p_mes` VARCHAR(7))  BEGIN
   SET time_zone = '-05:00';
    IF (p_mes!='') THEN
 
    	 SELECT entrada.identrada,entrada.fecha_entrada, entrada.descripcion_entrada, producto.nombre_producto, producto.codigo_barra,entrada.cantidad_entrada,entrada.costo_total_entrada FROM entrada INNER JOIN producto ON entrada.idproducto = producto.idproducto WHERE DATE_FORMAT(entrada.fecha_entrada,'%Y-%m') = p_mes ORDER by entrada.identrada DESC;
 
	ELSE
	
		SELECT entrada.identrada,entrada.fecha_entrada, entrada.descripcion_entrada, producto.nombre_producto, producto.codigo_barra,entrada.cantidad_entrada,entrada.costo_total_entrada FROM entrada INNER JOIN producto ON entrada.idproducto = producto.idproducto WHERE DATE_FORMAT(fecha_entrada,'%Y-%m') = DATE_FORMAT(CURDATE(),'%Y-%m') ORDER by entrada.identrada DESC;

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_2021_salidas` (IN `p_mes` VARCHAR(7))  BEGIN
   SET time_zone = '-05:00';
    IF (p_mes!='') THEN
 
    	 SELECT salida.idsalida,salida.fecha_salida, salida.descripcion_salida, producto.nombre_producto, producto.codigo_barra,salida.cantidad_salida,salida.costo_total_salida FROM salida INNER JOIN producto ON salida.idproducto = producto.idproducto WHERE DATE_FORMAT(salida.fecha_salida,'%Y-%m') = p_mes ORDER by salida.idsalida DESC;
 
	ELSE

		 SELECT salida.idsalida,salida.fecha_salida, salida.descripcion_salida, producto.nombre_producto, producto.codigo_barra,salida.cantidad_salida,salida.costo_total_salida FROM salida INNER JOIN producto ON salida.idproducto = producto.idproducto WHERE DATE_FORMAT(fecha_salida,'%Y-%m') = DATE_FORMAT(CURDATE(),'%Y-%m') ORDER by salida.idsalida DESC;

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_abrir_caja` (IN `p_monto_apertura` DECIMAL(8,2))  BEGIN
	  SET time_zone = '-05:00';
	  IF NOT EXISTS (SELECT * FROM `caja` WHERE DATE_FORMAT(`fecha_apertura`,'%Y-%m-%d') <= curdate() AND estado = 1) THEN
		INSERT INTO `caja`(`fecha_apertura`, `monto_apertura`)
		VALUES (NOW(), p_monto_apertura);
			ELSE
        UPDATE `caja` SET
        `estado` = 1
        WHERE DATE_FORMAT(`fecha_apertura`,'%Y-%m-%d') = curdate();
	  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_abrir_inventario` ()  BEGIN
  DECLARE producto_count INT;
  SET producto_count = (SELECT COUNT(*) FROM producto);
  SET time_zone = '-05:00';

    IF(producto_count != 0)THEN
	   IF NOT EXISTS (SELECT * FROM inventario WHERE fecha_apertura = DATE_FORMAT(CURDATE(),'%Y-%m-01')
	   AND fecha_cierre = LAST_DAY(CURDATE())) THEN

			 INSERT INTO `inventario`(`mes_inventario`,`fecha_apertura`, `fecha_cierre`,
			`saldo_inicial`, `entradas`, `salidas`, `saldo_final`, `estado`, `idproducto`)
			 SELECT DATE_FORMAT(CURDATE(),'%Y-%m'),DATE_FORMAT(CURDATE(),'%Y-%m-01'),LAST_DAY(CURDATE()),stock,
             0.00,0.00,stock, 1 ,idproducto
			 FROM producto WHERE estado = 1;

			 SELECT "ABIERTO" as respuesta;

			ELSE

			 UPDATE `inventario` SET
			`estado` = 1 WHERE `estado` = 0
			AND fecha_apertura = DATE_FORMAT(CURDATE(),'%Y-%m-01')
			AND fecha_cierre = LAST_DAY(CURDATE());

			SELECT "YA ABIERTO" as respuesta;

	   END IF;

       ELSE

		SELECT "SIN PRODUCTOS" as respuesta;

	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_anular_apartado` (IN `p_idapartado` INT(11))  BEGIN	

		DECLARE p_numero_apartado varchar(175);
		DECLARE p_descripcion_movimiento varchar(80);
		SET p_numero_apartado = (SELECT numero_apartado FROM apartado WHERE idapartado = p_idapartado);
		SET p_descripcion_movimiento = (CONCAT('POR APARTADO #',' ',p_numero_apartado));
        SET time_zone = '-05:00';


		DELETE FROM `caja_movimiento` 
        WHERE `descripcion_movimiento` = p_descripcion_movimiento;

		UPDATE `apartado` SET
		`estado` = 0
		WHERE idapartado = p_idapartado;
        
        DELETE FROM `salida`
        WHERE idapartado = p_idapartado;
        
		UPDATE inventario t2
		JOIN detalleapartado t1 ON t1.idproducto = t2.idproducto
        SET t2.salidas = t2.salidas - t1.cantidad,
        t2.saldo_final = t2.saldo_final + t1.cantidad
		WHERE t1.idapartado = p_idapartado AND t2.idproducto = t1.idproducto		
        AND t2.fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND t2.fecha_cierre = LAST_DAY(CURDATE());

		UPDATE perecedero t2
		JOIN detalleapartado t1 ON t1.idproducto = t2.idproducto
		SET t2.cantidad_perecedero = t2.cantidad_perecedero + t1.cantidad
		WHERE t1.idapartado = p_idapartado AND t2.idproducto = t1.idproducto
        AND t2.fecha_vencimiento = t1.fecha_vence;

		UPDATE producto t2
		JOIN detalleapartado t1 ON t1.idproducto = t2.idproducto
		SET t2.stock = t2.stock + t1.cantidad
		WHERE t1.idapartado = p_idapartado AND t2.idproducto = t1.idproducto;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_anular_compra` (IN `p_idcompra` INT(11))  BEGIN
        SET time_zone = '-05:00';
		DELETE FROM entrada
        WHERE idcompra = p_idcompra;

		UPDATE inventario t2
		JOIN detallecompra t1 ON t1.idproducto = t2.idproducto
		SET t2.saldo_final = t2.saldo_final - t1.cantidad,
        t2.entradas = t2.entradas - t1.cantidad
		WHERE t1.idcompra = p_idcompra AND t2.idproducto = t1.idproducto
        AND t2.fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND t2.fecha_cierre = LAST_DAY(CURDATE());

		UPDATE perecedero t2
		JOIN detallecompra t1 ON t1.idproducto = t2.idproducto
		SET t2.cantidad_perecedero = t2.cantidad_perecedero - t1.cantidad
		WHERE t1.idcompra = p_idcompra AND t2.idproducto = t1.idproducto AND t2.fecha_vencimiento = t1.fecha_vence;

		UPDATE producto t2
		JOIN detallecompra t1 ON t1.idproducto = t2.idproducto
		SET t2.stock = t2.stock - t1.cantidad
		WHERE t1.idcompra = p_idcompra AND t2.idproducto = t1.idproducto;

		UPDATE compra SET
		estado = 0
		WHERE idcompra = p_idcompra;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_anular_venta` (IN `p_idventa` INT(11))  BEGIN

	DECLARE p_numero_comprobante INT;
	DECLARE p_tipo_comprobante tinyint(1);
    DECLARE p_fecha_venta date;
    DECLARE p_descripcion_movimiento varchar(150);
    DECLARE p_estado TINYINT(1);
    SET time_zone = '-05:00';

    SET p_numero_comprobante = (SELECT numero_comprobante FROM venta WHERE idventa = p_idventa);
    SET p_tipo_comprobante = (SELECT tipo_comprobante FROM venta WHERE idventa = p_idventa);
    SET p_fecha_venta = (SELECT DATE_FORMAT(fecha_venta,'%Y-%m-%d') FROM venta WHERE idventa = p_idventa);
    SET p_estado = (SELECT estado FROM venta WHERE idventa = p_idventa);

 IF(p_estado = '1') THEN

    IF(p_tipo_comprobante = '1')THEN

		SET p_descripcion_movimiento = (CONCAT('POR VENTA',' ','TICKET', ' # ',p_numero_comprobante));

		DELETE FROM caja_movimiento WHERE
		descripcion_movimiento = (p_descripcion_movimiento) AND fecha_movimiento = p_fecha_venta;

        DELETE FROM salida
        WHERE idventa = p_idventa;

        UPDATE venta SET
        estado = 0
        WHERE idventa = p_idventa;

		UPDATE inventario t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
        SET t2.salidas = t2.salidas - t1.cantidad,
        t2.saldo_final = t2.saldo_final + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND t2.fecha_cierre = LAST_DAY(CURDATE());

		UPDATE perecedero t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.cantidad_perecedero = t2.cantidad_perecedero + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_vencimiento = t1.fecha_vence;

		UPDATE producto t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.stock = t2.stock + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto;


	ELSEIF (p_tipo_comprobante = '3')THEN


		SET p_descripcion_movimiento = (CONCAT('POR VENTA',' ','FACTURA', ' # ',p_numero_comprobante));

		DELETE FROM caja_movimiento WHERE
		descripcion_movimiento = (p_descripcion_movimiento) AND fecha_movimiento = p_fecha_venta;

		DELETE FROM salida
        WHERE idventa = p_idventa;

		UPDATE venta SET
        estado = 0
        WHERE idventa = p_idventa;

		UPDATE inventario t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
        SET t2.salidas = t2.salidas - t1.cantidad,
        t2.saldo_final = t2.saldo_final + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND t2.fecha_cierre = LAST_DAY(CURDATE());

		UPDATE perecedero t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.cantidad_perecedero = t2.cantidad_perecedero + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_vencimiento = t1.fecha_vence;

		UPDATE producto t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.stock = t2.stock + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto;

    ELSEIF (p_tipo_comprobante = '2')THEN


		SET p_descripcion_movimiento = CONCAT('POR VENTA',' ','BOLETA', ' # ',p_numero_comprobante);

		DELETE FROM caja_movimiento WHERE
		descripcion_movimiento = (p_descripcion_movimiento) AND fecha_movimiento = p_fecha_venta;

		DELETE FROM salida
        WHERE idventa = p_idventa;

		UPDATE venta SET
        estado = 0
        WHERE idventa = p_idventa;

		UPDATE inventario t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
        SET t2.salidas = t2.salidas - t1.cantidad,
        t2.saldo_final = t2.saldo_final + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND t2.fecha_cierre = LAST_DAY(CURDATE());

		UPDATE perecedero t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.cantidad_perecedero = t2.cantidad_perecedero + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_vencimiento = t1.fecha_vence;

		UPDATE producto t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.stock = t2.stock + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto;

    END IF;

 ELSEIF (p_estado = '2') THEN

    DELETE FROM credito WHERE idventa = p_idventa;

	IF(p_tipo_comprobante = '1')THEN

		SET p_descripcion_movimiento = (CONCAT('POR VENTA',' ','TICKET', ' # ',p_numero_comprobante));

		DELETE FROM caja_movimiento WHERE
		descripcion_movimiento = (p_descripcion_movimiento) AND fecha_movimiento = p_fecha_venta;

        DELETE FROM salida
        WHERE idventa = p_idventa;

        UPDATE venta SET
        estado = 0
        WHERE idventa = p_idventa;

		UPDATE inventario t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
        SET t2.salidas = t2.salidas - t1.cantidad,
        t2.saldo_final = t2.saldo_final + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND t2.fecha_cierre = LAST_DAY(CURDATE());

		UPDATE perecedero t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.cantidad_perecedero = t2.cantidad_perecedero + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_vencimiento = t1.fecha_vence;

		UPDATE producto t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.stock = t2.stock + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto;


	ELSEIF (p_tipo_comprobante = '3')THEN


		SET p_descripcion_movimiento = (CONCAT('POR VENTA',' ','FACTURA', ' # ',p_numero_comprobante));

		DELETE FROM caja_movimiento WHERE
		descripcion_movimiento = (p_descripcion_movimiento) AND fecha_movimiento = p_fecha_venta;

		DELETE FROM salida
        WHERE idventa = p_idventa;

		UPDATE venta SET
        estado = 0
        WHERE idventa = p_idventa;

		UPDATE inventario t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
        SET t2.salidas = t2.salidas - t1.cantidad,
        t2.saldo_final = t2.saldo_final + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND t2.fecha_cierre = LAST_DAY(CURDATE());

		UPDATE perecedero t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.cantidad_perecedero = t2.cantidad_perecedero + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_vencimiento = t1.fecha_vence;

		UPDATE producto t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.stock = t2.stock + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto;

    ELSEIF (p_tipo_comprobante = '2')THEN


		SET p_descripcion_movimiento = CONCAT('POR VENTA',' ','BOLETA', ' # ',p_numero_comprobante);

		DELETE FROM caja_movimiento WHERE
		descripcion_movimiento = (p_descripcion_movimiento) AND fecha_movimiento = p_fecha_venta;

		DELETE FROM salida
        WHERE idventa = p_idventa;

		UPDATE venta SET
        estado = 0
        WHERE idventa = p_idventa;

		UPDATE inventario t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
        SET t2.salidas = t2.salidas - t1.cantidad,
        t2.saldo_final = t2.saldo_final + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND t2.fecha_cierre = LAST_DAY(CURDATE());

		UPDATE perecedero t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.cantidad_perecedero = t2.cantidad_perecedero + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
        AND t2.fecha_vencimiento = t1.fecha_vence;

		UPDATE producto t2
		JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
		SET t2.stock = t2.stock + t1.cantidad
		WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto;

	END IF;

 END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cerrar_caja` (IN `p_monto_cierre` DECIMAL(8,2))  BEGIN
   DECLARE p_idcaja int(11);
   SET time_zone = '-05:00';
   SET p_idcaja = (SELECT idcaja FROM `caja` WHERE DATE(fecha_apertura) <= CURDATE() AND estado=1);

	UPDATE `caja` SET
    `monto_cierre` = p_monto_cierre,
    `fecha_cierre` = NOW(),
    `estado` = 0
     WHERE idcaja = p_idcaja;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cerrar_caja_manual` (IN `p_id` INT)  BEGIN
    SET time_zone = '-05:00';
	UPDATE `caja` SET `fecha_cierre` = NOW(), `estado` = 0 WHERE idcaja = p_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cerrar_inventario` ()  BEGIN
  SET time_zone = '-05:00';

		UPDATE `inventario` SET
		`estado` = 0 WHERE `estado` = 1
        AND fecha_apertura != DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND fecha_cierre != LAST_DAY(CURDATE()) ;



	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cerrar_inventario_manual` ()  BEGIN
  SET time_zone = '-05:00';

		UPDATE `inventario` SET
		`estado` = 0 WHERE `estado` = 1
        AND fecha_apertura = DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND fecha_cierre = LAST_DAY(CURDATE()) ;

		SELECT "CERRADO" as respuesta;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_compras_anual` ()  BEGIN

	DECLARE count_compra INT;
    SET count_compra = (SELECT COUNT(*) FROM compra WHERE estado = 1);

	IF (count_compra > 0 ) THEN

	SELECT IF (UCASE(DATE_FORMAT(fecha_compra,'%b')) IS NULL,'0.00',
    UCASE(DATE_FORMAT(fecha_compra,'%b'))) as mes,
    IF(SUM(total) IS NULL, 0.00, SUM(total)) as total FROM compra
	WHERE YEAR(fecha_compra) = YEAR(CURDATE()) AND estado = 1 GROUP BY MONTH(fecha_compra);

    ELSE

    SELECT '-' as mes,'0.00' as total;


    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_apartados` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10), IN `p_estado` VARCHAR(2))  BEGIN
  SET time_zone = '-05:00';

		IF(p_criterio = 'MES') THEN

		  IF (p_date = '')THEN

				IF(p_estado = '') THEN
					SELECT * FROM view_apartados WHERE MONTH(fecha_apartado) = MONTH(CURDATE())
                    GROUP BY numero_apartado;

				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_apartados WHERE MONTH(fecha_apartado) = MONTH(CURDATE())
					AND estado_apartado = p_estado  GROUP BY numero_apartado;


				END IF;


			ELSE

				IF(p_estado = '') THEN
					SELECT * FROM view_apartados WHERE MONTH(fecha_apartado) = p_date 
                     GROUP BY numero_apartado;


				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_apartados WHERE MONTH(fecha_apartado) = p_date
					AND estado_apartado = p_estado  GROUP BY numero_apartado;


				END IF;

		  END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

		   IF (p_date = '' AND p_date2 ='')THEN

				IF(p_estado = '') THEN
					SELECT * FROM view_apartados WHERE MONTH(fecha_apartado) = MONTH(CURDATE())
                     GROUP BY numero_apartado;


				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_apartados WHERE MONTH(fecha_apartado) = MONTH(CURDATE())
					AND estado_apartado = p_estado  GROUP BY numero_apartado;


				END IF;

			ELSE

				IF(p_estado = '') THEN
					SELECT * FROM view_apartados WHERE fecha_apartado BETWEEN p_date AND p_date2
                     GROUP BY numero_apartado;

				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_apartados WHERE fecha_apartado BETWEEN p_date AND p_date2
					AND estado_apartado = p_estado GROUP BY numero_apartado;


				END IF;

			END IF;

		ELSEIF (p_criterio = 'HOY') THEN

				IF(p_estado = '') THEN
					SELECT * FROM view_apartados WHERE DATE_FORMAT(fecha_apartado,'%Y-%m-%d') = CURDATE()
                     GROUP BY numero_apartado;

				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_apartados WHERE DATE_FORMAT(fecha_apartado,'%Y-%m-%d') = CURDATE()
					AND estado_apartado = p_estado GROUP BY numero_apartado;

				END IF;

        END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_apartados_detalle` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10), IN `p_estado` VARCHAR(2))  BEGIN

  SET time_zone = '-05:00';

		IF(p_criterio = 'MES') THEN

		  IF (p_date = '')THEN

				IF(p_estado = '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE MONTH(fecha_apartado) = MONTH(CURDATE()) ;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE MONTH(fecha_apartado) = MONTH(CURDATE())
					AND estado_apartado = p_estado
					;

				END IF;


			ELSE

				IF(p_estado = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE MONTH(fecha_apartado) = p_date;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE MONTH(fecha_apartado) = p_date
					AND estado_apartado = p_estado
					;

				END IF;

		  END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

		   IF (p_date = '' AND p_date2 ='')THEN

				IF(p_estado = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE MONTH(fecha_apartado) = MONTH(CURDATE())
					;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE MONTH(fecha_apartado) = MONTH(CURDATE())
					AND estado_apartado = p_estado
					;

				END IF;

			ELSE

				IF(p_estado = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE fecha_apartado BETWEEN p_date AND p_date2
					;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE fecha_apartado BETWEEN p_date AND p_date2
					AND estado_apartado = p_estado
					;

				END IF;

			END IF;

		ELSEIF (p_criterio = 'HOY') THEN

				IF(p_estado = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE DATE_FORMAT(fecha_apartado,'%Y-%m-%d') = CURDATE()
					;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_apartados WHERE DATE_FORMAT(fecha_apartado,'%Y-%m-%d') = CURDATE()
					AND estado_apartado = p_estado
					;

				END IF;

        END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_apartados_totales` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10), IN `p_estado` VARCHAR(2))  BEGIN
  SET time_zone = '-05:00';

		IF(p_criterio = 'MES') THEN

		  IF (p_date = '')THEN

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE MONTH(fecha_apartado) = MONTH(CURDATE());

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE MONTH(fecha_apartado) = MONTH(CURDATE())
					AND estado = p_estado;

				END IF;


			ELSE

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE MONTH(fecha_apartado) = p_date;

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE MONTH(fecha_apartado) = p_date
					AND estado = p_estado;

				END IF;

		  END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

		   IF (p_date = '' AND p_date2 ='')THEN

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE MONTH(fecha_apartado) = MONTH(CURDATE());

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE MONTH(fecha_apartado) = MONTH(CURDATE());

				END IF;

			ELSE

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE fecha_apartado BETWEEN p_date AND p_date2;

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE fecha_apartado BETWEEN p_date AND p_date2
					AND estado = p_estado;

				END IF;

			END IF;

		ELSEIF (p_criterio = 'HOY') THEN

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE DATE_FORMAT(fecha_apartado,'%Y-%m-%d') = CURDATE();

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_apartado FROM apartado
                    WHERE DATE_FORMAT(fecha_apartado,'%Y-%m-%d') = CURDATE()
					AND estado = p_estado;

				END IF;

        END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_compras` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10), IN `p_estado` VARCHAR(2), IN `p_pago` VARCHAR(2))  BEGIN
  SET time_zone = '-05:00';

		IF(p_criterio = 'MES') THEN

		  IF (p_date = '')THEN

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado_compra = p_estado
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND tipo_pago = p_pago
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado_compra = p_estado AND tipo_pago	= p_pago
					GROUP BY fecha_comprobante , numero_comprobante;

				END IF;


			ELSE

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = p_date
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = p_date
					AND estado_compra = p_estado
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = p_date
					AND tipo_pago = p_pago
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = p_date
					AND estado_compra = p_estado AND tipo_pago	= p_pago
					GROUP BY fecha_comprobante , numero_comprobante;

				END IF;

		  END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

		   IF (p_date = '' AND p_date2 ='')THEN

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado_compra = p_estado
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND tipo_pago = p_pago
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT * FROM view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado_compra = p_estado AND tipo_pago	= p_pago
					GROUP BY fecha_comprobante , numero_comprobante;

				END IF;

			ELSE

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT * FROM view_compras WHERE fecha_compra BETWEEN p_date AND p_date2
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT * FROM view_compras WHERE fecha_compra BETWEEN p_date AND p_date2
					AND estado_compra = p_estado
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT * FROM view_compras WHERE fecha_compra BETWEEN p_date AND p_date2
					AND tipo_pago = p_pago
					GROUP BY fecha_comprobante , numero_comprobante;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT * FROM view_compras WHERE fecha_compra BETWEEN p_date AND p_date2
					AND estado_compra = p_estado AND tipo_pago	= p_pago
					GROUP BY fecha_comprobante , numero_comprobante;

				END IF;

			END IF;

        END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_compras_detalle` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10), IN `p_estado` VARCHAR(2), IN `p_pago` VARCHAR(2))  BEGIN
  SET time_zone = '-05:00';

		IF(p_criterio = 'MES') THEN

		  IF (p_date = '')THEN

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE());

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado_compra = p_estado;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND tipo_pago = p_pago;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado_compra = p_estado AND tipo_pago	= p_pago;

				END IF;


			ELSE

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = p_date;

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = p_date
					AND estado_compra = p_estado;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = p_date
					AND tipo_pago = p_pago;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = p_date
					AND estado_compra = p_estado AND tipo_pago	= p_pago;

				END IF;

		  END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

		   IF (p_date = '' AND p_date2 ='')THEN

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE());

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado_compra = p_estado;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND tipo_pago = p_pago;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado_compra = p_estado AND tipo_pago	= p_pago;

				END IF;

			ELSE

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE fecha_compra BETWEEN p_date AND p_date2;

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE fecha_compra BETWEEN p_date AND p_date2
					AND estado_compra = p_estado;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE fecha_compra BETWEEN p_date AND p_date2
					AND tipo_pago = p_pago;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,importe FROM
					view_compras WHERE fecha_compra BETWEEN p_date AND p_date2
					AND estado_compra = p_estado AND tipo_pago	= p_pago;

				END IF;

			END IF;

        END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_compras_totales` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10), IN `p_estado` VARCHAR(2), IN `p_pago` VARCHAR(2))  BEGIN

		IF(p_criterio = 'MES') THEN

		  IF (p_date = '')THEN

				IF(p_estado = '' AND p_pago = '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra WHERE MONTH(fecha_compra) = MONTH(CURDATE());

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado = p_estado;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND tipo_pago = p_pago;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado = p_estado AND tipo_pago	= p_pago;

				END IF;


			ELSE

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE MONTH(fecha_compra) = p_date;

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE MONTH(fecha_compra) = p_date
					AND estado = p_estado;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE MONTH(fecha_compra) = p_date
					AND tipo_pago = p_pago;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra WHERE MONTH(fecha_compra) = p_date
					AND estado = p_estado AND tipo_pago	= p_pago;

				END IF;

		  END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

		   IF (p_date = '' AND p_date2 ='')THEN

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE MONTH(fecha_compra) = MONTH(CURDATE());

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado = p_estado;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND tipo_pago = p_pago;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE MONTH(fecha_compra) = MONTH(CURDATE())
					AND estado = p_estado AND tipo_pago	= p_pago;

				END IF;

			ELSE

				IF(p_estado = '' AND p_pago = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE fecha_compra BETWEEN p_date AND p_date2;

				ELSEIF (p_estado != '' AND p_pago = '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE fecha_compra BETWEEN p_date AND p_date2
					AND estado = p_estado;

				ELSEIF (p_estado = '' AND p_pago != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE fecha_compra BETWEEN p_date AND p_date2
					AND tipo_pago = p_pago;

				ELSEIF (p_estado != '' AND p_pago != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
					SUM(retenido) as total_retenido, SUM(total) as total_comprado
                    FROM compra  WHERE fecha_compra BETWEEN p_date AND p_date2
					AND estado = p_estado AND tipo_pago	= p_pago;

				END IF;

			END IF;

        END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_historico_precios` (IN `p_idproducto` INT(11))  BEGIN

		SELECT * FROM view_historico_precios WHERE idproducto = p_idproducto;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_precio_mas_bajo` (IN `p_idproducto` INT(11))  BEGIN

		SELECT * FROM view_historico_precios WHERE idproducto = p_idproducto
        AND precio_comprado = (SELECT MIN(precio_comprado) FROM  view_historico_precios
        WHERE idproducto = p_idproducto);

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_ventas` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10), IN `p_estado` VARCHAR(2))  BEGIN
  		 SET time_zone = '-05:00';

		IF(p_criterio = 'MES') THEN

		  IF (p_date = '')THEN

				IF(p_estado = '') THEN
					SELECT * FROM view_ventas WHERE MONTH(fecha_venta) = MONTH(CURDATE())
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_ventas WHERE MONTH(fecha_venta) = MONTH(CURDATE())
					AND estado_venta = p_estado
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				END IF;


			ELSE

				IF(p_estado = '') THEN
					SELECT * FROM view_ventas WHERE MONTH(fecha_venta) = p_date
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_ventas WHERE MONTH(fecha_venta) = p_date
					AND estado_venta = p_estado
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				END IF;

		  END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

		   IF (p_date = '' AND p_date2 ='')THEN

				IF(p_estado = '') THEN
					SELECT * FROM view_ventas WHERE MONTH(fecha_venta) = MONTH(CURDATE())
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_ventas WHERE MONTH(fecha_venta) = MONTH(CURDATE())
					AND estado_venta = p_estado
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				END IF;

			ELSE

				IF(p_estado = '') THEN
					SELECT * FROM view_ventas WHERE fecha_venta BETWEEN p_date AND p_date2
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_ventas WHERE fecha_venta BETWEEN p_date AND p_date2
					AND estado_venta = p_estado
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				END IF;

			END IF;

		ELSEIF (p_criterio = 'HOY') THEN

				IF(p_estado = '') THEN
					SELECT * FROM view_ventas WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE()
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				ELSEIF (p_estado != '') THEN

					SELECT * FROM view_ventas WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE()
					AND estado_venta = p_estado
					GROUP BY DATE_FORMAT(fecha_venta,'%Y-%m-%d'), numero_comprobante;

				END IF;

        END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_ventas_detalle` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10), IN `p_estado` VARCHAR(2))  BEGIN
   SET time_zone = '-05:00';


		IF(p_criterio = 'MES') THEN

		  IF (p_date = '')THEN

				IF(p_estado = '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE MONTH(fecha_venta) = MONTH(CURDATE())
					;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE MONTH(fecha_venta) = MONTH(CURDATE())
					AND estado_venta = p_estado
					;

				END IF;


			ELSE

				IF(p_estado = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE MONTH(fecha_venta) = p_date
					;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE MONTH(fecha_venta) = p_date
					AND estado_venta = p_estado
					;

				END IF;

		  END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

		   IF (p_date = '' AND p_date2 ='')THEN

				IF(p_estado = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE MONTH(fecha_venta) = MONTH(CURDATE())
					;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE MONTH(fecha_venta) = MONTH(CURDATE())
					AND estado_venta = p_estado
					;

				END IF;

			ELSE

				IF(p_estado = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE fecha_venta BETWEEN p_date AND p_date2
					;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE fecha_venta BETWEEN p_date AND p_date2
					AND estado_venta = p_estado
					;

				END IF;

			END IF;

		ELSEIF (p_criterio = 'HOY') THEN

				IF(p_estado = '') THEN
					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE()
					;

				ELSEIF (p_estado != '') THEN

					SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
					nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,(importe-descuento)
                    as importe,sumas,
					iva,total_exento,retenido,total_descuento,total,fecha_vence,precio_compra,
					((precio_unitario - precio_compra) * cantidad) - descuento AS utilidad_total
					FROM view_ventas WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE()
					AND estado_venta = p_estado
					;

				END IF;

        END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_consulta_ventas_totales` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10), IN `p_estado` VARCHAR(2))  BEGIN
   SET time_zone = '-05:00';

		IF(p_criterio = 'MES') THEN

		  IF (p_date = '')THEN

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE MONTH(fecha_venta) = MONTH(CURDATE());

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE MONTH(fecha_venta) = MONTH(CURDATE())
					AND estado = p_estado;

				END IF;


			ELSE

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE MONTH(fecha_venta) = p_date;

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE MONTH(fecha_venta) = p_date
					AND estado = p_estado;

				END IF;

		  END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

		   IF (p_date = '' AND p_date2 ='')THEN

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE MONTH(fecha_venta) = MONTH(CURDATE());

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE MONTH(fecha_venta) = MONTH(CURDATE());

				END IF;

			ELSE

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE fecha_venta BETWEEN p_date AND p_date2;

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE fecha_venta BETWEEN p_date AND p_date2
					AND estado = p_estado;

				END IF;

			END IF;

		ELSEIF (p_criterio = 'HOY') THEN

				IF(p_estado = '') THEN
					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE();

				ELSEIF (p_estado != '') THEN

					SELECT SUM(iva) as total_iva, SUM(exento) as total_exento,
                    SUM(retenido) as total_retenido, SUM(descuento) as total_descuento,
                    SUM(total) as total_vendido FROM venta
                    WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE()
					AND estado = p_estado;

				END IF;

        END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_corte_z_day` (IN `p_day` DATE)  BEGIN

	DECLARE p_desde_impreso INT;
    DECLARE p_hasta_impreso INT;
    DECLARE p_venta_gravada DECIMAL(8,2);
    DECLARE p_venta_iva DECIMAL(8,2);
	DECLARE p_total_exento DECIMAL(8,2);
    DECLARE p_total_gravado DECIMAL(8,2);
    DECLARE p_total_descuento DECIMAL(8,2);
    DECLARE p_total_venta DECIMAL(8,2);

    IF (p_day!='') THEN

		SET p_desde_impreso = (SELECT MIN(numero_comprobante) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = p_day AND tipo_comprobante = 1);

		SET p_hasta_impreso = (SELECT MAX(numero_comprobante) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = p_day AND tipo_comprobante = 1);

		SET p_venta_gravada = (SELECT SUM(sumas) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = p_day AND tipo_comprobante = 1);

		SET p_venta_iva = (SELECT SUM(iva) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = p_day AND tipo_comprobante = 1);

		SET p_total_exento = (SELECT SUM(exento) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = p_day AND tipo_comprobante = 1);
        
		SET p_total_descuento = (SELECT SUM(descuento) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = p_day AND tipo_comprobante = 1);

        SET p_total_gravado = (p_venta_gravada + p_venta_iva);
        SET p_total_venta = (p_total_gravado + p_total_exento) - p_total_descuento;

        SELECT p_desde_impreso, p_hasta_impreso, p_venta_gravada, p_venta_iva ,
        p_total_exento , p_total_gravado , p_total_descuento, p_total_venta;

	ELSE

		SET p_desde_impreso = (SELECT MIN(numero_comprobante) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE() AND tipo_comprobante = 1);

		SET p_hasta_impreso = (SELECT MAX(numero_comprobante) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE() AND tipo_comprobante = 1);

		SET p_venta_gravada = (SELECT SUM(sumas) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE() AND tipo_comprobante = 1);

		SET p_venta_iva = (SELECT SUM(iva) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE() AND tipo_comprobante = 1);

		SET p_total_exento = (SELECT SUM(exento) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE() AND tipo_comprobante = 1);
        
		SET p_total_descuento = (SELECT SUM(descuento) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') = CURDATE()  AND tipo_comprobante = 1);

        SET p_total_gravado = (p_venta_gravada + p_venta_iva);
        SET p_total_venta = (p_total_gravado + p_total_exento) - p_total_descuento;

        SELECT p_desde_impreso, p_hasta_impreso, p_venta_gravada, p_venta_iva ,
        p_total_exento , p_total_gravado , p_total_descuento, p_total_venta;

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_corte_z_mes` (IN `p_month` VARCHAR(7))  BEGIN

	DECLARE p_desde_impreso INT;
    DECLARE p_hasta_impreso INT;
    DECLARE p_venta_gravada DECIMAL(8,2);
    DECLARE p_venta_iva DECIMAL(8,2);
	DECLARE p_total_exento DECIMAL(8,2);
    DECLARE p_total_gravado DECIMAL(8,2);
	DECLARE p_total_descuento DECIMAL(8,2);
    DECLARE p_total_venta DECIMAL(8,2);

    IF (p_month!='') THEN

		SET p_desde_impreso = (SELECT MIN(numero_comprobante) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_month AND tipo_comprobante = 1);

		SET p_hasta_impreso = (SELECT MAX(numero_comprobante) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_month AND tipo_comprobante = 1);

		SET p_venta_gravada = (SELECT SUM(sumas) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_month AND tipo_comprobante = 1);

		SET p_venta_iva = (SELECT SUM(iva) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_month AND tipo_comprobante = 1);

		SET p_total_exento = (SELECT SUM(exento) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_month AND tipo_comprobante = 1);
        
        SET p_total_descuento = (SELECT SUM(descuento) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_month AND tipo_comprobante = 1);

        SET p_total_gravado = (p_venta_gravada + p_venta_iva);
        SET p_total_venta = (p_total_gravado + p_total_exento) - p_total_descuento;

        SELECT p_desde_impreso, p_hasta_impreso, p_venta_gravada, p_venta_iva ,
        p_total_exento , p_total_gravado , p_total_descuento, p_total_venta;

	ELSE

		SET p_desde_impreso = (SELECT MIN(numero_comprobante) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') =  MONTH(CURDATE()) AND tipo_comprobante = 1);

		SET p_hasta_impreso = (SELECT MAX(numero_comprobante) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') =  MONTH(CURDATE()) AND tipo_comprobante = 1);

		SET p_venta_gravada = (SELECT SUM(sumas) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') =  MONTH(CURDATE()) AND tipo_comprobante = 1);

		SET p_venta_iva = (SELECT SUM(iva) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') =  MONTH(CURDATE()) AND tipo_comprobante = 1);

		SET p_total_exento = (SELECT SUM(exento) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') =  MONTH(CURDATE()) AND tipo_comprobante = 1);
        
		SET p_total_descuento = (SELECT SUM(descuento) FROM venta
		WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = MONTH(CURDATE()) AND tipo_comprobante = 1);

        SET p_total_gravado = (p_venta_gravada + p_venta_iva);
        SET p_total_venta = (p_total_gravado + p_total_exento) - p_total_descuento;

        SELECT p_desde_impreso, p_hasta_impreso, p_venta_gravada, p_venta_iva ,
        p_total_exento , p_total_gravado , p_total_descuento, p_total_venta;

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_count_apartados` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10))  BEGIN

       DECLARE apartados_anuladas INT;
       DECLARE apartados_vigentes INT;
	   DECLARE apartados_saldados INT;

   IF (p_criterio = 'MES') THEN

     IF (p_date = '') THEN

       SET apartados_anuladas = (SELECT COUNT(*) AS apartados_anuladas
	   FROM apartado WHERE estado = 0 AND DATE_FORMAT(fecha_apartado,'%m-%Y') =  MONTH(CURDATE()));
       SET apartados_vigentes = (SELECT COUNT(*) AS apartados_vigentes
	   FROM apartado WHERE estado = 1 AND DATE_FORMAT(fecha_apartado,'%m-%Y') = MONTH(CURDATE()));
	   SET apartados_saldados = (SELECT COUNT(*) AS apartados_vigentes
	   FROM apartado WHERE estado = 2 AND DATE_FORMAT(fecha_apartado,'%m-%Y') = MONTH(CURDATE()));

		SELECT apartados_anuladas,apartados_vigentes,apartados_saldados;

     ELSE

       SET apartados_anuladas = (SELECT COUNT(*) AS apartados_anuladas FROM apartado
	   WHERE DATE_FORMAT(fecha_apartado,'%m-%Y') = p_date AND estado = 0 );
       SET apartados_vigentes = (SELECT COUNT(*) AS apartados_vigentes FROM apartado
	   WHERE DATE_FORMAT(fecha_apartado,'%m-%Y') = p_date AND estado = 1);
	   SET apartados_saldados = (SELECT COUNT(*) AS apartados_vigentes FROM apartado
	   WHERE DATE_FORMAT(fecha_apartado,'%m-%Y') = p_date AND estado = 2);

       SELECT apartados_anuladas,apartados_vigentes,apartados_saldados;

           END IF;

   ELSEIF (p_criterio = 'FECHAS') THEN

       IF (p_date = '' AND p_date2 = '') THEN

       SET apartados_anuladas = (SELECT COUNT(*) AS apartados_anuladas
       FROM apartado WHERE estado = 0 AND DATE_FORMAT(fecha_apartado,'%m-%Y') =  MONTH(CURDATE()));
       SET apartados_vigentes = (SELECT COUNT(*) AS apartados_vigentes
	   FROM apartado WHERE estado = 1 AND DATE_FORMAT(fecha_apartado,'%m-%Y') = MONTH(CURDATE()));
	   SET apartados_saldados = (SELECT COUNT(*) AS apartados_vigentes
	   FROM apartado WHERE estado = 2 AND DATE_FORMAT(fecha_apartado,'%m-%Y') = MONTH(CURDATE()));

		SELECT apartados_anuladas,apartados_vigentes,apartados_saldados;

     ELSE

       SET apartados_anuladas = (SELECT COUNT(*) AS apartados_anuladas FROM apartado
       WHERE estado = 0 AND DATE_FORMAT(fecha_apartado,'%Y-%m-%d') BETWEEN p_date AND p_date2);
       SET apartados_vigentes = (SELECT COUNT(*) AS apartados_vigentes FROM apartado
       WHERE estado = 1 AND DATE_FORMAT(fecha_apartado,'%Y-%m-%d') BETWEEN p_date AND p_date2);
	   SET apartados_saldados = (SELECT COUNT(*) AS apartados_vigentes FROM apartado
       WHERE estado = 2 AND DATE_FORMAT(fecha_apartado,'%Y-%m-%d') BETWEEN p_date AND p_date2);

       SELECT apartados_anuladas,apartados_vigentes,apartados_saldados;

           END IF;

   ELSEIF (p_criterio = 'HOY') THEN

     SET apartados_anuladas = (SELECT COUNT(*) AS apartados_anuladas
     FROM apartado WHERE estado = 0 AND DATE_FORMAT(fecha_apartado,'%Y-%m-%d') =  CURDATE());
     SET apartados_vigentes = (SELECT COUNT(*) AS apartados_vigentes
     FROM apartado WHERE estado = 1 AND DATE_FORMAT(fecha_apartado,'%Y-%m-%d') =  CURDATE());
     SET apartados_saldados = (SELECT COUNT(*) AS apartados_vigentes
     FROM apartado WHERE estado = 2 AND DATE_FORMAT(fecha_apartado,'%Y-%m-%d') =  CURDATE());


     SELECT apartados_anuladas,apartados_vigentes,apartados_saldados;

 END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_count_compras` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10))  BEGIN

        DECLARE compras_anuladas INT;
        DECLARE compras_vigentes INT;
        DECLARE compras_contado INT;
        DECLARE compras_credito INT;


		IF (p_criterio = 'MES') THEN

			IF (p_date = '') THEN

				SET compras_anuladas = (SELECT COUNT(*) AS compras_anuladas
                FROM compra WHERE estado = 0 AND DATE_FORMAT(fecha_compra,'%m-%Y') =  MONTH(CURDATE()));
				SET compras_vigentes = (SELECT COUNT(*) AS compras_vigentes
                FROM compra WHERE estado = 1 AND DATE_FORMAT(fecha_compra,'%m-%Y') = MONTH(CURDATE()));
				SET compras_contado = (SELECT COUNT(*) AS compras_vigentes
                FROM compra WHERE tipo_pago = 1 AND  DATE_FORMAT(fecha_compra,'%m-%Y') = MONTH(CURDATE()));
				SET compras_credito = (SELECT COUNT(*) AS compras_vigentes
                FROM compra WHERE tipo_pago = 2 AND  DATE_FORMAT(fecha_compra,'%m-%Y') = MONTH(CURDATE()));

                SELECT compras_anuladas,compras_vigentes,compras_contado,compras_credito;

			ELSE

				SET compras_anuladas = (SELECT COUNT(*) AS compras_anuladas FROM compra

                WHERE DATE_FORMAT(fecha_compra,'%m-%Y') = p_date AND estado = 0 );
				SET compras_vigentes = (SELECT COUNT(*) AS compras_vigentes FROM compra
                WHERE DATE_FORMAT(fecha_compra,'%m-%Y') = p_date AND estado = 1);
				SET compras_contado = (SELECT COUNT(*) AS compras_vigentes FROM compra
                WHERE DATE_FORMAT(fecha_compra,'%m-%Y') = p_date AND tipo_pago = 1);
				SET compras_credito = (SELECT COUNT(*) AS compras_vigentes FROM compra
                WHERE DATE_FORMAT(fecha_compra,'%m-%Y') = p_date AND tipo_pago = 2);

				SELECT compras_anuladas,compras_vigentes,compras_contado,compras_credito;

            END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

        IF (p_date = '' AND p_date2 = '') THEN

				SET compras_anuladas = (SELECT COUNT(*) AS compras_anuladas
                FROM compra WHERE estado = 0 AND DATE_FORMAT(fecha_compra,'%m-%Y') =  MONTH(CURDATE()));
				SET compras_vigentes = (SELECT COUNT(*) AS compras_vigentes
                FROM compra WHERE estado = 1 AND DATE_FORMAT(fecha_compra,'%m-%Y') = MONTH(CURDATE()));
				SET compras_contado = (SELECT COUNT(*) AS compras_vigentes
                FROM compra WHERE tipo_pago = 1 AND  DATE_FORMAT(fecha_compra,'%m-%Y') = MONTH(CURDATE()));
				SET compras_credito = (SELECT COUNT(*) AS compras_vigentes
                FROM compra WHERE tipo_pago = 2 AND  DATE_FORMAT(fecha_compra,'%m-%Y') = MONTH(CURDATE()));

                SELECT compras_anuladas,compras_vigentes,compras_contado,compras_credito;

			ELSE

				SET compras_anuladas = (SELECT COUNT(*) AS compras_anuladas FROM compra
				WHERE estado = 0 AND DATE_FORMAT(fecha_compra,'%Y-%m-%d') BETWEEN p_date AND p_date2);
				SET compras_vigentes = (SELECT COUNT(*) AS compras_vigentes FROM compra
				WHERE estado = 1 AND DATE_FORMAT(fecha_compra,'%Y-%m-%d') BETWEEN p_date AND p_date2);
				SET compras_contado = (SELECT COUNT(*) AS compras_vigentes FROM compra
				WHERE tipo_pago = 1 AND DATE_FORMAT(fecha_compra,'%Y-%m-%d') BETWEEN p_date AND p_date2);
				SET compras_credito = (SELECT COUNT(*) AS compras_vigentes FROM compra
				WHERE tipo_pago = 2 AND DATE_FORMAT(fecha_compra,'%Y-%m-%d') BETWEEN p_date AND p_date2);

				SELECT compras_anuladas,compras_vigentes,compras_contado,compras_credito;

            END IF;

	END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_count_cotizaciones` (IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10))  BEGIN

		IF (p_date = '' AND p_date2 = '') THEN

			SELECT COUNT(*) AS total_cotizaciones FROM cotizacion;

		ELSE

			SELECT COUNT(*) AS total_cotizaciones
            FROM cotizacion WHERE fecha_cotizacion
            BETWEEN p_date AND p_date2;

		END IF;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_count_creditos` ()  BEGIN

    DECLARE count_pendientes int;
    DECLARE count_pagados int;

	SET count_pendientes = (SELECT COUNT(*) AS creditos_pendientes FROM credito WHERE estado = 0);
    SET count_pagados = (SELECT COUNT(*) AS creditos_pagados FROM credito WHERE estado = 1);

    SELECT count_pendientes,count_pagados;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_count_creditos_proveedor` ()  BEGIN

    DECLARE count_pendientes int;
    DECLARE count_pagados int;

	SET count_pendientes = (SELECT COUNT(*) AS creditos_pendientes FROM creditoproveedor WHERE estado = 0);
    SET count_pagados = (SELECT COUNT(*) AS creditos_pagados FROM creditoproveedor WHERE estado = 1);

    SELECT count_pendientes,count_pagados;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_count_ordenes` (IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10))  BEGIN

 IF (p_date = '' AND p_date2 = '') THEN
		SELECT COUNT(*) as total_ordenes FROM view_taller ORDER BY fecha_ingreso DESC;
	ELSE
		 SELECT COUNT(*) as total_ordenes  FROM view_taller WHERE DATE_FORMAT(fecha_ingreso,'%Y-%m-%d') BETWEEN p_date AND p_date2
		 ORDER BY  DATE_FORMAT(fecha_ingreso,'%Y-%m-%d') DESC;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_count_ventas` (IN `p_criterio` VARCHAR(10), IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10))  BEGIN

        DECLARE ventas_anuladas INT;
        DECLARE ventas_vigentes INT;
        DECLARE ventas_contado INT;
        DECLARE ventas_credito INT;

   SET time_zone = '-05:00';

		IF (p_criterio = 'MES') THEN

			IF (p_date = '') THEN

				SET ventas_anuladas = (SELECT COUNT(*) AS ventas_anuladas
                FROM venta WHERE estado = 0 AND DATE_FORMAT(fecha_venta,'%m-%Y') =  MONTH(CURDATE()));
				SET ventas_vigentes = (SELECT COUNT(*) AS ventas_vigentes
                FROM venta WHERE estado = 1 AND DATE_FORMAT(fecha_venta,'%m-%Y') = MONTH(CURDATE()));
				SET ventas_contado = (SELECT COUNT(*) AS ventas_vigentes
                FROM venta WHERE estado = 1 AND  DATE_FORMAT(fecha_venta,'%m-%Y') = MONTH(CURDATE()));
				SET ventas_credito = (SELECT COUNT(*) AS ventas_vigentes
                FROM venta WHERE estado = 2 AND  DATE_FORMAT(fecha_venta,'%m-%Y') = MONTH(CURDATE()));

                SELECT ventas_anuladas,ventas_vigentes,ventas_contado,ventas_credito;

			ELSE

				SET ventas_anuladas = (SELECT COUNT(*) AS ventas_anuladas FROM venta
                WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_date AND estado = 0 );
				SET ventas_vigentes = (SELECT COUNT(*) AS ventas_vigentes FROM venta
                WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_date AND estado = 1);
				SET ventas_contado = (SELECT COUNT(*) AS ventas_vigentes FROM venta
                WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_date AND estado = 1);
				SET ventas_credito = (SELECT COUNT(*) AS ventas_vigentes FROM venta
                WHERE DATE_FORMAT(fecha_venta,'%m-%Y') = p_date AND estado = 2);

				SELECT ventas_anuladas,ventas_vigentes,ventas_contado,ventas_credito;

            END IF;

		ELSEIF (p_criterio = 'FECHAS') THEN

        IF (p_date = '' AND p_date2 = '') THEN

				SET ventas_anuladas = (SELECT COUNT(*) AS ventas_anuladas
                FROM venta WHERE estado = 0 AND DATE_FORMAT(fecha_venta,'%m-%Y') =  MONTH(CURDATE()));
				SET ventas_vigentes = (SELECT COUNT(*) AS ventas_vigentes
                FROM venta WHERE estado = 1 AND DATE_FORMAT(fecha_venta,'%m-%Y') = MONTH(CURDATE()));
				SET ventas_contado = (SELECT COUNT(*) AS ventas_vigentes
                FROM venta WHERE estado = 1 AND  DATE_FORMAT(fecha_venta,'%m-%Y') = MONTH(CURDATE()));
				SET ventas_credito = (SELECT COUNT(*) AS ventas_vigentes
                FROM venta WHERE estado = 2 AND  DATE_FORMAT(fecha_venta,'%m-%Y') = MONTH(CURDATE()));

                SELECT ventas_anuladas,ventas_vigentes,ventas_contado,ventas_credito;

			ELSE

				SET ventas_anuladas = (SELECT COUNT(*) AS ventas_anuladas FROM venta
				WHERE estado = 0 AND DATE_FORMAT(fecha_venta,'%Y-%m-%d') BETWEEN p_date AND p_date2);
				SET ventas_vigentes = (SELECT COUNT(*) AS ventas_vigentes FROM venta
				WHERE estado = 1 AND DATE_FORMAT(fecha_venta,'%Y-%m-%d') BETWEEN p_date AND p_date2);
				SET ventas_contado = (SELECT COUNT(*) AS ventas_vigentes FROM venta
				WHERE estado = 1 AND DATE_FORMAT(fecha_venta,'%Y-%m-%d') BETWEEN p_date AND p_date2);
				SET ventas_credito = (SELECT COUNT(*) AS ventas_vigentes FROM venta
				WHERE estado = 2 AND DATE_FORMAT(fecha_venta,'%Y-%m-%d') BETWEEN p_date AND p_date2);

				SELECT ventas_anuladas,ventas_vigentes,ventas_contado,ventas_credito;

            END IF;

		ELSEIF (p_criterio = 'HOY') THEN

			SET ventas_anuladas = (SELECT COUNT(*) AS ventas_anuladas
			FROM venta WHERE estado = 0 AND DATE_FORMAT(fecha_venta,'%Y-%m-%d') =  CURDATE());
			SET ventas_vigentes = (SELECT COUNT(*) AS ventas_vigentes
			FROM venta WHERE estado = 1 AND DATE_FORMAT(fecha_venta,'%Y-%m-%d') =  CURDATE());
			SET ventas_contado = (SELECT COUNT(*) AS ventas_vigentes
			FROM venta WHERE estado = 1 AND DATE_FORMAT(fecha_venta,'%Y-%m-%d') =  CURDATE());
			SET ventas_credito = (SELECT COUNT(*) AS ventas_vigentes
			FROM venta WHERE estado = 2 AND DATE_FORMAT(fecha_venta,'%Y-%m-%d') =  CURDATE());

			SELECT ventas_anuladas,ventas_vigentes,ventas_contado,ventas_credito;

	END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_abono` (IN `p_idabono` INT(11))  BEGIN

	DECLARE p_monto_abono decimal(8,2);
    DECLARE p_idcredito INT;
    DECLARE p_monto_abonado decimal(8,2);
    DECLARE p_monto_restante decimal(8,2);

    SET p_monto_abono = (SELECT monto_abono FROM abono WHERE idabono = p_idabono);
    SET p_idcredito = (SELECT idcredito FROM view_abonos WHERE idabono = p_idabono);
    SET p_monto_abonado = (SELECT monto_abonado FROM credito WHERE idcredito = p_idcredito);
    SET p_monto_restante = (SELECT monto_restante FROM credito WHERE idcredito = p_idcredito);

    IF p_monto_restante = 0 THEN

		UPDATE credito SET
        estado = 0,
        monto_restante = p_monto_abono,
        monto_abonado = monto_abonado - p_monto_abono
        WHERE idcredito = p_idcredito;

    ELSEIF p_monto_restante > 0 THEN
		UPDATE credito SET
        monto_restante = monto_restante + p_monto_abono,
        monto_abonado = monto_abonado - p_monto_abono
        WHERE idcredito = p_idcredito;
    END IF;

	DELETE FROM `abono`
	WHERE `idabono` = p_idabono;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_abono_proveedor` (IN `p_idabonoproveedor` INT(11))  BEGIN

	DECLARE p_monto_abono decimal(8,2);
    DECLARE p_idcreditoproveedor INT;
    DECLARE p_monto_abonado decimal(8,2);
    DECLARE p_monto_restante decimal(8,2);

    SET p_monto_abono = (SELECT monto_abono FROM abonoproveedor WHERE idabonoproveedor = p_idabonoproveedor);
    SET p_idcreditoproveedor = (SELECT idcreditoproveedor FROM view_abonos_proveedor WHERE idabonoproveedor = p_idabonoproveedor);
    SET p_monto_abonado = (SELECT monto_abonado FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
    SET p_monto_restante = (SELECT monto_restante FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);

    IF p_monto_restante = 0 THEN

		UPDATE creditoproveedor SET
        estado = 0,
        monto_restante = p_monto_abono,
        monto_abonado = monto_abonado - p_monto_abono
        WHERE idcreditoproveedor = p_idcreditoproveedor;

    ELSEIF p_monto_restante > 0 THEN
		UPDATE creditoproveedor SET
        monto_restante = monto_restante + p_monto_abono,
        monto_abonado = monto_abonado - p_monto_abono
        WHERE idcreditoproveedor = p_idcreditoproveedor;
    END IF;

	DELETE FROM `abonoproveedor`
	WHERE `idabonoproveedor` = p_idabonoproveedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_cotizacion` (IN `p_idcotizacion` INT(11))  BEGIN
DELETE FROM `cotizacion`
WHERE `idcotizacion` = p_idcotizacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_ordentaller` (IN `p_idorden` INT(11))  BEGIN
	DELETE FROM `ordentaller`
	WHERE `idorden` = p_idorden;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_delete_perecedero` (IN `p_fecha_vencimiento` DATE, IN `p_idproducto` INT(11))  BEGIN
	DELETE FROM `perecedero` WHERE `idproducto` =  p_idproducto
    AND `fecha_vencimiento` = p_fecha_vencimiento;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_descontar_perecedero` (IN `p_idproducto` INT(11), IN `p_cantidad` DECIMAL(8,2), IN `p_fecha_vencimiento` DATE)  BEGIN

    DECLARE p_cantidad_perecedero DECIMAL(8,2);
    DECLARE p_resta DECIMAL(8,2);

	SET p_cantidad_perecedero = (SELECT cantidad_perecedero FROM perecedero WHERE
    idproducto = p_idproducto AND cantidad_perecedero > 0.00
    AND fecha_vencimiento = p_fecha_vencimiento);

    SET p_resta = p_cantidad_perecedero - p_cantidad;

    IF p_resta = 0 THEN

        UPDATE perecedero SET
		cantidad_perecedero = 0.00,
        estado = 2
        WHERE idproducto = p_idproducto AND fecha_vencimiento = p_fecha_vencimiento;

     ELSE

		UPDATE perecedero SET
		cantidad_perecedero = p_resta
        WHERE idproducto = p_idproducto AND fecha_vencimiento = p_fecha_vencimiento;

    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_detalle_imprimir_factura_venta` (IN `p_idventa` INT(11))  BEGIN

		DECLARE p_idmax int;
        SET p_idmax = (SELECT MAX(idventa) FROM venta);


		IF (p_idventa = '') THEN

        SELECT cantidad,nombre_producto,precio_unitario,
        if(producto_exento = '1', CONCAT(importe,'E'), CONCAT(importe,'G')) as importe,
        exento,descuento
        FROM view_ventas
        WHERE idventa = p_idmax;

        ELSE

		SELECT cantidad, nombre_producto,precio_unitario,
        if(producto_exento = '1', CONCAT(importe,'E'), CONCAT(importe,'G')) as importe,
         exento,descuento
        FROM view_ventas
        WHERE idventa = p_idventa;

		END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_detalle_imprimir_ticket_apartado` (IN `p_idapartado` INT(11))  BEGIN

		DECLARE p_idmax int;
				SET p_idmax = (SELECT MAX(idapartado) FROM apartado);


		IF (p_idapartado = '') THEN

		SELECT cantidad, substring(nombre_producto,1,12) as descripcion,precio_unitario,
				if(producto_exento = '1', CONCAT(importe,'E'), CONCAT(importe,'G')) as importe
				FROM view_apartados
				WHERE idapartado = p_idmax;

				ELSE

		SELECT cantidad, substring(nombre_producto,1,12) as descripcion,precio_unitario,
				if(producto_exento = '1', CONCAT(importe,'E'), CONCAT(importe,'G')) as importe
				FROM view_apartados
				WHERE idapartado = p_idapartado;

		END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_detalle_imprimir_ticket_venta` (IN `p_idventa` INT(11))  BEGIN

		DECLARE p_idmax int;
        SET p_idmax = (SELECT MAX(idventa) FROM venta);


		IF (p_idventa = '') THEN

        SELECT codigo_barra, cantidad, substring(nombre_producto,1,22) as descripcion,precio_unitario,
        if(producto_exento = '1', CONCAT(importe,'E'), CONCAT(importe,'G')) as importe
        FROM view_ventas
        WHERE idventa = p_idmax;

        ELSE

		SELECT codigo_barra, cantidad, substring(nombre_producto,1,22) as descripcion,precio_unitario,
        if(producto_exento = '1', CONCAT(importe,'E'), CONCAT(importe,'G')) as importe
        FROM view_ventas
        WHERE idventa = p_idventa;

		END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_devolver_productos_apartados` ()  BEGIN
		
		DECLARE i int;
        DECLARE temp_id INT;
        DECLARE p_count INT;
        DECLARE p_idmax INT;
        
        SET p_count = (SELECT COUNT(*) FROM apartado WHERE `estado` = 1
		AND fecha_limite_retiro < CURDATE());
        SET i = 0;
        SET temp_id = 0;
        
        WHILE (i < p_count) DO
        
			DROP TABLE IF EXISTS temporal_apartados;
			CREATE TEMPORARY TABLE IF NOT EXISTS temporal_apartados
			SELECT idapartado FROM apartado WHERE `estado` = 1
			AND fecha_limite_retiro < CURDATE();
        
			SET p_idmax = (SELECT max(idapartado) FROM temporal_apartados);
			
            IF(temp_id != p_idmax) THEN
            
				SET temp_id = (p_idmax);
				CALL sp_anular_apartado(temp_id);
                
			END IF;
            
			SET i = i + 1;
            
        END WHILE;
        
	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_fechas_vencimiento` (IN `p_idproducto` INT(11))  BEGIN

   SELECT cantidad_perecedero, DATE_FORMAT(fecha_vencimiento,'%d/%m/%Y') as fecha_vencimiento FROM perecedero
   WHERE idproducto = p_idproducto
   AND estado = 1 ORDER by fecha_vencimiento ASC;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_finalizar_venta` (IN `p_idventa` INT(11))  BEGIN

	DECLARE p_total DECIMAL(8,2);
    DECLARE p_descr_salida varchar(150);
    DECLARE p_tipo_comprobante tinyint(1);
    DECLARE p_numero_comprobante int(11);

    SET p_total = (SELECT total FROM venta WHERE idventa = p_idventa);
    SET p_tipo_comprobante = (SELECT tipo_comprobante FROM venta WHERE idventa = p_idventa);
    SET p_numero_comprobante = (SELECT numero_comprobante FROM venta WHERE idventa = p_idventa);

    IF p_tipo_comprobante = '1' THEN
		SET p_descr_salida = (CONCAT('POR VENTA',' ','TICKET', ' # ',p_numero_comprobante));
	ELSEIF p_tipo_comprobante = '2' THEN
		SET p_descr_salida = (CONCAT('POR VENTA',' ','FACTURA', ' # ',p_numero_comprobante));
	ELSEIF p_tipo_comprobante = '3' THEN
		SET p_descr_salida = (CONCAT('POR VENTA',' ','BOLETA', ' # ',p_numero_comprobante));
    END IF;

	INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
	`precio_unitario_salida`, `costo_total_salida`, `idproducto`)
	SELECT DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_salida,cantidad,precio_unitario,(cantidad*precio_unitario),idproducto
	FROM detalleventa WHERE idventa = p_idventa;


	UPDATE inventario t2
	JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
	SET t2.saldo_final = t2.saldo_final - t1.cantidad,
	t2.salidas = t2.salidas + t1.cantidad
	WHERE t1.idventa = p_idventa AND t2.idproducto = t1.idproducto
	AND t2.fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
	AND t2.fecha_cierre = LAST_DAY(CURDATE());

    UPDATE perecedero t2
    JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
    SET t2.cantidad_perecedero = t2.cantidad_perecedero - t1.cantidad
    WHERE t2.idproducto = t1.idproducto AND t2.fecha_vencimiento = t1.fecha_vence;

    UPDATE producto t2
    JOIN detalleventa t1 ON t1.idproducto = t2.idproducto
    SET t2.stock = t2.stock - t1.cantidad
    WHERE t2.idproducto = t1.idproducto;

    UPDATE venta SET
    estado = 1
    WHERE idventa = p_idventa;

	CALL sp_insert_caja_venta(p_total);


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_historico_caja` (IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10))  BEGIN
    IF (p_date = '' AND p_date2 = '') THEN
		SELECT * FROM caja ORDER BY fecha_apertura DESC;
	ELSE
		 SELECT * FROM caja WHERE fecha_apertura BETWEEN p_date AND p_date2
		 ORDER BY fecha_apertura DESC;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_imprimir_ticket` (IN `p_idventa` INT(11))  BEGIN


        DECLARE p_idmax int;
		
		DECLARE p_idcli int;
        DECLARE p_nombre_cliente varchar(175);
        DECLARE p_cedula_cliente varchar(50);
        DECLARE p_direccion_cliente varchar(100);
        DECLARE p_telefono_cliente varchar(8);
		
        DECLARE p_tipo_comprobante tinyint(1);
        DECLARE p_idparametro int;
        DECLARE p_empresa varchar(150);
        DECLARE p_propietario varchar(150);
        DECLARE p_direccion varchar(200);
        DECLARE p_numero_nit varchar(70);
        DECLARE p_numero_nrc varchar(70);
        DECLARE p_fecha_resolucion datetime;
        DECLARE p_numero_resolucion varchar(80);
        DECLARE p_serie varchar(175);
        DECLARE p_subtotal decimal(8,2);
        DECLARE p_exento decimal(8,2);
        DECLARE p_descuento decimal(8,2);
        DECLARE p_total decimal(8,2);
        DECLARE p_numero_productos decimal(8,2);
        DECLARE p_numero_comprobante INT;
        DECLARE p_empleado varchar(181);
        DECLARE p_numero_venta varchar(175);
        DECLARE p_fecha_venta datetime;
        DECLARE p_moneda varchar(35);
        DECLARE p_idcurrency int;
        DECLARE p_estado tinyint(1);
		
		DECLARE p_sonletras varchar(150);
		DECLARE p_retenido decimal(12,2);
		DECLARE p_sumas decimal(12,2);
        DECLARE p_iva decimal(12,2);


         DECLARE p_tipo_pago varchar(75);
		 DECLARE p_pago_efectivo decimal(8,2);
         DECLARE p_pago_tarjeta decimal(8,2);
         DECLARE p_numero_tarjeta varchar(16);
         DECLARE p_tarjeta_habiente varchar(90);
         DECLARE p_cambio decimal(8,2);
	  
        SET time_zone = '-05:00';
        SET p_idmax = (SELECT MAX(idventa) FROM venta);
        SET p_idparametro = (SELECT MAX(idparametro) FROM parametro);
        SET p_idcurrency = (SELECT idcurrency FROM parametro WHERE idparametro = p_idparametro);
        SET p_empresa = (SELECT nombre_empresa FROM parametro);
        SET p_propietario = (SELECT propietario FROM parametro);
        SET p_direccion = (SELECT direccion_empresa FROM parametro);
        SET p_numero_nit = (SELECT numero_nit FROM parametro);
        SET p_numero_nrc = (SELECT numero_nrc FROM parametro);
        SET p_fecha_resolucion = (SELECT fecha_resolucion FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_numero_resolucion = (SELECT numero_resolucion FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_serie = (SELECT serie FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_moneda = (SELECT CurrencyName	FROM currency WHERE idcurrency = p_idcurrency);






		IF (p_idventa = '') THEN

        SET p_tipo_comprobante = (SELECT tipo_comprobante FROM venta WHERE idventa = p_idmax);
		SET p_subtotal = (SELECT (sumas + iva) as subtotal FROM venta WHERE idventa = p_idmax);
		SET p_exento = (SELECT exento FROM venta WHERE idventa = p_idmax);
		SET p_descuento = (SELECT descuento FROM venta WHERE idventa = p_idmax);
        SET p_total = (SELECT total FROM venta WHERE idventa = p_idmax);
        SET p_numero_productos = (SELECT SUM(cantidad) FROM detalleventa WHERE idventa = p_idmax);
        SET p_numero_comprobante = (SELECT numero_comprobante FROM venta WHERE idventa = p_idmax);
        SET p_empleado = (SELECT empleado FROM view_ventas WHERE idventa = p_idmax GROUP BY empleado);
        SET p_numero_venta = (SELECT numero_venta FROM venta WHERE idventa = p_idmax);
		SET p_fecha_venta = (SELECT fecha_venta FROM venta WHERE idventa = p_idmax);
		SET p_tipo_pago  = (SELECT tipo_pago FROM venta WHERE idventa = p_idmax);
		SET p_pago_efectivo  = (SELECT pago_efectivo FROM venta WHERE idventa = p_idmax);
        SET p_pago_tarjeta  = (SELECT pago_tarjeta FROM venta WHERE idventa = p_idmax);
        SET p_numero_tarjeta  = (SELECT numero_tarjeta FROM venta WHERE idventa = p_idmax);
        SET p_tarjeta_habiente  = (SELECT tarjeta_habiente FROM venta WHERE idventa = p_idmax);
        SET p_cambio = (SELECT cambio FROM venta WHERE idventa = p_idmax);
        SET p_estado = (SELECT estado FROM venta WHERE idventa = p_idmax);
		
		SET p_idcli = (SELECT idcliente FROM venta WHERE idventa = p_idmax);
        SET p_nombre_cliente = (SELECT nombre_cliente FROM cliente WHERE idcliente = p_idcli);
		SET p_cedula_cliente  = (SELECT numero_nit FROM cliente WHERE idcliente = p_idcli);
        SET p_direccion_cliente = (SELECT direccion_cliente FROM cliente WHERE idcliente = p_idcli);
        SET p_telefono_cliente = (SELECT numero_telefono FROM cliente WHERE idcliente = p_idcli);
		
		SET p_sumas = (SELECT sumas FROM venta WHERE idventa = p_idmax);
        SET p_iva  = (SELECT iva FROM venta WHERE idventa = p_idmax);
		SET p_retenido = (SELECT retenido FROM venta WHERE idventa = p_idmax);
		SET p_sonletras = (SELECT sonletras FROM venta WHERE idventa = p_idmax);

        SELECT p_tipo_comprobante,p_empresa, p_propietario, p_direccion, p_numero_nit , p_numero_nrc,
        DATE_FORMAT(p_fecha_resolucion,'%d/%m/%Y %k:%i %p')  as p_fecha_resolucion,p_numero_resolucion,
        p_serie, p_numero_comprobante,  p_subtotal, p_exento, p_descuento, p_total, p_numero_productos,
		p_empleado,DATE_FORMAT(p_fecha_venta,'%d/%m/%Y %k:%i %p') as p_fecha_venta ,p_numero_venta,
        p_tipo_pago, p_pago_efectivo, p_pago_tarjeta, p_numero_tarjeta, p_tarjeta_habiente, p_cambio,
        p_moneda,p_estado,p_nombre_cliente,p_cedula_cliente,p_direccion_cliente,p_telefono_cliente,p_sumas,p_iva,p_retenido, p_sonletras;

        ELSE

        SET p_tipo_comprobante = (SELECT tipo_comprobante FROM venta WHERE idventa = p_idventa);
		SET p_subtotal = (SELECT (sumas + iva) as subtotal FROM venta WHERE idventa = p_idventa);
		SET p_exento = (SELECT exento FROM venta WHERE idventa = p_idventa);
		SET p_descuento = (SELECT descuento FROM venta WHERE idventa = p_idventa);
        SET p_total = (SELECT total FROM venta WHERE idventa = p_idventa);
        SET p_numero_productos = (SELECT SUM(cantidad) FROM detalleventa WHERE idventa = p_idventa);
        SET p_numero_comprobante = (SELECT numero_comprobante FROM venta WHERE idventa = p_idventa);
        SET p_empleado = (SELECT empleado FROM view_ventas WHERE idventa =  p_idventa  GROUP BY empleado);
		SET p_numero_venta = (SELECT numero_venta FROM venta WHERE idventa = p_idventa);
		SET p_fecha_venta = (SELECT fecha_venta FROM venta WHERE idventa =  p_idventa);
		SET p_tipo_pago  = (SELECT tipo_pago FROM venta WHERE idventa = p_idventa);
		SET p_pago_efectivo  = (SELECT pago_efectivo FROM venta WHERE idventa =  p_idventa);
        SET p_pago_tarjeta  = (SELECT pago_tarjeta FROM venta WHERE idventa =  p_idventa);
        SET p_numero_tarjeta  = (SELECT numero_tarjeta FROM venta WHERE idventa =  p_idventa);
        SET p_tarjeta_habiente  = (SELECT tarjeta_habiente FROM venta WHERE idventa =  p_idventa);
        SET p_cambio = (SELECT cambio FROM venta WHERE idventa =  p_idventa);
        SET p_estado = (SELECT estado FROM venta WHERE idventa = p_idventa);
		
		SET p_idcli = (SELECT idcliente FROM venta WHERE idventa = p_idventa);
        SET p_nombre_cliente = (SELECT nombre_cliente FROM cliente WHERE idcliente = p_idcli);
		SET p_cedula_cliente  = (SELECT numero_nit FROM cliente WHERE idcliente = p_idcli);
        SET p_direccion_cliente = (SELECT direccion_cliente FROM cliente WHERE idcliente = p_idcli);
        SET p_telefono_cliente = (SELECT numero_telefono FROM cliente WHERE idcliente = p_idcli);
		
		SET p_sumas = (SELECT sumas FROM venta WHERE idventa = p_idventa);
        SET p_iva  = (SELECT iva FROM venta WHERE idventa = p_idventa);
		SET p_retenido = (SELECT retenido FROM venta WHERE idventa = p_idventa);
		SET p_sonletras = (SELECT sonletras FROM venta WHERE idventa = p_idventa);

        SELECT p_tipo_comprobante,p_empresa, p_propietario, p_direccion, p_numero_nit , p_numero_nrc,
        DATE_FORMAT(p_fecha_resolucion,'%d/%m/%Y %k:%i %p')  as p_fecha_resolucion,p_numero_resolucion,
        p_serie, p_numero_comprobante,  p_subtotal, p_exento, p_descuento, p_total, p_numero_productos,
		p_empleado,DATE_FORMAT(p_fecha_venta,'%d/%m/%Y %k:%i %p') as p_fecha_venta,p_numero_venta,
        p_tipo_pago, p_pago_efectivo, p_pago_tarjeta, p_numero_tarjeta, p_tarjeta_habiente, p_cambio,
        p_moneda,p_estado, p_nombre_cliente,p_cedula_cliente,p_direccion_cliente,p_telefono_cliente,p_sumas,p_iva,p_retenido, p_sonletras;

		END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_imprimir_ticket_abono` (IN `p_idabono` INT(11))  BEGIN


        DECLARE p_idmax int;
        DECLARE p_idparametro int;
        DECLARE p_empresa varchar(150);
        DECLARE p_propietario varchar(150);
        DECLARE p_direccion varchar(200);
        DECLARE p_numero_nit varchar(70);
        DECLARE p_numero_nrc varchar(70);
        DECLARE p_fecha_resolucion datetime;
        DECLARE p_numero_resolucion varchar(80);
        DECLARE p_serie varchar(175);
        DECLARE p_moneda varchar(35);
        DECLARE p_idcurrency int;
		DECLARE p_simbolo varchar(3);

		DECLARE p_idcredito int;
        DECLARE p_codigo_credito varchar(175);
        DECLARE p_monto_credito decimal(8,2);
        DECLARE p_monto_abonado decimal(8,2);
        DECLARE p_monto_restante decimal(8,2);
        DECLARE p_fecha_abono datetime;
        DECLARE p_monto_abono decimal(8,2);
        DECLARE p_total_abonado decimal(8,2);
        DECLARE p_restante_credito decimal(8,2);
        DECLARE p_cliente varchar(150);
        DECLARE p_usuario varchar(70);

        SET p_idmax = (SELECT MAX(idabono) FROM abono);
        SET p_idparametro = (SELECT MAX(idparametro) FROM parametro);
        SET p_idcurrency = (SELECT idcurrency FROM parametro WHERE idparametro = p_idparametro);
        SET p_empresa = (SELECT nombre_empresa FROM parametro);
        SET p_propietario = (SELECT propietario FROM parametro);
        SET p_direccion = (SELECT direccion_empresa FROM parametro);
        SET p_numero_nit = (SELECT numero_nit FROM parametro);
        SET p_numero_nrc = (SELECT numero_nrc FROM parametro);
        SET p_fecha_resolucion = (SELECT fecha_resolucion FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_numero_resolucion = (SELECT numero_resolucion FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_serie = (SELECT serie FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_moneda = (SELECT CurrencyName	FROM currency WHERE idcurrency = p_idcurrency);
		SET p_simbolo = (SELECT Symbol FROM currency WHERE idcurrency = p_idcurrency);




		IF (p_idabono = '') THEN

        SET p_idcredito = (SELECT idcredito FROM abono WHERE idabono = p_idmax);
        SET p_fecha_abono = (SELECT fecha_abono FROM abono where idabono = p_idmax);
        SET p_monto_abono = (SELECT monto_abono FROM abono where idabono = p_idmax);
        SET p_total_abonado = (SELECT total_abonado FROM abono where idabono = p_idmax);
        SET p_restante_credito = (SELECT restante_credito FROM abono where idabono = p_idmax);
        SET p_usuario = (SELECT usuario FROM view_abonos where idabono = p_idmax);
		SET p_codigo_credito = (SELECT codigo_credito FROM credito WHERE idcredito = p_idcredito);
        SET p_monto_credito = (SELECT monto_credito  FROM credito WHERE idcredito = p_idcredito);
        SET p_monto_abonado = (SELECT monto_abonado FROM credito WHERE idcredito = p_idcredito);
        SET p_monto_restante = (SELECT monto_restante FROM credito WHERE idcredito = p_idcredito);
        SET p_cliente = (SELECT cliente FROM view_creditos_venta WHERE idcredito = p_idcredito);


        SELECT p_empresa, p_propietario, p_direccion, p_numero_nit , p_numero_nrc,
        DATE_FORMAT(p_fecha_resolucion,'%d/%m/%Y %k:%i %p')  as p_fecha_resolucion,p_numero_resolucion,
        p_serie,p_fecha_abono,p_monto_abono,p_codigo_credito,p_monto_credito,p_monto_abonado,p_monto_restante,
        p_total_abonado,p_restante_credito,p_moneda,p_simbolo,p_cliente,p_usuario;

        ELSE

        SET p_idcredito = (SELECT idcredito FROM abono WHERE idabono = p_idabono);
        SET p_fecha_abono = (SELECT fecha_abono FROM abono where idabono = p_idabono);
        SET p_monto_abono = (SELECT monto_abono FROM abono where idabono = p_idabono);
		SET p_total_abonado = (SELECT total_abonado FROM abono where idabono = p_idabono);
        SET p_usuario = (SELECT usuario FROM view_abonos where idabono = p_idabono);
        SET p_restante_credito = (SELECT restante_credito FROM abono where idabono = p_idabono);
		SET p_codigo_credito = (SELECT codigo_credito FROM credito WHERE idcredito = p_idcredito);
        SET p_monto_credito = (SELECT monto_credito  FROM credito WHERE idcredito = p_idcredito);
        SET p_monto_abonado = (SELECT monto_abonado FROM credito WHERE idcredito = p_idcredito);
        SET p_monto_restante = (SELECT monto_restante FROM credito WHERE idcredito = p_idcredito);
        SET p_cliente = (SELECT cliente FROM view_creditos_venta WHERE idcredito = p_idcredito);

        SELECT p_empresa, p_propietario, p_direccion, p_numero_nit , p_numero_nrc,
        DATE_FORMAT(p_fecha_resolucion,'%d/%m/%Y %k:%i %p')  as p_fecha_resolucion,p_numero_resolucion,
        p_serie,p_fecha_abono,p_monto_abono,p_codigo_credito,p_monto_credito,p_monto_abonado,p_monto_restante,
        p_total_abonado,p_restante_credito,p_moneda,p_simbolo,p_cliente,p_usuario;

		END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_imprimir_ticket_abono_proveedor` (IN `p_idabonoproveedor` INT(11))  BEGIN


        DECLARE p_idmax int;
        DECLARE p_idparametro int;
        DECLARE p_empresa varchar(150);
        DECLARE p_propietario varchar(150);
        DECLARE p_direccion varchar(200);
        DECLARE p_numero_nit varchar(70);
        DECLARE p_numero_nrc varchar(70);
        DECLARE p_fecha_resolucion datetime;
        DECLARE p_numero_resolucion varchar(80);
        DECLARE p_serie varchar(175);
        DECLARE p_moneda varchar(35);
        DECLARE p_idcurrency int;
		DECLARE p_simbolo varchar(3);

		DECLARE p_idcreditoproveedor int;
        DECLARE p_codigo_credito varchar(175);
        DECLARE p_monto_credito decimal(8,2);
        DECLARE p_monto_abonado decimal(8,2);
        DECLARE p_monto_restante decimal(8,2);
        DECLARE p_fecha_abono datetime;
        DECLARE p_monto_abono decimal(8,2);
        DECLARE p_total_abonado decimal(8,2);
        DECLARE p_restante_credito decimal(8,2);
        DECLARE p_proveedor varchar(150);
        DECLARE p_usuario varchar(70);

        SET p_idmax = (SELECT MAX(idabonoproveedor) FROM abonoproveedor);
        SET p_idparametro = (SELECT MAX(idparametro) FROM parametro);
        SET p_idcurrency = (SELECT idcurrency FROM parametro WHERE idparametro = p_idparametro);
        SET p_empresa = (SELECT nombre_empresa FROM parametro);
        SET p_propietario = (SELECT propietario FROM parametro);
        SET p_direccion = (SELECT direccion_empresa FROM parametro);
        SET p_numero_nit = (SELECT numero_nit FROM parametro);
        SET p_numero_nrc = (SELECT numero_nrc FROM parametro);
        SET p_fecha_resolucion = (SELECT fecha_resolucion FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_numero_resolucion = (SELECT numero_resolucion FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_serie = (SELECT serie FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_moneda = (SELECT CurrencyName	FROM currency WHERE idcurrency = p_idcurrency);
		SET p_simbolo = (SELECT Symbol FROM currency WHERE idcurrency = p_idcurrency);




		IF (p_idabonoproveedor = '') THEN

        SET p_idcreditoproveedor = (SELECT idcreditoproveedor FROM abonoproveedor WHERE idabonoproveedor = p_idmax);
        SET p_fecha_abono = (SELECT fecha_abono FROM abonoproveedor where idabonoproveedor = p_idmax);
        SET p_monto_abono = (SELECT monto_abono FROM abonoproveedor where idabonoproveedor = p_idmax);
        SET p_total_abonado = (SELECT total_abonado FROM abonoproveedor where idabonoproveedor = p_idmax);
        SET p_restante_credito = (SELECT restante_credito FROM abonoproveedor where idabonoproveedor = p_idmax);
        SET p_usuario = (SELECT usuario FROM view_abonos_proveedor where idabonoproveedor = p_idmax);
		SET p_codigo_credito = (SELECT codigo_credito FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
        SET p_monto_credito = (SELECT monto_credito  FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
        SET p_monto_abonado = (SELECT monto_abonado FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
        SET p_monto_restante = (SELECT monto_restante FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
        SET p_proveedor = (SELECT proveedor FROM view_creditos_compra WHERE idcreditoproveedor = p_idcreditoproveedor);


        SELECT p_empresa, p_propietario, p_direccion, p_numero_nit , p_numero_nrc,
        DATE_FORMAT(p_fecha_resolucion,'%d/%m/%Y %k:%i %p')  as p_fecha_resolucion,p_numero_resolucion,
        p_serie,p_fecha_abono,p_monto_abono,p_codigo_credito,p_monto_credito,p_monto_abonado,p_monto_restante,
        p_total_abonado,p_restante_credito,p_moneda,p_simbolo,p_proveedor,p_usuario;

        ELSE

        SET p_idcreditoproveedor = (SELECT idcreditoproveedor FROM abonoproveedor WHERE idabonoproveedor = p_idabonoproveedor);
        SET p_fecha_abono = (SELECT fecha_abono FROM abonoproveedor where idabonoproveedor = p_idabonoproveedor);
        SET p_monto_abono = (SELECT monto_abono FROM abonoproveedor where idabonoproveedor = p_idabonoproveedor);
		SET p_total_abonado = (SELECT total_abonado FROM abonoproveedor where idabonoproveedor = p_idabonoproveedor);
        SET p_usuario = (SELECT usuario FROM view_abonos_proveedor where idabonoproveedor = p_idabonoproveedor);
        SET p_restante_credito = (SELECT restante_credito FROM abonoproveedor where idabonoproveedor = p_idabonoproveedor);
		SET p_codigo_credito = (SELECT codigo_credito FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
        SET p_monto_credito = (SELECT monto_credito  FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
        SET p_monto_abonado = (SELECT monto_abonado FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
        SET p_monto_restante = (SELECT monto_restante FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
        SET p_proveedor = (SELECT proveedor FROM view_creditos_compra WHERE idcreditoproveedor = p_idcreditoproveedor);


        SELECT p_empresa, p_propietario, p_direccion, p_numero_nit , p_numero_nrc,
        DATE_FORMAT(p_fecha_resolucion,'%d/%m/%Y %k:%i %p')  as p_fecha_resolucion,p_numero_resolucion,
        p_serie,p_fecha_abono,p_monto_abono,p_codigo_credito,p_monto_credito,p_monto_abonado,p_monto_restante,
        p_total_abonado,p_restante_credito,p_moneda,p_simbolo,p_proveedor,p_usuario;

		END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_imprimir_ticket_apartado` (IN `p_idapartado` INT(11))  BEGIN


        DECLARE p_idmax int;
        DECLARE p_idparametro int;
        DECLARE p_empresa varchar(150);
        DECLARE p_propietario varchar(150);
        DECLARE p_direccion varchar(200);
        DECLARE p_numero_nit varchar(70);
        DECLARE p_numero_nrc varchar(70);
        DECLARE p_fecha_resolucion datetime;
        DECLARE p_numero_resolucion varchar(80);
        DECLARE p_serie varchar(175);
        DECLARE p_subtotal decimal(8,2);
        DECLARE p_exento decimal(8,2);
        DECLARE p_descuento decimal(8,2);
        DECLARE p_total decimal(8,2);
        DECLARE p_numero_productos decimal(8,2);
        DECLARE p_empleado varchar(181);
        DECLARE p_numero_apartado varchar(175);
        DECLARE p_fecha_apartado datetime;
        DECLARE p_moneda varchar(35);
        DECLARE p_idcurrency int;
        DECLARE p_estado tinyint(1);

		DECLARE p_abonado_apartado decimal(8,2);
        DECLARE p_restante_pagar decimal(8,2);
		DECLARE p_fecha_limite_retiro datetime;
        DECLARE p_diferencia_fechas int;

        SET p_idmax = (SELECT MAX(idapartado) FROM apartado);
        SET p_idparametro = (SELECT MAX(idparametro) FROM parametro);
        SET p_idcurrency = (SELECT idcurrency FROM parametro WHERE idparametro = p_idparametro);
        SET p_empresa = (SELECT nombre_empresa FROM parametro);
        SET p_propietario = (SELECT propietario FROM parametro);
        SET p_direccion = (SELECT direccion_empresa FROM parametro);
        SET p_numero_nit = (SELECT numero_nit FROM parametro);
        SET p_numero_nrc = (SELECT numero_nrc FROM parametro);
        SET p_fecha_resolucion = (SELECT fecha_resolucion FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_numero_resolucion = (SELECT numero_resolucion FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_serie = (SELECT serie FROM tiraje_comprobante WHERE idcomprobante = 1);
        SET p_moneda = (SELECT CurrencyName	FROM currency WHERE idcurrency = p_idcurrency);



		IF (p_idapartado= '') THEN

		SET p_subtotal = (SELECT (sumas + iva) as subtotal FROM apartado WHERE idapartado= p_idmax);
		SET p_exento = (SELECT exento FROM apartado WHERE idapartado= p_idmax);
		SET p_descuento = (SELECT descuento FROM apartado WHERE idapartado= p_idmax);
		SET p_total = (SELECT total FROM apartado WHERE idapartado= p_idmax);
		SET p_numero_productos = (SELECT SUM(cantidad) FROM detalleapartado WHERE idapartado= p_idmax);
		SET p_empleado = (SELECT empleado FROM view_apartados WHERE idapartado= p_idmax GROUP BY empleado);
		SET p_numero_apartado = (SELECT numero_apartado FROM apartado WHERE idapartado= p_idmax);
		SET p_fecha_apartado = (SELECT fecha_apartado FROM apartado WHERE idapartado= p_idmax);
		SET p_abonado_apartado  = (SELECT abonado_apartado FROM apartado WHERE idapartado= p_idmax);
		SET p_restante_pagar  = (SELECT restante_pagar FROM apartado WHERE idapartado= p_idmax);
		SET p_fecha_limite_retiro = (SELECT fecha_limite_retiro	 FROM apartado WHERE idapartado= p_idmax);
		SET p_estado = (SELECT estado FROM apartado WHERE idapartado= p_idmax);
        SET p_diferencia_fechas = (SELECT DATEDIFF(p_fecha_limite_retiro, p_fecha_apartado));


        SELECT p_empresa, p_propietario, p_direccion, p_numero_nit , p_numero_nrc,
        DATE_FORMAT(p_fecha_resolucion,'%d/%m/%Y %k:%i %p')  as p_fecha_resolucion,p_numero_resolucion,
        p_serie, p_subtotal, p_exento, p_descuento, p_total, p_numero_productos,
		p_empleado,DATE_FORMAT(p_fecha_apartado,'%d/%m/%Y %k:%i %p') as p_fecha_apartado ,p_numero_apartado,
      	p_fecha_limite_retiro, p_restante_pagar ,p_abonado_apartado,p_moneda,p_estado,p_diferencia_fechas;

        ELSE

		SET p_subtotal = (SELECT (sumas + iva) as subtotal FROM apartado WHERE idapartado= p_idapartado);
		SET p_exento = (SELECT exento FROM apartado WHERE idapartado= p_idapartado);
		SET p_descuento = (SELECT descuento FROM apartado WHERE idapartado= p_idapartado);
        SET p_total = (SELECT total FROM apartado WHERE idapartado= p_idapartado);
        SET p_numero_productos = (SELECT SUM(cantidad) FROM detalleapartado WHERE idapartado= p_idapartado);
        SET p_empleado = (SELECT empleado FROM view_apartados WHERE idapartado=  p_idapartado GROUP BY empleado);
		SET p_numero_apartado = (SELECT numero_apartado FROM apartado WHERE idapartado= p_idapartado);
		SET p_fecha_apartado = (SELECT fecha_apartado FROM apartado WHERE idapartado=  p_idapartado);
		SET p_abonado_apartado  = (SELECT abonado_apartado FROM apartado WHERE idapartado= p_idapartado);
		SET p_restante_pagar  = (SELECT restante_pagar FROM apartado WHERE idapartado= p_idapartado);
		SET p_fecha_limite_retiro = (SELECT fecha_limite_retiro	 FROM apartado WHERE idapartado= p_idapartado);
        SET p_estado = (SELECT estado FROM apartado WHERE idapartado= p_idapartado);
		SET p_diferencia_fechas = (SELECT DATEDIFF(p_fecha_limite_retiro, p_fecha_apartado));

		SELECT p_empresa, p_propietario, p_direccion, p_numero_nit , p_numero_nrc,
        DATE_FORMAT(p_fecha_resolucion,'%d/%m/%Y %k:%i %p')  as p_fecha_resolucion,p_numero_resolucion,
        p_serie,  p_subtotal, p_exento, p_descuento, p_total, p_numero_productos,
		p_empleado,DATE_FORMAT(p_fecha_apartado,'%d/%m/%Y %k:%i %p') as p_fecha_apartado ,p_numero_apartado,
      	p_fecha_limite_retiro, p_restante_pagar ,p_abonado_apartado,p_moneda,p_estado,p_diferencia_fechas;

		END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_abono` (IN `p_idcredito` INT(11), IN `p_monto_abono` DECIMAL(8,2), IN `p_idusuario` INT(11))  BEGIN
DECLARE p_codigo_credito varchar(175);
DECLARE p_monto_restante DECIMAL(8,2);
DECLARE p_resta_montos DECIMAL(8,2);
DECLARE p_monto_abonado DECIMAL(8,2);
DECLARE p_idventa int;

SET p_monto_restante = (SELECT monto_restante FROM credito WHERE idcredito = p_idcredito);
SET p_resta_montos = (p_monto_restante - p_monto_abono);
SET p_idventa = (SELECT idventa FROM credito WHERE idcredito = p_idcredito);
SET p_codigo_credito = (SELECT codigo_credito FROM credito WHERE idcredito = p_idcredito);

IF p_resta_montos = 0 THEN

	UPDATE credito SET
	monto_restante = 0.00,
    monto_abonado = monto_abonado + p_monto_abono,
    estado = 1
	WHERE idcredito = p_idcredito;

    SET p_monto_abonado = (SELECT monto_abonado FROM credito WHERE idcredito = p_idcredito);

    CALL sp_insert_caja_movimiento(1,p_monto_abono,(CONCAT('POR ABONO A CREDITO',' ',p_codigo_credito)));

    INSERT INTO `abono`(`idcredito`, `fecha_abono`, `monto_abono`, `total_abonado`,`restante_credito`,`idusuario`)
	VALUES (p_idcredito, NOW(), p_monto_abono,p_monto_abonado, 0.00,p_idusuario);

ELSEIF p_resta_montos > 0 THEN
	UPDATE credito SET
	monto_restante = p_resta_montos,
    monto_abonado = monto_abonado + p_monto_abono
	WHERE idcredito = p_idcredito;

	SET p_monto_abonado = (SELECT monto_abonado FROM credito WHERE idcredito = p_idcredito);

	    CALL sp_insert_caja_movimiento(1,p_monto_abono,(CONCAT('POR ABONO A CREDITO',' ',p_codigo_credito)));

    INSERT INTO `abono`(`idcredito`, `fecha_abono`, `monto_abono`, `total_abonado`,`restante_credito`,`idusuario`)
	VALUES (p_idcredito, NOW(), p_monto_abono,p_monto_abonado, p_resta_montos,p_idusuario);

END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_abono_proveedor` (IN `p_idcreditoproveedor` INT(11), IN `p_monto_abono` DECIMAL(8,2), IN `p_idusuario` INT(11))  BEGIN
DECLARE p_codigo_credito varchar(175);
DECLARE p_monto_restante DECIMAL(8,2);
DECLARE p_resta_montos DECIMAL(8,2);
DECLARE p_monto_abonado DECIMAL(8,2);
DECLARE p_idcompra int;
SET time_zone = '-05:00';


SET p_monto_restante = (SELECT monto_restante FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
SET p_resta_montos = (p_monto_restante - p_monto_abono);
SET p_idcompra = (SELECT idcompra FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);
SET p_codigo_credito = (SELECT codigo_credito FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);

IF p_resta_montos = 0 THEN

	UPDATE creditoproveedor SET
	monto_restante = 0.00,
    monto_abonado = monto_abonado + p_monto_abono,
    estado = 1
	WHERE idcreditoproveedor = p_idcreditoproveedor;

    SET p_monto_abonado = (SELECT monto_abonado FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);

    -- CALL sp_insert_caja_movimiento(1,p_monto_abono,(CONCAT('POR ABONO A CREDITO',' ',p_codigo_credito)));

    INSERT INTO `abonoproveedor`(`idcreditoproveedor`, `fecha_abono`, `monto_abono`, `total_abonado`,`restante_credito`,`idusuario`)
	VALUES (p_idcreditoproveedor, NOW(), p_monto_abono,p_monto_abonado, 0.00,p_idusuario);

ELSEIF p_resta_montos > 0 THEN
	UPDATE creditoproveedor SET
	monto_restante = p_resta_montos,
    monto_abonado = monto_abonado + p_monto_abono
	WHERE idcreditoproveedor = p_idcreditoproveedor;

	SET p_monto_abonado = (SELECT monto_abonado FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor);

	-- CALL sp_insert_caja_movimiento(1,p_monto_abono,(CONCAT('POR ABONO A CREDITO',' ',p_codigo_credito)));

    INSERT INTO `abonoproveedor`(`idcreditoproveedor`, `fecha_abono`, `monto_abono`, `total_abonado`,`restante_credito`,`idusuario`)
	VALUES (p_idcreditoproveedor, NOW(), p_monto_abono,p_monto_abonado, p_resta_montos,p_idusuario);

END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_apartado` (IN `p_fecha_limite_retiro` DATETIME, IN `p_sumas` DECIMAL(8,2), IN `p_iva` DECIMAL(8,2), IN `p_exento` DECIMAL(8,2), IN `p_retenido` DECIMAL(8,2), IN `p_descuento` DECIMAL(8,2), IN `p_total` DECIMAL(8,2), IN `p_abonado_apartado` DECIMAL(8,2), IN `p_restante_pagar` DECIMAL(8,2), IN `p_sonletras` VARCHAR(150), IN `p_idcliente` INT(11), IN `p_idusuario` INT(11))  BEGIN
    SET time_zone = '-05:00';
	INSERT INTO `apartado`(`fecha_apartado`,
	`fecha_limite_retiro`, `sumas`, `iva`, `exento`, `retenido`, `descuento`,
	`total`, `abonado_apartado`, `restante_pagar`, `sonletras`,`idcliente`, `idusuario`)
	VALUES (NOW(), p_fecha_limite_retiro,
	p_sumas, p_iva, p_exento, p_retenido, p_descuento, p_total, p_abonado_apartado,
	p_restante_pagar, p_sonletras, p_idcliente, p_idusuario);

    CALL sp_insert_caja_apartado(p_abonado_apartado);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_caja_apartado` (IN `p_monto_movimiento` DECIMAL(8,2))  BEGIN

	
    DECLARE p_idcaja int(11);
    DECLARE p_descripcion_movimiento varchar(80);
    DECLARE p_numero_apartado varchar(175);

    SET p_numero_apartado = (SELECT max(numero_apartado) FROM apartado);
    SET p_idcaja = (SELECT idcaja FROM `caja` WHERE DATE(fecha_apertura) = CURDATE());
	SET p_descripcion_movimiento = (CONCAT('POR APARTADO #',' ',p_numero_apartado));

	INSERT INTO `caja_movimiento`(`idcaja`, `tipo_movimiento`, `monto_movimiento`,
    `descripcion_movimiento`,`fecha_movimiento`) VALUES (p_idcaja, 1, p_monto_movimiento,
	 p_descripcion_movimiento,curdate());

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_caja_movimiento` (IN `p_tipo_movimiento` TINYINT(1), IN `p_monto_movimiento` DECIMAL(8,2), IN `p_descripcion_movimiento` VARCHAR(80))  BEGIN

    DECLARE p_idcaja int(11);
    DECLARE p_tipo_comprobante tinyint(1);
    DECLARE p_numero_comprobante int(11);
	SET time_zone = '-05:00';

    SET p_idcaja = (SELECT idcaja FROM `caja` WHERE DATE(fecha_apertura) <= CURDATE() AND estado = 1);


	INSERT INTO `caja_movimiento`(`idcaja`, `tipo_movimiento`, `monto_movimiento`,
    `descripcion_movimiento`,`fecha_movimiento`) VALUES (p_idcaja, p_tipo_movimiento, p_monto_movimiento,
     p_descripcion_movimiento,curdate());


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_caja_venta` (IN `p_monto_movimiento` DECIMAL(8,2))  BEGIN
	DECLARE p_idventa int(11);
    DECLARE p_idcaja int(11);
    DECLARE p_tipo_comprobante tinyint(1);
    DECLARE p_numero_comprobante int(11);
    DECLARE p_descripcion_movimiento varchar(80);
    DECLARE p_monto_movimiento_tarjeta DECIMAL(8,2);
    
	SET time_zone = '-05:00';

    SET p_idventa = (SELECT max(idventa) FROM venta);
    SET p_idcaja = (SELECT idcaja FROM `caja` WHERE DATE(fecha_apertura) <= CURDATE() AND estado=1);
    SET p_tipo_comprobante = (SELECT tipo_comprobante FROM `venta` WHERE idventa = p_idventa);
    SET p_numero_comprobante = (SELECT numero_comprobante FROM `venta` WHERE idventa = p_idventa);
    
    SET p_monto_movimiento_tarjeta=(SELECT pago_tarjeta FROM `venta` WHERE idventa=p_idventa);
    

    IF p_tipo_comprobante = 1 THEN
	SET p_descripcion_movimiento = (CONCAT('POR VENTA',' ','TICKET', ' # ',p_numero_comprobante));
	INSERT INTO `caja_movimiento`(`idcaja`, `tipo_movimiento`, `monto_movimiento`,
    `descripcion_movimiento`,`fecha_movimiento`,`monto_movimiento_tarjeta`) VALUES (p_idcaja, 1, p_monto_movimiento,
	p_descripcion_movimiento,curdate(),p_monto_movimiento_tarjeta);
	ELSEIF p_tipo_comprobante = 2 THEN
     SET p_descripcion_movimiento = (CONCAT('POR VENTA',' ','BOLETA', ' # ',p_numero_comprobante));
	INSERT INTO `caja_movimiento`(`idcaja`, `tipo_movimiento`, `monto_movimiento`,
    `descripcion_movimiento`,`fecha_movimiento`,`monto_movimiento_tarjeta`) VALUES (p_idcaja, 1, p_monto_movimiento,
	p_descripcion_movimiento,curdate(),p_monto_movimiento_tarjeta);
	ELSEIF p_tipo_comprobante = 3 THEN
     SET p_descripcion_movimiento = (CONCAT('POR VENTA',' ','FACTURA', ' # ',p_numero_comprobante));
	INSERT INTO `caja_movimiento`(`idcaja`, `tipo_movimiento`, `monto_movimiento`,
    `descripcion_movimiento`,`fecha_movimiento`,`monto_movimiento_tarjeta`) VALUES (p_idcaja,1, p_monto_movimiento,
	p_descripcion_movimiento,curdate(),p_monto_movimiento_tarjeta);
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_categoria` (IN `p_nombre_categoria` VARCHAR(120))  BEGIN
    IF NOT EXISTS (SELECT * FROM `categoria` WHERE `nombre_categoria` = p_nombre_categoria) THEN
		INSERT INTO `categoria`(`nombre_categoria`)
		VALUES (p_nombre_categoria);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_cliente` (IN `p_nombre_cliente` VARCHAR(150), IN `p_numero_nit` VARCHAR(70), IN `p_numero_nrc` VARCHAR(45), IN `p_direccion_cliente` VARCHAR(100), IN `p_numero_telefono` VARCHAR(70), IN `p_email` VARCHAR(80), IN `p_giro` VARCHAR(80), IN `p_limite_credito` DECIMAL(8,2))  BEGIN
	IF NOT EXISTS (SELECT * FROM `cliente` WHERE `nombre_cliente` = p_nombre_cliente) THEN
			INSERT INTO `cliente`(`nombre_cliente`, `numero_nit`,
			`numero_nrc`, `direccion_cliente`, `numero_telefono`, `email`, `giro`,
			`limite_credito`)
			VALUES (p_nombre_cliente, p_numero_nit,
			p_numero_nrc, p_direccion_cliente, p_numero_telefono, p_email, p_giro,
			p_limite_credito);
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_compra` (IN `p_fecha_compra` DATETIME, IN `p_idproveedor` INT(11), IN `p_tipo_pago` VARCHAR(75), IN `p_numero_comprobante` VARCHAR(60), IN `p_tipo_comprobante` VARCHAR(60), IN `p_fecha_comprobante` DATE, IN `p_sumas` DECIMAL(8,2), IN `p_iva` DECIMAL(8,2), IN `p_exento` DECIMAL(8,2), IN `p_retenido` DECIMAL(8,2), IN `p_total` DECIMAL(8,2), IN `p_sonletras` VARCHAR(150))  BEGIN
   IF NOT EXISTS (SELECT * FROM `compra` WHERE `fecha_comprobante` = p_fecha_comprobante
   AND `numero_comprobante` = p_numero_comprobante) THEN
		INSERT INTO `compra`(`fecha_compra`, `idproveedor`, `tipo_pago`,
		`numero_comprobante`, `tipo_comprobante`, `fecha_comprobante`, `sumas`,
		`iva`, `exento`, `retenido`, `total`,`sonletras`)
		VALUES (p_fecha_compra, p_idproveedor, p_tipo_pago,
		p_numero_comprobante, p_tipo_comprobante, p_fecha_comprobante, p_sumas,
		p_iva, p_exento, p_retenido, p_total, p_sonletras);
   END IF;
   if p_tipo_pago = '2' then
    call sp_insert_credito_compra(p_total,p_idproveedor);
   end if;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_comprobante` (IN `p_nombre_comprobante` VARCHAR(75))  BEGIN
   IF NOT EXISTS (SELECT * FROM `comprobante` WHERE `nombre_comprobante` = p_nombre_comprobante) THEN
	INSERT INTO `comprobante`(`nombre_comprobante`)
	VALUES (p_nombre_comprobante);
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_cotizacion` (IN `p_a_nombre` VARCHAR(175), IN `p_tipo_pago` VARCHAR(60), IN `p_entrega` VARCHAR(60), IN `p_sumas` DECIMAL(8,2), IN `p_iva` DECIMAL(8,2), IN `p_exento` DECIMAL(8,2), IN `p_retenido` DECIMAL(8,2), IN `p_descuento` DECIMAL(8,2), IN `p_total` DECIMAL(8,2), IN `p_sonletras` VARCHAR(150), IN `p_idusuario` INT(11), IN `p_idcliente` INT(11))  BEGIN
INSERT INTO `cotizacion`(`fecha_cotizacion`, `a_nombre`,
`tipo_pago`, `entrega`, `sumas`, `iva`,
`exento`, `retenido`, `descuento`, `total`,
`sonletras`,`idusuario`,`idcliente`)
VALUES (NOW(), p_a_nombre,
p_tipo_pago, p_entrega, p_sumas, p_iva,
p_exento, p_retenido, p_descuento, p_total,
p_sonletras, p_idusuario,p_idcliente);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_credito_compra` (IN `p_monto_credito` DECIMAL(8,2), IN `p_idproveedor` INT(11))  BEGIN

    DECLARE p_idcompra int(11);
    DECLARE p_numero_compra varchar(175);
	DECLARE p_nombre_credito varchar(120);
	DECLARE p_idcredito INT;

    SET p_idcompra = (SELECT MAX(idcompra) FROM compra);
    SET p_numero_compra = (SELECT numero_comprobante FROM compra WHERE idcompra = p_idcompra);
    SET p_nombre_credito = (CONCAT('POR COMPRA #',' ',p_numero_compra));
    SET p_idcredito = (SELECT MAX(idcreditoproveedor) FROM creditoproveedor);

	INSERT INTO `creditoproveedor`(`idcompra`, `nombre_credito`, `fecha_credito`,
	`monto_credito`,`monto_abonado`,`monto_restante`,`idproveedor`)
	VALUES (p_idcompra, p_nombre_credito, NOW(),p_monto_credito,
    0.00,p_monto_credito,p_idproveedor);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_credito_venta` (IN `p_monto_credito` DECIMAL(8,2), IN `p_idcliente` INT(11))  BEGIN

    DECLARE p_idventa int(11);
    DECLARE p_numero_venta varchar(175);
	DECLARE p_nombre_credito varchar(120);
	DECLARE p_idcredito INT;

    SET p_idventa = (SELECT MAX(idventa) FROM venta);
    SET p_numero_venta = (SELECT numero_venta FROM venta WHERE idventa = p_idventa);
    SET p_nombre_credito = (CONCAT('POR VENTA #',' ',p_numero_venta));
    SET p_idcredito = (SELECT MAX(idcredito) FROM credito);

	INSERT INTO `credito`(`idventa`, `nombre_credito`, `fecha_credito`,
	`monto_credito`,`monto_abonado`,`monto_restante`,`idcliente`)
	VALUES (p_idventa, p_nombre_credito, NOW(),p_monto_credito,
    0.00,p_monto_credito,p_idcliente);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_currency` (IN `p_CurrencyISO` VARCHAR(3), IN `p_Language` VARCHAR(3), IN `p_CurrencyName` VARCHAR(35), IN `p_Money` VARCHAR(30), IN `p_Symbol` VARCHAR(3))  BEGIN
IF NOT EXISTS (SELECT * FROM `currency` WHERE `CurrencyName` = p_CurrencyName) THEN
		INSERT INTO `currency`(`CurrencyISO`, `Language`, `CurrencyName`, 
		`Money`, `Symbol`) 
		VALUES (p_CurrencyISO, p_Language, p_CurrencyName, 
		p_Money, p_Symbol);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_detalleapartado` (IN `p_idproducto` INT(11), IN `p_cantidad` DECIMAL(8,2), IN `p_precio_unitario` DECIMAL(8,2), IN `p_exento` DECIMAL(8,2), IN `p_descuento` DECIMAL(8,2), IN `p_fecha_vence` DATE, IN `p_importe` DECIMAL(8,2))  BEGIN

	DECLARE p_idapartado int(11);
    DECLARE p_numero_apartado VARCHAR(175);
    DECLARE p_precio_compra DECIMAL(8,2);
    DECLARE p_costo DECIMAL(8,2);
    DECLARE p_total DECIMAL(8,2);
    DECLARE p_descr_salida varchar(150);
    DECLARE p_inventariable int(11);
    DECLARE	p_estado tinyint(1);
    DECLARE p_stock DECIMAL(8,2);
    DECLARE p_cantidad_perecedero DECIMAL(8,2);


    SET p_idapartado = (SELECT MAX(idapartado) FROM apartado);
    SET p_total = (SELECT total FROM apartado WHERE idapartado = p_idapartado);
    SET p_precio_compra = (SELECT precio_compra FROM producto WHERE idproducto = p_idproducto);
    SET p_numero_apartado = (SELECT numero_apartado FROM apartado WHERE idapartado = p_idapartado);
    SET p_costo = (p_cantidad * p_precio_compra);


    SET p_descr_salida = (CONCAT('POR APARTADO',' # ',p_numero_apartado));
    SET p_inventariable = (SELECT inventariable FROM producto WHERE idproducto = p_idproducto);
    SET p_estado = (SELECT estado FROM apartado WHERE idapartado = p_idapartado);
    SET p_cantidad_perecedero = (SELECT cantidad_perecedero FROM perecedero WHERE idproducto = p_idproducto
    AND fecha_vencimiento = p_fecha_vence AND estado = 1);
    SET p_stock = (SELECT stock FROM producto WHERE idproducto = p_idproducto);

		IF (p_inventariable  = 0) THEN

			IF p_idapartado IS NULL OR p_idapartado= '' THEN

				INSERT INTO `detalleapartado`(`idapartado`, `idproducto`, `cantidad`, `precio_unitario`,
				`fecha_vence`, `exento`, `descuento`, `importe`)
				VALUES (1, p_idproducto, p_cantidad, p_precio_unitario,
				p_fecha_vence, p_exento, p_descuento, p_importe);


				ELSE

				INSERT INTO `detalleapartado`(`idapartado`, `idproducto`, `cantidad`, `precio_unitario`,
				`fecha_vence`, `exento`, `descuento`, `importe`)
				VALUES (p_idapartado, p_idproducto, p_cantidad, p_precio_unitario,
				p_fecha_vence, p_exento, p_descuento, p_importe);

			END IF; -- IF p_idapartadoIS NULL OR p_idapartado= '' THEN


		ELSE -- ELSE p_inventariable  = 0

			IF (p_fecha_vence != '2000-01-01') THEN

				IF p_idapartado IS NULL OR p_idapartado= '' THEN

                    IF (p_stock > 0) THEN

							INSERT INTO `detalleapartado`(`idapartado`, `idproducto`, `cantidad`, `precio_unitario`,
							`fecha_vence`, `exento`, `descuento`, `importe`)
							VALUES (1, p_idproducto, p_cantidad, p_precio_unitario,
							p_fecha_vence, p_exento, p_descuento, p_importe);

							INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
							`precio_unitario_salida`, `costo_total_salida`,`idproducto`,`idapartado`)
							VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_salida,p_cantidad,p_precio_compra,p_costo,p_idproducto,1);

							UPDATE `inventario` SET
							`saldo_final` = `saldo_final` - p_cantidad,
							`salidas` = `salidas` + p_cantidad
							WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
							AND fecha_cierre = LAST_DAY(CURDATE());

							CALL sp_descontar_perecedero(p_idproducto, p_cantidad, p_fecha_vence);

							UPDATE `producto` SET
							`stock` = `stock` - p_cantidad
							WHERE idproducto = p_idproducto;

                    END IF; -- IF p_stock > 0;

			ELSE -- ELSE p_idapartado IS NULL OR p_idapartado= ''

					 IF (p_stock > 0) THEN

							INSERT INTO `detalleapartado`(`idapartado`, `idproducto`, `cantidad`, `precio_unitario`,
							`fecha_vence`, `exento`, `descuento`, `importe`)
							VALUES (p_idapartado, p_idproducto, p_cantidad, p_precio_unitario,
							p_fecha_vence, p_exento, p_descuento, p_importe);

							INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
							`precio_unitario_salida`, `costo_total_salida`,`idproducto`,`idapartado`)
							VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_salida,p_cantidad,p_precio_compra,p_costo,p_idproducto,p_idapartado);

							UPDATE `inventario` SET
							`saldo_final` = `saldo_final` - p_cantidad,
							`salidas` = `salidas` + p_cantidad
							WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
							AND fecha_cierre = LAST_DAY(CURDATE());

							CALL sp_descontar_perecedero(p_idproducto, p_cantidad, p_fecha_vence);

							UPDATE `producto` SET
							`stock` = `stock` - p_cantidad
							WHERE idproducto = p_idproducto;

						END IF; -- IF p_stock > 0;

					END IF; -- IF p_idapartadoIS NULL OR p_idapartado= ''

				ELSE  -- ELSE p_fecha_vencimiento != '2000-01-01'

                IF p_idapartado IS NULL OR p_idapartado= '' THEN

                    IF (p_stock > 0) THEN

                            INSERT INTO `detalleapartado`(`idapartado`, `idproducto`, `cantidad`, `precio_unitario`,
							`fecha_vence`, `exento`, `descuento`, `importe`)
							VALUES (1, p_idproducto, p_cantidad, p_precio_unitario,
							NULL, p_exento, p_descuento, p_importe);

							INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
							`precio_unitario_salida`, `costo_total_salida`,`idproducto`,`idapartado`)
							VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_salida,p_cantidad,p_precio_compra,p_costo,p_idproducto,1);

							UPDATE `inventario` SET
							`saldo_final` = `saldo_final` - p_cantidad,
							`salidas` = `salidas` + p_cantidad
							WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
							AND fecha_cierre = LAST_DAY(CURDATE());


							UPDATE `producto` SET
							`stock` = `stock` - p_cantidad
							WHERE idproducto = p_idproducto;

                    END IF; -- IF p_stock > 0;

			ELSE -- ELSE p_idapartadoIS NULL OR p_idapartado= ''

					 IF (p_stock > 0) THEN

							INSERT INTO `detalleapartado`(`idapartado`, `idproducto`, `cantidad`, `precio_unitario`,
							`fecha_vence`, `exento`, `descuento`, `importe`)
							VALUES (p_idapartado, p_idproducto, p_cantidad, p_precio_unitario,
							NULL, p_exento, p_descuento, p_importe);

							INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
							`precio_unitario_salida`, `costo_total_salida`,`idproducto`,`idapartado`)
							VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_salida,p_cantidad,p_precio_compra,p_costo,p_idproducto,p_idapartado);

							UPDATE `inventario` SET
							`saldo_final` = `saldo_final` - p_cantidad,
							`salidas` = `salidas` + p_cantidad
							WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
							AND fecha_cierre = LAST_DAY(CURDATE());


							UPDATE `producto` SET
							`stock` = `stock` - p_cantidad
							WHERE idproducto = p_idproducto;

						END IF; -- IF p_stock > 0;

					END IF; -- IF p_idapartadoIS NULL OR p_idapartado= ''

			END IF; -- IF p_fecha_vencimiento != '2000-01-01'

		END IF;  -- IF p_inventariable  = 0

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_detallecompra` (IN `p_idproducto` INT(11), IN `p_cantidad` DECIMAL(8,2), IN `p_precio_unitario` DECIMAL(8,2), IN `p_exento` DECIMAL(8,2), IN `p_fecha_vencimiento` DATE, IN `p_importe` DECIMAL(8,2))  BEGIN

	DECLARE p_idcompra int(11);
	DECLARE p_idproveedor int(11);
    DECLARE p_costo DECIMAL(8,2);
    DECLARE p_numero_comprobante varchar(60);
    DECLARE p_tipo_comprobante varchar(60);
    DECLARE p_descr_entrada varchar(150);
    DECLARE p_inventariable int(11);


    SET p_idcompra = (SELECT MAX(idcompra) FROM compra);
    SET p_idproveedor = (SELECT idproveedor FROM compra WHERE idcompra = p_idcompra);
    SET p_costo = (p_cantidad * p_precio_unitario);
    SET p_numero_comprobante = (SELECT numero_comprobante FROM compra WHERE idcompra = p_idcompra);
    SET p_tipo_comprobante = (SELECT tipo_comprobante FROM compra WHERE idcompra = p_idcompra);


    IF(p_tipo_comprobante = 1)THEN
		SET p_descr_entrada = (CONCAT('POR COMPRA',' TICKET # ',p_numero_comprobante));
	ELSEIF (p_tipo_comprobante = 2) THEN
		SET p_descr_entrada = (CONCAT('POR COMPRA',' FACTURA # ',p_numero_comprobante));
	ELSEIF (p_tipo_comprobante = 3) THEN
		SET p_descr_entrada = (CONCAT('POR COMPRA',' BOLETA # ',p_numero_comprobante));
    END IF;

    SET p_inventariable = (SELECT inventariable FROM producto WHERE idproducto = p_idproducto);


    IF (p_inventariable  = 0) THEN

	  IF p_idcompra IS NULL OR p_idcompra = '' THEN

		INSERT INTO `detallecompra`(`idcompra`, `idproducto`, `fecha_vence`, `cantidad`, `precio_unitario`,
		`exento`, `importe`)
		VALUES (1, p_idproducto, NULL ,p_cantidad, p_precio_unitario,
		p_exento, p_importe);

		INSERT INTO `proveedor_precio`(`idproveedor`, `idproducto`, `fecha_precio`, `precio_compra`)
		VALUES (p_idproveedor, p_idproducto, CURDATE(), p_precio_unitario);

		ELSE

		INSERT INTO `detallecompra`(`idcompra`, `idproducto`, `fecha_vence`, `cantidad`, `precio_unitario`,
		`exento`, `importe`)
		VALUES (p_idcompra, p_idproducto, NULL, p_cantidad, p_precio_unitario,
		p_exento, p_importe);


		INSERT INTO `proveedor_precio`(`idproveedor`, `idproducto`, `fecha_precio`, `precio_compra`)
		VALUES (p_idproveedor, p_idproducto, CURDATE(), p_precio_unitario);

		END IF;

    ELSE

    IF (p_fecha_vencimiento != '2000-01-01') THEN

        IF p_idcompra IS NULL OR p_idcompra = '' THEN

			INSERT INTO `detallecompra`(`idcompra`, `idproducto`, `fecha_vence`, `cantidad`, `precio_unitario`,
			`exento`, `importe`)
			VALUES (1, p_idproducto, p_fecha_vencimiento,  p_cantidad, p_precio_unitario,
			p_exento, p_importe);

			INSERT INTO `entrada`(`mes_inventario`,`fecha_entrada`, `descripcion_entrada`, `cantidad_entrada`,
			`precio_unitario_entrada`, `costo_total_entrada`,`idproducto`,`idcompra`)
			VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_entrada,p_cantidad,p_precio_unitario,p_costo,p_idproducto,1);

			INSERT INTO `proveedor_precio`(`idproveedor`, `idproducto`, `fecha_precio`, `precio_compra`)
			VALUES (p_idproveedor, p_idproducto, CURDATE(), p_precio_unitario);

			UPDATE `inventario` SET
			`saldo_final` = `saldo_final` + p_cantidad,
            `entradas` = `entradas` + p_cantidad
			WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
			AND fecha_cierre = LAST_DAY(CURDATE());

			IF NOT EXISTS (SELECT * FROM perecedero WHERE fecha_vencimiento = p_fecha_vencimiento
			AND idproducto = p_idproducto) THEN
				INSERT INTO `perecedero` (`fecha_vencimiento`, `cantidad_perecedero`, `idproducto`)
				VALUES (p_fecha_vencimiento,p_cantidad,p_idproducto);
			   ELSE
			   UPDATE `perecedero` SET
			   `cantidad_perecedero` = `cantidad_perecedero` + p_cantidad
			   WHERE `idproducto` = p_idproducto AND `fecha_vencimiento` = p_fecha_vencimiento;
			END IF;

			UPDATE `producto` SET
			`stock` = `stock` + p_cantidad
			WHERE idproducto = p_idproducto;

		ELSE

			INSERT INTO `detallecompra`(`idcompra`, `idproducto`, `fecha_vence`, `cantidad`, `precio_unitario`,
			`exento`, `importe`)
			VALUES (p_idcompra, p_idproducto, p_fecha_vencimiento, p_cantidad, p_precio_unitario,
			p_exento, p_importe);

			INSERT INTO `entrada`(`mes_inventario`,`fecha_entrada`, `descripcion_entrada`, `cantidad_entrada`,
			`precio_unitario_entrada`, `costo_total_entrada`,`idproducto`,`idcompra`)
			VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_entrada,p_cantidad,p_precio_unitario,p_costo,p_idproducto,p_idcompra);

			INSERT INTO `proveedor_precio`(`idproveedor`, `idproducto`, `fecha_precio`, `precio_compra`)
			VALUES (p_idproveedor, p_idproducto, CURDATE(), p_precio_unitario);

			UPDATE `inventario` SET
			`saldo_final` = `saldo_final` + p_cantidad,
            `entradas` = `entradas` + p_cantidad
			WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
			AND fecha_cierre = LAST_DAY(CURDATE());

			IF NOT EXISTS (SELECT * FROM perecedero WHERE fecha_vencimiento = p_fecha_vencimiento
			AND idproducto = p_idproducto) THEN
				INSERT INTO `perecedero` (`fecha_vencimiento`, `cantidad_perecedero`, `idproducto`)
				VALUES (p_fecha_vencimiento,p_cantidad,p_idproducto);
			   ELSE
			   UPDATE `perecedero` SET
			   `cantidad_perecedero` = `cantidad_perecedero` + p_cantidad
			   WHERE `idproducto` = p_idproducto AND `fecha_vencimiento` = p_fecha_vencimiento;
			END IF;


			UPDATE `producto` SET
			`stock` = `stock` + p_cantidad
			WHERE idproducto = p_idproducto;

			END IF;

	ELSE

		IF p_idcompra IS NULL OR p_idcompra = '' THEN

		INSERT INTO `detallecompra`(`idcompra`, `idproducto`, `fecha_vence`, `cantidad`, `precio_unitario`,
		`exento`, `importe`)
		VALUES (1, p_idproducto, NULL, p_cantidad, p_precio_unitario,
		p_exento, p_importe);

		INSERT INTO `entrada`(`mes_inventario`,`fecha_entrada`, `descripcion_entrada`, `cantidad_entrada`,
		`precio_unitario_entrada`, `costo_total_entrada`,`idproducto`,`idcompra`)
		VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_entrada,p_cantidad,p_precio_unitario,p_costo,p_idproducto,1);

		INSERT INTO `proveedor_precio`(`idproveedor`, `idproducto`, `fecha_precio`, `precio_compra`)
		VALUES (p_idproveedor, p_idproducto, CURDATE(), p_precio_unitario);

		UPDATE `inventario` SET
		`saldo_final` = `saldo_final` + p_cantidad,
		`entradas` = `entradas` + p_cantidad
		WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND fecha_cierre = LAST_DAY(CURDATE());

		UPDATE `producto` SET
		`stock` = `stock` + p_cantidad
		WHERE idproducto = p_idproducto;

		ELSE

		INSERT INTO `detallecompra`(`idcompra`, `idproducto`, `fecha_vence`, `cantidad`, `precio_unitario`,
		`exento`, `importe`)
		VALUES (p_idcompra, p_idproducto, NULL, p_cantidad, p_precio_unitario,
		p_exento, p_importe);

		INSERT INTO `entrada`(`mes_inventario`,`fecha_entrada`, `descripcion_entrada`, `cantidad_entrada`,
		`precio_unitario_entrada`, `costo_total_entrada`,`idproducto`,`idcompra`)
		VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_entrada,p_cantidad,p_precio_unitario,p_costo,p_idproducto,p_idcompra);


		INSERT INTO `proveedor_precio`(`idproveedor`, `idproducto`, `fecha_precio`, `precio_compra`)
		VALUES (p_idproveedor, p_idproducto, CURDATE(), p_precio_unitario);

		UPDATE `inventario` SET
		`saldo_final` = `saldo_final` + p_cantidad,
		`entradas` = `entradas` + p_cantidad
		WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
		AND fecha_cierre = LAST_DAY(CURDATE());

		UPDATE `producto` SET
		`stock` = `stock` + p_cantidad
		WHERE idproducto = p_idproducto;

		END IF;

	 END IF;

    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_detallecotizacion` (IN `p_idproducto` INT(11), IN `p_cantidad` DECIMAL(8,2), IN `p_disponible` TINYINT(1), IN `p_precio_unitario` DECIMAL(8,2), IN `p_exento` DECIMAL(8,2), IN `p_descuento` DECIMAL(8,2), IN `p_importe` DECIMAL(8,2))  BEGIN
	DECLARE p_idcotizacion int(11);
	SET p_idcotizacion  = (SELECT MAX(idcotizacion) FROM cotizacion);

    IF p_idcotizacion IS NULL OR p_idcotizacion = '' THEN
		INSERT INTO `detallecotizacion`(`idcotizacion`, `idproducto`, `cantidad`, `disponible`,
        `precio_unitario`, `exento`, `descuento`, `importe`)
		VALUES (1, p_idproducto, p_cantidad, p_disponible, p_precio_unitario,
		p_exento, p_descuento, p_importe);
	ELSE
		INSERT INTO `detallecotizacion`(`idcotizacion`, `idproducto`, `cantidad`, `disponible`,
        `precio_unitario`,
		`exento`, `descuento`, `importe`)
		VALUES (p_idcotizacion, p_idproducto, p_cantidad, p_disponible, p_precio_unitario,
		p_exento, p_descuento, p_importe);

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_detalleventa` (IN `p_idproducto` INT(11), IN `p_cantidad` DECIMAL(8,2), IN `p_precio_unitario` DECIMAL(8,2), IN `p_exento` DECIMAL(8,2), IN `p_descuento` DECIMAL(8,2), IN `p_fecha_vence` DATE, IN `p_importe` DECIMAL(8,2))  BEGIN

	DECLARE p_idventa int(11);
    DECLARE p_idcomprobante int(11);
    DECLARE p_tipo_comprobante TINYINT(1);
	DECLARE p_comprobante	varchar(75);
    DECLARE p_precio_compra DECIMAL(8,2);
    DECLARE p_costo DECIMAL(8,2);
    DECLARE p_total DECIMAL(8,2);
    DECLARE p_numero_comprobante varchar(60);
    DECLARE p_descr_salida varchar(150);
    DECLARE p_inventariable int(11);
    DECLARE	p_estado tinyint(1);
    DECLARE p_stock DECIMAL(8,2);
    DECLARE p_cantidad_perecedero DECIMAL(8,2);
	SET time_zone = '-05:00';


    SET p_idventa = (SELECT MAX(idventa) FROM venta);
    SET p_total = (SELECT total FROM venta WHERE idventa = p_idventa);
    SET p_precio_compra = (SELECT precio_compra FROM producto WHERE idproducto = p_idproducto);

    SET p_costo = (p_cantidad * p_precio_compra);

    SET p_tipo_comprobante = (SELECT tipo_comprobante FROM venta WHERE idventa = p_idventa);
    SET p_numero_comprobante = (SELECT numero_comprobante FROM venta WHERE idventa = p_idventa);
    SET p_comprobante = (SELECT nombre_comprobante FROM comprobante WHERE idcomprobante = p_tipo_comprobante);
    SET p_descr_salida = (CONCAT('POR VENTA',' ', p_comprobante,' # ',p_numero_comprobante));
    SET p_inventariable = (SELECT inventariable FROM producto WHERE idproducto = p_idproducto);
    SET p_estado = (SELECT estado FROM venta WHERE idventa = p_idventa);
    SET p_cantidad_perecedero = (SELECT cantidad_perecedero FROM perecedero WHERE idproducto = p_idproducto
    AND fecha_vencimiento = p_fecha_vence AND estado = 1);
    SET p_stock = (SELECT stock FROM producto WHERE idproducto = p_idproducto);

		IF (p_inventariable  = 0) THEN

			IF p_idventa IS NULL OR p_idventa = '' THEN

				INSERT INTO `detalleventa`(`idventa`, `idproducto`, `cantidad`, `precio_unitario`,
				`fecha_vence`, `exento`, `descuento`, `importe`)
				VALUES (1, p_idproducto, p_cantidad, p_precio_unitario,
				NULL, p_exento, p_descuento, p_importe);


				ELSE

				INSERT INTO `detalleventa`(`idventa`, `idproducto`, `cantidad`, `precio_unitario`,
				`fecha_vence`, `exento`, `descuento`, `importe`)
				VALUES (p_idventa, p_idproducto, p_cantidad, p_precio_unitario,
				NULL, p_exento, p_descuento, p_importe);

			END IF; -- IF p_idventa IS NULL OR p_idventa = '' THEN


		ELSE -- ELSE p_inventariable  = 0

			IF (p_fecha_vence != '2000-01-01') THEN

				IF p_idventa IS NULL OR p_idventa = '' THEN

                    IF (p_stock > 0) THEN

							INSERT INTO `detalleventa`(`idventa`, `idproducto`, `cantidad`, `precio_unitario`,
							`fecha_vence`, `exento`, `descuento`, `importe`)
							VALUES (1, p_idproducto, p_cantidad, p_precio_unitario,
							p_fecha_vence, p_exento, p_descuento, p_importe);

							INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
							`precio_unitario_salida`, `costo_total_salida`,`idproducto`,`idventa`)
							VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_salida,p_cantidad,p_precio_compra,p_costo,p_idproducto,1);

							UPDATE `inventario` SET
							`saldo_final` = `saldo_final` - p_cantidad,
							`salidas` = `salidas` + p_cantidad
							WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
							AND fecha_cierre = LAST_DAY(CURDATE());

							CALL sp_descontar_perecedero(p_idproducto, p_cantidad, p_fecha_vence);

							UPDATE `producto` SET
							`stock` = `stock` - p_cantidad
							WHERE idproducto = p_idproducto;

                    END IF; -- IF p_stock > 0;

			ELSE -- ELSE p_idventa IS NULL OR p_idventa = ''

					 IF (p_stock > 0) THEN

							INSERT INTO `detalleventa`(`idventa`, `idproducto`, `cantidad`, `precio_unitario`,
							`fecha_vence`, `exento`, `descuento`, `importe`)
							VALUES (p_idventa, p_idproducto, p_cantidad, p_precio_unitario,
							p_fecha_vence, p_exento, p_descuento, p_importe);

							INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
							`precio_unitario_salida`, `costo_total_salida`,`idproducto`,`idventa`)
							VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_salida,p_cantidad,p_precio_compra,p_costo,p_idproducto,p_idventa);

							UPDATE `inventario` SET
							`saldo_final` = `saldo_final` - p_cantidad,
							`salidas` = `salidas` + p_cantidad
							WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
							AND fecha_cierre = LAST_DAY(CURDATE());

							CALL sp_descontar_perecedero(p_idproducto, p_cantidad, p_fecha_vence);

							UPDATE `producto` SET
							`stock` = `stock` - p_cantidad
							WHERE idproducto = p_idproducto;

						END IF; -- IF p_stock > 0;

					END IF; -- IF p_idventa IS NULL OR p_idventa = ''

				ELSE  -- ELSE p_fecha_vencimiento != '2000-01-01'

                IF p_idventa IS NULL OR p_idventa = '' THEN

                    IF (p_stock > 0) THEN

							INSERT INTO `detalleventa`(`idventa`, `idproducto`, `cantidad`, `precio_unitario`,
							`fecha_vence`, `exento`, `descuento`, `importe`)
							VALUES (1, p_idproducto, p_cantidad, p_precio_unitario,
							NULL, p_exento, p_descuento, p_importe);

							INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
							`precio_unitario_salida`, `costo_total_salida`,`idproducto`,`idventa`)
							VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_salida,p_cantidad,p_precio_compra,p_costo,p_idproducto,1);

							UPDATE `inventario` SET
							`saldo_final` = `saldo_final` - p_cantidad,
							`salidas` = `salidas` + p_cantidad
							WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
							AND fecha_cierre = LAST_DAY(CURDATE());


							UPDATE `producto` SET
							`stock` = `stock` - p_cantidad
							WHERE idproducto = p_idproducto;

                    END IF; -- IF p_stock > 0;

			ELSE -- ELSE p_idventa IS NULL OR p_idventa = ''

					 IF (p_stock > 0) THEN

							INSERT INTO `detalleventa`(`idventa`, `idproducto`, `cantidad`, `precio_unitario`,
							`fecha_vence`, `exento`, `descuento`, `importe`)
							VALUES (p_idventa, p_idproducto, p_cantidad, p_precio_unitario,
							NULL, p_exento, p_descuento, p_importe);

							INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
							`precio_unitario_salida`, `costo_total_salida`,`idproducto`,`idventa`)
							VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),NOW(),p_descr_salida,p_cantidad,p_precio_compra,p_costo,p_idproducto,p_idventa);

							UPDATE `inventario` SET
							`saldo_final` = `saldo_final` - p_cantidad,
							`salidas` = `salidas` + p_cantidad
							WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
							AND fecha_cierre = LAST_DAY(CURDATE());


							UPDATE `producto` SET
							`stock` = `stock` - p_cantidad
							WHERE idproducto = p_idproducto;

						END IF; -- IF p_stock > 0;

					END IF; -- IF p_idventa IS NULL OR p_idventa = ''

			END IF; -- IF p_fecha_vencimiento != '2000-01-01'

		END IF;  -- IF p_inventariable  = 0

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_diagnostico` (IN `p_idorden` INT(11), IN `p_diagnostico` VARCHAR(200), IN `p_estado_aparato` VARCHAR(200), IN `p_repuestos` DECIMAL(8,2), IN `p_mano_obra` DECIMAL(8,2), IN `p_fecha_alta` DATETIME, IN `p_fecha_retiro` DATETIME, IN `p_ubicacion` VARCHAR(150), IN `p_parcial_pagar` DECIMAL(8,2))  BEGIN
	UPDATE `ordentaller`
	SET `diagnostico` = p_diagnostico, `estado_aparato` = p_estado_aparato,
    `repuestos` = p_repuestos, `mano_obra` = p_mano_obra, `fecha_alta` = p_fecha_alta,
    `fecha_retiro` = p_fecha_retiro, `ubicacion` = p_ubicacion, `parcial_pagar` = p_parcial_pagar
	WHERE `idorden` = p_idorden;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_empleado` (IN `p_nombre_empleado` VARCHAR(90), IN `p_apellido_empleado` VARCHAR(90), IN `p_telefono_empleado` VARCHAR(70), IN `p_email_empleado` VARCHAR(80))  BEGIN
	IF NOT EXISTS (SELECT * FROM `empleado` WHERE `nombre_empleado` = p_nombre_empleado AND
    `apellido_empleado` = p_apellido_empleado) THEN
		INSERT INTO `empleado`(`nombre_empleado`, `apellido_empleado`,
		`telefono_empleado`, `email_empleado`)
		VALUES (p_nombre_empleado, p_apellido_empleado,
		p_telefono_empleado, p_email_empleado);
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_entrada` (IN `p_descripcion_entrada` VARCHAR(150), IN `p_cantidad_entrada` DECIMAL(8,2), IN `p_idproducto` INT(11))  BEGIN

	DECLARE p_precio_unitario_entrada decimal(8,2);
    DECLARE p_costo_total_entrada decimal(8,2);

    SET p_precio_unitario_entrada = (SELECT precio_compra FROM producto WHERE idproducto = p_idproducto);
    SET p_costo_total_entrada = (p_precio_unitario_entrada * p_cantidad_entrada);

	INSERT INTO `entrada`(`mes_inventario`,`fecha_entrada`, `descripcion_entrada`, `cantidad_entrada`,
	`precio_unitario_entrada`, `costo_total_entrada`, `idproducto`, `idcompra`)
	VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),CURDATE(), p_descripcion_entrada, p_cantidad_entrada,
	p_precio_unitario_entrada, p_costo_total_entrada, p_idproducto, NULL);

	UPDATE `inventario` SET
	`saldo_final` = `saldo_final` + p_cantidad_entrada,
    `entradas` = `entradas` + p_cantidad_entrada
	WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
	AND fecha_cierre = LAST_DAY(CURDATE());

	UPDATE `producto` SET
	`stock` = `stock` + p_cantidad_entrada
	WHERE idproducto = p_idproducto;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_marca` (IN `p_nombre_marca` VARCHAR(120))  BEGIN
  IF NOT EXISTS (SELECT * FROM `marca` WHERE `nombre_marca` = p_nombre_marca) THEN
	INSERT INTO `marca`(`nombre_marca`)
	VALUES (p_nombre_marca);
  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_ordentaller` (IN `p_idcliente` INT(11), IN `p_aparato` VARCHAR(125), IN `p_modelo` VARCHAR(125), IN `p_idmarca` INT(11), IN `p_serie` VARCHAR(125), IN `p_idtecnico` INT(11), IN `p_averia` VARCHAR(200), IN `p_observaciones` VARCHAR(200), IN `p_deposito_revision` DECIMAL(8,2), IN `p_deposito_reparacion` DECIMAL(8,2), IN `p_parcial_pagar` DECIMAL(8,2))  BEGIN
	INSERT INTO `ordentaller`(`fecha_ingreso`, `idcliente`,
	`aparato`, `modelo`, `idmarca`, `serie`, `idtecnico`, `averia`, `observaciones`, `deposito_revision`,
	`deposito_reparacion`,`parcial_pagar`)
	VALUES (NOW(), p_idcliente,
	p_aparato, p_modelo, p_idmarca, p_serie,
	p_idtecnico, p_averia, p_observaciones, p_deposito_revision,
	p_deposito_reparacion,p_parcial_pagar);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_parametro` (IN `p_nombre_empresa` VARCHAR(150), IN `p_propietario` VARCHAR(150), IN `p_numero_nit` VARCHAR(70), IN `p_numero_nrc` VARCHAR(70), IN `p_porcentaje_iva` DECIMAL(8,2), IN `p_porcentaje_retencion` DECIMAL(8,2), IN `p_monto_retencion` DECIMAL(8,2), IN `p_direccion_empresa` VARCHAR(200), IN `p_idcurrency` INT(11))  BEGIN
	   DECLARE contador INT;
	   SET contador = (SELECT COUNT(*) FROM `parametro`);

		IF contador = 0 THEN
			INSERT INTO `parametro`(`nombre_empresa`, `propietario`, `numero_nit`,
			`numero_nrc`, `porcentaje_iva`, `porcentaje_retencion`, `monto_retencion`, `direccion_empresa`,`idcurrency`)
			VALUES (p_nombre_empresa, p_propietario, p_numero_nit,
			p_numero_nrc, p_porcentaje_iva, p_porcentaje_retencion, p_monto_retencion,
            p_direccion_empresa,p_idcurrency);
		END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_perecedero` (IN `p_fecha_vencimiento` DATE, IN `p_cantidad_perecedero` DECIMAL(8,2), IN `p_idproducto` INT(11))  BEGIN
  IF NOT EXISTS (SELECT * FROM perecedero WHERE idproducto = p_idproducto
  AND fecha_vencimiento = p_fecha_vencimiento) THEN
	INSERT INTO `perecedero`(`fecha_vencimiento`, `cantidad_perecedero`, `idproducto`)
	VALUES (p_fecha_vencimiento, p_cantidad_perecedero, p_idproducto);
  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_presentacion` (IN `p_nombre_presentacion` VARCHAR(120), IN `p_siglas` VARCHAR(45))  BEGIN
  IF NOT EXISTS (SELECT * FROM `presentacion` WHERE `nombre_presentacion` = p_nombre_presentacion) THEN
	INSERT INTO `presentacion`(`nombre_presentacion`,`siglas`)
	VALUES (p_nombre_presentacion,p_siglas);
  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_producto` (IN `p_codigo_interno` VARCHAR(175), IN `p_codigo_barra` VARCHAR(200), IN `p_nombre_producto` VARCHAR(175), IN `p_precio_compra` DECIMAL(8,2), IN `p_precio_venta` DECIMAL(8,2), IN `p_precio_venta_mayoreo` DECIMAL(8,2), IN `p_precio_venta_3` DECIMAL(8,2), IN `p_stock` DECIMAL(8,2), IN `p_stock_min` DECIMAL(8,2), IN `p_idcategoria` INT(11), IN `p_idmarca` INT(11), IN `p_idpresentacion` INT(11), IN `p_exento` TINYINT(1), IN `p_inventariable` TINYINT(1), IN `p_perecedero` TINYINT(1))  BEGIN
    IF (p_inventariable = 1) THEN
        IF NOT EXISTS (SELECT * FROM `producto` WHERE `nombre_producto` = p_nombre_producto) THEN
            INSERT INTO `producto`(
                `codigo_interno`,  -- Agregar el nuevo campo al inicio
                `codigo_barra`, 
                `nombre_producto`,
                `precio_compra`, 
                `precio_venta`, 
                `precio_venta_mayoreo`,
                `precio_venta_3`, 
                `stock`,
                `stock_min`, 
                `idcategoria`, 
                `idmarca`, 
                `idpresentacion`,
                `exento`,
                `inventariable`, 
                `perecedero`
            )
            VALUES (
                p_codigo_interno,  -- Agregar el nuevo valor al inicio
                p_codigo_barra, 
                p_nombre_producto,
                p_precio_compra, 
                p_precio_venta, 
                p_precio_venta_mayoreo,
                p_precio_venta_3,
                p_stock,
                p_stock_min, 
                p_idcategoria, 
                p_idmarca, 
                p_idpresentacion,
                p_exento, 
                p_inventariable, 
                p_perecedero
            );
        END IF;
    ELSE
        IF NOT EXISTS (SELECT * FROM `producto` WHERE `nombre_producto` = p_nombre_producto) THEN
            INSERT INTO `producto`(
                `codigo_interno`,  -- Agregar el nuevo campo al inicio
                `codigo_barra`, 
                `nombre_producto`,
                `precio_compra`, 
                `precio_venta`, 
                `precio_venta_mayoreo`,
                `precio_venta_3`,
                `stock_min`, 
                `idcategoria`, 
                `idmarca`, 
                `idpresentacion`,
                `exento`,
                `inventariable`, 
                `perecedero`
            )
            VALUES (
                p_codigo_interno,  -- Agregar el nuevo valor al inicio
                p_codigo_barra, 
                p_nombre_producto,
                p_precio_compra, 
                p_precio_venta, 
                p_precio_venta_mayoreo,
                p_precio_venta_3,
                0, 
                p_idcategoria, 
                p_idmarca, 
                p_idpresentacion,
                p_exento, 
                p_inventariable, 
                p_perecedero
            );
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_proveedor` (IN `p_nombre_proveedor` VARCHAR(175), IN `p_numero_telefono` VARCHAR(70), IN `p_numero_nit` VARCHAR(70), IN `p_numero_nrc` VARCHAR(70), IN `p_nombre_contacto` VARCHAR(150), IN `p_telefono_contacto` VARCHAR(150))  BEGIN
   IF NOT EXISTS (SELECT * FROM `proveedor` WHERE `nombre_proveedor` = p_nombre_proveedor OR
   `numero_nit` = p_numero_nit OR `numero_nrc` =  p_numero_nrc) THEN
	INSERT INTO `proveedor`(`nombre_proveedor`, `numero_telefono`,
	`numero_nit`, `numero_nrc`, `nombre_contacto`, `telefono_contacto`)
	VALUES (p_nombre_proveedor, p_numero_telefono,
	p_numero_nit, p_numero_nrc, p_nombre_contacto, p_telefono_contacto);
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_salida` (IN `p_descripcion_salida` VARCHAR(150), IN `p_cantidad_salida` DECIMAL(8,2), IN `p_idproducto` INT(11))  BEGIN

	DECLARE p_precio_unitario_salida decimal(8,2);
	DECLARE p_costo_total_salida decimal(8,2);

	SET p_precio_unitario_salida = (SELECT precio_compra FROM producto WHERE idproducto = p_idproducto);
	SET p_costo_total_salida = (p_precio_unitario_salida * p_cantidad_salida);

	INSERT INTO `salida`(`mes_inventario`,`fecha_salida`, `descripcion_salida`, `cantidad_salida`,
	`precio_unitario_salida`, `costo_total_salida`, `idproducto`, `idventa`)
	VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),CURDATE(), p_descripcion_salida, p_cantidad_salida,
	p_precio_unitario_salida, p_costo_total_salida, p_idproducto, NULL);

	UPDATE `inventario` SET
	`saldo_final` = `saldo_final` - p_cantidad_salida,
    `salidas` = `salidas` + p_cantidad_salida
	WHERE idproducto = p_idproducto AND fecha_apertura =  DATE_FORMAT(CURDATE(),'%Y-%m-01')
	AND fecha_cierre = LAST_DAY(CURDATE());

	UPDATE `producto` SET
	`stock` = `stock` - p_cantidad_salida
	WHERE idproducto = p_idproducto;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_tecnico` (IN `p_tecnico` VARCHAR(150), IN `p_telefono` VARCHAR(70))  BEGIN
 IF NOT EXISTS (SELECT * FROM tecnico WHERE tecnico = p_tecnico) THEN
	INSERT INTO `tecnico`(`tecnico`, `telefono`)
	VALUES (p_tecnico, p_telefono);
 END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_tiraje_comprobante` (IN `p_fecha_resolucion` DATETIME, IN `p_numero_resolucion` VARCHAR(100), IN `p_serie` VARCHAR(175), IN `p_desde` INT(11), IN `p_hasta` INT(11), IN `p_disponibles` INT(11), IN `p_idcomprobante` INT(11))  BEGIN
   IF NOT EXISTS (SELECT * FROM `tiraje_comprobante` WHERE idcomprobante =  p_idcomprobante) THEN
	 INSERT INTO `tiraje_comprobante`(`fecha_resolucion`, `numero_resolucion`, `serie`,
	`desde`, `hasta`, `disponibles`, `idcomprobante`)
		VALUES (p_fecha_resolucion, p_numero_resolucion, p_serie,
		p_desde, p_hasta, p_disponibles, p_idcomprobante);
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_usuario` (IN `p_usuario` VARCHAR(70), IN `p_contrasena` VARCHAR(12), IN `p_tipo_usuario` TINYINT(1), IN `p_idempleado` INT(11))  BEGIN
  IF NOT EXISTS (SELECT * FROM `usuario` WHERE `idempleado` = p_idempleado) THEN
	INSERT INTO `usuario`(`usuario`, `contrasena`, `tipo_usuario`,`idempleado`)
	VALUES (p_usuario, p_contrasena, p_tipo_usuario, p_idempleado);
  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_venta` (IN `p_tipo_pago` VARCHAR(75), IN `p_tipo_comprobante` TINYINT(1), IN `p_sumas` DECIMAL(8,2), IN `p_iva` DECIMAL(8,2), IN `p_exento` DECIMAL(8,2), IN `p_retenido` DECIMAL(8,2), IN `p_descuento` DECIMAL(8,2), IN `p_total` DECIMAL(8,2), IN `p_sonletras` VARCHAR(150), IN `p_pago_efectivo` DECIMAL(8,2), IN `p_pago_tarjeta` DECIMAL(8,2), IN `p_numero_tarjeta` VARCHAR(16), IN `p_tarjeta_habiente` VARCHAR(90), IN `p_cambio` DECIMAL(8,2), IN `p_estado` TINYINT(1), IN `p_idcliente` INT(11), IN `p_idusuario` INT(11))  BEGIN

	DECLARE p_numero_comprobante INT;
    DECLARE p_efectivo_caja DECIMAL(8,2);
    DECLARE p_abono_credito DECIMAL(8,2);
    SET time_zone = '-05:00';
	SET p_numero_comprobante = (SELECT usados + 1 FROM view_comprobantes WHERE idcomprobante = p_tipo_comprobante);



		  IF NOT EXISTS (SELECT * FROM venta WHERE `numero_comprobante` = p_numero_comprobante
		  AND `tipo_comprobante` = p_tipo_comprobante AND `fecha_venta` = NOW()) THEN

			  IF p_estado = '1' THEN

              IF p_idcliente = '0' THEN

			    IF p_numero_comprobante = '0' THEN

					INSERT INTO `venta`(`fecha_venta`, `tipo_pago`,
					`numero_comprobante`, `tipo_comprobante`, `sumas`, `iva`,
					`exento`, `retenido`, `descuento`, `total`,
					`sonletras`, `pago_efectivo`, `pago_tarjeta`, `numero_tarjeta`,
					`tarjeta_habiente`, `cambio`, `estado`, `idcliente`, `idusuario`)
					VALUES (NOW(), p_tipo_pago,
					1, p_tipo_comprobante, p_sumas, p_iva,
					p_exento, p_retenido, p_descuento, p_total,
					p_sonletras, p_pago_efectivo, p_pago_tarjeta, p_numero_tarjeta,
					p_tarjeta_habiente, p_cambio, p_estado, NULL, p_idusuario);
                    
					UPDATE `tiraje_comprobante` SET
					`disponibles` = `disponibles` - 1
					WHERE idcomprobante = p_tipo_comprobante;


					IF (p_tipo_pago = 'EFECTIVO') THEN
						CALL sp_insert_caja_venta(p_total);
					ELSEIF (p_tipo_pago = 'EFECTIVO Y TARJETA') THEN
						CALL sp_insert_caja_venta(p_pago_efectivo);
                    ELSEIF (p_tipo_pago = 'TARJETA') THEN
						CALL sp_insert_caja_venta(0);
					END IF;

				ELSE

					INSERT INTO `venta`(`fecha_venta`, `tipo_pago`,
					`numero_comprobante`, `tipo_comprobante`, `sumas`, `iva`,
					`exento`, `retenido`, `descuento`, `total`,
					`sonletras`, `pago_efectivo`, `pago_tarjeta`, `numero_tarjeta`,
					`tarjeta_habiente`, `cambio`, `estado`, `idcliente`, `idusuario`)
					VALUES (NOW(), p_tipo_pago,
					p_numero_comprobante, p_tipo_comprobante, p_sumas, p_iva,
					p_exento, p_retenido, p_descuento, p_total,
					p_sonletras, p_pago_efectivo, p_pago_tarjeta, p_numero_tarjeta,
					p_tarjeta_habiente, p_cambio, p_estado, NULL, p_idusuario);
                    
					UPDATE `tiraje_comprobante` SET
					`disponibles` = `disponibles` - 1
					WHERE idcomprobante = p_tipo_comprobante;


					IF (p_tipo_pago = 'EFECTIVO') THEN
						CALL sp_insert_caja_venta(p_total);
					ELSEIF (p_tipo_pago = 'EFECTIVO Y TARJETA') THEN
						CALL sp_insert_caja_venta(p_pago_efectivo);
					ELSEIF (p_tipo_pago = 'TARJETA') THEN
						CALL sp_insert_caja_venta(0);
                    END IF;

				END IF;

			   ELSE

				IF p_numero_comprobante = '0' THEN

					INSERT INTO `venta`(`fecha_venta`, `tipo_pago`,
					`numero_comprobante`, `tipo_comprobante`, `sumas`, `iva`,
					`exento`, `retenido`, `descuento`, `total`,
					`sonletras`, `pago_efectivo`, `pago_tarjeta`, `numero_tarjeta`,
					`tarjeta_habiente`, `cambio`, `estado`, `idcliente`, `idusuario`)
					VALUES (NOW(), p_tipo_pago,
					1, p_tipo_comprobante, p_sumas, p_iva,
					p_exento, p_retenido, p_descuento, p_total,
					p_sonletras, p_pago_efectivo, p_pago_tarjeta, p_numero_tarjeta,
					p_tarjeta_habiente, p_cambio, p_estado, p_idcliente, p_idusuario);
                    
					UPDATE `tiraje_comprobante` SET
					`disponibles` = `disponibles` - 1
					WHERE idcomprobante = p_tipo_comprobante;


					IF (p_tipo_pago = 'EFECTIVO') THEN
						CALL sp_insert_caja_venta(p_total);
					ELSEIF (p_tipo_pago = 'EFECTIVO Y TARJETA') THEN
						CALL sp_insert_caja_venta(p_pago_efectivo);
					ELSEIF (p_tipo_pago = 'TARJETA') THEN
						CALL sp_insert_caja_venta(0);
                    END IF;

				ELSE

					INSERT INTO `venta`(`fecha_venta`, `tipo_pago`,
					`numero_comprobante`, `tipo_comprobante`, `sumas`, `iva`,
					`exento`, `retenido`, `descuento`, `total`,
					`sonletras`, `pago_efectivo`, `pago_tarjeta`, `numero_tarjeta`,
					`tarjeta_habiente`, `cambio`, `estado`, `idcliente`, `idusuario`)
					VALUES (NOW(), p_tipo_pago,
					p_numero_comprobante, p_tipo_comprobante, p_sumas, p_iva,
					p_exento, p_retenido, p_descuento, p_total,
					p_sonletras, p_pago_efectivo, p_pago_tarjeta, p_numero_tarjeta,
					p_tarjeta_habiente, p_cambio, p_estado, p_idcliente, p_idusuario);
                    
					UPDATE `tiraje_comprobante` SET
					`disponibles` = `disponibles` - 1
					WHERE idcomprobante = p_tipo_comprobante;


					IF (p_tipo_pago = 'EFECTIVO') THEN
						CALL sp_insert_caja_venta(p_total);
					ELSEIF (p_tipo_pago = 'EFECTIVO Y TARJETA') THEN
						CALL sp_insert_caja_venta(p_pago_efectivo);
                    ELSEIF (p_tipo_pago = 'TARJETA') THEN
						CALL sp_insert_caja_venta(0);
                    END IF;

				END IF;


			  END IF;


            ELSEIF p_estado = '2' THEN

            IF p_numero_comprobante = '0' THEN

				INSERT INTO `venta`(`fecha_venta`, `tipo_pago`,
				`numero_comprobante`, `tipo_comprobante`, `sumas`, `iva`,
				`exento`, `retenido`, `descuento`, `total`,
				`sonletras`, `pago_efectivo`, `pago_tarjeta`, `numero_tarjeta`,
				`tarjeta_habiente`, `cambio`, `estado`, `idcliente`, `idusuario`)
				VALUES (NOW(), p_tipo_pago,
				1, p_tipo_comprobante, p_sumas, p_iva,
				p_exento, p_retenido, p_descuento, p_total,
				p_sonletras, 0.00, 0.00, NULL, 0.00, 0.00, p_estado, p_idcliente, p_idusuario);

				UPDATE `tiraje_comprobante` SET
				`disponibles` = `disponibles` - 1
				WHERE idcomprobante = p_tipo_comprobante;

                CALL sp_insert_credito_venta(p_total, p_idcliente);

                ELSE

				INSERT INTO `venta`(`fecha_venta`, `tipo_pago`,
				`numero_comprobante`, `tipo_comprobante`, `sumas`, `iva`,
				`exento`, `retenido`, `descuento`, `total`,
				`sonletras`, `pago_efectivo`, `pago_tarjeta`, `numero_tarjeta`,
				`tarjeta_habiente`, `cambio`, `estado`, `idcliente`, `idusuario`)
				VALUES (NOW(), p_tipo_pago,
				p_numero_comprobante, p_tipo_comprobante, p_sumas, p_iva,
				p_exento, p_retenido, p_descuento, p_total,
				p_sonletras, 0.00, 0.00, NULL, 0.00, 0.00, p_estado, p_idcliente, p_idusuario);

				UPDATE `tiraje_comprobante` SET
				`disponibles` = `disponibles` - 1
				WHERE idcomprobante = p_tipo_comprobante;

                CALL sp_insert_credito_venta(p_total, p_idcliente);

			END IF;

			END IF;

		END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_insert_venta_apartado` (IN `p_idapartado` INT(11), IN `p_tipo_pago` VARCHAR(75), IN `p_tipo_comprobante` TINYINT(1), IN `p_pago_efectivo` DECIMAL(8,2), IN `p_pago_tarjeta` DECIMAL(8,2), IN `p_numero_tarjeta` VARCHAR(16), IN `p_tarjeta_habiente` VARCHAR(90), IN `p_cambio` DECIMAL(8,2), IN `p_idcliente` INT(11), IN `p_idusuario` INT(11))  BEGIN

	DECLARE p_numero_comprobante INT;
    DECLARE p_abono_credito DECIMAL(8,2);
    DECLARE p_idventa INT;
    DECLARE p_sumas decimal(8,2);
  	DECLARE p_iva decimal(8,2);
  	DECLARE p_exento decimal(8,2);
  	DECLARE p_retenido decimal(8,2);
  	DECLARE p_descuento decimal(8,2);
  	DECLARE p_total decimal(8,2);
  	DECLARE p_sonletras varchar(150);

  	SET p_numero_comprobante = (SELECT usados + 1 FROM view_comprobantes WHERE idcomprobante = p_tipo_comprobante);
    SET p_sumas = (SELECT sumas FROM apartado WHERE idapartado = p_idapartado);
    SET p_iva = (SELECT iva FROM apartado WHERE idapartado = p_idapartado);
    SET p_exento = (SELECT exento FROM apartado WHERE idapartado = p_idapartado);
    SET p_retenido = (SELECT retenido FROM apartado WHERE idapartado = p_idapartado);
    SET p_descuento = (SELECT descuento FROM apartado WHERE idapartado = p_idapartado);
    SET p_total = (SELECT total FROM apartado WHERE idapartado = p_idapartado);
    SET p_sonletras = (SELECT sonletras FROM apartado WHERE idapartado = p_idapartado);


		  IF NOT EXISTS (SELECT * FROM venta WHERE `numero_comprobante` = p_numero_comprobante
		  AND `tipo_comprobante` = p_tipo_comprobante AND `fecha_venta` = NOW()) THEN


				IF p_numero_comprobante = '0' THEN

					INSERT INTO `venta`(`fecha_venta`, `tipo_pago`,
					`numero_comprobante`, `tipo_comprobante`, `sumas`, `iva`,
					`exento`, `retenido`, `descuento`, `total`,
					`sonletras`, `pago_efectivo`, `pago_tarjeta`, `numero_tarjeta`,
					`tarjeta_habiente`, `cambio`, `estado`, `idcliente`, `idusuario`)
					VALUES (NOW(), p_tipo_pago,
					1, p_tipo_comprobante, p_sumas, p_iva,
					p_exento, p_retenido, p_descuento, p_total,
					p_sonletras, p_pago_efectivo, p_pago_tarjeta, p_numero_tarjeta,
					p_tarjeta_habiente, p_cambio, 1, NULL, p_idusuario);
                    
					UPDATE `tiraje_comprobante` SET
					`disponibles` = `disponibles` - 1
					WHERE idcomprobante = p_tipo_comprobante;


					IF (p_tipo_pago = 'EFECTIVO') THEN
						CALL sp_insert_caja_venta(p_total);
					ELSEIF (p_tipo_pago = 'EFECTIVO Y TARJETA') THEN
						CALL sp_insert_caja_venta(p_pago_efectivo);
					END IF;

				ELSE

					INSERT INTO `venta`(`fecha_venta`, `tipo_pago`,
					`numero_comprobante`, `tipo_comprobante`, `sumas`, `iva`,
					`exento`, `retenido`, `descuento`, `total`,
					`sonletras`, `pago_efectivo`, `pago_tarjeta`, `numero_tarjeta`,
					`tarjeta_habiente`, `cambio`, `estado`, `idcliente`, `idusuario`)
					VALUES (NOW(), p_tipo_pago,
					p_numero_comprobante, p_tipo_comprobante, p_sumas, p_iva,
					p_exento, p_retenido, p_descuento, p_total,
					p_sonletras, p_pago_efectivo, p_pago_tarjeta, p_numero_tarjeta,
					p_tarjeta_habiente, p_cambio, 1, NULL, p_idusuario);
                    
					UPDATE `tiraje_comprobante` SET
					`disponibles` = `disponibles` - 1
					WHERE idcomprobante = p_tipo_comprobante;


					IF (p_tipo_pago = 'EFECTIVO') THEN
						CALL sp_insert_caja_venta(p_total);
					ELSEIF (p_tipo_pago = 'EFECTIVO Y TARJETA') THEN
						CALL sp_insert_caja_venta(p_pago_efectivo);
					END IF;

				END IF;

				UPDATE `apartado` SET
				`estado` = 2
				WHERE idapartado = p_idapartado;

                SET p_idventa = (SELECT MAX(idventa) FROM venta);

				INSERT INTO `detalleventa`(`idventa`, `idproducto`, `cantidad`, `precio_unitario`, `fecha_vence`,
                `exento`, `descuento`, `importe`)
				SELECT p_idventa, idproducto,cantidad,precio_unitario,fecha_vence,exento,descuento,importe FROM detalleapartado
				WHERE idapartado = p_idapartado;

		END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_kardex_inventario` (IN `p_mes` VARCHAR(7))  BEGIN
	SET time_zone = '-05:00';

	IF p_mes = '' THEN

        SELECT * FROM view_kardex WHERE mes_inventario = DATE_FORMAT(CURDATE(),'%Y-%m')
        ORDER BY idproducto;

	 ELSE

		SELECT * FROM view_kardex WHERE mes_inventario = p_mes  ORDER BY idproducto;

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_usuario` (IN `p_usuario` VARCHAR(70), IN `p_contrasena` VARCHAR(12))  BEGIN
	SELECT * FROM view_usuarios WHERE usuario = p_usuario AND contrasena = p_contrasena
    AND estado = 1;

    CALL sp_cerrar_inventario();

    CALL sp_sacar_vencidos();
    
    CALL sp_devolver_productos_apartados();

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_panel_dashboard` ()  BEGIN

	DECLARE compras_mes DECIMAL(8,2);
	DECLARE ventas_dia DECIMAL(8,2);
	DECLARE inversion_stock DECIMAL(8,2);
	DECLARE proveedores DECIMAL(8,2);
	DECLARE marcas DECIMAL(8,2);
	DECLARE presentaciones DECIMAL(8,2);
	DECLARE productos DECIMAL(8,2);
	DECLARE a_vencer DECIMAL(8,2);
    DECLARE perecederos DECIMAL(8,2);
	DECLARE clientes DECIMAL(8,2);
    DECLARE creditos DECIMAL(8,2);
	DECLARE p_ingresos decimal(8,2);
	DECLARE p_devoluciones decimal(8,2);
	DECLARE p_prestamos decimal(8,2);
	DECLARE p_gastos decimal(8,2);
	DECLARE p_egresos decimal(8,2);
	DECLARE p_saldo decimal(8,2);

    DECLARE p_monto_inicial decimal(8,2);
    SET time_zone = '-05:00';


    SET p_ingresos = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
    DATE(fecha_apertura) <= CURDATE() AND estado=1 AND tipo_movimiento = 1);

    SET p_devoluciones = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
    DATE(fecha_apertura) <= CURDATE() AND estado=1 AND tipo_movimiento = 2);

    SET p_prestamos = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
    DATE(fecha_apertura) <= CURDATE() AND estado=1 AND tipo_movimiento = 3);

    SET p_gastos = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
    DATE(fecha_apertura) <= CURDATE() AND estado=1 AND tipo_movimiento = 4);

	IF (p_ingresos IS NULL) THEN
	   SET p_ingresos = (0.00);
	END IF;

	IF (p_devoluciones IS NULL) THEN
	   SET p_devoluciones = (0.00);
	END IF;

	IF (p_gastos IS NULL) THEN
	   SET p_gastos = (0.00);
	END IF;

	IF (p_prestamos IS NULL) THEN
	   SET p_prestamos = (0.00);
	END IF;

    SET p_egresos = (p_prestamos + p_gastos);
    SET p_saldo = (p_ingresos - p_egresos +  p_devoluciones);
    SET p_monto_inicial = (SELECT monto_apertura FROM caja WHERE DATE(fecha_apertura) <= CURDATE() AND estado=1);

	SET compras_mes = (SELECT if(SUM(total) IS NULL,0.00,SUM(total)) as compras_mes
    FROM compra  WHERE MONTH(fecha_compra) = MONTH(NOW()) AND estado=1);
    SET ventas_dia = (SELECT if(SUM(total) IS NULL,0.00, SUM(total)) as ventas_dia
    FROM venta  WHERE DATE_FORMAT(fecha_venta,'%Y-%m-%d') <= CURDATE() AND estado = 1);
    SET inversion_stock = (SELECT TRUNCATE(SUM((stock * precio_compra)),2) as costo FROM producto
    WHERE  stock > 0.00);
    SET proveedores = (SELECT COUNT(*) as numero_proveedores FROM proveedor);
    SET marcas = (SELECT COUNT(*) as numero_marcas FROM marca);
    SET presentaciones = (SELECT COUNT(*) as numero_presentaciones FROM presentacion);
    SET productos = (SELECT COUNT(*) as numero_productos FROM producto);

    SET a_vencer = (SELECT COUNT(*) FROM perecedero WHERE fecha_vencimiento
    BETWEEN CURDATE() + INTERVAL 30 DAY AND CURDATE() + INTERVAL 1 MONTH);

    SET perecederos = (SELECT COUNT(*) FROM perecedero);
    SET clientes = (SELECT COUNT(*) FROM cliente);
    SET creditos = (SELECT COUNT(*) FROM credito WHERE estado = 0);


    SELECT compras_mes,ventas_dia,inversion_stock,proveedores,marcas,presentaciones,productos,
    p_monto_inicial + p_saldo as dinero_caja, perecederos, a_vencer,clientes,creditos;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_print_barcode_producto` (IN `p_id` INT)  BEGIN
SELECT codigo_barra,codigo_interno,nombre_producto FROM producto WHERE idproducto = p_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_sacar_vencidos` ()  BEGIN

		UPDATE `perecedero` SET
		`estado` = 0 WHERE `estado` = 1
         AND fecha_vencimiento < CURDATE();

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_search_producto` (IN `p_search` VARCHAR(175))  BEGIN
SELECT idproducto,codigo_interno,codigo_barra,nombre_producto,siglas,nombre_marca,
precio_compra,exento,perecedero FROM view_productos WHERE codigo_barra LIKE CONCAT('%',p_search,'%')
OR nombre_producto LIKE CONCAT('%',p_search,'%') AND estado = 1 AND inventariable = 1 AND precio_compra > 0.00;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_search_producto_apartado` (IN `p_search` VARCHAR(175))  BEGIN
SELECT * FROM view_productos_apartado WHERE codigo_barra LIKE CONCAT('%',p_search,'%')
OR nombre_producto LIKE CONCAT('%',p_search,'%') OR codigo_interno LIKE CONCAT('%',p_search,'%')
ORDER BY idproducto DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_search_producto_cotizacion` (IN `p_search` VARCHAR(175))  BEGIN
SELECT idproducto,codigo_interno,codigo_barra,nombre_producto,siglas,nombre_marca,
precio_venta,precio_venta_mayoreo,stock,exento,perecedero
FROM view_productos WHERE codigo_barra LIKE CONCAT('%',p_search,'%')
OR nombre_producto LIKE CONCAT('%',p_search,'%') AND estado = 1 AND inventariable = 1
AND precio_venta > 0.00;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_search_producto_venta` (IN `p_search` VARCHAR(175))  BEGIN
SELECT * FROM view_productos_venta WHERE codigo_barra LIKE CONCAT('%',p_search,'%')
OR nombre_producto LIKE CONCAT('%',p_search,'%') OR codigo_interno LIKE CONCAT('%',p_search,'%')
ORDER BY idproducto DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_abono` (IN `p_idabono` INT(11), IN `p_fecha_abono` DATETIME, IN `p_monto_abono` DECIMAL(8,2))  BEGIN
UPDATE `abono`
SET  `fecha_abono` = p_fecha_abono, `monto_abono` = p_monto_abono
WHERE `idabono` = p_idabono;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_abono_proveedor` (IN `p_idabonoproveedor` INT(11), IN `p_fecha_abono` DATETIME, IN `p_monto_abono` DECIMAL(8,2))  BEGIN
UPDATE `abonoproveedor`
SET  `fecha_abono` = p_fecha_abono, `monto_abono` = p_monto_abono
WHERE `idabonoproveedor` = p_idabonoproveedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_categoria` (IN `p_idcategoria` INT(11), IN `p_nombre_categoria` VARCHAR(120), IN `p_estado` TINYINT(1))  BEGIN
UPDATE `categoria`
SET `nombre_categoria` = p_nombre_categoria, `estado` = p_estado
WHERE `idcategoria` = p_idcategoria;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_cliente` (IN `p_idcliente` INT(11), IN `p_nombre_cliente` VARCHAR(150), IN `p_numero_nit` VARCHAR(70), IN `p_numero_nrc` VARCHAR(45), IN `p_direccion_cliente` VARCHAR(100), IN `p_numero_telefono` VARCHAR(70), IN `p_email` VARCHAR(80), IN `p_giro` VARCHAR(80), IN `p_limite_credito` DECIMAL(8,2), IN `p_estado` TINYINT(1))  BEGIN
UPDATE `cliente`
SET  `nombre_cliente` = p_nombre_cliente, `numero_nit` = p_numero_nit, `numero_nrc` = p_numero_nrc,
`direccion_cliente` = p_direccion_cliente, `numero_telefono` = p_numero_telefono, `email` = p_email,
`giro` = p_giro, `limite_credito` = p_limite_credito,
`estado` = p_estado
WHERE `idcliente` = p_idcliente;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_comprobante` (IN `p_idcomprobante` INT(11), IN `p_nombre_comprobante` VARCHAR(75), IN `p_estado` TINYINT(1))  BEGIN
UPDATE `comprobante`
SET `nombre_comprobante` = p_nombre_comprobante, `estado` = p_estado
WHERE `idcomprobante` = p_idcomprobante;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_credito` (IN `p_idcredito` INT(11), IN `p_nombre_credito` VARCHAR(120), IN `p_fecha_credito` DATETIME, IN `p_monto_credito` DECIMAL(8,2), IN `p_monto_abonado` DECIMAL(8,2), IN `p_monto_restante` DECIMAL(8,2), IN `p_estado` TINYINT(1))  BEGIN
UPDATE `credito`
SET `nombre_credito` = p_nombre_credito, `fecha_credito` = p_fecha_credito,
`monto_credito` = p_monto_credito, `monto_abonado` = p_monto_abonado, `monto_restante` = p_monto_restante,
`estado` = p_estado
WHERE `idcredito` = p_idcredito;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_credito_proveedor` (IN `p_idcreditoproveedor` INT(11), IN `p_nombre_credito` VARCHAR(120), IN `p_fecha_credito` DATETIME, IN `p_monto_credito` DECIMAL(8,2), IN `p_monto_abonado` DECIMAL(8,2), IN `p_monto_restante` DECIMAL(8,2), IN `p_estado` TINYINT(1))  BEGIN
UPDATE `creditoproveedor`
SET `nombre_credito` = p_nombre_credito, `fecha_credito` = p_fecha_credito,
`monto_credito` = p_monto_credito, `monto_abonado` = p_monto_abonado, `monto_restante` = p_monto_restante,
`estado` = p_estado
WHERE `idcreditoproveedor` = p_idcreditoproveedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_currency` (IN `p_idcurrency` INT(11), IN `p_CurrencyISO` VARCHAR(3), IN `p_Language` VARCHAR(3), IN `p_CurrencyName` VARCHAR(35), IN `p_Money` VARCHAR(30), IN `p_Symbol` VARCHAR(3))  BEGIN
UPDATE `currency` 
SET `CurrencyISO` = p_CurrencyISO, `Language` = p_Language, `CurrencyName` = p_CurrencyName, `Money` = p_Money, 
`Symbol` = p_Symbol
WHERE `idcurrency` = p_idcurrency;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_empleado` (IN `p_idempleado` INT(11), IN `p_nombre_empleado` VARCHAR(90), IN `p_apellido_empleado` VARCHAR(90), IN `p_telefono_empleado` VARCHAR(70), IN `p_email_empleado` VARCHAR(80), IN `p_estado` TINYINT(1))  BEGIN
UPDATE `empleado`
SET `nombre_empleado` = p_nombre_empleado, `apellido_empleado` = p_apellido_empleado, `telefono_empleado` = p_telefono_empleado,
`email_empleado` = p_email_empleado, `estado` = p_estado
WHERE `idempleado` = p_idempleado;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_marca` (IN `p_idmarca` INT(11), IN `p_nombre_marca` VARCHAR(120), IN `p_estado` TINYINT(1))  BEGIN
UPDATE `marca`
SET `nombre_marca` = p_nombre_marca, `estado` = p_estado
WHERE `idmarca` = p_idmarca;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_monto_inicial` (IN `p_monto_apertura` DECIMAL(8,2))  BEGIN
	IF EXISTS (SELECT * FROM `caja` WHERE DATE_FORMAT(`fecha_apertura`,'%Y-%m-%d') <= curdate()) THEN
		UPDATE `caja` SET
        `monto_apertura` =  p_monto_apertura
		WHERE DATE_FORMAT(`fecha_apertura`,'%Y-%m-%d') <= curdate() AND estado = 1;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_ordentaller` (IN `p_idorden` INT(11), IN `p_numero_orden` VARCHAR(175), IN `p_fecha_ingreso` DATETIME, IN `p_idcliente` INT(11), IN `p_aparato` VARCHAR(125), IN `p_modelo` VARCHAR(125), IN `p_idmarca` INT(11), IN `p_serie` VARCHAR(125), IN `p_idtecnico` INT(11), IN `p_averia` VARCHAR(200), IN `p_observaciones` VARCHAR(200), IN `p_deposito_revision` DECIMAL(8,2), IN `p_deposito_reparacion` DECIMAL(8,2), IN `p_diagnostico` VARCHAR(200), IN `p_estado_aparato` VARCHAR(200), IN `p_repuestos` DECIMAL(8,2), IN `p_mano_obra` DECIMAL(8,2), IN `p_fecha_alta` DATETIME, IN `p_fecha_retiro` DATETIME, IN `p_ubicacion` VARCHAR(150), IN `p_parcial_pagar` DECIMAL(8,2))  BEGIN
UPDATE `ordentaller`
SET `numero_orden` = p_numero_orden, `fecha_ingreso` = p_fecha_ingreso, `idcliente` = p_idcliente, `aparato` = p_aparato,
`modelo` = p_modelo, `idmarca` = p_idmarca, `serie` = p_serie, `idtecnico` = p_idtecnico,
`averia` = p_averia, `observaciones` = p_observaciones, `deposito_revision` = p_deposito_revision, `deposito_reparacion` = p_deposito_reparacion,
`diagnostico` = p_diagnostico, `estado_aparato` = p_estado_aparato, `repuestos` = p_repuestos, `mano_obra` = p_mano_obra,
`fecha_alta` = p_fecha_alta, `fecha_retiro` = p_fecha_retiro, `ubicacion` = p_ubicacion, `parcial_pagar` = p_parcial_pagar
WHERE `idorden` = p_idorden;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_parametro` (IN `p_idparametro` INT(11), IN `p_nombre_empresa` VARCHAR(150), IN `p_propietario` VARCHAR(150), IN `p_numero_nit` VARCHAR(70), IN `p_numero_nrc` VARCHAR(70), IN `p_porcentaje_iva` DECIMAL(8,2), IN `p_porcentaje_retencion` DECIMAL(8,2), IN `p_monto_retencion` DECIMAL(8,2), IN `p_direccion_empresa` VARCHAR(200), IN `p_idcurrency` INT(11))  BEGIN
UPDATE `parametro`
SET `nombre_empresa` = p_nombre_empresa, `propietario` = p_propietario, `numero_nit` = p_numero_nit, `numero_nrc` = p_numero_nrc,
`porcentaje_iva` = p_porcentaje_iva, `porcentaje_retencion` = p_porcentaje_retencion,
`monto_retencion` = p_monto_retencion,`direccion_empresa` = p_direccion_empresa,`idcurrency` = p_idcurrency
WHERE `idparametro` = p_idparametro;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_perecedero` (IN `p_fecha_vencimiento` DATE, IN `p_cantidad_perecedero` DECIMAL(8,2), IN `p_idproducto` INT(11))  BEGIN
  UPDATE `perecedero` SET
  `cantidad_perecedero` = p_cantidad_perecedero
   WHERE `idproducto` =  p_idproducto AND `fecha_vencimiento` = p_fecha_vencimiento;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_presentacion` (IN `p_idpresentacion` INT(11), IN `p_nombre_presentacion` VARCHAR(120), IN `p_siglas` VARCHAR(45), IN `p_estado` TINYINT(1))  BEGIN
UPDATE `presentacion`
SET `nombre_presentacion` = p_nombre_presentacion,
`siglas` = p_siglas,
`estado` = p_estado
WHERE `idpresentacion` = p_idpresentacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_producto` (IN `p_codigo_interno` VARCHAR(175), IN `p_idproducto` INT(11), IN `p_codigo_barra` VARCHAR(200), IN `p_nombre_producto` VARCHAR(175), IN `p_precio_compra` DECIMAL(8,2), IN `p_precio_venta` DECIMAL(8,2), IN `p_precio_venta_mayoreo` DECIMAL(8,2), IN `p_precio_venta_3` DECIMAL(8,2), IN `p_stock_min` DECIMAL(8,2), IN `p_idcategoria` INT(11), IN `p_idmarca` INT(11), IN `p_idpresentacion` INT(11), IN `p_estado` TINYINT(1), IN `p_exento` TINYINT(1), IN `p_inventariable` TINYINT(1), IN `p_perecedero` TINYINT(1))  BEGIN
    IF (p_inventariable = 0) THEN
        UPDATE `producto`
        SET `codigo_interno` = p_codigo_interno,  -- Agregar el nuevo campo al inicio
            `codigo_barra` = p_codigo_barra, 
            `nombre_producto` = p_nombre_producto, 
            `precio_compra` = p_precio_compra,
            `precio_venta` = p_precio_venta, 
            `precio_venta_mayoreo` = p_precio_venta_mayoreo,
            `precio_venta_3` = p_precio_venta_3,
            `stock_min` = 0, 
            `stock` = 0,
            `idcategoria` = p_idcategoria, 
            `idmarca` = p_idmarca, 
            `idpresentacion` = p_idpresentacion, 
            `estado` = p_estado,
            `exento` = p_exento, 
            `inventariable` = p_inventariable, 
            `perecedero` = p_perecedero
        WHERE `idproducto` = p_idproducto;
    ELSE
        UPDATE `producto`
        SET `codigo_interno` = p_codigo_interno,  -- Agregar el nuevo campo al inicio
            `codigo_barra` = p_codigo_barra, 
            `nombre_producto` = p_nombre_producto, 
            `precio_compra` = p_precio_compra,
            `precio_venta` = p_precio_venta, 
            `precio_venta_mayoreo` = p_precio_venta_mayoreo,
            `precio_venta_3` = p_precio_venta_3,
            `stock_min` = p_stock_min,
            `idcategoria` = p_idcategoria, 
            `idmarca` = p_idmarca, 
            `idpresentacion` = p_idpresentacion, 
            `estado` = p_estado,
            `exento` = p_exento, 
            `inventariable` = p_inventariable, 
            `perecedero` = p_perecedero
        WHERE `idproducto` = p_idproducto;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_proveedor` (IN `p_idproveedor` INT(11), IN `p_nombre_proveedor` VARCHAR(175), IN `p_numero_telefono` VARCHAR(70), IN `p_numero_nit` VARCHAR(70), IN `p_numero_nrc` VARCHAR(70), IN `p_nombre_contacto` VARCHAR(150), IN `p_telefono_contacto` VARCHAR(150), IN `p_estado` TINYINT(1))  BEGIN
UPDATE `proveedor`
SET `nombre_proveedor` = p_nombre_proveedor, `numero_telefono` = p_numero_telefono, `numero_nit` = p_numero_nit,
`numero_nrc` = p_numero_nrc, `nombre_contacto` = p_nombre_contacto, `telefono_contacto` = p_telefono_contacto, `estado` = p_estado
WHERE `idproveedor` = p_idproveedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_tecnico` (IN `p_idtecnico` INT(11), IN `p_tecnico` VARCHAR(150), IN `p_telefono` VARCHAR(70), IN `p_estado` TINYINT(1))  BEGIN
	UPDATE `tecnico`
	SET `tecnico` = p_tecnico, `telefono` = p_telefono, `estado` = p_estado
	WHERE `idtecnico` = p_idtecnico;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_tiraje_comprobante` (IN `p_idtiraje` INT(11), IN `p_fecha_resolucion` DATETIME, IN `p_numero_resolucion` VARCHAR(100), IN `p_serie` VARCHAR(175), IN `p_desde` INT(11), IN `p_hasta` INT(11), IN `p_disponibles` INT(11), IN `p_idcomprobante` INT(11))  BEGIN
UPDATE `tiraje_comprobante`
SET `fecha_resolucion` = p_fecha_resolucion, `numero_resolucion` = p_numero_resolucion, `serie` = p_serie, `desde` = p_desde,
`hasta` = p_hasta, `disponibles` = p_disponibles, `idcomprobante` = p_idcomprobante
WHERE `idtiraje` = p_idtiraje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_usuario` (IN `p_idusuario` INT(11), IN `p_usuario` VARCHAR(70), IN `p_contrasena` VARCHAR(12), IN `p_tipo_usuario` TINYINT(1), IN `p_estado` TINYINT(1), IN `p_idempleado` INT(11))  BEGIN
UPDATE `usuario`
SET `usuario` = p_usuario, `contrasena` = p_contrasena, `tipo_usuario` = p_tipo_usuario, `estado` = p_estado,
`idempleado` = p_idempleado
WHERE `idusuario` = p_idusuario;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_validar_caja` ()  BEGIN
		SET time_zone = '-05:00';
		SELECT * FROM caja WHERE DATE(fecha_apertura) <= CURDATE()
        AND estado = 1;
	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_validar_inventario` ()  BEGIN

	  DECLARE producto_count INT;
      DECLARE count_inventario INT;
      SET time_zone = '-05:00';
	  SET producto_count = (SELECT COUNT(*) FROM producto);
      SET count_inventario = (SELECT COUNT(*) FROM inventario
      WHERE fecha_apertura = DATE_FORMAT(CURDATE(),'%Y-%m-01')
      AND fecha_cierre = LAST_DAY(CURDATE()) AND estado = 1);
      

      IF(producto_count != 0)THEN

			IF(count_inventario != 0) THEN

				SELECT "VALIDADO" as respuesta;

			ELSE

				SELECT "NO EXISTE" as respuesta;

            END IF;

        ELSE

		SELECT "SIN PRODUCTOS" as respuesta;

	 END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ventas_anual` ()  BEGIN
	DECLARE count_venta INT;
    SET count_venta = (SELECT COUNT(*) FROM venta WHERE estado = 1);

	IF (count_venta > 0 ) THEN

	SELECT IF (UCASE(DATE_FORMAT(fecha_venta,'%b')) IS NULL,'0.00',
    UCASE(DATE_FORMAT(fecha_venta,'%b'))) as mes,
    IF(SUM(total) IS NULL, 0.00, SUM(total)) as total FROM venta
	WHERE YEAR(fecha_venta) = YEAR(CURDATE()) AND estado = 1 GROUP BY MONTH(fecha_venta);

    ELSE

    SELECT '-' as mes,'0.00' as total;


    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_abonos` (IN `p_idcredito` INT(11))  BEGIN
	SELECT * FROM view_abonos WHERE idcredito = p_idcredito;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_abonos_proveedor` (IN `p_idcreditoproveedor` INT(11))  BEGIN
	SELECT * FROM view_abonos_proveedor WHERE idcreditoproveedor = p_idcreditoproveedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_all_abonos` ()  BEGIN
	SELECT * FROM view_abonos;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_all_abonos_proveedor` ()  BEGIN
	SELECT * FROM view_abonos_proveedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_apartado` (IN `p_idapartado` INT(11))  BEGIN

	SELECT numero_apartado,fecha_apartado,fecha_limite_retiro,cliente,
    sumas,iva,(sumas + iva) as subtotal,
    total_exento,retenido,total_descuento,total
    FROM view_apartados WHERE idapartado = p_idapartado
    GROUP BY numero_apartado;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_categoria` ()  BEGIN
SELECT `idcategoria`, `nombre_categoria`, `estado`
FROM `categoria`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_categoria_activa` ()  BEGIN
SELECT `idcategoria`, `nombre_categoria`, `estado`
FROM `categoria` WHERE `estado` = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_cliente` ()  BEGIN
SELECT `idcliente`, `codigo_cliente`, `nombre_cliente`, `numero_nit`,
`numero_nrc`, `direccion_cliente`, `numero_telefono`, `email`,
`giro`, `limite_credito`, `estado`
FROM `cliente`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_cliente_activo` ()  BEGIN
SELECT `idcliente`, `codigo_cliente`, `nombre_cliente`, `numero_nit`,
`numero_nrc`, `direccion_cliente`, `numero_telefono`, `email`,
`giro`, `limite_credito`, `estado`
FROM `cliente` WHERE `estado` = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_cliente_inactivo` ()  BEGIN
SELECT `idcliente`, `codigo_cliente`, `nombre_cliente`, `numero_nit`,
`numero_nrc`, `direccion_cliente`, `numero_telefono`, `email`,
`giro`, `limite_credito`, `estado`
FROM `cliente` WHERE `estado` = 0;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_compra` (IN `p_idcompra` INT(11))  BEGIN

		SELECT fecha_compra,tipo_pago,nombre_proveedor,numero_nit,
		numero_comprobante,tipo_comprobante,fecha_comprobante,
        sumas,iva,(sumas + iva) as subtotal,
		total_exento,retenido,total
		FROM view_compras WHERE idcompra = p_idcompra
		GROUP BY fecha_compra,numero_comprobante;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_comprobante` ()  BEGIN
SELECT `idcomprobante`, `nombre_comprobante`, `estado`
FROM `comprobante`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_comprobante_activo` ()  BEGIN
SELECT `idcomprobante`, `nombre_comprobante` FROM `comprobante` WHERE `estado` = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_cotizacion` (IN `p_fecha` VARCHAR(32), IN `p_fecha2` VARCHAR(32))  BEGIN
	
	  IF(`p_fecha` = '' AND `p_fecha2` ='') THEN

			SELECT * FROM view_cotizaciones
			GROUP BY numero_cotizacion;

	   ELSE
			SELECT * FROM view_cotizaciones WHERE
			date(fecha_cotizacion) BETWEEN p_fecha AND p_fecha2
			GROUP BY numero_cotizacion;

	  END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_cotizacion_detalle` (`p_idcotizacion` INT)  BEGIN
	IF  p_idcotizacion  = '' THEN

		SET p_idcotizacion = (SELECT MAX(idcotizacion) FROM cotizacion);

		SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,disponible,
		nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,importe
		FROM view_cotizaciones WHERE idcotizacion = p_idcotizacion;

	ELSE

		SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,disponible,
		nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,importe
		FROM view_cotizaciones WHERE idcotizacion = p_idcotizacion;

    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_creditos` (IN `p_criterio` TINYINT(1))  BEGIN
	SELECT * FROM view_creditos_venta WHERE estado_credito = p_criterio;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_creditos_espc` (IN `p_idcredito` INT)  BEGIN
	SELECT * FROM view_creditos_venta WHERE idcredito = p_idcredito;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_creditos_espc_proveedor` (IN `p_idcreditoproveedor` INT)  BEGIN
	SELECT * FROM view_creditos_compra WHERE idcreditoproveedor = p_idcreditoproveedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_creditos_proveedor` (IN `p_criterio` TINYINT(1))  BEGIN
	SELECT * FROM view_creditos_compra WHERE estado_credito = p_criterio;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_currency` ()  BEGIN
SELECT `idcurrency`, `CurrencyISO`, `Language`, `CurrencyName`, 
`Money`, `Symbol`
FROM `currency`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_datos_caja` ()  BEGIN
   SELECT idcaja, COUNT(*) as veces_abierta, fecha_apertura, fecha_cierre , estado, monto_apertura
   FROM caja WHERE DATE(fecha_apertura) <= CURDATE()
   AND estado = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_datos_caja_fecha` (IN `p_fecha` VARCHAR(32), IN `p_idcaja` INT(11))  BEGIN
   SELECT COUNT(*) as veces_abierta, fecha_apertura, fecha_cierre , estado, monto_apertura
   FROM caja WHERE DATE(fecha_apertura) <= p_fecha
   AND idcaja = p_idcaja;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_detalleapartado` (IN `p_idapartado` INT(11))  BEGIN

	SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
	nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,importe,sumas,
	iva,total_exento,retenido,total_descuento,total,fecha_vence FROM
	view_apartados WHERE idapartado = p_idapartado;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_detallecompra` (IN `p_idcompra` INT(11))  BEGIN

		SELECT idproducto,codigo_barra,codigo_interno,fecha_vence,nombre_producto,
        nombre_marca,siglas,cantidad,precio_unitario,exento,importe,sumas,
        iva,total_exento,retenido,total FROM
        view_compras WHERE idcompra = p_idcompra;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_detalleventa` (IN `p_idventa` INT(11))  BEGIN

	SELECT idproducto,codigo_barra,codigo_interno,nombre_producto,
	nombre_marca,siglas,cantidad,precio_unitario,exento,descuento,importe,sumas,
	iva,total_exento,retenido,total_descuento,total,fecha_vence FROM
	view_ventas WHERE idventa = p_idventa;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_devoluciones_caja` ()  BEGIN
   SELECT * FROM view_caja WHERE tipo_movimiento = 2 AND DATE(fecha_apertura) = CURDATE();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_empleado` ()  BEGIN
SELECT `idempleado`, `codigo_empleado`, `nombre_empleado`, `apellido_empleado`,
`telefono_empleado`, `email_empleado`, `estado`
FROM `empleado`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_empleado_activo` ()  BEGIN
SELECT `idempleado`, `codigo_empleado`, `nombre_empleado`, `apellido_empleado`,
`telefono_empleado`, `email_empleado`, `estado`
FROM `empleado` WHERE `estado` = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_entradas` (IN `p_mes` VARCHAR(7))  BEGIN
	SET time_zone = '-05:00';
    IF (p_mes!='') THEN

		SELECT * FROM view_full_entradas WHERE DATE_FORMAT(fecha_entrada,'%Y-%m') = p_mes;
 
	ELSE

		SELECT * FROM view_full_entradas WHERE DATE_FORMAT(fecha_entrada,'%Y-%m') = DATE_FORMAT(CURDATE(),'%Y-%m');

    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_gastos_caja` ()  BEGIN
   SET time_zone = '-05:00';
   SELECT * FROM view_caja WHERE tipo_movimiento = 4 AND DATE(fecha_apertura) <= CURDATE() and estado = 1 ;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_impuesto` ()  BEGIN
SELECT `porcentaje_iva`,`porcentaje_retencion`,`monto_retencion`  FROM `parametro`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_info_cotizacion` (IN `p_idcotizacion` INT(11))  BEGIN

	IF  p_idcotizacion  = '' THEN

		SET p_idcotizacion = (SELECT MAX(idcotizacion) FROM cotizacion);

		SELECT numero_cotizacion,fecha_cotizacion,a_nombre,numero_nit,
        direccion_cliente,numero_telefono,email,tipo_pago,entrega,
		sumas,iva,(sumas + iva) as subtotal,
		total_exento,retenido,total_descuento,total,empleado
		FROM view_cotizaciones WHERE idcotizacion = p_idcotizacion
		GROUP BY numero_cotizacion;

    ELSE

		SELECT numero_cotizacion,fecha_cotizacion,a_nombre,numero_nit,
        direccion_cliente,numero_telefono,email,tipo_pago,entrega,
		sumas,iva,(sumas + iva) as subtotal,
		total_exento,retenido,total_descuento,total,empleado
		FROM view_cotizaciones WHERE idcotizacion = p_idcotizacion
		GROUP BY numero_cotizacion;

    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_ingresos_caja` ()  BEGIN

SET time_zone = '-05:00';

SELECT * FROM caja_movimiento WHERE tipo_movimiento = 1 AND DATE(fecha_movimiento) <= CURDATE() AND (SELECT `idcaja` FROM `caja` WHERE `estado`=1) = (select MAX(idcaja) from caja_movimiento) AND idcaja = (SELECT MAX(idcaja) FROM caja_movimiento);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_limite_credito` (IN `p_idcliente` INT(11))  BEGIN

  SELECT limite_credito FROM cliente
  WHERE idcliente = p_idcliente LIMIT 1;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_marca` ()  BEGIN
SELECT `idmarca`, `nombre_marca`, `estado`
FROM `marca`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_marca_activa` ()  BEGIN
SELECT `idmarca`, `nombre_marca`, `estado`
FROM `marca` WHERE `estado` = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_money` ()  BEGIN
DECLARE p_idcurrency INT;
SET p_idcurrency = (SELECT MAX(idcurrency) FROM parametro);
SELECT `CurrencyISO`,`Symbol`,`CurrencyName`
FROM `currency`
WHERE `idcurrency` = p_idcurrency;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_monto_credito` (IN `p_idcredito` INT(11))  BEGIN
	SELECT monto_restante FROM credito WHERE idcredito = p_idcredito;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_monto_credito_proveedor` (IN `p_idcreditoproveedor` INT(11))  BEGIN
	SELECT monto_restante FROM creditoproveedor WHERE idcreditoproveedor = p_idcreditoproveedor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_movimientos_caja` ()  BEGIN
   DECLARE p_ingresos decimal(8,2);
   DECLARE p_ingresos_tarjeta decimal(8,2);
   DECLARE p_ingresos_totales decimal(8,2);
   DECLARE p_devoluciones decimal(8,2);
   DECLARE p_prestamos decimal(8,2);
   DECLARE p_gastos decimal(8,2);
   DECLARE p_egresos decimal(8,2);
   DECLARE p_saldo decimal(8,2);
   DECLARE p_diferencia decimal(8,2);
   DECLARE p_total_movimiento decimal(8,2);
   DECLARE p_monto_inicial decimal(8,2);

   DECLARE c_ingresos int;
   DECLARE c_devoluciones int;
   DECLARE c_prestamos int;
   DECLARE c_gastos int;

   SET time_zone = '-05:00';
   
   SET p_ingresos = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
   DATE(fecha_apertura) <= CURDATE() AND tipo_movimiento = 1 AND estado = 1);
   
   SET p_ingresos_tarjeta = (SELECT SUM(monto_movimiento_tarjeta) FROM caja_movimiento WHERE `idcaja`= (select MAX(idcaja) from caja_movimiento) AND (SELECT `idcaja` FROM `caja` WHERE `estado`=1) = (select MAX(idcaja) from caja_movimiento)); 
   
   SET p_devoluciones = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
   DATE(fecha_apertura) <= CURDATE() AND tipo_movimiento = 2 AND estado = 1);

   SET p_prestamos = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
   DATE(fecha_apertura) <= CURDATE() AND tipo_movimiento = 3 AND estado = 1);

   SET p_gastos = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
   DATE(fecha_apertura) <= CURDATE() AND tipo_movimiento = 4 AND estado = 1);

   SET p_monto_inicial = (SELECT monto_apertura FROM caja WHERE DATE(fecha_apertura) <= CURDATE() AND estado = 1);


   SET c_ingresos = (SELECT COUNT(*) FROM view_caja WHERE
   DATE(fecha_apertura) <= CURDATE() AND tipo_movimiento = 1 AND estado = 1);

   SET c_devoluciones = (SELECT COUNT(*) FROM view_caja WHERE
   DATE(fecha_apertura) <= CURDATE() AND tipo_movimiento = 2 AND estado = 1);

   SET c_prestamos = (SELECT COUNT(*) FROM view_caja WHERE
   DATE(fecha_apertura) <= CURDATE() AND tipo_movimiento = 3 AND estado = 1);

   SET c_gastos = (SELECT COUNT(*) FROM view_caja WHERE
   DATE(fecha_apertura) <= CURDATE() AND tipo_movimiento = 4 AND estado = 1);

   IF (p_ingresos IS NULL) THEN
		SET p_ingresos = (0.00);
   END IF;
  
   IF (p_ingresos IS NULL) THEN
		SET p_ingresos_tarjeta = (0.00);
   END IF;


   IF (p_devoluciones IS NULL) THEN
      SET p_devoluciones = (0.00);
   END IF;

   IF (p_gastos IS NULL) THEN
     SET p_gastos = (0.00);
   END IF;

   IF (p_prestamos IS NULL) THEN
     SET p_prestamos = (0.00);
   END IF;

   SET p_egresos = (p_prestamos + p_gastos);
   SET p_ingresos_totales = (p_ingresos +  p_ingresos_tarjeta + p_devoluciones);
   SET p_saldo = (p_ingresos - p_egresos +  p_devoluciones);
   SET p_total_movimiento = (p_ingresos + p_egresos);
   SET p_diferencia = (p_monto_inicial + p_saldo);

   SELECT p_ingresos ,p_ingresos_tarjeta ,p_devoluciones , p_prestamos , p_gastos, p_egresos, p_saldo, p_total_movimiento,
   c_ingresos, c_devoluciones , c_prestamos , c_gastos, p_monto_inicial, p_diferencia, p_ingresos_totales;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_movimientos_caja_fecha` (IN `p_fecha` VARCHAR(32))  BEGIN

   DECLARE p_ingresos decimal(8,2);
   DECLARE p_ingresos_totales decimal(8,2);
   DECLARE p_devoluciones decimal(8,2);
   DECLARE p_prestamos decimal(8,2);
   DECLARE p_gastos decimal(8,2);
   DECLARE p_egresos decimal(8,2);
   DECLARE p_saldo decimal(8,2);
   DECLARE p_diferencia decimal(8,2);
   DECLARE p_total_movimiento decimal(8,2);
   DECLARE p_monto_inicial decimal(8,2);

   DECLARE c_ingresos int;
   DECLARE c_devoluciones int;
   DECLARE c_prestamos int;
   DECLARE c_gastos int;


   SET p_ingresos = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
   DATE(fecha_apertura) = p_fecha AND tipo_movimiento = 1);

   SET p_devoluciones = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
   DATE(fecha_apertura) = p_fecha AND tipo_movimiento = 2);

   SET p_prestamos = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
   DATE(fecha_apertura) = p_fecha AND tipo_movimiento = 3);

   SET p_gastos = (SELECT SUM(monto_movimiento) FROM view_caja WHERE
   DATE(fecha_apertura) = p_fecha AND tipo_movimiento = 4);

   SET p_monto_inicial = (SELECT monto_apertura FROM caja WHERE DATE(fecha_apertura) = p_fecha);


   SET c_ingresos = (SELECT COUNT(*) FROM view_caja WHERE
   DATE(fecha_apertura) = p_fecha AND tipo_movimiento = 1);

   SET c_devoluciones = (SELECT COUNT(*) FROM view_caja WHERE
   DATE(fecha_apertura) = p_fecha AND tipo_movimiento = 2);

   SET c_prestamos = (SELECT COUNT(*) FROM view_caja WHERE
   DATE(fecha_apertura) = p_fecha AND tipo_movimiento = 3);

   SET c_gastos = (SELECT COUNT(*) FROM view_caja WHERE
   DATE(fecha_apertura) = p_fecha AND tipo_movimiento = 4);

   IF (p_ingresos IS NULL) THEN
		SET p_ingresos = (0.00);
   END IF;

   IF (p_devoluciones IS NULL) THEN
      SET p_devoluciones = (0.00);
   END IF;


   IF (p_gastos IS NULL) THEN
     SET p_gastos = (0.00);
   END IF;

   IF (p_prestamos IS NULL) THEN
     SET p_prestamos = (0.00);
   END IF;

   SET p_egresos = (p_prestamos + p_gastos);
   SET p_ingresos_totales = (p_ingresos +  p_devoluciones);
   SET p_saldo = (p_ingresos - p_egresos +  p_devoluciones);
   SET p_total_movimiento = (p_ingresos + p_egresos);
   SET p_diferencia = (p_monto_inicial + p_saldo);

   SELECT p_ingresos, p_devoluciones , p_prestamos , p_gastos, p_egresos, p_saldo, p_total_movimiento,
   c_ingresos, c_devoluciones , c_prestamos , c_gastos, p_monto_inicial, p_diferencia, p_ingresos_totales;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_movimientos_detalle_fecha` (IN `p_fecha` VARCHAR(32), IN `p_idcaja` INT(11))  BEGIN

	SELECT *
	FROM caja_movimiento
	WHERE idcaja = p_idcaja;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_ordentaller` (IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10))  BEGIN

 IF (p_date = '' AND p_date2 = '') THEN
		SELECT * FROM view_taller ORDER BY fecha_ingreso DESC;
	ELSE
		 SELECT * FROM view_taller WHERE DATE_FORMAT(fecha_ingreso,'%Y-%m-%d') BETWEEN p_date AND p_date2
		 ORDER BY  DATE_FORMAT(fecha_ingreso,'%Y-%m-%d') DESC;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_parametro` ()  BEGIN
SELECT `idparametro`, `nombre_empresa`, `propietario`, `numero_nit`,
`numero_nrc`, `porcentaje_iva`, `porcentaje_retencion`, `monto_retencion`,
`direccion_empresa`, `logo_empresa`, `idcurrency`
FROM `parametro`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_perecedero` (IN `p_desde` DATE, IN `p_hasta` DATE)  BEGIN
	IF p_desde IS NULL AND p_hasta IS NULL THEN
		SELECT * FROM view_perecederos;
	ELSE
		SELECT * FROM view_perecederos WHERE fecha_vencimiento
		BETWEEN p_desde AND p_hasta;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_presentacion` ()  BEGIN
SELECT `idpresentacion`, `nombre_presentacion`, `siglas` , `estado`
FROM `presentacion`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_presentacion_activa` ()  BEGIN
SELECT `idpresentacion`, `nombre_presentacion`, `siglas` , `estado`
FROM `presentacion` WHERE `estado` = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_prestamos_caja` ()  BEGIN
   SELECT * FROM view_caja WHERE tipo_movimiento = 3 AND DATE(fecha_apertura) = CURDATE();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_producto` ()  BEGIN
SELECT * FROM view_productos;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_producto_activo` ()  BEGIN
SELECT * FROM view_productos WHERE estado = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_producto_agotado` ()  BEGIN
SELECT * FROM view_productos WHERE stock = 0;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_producto_inactivo` ()  BEGIN
SELECT * FROM view_productos WHERE estado = 0;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_producto_no_perecedero` ()  BEGIN
SELECT * FROM view_productos WHERE estado = 1 AND perecedero = 0 AND  stock > 0.00 AND inventariable = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_producto_perecedero` ()  BEGIN
SELECT * FROM view_productos WHERE estado = 1 AND perecedero = 1 AND  stock > 0.00 AND inventariable = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_producto_vigente` ()  BEGIN
SELECT * FROM view_productos WHERE  stock > 0.00;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_proveedor` ()  BEGIN
SELECT `idproveedor`, `codigo_proveedor`, `nombre_proveedor`, `numero_telefono`,
`numero_nit`, `numero_nrc`, `nombre_contacto`, `telefono_contacto`,
`estado`
FROM `proveedor`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_proveedor_activo` ()  BEGIN
SELECT `idproveedor`, `codigo_proveedor`, `nombre_proveedor`, `numero_telefono`,
`numero_nit`, `numero_nrc`, `nombre_contacto`, `telefono_contacto`,
`estado`
FROM `proveedor` WHERE `estado`= 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_report_ordentaller` (IN `p_id` INT)  BEGIN
	DECLARE p_idmax int;
	 IF (p_id  = '0') THEN
		SET p_idmax = (SELECT MAX(idorden) FROM ordentaller);
		SELECT * FROM view_taller WHERE idorden = p_idmax;
	 ELSE
		 SELECT * FROM view_taller WHERE idorden = p_id;
	 END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_salidas` (IN `p_mes` VARCHAR(7))  BEGIN
	SET time_zone = '-05:00';

    IF (p_mes!='') THEN

		SELECT * FROM view_full_salidas WHERE DATE_FORMAT(fecha_salida,'%Y-%m') = p_mes;
 
	ELSE

		SELECT * FROM view_full_salidas WHERE DATE_FORMAT(fecha_salida,'%Y-%m') = DATE_FORMAT(CURDATE(),'%Y-%m');
        
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_stock_producto_perecedero` (IN `p_idproducto` INT(11))  BEGIN
SELECT stock FROM view_productos WHERE estado = 1 AND perecedero = 1
AND  stock > 0.00 AND inventariable = 1 AND idproducto = p_idproducto ;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_tecnico` ()  BEGIN
	SELECT `idtecnico`, `tecnico`, `telefono`, `estado`
	FROM `tecnico`;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_tecnico_activo` ()  BEGIN
	SELECT `idtecnico`, `tecnico`, `telefono`, `estado`
	FROM `tecnico` WHERE `estado` = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_tiraje` ()  BEGIN
SELECT * FROM view_comprobantes;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_tiraje_activo` ()  BEGIN
SELECT idcomprobante, nombre_comprobante FROM view_comprobantes WHERE estado = 1 AND
disponibles > 0;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_total_abonos_fechas` (IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10))  BEGIN
		 SELECT codigo_credito, nombre_credito, monto_abono, DATE_FORMAT(fecha_abono,'%d/%m/%Y') as fecha_abono
         FROM view_abonos WHERE DATE_FORMAT(fecha_abono,'%Y-%m-%d') BETWEEN p_date AND p_date2
		 ORDER BY monto_abono, DATE_FORMAT(fecha_abono,'%d/%m/%Y')  DESC;
	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_total_abonos_proveedor_fechas` (IN `p_date` VARCHAR(10), IN `p_date2` VARCHAR(10))  BEGIN
		 SELECT codigo_credito, nombre_credito, monto_abono, DATE_FORMAT(fecha_abono,'%d/%m/%Y') as fecha_abono
         FROM view_abonos_proveedor WHERE DATE_FORMAT(fecha_abono,'%Y-%m-%d') BETWEEN p_date AND p_date2
		 ORDER BY monto_abono, DATE_FORMAT(fecha_abono,'%d/%m/%Y')  DESC;
	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_usuario` ()  BEGIN
SELECT * FROM view_usuarios;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_view_venta` (IN `p_idventa` INT(11))  BEGIN

	SELECT numero_venta,fecha_venta,tipo_pago,cliente,
    pago_efectivo,pago_tarjeta,numero_tarjeta,tarjeta_habiente,cambio,
    numero_comprobante,tipo_comprobante,sumas,iva,(sumas + iva) as subtotal,
    total_exento,retenido,total_descuento,total
    FROM view_ventas WHERE idventa = p_idventa
    GROUP BY numero_venta;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `abono`
--

CREATE TABLE `abono` (
  `idabono` int(11) NOT NULL,
  `idcredito` int(11) NOT NULL,
  `fecha_abono` datetime NOT NULL,
  `monto_abono` decimal(8,2) NOT NULL,
  `total_abonado` decimal(8,2) DEFAULT '0.00',
  `restante_credito` decimal(8,2) NOT NULL DEFAULT '0.00',
  `idusuario` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `abonoproveedor`
--

CREATE TABLE `abonoproveedor` (
  `idabonoproveedor` int(11) NOT NULL,
  `idcreditoproveedor` int(11) NOT NULL,
  `fecha_abono` datetime NOT NULL,
  `monto_abono` decimal(8,2) NOT NULL DEFAULT '0.00',
  `total_abonado` decimal(8,2) DEFAULT '0.00',
  `restante_credito` decimal(8,2) DEFAULT '0.00',
  `idusuario` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `apartado`
--

CREATE TABLE `apartado` (
  `idapartado` int(11) NOT NULL,
  `numero_apartado` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_apartado` datetime NOT NULL,
  `fecha_limite_retiro` datetime NOT NULL,
  `sumas` decimal(8,2) NOT NULL,
  `iva` decimal(8,2) NOT NULL,
  `exento` decimal(8,2) NOT NULL,
  `retenido` decimal(8,2) NOT NULL,
  `descuento` decimal(8,2) NOT NULL,
  `total` decimal(8,2) NOT NULL,
  `abonado_apartado` decimal(8,2) NOT NULL DEFAULT '0.00',
  `restante_pagar` decimal(8,2) NOT NULL DEFAULT '0.00',
  `sonletras` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `idcliente` int(11) DEFAULT NULL,
  `idusuario` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `apartado`
--
DELIMITER $$
CREATE TRIGGER `generar_numero_apartado` BEFORE INSERT ON `apartado` FOR EACH ROW BEGIN
    
        DECLARE numero INT(11);

        SET numero = (SELECT max(idapartado) FROM apartado);
        
		IF numero IS NULL then
		  set numero=1;
        SET NEW.numero_apartado='APR00000001';

		ELSEIF numero >= 1 and numero < 9 then
			set numero=numero+1;
		SET NEW.numero_apartado=(select concat('APR0000000',CAST(numero AS CHAR)));
        
		ELSEIF numero >=9 and numero<=99 then
			set numero=numero+1;
		SET NEW.numero_apartado=(select concat('APR000000',CAST(numero AS CHAR)));
            
		ELSEIF numero>=99 and numero<=999 then
			set numero=numero+1;
		SET NEW.numero_apartado=(select concat('APR00000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=999 and numero<=9999 then
		   set numero=numero+1;
		SET NEW.numero_apartado=(select concat('APR0000',CAST(numero AS CHAR)));
           
		ELSEIF numero>=9999 and numero<=99999 then
			set numero=numero+1;
		SET NEW.numero_apartado=(select concat('APR000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=99999 and numero<=999999 then
			set numero=numero+1;
		SET NEW.numero_apartado=(select concat('APR00',CAST(numero AS CHAR)));
            
		ELSEIF numero>=999999 and numero<=9999999 then
			set numero=numero+1;
		SET NEW.numero_apartado=(select concat('APR0',CAST(numero AS CHAR)));
            
        ELSEIF numero>=9999999  then -- DIEZ MILLONES EN DELANTE
			set numero=numero+1;
		SET NEW.numero_apartado=(select concat('APR',CAST(numero AS CHAR)));
            
		END IF;
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `caja`
--

CREATE TABLE `caja` (
  `idcaja` int(11) NOT NULL,
  `fecha_apertura` datetime NOT NULL,
  `monto_apertura` decimal(8,2) NOT NULL,
  `monto_cierre` decimal(8,2) DEFAULT '0.00',
  `fecha_cierre` datetime DEFAULT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `caja_movimiento`
--

CREATE TABLE `caja_movimiento` (
  `idcaja` int(11) NOT NULL,
  `tipo_movimiento` tinyint(1) NOT NULL DEFAULT '0',
  `monto_movimiento` decimal(8,2) NOT NULL,
  `descripcion_movimiento` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_movimiento` date NOT NULL,
  `monto_movimiento_tarjeta` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria`
--

CREATE TABLE `categoria` (
  `idcategoria` int(11) NOT NULL,
  `nombre_categoria` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `categoria`
--

INSERT INTO `categoria` (`idcategoria`, `nombre_categoria`, `estado`) VALUES
(1, 'ELECTRONICO', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `idcliente` int(11) NOT NULL,
  `codigo_cliente` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nombre_cliente` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_nit` varchar(70) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_nrc` varchar(70) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `direccion_cliente` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_telefono` varchar(70) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `giro` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `limite_credito` decimal(8,2) NOT NULL DEFAULT '0.00',
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`idcliente`, `codigo_cliente`, `nombre_cliente`, `numero_nit`, `numero_nrc`, `direccion_cliente`, `numero_telefono`, `email`, `giro`, `limite_credito`, `estado`) VALUES
(1, 'CL00000001', 'ESTUARDO GARCIA', '43416241', 'undefined', 'BARRIO CHILIMA, CHICHICASTENANGO, QUICHE, GUATEMALA', '42070947', 'estgar@gmail.com', 'CARPINTERO', '1000.00', 1);

--
-- Disparadores `cliente`
--
DELIMITER $$
CREATE TRIGGER `generar_codigo_cliente` BEFORE INSERT ON `cliente` FOR EACH ROW BEGIN
    
        DECLARE numero INT;

        SET numero = (SELECT max(idcliente) FROM cliente);
        
		IF numero IS NULL then
		  set numero=1;
        SET NEW.codigo_cliente='CL00000001';

		ELSEIF numero >= 1 and numero < 9 then
			set numero=numero+1;
		SET NEW.codigo_cliente=(select concat('CL0000000',CAST(numero AS CHAR)));
        
		ELSEIF numero >=9 and numero<=99 then
			set numero=numero+1;
		SET NEW.codigo_cliente=(select concat('CL000000',CAST(numero AS CHAR)));
            
		ELSEIF numero>=99 and numero<=999 then
			set numero=numero+1;
		SET NEW.codigo_cliente=(select concat('CL00000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=999 and numero<=9999 then
		   set numero=numero+1;
		SET NEW.codigo_cliente=(select concat('CL0000',CAST(numero AS CHAR)));
           
		ELSEIF numero>=9999 and numero<=99999 then
			set numero=numero+1;
		SET NEW.codigo_cliente=(select concat('CL000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=99999 and numero<=999999 then
			set numero=numero+1;
		SET NEW.codigo_cliente=(select concat('CL00',CAST(numero AS CHAR)));
            
		ELSEIF numero>=999999 and numero<=9999999 then
			set numero=numero+1;
		SET NEW.codigo_cliente=(select concat('CL0',CAST(numero AS CHAR)));
            
        ELSEIF numero>=9999999  then -- DIEZ MILLONES EN DELANTE
			set numero=numero+1;
		SET NEW.codigo_cliente=(select concat('CL',CAST(numero AS CHAR)));
            
		END IF;
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compra`
--

CREATE TABLE `compra` (
  `idcompra` int(11) NOT NULL,
  `fecha_compra` datetime NOT NULL,
  `idproveedor` int(11) NOT NULL,
  `tipo_pago` varchar(75) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_comprobante` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo_comprobante` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_comprobante` date DEFAULT NULL,
  `sumas` decimal(8,2) NOT NULL,
  `iva` decimal(8,2) NOT NULL,
  `exento` decimal(8,2) NOT NULL,
  `retenido` decimal(8,2) NOT NULL,
  `total` decimal(8,2) NOT NULL,
  `sonletras` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `comprobante`
--

CREATE TABLE `comprobante` (
  `idcomprobante` int(11) NOT NULL,
  `nombre_comprobante` varchar(75) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `comprobante`
--

INSERT INTO `comprobante` (`idcomprobante`, `nombre_comprobante`, `estado`) VALUES
(1, 'TICKET', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cotizacion`
--

CREATE TABLE `cotizacion` (
  `idcotizacion` int(11) NOT NULL,
  `numero_cotizacion` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_cotizacion` datetime NOT NULL,
  `a_nombre` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipo_pago` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entrega` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sumas` decimal(8,2) NOT NULL,
  `iva` decimal(8,2) NOT NULL,
  `exento` decimal(8,2) NOT NULL,
  `retenido` decimal(8,2) NOT NULL,
  `descuento` decimal(8,2) NOT NULL,
  `total` decimal(8,2) NOT NULL,
  `sonletras` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `idusuario` int(11) NOT NULL,
  `idcliente` int(11) NOT NULL,
  `CURRENT_TIMESTAMP` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `lastUpdated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `cotizacion`
--
DELIMITER $$
CREATE TRIGGER `generar_numero_cotizacion` BEFORE INSERT ON `cotizacion` FOR EACH ROW BEGIN
    
        DECLARE numero INT(11);

        SET numero = (SELECT max(idcotizacion) FROM cotizacion);
        
		IF numero IS NULL then
		  set numero=1;
        SET NEW.numero_cotizacion='COTI00000001';

		ELSEIF numero >= 1 and numero < 9 then
			set numero=numero+1;
		SET NEW.numero_cotizacion=(select concat('COTI0000000',CAST(numero AS CHAR)));
        
		ELSEIF numero >=9 and numero<=99 then
			set numero=numero+1;
		SET NEW.numero_cotizacion=(select concat('COTI000000',CAST(numero AS CHAR)));
            
		ELSEIF numero>=99 and numero<=999 then
			set numero=numero+1;
		SET NEW.numero_cotizacion=(select concat('COTI00000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=999 and numero<=9999 then
		   set numero=numero+1;
		SET NEW.numero_cotizacion=(select concat('COTI0000',CAST(numero AS CHAR)));
           
		ELSEIF numero>=9999 and numero<=99999 then
			set numero=numero+1;
		SET NEW.numero_cotizacion=(select concat('COTI000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=99999 and numero<=999999 then
			set numero=numero+1;
		SET NEW.numero_cotizacion=(select concat('COTI00',CAST(numero AS CHAR)));
            
		ELSEIF numero>=999999 and numero<=9999999 then
			set numero=numero+1;
		SET NEW.numero_cotizacion=(select concat('COTI0',CAST(numero AS CHAR)));
            
        ELSEIF numero>=9999999  then -- DIEZ MILLONES EN DELANTE
			set numero=numero+1;
		SET NEW.numero_cotizacion=(select concat('COTI',CAST(numero AS CHAR)));
            
		END IF;
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `credito`
--

CREATE TABLE `credito` (
  `idcredito` int(11) NOT NULL,
  `idventa` int(11) DEFAULT NULL,
  `codigo_credito` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nombre_credito` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_credito` datetime NOT NULL,
  `monto_credito` decimal(8,2) NOT NULL,
  `monto_abonado` decimal(8,2) NOT NULL DEFAULT '0.00',
  `monto_restante` decimal(8,2) NOT NULL DEFAULT '0.00',
  `estado` tinyint(1) NOT NULL DEFAULT '0',
  `idcliente` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `credito`
--
DELIMITER $$
CREATE TRIGGER `generar_numero_credito` BEFORE INSERT ON `credito` FOR EACH ROW BEGIN
    
        DECLARE numero INT(11);

        SET numero = (SELECT max(idcredito) FROM credito);
        
		IF numero IS NULL then
		  set numero=1;
        SET NEW.codigo_credito='CRED00000001';

		ELSEIF numero >= 1 and numero < 9 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED0000000',CAST(numero AS CHAR)));
        
		ELSEIF numero >=9 and numero<=99 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED000000',CAST(numero AS CHAR)));
            
		ELSEIF numero>=99 and numero<=999 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED00000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=999 and numero<=9999 then
		   set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED0000',CAST(numero AS CHAR)));
           
		ELSEIF numero>=9999 and numero<=99999 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=99999 and numero<=999999 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED00',CAST(numero AS CHAR)));
            
		ELSEIF numero>=999999 and numero<=9999999 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED0',CAST(numero AS CHAR)));
            
        ELSEIF numero>=9999999  then -- DIEZ MILLONES EN DELANTE
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED',CAST(numero AS CHAR)));
            
		END IF;
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `creditoproveedor`
--

CREATE TABLE `creditoproveedor` (
  `idcreditoproveedor` int(11) NOT NULL,
  `idcompra` int(11) NOT NULL,
  `codigo_credito` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nombre_credito` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_credito` datetime NOT NULL,
  `monto_credito` decimal(8,2) NOT NULL DEFAULT '0.00',
  `monto_abonado` decimal(8,2) NOT NULL DEFAULT '0.00',
  `monto_restante` decimal(8,2) NOT NULL DEFAULT '0.00',
  `estado` tinyint(1) DEFAULT '0',
  `idproveedor` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `creditoproveedor`
--
DELIMITER $$
CREATE TRIGGER `generar_numero_credito_proveedor` BEFORE INSERT ON `creditoproveedor` FOR EACH ROW BEGIN
    
        DECLARE numero INT(11);

        SET numero = (SELECT max(idcreditoproveedor) FROM creditoproveedor);
        
		IF numero IS NULL then
		  set numero=1;
        SET NEW.codigo_credito='CRED00000001';

		ELSEIF numero >= 1 and numero < 9 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED0000000',CAST(numero AS CHAR)));
        
		ELSEIF numero >=9 and numero<=99 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED000000',CAST(numero AS CHAR)));
            
		ELSEIF numero>=99 and numero<=999 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED00000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=999 and numero<=9999 then
		   set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED0000',CAST(numero AS CHAR)));
           
		ELSEIF numero>=9999 and numero<=99999 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=99999 and numero<=999999 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED00',CAST(numero AS CHAR)));
            
		ELSEIF numero>=999999 and numero<=9999999 then
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED0',CAST(numero AS CHAR)));
            
        ELSEIF numero>=9999999  then -- DIEZ MILLONES EN DELANTE
			set numero=numero+1;
		SET NEW.codigo_credito=(select concat('CRED',CAST(numero AS CHAR)));
            
		END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `currency`
--

CREATE TABLE `currency` (
  `idcurrency` int(11) NOT NULL,
  `CurrencyISO` varchar(3) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Language` varchar(3) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `CurrencyName` varchar(35) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Money` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Symbol` varchar(3) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `currency`
--

INSERT INTO `currency` (`idcurrency`, `CurrencyISO`, `Language`, `CurrencyName`, `Money`, `Symbol`) VALUES
(1, 'QTG', 'ES', 'Quetzal Guatemala', 'QTG', 'Q.'),
(2, 'QGT', 'ES', 'QUETZAL', 'QGT', 'Q.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalleapartado`
--

CREATE TABLE `detalleapartado` (
  `idapartado` int(11) NOT NULL,
  `idproducto` int(11) NOT NULL,
  `cantidad` decimal(8,2) NOT NULL,
  `precio_unitario` decimal(8,2) NOT NULL,
  `fecha_vence` date DEFAULT NULL,
  `exento` decimal(8,2) NOT NULL,
  `descuento` decimal(8,2) NOT NULL,
  `importe` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detallecompra`
--

CREATE TABLE `detallecompra` (
  `idcompra` int(11) NOT NULL,
  `idproducto` int(11) NOT NULL,
  `fecha_vence` date DEFAULT NULL,
  `cantidad` decimal(8,2) NOT NULL,
  `precio_unitario` decimal(8,2) NOT NULL,
  `exento` decimal(8,2) NOT NULL,
  `importe` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detallecotizacion`
--

CREATE TABLE `detallecotizacion` (
  `idcotizacion` int(11) NOT NULL,
  `idproducto` int(11) NOT NULL,
  `cantidad` decimal(8,2) NOT NULL,
  `disponible` tinyint(1) NOT NULL,
  `precio_unitario` decimal(8,2) NOT NULL,
  `exento` decimal(8,2) NOT NULL,
  `descuento` decimal(8,2) NOT NULL,
  `importe` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalleventa`
--

CREATE TABLE `detalleventa` (
  `idventa` int(11) NOT NULL,
  `idproducto` int(11) NOT NULL,
  `cantidad` decimal(8,2) NOT NULL,
  `precio_unitario` decimal(8,2) NOT NULL,
  `fecha_vence` date DEFAULT NULL,
  `exento` decimal(8,2) NOT NULL,
  `descuento` decimal(8,2) NOT NULL,
  `importe` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empleado`
--

CREATE TABLE `empleado` (
  `idempleado` int(11) NOT NULL,
  `codigo_empleado` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nombre_empleado` varchar(90) COLLATE utf8mb4_unicode_ci NOT NULL,
  `apellido_empleado` varchar(90) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telefono_empleado` varchar(70) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_empleado` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `empleado`
--

INSERT INTO `empleado` (`idempleado`, `codigo_empleado`, `nombre_empleado`, `apellido_empleado`, `telefono_empleado`, `email_empleado`, `estado`) VALUES
(1, 'EM00000001', 'ESTUARDO', 'GARCIA', '42070947', 'garciest@gmail.com', 1),
(2, 'EM00000002', 'DANIEL', 'SUC GARCIA', '31566431', 'dsuc@gmail.com', 1),
(3, 'EM00000003', 'EDGAR', 'MORALES', '46627074', 'emorales@gmail.com', 1),
(4, 'EM00000004', 'MIDORI', 'GOYO', '944322351', '', 1),
(5, 'EM00000005', 'RAUL', 'LLAMOSAS', '986375192', 'llamosasraul@gmail.com', 1);

--
-- Disparadores `empleado`
--
DELIMITER $$
CREATE TRIGGER `generar_codigo_empleado` BEFORE INSERT ON `empleado` FOR EACH ROW BEGIN
    
        DECLARE numero INT;
        
        SET numero = (SELECT max(idempleado) FROM empleado);
        
		IF numero IS NULL then
		  set numero=1;
        SET NEW.codigo_empleado='EM00000001';

		ELSEIF numero >= 1 and numero < 9 then
			set numero=numero+1;
		SET NEW.codigo_empleado=(select concat('EM0000000',CAST(numero AS CHAR)));
        
		ELSEIF numero >=9 and numero<=99 then
			set numero=numero+1;
		SET NEW.codigo_empleado=(select concat('EM000000',CAST(numero AS CHAR)));
            
		ELSEIF numero>=99 and numero<=999 then
			set numero=numero+1;
		SET NEW.codigo_empleado=(select concat('EM00000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=999 and numero<=9999 then
		   set numero=numero+1;
		SET NEW.codigo_empleado=(select concat('EM0000',CAST(numero AS CHAR)));
           
		ELSEIF numero>=9999 and numero<=99999 then
			set numero=numero+1;
		SET NEW.codigo_empleado=(select concat('EM000',CAST(numero AS CHAR)));
             

		ELSEIF numero>=99999 and numero<=999999 then
			set numero=numero+1;
		SET NEW.codigo_empleado=(select concat('EM00',CAST(numero AS CHAR)));
            

		ELSEIF numero>=999999 and numero<=9999999 then
			set numero=numero+1;
		SET NEW.codigo_empleado=(select concat('EM0',CAST(numero AS CHAR)));
            
        ELSEIF numero>=9999999  then -- DIEZ MILLONES EN DELANTE
			set numero=numero+1;
		SET NEW.codigo_empleado=(select concat('EM',CAST(numero AS CHAR)));
            
		END IF;
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `entrada`
--

CREATE TABLE `entrada` (
  `identrada` int(11) NOT NULL,
  `mes_inventario` varchar(7) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_entrada` date NOT NULL,
  `descripcion_entrada` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cantidad_entrada` decimal(8,2) NOT NULL,
  `precio_unitario_entrada` decimal(8,2) NOT NULL,
  `costo_total_entrada` decimal(8,2) NOT NULL,
  `idproducto` int(11) NOT NULL,
  `idcompra` int(11) DEFAULT NULL,
  `idapartado` int(11) DEFAULT NULL,
  `CREATE_TIMESTAMP` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lastUpdated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `entrada`
--

INSERT INTO `entrada` (`identrada`, `mes_inventario`, `fecha_entrada`, `descripcion_entrada`, `cantidad_entrada`, `precio_unitario_entrada`, `costo_total_entrada`, `idproducto`, `idcompra`, `idapartado`, `CREATE_TIMESTAMP`, `lastUpdated`) VALUES
(1, '2024-02', '2024-02-03', 'INVENTARIO INICIAL', '20.00', '30.00', '600.00', 1, NULL, NULL, '2024-02-03 18:25:51', '2024-02-03 18:25:51'),
(2, '2024-02', '2024-02-03', 'INVENTARIO INICIAL', '10.00', '1000.00', '10000.00', 2, NULL, NULL, '2024-02-03 18:43:54', '2024-02-03 18:43:54'),
(3, '2024-02', '2024-02-03', 'INVENTARIO INICIAL', '20.00', '400.00', '8000.00', 3, NULL, NULL, '2024-02-03 18:44:40', '2024-02-03 18:44:40'),
(4, '2024-02', '2024-02-03', 'INVENTARIO INICIAL', '50.00', '60.00', '3000.00', 4, NULL, NULL, '2024-02-03 18:53:23', '2024-02-03 18:53:23'),
(5, '2024-02', '2024-02-03', 'INVENTARIO INICIAL', '20.00', '500.00', '10000.00', 5, NULL, NULL, '2024-02-03 19:30:38', '2024-02-03 19:30:38');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inventario`
--

CREATE TABLE `inventario` (
  `mes_inventario` varchar(7) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_apertura` date NOT NULL,
  `fecha_cierre` date NOT NULL,
  `saldo_inicial` decimal(8,2) NOT NULL,
  `entradas` decimal(8,2) DEFAULT NULL,
  `salidas` decimal(8,2) DEFAULT NULL,
  `saldo_final` decimal(8,2) NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `idproducto` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `inventario`
--

INSERT INTO `inventario` (`mes_inventario`, `fecha_apertura`, `fecha_cierre`, `saldo_inicial`, `entradas`, `salidas`, `saldo_final`, `estado`, `idproducto`) VALUES
('2024-02', '2024-02-01', '2024-02-29', '20.00', '20.00', '0.00', '20.00', 1, 1),
('2024-02', '2024-02-01', '2024-02-29', '10.00', '10.00', '0.00', '10.00', 1, 2),
('2024-02', '2024-02-01', '2024-02-29', '20.00', '20.00', '0.00', '20.00', 1, 3),
('2024-02', '2024-02-01', '2024-02-29', '50.00', '50.00', '0.00', '50.00', 1, 4),
('2024-02', '2024-02-01', '2024-02-29', '20.00', '20.00', '0.00', '20.00', 1, 5);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `marca`
--

CREATE TABLE `marca` (
  `idmarca` int(11) NOT NULL,
  `nombre_marca` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `marca`
--

INSERT INTO `marca` (`idmarca`, `nombre_marca`, `estado`) VALUES
(1, 'LG', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ordentaller`
--

CREATE TABLE `ordentaller` (
  `idorden` int(11) NOT NULL,
  `numero_orden` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_ingreso` datetime NOT NULL,
  `idcliente` int(11) NOT NULL,
  `aparato` varchar(125) COLLATE utf8mb4_unicode_ci NOT NULL,
  `modelo` varchar(125) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `idmarca` int(11) NOT NULL,
  `serie` varchar(125) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `idtecnico` int(11) NOT NULL,
  `averia` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `observaciones` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deposito_revision` decimal(8,2) NOT NULL DEFAULT '0.00',
  `deposito_reparacion` decimal(8,2) DEFAULT '0.00',
  `diagnostico` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado_aparato` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `repuestos` decimal(8,2) NOT NULL DEFAULT '0.00',
  `mano_obra` decimal(8,2) DEFAULT '0.00',
  `fecha_alta` datetime DEFAULT NULL,
  `fecha_retiro` datetime DEFAULT NULL,
  `ubicacion` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `parcial_pagar` decimal(8,2) NOT NULL DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `ordentaller`
--
DELIMITER $$
CREATE TRIGGER `generar_codigo_ordentaller` BEFORE INSERT ON `ordentaller` FOR EACH ROW BEGIN
    
        DECLARE numero INT;
        
        SET numero = (SELECT max(idorden) FROM ordentaller);
 
		IF numero IS NULL then
		  set numero=1;
        SET NEW.numero_orden ='00000001';

		ELSEIF numero >= 1 and numero < 9 then
			set numero=numero+1;
		SET NEW.numero_orden =(select concat('0000000',CAST(numero AS CHAR)));
        
		ELSEIF numero >=9 and numero<=99 then
			set numero=numero+1;
		SET NEW.numero_orden =(select concat('000000',CAST(numero AS CHAR)));
            
		ELSEIF numero>=99 and numero<=999 then
			set numero=numero+1;
		SET NEW.numero_orden =(select concat('00000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=999 and numero<=9999 then
		   set numero=numero+1;
		SET NEW.numero_orden =(select concat('0000',CAST(numero AS CHAR)));
           
		ELSEIF numero>=9999 and numero<=99999 then
			set numero=numero+1;
		SET NEW.numero_orden =(select concat('000',CAST(numero AS CHAR)));
             

		ELSEIF numero>=99999 and numero<=999999 then
			set numero=numero+1;
		SET NEW.numero_orden =(select concat('00',CAST(numero AS CHAR)));
            

		ELSEIF numero>=999999 and numero<=9999999 then
			set numero=numero+1;
		SET NEW.numero_orden =(select concat('0',CAST(numero AS CHAR)));
            
        ELSEIF numero>=9999999  then -- DIEZ MILLONES EN DELANTE
			set numero=numero+1;
		SET NEW.numero_orden =(numero);
            
		END IF;
        
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `parametro`
--

CREATE TABLE `parametro` (
  `idparametro` int(11) NOT NULL,
  `nombre_empresa` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `propietario` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_nit` varchar(70) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_nrc` varchar(70) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `porcentaje_iva` decimal(8,2) NOT NULL,
  `porcentaje_retencion` decimal(8,2) DEFAULT NULL,
  `monto_retencion` decimal(8,2) DEFAULT NULL,
  `direccion_empresa` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logo_empresa` varchar(90) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `idcurrency` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `parametro`
--

INSERT INTO `parametro` (`idparametro`, `nombre_empresa`, `propietario`, `numero_nit`, `numero_nrc`, `porcentaje_iva`, `porcentaje_retencion`, `monto_retencion`, `direccion_empresa`, `logo_empresa`, `idcurrency`) VALUES
(1, 'FERRE LA CRUZ', 'JOSE DANIEL SUCUC GARCIA', '2680160890402', '64465217', '18.00', '0.00', '0.00', 'SECTOR LA CRUZ, CHULUMAL PRIMERO, CHICHICASTENAGO.                      QUICHE GUATEMALA', NULL, 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perecedero`
--

CREATE TABLE `perecedero` (
  `fecha_vencimiento` date NOT NULL,
  `cantidad_perecedero` decimal(8,2) NOT NULL,
  `idproducto` int(11) NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `presentacion`
--

CREATE TABLE `presentacion` (
  `idpresentacion` int(11) NOT NULL,
  `nombre_presentacion` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `siglas` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `presentacion`
--

INSERT INTO `presentacion` (`idpresentacion`, `nombre_presentacion`, `siglas`, `estado`) VALUES
(1, 'UNIDAD', 'UNIDAD', 1),
(2, 'DOCENAS', 'DOCENAS', 1),
(3, 'CAJA', 'CAJA', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `idproducto` int(11) NOT NULL,
  `codigo_interno` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `codigo_barra` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nombre_producto` varchar(175) COLLATE utf8mb4_unicode_ci NOT NULL,
  `precio_compra` decimal(8,2) NOT NULL,
  `precio_venta` decimal(8,2) NOT NULL,
  `precio_venta_mayoreo` decimal(8,2) NOT NULL,
  `precio_venta_3` decimal(8,2) NOT NULL,
  `stock` decimal(8,2) NOT NULL DEFAULT '0.00',
  `stock_min` decimal(8,2) NOT NULL DEFAULT '1.00',
  `idcategoria` int(11) NOT NULL,
  `idmarca` int(11) DEFAULT NULL,
  `idpresentacion` int(11) NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `exento` tinyint(1) NOT NULL DEFAULT '0',
  `inventariable` tinyint(1) NOT NULL DEFAULT '1',
  `perecedero` tinyint(1) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`idproducto`, `codigo_interno`, `codigo_barra`, `nombre_producto`, `precio_compra`, `precio_venta`, `precio_venta_mayoreo`, `precio_venta_3`, `stock`, `stock_min`, `idcategoria`, `idmarca`, `idpresentacion`, `estado`, `exento`, `inventariable`, `perecedero`) VALUES
(1, 'KJZZ111', '', 'MAQUINA DE ESCRIBIR A MANO', '30.00', '40.00', '50.00', '60.00', '20.00', '3.00', 1, 1, 1, 1, 0, 1, 0),
(2, 'Z002SAF', '', 'MONITOR 27 PULGADAS XX', '1000.00', '1200.00', '1500.00', '1700.00', '10.00', '5.00', 1, 1, 1, 1, 0, 1, 0),
(3, 'F001ZCD', '', 'ESCRITORIO', '400.00', '500.00', '600.00', '700.00', '20.00', '5.00', 1, 1, 1, 1, 0, 1, 0),
(4, 'MLX0001', '', 'MOUSE HALION', '60.00', '70.00', '80.00', '100.00', '50.00', '6.00', 1, 1, 1, 1, 0, 1, 0),
(5, 'KAZ0001', '', 'CELULAR', '500.00', '600.00', '700.00', '750.00', '20.00', '5.00', 1, 1, 2, 1, 0, 1, 0);

--
-- Disparadores `producto`
--
DELIMITER $$
CREATE TRIGGER `insertar_nuevo_producto_inventario` AFTER INSERT ON `producto` FOR EACH ROW BEGIN
    DECLARE p_idproducto INT;
    DECLARE p_stock INT;
    DECLARE p_precio DECIMAL(8,2);
    DECLARE p_costo_total DECIMAL(8,2);
    
	SET p_idproducto = (SELECT MAX(idproducto) FROM producto);
    SET p_stock = (SELECT stock FROM producto WHERE idproducto = p_idproducto);
    SET p_precio = (SELECT precio_compra FROM producto WHERE idproducto = p_idproducto);
    
    SET p_costo_total = p_stock * p_precio;
    
    INSERT INTO inventario (mes_inventario,fecha_apertura,fecha_cierre,saldo_inicial,entradas,salidas,saldo_final,estado,idproducto)
    SELECT DATE_FORMAT(CURDATE(),'%Y-%m'),DATE_FORMAT(CURDATE(),'%Y-%m-01'),LAST_DAY(CURDATE()),p_stock,p_stock,0,p_stock,1,p_idproducto;
	
    INSERT INTO entrada (mes_inventario,fecha_entrada,descripcion_entrada,
    cantidad_entrada,precio_unitario_entrada,costo_total_entrada,idproducto,idcompra)
    VALUES (DATE_FORMAT(CURDATE(),'%Y-%m'),CURDATE(),'INVENTARIO INICIAL',p_stock,p_precio,
    p_costo_total,p_idproducto,NULL);

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto_proveedor`
--

CREATE TABLE `producto_proveedor` (
  `idproveedor` int(11) NOT NULL,
  `idproducto` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor`
--

CREATE TABLE `proveedor` (
  `idproveedor` int(11) NOT NULL,
  `codigo_proveedor` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nombre_proveedor` varchar(175) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_telefono` varchar(70) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_nit` varchar(70) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_nrc` varchar(70) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre_contacto` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telefono_contacto` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `proveedor`
--
DELIMITER $$
CREATE TRIGGER `generar_codigo_proveedor` BEFORE INSERT ON `proveedor` FOR EACH ROW BEGIN
    
        DECLARE numero INT;
        
        SET numero = (SELECT max(idproveedor) FROM proveedor);
 
		IF numero IS NULL then
		  set numero=1;
        SET NEW.codigo_proveedor ='PROV00000001';

		ELSEIF numero >= 1 and numero < 9 then
			set numero=numero+1;
		SET NEW.codigo_proveedor =(select concat('PROV0000000',CAST(numero AS CHAR)));
        
		ELSEIF numero >=9 and numero<=99 then
			set numero=numero+1;
		SET NEW.codigo_proveedor =(select concat('PROV000000',CAST(numero AS CHAR)));
            
		ELSEIF numero>=99 and numero<=999 then
			set numero=numero+1;
		SET NEW.codigo_proveedor =(select concat('PROV00000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=999 and numero<=9999 then
		   set numero=numero+1;
		SET NEW.codigo_proveedor =(select concat('PROV0000',CAST(numero AS CHAR)));
           
		ELSEIF numero>=9999 and numero<=99999 then
			set numero=numero+1;
		SET NEW.codigo_proveedor =(select concat('PROV000',CAST(numero AS CHAR)));
             

		ELSEIF numero>=99999 and numero<=999999 then
			set numero=numero+1;
		SET NEW.codigo_proveedor =(select concat('PROV00',CAST(numero AS CHAR)));
            

		ELSEIF numero>=999999 and numero<=9999999 then
			set numero=numero+1;
		SET NEW.codigo_proveedor =(select concat('PROV0',CAST(numero AS CHAR)));
            
        ELSEIF numero>=9999999  then -- DIEZ MILLONES EN DELANTE
			set numero=numero+1;
		SET NEW.codigo_proveedor =(select concat('PROV',CAST(numero AS CHAR)));
            
		END IF;
        
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor_precio`
--

CREATE TABLE `proveedor_precio` (
  `idproveedor` int(11) NOT NULL,
  `idproducto` int(11) NOT NULL,
  `fecha_precio` date NOT NULL,
  `precio_compra` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `salida`
--

CREATE TABLE `salida` (
  `idsalida` int(11) NOT NULL,
  `mes_inventario` varchar(7) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_salida` date NOT NULL,
  `descripcion_salida` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cantidad_salida` decimal(8,2) NOT NULL,
  `precio_unitario_salida` decimal(8,2) NOT NULL,
  `costo_total_salida` decimal(8,2) NOT NULL,
  `idproducto` int(11) NOT NULL,
  `idventa` int(11) DEFAULT NULL,
  `idapartado` int(11) DEFAULT NULL,
  `CURRENT_TIMESTAMP` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `lastUpdated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tecnico`
--

CREATE TABLE `tecnico` (
  `idtecnico` int(11) NOT NULL,
  `tecnico` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telefono` varchar(70) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tiraje_comprobante`
--

CREATE TABLE `tiraje_comprobante` (
  `idtiraje` int(11) NOT NULL,
  `fecha_resolucion` datetime NOT NULL,
  `numero_resolucion` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `serie` varchar(175) COLLATE utf8mb4_unicode_ci NOT NULL,
  `desde` int(11) NOT NULL,
  `hasta` int(11) NOT NULL,
  `idcomprobante` int(11) NOT NULL,
  `disponibles` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tiraje_comprobante`
--

INSERT INTO `tiraje_comprobante` (`idtiraje`, `fecha_resolucion`, `numero_resolucion`, `serie`, `desde`, `hasta`, `idcomprobante`, `disponibles`) VALUES
(1, '2024-01-01 00:23:11', 'R00101001', 'D00101101', 1, 1000000, 1, 1000000),
(2, '2019-08-03 00:23:11', '1214584575', '11545887911', 1, 100000000, 2, 100000000),
(3, '2017-11-28 10:56:11', '15415421542', '6554512412', 1, 100000000, 3, 100000000);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `idusuario` int(11) NOT NULL,
  `usuario` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contrasena` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo_usuario` tinyint(1) NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `idempleado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`idusuario`, `usuario`, `contrasena`, `tipo_usuario`, `estado`, `idempleado`) VALUES
(1, 'admin', 'admin', 1, 1, 1),
(2, 'dsuc', 'dsuc001', 1, 1, 2),
(3, 'Ventas01', 'Vsuc001', 2, 1, 3),
(4, 'MIDORI', 'Micarolina16', 1, 1, 4),
(5, 'RAUL', '2265825', 1, 1, 5);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta`
--

CREATE TABLE `venta` (
  `idventa` int(11) NOT NULL,
  `numero_venta` varchar(175) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_venta` datetime NOT NULL,
  `tipo_pago` varchar(75) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_comprobante` int(11) NOT NULL,
  `tipo_comprobante` tinyint(1) NOT NULL,
  `sumas` decimal(8,2) NOT NULL,
  `iva` decimal(8,2) NOT NULL,
  `exento` decimal(8,2) NOT NULL,
  `retenido` decimal(8,2) NOT NULL,
  `descuento` decimal(8,2) NOT NULL,
  `total` decimal(8,2) NOT NULL,
  `sonletras` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pago_efectivo` decimal(8,2) NOT NULL DEFAULT '0.00',
  `pago_tarjeta` decimal(8,2) NOT NULL DEFAULT '0.00',
  `numero_tarjeta` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tarjeta_habiente` varchar(90) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cambio` decimal(8,2) NOT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT '1',
  `idcliente` int(11) DEFAULT NULL,
  `idusuario` int(11) NOT NULL,
  `CURRENT_TIMESTAMP` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `lastUpdated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `venta`
--
DELIMITER $$
CREATE TRIGGER `generar_numero_venta` BEFORE INSERT ON `venta` FOR EACH ROW BEGIN
    
        DECLARE numero INT(11);

        SET numero = (SELECT max(idventa) FROM venta);
        
		IF numero IS NULL then
		  set numero=1;
        SET NEW.numero_venta='V00000001';

		ELSEIF numero >= 1 and numero < 9 then
			set numero=numero+1;
		SET NEW.numero_venta=(select concat('V0000000',CAST(numero AS CHAR)));
        
		ELSEIF numero >=9 and numero<=99 then
			set numero=numero+1;
		SET NEW.numero_venta=(select concat('V000000',CAST(numero AS CHAR)));
            
		ELSEIF numero>=99 and numero<=999 then
			set numero=numero+1;
		SET NEW.numero_venta=(select concat('V00000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=999 and numero<=9999 then
		   set numero=numero+1;
		SET NEW.numero_venta=(select concat('V0000',CAST(numero AS CHAR)));
           
		ELSEIF numero>=9999 and numero<=99999 then
			set numero=numero+1;
		SET NEW.numero_venta=(select concat('V000',CAST(numero AS CHAR)));
             
		ELSEIF numero>=99999 and numero<=999999 then
			set numero=numero+1;
		SET NEW.numero_venta=(select concat('V00',CAST(numero AS CHAR)));
            
		ELSEIF numero>=999999 and numero<=9999999 then
			set numero=numero+1;
		SET NEW.numero_venta=(select concat('V0',CAST(numero AS CHAR)));
            
        ELSEIF numero>=9999999  then -- DIEZ MILLONES EN DELANTE
			set numero=numero+1;
		SET NEW.numero_venta=(select concat('V',CAST(numero AS CHAR)));
            
		END IF;
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_abonos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_abonos` (
`idcredito` int(11)
,`codigo_credito` varchar(175)
,`nombre_credito` varchar(120)
,`idabono` int(11)
,`fecha_abono` datetime
,`monto_abono` decimal(8,2)
,`restante_credito` decimal(8,2)
,`total_abonado` decimal(8,2)
,`idusuario` int(11)
,`usuario` varchar(8)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_abonos_proveedor`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_abonos_proveedor` (
`idcreditoproveedor` int(11)
,`codigo_credito` varchar(175)
,`nombre_credito` varchar(120)
,`idabonoproveedor` int(11)
,`fecha_abono` datetime
,`monto_abono` decimal(8,2)
,`restante_credito` decimal(8,2)
,`total_abonado` decimal(8,2)
,`idusuario` int(11)
,`usuario` varchar(8)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_apartados`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_apartados` (
`idapartado` int(11)
,`numero_apartado` varchar(175)
,`fecha_apartado` datetime
,`fecha_limite_retiro` datetime
,`sumas` decimal(8,2)
,`iva` decimal(8,2)
,`total_exento` decimal(8,2)
,`retenido` decimal(8,2)
,`total_descuento` decimal(8,2)
,`total` decimal(8,2)
,`sonletras` varchar(150)
,`estado_apartado` tinyint(1)
,`idcliente` int(11)
,`cliente` varchar(150)
,`idproducto` int(11)
,`codigo_barra` varchar(200)
,`codigo_interno` varchar(175)
,`nombre_producto` varchar(175)
,`nombre_marca` varchar(120)
,`siglas` varchar(45)
,`producto_exento` tinyint(1)
,`perecedero` tinyint(1)
,`fecha_vence` date
,`cantidad` decimal(8,2)
,`precio_unitario` decimal(8,2)
,`precio_compra` decimal(8,2)
,`exento` decimal(8,2)
,`descuento` decimal(8,2)
,`importe` decimal(8,2)
,`empleado` varchar(181)
,`abonado_apartado` decimal(8,2)
,`restante_pagar` decimal(8,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_caja`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_caja` (
`idcaja` int(11)
,`fecha_apertura` datetime
,`monto_apertura` decimal(8,2)
,`monto_cierre` decimal(8,2)
,`fecha_cierre` datetime
,`estado` tinyint(1)
,`tipo_movimiento` tinyint(1)
,`monto_movimiento` decimal(8,2)
,`descripcion_movimiento` varchar(80)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_compras`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_compras` (
`idcompra` int(11)
,`fecha_compra` datetime
,`idproveedor` int(11)
,`nombre_proveedor` varchar(175)
,`numero_nit` varchar(70)
,`tipo_pago` varchar(75)
,`tipo_comprobante` varchar(60)
,`numero_comprobante` varchar(60)
,`fecha_comprobante` date
,`idproducto` int(11)
,`fecha_vence` date
,`codigo_barra` varchar(200)
,`codigo_interno` varchar(175)
,`nombre_producto` varchar(175)
,`nombre_marca` varchar(120)
,`siglas` varchar(45)
,`cantidad` decimal(8,2)
,`precio_unitario` decimal(8,2)
,`exento` decimal(8,2)
,`importe` decimal(8,2)
,`sumas` decimal(8,2)
,`iva` decimal(8,2)
,`total_exento` decimal(8,2)
,`retenido` decimal(8,2)
,`total` decimal(8,2)
,`sonletras` varchar(150)
,`estado_compra` tinyint(1)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_comprobantes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_comprobantes` (
`idcomprobante` int(11)
,`nombre_comprobante` varchar(75)
,`estado` tinyint(1)
,`idtiraje` int(11)
,`fecha_resolucion` datetime
,`serie` varchar(175)
,`numero_resolucion` varchar(100)
,`desde` int(11)
,`hasta` int(11)
,`disponibles` int(11)
,`usados` bigint(12)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_cotizaciones`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_cotizaciones` (
`idcotizacion` int(11)
,`numero_cotizacion` varchar(175)
,`fecha_cotizacion` datetime
,`a_nombre` varchar(175)
,`nombre_cliente` varchar(150)
,`numero_nit` varchar(70)
,`direccion_cliente` varchar(100)
,`numero_telefono` varchar(70)
,`email` varchar(80)
,`tipo_pago` varchar(60)
,`entrega` varchar(60)
,`idproducto` int(11)
,`codigo_barra` varchar(200)
,`codigo_interno` varchar(175)
,`nombre_producto` varchar(175)
,`nombre_marca` varchar(120)
,`siglas` varchar(45)
,`stock` decimal(8,2)
,`cantidad` decimal(8,2)
,`disponible` tinyint(1)
,`precio_unitario` decimal(8,2)
,`exento` decimal(8,2)
,`descuento` decimal(8,2)
,`importe` decimal(8,2)
,`sumas` decimal(8,2)
,`iva` decimal(8,2)
,`total_exento` decimal(8,2)
,`retenido` decimal(8,2)
,`total_descuento` decimal(8,2)
,`total` decimal(8,2)
,`sonletras` varchar(150)
,`empleado` varchar(181)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_creditos_compra`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_creditos_compra` (
`idcreditoproveedor` int(11)
,`codigo_credito` varchar(175)
,`idcompra` int(11)
,`numero_compra` varchar(60)
,`nombre_credito` varchar(120)
,`fecha_credito` datetime
,`monto_credito` decimal(8,2)
,`monto_abonado` decimal(8,2)
,`monto_restante` decimal(8,2)
,`estado_credito` tinyint(1)
,`codigo_proveedor` varchar(175)
,`proveedor` varchar(175)
,`limite_credito` decimal(3,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_creditos_venta`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_creditos_venta` (
`idcredito` int(11)
,`codigo_credito` varchar(175)
,`idventa` int(11)
,`numero_venta` varchar(175)
,`nombre_credito` varchar(120)
,`fecha_credito` datetime
,`monto_credito` decimal(8,2)
,`monto_abonado` decimal(8,2)
,`monto_restante` decimal(8,2)
,`estado_credito` tinyint(1)
,`codigo_cliente` varchar(175)
,`cliente` varchar(150)
,`limite_credito` decimal(8,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_full_entradas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_full_entradas` (
`idproducto` int(11)
,`codigo_interno` varchar(175)
,`codigo_barra` varchar(200)
,`nombre_producto` varchar(175)
,`nombre_marca` varchar(120)
,`siglas` varchar(45)
,`fecha_entrada` date
,`descripcion_entrada` varchar(150)
,`cantidad_entrada` decimal(8,2)
,`precio_unitario_entrada` decimal(8,2)
,`costo_total_entrada` decimal(8,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_full_salidas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_full_salidas` (
`idproducto` int(11)
,`codigo_interno` varchar(175)
,`codigo_barra` varchar(200)
,`nombre_producto` varchar(175)
,`nombre_marca` varchar(120)
,`siglas` varchar(45)
,`fecha_salida` date
,`descripcion_salida` varchar(150)
,`cantidad_salida` decimal(8,2)
,`precio_unitario_salida` decimal(8,2)
,`costo_total_salida` decimal(8,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_historico_precios`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_historico_precios` (
`idproducto` int(11)
,`codigo_interno` varchar(175)
,`codigo_barra` varchar(200)
,`nombre_producto` varchar(175)
,`nombre_marca` varchar(120)
,`siglas` varchar(45)
,`idproveedor` int(11)
,`nombre_proveedor` varchar(175)
,`fecha_precio` date
,`precio_comprado` decimal(8,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_kardex`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_kardex` (
`idproducto` int(11)
,`producto` varchar(222)
,`nombre_marca` varchar(120)
,`saldo_inicial` decimal(8,2)
,`entradas` decimal(8,2)
,`salidas` decimal(8,2)
,`saldo_final` decimal(8,2)
,`mes_inventario` varchar(7)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_perecederos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_perecederos` (
`idproducto` int(11)
,`codigo_interno` varchar(175)
,`codigo_barra` varchar(200)
,`nombre_producto` varchar(175)
,`nombre_marca` varchar(120)
,`siglas` varchar(45)
,`fecha_vencimiento` date
,`cantidad_perecedero` decimal(8,2)
,`estado_perecedero` tinyint(1)
,`vencido` varchar(2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_productos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_productos` (
`idproducto` int(11)
,`codigo_interno` varchar(175)
,`codigo_barra` varchar(200)
,`nombre_producto` varchar(175)
,`precio_compra` decimal(8,2)
,`precio_venta` decimal(8,2)
,`precio_venta_mayoreo` decimal(8,2)
,`precio_venta_3` decimal(8,2)
,`stock` decimal(8,2)
,`stock_min` decimal(8,2)
,`idcategoria` int(11)
,`nombre_categoria` varchar(120)
,`idmarca` int(11)
,`nombre_marca` varchar(120)
,`idpresentacion` int(11)
,`nombre_presentacion` varchar(120)
,`siglas` varchar(45)
,`estado` tinyint(1)
,`exento` tinyint(1)
,`inventariable` tinyint(1)
,`perecedero` tinyint(1)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_productos_apartado`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_productos_apartado` (
`idproducto` int(11)
,`codigo_interno` varchar(175)
,`codigo_barra` varchar(200)
,`nombre_producto` varchar(175)
,`siglas` varchar(45)
,`nombre_marca` varchar(120)
,`precio_venta` decimal(8,2)
,`precio_venta_mayoreo` decimal(8,2)
,`stock` decimal(8,2)
,`exento` tinyint(1)
,`perecedero` tinyint(1)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_productos_venta`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_productos_venta` (
`idproducto` int(11)
,`codigo_interno` varchar(175)
,`codigo_barra` varchar(200)
,`nombre_producto` varchar(175)
,`siglas` varchar(45)
,`nombre_marca` varchar(120)
,`precio_venta` decimal(8,2)
,`precio_venta_mayoreo` decimal(8,2)
,`precio_venta_3` decimal(8,2)
,`stock` decimal(8,2)
,`exento` tinyint(1)
,`perecedero` tinyint(1)
,`inventariable` tinyint(1)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_taller`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_taller` (
`idorden` int(11)
,`numero_orden` varchar(175)
,`fecha_ingreso` datetime
,`aparato` varchar(125)
,`modelo` varchar(125)
,`serie` varchar(125)
,`averia` varchar(200)
,`observaciones` varchar(200)
,`deposito_revision` decimal(8,2)
,`deposito_reparacion` decimal(8,2)
,`diagnostico` varchar(200)
,`estado_aparato` varchar(200)
,`repuestos` decimal(8,2)
,`mano_obra` decimal(8,2)
,`fecha_alta` datetime
,`fecha_retiro` datetime
,`ubicacion` varchar(150)
,`parcial_pagar` decimal(8,2)
,`idcliente` int(11)
,`nombre_cliente` varchar(150)
,`numero_nit` varchar(70)
,`numero_telefono` varchar(70)
,`idtecnico` int(11)
,`tecnico` varchar(150)
,`idmarca` int(11)
,`nombre_marca` varchar(120)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_usuarios`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_usuarios` (
`idusuario` int(11)
,`usuario` varchar(8)
,`contrasena` varchar(12)
,`tipo_usuario` tinyint(1)
,`estado` tinyint(1)
,`idempleado` int(11)
,`nombre_empleado` varchar(90)
,`apellido_empleado` varchar(90)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_ventas`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `view_ventas` (
`idventa` int(11)
,`numero_venta` varchar(175)
,`fecha_venta` datetime
,`tipo_pago` varchar(75)
,`numero_comprobante` int(11)
,`tipo_comprobante` tinyint(1)
,`pago_efectivo` decimal(8,2)
,`pago_tarjeta` decimal(8,2)
,`numero_tarjeta` varchar(16)
,`tarjeta_habiente` varchar(90)
,`cambio` decimal(8,2)
,`sumas` decimal(8,2)
,`iva` decimal(8,2)
,`total_exento` decimal(8,2)
,`retenido` decimal(8,2)
,`total_descuento` decimal(8,2)
,`total` decimal(8,2)
,`sonletras` varchar(150)
,`estado_venta` tinyint(1)
,`idcliente` int(11)
,`cliente` varchar(150)
,`ruc` varchar(70)
,`idproducto` int(11)
,`codigo_barra` varchar(200)
,`codigo_interno` varchar(175)
,`nombre_producto` varchar(175)
,`nombre_marca` varchar(120)
,`siglas` varchar(45)
,`producto_exento` tinyint(1)
,`perecedero` tinyint(1)
,`fecha_vence` date
,`cantidad` decimal(8,2)
,`precio_unitario` decimal(8,2)
,`precio_compra` decimal(8,2)
,`exento` decimal(8,2)
,`descuento` decimal(8,2)
,`importe` decimal(8,2)
,`empleado` varchar(181)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `view_abonos`
--
DROP TABLE IF EXISTS `view_abonos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_abonos`  AS  select `view_creditos_venta`.`idcredito` AS `idcredito`,`view_creditos_venta`.`codigo_credito` AS `codigo_credito`,`view_creditos_venta`.`nombre_credito` AS `nombre_credito`,`abono`.`idabono` AS `idabono`,`abono`.`fecha_abono` AS `fecha_abono`,`abono`.`monto_abono` AS `monto_abono`,`abono`.`restante_credito` AS `restante_credito`,`abono`.`total_abonado` AS `total_abonado`,`abono`.`idusuario` AS `idusuario`,`view_usuarios`.`usuario` AS `usuario` from ((`abono` join `view_creditos_venta` on((`view_creditos_venta`.`idcredito` = `abono`.`idcredito`))) join `view_usuarios` on((`abono`.`idusuario` = `view_usuarios`.`idusuario`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_abonos_proveedor`
--
DROP TABLE IF EXISTS `view_abonos_proveedor`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_abonos_proveedor`  AS  select `view_creditos_compra`.`idcreditoproveedor` AS `idcreditoproveedor`,`view_creditos_compra`.`codigo_credito` AS `codigo_credito`,`view_creditos_compra`.`nombre_credito` AS `nombre_credito`,`abonoproveedor`.`idabonoproveedor` AS `idabonoproveedor`,`abonoproveedor`.`fecha_abono` AS `fecha_abono`,`abonoproveedor`.`monto_abono` AS `monto_abono`,`abonoproveedor`.`restante_credito` AS `restante_credito`,`abonoproveedor`.`total_abonado` AS `total_abonado`,`abonoproveedor`.`idusuario` AS `idusuario`,`view_usuarios`.`usuario` AS `usuario` from ((`abonoproveedor` join `view_creditos_compra` on((`view_creditos_compra`.`idcreditoproveedor` = `abonoproveedor`.`idcreditoproveedor`))) join `view_usuarios` on((`abonoproveedor`.`idusuario` = `view_usuarios`.`idusuario`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_apartados`
--
DROP TABLE IF EXISTS `view_apartados`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_apartados`  AS  select `apartado`.`idapartado` AS `idapartado`,`apartado`.`numero_apartado` AS `numero_apartado`,`apartado`.`fecha_apartado` AS `fecha_apartado`,`apartado`.`fecha_limite_retiro` AS `fecha_limite_retiro`,`apartado`.`sumas` AS `sumas`,`apartado`.`iva` AS `iva`,`apartado`.`exento` AS `total_exento`,`apartado`.`retenido` AS `retenido`,`apartado`.`descuento` AS `total_descuento`,`apartado`.`total` AS `total`,`apartado`.`sonletras` AS `sonletras`,`apartado`.`estado` AS `estado_apartado`,`apartado`.`idcliente` AS `idcliente`,`cliente`.`nombre_cliente` AS `cliente`,`detalleapartado`.`idproducto` AS `idproducto`,`view_productos`.`codigo_barra` AS `codigo_barra`,`view_productos`.`codigo_interno` AS `codigo_interno`,`view_productos`.`nombre_producto` AS `nombre_producto`,`view_productos`.`nombre_marca` AS `nombre_marca`,`view_productos`.`siglas` AS `siglas`,`view_productos`.`exento` AS `producto_exento`,`view_productos`.`perecedero` AS `perecedero`,`detalleapartado`.`fecha_vence` AS `fecha_vence`,`detalleapartado`.`cantidad` AS `cantidad`,`detalleapartado`.`precio_unitario` AS `precio_unitario`,`view_productos`.`precio_compra` AS `precio_compra`,`detalleapartado`.`exento` AS `exento`,`detalleapartado`.`descuento` AS `descuento`,`detalleapartado`.`importe` AS `importe`,concat(`view_usuarios`.`nombre_empleado`,' ',`view_usuarios`.`apellido_empleado`) AS `empleado`,`apartado`.`abonado_apartado` AS `abonado_apartado`,`apartado`.`restante_pagar` AS `restante_pagar` from ((((`apartado` join `detalleapartado` on((`detalleapartado`.`idapartado` = `apartado`.`idapartado`))) join `view_productos` on((`detalleapartado`.`idproducto` = `view_productos`.`idproducto`))) join `view_usuarios` on((`view_usuarios`.`idusuario` = `apartado`.`idusuario`))) left join `cliente` on((`apartado`.`idcliente` = `cliente`.`idcliente`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_caja`
--
DROP TABLE IF EXISTS `view_caja`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_caja`  AS  select `caja`.`idcaja` AS `idcaja`,`caja`.`fecha_apertura` AS `fecha_apertura`,`caja`.`monto_apertura` AS `monto_apertura`,`caja`.`monto_cierre` AS `monto_cierre`,`caja`.`fecha_cierre` AS `fecha_cierre`,`caja`.`estado` AS `estado`,`caja_movimiento`.`tipo_movimiento` AS `tipo_movimiento`,`caja_movimiento`.`monto_movimiento` AS `monto_movimiento`,`caja_movimiento`.`descripcion_movimiento` AS `descripcion_movimiento` from (`caja` join `caja_movimiento` on((`caja`.`idcaja` = `caja_movimiento`.`idcaja`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_compras`
--
DROP TABLE IF EXISTS `view_compras`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_compras`  AS  select `compra`.`idcompra` AS `idcompra`,`compra`.`fecha_compra` AS `fecha_compra`,`compra`.`idproveedor` AS `idproveedor`,`proveedor`.`nombre_proveedor` AS `nombre_proveedor`,`proveedor`.`numero_nit` AS `numero_nit`,`compra`.`tipo_pago` AS `tipo_pago`,`compra`.`tipo_comprobante` AS `tipo_comprobante`,`compra`.`numero_comprobante` AS `numero_comprobante`,`compra`.`fecha_comprobante` AS `fecha_comprobante`,`detallecompra`.`idproducto` AS `idproducto`,`detallecompra`.`fecha_vence` AS `fecha_vence`,`producto`.`codigo_barra` AS `codigo_barra`,`producto`.`codigo_interno` AS `codigo_interno`,`producto`.`nombre_producto` AS `nombre_producto`,`marca`.`nombre_marca` AS `nombre_marca`,`presentacion`.`siglas` AS `siglas`,`detallecompra`.`cantidad` AS `cantidad`,`detallecompra`.`precio_unitario` AS `precio_unitario`,`detallecompra`.`exento` AS `exento`,`detallecompra`.`importe` AS `importe`,`compra`.`sumas` AS `sumas`,`compra`.`iva` AS `iva`,`compra`.`exento` AS `total_exento`,`compra`.`retenido` AS `retenido`,`compra`.`total` AS `total`,`compra`.`sonletras` AS `sonletras`,`compra`.`estado` AS `estado_compra` from (((((`compra` join `detallecompra` on((`compra`.`idcompra` = `detallecompra`.`idcompra`))) join `proveedor` on((`proveedor`.`idproveedor` = `compra`.`idproveedor`))) join `producto` on((`detallecompra`.`idproducto` = `producto`.`idproducto`))) join `presentacion` on((`producto`.`idpresentacion` = `presentacion`.`idpresentacion`))) left join `marca` on((`producto`.`idmarca` = `marca`.`idmarca`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_comprobantes`
--
DROP TABLE IF EXISTS `view_comprobantes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_comprobantes`  AS  select `comprobante`.`idcomprobante` AS `idcomprobante`,`comprobante`.`nombre_comprobante` AS `nombre_comprobante`,`comprobante`.`estado` AS `estado`,`tiraje_comprobante`.`idtiraje` AS `idtiraje`,`tiraje_comprobante`.`fecha_resolucion` AS `fecha_resolucion`,`tiraje_comprobante`.`serie` AS `serie`,`tiraje_comprobante`.`numero_resolucion` AS `numero_resolucion`,`tiraje_comprobante`.`desde` AS `desde`,`tiraje_comprobante`.`hasta` AS `hasta`,`tiraje_comprobante`.`disponibles` AS `disponibles`,(`tiraje_comprobante`.`hasta` - `tiraje_comprobante`.`disponibles`) AS `usados` from (`comprobante` join `tiraje_comprobante` on((`comprobante`.`idcomprobante` = `tiraje_comprobante`.`idcomprobante`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_cotizaciones`
--
DROP TABLE IF EXISTS `view_cotizaciones`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_cotizaciones`  AS  select `cotizacion`.`idcotizacion` AS `idcotizacion`,`cotizacion`.`numero_cotizacion` AS `numero_cotizacion`,`cotizacion`.`fecha_cotizacion` AS `fecha_cotizacion`,`cotizacion`.`a_nombre` AS `a_nombre`,`cliente`.`nombre_cliente` AS `nombre_cliente`,`cliente`.`numero_nit` AS `numero_nit`,`cliente`.`direccion_cliente` AS `direccion_cliente`,`cliente`.`numero_telefono` AS `numero_telefono`,`cliente`.`email` AS `email`,`cotizacion`.`tipo_pago` AS `tipo_pago`,`cotizacion`.`entrega` AS `entrega`,`detallecotizacion`.`idproducto` AS `idproducto`,`producto`.`codigo_barra` AS `codigo_barra`,`producto`.`codigo_interno` AS `codigo_interno`,`producto`.`nombre_producto` AS `nombre_producto`,`marca`.`nombre_marca` AS `nombre_marca`,`presentacion`.`siglas` AS `siglas`,`producto`.`stock` AS `stock`,`detallecotizacion`.`cantidad` AS `cantidad`,`detallecotizacion`.`disponible` AS `disponible`,`detallecotizacion`.`precio_unitario` AS `precio_unitario`,`detallecotizacion`.`exento` AS `exento`,`detallecotizacion`.`descuento` AS `descuento`,`detallecotizacion`.`importe` AS `importe`,`cotizacion`.`sumas` AS `sumas`,`cotizacion`.`iva` AS `iva`,`cotizacion`.`exento` AS `total_exento`,`cotizacion`.`retenido` AS `retenido`,`cotizacion`.`descuento` AS `total_descuento`,`cotizacion`.`total` AS `total`,`cotizacion`.`sonletras` AS `sonletras`,concat(`view_usuarios`.`nombre_empleado`,' ',`view_usuarios`.`apellido_empleado`) AS `empleado` from ((((((`cotizacion` join `detallecotizacion` on((`cotizacion`.`idcotizacion` = `detallecotizacion`.`idcotizacion`))) join `producto` on((`detallecotizacion`.`idproducto` = `producto`.`idproducto`))) join `presentacion` on((`producto`.`idpresentacion` = `presentacion`.`idpresentacion`))) left join `marca` on((`producto`.`idmarca` = `marca`.`idmarca`))) join `view_usuarios` on((`cotizacion`.`idusuario` = `view_usuarios`.`idusuario`))) join `cliente` on((`cotizacion`.`idcliente` = `cliente`.`idcliente`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_creditos_compra`
--
DROP TABLE IF EXISTS `view_creditos_compra`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_creditos_compra`  AS  select `creditoproveedor`.`idcreditoproveedor` AS `idcreditoproveedor`,`creditoproveedor`.`codigo_credito` AS `codigo_credito`,`creditoproveedor`.`idcompra` AS `idcompra`,`compra`.`numero_comprobante` AS `numero_compra`,`creditoproveedor`.`nombre_credito` AS `nombre_credito`,`creditoproveedor`.`fecha_credito` AS `fecha_credito`,`creditoproveedor`.`monto_credito` AS `monto_credito`,`creditoproveedor`.`monto_abonado` AS `monto_abonado`,`creditoproveedor`.`monto_restante` AS `monto_restante`,`creditoproveedor`.`estado` AS `estado_credito`,`proveedor`.`codigo_proveedor` AS `codigo_proveedor`,`proveedor`.`nombre_proveedor` AS `proveedor`,0.00 AS `limite_credito` from ((`creditoproveedor` join `compra` on((`creditoproveedor`.`idcompra` = `compra`.`idcompra`))) join `proveedor` on((`creditoproveedor`.`idproveedor` = `proveedor`.`idproveedor`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_creditos_venta`
--
DROP TABLE IF EXISTS `view_creditos_venta`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_creditos_venta`  AS  select `credito`.`idcredito` AS `idcredito`,`credito`.`codigo_credito` AS `codigo_credito`,`credito`.`idventa` AS `idventa`,`venta`.`numero_venta` AS `numero_venta`,`credito`.`nombre_credito` AS `nombre_credito`,`credito`.`fecha_credito` AS `fecha_credito`,`credito`.`monto_credito` AS `monto_credito`,`credito`.`monto_abonado` AS `monto_abonado`,`credito`.`monto_restante` AS `monto_restante`,`credito`.`estado` AS `estado_credito`,`cliente`.`codigo_cliente` AS `codigo_cliente`,`cliente`.`nombre_cliente` AS `cliente`,`cliente`.`limite_credito` AS `limite_credito` from ((`credito` join `venta` on((`credito`.`idventa` = `venta`.`idventa`))) join `cliente` on((`credito`.`idcliente` = `cliente`.`idcliente`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_full_entradas`
--
DROP TABLE IF EXISTS `view_full_entradas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_full_entradas`  AS  select `entrada`.`idproducto` AS `idproducto`,`view_productos`.`codigo_interno` AS `codigo_interno`,`view_productos`.`codigo_barra` AS `codigo_barra`,`view_productos`.`nombre_producto` AS `nombre_producto`,`view_productos`.`nombre_marca` AS `nombre_marca`,`view_productos`.`siglas` AS `siglas`,`entrada`.`fecha_entrada` AS `fecha_entrada`,`entrada`.`descripcion_entrada` AS `descripcion_entrada`,`entrada`.`cantidad_entrada` AS `cantidad_entrada`,`entrada`.`precio_unitario_entrada` AS `precio_unitario_entrada`,`entrada`.`costo_total_entrada` AS `costo_total_entrada` from (`entrada` join `view_productos` on((`entrada`.`idproducto` = `view_productos`.`idproducto`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_full_salidas`
--
DROP TABLE IF EXISTS `view_full_salidas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_full_salidas`  AS  select `salida`.`idproducto` AS `idproducto`,`view_productos`.`codigo_interno` AS `codigo_interno`,`view_productos`.`codigo_barra` AS `codigo_barra`,`view_productos`.`nombre_producto` AS `nombre_producto`,`view_productos`.`nombre_marca` AS `nombre_marca`,`view_productos`.`siglas` AS `siglas`,`salida`.`fecha_salida` AS `fecha_salida`,`salida`.`descripcion_salida` AS `descripcion_salida`,`salida`.`cantidad_salida` AS `cantidad_salida`,`salida`.`precio_unitario_salida` AS `precio_unitario_salida`,`salida`.`costo_total_salida` AS `costo_total_salida` from (`salida` join `view_productos` on((`salida`.`idproducto` = `view_productos`.`idproducto`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_historico_precios`
--
DROP TABLE IF EXISTS `view_historico_precios`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_historico_precios`  AS  select `proveedor_precio`.`idproducto` AS `idproducto`,`view_productos`.`codigo_interno` AS `codigo_interno`,`view_productos`.`codigo_barra` AS `codigo_barra`,`view_productos`.`nombre_producto` AS `nombre_producto`,`view_productos`.`nombre_marca` AS `nombre_marca`,`view_productos`.`siglas` AS `siglas`,`proveedor_precio`.`idproveedor` AS `idproveedor`,`proveedor`.`nombre_proveedor` AS `nombre_proveedor`,`proveedor_precio`.`fecha_precio` AS `fecha_precio`,`proveedor_precio`.`precio_compra` AS `precio_comprado` from ((`proveedor_precio` join `view_productos` on((`proveedor_precio`.`idproducto` = `view_productos`.`idproducto`))) join `proveedor` on((`proveedor_precio`.`idproveedor` = `proveedor`.`idproveedor`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_kardex`
--
DROP TABLE IF EXISTS `view_kardex`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_kardex`  AS  select `inventario`.`idproducto` AS `idproducto`,concat(`view_productos`.`nombre_producto`,'  ',`view_productos`.`siglas`) AS `producto`,`view_productos`.`nombre_marca` AS `nombre_marca`,`inventario`.`saldo_inicial` AS `saldo_inicial`,if(isnull(`inventario`.`entradas`),0.00,`inventario`.`entradas`) AS `entradas`,if(isnull(`inventario`.`salidas`),0.00,`inventario`.`salidas`) AS `salidas`,`inventario`.`saldo_final` AS `saldo_final`,`inventario`.`mes_inventario` AS `mes_inventario` from (`inventario` join `view_productos` on((`inventario`.`idproducto` = `view_productos`.`idproducto`))) group by `inventario`.`idproducto`,`inventario`.`mes_inventario` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_perecederos`
--
DROP TABLE IF EXISTS `view_perecederos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_perecederos`  AS  select `perecedero`.`idproducto` AS `idproducto`,`producto`.`codigo_interno` AS `codigo_interno`,`producto`.`codigo_barra` AS `codigo_barra`,`producto`.`nombre_producto` AS `nombre_producto`,`marca`.`nombre_marca` AS `nombre_marca`,`presentacion`.`siglas` AS `siglas`,`perecedero`.`fecha_vencimiento` AS `fecha_vencimiento`,`perecedero`.`cantidad_perecedero` AS `cantidad_perecedero`,`perecedero`.`estado` AS `estado_perecedero`,if((curdate() < `perecedero`.`fecha_vencimiento`),'NO','SI') AS `vencido` from (((`perecedero` join `producto` on((`perecedero`.`idproducto` = `producto`.`idproducto`))) join `presentacion` on((`producto`.`idpresentacion` = `presentacion`.`idpresentacion`))) left join `marca` on((`producto`.`idmarca` = `marca`.`idmarca`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_productos`
--
DROP TABLE IF EXISTS `view_productos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_productos`  AS  select `producto`.`idproducto` AS `idproducto`,`producto`.`codigo_interno` AS `codigo_interno`,`producto`.`codigo_barra` AS `codigo_barra`,`producto`.`nombre_producto` AS `nombre_producto`,`producto`.`precio_compra` AS `precio_compra`,`producto`.`precio_venta` AS `precio_venta`,`producto`.`precio_venta_mayoreo` AS `precio_venta_mayoreo`,`producto`.`precio_venta_3` AS `precio_venta_3`,`producto`.`stock` AS `stock`,`producto`.`stock_min` AS `stock_min`,`producto`.`idcategoria` AS `idcategoria`,`categoria`.`nombre_categoria` AS `nombre_categoria`,`producto`.`idmarca` AS `idmarca`,`marca`.`nombre_marca` AS `nombre_marca`,`producto`.`idpresentacion` AS `idpresentacion`,`presentacion`.`nombre_presentacion` AS `nombre_presentacion`,`presentacion`.`siglas` AS `siglas`,`producto`.`estado` AS `estado`,`producto`.`exento` AS `exento`,`producto`.`inventariable` AS `inventariable`,`producto`.`perecedero` AS `perecedero` from (((`producto` join `categoria` on((`producto`.`idcategoria` = `categoria`.`idcategoria`))) join `presentacion` on((`producto`.`idpresentacion` = `presentacion`.`idpresentacion`))) left join `marca` on((`producto`.`idmarca` = `marca`.`idmarca`))) group by `producto`.`idproducto` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_productos_apartado`
--
DROP TABLE IF EXISTS `view_productos_apartado`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_productos_apartado`  AS  select `view_productos`.`idproducto` AS `idproducto`,`view_productos`.`codigo_interno` AS `codigo_interno`,`view_productos`.`codigo_barra` AS `codigo_barra`,`view_productos`.`nombre_producto` AS `nombre_producto`,`view_productos`.`siglas` AS `siglas`,`view_productos`.`nombre_marca` AS `nombre_marca`,`view_productos`.`precio_venta` AS `precio_venta`,`view_productos`.`precio_venta_mayoreo` AS `precio_venta_mayoreo`,`view_productos`.`stock` AS `stock`,`view_productos`.`exento` AS `exento`,`view_productos`.`perecedero` AS `perecedero` from `view_productos` where ((`view_productos`.`stock` > 0.00) and (`view_productos`.`precio_venta` > 0.00) and (`view_productos`.`estado` = 1) and (`view_productos`.`perecedero` = 0) and (`view_productos`.`inventariable` = 1)) group by `view_productos`.`idproducto` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_productos_venta`
--
DROP TABLE IF EXISTS `view_productos_venta`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_productos_venta`  AS  select `view_productos`.`idproducto` AS `idproducto`,`view_productos`.`codigo_interno` AS `codigo_interno`,`view_productos`.`codigo_barra` AS `codigo_barra`,`view_productos`.`nombre_producto` AS `nombre_producto`,`view_productos`.`siglas` AS `siglas`,`view_productos`.`nombre_marca` AS `nombre_marca`,`view_productos`.`precio_venta` AS `precio_venta`,`view_productos`.`precio_venta_mayoreo` AS `precio_venta_mayoreo`,`view_productos`.`precio_venta_3` AS `precio_venta_3`,`view_productos`.`stock` AS `stock`,`view_productos`.`exento` AS `exento`,`view_productos`.`perecedero` AS `perecedero`,`view_productos`.`inventariable` AS `inventariable` from `view_productos` where (((`view_productos`.`stock` > 0.00) and (`view_productos`.`precio_venta` > 0.00) and (`view_productos`.`estado` = 1) and (`view_productos`.`inventariable` = 1)) or (`view_productos`.`inventariable` = 0)) group by `view_productos`.`idproducto` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_taller`
--
DROP TABLE IF EXISTS `view_taller`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_taller`  AS  select `ordentaller`.`idorden` AS `idorden`,`ordentaller`.`numero_orden` AS `numero_orden`,`ordentaller`.`fecha_ingreso` AS `fecha_ingreso`,`ordentaller`.`aparato` AS `aparato`,`ordentaller`.`modelo` AS `modelo`,`ordentaller`.`serie` AS `serie`,`ordentaller`.`averia` AS `averia`,`ordentaller`.`observaciones` AS `observaciones`,`ordentaller`.`deposito_revision` AS `deposito_revision`,`ordentaller`.`deposito_reparacion` AS `deposito_reparacion`,`ordentaller`.`diagnostico` AS `diagnostico`,`ordentaller`.`estado_aparato` AS `estado_aparato`,`ordentaller`.`repuestos` AS `repuestos`,`ordentaller`.`mano_obra` AS `mano_obra`,`ordentaller`.`fecha_alta` AS `fecha_alta`,`ordentaller`.`fecha_retiro` AS `fecha_retiro`,`ordentaller`.`ubicacion` AS `ubicacion`,`ordentaller`.`parcial_pagar` AS `parcial_pagar`,`ordentaller`.`idcliente` AS `idcliente`,`cliente`.`nombre_cliente` AS `nombre_cliente`,`cliente`.`numero_nit` AS `numero_nit`,`cliente`.`numero_telefono` AS `numero_telefono`,`ordentaller`.`idtecnico` AS `idtecnico`,`tecnico`.`tecnico` AS `tecnico`,`ordentaller`.`idmarca` AS `idmarca`,`marca`.`nombre_marca` AS `nombre_marca` from (((`ordentaller` join `cliente` on((`ordentaller`.`idcliente` = `cliente`.`idcliente`))) join `marca` on((`ordentaller`.`idmarca` = `marca`.`idmarca`))) join `tecnico` on((`ordentaller`.`idtecnico` = `tecnico`.`idtecnico`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_usuarios`
--
DROP TABLE IF EXISTS `view_usuarios`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_usuarios`  AS  select `usuario`.`idusuario` AS `idusuario`,`usuario`.`usuario` AS `usuario`,`usuario`.`contrasena` AS `contrasena`,`usuario`.`tipo_usuario` AS `tipo_usuario`,`usuario`.`estado` AS `estado`,`usuario`.`idempleado` AS `idempleado`,`empleado`.`nombre_empleado` AS `nombre_empleado`,`empleado`.`apellido_empleado` AS `apellido_empleado` from (`usuario` join `empleado` on((`usuario`.`idempleado` = `empleado`.`idempleado`))) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_ventas`
--
DROP TABLE IF EXISTS `view_ventas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_ventas`  AS  select `venta`.`idventa` AS `idventa`,`venta`.`numero_venta` AS `numero_venta`,`venta`.`fecha_venta` AS `fecha_venta`,`venta`.`tipo_pago` AS `tipo_pago`,`venta`.`numero_comprobante` AS `numero_comprobante`,`venta`.`tipo_comprobante` AS `tipo_comprobante`,`venta`.`pago_efectivo` AS `pago_efectivo`,`venta`.`pago_tarjeta` AS `pago_tarjeta`,`venta`.`numero_tarjeta` AS `numero_tarjeta`,`venta`.`tarjeta_habiente` AS `tarjeta_habiente`,`venta`.`cambio` AS `cambio`,`venta`.`sumas` AS `sumas`,`venta`.`iva` AS `iva`,`venta`.`exento` AS `total_exento`,`venta`.`retenido` AS `retenido`,`venta`.`descuento` AS `total_descuento`,`venta`.`total` AS `total`,`venta`.`sonletras` AS `sonletras`,`venta`.`estado` AS `estado_venta`,`venta`.`idcliente` AS `idcliente`,`cliente`.`nombre_cliente` AS `cliente`,`cliente`.`numero_nit` AS `ruc`,`detalleventa`.`idproducto` AS `idproducto`,`view_productos`.`codigo_barra` AS `codigo_barra`,`view_productos`.`codigo_interno` AS `codigo_interno`,`view_productos`.`nombre_producto` AS `nombre_producto`,`view_productos`.`nombre_marca` AS `nombre_marca`,`view_productos`.`siglas` AS `siglas`,`view_productos`.`exento` AS `producto_exento`,`view_productos`.`perecedero` AS `perecedero`,`detalleventa`.`fecha_vence` AS `fecha_vence`,`detalleventa`.`cantidad` AS `cantidad`,`detalleventa`.`precio_unitario` AS `precio_unitario`,`view_productos`.`precio_compra` AS `precio_compra`,`detalleventa`.`exento` AS `exento`,`detalleventa`.`descuento` AS `descuento`,`detalleventa`.`importe` AS `importe`,concat(`view_usuarios`.`nombre_empleado`,' ',`view_usuarios`.`apellido_empleado`) AS `empleado` from ((((`venta` join `detalleventa` on((`detalleventa`.`idventa` = `venta`.`idventa`))) join `view_productos` on((`detalleventa`.`idproducto` = `view_productos`.`idproducto`))) join `view_usuarios` on((`view_usuarios`.`idusuario` = `venta`.`idusuario`))) left join `cliente` on((`venta`.`idcliente` = `cliente`.`idcliente`))) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `abono`
--
ALTER TABLE `abono`
  ADD PRIMARY KEY (`idabono`),
  ADD KEY `fk_abono_credito1_idx` (`idcredito`),
  ADD KEY `fk_abono_usuario1_idx` (`idusuario`);

--
-- Indices de la tabla `abonoproveedor`
--
ALTER TABLE `abonoproveedor`
  ADD PRIMARY KEY (`idabonoproveedor`),
  ADD KEY `idcreditoproveedor` (`idcreditoproveedor`);

--
-- Indices de la tabla `apartado`
--
ALTER TABLE `apartado`
  ADD PRIMARY KEY (`idapartado`),
  ADD UNIQUE KEY `numero_venta_UNIQUE` (`numero_apartado`),
  ADD KEY `fk_venta_cliente1_idx` (`idcliente`),
  ADD KEY `fk_venta_usuario1_idx` (`idusuario`);

--
-- Indices de la tabla `caja`
--
ALTER TABLE `caja`
  ADD PRIMARY KEY (`idcaja`);

--
-- Indices de la tabla `caja_movimiento`
--
ALTER TABLE `caja_movimiento`
  ADD KEY `fk_caja_movimiento_caja1_idx` (`idcaja`);

--
-- Indices de la tabla `categoria`
--
ALTER TABLE `categoria`
  ADD PRIMARY KEY (`idcategoria`);

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`idcliente`),
  ADD UNIQUE KEY `codigo_cliente_UNIQUE` (`codigo_cliente`);

--
-- Indices de la tabla `compra`
--
ALTER TABLE `compra`
  ADD PRIMARY KEY (`idcompra`),
  ADD KEY `fk_compra_proveedor1_idx` (`idproveedor`);

--
-- Indices de la tabla `comprobante`
--
ALTER TABLE `comprobante`
  ADD PRIMARY KEY (`idcomprobante`);

--
-- Indices de la tabla `cotizacion`
--
ALTER TABLE `cotizacion`
  ADD PRIMARY KEY (`idcotizacion`),
  ADD KEY `fk_cotizacion_usuario1_idx` (`idusuario`),
  ADD KEY `fk_cotizacion_cliente1_idx` (`idcliente`);

--
-- Indices de la tabla `credito`
--
ALTER TABLE `credito`
  ADD PRIMARY KEY (`idcredito`),
  ADD KEY `fk_credito_venta1_idx` (`idventa`),
  ADD KEY `fk_credito_cliente1_idx` (`idcliente`);

--
-- Indices de la tabla `creditoproveedor`
--
ALTER TABLE `creditoproveedor`
  ADD PRIMARY KEY (`idcreditoproveedor`),
  ADD KEY `idcompra` (`idcompra`),
  ADD KEY `idproveedor` (`idproveedor`);

--
-- Indices de la tabla `currency`
--
ALTER TABLE `currency`
  ADD PRIMARY KEY (`idcurrency`);

--
-- Indices de la tabla `detalleapartado`
--
ALTER TABLE `detalleapartado`
  ADD KEY `fk_detalleventa_producto1_idx` (`idproducto`),
  ADD KEY `fk_detalleapartado_apartado1_idx` (`idapartado`);

--
-- Indices de la tabla `detallecompra`
--
ALTER TABLE `detallecompra`
  ADD KEY `fk_detallecompra_producto1_idx` (`idproducto`),
  ADD KEY `fk_detallecompra_compra1_idx` (`idcompra`);

--
-- Indices de la tabla `detallecotizacion`
--
ALTER TABLE `detallecotizacion`
  ADD KEY `fk_detallecotizacion_producto1_idx` (`idproducto`),
  ADD KEY `fk_detallecotizacion_cotizacion1_idx` (`idcotizacion`);

--
-- Indices de la tabla `detalleventa`
--
ALTER TABLE `detalleventa`
  ADD KEY `fk_detalleventa_venta1_idx` (`idventa`),
  ADD KEY `fk_detalleventa_producto1_idx` (`idproducto`);

--
-- Indices de la tabla `empleado`
--
ALTER TABLE `empleado`
  ADD PRIMARY KEY (`idempleado`),
  ADD UNIQUE KEY `codigo_empleado_UNIQUE` (`codigo_empleado`);

--
-- Indices de la tabla `entrada`
--
ALTER TABLE `entrada`
  ADD PRIMARY KEY (`identrada`),
  ADD KEY `fk_entrada_producto1_idx` (`idproducto`),
  ADD KEY `fk_entrada_compra1_idx` (`idcompra`),
  ADD KEY `fk_entrada_apartado1_idx` (`idapartado`);

--
-- Indices de la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD KEY `fk_inventario_producto1_idx` (`idproducto`);

--
-- Indices de la tabla `marca`
--
ALTER TABLE `marca`
  ADD PRIMARY KEY (`idmarca`);

--
-- Indices de la tabla `ordentaller`
--
ALTER TABLE `ordentaller`
  ADD PRIMARY KEY (`idorden`),
  ADD KEY `fk_ordentaller_cliente1_idx` (`idcliente`),
  ADD KEY `fk_ordentaller_marca1_idx` (`idmarca`),
  ADD KEY `fk_ordentaller_tecnico1_idx` (`idtecnico`);

--
-- Indices de la tabla `parametro`
--
ALTER TABLE `parametro`
  ADD PRIMARY KEY (`idparametro`),
  ADD KEY `fk_parametro_currency1_idx` (`idcurrency`);

--
-- Indices de la tabla `perecedero`
--
ALTER TABLE `perecedero`
  ADD KEY `fk_perecedero_producto1_idx` (`idproducto`);

--
-- Indices de la tabla `presentacion`
--
ALTER TABLE `presentacion`
  ADD PRIMARY KEY (`idpresentacion`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`idproducto`),
  ADD UNIQUE KEY `codigo_interno_UNIQUE` (`codigo_interno`),
  ADD KEY `fk_producto_categoria_idx` (`idcategoria`),
  ADD KEY `fk_producto_presentacion1_idx` (`idpresentacion`),
  ADD KEY `fk_producto_marca1_idx` (`idmarca`);

--
-- Indices de la tabla `producto_proveedor`
--
ALTER TABLE `producto_proveedor`
  ADD KEY `fk_producto_proveedor_proveedor1_idx` (`idproveedor`),
  ADD KEY `fk_producto_proveedor_producto1_idx` (`idproducto`);

--
-- Indices de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`idproveedor`),
  ADD UNIQUE KEY `nombre_proveedor_UNIQUE` (`nombre_proveedor`),
  ADD UNIQUE KEY `codigo_proveedor_UNIQUE` (`codigo_proveedor`);

--
-- Indices de la tabla `proveedor_precio`
--
ALTER TABLE `proveedor_precio`
  ADD KEY `fk_proveedor_precio_proveedor1_idx` (`idproveedor`),
  ADD KEY `fk_proveedor_precio_producto1_idx` (`idproducto`);

--
-- Indices de la tabla `salida`
--
ALTER TABLE `salida`
  ADD PRIMARY KEY (`idsalida`),
  ADD KEY `fk_entrada_producto1_idx` (`idproducto`),
  ADD KEY `fk_salida_venta1_idx` (`idventa`),
  ADD KEY `fk_salida_apartado1_idx` (`idapartado`);

--
-- Indices de la tabla `tecnico`
--
ALTER TABLE `tecnico`
  ADD PRIMARY KEY (`idtecnico`);

--
-- Indices de la tabla `tiraje_comprobante`
--
ALTER TABLE `tiraje_comprobante`
  ADD PRIMARY KEY (`idtiraje`),
  ADD KEY `fk_tiraje_comprobante_comprobante1_idx` (`idcomprobante`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`idusuario`),
  ADD KEY `fk_usuario_empleado1_idx` (`idempleado`);

--
-- Indices de la tabla `venta`
--
ALTER TABLE `venta`
  ADD PRIMARY KEY (`idventa`),
  ADD UNIQUE KEY `numero_venta_UNIQUE` (`numero_venta`),
  ADD KEY `fk_venta_cliente1_idx` (`idcliente`),
  ADD KEY `fk_venta_usuario1_idx` (`idusuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `abono`
--
ALTER TABLE `abono`
  MODIFY `idabono` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `abonoproveedor`
--
ALTER TABLE `abonoproveedor`
  MODIFY `idabonoproveedor` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `apartado`
--
ALTER TABLE `apartado`
  MODIFY `idapartado` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `caja`
--
ALTER TABLE `caja`
  MODIFY `idcaja` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `categoria`
--
ALTER TABLE `categoria`
  MODIFY `idcategoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `idcliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `compra`
--
ALTER TABLE `compra`
  MODIFY `idcompra` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `comprobante`
--
ALTER TABLE `comprobante`
  MODIFY `idcomprobante` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `cotizacion`
--
ALTER TABLE `cotizacion`
  MODIFY `idcotizacion` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `credito`
--
ALTER TABLE `credito`
  MODIFY `idcredito` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `creditoproveedor`
--
ALTER TABLE `creditoproveedor`
  MODIFY `idcreditoproveedor` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `currency`
--
ALTER TABLE `currency`
  MODIFY `idcurrency` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `empleado`
--
ALTER TABLE `empleado`
  MODIFY `idempleado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `entrada`
--
ALTER TABLE `entrada`
  MODIFY `identrada` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `marca`
--
ALTER TABLE `marca`
  MODIFY `idmarca` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `ordentaller`
--
ALTER TABLE `ordentaller`
  MODIFY `idorden` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `parametro`
--
ALTER TABLE `parametro`
  MODIFY `idparametro` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `presentacion`
--
ALTER TABLE `presentacion`
  MODIFY `idpresentacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `idproducto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `idproveedor` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `salida`
--
ALTER TABLE `salida`
  MODIFY `idsalida` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `tecnico`
--
ALTER TABLE `tecnico`
  MODIFY `idtecnico` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `tiraje_comprobante`
--
ALTER TABLE `tiraje_comprobante`
  MODIFY `idtiraje` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `idusuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `venta`
--
ALTER TABLE `venta`
  MODIFY `idventa` int(11) NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `abono`
--
ALTER TABLE `abono`
  ADD CONSTRAINT `fk_abono_credito1` FOREIGN KEY (`idcredito`) REFERENCES `credito` (`idcredito`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_abono_usuario1` FOREIGN KEY (`idusuario`) REFERENCES `usuario` (`idusuario`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `apartado`
--
ALTER TABLE `apartado`
  ADD CONSTRAINT `fk_venta_cliente0` FOREIGN KEY (`idcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_venta_usuario0` FOREIGN KEY (`idusuario`) REFERENCES `usuario` (`idusuario`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `caja_movimiento`
--
ALTER TABLE `caja_movimiento`
  ADD CONSTRAINT `fk_caja_movimiento_caja` FOREIGN KEY (`idcaja`) REFERENCES `caja` (`idcaja`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `compra`
--
ALTER TABLE `compra`
  ADD CONSTRAINT `fk_compra_proveedor` FOREIGN KEY (`idproveedor`) REFERENCES `proveedor` (`idproveedor`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `cotizacion`
--
ALTER TABLE `cotizacion`
  ADD CONSTRAINT `fk_cotizacion_cliente1` FOREIGN KEY (`idcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cotizacion_usuario1` FOREIGN KEY (`idusuario`) REFERENCES `usuario` (`idusuario`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `credito`
--
ALTER TABLE `credito`
  ADD CONSTRAINT `fk_credito_cliente1` FOREIGN KEY (`idcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_credito_venta1` FOREIGN KEY (`idventa`) REFERENCES `venta` (`idventa`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalleapartado`
--
ALTER TABLE `detalleapartado`
  ADD CONSTRAINT `fk_detalleapartado_apartado1` FOREIGN KEY (`idapartado`) REFERENCES `apartado` (`idapartado`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_detalleventa_producto0` FOREIGN KEY (`idproducto`) REFERENCES `producto` (`idproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detallecompra`
--
ALTER TABLE `detallecompra`
  ADD CONSTRAINT `fk_detallecompra_compra` FOREIGN KEY (`idcompra`) REFERENCES `compra` (`idcompra`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_detallecompra_producto` FOREIGN KEY (`idproducto`) REFERENCES `producto` (`idproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detallecotizacion`
--
ALTER TABLE `detallecotizacion`
  ADD CONSTRAINT `fk_detallecotizacion_cotizacion1` FOREIGN KEY (`idcotizacion`) REFERENCES `cotizacion` (`idcotizacion`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_detallecotizacion_producto1` FOREIGN KEY (`idproducto`) REFERENCES `producto` (`idproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalleventa`
--
ALTER TABLE `detalleventa`
  ADD CONSTRAINT `fk_detalleventa_producto` FOREIGN KEY (`idproducto`) REFERENCES `producto` (`idproducto`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_detalleventa_venta` FOREIGN KEY (`idventa`) REFERENCES `venta` (`idventa`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `entrada`
--
ALTER TABLE `entrada`
  ADD CONSTRAINT `fk_entrada_apartado` FOREIGN KEY (`idapartado`) REFERENCES `apartado` (`idapartado`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_entrada_compra` FOREIGN KEY (`idcompra`) REFERENCES `compra` (`idcompra`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_entrada_producto` FOREIGN KEY (`idproducto`) REFERENCES `producto` (`idproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD CONSTRAINT `fk_inventario_producto` FOREIGN KEY (`idproducto`) REFERENCES `producto` (`idproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `parametro`
--
ALTER TABLE `parametro`
  ADD CONSTRAINT `fk_parametro_currency1` FOREIGN KEY (`idcurrency`) REFERENCES `currency` (`idcurrency`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
