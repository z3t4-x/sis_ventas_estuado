<?php
	require('ClassTicket.php');
	$idventa =  base64_decode(isset($_GET['venta']) ? $_GET['venta'] : '');
	try
	{

	function __autoload($className){
            $model = "../model/". $className ."_model.php";
            $controller = "../controller/". $className ."_controller.php";

           require_once($model);
           require_once($controller);
    }


    $objVenta = new Venta();

    if($idventa == ""){
    	$detalle = $objVenta->Imprimir_Ticket_DetalleVenta('0');
    	$datos = $objVenta->Imprimir_Ticket_Venta('0');
    } else {
    	$detalle = $objVenta->Imprimir_Ticket_DetalleVenta($idventa);
    	$datos = $objVenta->Imprimir_Ticket_Venta($idventa);
    }

    foreach ($datos as $row => $column) {

    	$tipo_comprobante = $column["p_tipo_comprobante"];
    	$empresa = $column["p_empresa"];
    	$propietario = $column["p_propietario"];
    	$direccion = $column["p_direccion"];
    	$nit = $column["p_numero_nit"];
    	$nrc = $column["p_numero_nrc"];
    	$fecha_resolucion = $column["p_fecha_resolucion"];
    	$numero_resolucion = $column["p_numero_resolucion"];
    	$serie = $column["p_serie"];
    	$numero_comprobante = $column["p_numero_comprobante"];
    	$empleado = $column["p_empleado"];
    	$numero_venta = $column["p_numero_venta"];
    	$fecha_venta = $column["p_fecha_venta"];
    	$subtotal = $column["p_subtotal"];
    	$exento = $column["p_exento"];
    	$descuento = $column["p_descuento"];
    	$total = $column["p_total"];
    	$numero_productos = $column["p_numero_productos"];
		$tipo_pago = $column["p_tipo_pago"];
		$efectivo = $column["p_pago_efectivo"];
		$pago_tarjeta = $column["p_pago_tarjeta"];
		$numero_tarjeta = $column["p_numero_tarjeta"];
		$tarjeta_habiente = $column["p_tarjeta_habiente"];
		$cambio = $column["p_cambio"];
		$moneda = $column["p_moneda"];
		$estado = $column["p_estado"];
    }

    
		$numero_tarjeta = substr($numero_tarjeta,0,4).'-XXXX-XXXX-'.substr($numero_tarjeta,12,16);

	$pdf = new TICKET('P','mm',array(76,297));
	$pdf->AddPage();


	if($tipo_comprobante == '1')
	{
		$pdf->SetFont('Arial', '', 12);
		$pdf->SetAutoPageBreak(true,1);

		include('../includes/ticketheader.inc.php');

		$pdf->SetFont('Arial', '', 9.2);
		$pdf->Text(2, $get_YH + 2 , '------------------------------------------------------------------');
		$pdf->SetFont('Arial', 'B', 8.5);
		$pdf->Text(3.8, $get_YH  + 5, 'Transc : '.$numero_venta);
		$pdf->Text(55, $get_YH + 5, 'Caja No.: 1');
		$pdf->Text(4, $get_YH + 10, 'Fecha : '.$fecha_venta);
		$pdf->Text(4, $get_YH + 15, 'No. Ticket : '.$numero_comprobante);
		$pdf->Text(38, $get_YH  + 15, 'Cajero : '.substr($empleado, 0,5));
		$pdf->SetFont('Arial', '', 9.2);
		$pdf->Text(2, $get_YH + 18, '------------------------------------------------------------------');

		$pdf->SetXY(2,$get_YH + 19);
		$pdf->SetFillColor(255,255,255);
		$pdf->SetFont('Arial','B',8.5);
		$pdf->Cell(13,4,'Cantid',0,0,'L',1);
		$pdf->Cell(28,4,'Descripcion',0,0,'L',1);
		$pdf->Cell(16,4,'Precio',0,0,'L',1);
		$pdf->Cell(12,4,'Total',0,0,'L',1);
		$pdf->SetFont('Arial','',8.5);
		$pdf->Text(2, $get_YH + 24, '-----------------------------------------------------------------------');
		$pdf->Ln(6);
		$item = 0;
		while($row = $detalle->fetch(PDO::FETCH_ASSOC)) {
		 $item = $item + 1;
			$pdf->setX(1.1);
			$pdf->Cell(13,4,$row['cantidad'],0,0,'L');
			$pdf->Cell(28,4,$row['descripcion'],0,0,'L',1);
			$pdf->Cell(16,4,$row['precio_unitario'],0,0,'L',1);
			$pdf->Cell(8,4,$row['importe'],0,0,'L',1);
			$pdf->Ln(4.5);
			$get_Y = $pdf->GetY();
		}
		$pdf->Text(2, $get_Y+1, '-----------------------------------------------------------------------');
		$pdf->SetFont('Arial','B',8.5);
		$pdf->Text(4,$get_Y + 5,'G = GRAVADO');
		$pdf->Text(30,$get_Y + 5,'E = EXENTO');

		$pdf->Text(4,$get_Y + 10,'SUBTOTAL :');
		$pdf->Text(57,$get_Y + 10,$subtotal);
		$pdf->Text(4,$get_Y + 15,'EXENTO :');
		$pdf->Text(57,$get_Y + 15,$exento);
		$pdf->Text(4,$get_Y + 20,'GRAVADO :');
		$pdf->Text(57,$get_Y + 20,$subtotal);
		$pdf->Text(4,$get_Y + 25,'DESCUENTO :');
		$pdf->Text(56,$get_Y + 25,'-'.$descuento);
		$pdf->Text(4,$get_Y + 30,'TOTAL A PAGAR :');
		$pdf->SetFont('Arial','B',8.5);
		$pdf->Text(57,$get_Y + 30,$total);

		$pdf->Text(2, $get_Y+33, '-----------------------------------------------------------------------');
		$pdf->Text(4,$get_Y + 36,'Numero de Productos :');
		$pdf->Text(57,$get_Y + 36,$numero_productos);

		if($tipo_pago == 'EFECTIVO'){

		$pdf->Text(24,$get_Y + 40,'Efectivo :');
		$pdf->Text(57,$get_Y + 40,$efectivo);
		$pdf->Text(24,$get_Y + 44,'Cambio :');
		$pdf->Text(57,$get_Y + 44,$cambio);


		$pdf->Text(2, $get_Y+47, '-----------------------------------------------------------------------');
		$pdf->SetFont('Arial','BI',8.5);
		$pdf->Text(3, $get_Y+52, 'Precios en : '.$moneda);
		if($estado == '2'):
			$pdf->Text(3, $get_Y+55, 'Esta venta ha sido al credito');
			$pdf->SetFont('Arial','B',8.5);
		endif;
		$pdf->SetFont('Arial','B',8.5);
		$pdf->Text(19, $get_Y+62, 'GRACIAS POR SU COMPRA');
		$pdf->SetFillColor(0,0,0);
		$pdf->Code39(9,$get_Y+64,$numero_venta,1,5);
		$pdf->Text(28, $get_Y+74, '*'.$numero_venta.'*');

	} else if ($tipo_pago == 'TARJETA'){

		$pdf->Text(20,$get_Y + 40.5,'No. Tarjeta :');
		$pdf->Text(40,$get_Y + 40.5,$numero_tarjeta);
		$pdf->Text(23,$get_Y + 45,'Debitado :');
		$pdf->Text(57,$get_Y + 45,$total);

		$pdf->Text(2, $get_Y+47, '-----------------------------------------------------------------------');
		$pdf->SetFont('Arial','BI',8.5);
		$pdf->Text(3, $get_Y+52, 'Precios en : '.$moneda);
		$pdf->SetFont('Arial','B',8.5);
		if($estado == '2'):
			$pdf->Text(3, $get_Y+55, 'Esta venta ha sido al credito');
			$pdf->SetFont('Arial','B',8.5);
		endif;
		$pdf->Text(19, $get_Y+62, 'GRACIAS POR SU COMPRA');
		$pdf->SetFillColor(0,0,0);
		$pdf->Code39(9,$get_Y+64,$numero_venta,1,5);
		$pdf->Text(28, $get_Y+74, '*'.$numero_venta.'*');

	} else if ($tipo_pago == 'EFECTIVO Y TARJETA'){

		$pdf->Text(24,$get_Y + 41,'Efectivo :');
		$pdf->Text(57,$get_Y + 41,$efectivo);

		$pdf->Text(20,$get_Y + 46,'No. Tarjeta :');
		$pdf->Text(40,$get_Y + 46,$numero_tarjeta);
		$pdf->Text(23,$get_Y + 51,'Debitado :');
		$pdf->Text(57,$get_Y + 51,$pago_tarjeta);

		$pdf->Text(2, $get_Y+53, '-----------------------------------------------------------------------');
		$pdf->SetFont('Arial','BI',8.5);
		$pdf->Text(3, $get_Y+58, 'Precios en : '.$moneda);
		$pdf->SetFont('Arial','',8.5);
		$pdf->Text(3, $get_Y+63, 'Venta realizada con dos metodos de pago');
		$pdf->SetFont('Arial','B',8.5);
		if($estado == '2'):
			$pdf->Text(3, $get_Y+66, 'Esta venta ha sido al credito');
			$pdf->SetFont('Arial','B',8.5);
		endif;
		$pdf->Text(19, $get_Y+73, 'GRACIAS POR SU COMPRA');
		$pdf->SetFillColor(0,0,0);
		$pdf->Code39(9,$get_Y+75,$numero_venta,1,5);
		$pdf->Text(28, $get_Y+84, '*'.$numero_venta.'*');

	}

		//$pdf->IncludeJS("print('true');");

	} else if ($tipo_comprobante == '2') {

				$pdf->SetFont('Arial', '', 12);
				$pdf->SetAutoPageBreak(true,1);

				include('../includes/ticketheader.inc.php');

				$pdf->SetFont('Arial', '', 9.2);
				$pdf->Text(2, $get_YH + 2 , '------------------------------------------------------------------');
				$pdf->SetFont('Arial', 'B', 8.5);
				$pdf->Text(3.8, $get_YH  + 5, 'Transc : '.$numero_venta);
				$pdf->Text(55, $get_YH + 5, 'Caja No.: 1');
				$pdf->Text(4, $get_YH + 10, 'Fecha : '.$fecha_venta);
				$pdf->Text(4, $get_YH + 15, 'No. Factura : '.$numero_comprobante);
				$pdf->Text(38, $get_YH  + 15, 'Cajero : '.substr($empleado, 0,5));
				$pdf->SetFont('Arial', '', 9.2);
				$pdf->Text(2, $get_YH + 18, '------------------------------------------------------------------');

				$pdf->SetXY(2,$get_YH + 19);
				$pdf->SetFillColor(255,255,255);
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Cell(13,4,'Cantid',0,0,'L',1);
				$pdf->Cell(28,4,'Descripcion',0,0,'L',1);
				$pdf->Cell(16,4,'Precio',0,0,'L',1);
				$pdf->Cell(12,4,'Total',0,0,'L',1);
				$pdf->SetFont('Arial','',8.5);
				$pdf->Text(2, $get_YH + 24, '-----------------------------------------------------------------------');
				$pdf->Ln(6);
				$item = 0;
				while($row = $detalle->fetch(PDO::FETCH_ASSOC)) {
				 $item = $item + 1;
					$pdf->setX(1.1);
					$pdf->Cell(13,4,$row['cantidad'],0,0,'L');
					$pdf->Cell(28,4,$row['descripcion'],0,0,'L',1);
					$pdf->Cell(16,4,$row['precio_unitario'],0,0,'L',1);
					$pdf->Cell(8,4,$row['importe'],0,0,'L',1);
					$pdf->Ln(4.5);
					$get_Y = $pdf->GetY();
				}
				$pdf->Text(2, $get_Y+1, '-----------------------------------------------------------------------');
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Text(4,$get_Y + 5,'G = GRAVADO');
				$pdf->Text(30,$get_Y + 5,'E = EXENTO');

				$pdf->Text(4,$get_Y + 10,'SUBTOTAL :');
				$pdf->Text(57,$get_Y + 10,$subtotal);
				$pdf->Text(4,$get_Y + 15,'EXENTO :');
				$pdf->Text(57,$get_Y + 15,$exento);
				$pdf->Text(4,$get_Y + 20,'GRAVADO :');
				$pdf->Text(57,$get_Y + 20,$subtotal);
				$pdf->Text(4,$get_Y + 25,'DESCUENTO :');
				$pdf->Text(56,$get_Y + 25,'-'.$descuento);
				$pdf->Text(4,$get_Y + 30,'TOTAL A PAGAR :');
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Text(57,$get_Y + 30,$total);

				$pdf->Text(2, $get_Y+33, '-----------------------------------------------------------------------');
				$pdf->Text(4,$get_Y + 36,'Numero de Productos :');
				$pdf->Text(57,$get_Y + 36,$numero_productos);

				if($tipo_pago == 'EFECTIVO'){

				$pdf->Text(24,$get_Y + 40,'Efectivo :');
				$pdf->Text(57,$get_Y + 40,$efectivo);
				$pdf->Text(24,$get_Y + 44,'Cambio :');
				$pdf->Text(57,$get_Y + 44,$cambio);


				$pdf->Text(2, $get_Y+47, '-----------------------------------------------------------------------');
				$pdf->SetFont('Arial','BI',8.5);
				$pdf->Text(3, $get_Y+52, 'Precios en : '.$moneda);
				if($estado == '2'):
					$pdf->Text(3, $get_Y+55, 'Esta venta ha sido al credito');
					$pdf->SetFont('Arial','B',8.5);
				endif;
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Text(19, $get_Y+62, 'GRACIAS POR SU COMPRA');
				$pdf->SetFillColor(0,0,0);
				$pdf->Code39(9,$get_Y+64,$numero_venta,1,5);
				$pdf->Text(28, $get_Y+74, '*'.$numero_venta.'*');

			} else if ($tipo_pago == 'TARJETA'){

				$pdf->Text(20,$get_Y + 40.5,'No. Tarjeta :');
				$pdf->Text(40,$get_Y + 40.5,$numero_tarjeta);
				$pdf->Text(23,$get_Y + 45,'Debitado :');
				$pdf->Text(57,$get_Y + 45,$total);

				$pdf->Text(2, $get_Y+47, '-----------------------------------------------------------------------');
				$pdf->SetFont('Arial','BI',8.5);
				$pdf->Text(3, $get_Y+52, 'Precios en : '.$moneda);
				$pdf->SetFont('Arial','B',8.5);
				if($estado == '2'):
					$pdf->Text(3, $get_Y+55, 'Esta venta ha sido al credito');
					$pdf->SetFont('Arial','B',8.5);
				endif;
				$pdf->Text(19, $get_Y+62, 'GRACIAS POR SU COMPRA');
				$pdf->SetFillColor(0,0,0);
				$pdf->Code39(9,$get_Y+64,$numero_venta,1,5);
				$pdf->Text(28, $get_Y+74, '*'.$numero_venta.'*');

			} else if ($tipo_pago == 'EFECTIVO Y TARJETA'){

				$pdf->Text(24,$get_Y + 41,'Efectivo :');
				$pdf->Text(57,$get_Y + 41,$efectivo);

				$pdf->Text(20,$get_Y + 46,'No. Tarjeta :');
				$pdf->Text(40,$get_Y + 46,$numero_tarjeta);
				$pdf->Text(23,$get_Y + 51,'Debitado :');
				$pdf->Text(57,$get_Y + 51,$pago_tarjeta);

				$pdf->Text(2, $get_Y+53, '-----------------------------------------------------------------------');
				$pdf->SetFont('Arial','BI',8.5);
				$pdf->Text(3, $get_Y+58, 'Precios en : '.$moneda);
				$pdf->SetFont('Arial','',8.5);
				$pdf->Text(3, $get_Y+63, 'Venta realizada con dos metodos de pago');
				$pdf->SetFont('Arial','B',8.5);
				if($estado == '2'):
					$pdf->Text(3, $get_Y+66, 'Esta venta ha sido al credito');
					$pdf->SetFont('Arial','B',8.5);
				endif;
				$pdf->Text(19, $get_Y+73, 'GRACIAS POR SU COMPRA');
				$pdf->SetFillColor(0,0,0);
				$pdf->Code39(9,$get_Y+75,$numero_venta,1,5);
				$pdf->Text(28, $get_Y+84, '*'.$numero_venta.'*');

			}
			
		} else if ($tipo_comprobante == '3') {


				$pdf->SetFont('Arial', '', 12);
				$pdf->SetAutoPageBreak(true,1);

				include('../includes/ticketheader.inc.php');

				$pdf->SetFont('Arial', '', 9.2);
				$pdf->Text(2, $get_YH + 2 , '------------------------------------------------------------------');
				$pdf->SetFont('Arial', 'B', 8.5);
				$pdf->Text(3.8, $get_YH  + 5, 'Transc : '.$numero_venta);
				$pdf->Text(55, $get_YH + 5, 'Caja No.: 1');
				$pdf->Text(4, $get_YH + 10, 'Fecha : '.$fecha_venta);
				$pdf->Text(4, $get_YH + 15, 'No. Boleta : '.$numero_comprobante);
				$pdf->Text(38, $get_YH  + 15, 'Cajero : '.substr($empleado, 0,5));
				$pdf->SetFont('Arial', '', 9.2);
				$pdf->Text(2, $get_YH + 18, '------------------------------------------------------------------');

				$pdf->SetXY(2,$get_YH + 19);
				$pdf->SetFillColor(255,255,255);
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Cell(13,4,'Cantid',0,0,'L',1);
				$pdf->Cell(28,4,'Descripcion',0,0,'L',1);
				$pdf->Cell(16,4,'Precio',0,0,'L',1);
				$pdf->Cell(12,4,'Total',0,0,'L',1);
				$pdf->SetFont('Arial','',8.5);
				$pdf->Text(2, $get_YH + 24, '-----------------------------------------------------------------------');
				$pdf->Ln(6);
				$item = 0;
				while($row = $detalle->fetch(PDO::FETCH_ASSOC)) {
				 $item = $item + 1;
					$pdf->setX(1.1);
					$pdf->Cell(13,4,$row['cantidad'],0,0,'L');
					$pdf->Cell(28,4,$row['descripcion'],0,0,'L',1);
					$pdf->Cell(16,4,$row['precio_unitario'],0,0,'L',1);
					$pdf->Cell(8,4,$row['importe'],0,0,'L',1);
					$pdf->Ln(4.5);
					$get_Y = $pdf->GetY();
				}
				$pdf->Text(2, $get_Y+1, '-----------------------------------------------------------------------');
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Text(4,$get_Y + 5,'G = GRAVADO');
				$pdf->Text(30,$get_Y + 5,'E = EXENTO');

				$pdf->Text(4,$get_Y + 10,'SUBTOTAL :');
				$pdf->Text(57,$get_Y + 10,$subtotal);
				$pdf->Text(4,$get_Y + 15,'EXENTO :');
				$pdf->Text(57,$get_Y + 15,$exento);
				$pdf->Text(4,$get_Y + 20,'GRAVADO :');
				$pdf->Text(57,$get_Y + 20,$subtotal);
				$pdf->Text(4,$get_Y + 25,'DESCUENTO :');
				$pdf->Text(56,$get_Y + 25,'-'.$descuento);
				$pdf->Text(4,$get_Y + 30,'TOTAL A PAGAR :');
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Text(57,$get_Y + 30,$total);

				$pdf->Text(2, $get_Y+33, '-----------------------------------------------------------------------');
				$pdf->Text(4,$get_Y + 36,'Numero de Productos :');
				$pdf->Text(57,$get_Y + 36,$numero_productos);

				if($tipo_pago == 'EFECTIVO'){

				$pdf->Text(24,$get_Y + 40,'Efectivo :');
				$pdf->Text(57,$get_Y + 40,$efectivo);
				$pdf->Text(24,$get_Y + 44,'Cambio :');
				$pdf->Text(57,$get_Y + 44,$cambio);


				$pdf->Text(2, $get_Y+47, '-----------------------------------------------------------------------');
				$pdf->SetFont('Arial','BI',8.5);
				$pdf->Text(3, $get_Y+52, 'Precios en : '.$moneda);
				if($estado == '2'):
					$pdf->Text(3, $get_Y+55, 'Esta venta ha sido al credito');
					$pdf->SetFont('Arial','B',8.5);
				endif;
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Text(19, $get_Y+62, 'GRACIAS POR SU COMPRA');
				$pdf->SetFillColor(0,0,0);
				$pdf->Code39(9,$get_Y+64,$numero_venta,1,5);
				$pdf->Text(28, $get_Y+74, '*'.$numero_venta.'*');

			} else if ($tipo_pago == 'TARJETA'){

				$pdf->Text(20,$get_Y + 40.5,'No. Tarjeta :');
				$pdf->Text(40,$get_Y + 40.5,$numero_tarjeta);
				$pdf->Text(23,$get_Y + 45,'Debitado :');
				$pdf->Text(57,$get_Y + 45,$total);

				$pdf->Text(2, $get_Y+47, '-----------------------------------------------------------------------');
				$pdf->SetFont('Arial','BI',8.5);
				$pdf->Text(3, $get_Y+52, 'Precios en : '.$moneda);
				$pdf->SetFont('Arial','B',8.5);
				if($estado == '2'):
					$pdf->Text(3, $get_Y+55, 'Esta venta ha sido al credito');
					$pdf->SetFont('Arial','B',8.5);
				endif;
				$pdf->Text(19, $get_Y+62, 'GRACIAS POR SU COMPRA');
				$pdf->SetFillColor(0,0,0);
				$pdf->Code39(9,$get_Y+64,$numero_venta,1,5);
				$pdf->Text(28, $get_Y+74, '*'.$numero_venta.'*');

			} else if ($tipo_pago == 'EFECTIVO Y TARJETA'){

				$pdf->Text(24,$get_Y + 41,'Efectivo :');
				$pdf->Text(57,$get_Y + 41,$efectivo);

				$pdf->Text(20,$get_Y + 46,'No. Tarjeta :');
				$pdf->Text(40,$get_Y + 46,$numero_tarjeta);
				$pdf->Text(23,$get_Y + 51,'Debitado :');
				$pdf->Text(57,$get_Y + 51,$pago_tarjeta);

				$pdf->Text(2, $get_Y+53, '-----------------------------------------------------------------------');
				$pdf->SetFont('Arial','BI',8.5);
				$pdf->Text(3, $get_Y+58, 'Precios en : '.$moneda);
				$pdf->SetFont('Arial','',8.5);
				$pdf->Text(3, $get_Y+63, 'Venta realizada con dos metodos de pago');
				$pdf->SetFont('Arial','B',8.5);
				if($estado == '2'):
					$pdf->Text(3, $get_Y+66, 'Esta venta ha sido al credito');
					$pdf->SetFont('Arial','B',8.5);
				endif;
				$pdf->Text(19, $get_Y+73, 'GRACIAS POR SU COMPRA');
				$pdf->SetFillColor(0,0,0);
				$pdf->Code39(9,$get_Y+75,$numero_venta,1,5);
				$pdf->Text(28, $get_Y+84, '*'.$numero_venta.'*');

			}
		}




	$pdf->Output('','Ticket_'.$numero_comprobante.'.pdf',true);
	} catch (Exception $e) {

		$pdf->Text(22.8, 5, 'ERROR AL IMPRIMIR TICKET');
		$pdf->Output('I','Ticket_ERROR.pdf',true);

	}








 ?>
