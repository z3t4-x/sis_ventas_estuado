<?php
  require('fpdf/fpdf.php');
  $idventa =  base64_decode(isset($_GET['venta']) ? $_GET['venta'] : '');

  class PDF_MC_Table extends FPDF
  {
  var $widths;
  var $aligns;

  function SetWidths($w)
  {
      //Set the array of column widths
      $this->widths=$w;
  }
  function SetAligns($a)
  {
      //Set the array of column alignments
      $this->aligns=$a;
  }

  function Row($data)
  {
      //Calculate the height of the row
      $nb=0;
      for($i=0;$i<count($data);$i++)
          $nb=max($nb,$this->NbLines($this->widths[$i],$data[$i]));
      $h=5*$nb;
      //Issue a page break first if needed
      $this->CheckPageBreak($h);
      //Draw the cells of the row
      for($i=0;$i<count($data);$i++)
      {
          $w=$this->widths[$i];
          $a=isset($this->aligns[$i]) ? $this->aligns[$i] : 'L';
          //Save the current position
          $x=$this->GetX();
          $y=$this->GetY();
          //Draw the border
          $this->Rect($x,$y,$w,$h);
          //Print the text
          $this->MultiCell($w,5,$data[$i],0,$a);
          //Put the position to the right of the cell
          $this->SetXY($x+$w,$y);
      }
      //Go to the next line
      $this->Ln($h);
  }

  function CheckPageBreak($h)
  {
      //If the height h would cause an overflow, add a new page immediately
      if($this->GetY()+$h>$this->PageBreakTrigger)
          $this->AddPage($this->CurOrientation);
  }

  function NbLines($w,$txt)
  {
      //Computes the number of lines a MultiCell of width w will take
      $cw=&$this->CurrentFont['cw'];
      if($w==0)
          $w=$this->w-$this->rMargin-$this->x;
      $wmax=($w-2*$this->cMargin)*1000/$this->FontSize;
      $s=str_replace("\r",'',$txt);
      $nb=strlen($s);
      if($nb>0 and $s[$nb-1]=="\n")
          $nb--;
      $sep=-1;
      $i=0;
      $j=0;
      $l=0;
      $nl=1;
      while($i<$nb)
      {
          $c=$s[$i];
          if($c=="\n")
          {
              $i++;
              $sep=-1;
              $j=$i;
              $l=0;
              $nl++;
              continue;
          }
          if($c==' ')
              $sep=$i;
          $l+=$cw[$c];
          if($l>$wmax)
          {
              if($sep==-1)
              {
                  if($i==$j)
                      $i++;
              }
              else
                  $i=$sep+1;
              $sep=-1;
              $j=$i;
              $l=0;
              $nl++;
          }
          else
              $i++;
      }
      return $nl;
  }
  }

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
    	$detalle = $objVenta->Imprimir_Factura_DetalleVenta('0');
    	//$detalle = $objVenta->Imprimir_Ticket_DetalleVenta('0');
    	$datos = $objVenta->Imprimir_Ticket_Venta('0');
    } else {
    	$detalle = $objVenta->Imprimir_Factura_DetalleVenta($idventa);
    	//$detalle = $objVenta->Imprimir_Ticket_DetalleVenta($idventa);
    	$datos = $objVenta->Imprimir_Ticket_Venta($idventa);
    }

		foreach ($datos as $row => $column) {

			$tipo_comprobante = $column["p_tipo_comprobante"];
			$empresa = $column["p_empresa"];
			$propietario = $column["p_propietario"];
			$direccion = $column["p_direccion"];
			$numero_cedula = $column["p_numero_nit"];
			$fecha_resolucion = $column["p_fecha_resolucion"];
			$numero_resolucion = $column["p_numero_resolucion"];
			$serie = $column["p_serie"];
			$numero_comprobante = $column["p_numero_comprobante"];
			$empleado = $column["p_empleado"];
			$numero_venta = $column["p_numero_venta"];
			$fecha_venta = $column["p_fecha_venta"];
			$sumas = $column["p_sumas"];
			$iva = $column["p_iva"];
			$subtotal = $column["p_subtotal"];
			$exento = $column["p_exento"];
			$retenido = $column["p_retenido"];
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
      $nombre_cliente = $column["p_nombre_cliente"];
      $direccion_cliente = $column["p_direccion_cliente"];
      $telefono_cliente = $column["p_telefono_cliente"];
      $numero_cedula_c = $column["p_cedula_cliente"];
      $telefono_cliente =  substr($telefono_cliente, 0, 4).'-'.substr($telefono_cliente, 4);
      $sonletras = $column["p_sonletras"];
		}

		/*
		* AQUI SE DEBE CAMBIAR PARA EL FACTOR DE CAMBIO DE DOLAR 
		*/

		$cambio_dolar = 4.1;

	  $numero_tarjeta = substr($numero_tarjeta,0,4).'-XXXX-XXXX-'.substr($numero_tarjeta,12,16);

    $pdf = new PDF_MC_Table('P','mm',array(76,180));
    $pdf->AddPage();
    $pdf->AliasNbPages();
    
    
    if ($tipo_comprobante == '3') {

				$pdf->SetFont('Arial', '', 12);
				$pdf->SetAutoPageBreak(true,1);

				include('../includes/ticketheader.inc.php');

				$pdf->SetFont('Arial', '', 9.2);
				$pdf->Text(2, $get_YH + 2 , '------------------------------------------------------------------');
				$pdf->SetFont('Arial', 'B', 8.5);
				$pdf->Text(22, $get_YH  + 5, 'FACTURA ELECTRONICA');
				$pdf->Text(28, $get_YH  + 10, 'F003 - '.str_pad($numero_comprobante, 9, '0', STR_PAD_LEFT));
				
				//$pdf->Text(55, $get_YH + 10, 'Caja No.: 1');
				$pdf->Text(3, $get_YH + 15, 'Fecha : '.$fecha_venta);
				//$pdf->Text(4, $get_YH + 15, 'No. Ticket : '.$numero_comprobante);

			//	$pdf->Text(48, $get_YH  + 15, 'Cajero : '.substr($empleado, 0,6));
				$pdf->Text(46, $get_YH  + 15, 'RUC : '.$numero_cedula_c);

				$pdf->Text(3, $get_YH + 20, 'R.S : '.substr($nombre_cliente,0,35));
			 
				$pdf->Text(3, $get_YH + 24, 'Dir : '.substr($direccion_cliente, 0,37));

				$pdf->SetFont('Arial', '', 9.2);
				//$pdf->Text(2, $get_YH + 23, '------------------------------------------------------------------');

				$pdf->SetXY(2,$get_YH + 25);
				$pdf->SetFillColor(255,255,255);
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Cell(13,4,'Cantid',0,0,'L',1);
				$pdf->Cell(28,4,'Descripcion',0,0,'L',1);
				$pdf->Cell(16,4,'Precio',0,0,'L',1);
				$pdf->Cell(12,4,'Total',0,0,'L',1);
				$pdf->SetFont('Arial','',8.5);
				$pdf->Text(2, $get_YH + 29, '-----------------------------------------------------------------------');
				$pdf->Ln(6);
				$item = 0;
				while($row = $detalle->fetch(PDO::FETCH_ASSOC)) {
				 $item = $item + 1;
					$pdf->setX(2.1);
					$pdf->Cell(13,4,$row['cantidad'],0,0,'L');
					$pdf->SetFont('Arial','',6);
					$pdf->Cell(28,4,substr($row['nombre_producto'],0,20),0,0,'L',1);
					$pdf->SetFont('Arial','',8.5);
					$pdf->Cell(8,4,$row['importe'],0,0,'L',1);
					$pdf->Ln(4.5);
					$get_Y = $pdf->GetY();
				}

				$pdf->Text(2, $get_Y+1, '-----------------------------------------------------------------------');
                $pdf->SetFont('Arial','B',8.5);
				$pdf->Text(4,$get_Y + 5,'G = GRAVADO');
				$pdf->Text(30,$get_Y + 5,'E = EXENTO');

				$pdf->Text(4,$get_Y + 10,'SUBTOTAL :');
				$pdf->Text(57,$get_Y + 10,$sumas);
				$pdf->Text(4,$get_Y + 15,'IGV :');
				$pdf->Text(57,$get_Y + 15,$iva);
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
				$pdf->Text(3, $get_Y+52, 'Son: '.$sonletras.' soles');
				if($estado == '2'):
					$pdf->Text(3, $get_Y+55, 'Esta venta ha sido al credito');
					$pdf->SetFont('Arial','B',8.5);
				endif;

				$pdf->Image('http://chart.googleapis.com/chart?chs=120x120&cht=qr&chl='.$numero_venta.'&.png',22,$get_Y+54);
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Text(18, $get_Y+88, 'GRACIAS POR SU COMPRA');
				$pdf->SetFillColor(0,0,0);
			//	$pdf->Code39(9,$get_Y+64,$numero_venta,1,5);
		//		$pdf->Text(28, $get_Y+74, '*'.$numero_venta.'*');

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
 				$pdf->Text(28, $get_Y+84, '*'.$numero_venta.'*'); 

			}
		} else if ($tipo_comprobante == '2') {

				$pdf->SetFont('Arial', '', 12);
				$pdf->SetAutoPageBreak(true,1);

				include('../includes/ticketheader.inc.php');

				$pdf->SetFont('Arial', '', 9.2);
				$pdf->Text(2, $get_YH + 2 , '------------------------------------------------------------------');
				$pdf->SetFont('Arial', 'B', 8.5);
				$pdf->Text(22, $get_YH  + 5, 'BOLETA ELECTRONICA');
				$pdf->Text(28, $get_YH  + 10, 'B003 - '.str_pad($numero_comprobante, 9, '0', STR_PAD_LEFT));
				
				//$pdf->Text(55, $get_YH + 10, 'Caja No.: 1');
				$pdf->Text(3, $get_YH + 15, 'Fecha : '.$fecha_venta);
				//$pdf->Text(4, $get_YH + 15, 'No. Ticket : '.$numero_comprobante);

				$pdf->Text(48, $get_YH  + 20, 'Cajero : '.substr($empleado, 0,5));
				$pdf->Text(3, $get_YH + 20, 'Cliente : '.$nombre_cliente);
				$pdf->SetFont('Arial', '', 9.2);
				$pdf->Text(2, $get_YH + 23, '------------------------------------------------------------------');

				$pdf->SetXY(2,$get_YH + 24);
				$pdf->SetFillColor(255,255,255);
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Cell(13,4,'Cantid',0,0,'L',1);
				$pdf->Cell(28,4,'Descripcion',0,0,'L',1);
				$pdf->Cell(16,4,'Precio',0,0,'L',1);
				$pdf->Cell(12,4,'Total',0,0,'L',1);
				$pdf->SetFont('Arial','',8.5);
				$pdf->Text(2, $get_YH + 29, '-----------------------------------------------------------------------');
				$pdf->Ln(6);
				$item = 0;
				while($row = $detalle->fetch(PDO::FETCH_ASSOC)) {
				 $item = $item + 1;
					$pdf->setX(1.1);
					$pdf->Cell(13,4,$row['cantidad'],0,0,'L');
					$pdf->SetFont('Arial','',6);
					$pdf->Cell(28,4,substr($row['nombre_producto'],0,20),0,0,'L',1);
					$pdf->SetFont('Arial','',8.5);
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
				$pdf->Text(57,$get_Y + 10,$sumas);
				$pdf->Text(4,$get_Y + 15,'IGV :');
				$pdf->Text(57,$get_Y + 15,$iva);
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
				$pdf->Text(3, $get_Y+52, 'Son: '.$sonletras.' soles');
				if($estado == '2'):
					$pdf->Text(3, $get_Y+55, 'Esta venta ha sido al credito');
					$pdf->SetFont('Arial','B',8.5);
				endif;

				$pdf->Image('http://chart.googleapis.com/chart?chs=120x120&cht=qr&chl='.$numero_venta.'&.png',22,$get_Y+54);
				$pdf->SetFont('Arial','B',8.5);
				$pdf->Text(18, $get_Y+88, 'GRACIAS POR SU COMPRA');
				$pdf->SetFillColor(0,0,0);
			//	$pdf->Code39(9,$get_Y+64,$numero_venta,1,5);
		//		$pdf->Text(28, $get_Y+74, '*'.$numero_venta.'*');

			} else if ($tipo_pago == 'TARJETA'){

		//		$pdf->Text(20,$get_Y + 40.5,'No. Tarjeta :');
			//	$pdf->Text(40,$get_Y + 40.5,$numero_tarjeta);
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
 				$pdf->Text(28, $get_Y+74, '*'.$numero_venta.'*');

			} else if ($tipo_pago == 'EFECTIVO Y TARJETA'){

				$pdf->Text(24,$get_Y + 41,'Efectivo :');
				$pdf->Text(57,$get_Y + 41,$efectivo);

			//	$pdf->Text(20,$get_Y + 46,'No. Tarjeta :');
			//	$pdf->Text(40,$get_Y + 46,$numero_tarjeta);
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
			//	$pdf->Code39(9,$get_Y+75,$numero_venta,1,5);
				$pdf->Text(28, $get_Y+84, '*'.$numero_venta.'*');

			}
    
    
    /*
    
    $pdf->SetFont('Arial','B',16);
    $pdf->setXY(10,6);
    $pdf->Cell(40,10,$empresa);


    $pdf->setXY(150,6);
    $pdf->SetFont('Arial','',11);
    $pdf->Cell(34,10,'NO. FACTURA : ');
    $pdf->SetFont('Arial','B',11);
    $pdf->Cell(30,10,$numero_comprobante);
    $pdf->SetFont('Arial','',10);
    
    $pdf->setXY(10,6);
    $pdf->SetFont('Arial','',8);
    $pdf->Cell(50,20,$propietario);
    $pdf->setX(10);
    $pdf->SetFont('Arial','',10);
    $pdf->Cell(2,30,$direccion);
    $pdf->setX(10);
    $pdf->SetFont('Arial','B',10);
    
    
    
    $pdf->SetFont('Arial','',10);
    $pdf->setXY(10,23);
    $pdf->Cell(38,7,'FECHA DE VENTA : ');
    $pdf->SetFont('Arial','B',10);
    $pdf->Cell(38,7,$fecha_venta);



    $pdf->SetFont('Arial','',10);
    $pdf->setXY(10,28);
    $pdf->Cell(38,7,'CLIENTE : ');
    $pdf->SetFont('Arial','B',10);
    $pdf->Cell(10,7,$nombre_cliente);
    $pdf->setXY(110,28);
    $pdf->SetFont('Arial','',10);
    $pdf->Cell(10,7,$direccion_cliente);
    
    $pdf->setXY(10,33);
    $pdf->SetFont('Arial','B',10);
    $pdf->Cell(2,7,'RUC : ');
    $pdf->setXY(22.5,33);
    $pdf->SetFont('Arial','',10);
    $pdf->Cell(2,7,$numero_cedula_c);
    
    $pdf->setXY(48,33);
    $pdf->SetFont('Arial','B',10);
    $pdf->Cell(2,7,'TELEFONO : ');
    $pdf->SetFont('Arial','',10);
    $pdf->setXY(70,33);
    $pdf->Cell(2,7,$telefono_cliente);



    //$pdf->Line(210,60,10,60);
    $pdf->Ln(10);


    $pdf->SetFillColor(172,172,172);
    $pdf->Cell(23,5,'Cant.',1,0,'L',1);
    $pdf->Cell(85,5,'Producto',1,0,'L',1);
    $pdf->Cell(23,5,'Precio',1,0,'C',1);
    $pdf->Cell(23,5,'Exento',1,0,'C',1);
    $pdf->Cell(23,5,'Descuento',1,0,'C',1);
    $pdf->Cell(23,5,'Total',1,0,'C',1);
    $pdf->SetFillColor(255,255,255);
    $pdf->Ln(5);

    $pdf->SetWidths(array(23,85,23,23,23,23));

    if (is_array($detalle) || is_object($detalle))
    {
        foreach ($detalle as $row => $column) {
         $pdf->SetAligns('C');
         $pdf->setX(10);
        if($column['nombre_producto'] == null){
            $pdf->Row(array($column["cantidad"],$column["nombre_producto"],$column["precio_unitario"],$column["exento"],
            $column["descuento"],$column["importe"]));
          } else {
            $pdf->Row(array($column["cantidad"],$column["nombre_producto"],$column["precio_unitario"],$column["exento"],
            $column["descuento"],$column["importe"]));
          }
         $get_Y = $pdf->GetY();
      }



 $pdf->Text(11,$get_Y + 39,'GRACIAS POR SU COMPRA');
      $pdf->SetFont('Arial','B',12);
      $pdf->Cell(144,35,'',1,0,'C',1);
      $pdf->Text(60,$get_Y + 5,'SON');
      $pdf->SetFont('Arial','',12);
      $pdf->Text(15,$get_Y + 10,$sonletras);
      $pdf->setX(154);
      $pdf->SetFillColor(172,172,172);
      $pdf->SetFont('Arial','B',8.5);
      $pdf->Cell(33,5,'SUMAS',1,0,'R',1);
      $pdf->SetFont('Arial','',8.5);
      $pdf->SetFillColor(255,255,255);
      $pdf->Cell(23,5,$sumas,1,0,'C',1);
      $pdf->Ln(5);
      $pdf->setX(154);
      $pdf->SetFillColor(172,172,172);
      $pdf->SetFont('Arial','B',8.5);
      $pdf->Cell(33,5,'IVA',1,0,'R',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->SetFont('Arial','',8.5);
      $pdf->Cell(23,5,$iva,1,0,'C',1);
      $pdf->Ln(5);
      $pdf->setX(154);
      $pdf->SetFillColor(172,172,172);
      $pdf->SetFont('Arial','B',8.5);
      $pdf->Cell(33,5,'SUBTOTAL',1,0,'R',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->SetFont('Arial','',8.5);
      $pdf->Cell(23,5,$subtotal,1,0,'C',1);
      $pdf->Ln(5);
      $pdf->setX(154);
      $pdf->SetFillColor(172,172,172);
      $pdf->SetFont('Arial','B',8.5);
      $pdf->Cell(33,5,'RETENCION',1,0,'R',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->SetFont('Arial','',8.5);
      $pdf->Cell(23,5,$retenido,1,0,'C',1);
      $pdf->Ln(5);
      $pdf->setX(154);
      $pdf->SetFillColor(172,172,172);
      $pdf->SetFont('Arial','B',8.5);
      $pdf->Cell(33,5,'TOTAL EXENTO',1,0,'R',1);
      $pdf->SetFont('Arial','',8.5);
      $pdf->SetFillColor(255,255,255);
      $pdf->Cell(23,5,$exento,1,0,'C',1);
      $pdf->Ln(5);
      $pdf->setX(154);
      $pdf->SetFillColor(172,172,172);
      $pdf->SetFont('Arial','B',8.5);
      $pdf->Cell(33,5,'TOTAL DESCUENTO',1,0,'R',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->SetFont('Arial','',8.5);
      $pdf->Cell(23,5,$descuento,1,0,'C',1);
      $pdf->Ln(5);
      $pdf->setX(154);
      $pdf->SetFillColor(172,172,172);
      $pdf->SetFont('Arial','B',8.5);
      $pdf->Cell(33,5,'TOTAL PAGAR',1,0,'R',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->SetFont('Arial','',8.5);
      $pdf->Cell(23,5,$total,1,0,'C',1);


*/

    }


      $pdf->Output('I','Factura_'.$numero_comprobante.'.pdf');

  } catch (Exception $e) {

    $pdf->Text(22.8, 5, 'ERROR AL IMPRIMIR COTIZACION');
    $pdf->Output('I','COTIZACION_ERROR.pdf',true);

  }

 ?>
