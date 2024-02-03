<?php
require('fpdf/fpdf.php');

class PDF extends FPDF
{
    // Page header
    function Header()
    {
        if ($this->page == 1)
        {
             $fecha1 = isset($_GET['fecha1']) ? $_GET['fecha1'] : '';
             $fecha2 = isset($_GET['fecha2']) ? $_GET['fecha2'] : '';

            // Logo
            //  $this->Image('logo.png',10,6,30);
            // Arial bold 15
            $this->SetFont('Arial','B',15);
            // Move to the right
            $this->Cell(98);
            // Title
            $this->Cell(105,10,'TOTAL DE ABONOS REALIZADO ENTRE EL '.$fecha1.' Y '.$fecha2,0,0,'C');

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
        $this->Cell(275,10,'Pagina '.$this->PageNo().'/{nb}',0,0,'L');
        $this->Cell(43.2,10,date('d/m/Y H:i:s'),0,0,'C');
    }
}

    function __autoload($className){
            $model = "../model/". $className ."_model.php";
            $controller = "../controller/". $className ."_controller.php";

           require_once($model);
           require_once($controller);
    }

    $fecha1 = isset($_GET['fecha1']) ? $_GET['fecha1'] : '';
    $fecha2 = isset($_GET['fecha2']) ? $_GET['fecha2'] : '';


    $fecha1 = DateTime::createFromFormat('d/m/Y', $fecha1)->format('Y-m-d');
    $fecha2 = DateTime::createFromFormat('d/m/Y', $fecha2)->format('Y-m-d');

    $objCompra =  new Compra();
    $objCredito = New CreditoProveedor();
    $listado = $objCredito->Reporte_Abonos_Proveedor($fecha1,$fecha2);
    $parametros = $objCompra->Ver_Moneda_Reporte();

    foreach ($parametros as $row => $column) {

        $moneda = $column['CurrencyName'];

    }

    $fecha1 = DateTime::createFromFormat('Y-m-d', $fecha1)->format('d/m/Y');
    $fecha2 = DateTime::createFromFormat('Y-m-d', $fecha2)->format('d/m/Y');

try {
    // Instanciation of inherited class
    $pdf = new PDF('L','mm',array(216,330));
    $pdf->AliasNbPages();
    $pdf->AddPage();
    $pdf->SetFont('Arial','',11);
    $pdf->SetFillColor(255,255,255);
    $pdf->Cell(35,5,'Codigo Credito',0,0,'L',1);
    $pdf->Cell(120,5,'Credito',0,0,'L',1);
    $pdf->Cell(30,5,'Fecha Abono',0,0,'L',1);
    $pdf->Cell(30,5,'Monto Abonado',0,0,'C',1);
    $pdf->Line(322,28,10,28);
    $pdf->Line(322,37,10,37);
    $pdf->Ln(9);
    $total = 0;
    if (is_array($listado) || is_object($listado))
    {
        foreach ($listado as $row => $column) {

            $pdf->setX(9);
            $pdf->Cell(35,5,$column["codigo_credito"],0,0,'L',1);
            $pdf->Cell(120,5,$column["nombre_credito"],0,0,'L',1);
            $pdf->Cell(30,5,$column["fecha_abono"],0,0,'L',1);
            $pdf->Cell(30,5,$column["monto_abono"],0,0,'C',1);
            $total = $total + $column["monto_abono"];
            $pdf->Ln(6);
            $get_Y = $pdf->GetY();
        }

         $pdf->Line(322,$get_Y+1,10,$get_Y+1);
         $pdf->SetFont('Arial','B',11);
         $pdf->Text(10,$get_Y + 10,'TOTAL INGRESADO POR ABONOS : '.number_format($total, 2, '.', ','));
           $pdf->Text(10,$get_Y + 15,'PRECIOS EN : '.$moneda);
    }


    $pdf->Output('I','Total_Abonos_'.$fecha1.'_al_'.$fecha2.'.pdf');



} catch (Exception $e) {

    // Instanciation of inherited class
    $pdf = new PDF();
    $pdf->AliasNbPages();
    $pdf->AddPage('L','Letter');
    $pdf->Text(50,50,'ERROR AL IMPRIMIR');
    $pdf->SetFont('Times','',12);
    $pdf->Output();

}

?>
