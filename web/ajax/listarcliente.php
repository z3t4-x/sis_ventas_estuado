<?php

	function __autoload($className){
		$model = "../../model/". $className ."_model.php";
		$controller = "../../controller/". $className ."_controller.php";

		require_once($model);
		require_once($controller);
	}

	$objCliente =  new Cliente();
  $filas = $objCliente->Listar_Clientes();
  echo json_encode($filas);
 ?>
