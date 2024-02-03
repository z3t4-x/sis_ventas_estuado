<?php
require('fpdf/fpdf.php');

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
            $this->Cell(105);
            // Title
            $this->Cell(105,10,'REPORTE DE PRODUCTOS PERECEDEROS - ALMACENADOS',0,0,'C');

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

    $objProducto = new Perecedero();
    $listado = $objProducto->Listar_Perecederos(null,null);

try {
    // Instanciation of inherited class
    $pdf = new PDF('L','mm',array(216,330));
    $pdf->AliasNbPages();
    $pdf->AddPage();
    $pdf->SetFont('Arial','',11);
    $pdf->SetFillColor(255,255,255);
    $pdf->Cell(30,5,'Cod. Interno',0,0,'L',1);
    $pdf->Cell(30,5,'Cod. Barra',0,0,'L',1);
    $pdf->Cell(100,5,'Producto',0,0,'L',1);
    $pdf->Cell(40,5,'Marca',0,0,'L',1);
    $pdf->Cell(30,5,'Presentacion',0,0,'L',1);
    $pdf->Cell(25,5,'Vence',0,0,'C',1);
    $pdf->Cell(25,5,'Cant.',0,0,'C',1);
    $pdf->Cell(22,5,'Estado',0,0,'C',1);
    $pdf->Line(322,28,10,28);
    $pdf->Line(322,37,10,37);
    $pdf->Ln(9);
    $total = 0;

    if (is_array($listado) || is_object($listado))
    {
        foreach ($listado as $row => $column) {

        $fecha_vencimiento = $column["fecha_vencimiento"];
        if(is_null($fecha_vencimiento))
        {
        $envio_date = '';

        } else {

        $envio_date = DateTime::createFromFormat('Y-m-d',$fecha_vencimiento)->format('d/m/Y');
        }

        $estado = $column['estado_perecedero'];
        if($estado == '1')
        {
          $estado = 'VIGENTE';
        } else {
          $estado = 'VENCIDO';
        }

            $pdf->setX(9);
            $pdf->Cell(30,5,$column["codigo_interno"],0,0,'L',1);
            $pdf->Cell(30,5,$column["codigo_barra"],0,0,'L',1);
            $pdf->Cell(100,5,$column["nombre_producto"],0,0,'L',1);
            $pdf->Cell(40,5,$column["nombre_marca"],0,0,'L',1);
            $pdf->Cell(30,5,$column["siglas"],0,0,'L',1);
            $pdf->Cell(25,5,$envio_date,0,0,'C',1);
            $pdf->Cell(25,5,$column['cantidad_perecedero'],0,0,'C',1);
            $pdf->Cell(22,5,$estado,0,0,'C',1);
            $pdf->Ln(6);
            $get_Y = $pdf->GetY();
            $total = $total + 1 ;
        }

        $pdf->Line(322,$get_Y+1,10,$get_Y+1);
        $pdf->SetFont('Arial','B',11);
        $pdf->Text(10,$get_Y + 10,'TOTAL DE PRODUCTOS PERECEDEROS REGISTRADOS : '.number_format($total, 2, '.', ','));
    }


    $pdf->Output('I','Productos_Perecederos.pdf');



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
