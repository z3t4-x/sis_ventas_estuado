<?php
session_start();
require('fpdf/fpdf.php');
date_default_timezone_set("America/Lima");

class PDF extends FPDF
{
    // Page header
    function Header()
    {
        if ($this->page == 1)
        {
            // Logo
            //  $this->Image('logo.png',10,6,30);
            // Arial bold 15
            $this->SetFont('Arial','B',15);
            // Move to the right
            //$this->Cell(98);
            // Title
            $this->Cell(190,10,'ARQUEO DE CAJA',0,0,'C');

            // Line break
            $this->Ln(20);
        }
    }


// Page footer
    function Footer()
    {
        // Position at 1.5 cm from bottom
        $this->SetY(-15);
        // Arial italic 8
        $this->SetFont('Arial','I',8);
        // Page number
        $this->Cell(160,10,'Pagina '.$this->PageNo().'/{nb}',0,0,'L');
        $this->Cell(43.2,10,date('d/m/Y H:i:s'),0,0,'C');
    }
}

    function __autoload($className){
            $model = "../model/". $className ."_model.php";
            $controller = "../controller/". $className ."_controller.php";

           require_once($model);
           require_once($controller);
    }

    try {

      $now = new DateTime();
      $now = $now->format('YYYY-mm-dd');
      $fecha = isset($_GET['fecha']) ? $_GET['fecha'] : $now;
      $idcaja = $_GET['idcaja'];
      
      $objCaja =  new Caja();
    	$objParametro = new Parametro();

    	$caja = $objCaja->Listar_Datos_Fecha($fecha,$idcaja);
    //	$totales = $objCaja->Listar_Movimientos_Fecha($fecha,$idcaja);
    
     	$movimientos = $objCaja->Listar_Movimientos_Detalle_Fecha($fecha,$idcaja);
    	
      $monedas = $objParametro->Ver_Moneda_Simbolo();

      // Obtener datos de la caja

      if (is_array($caja) || is_object($caja)){
          foreach ($caja as $row => $column) {
            $fecha_apertura = $column['fecha_apertura'];
            $fecha_cierre = $column['fecha_cierre'];
            $monto_apertura = $column['monto_apertura'];
          }
      }

      $pdf = new PDF('P','mm','A4');
      $pdf->AliasNbPages();
      $pdf->AddPage();
      $pdf->SetFont('Arial','',11);
      $pdf->SetFillColor(200,200,200);

      // Mostrar Datos de Caja
      $pdf->Cell(60,7,'Interin',1,0,'C',1);
      $pdf->setX(80);
      $pdf->Cell(50,7,'Cajero',1,0,'C',1);
      $pdf->setX(140);
      $pdf->Cell(60,7,'Informacion de la Caja',1,0,'C',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->ln();

      $pdf->Cell(20,7,'Desde:',0,0,'L',1);
      $pdf->Cell(40,7,$fecha_apertura,0,0,'L',1);

      $pdf->setX(80);
      $pdf->Cell(20,7,'Nombres:',0,0,'L',1);
      $pdf->Cell(40,7,$_SESSION['user_empleado'],0,0,'L',1);

      $pdf->setX(140);
      $pdf->Cell(40,7,'Cierre de caja numero ',0,0,'L',1);
      $pdf->Cell(40,7,$idcaja,0,0,'L',1);

      $pdf->ln();
      $pdf->Cell(20,7,'Hasta:',0,0,'L',1);
      $pdf->Cell(40,7,$fecha_cierre,0,0,'L',1);

      $pdf->setX(80);
      $pdf->Cell(20,7,'Apellidos:',0,0,'L',1);
      $pdf->Cell(40,7,$_SESSION['apellido_empleado'],0,0,'L',1);

      $pdf->setX(140);
      $pdf->Cell(40,7,'Monto de Apertura:',0,0,'L',1);
      $pdf->Cell(20,7,$monto_apertura,0,0,'L',1);

      $pdf->line(10,52,70,52);
      $pdf->line(10,30,10,52);
      $pdf->line(70,30,70,52);

      $pdf->line(80,52,130,52);
      $pdf->line(80,30,80,52);
      $pdf->line(130,30,130,52);

      $pdf->line(140,52,200,52);
      $pdf->line(140,30,140,52);
      $pdf->line(200,30,200,52);
      $pdf->ln(15);

      // Egresos
      $pdf->SetFillColor(200,200,200);
      $pdf->Cell(190,7,'Egresos',1,0,'C',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->ln();
      $pdf->SetFillColor(230,230,230);
      $pdf->Cell(140,7,'Concepto',1,0,'C',1);
      $pdf->Cell(50,7,'Monto',1,0,'C',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->ln();

      $total_egresos = 0;
      $id_caja = 0;
      if (is_array($movimientos) || is_object($movimientos)){
          foreach ($movimientos as $row => $column) {
            if ($column['tipo_movimiento'] > 2) {
              $pdf->Cell(140,7,$column['descripcion_movimiento'],1,0,'L',1);
              $pdf->Cell(50,7,$column['monto_movimiento'],1,0,'R',1);
              $pdf->ln();
              $id_caja = $column['idcaja'];
              $total_egresos = $total_egresos + $column['monto_movimiento'];
            }
          }
      }
      $pdf->SetFillColor(230,230,230);
      $pdf->Cell(140,7,'Total Egresos',1,0,'L',1);
      $pdf->Cell(50,7,$total_egresos,1,0,'R',1);
      $pdf->SetFillColor(255,255,255);

      // Ingresos
      $pdf->ln(10);
      $pdf->SetFillColor(200,200,200);
      $pdf->Cell(190,7,'Ingresos',1,0,'C',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->ln();
      $pdf->Cell(140,7,'Concepto',1,0,'C',1);
      $pdf->Cell(50,7,'Monto',1,0,'C',1);
      $pdf->ln();

      $total_ingresos_efectivo = 0;
      $total_ingresos = 0;

      if (is_array($movimientos) || is_object($movimientos)){
          foreach ($movimientos as $row => $column) {
            if ($column['tipo_movimiento'] <= 2) {
              $pdf->Cell(140,7,$column['descripcion_movimiento'],1,0,'L',1);
              $pdf->Cell(50,7,number_format($column['monto_movimiento']+$column['monto_movimiento_tarjeta'], 2),1,0,'R',1);
              $pdf->ln();
              $id_caja = $column['idcaja'];
              $total_ingresos = $total_ingresos + $column['monto_movimiento']+$column['monto_movimiento_tarjeta'];
              $total_ingresos_efectivo = $total_ingresos_efectivo+ $column['monto_movimiento'];
            }
          }
      }

    
      $pdf->Cell(140,7,'Total Ingresos Tarjeta/Yape',1,0,'L',1);
      $pdf->Cell(50,7,$total_ingresos - $total_ingresos_efectivo,1,0,'R',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->ln();
      $pdf->Cell(140,7,'Total Ingresos Efectivo',1,0,'L',1);
      $pdf->Cell(50,7,$total_ingresos_efectivo,1,0,'R',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->ln();
      $pdf->SetFillColor(230,230,230);
      $pdf->Cell(140,7,'Total Ingresos (Ingreso Tarjeta/Yape + Efectivo)',1,0,'L',1);
      $pdf->Cell(50,7,$total_ingresos,1,0,'R',1);
      $pdf->SetFillColor(255,255,255);
      $pdf->ln(15);

      $pdf->Cell(140,7,'Saldo de Caja (Total Ingresos Efectivo - Total Egresos )',1,0,'L',1);
      $pdf->Cell(50,7,$total_ingresos_efectivo - $total_egresos,1,0,'R',1);
      $pdf->ln();
      $pdf->Cell(140,7,'Monto de Cierre (Monto Apertura + Total Ingresos Efectivo - Total Egresos )',1,0,'L',1);
      $pdf->Cell(50,7,$monto_apertura + ($total_ingresos_efectivo - $total_egresos),1,0,'R',1);
      $pdf->ln(20);

      $y = $pdf->getY();
      $pdf->line(10,$y,200,$y);
      $pdf->line(200,$y,200,$y+30);
      $pdf->line(10,$y+30,200,$y+30);
      $pdf->line(10,$y,10,$y+30);

      $pdf->line(30,$y+20,90,$y+20);
      $pdf->line(120,$y+20,180,$y+20);
      $pdf->text(55,$y + 25,'Firma');
      $pdf->text(125,$y + 25,'Aclaracion y Nro Documento');
     // $pdf->text(182,42,'000'.$id_caja);

      $pdf->Output('I','Reporte_Caja_'.$fecha.'.pdf');
    } catch (\Exception $e) {
      $pdf = new PDF();
      $pdf->AliasNbPages();
      $pdf->AddPage('L','Letter');
      $pdf->Text(50,50,'ERROR AL IMPRIMIR');
      $pdf->SetFont('Times','',12);
      $pdf->Output();
    }


    // Obtener movimientos


?>
