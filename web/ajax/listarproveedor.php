<?php

	function __autoload($className){
		$model = "../../model/". $className ."_model.php";
		$controller = "../../controller/". $className ."_controller.php";

		require_once($model);
		require_once($controller);
	}

	$objProveedor =  new Proveedor();
  $filas = $objProveedor->Listar_Proveedores();
  echo json_encode($filas);
 ?>
