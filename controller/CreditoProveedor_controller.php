<?php

	class CreditoProveedor {

		public function Imprimir_Ticket_Abono_Proveedor($idabono){

			$filas = CreditoProveedorModel::Imprimir_Ticket_Abono_Proveedor($idabono);
			return $filas;

		}

		public function Reporte_Abonos_Proveedor($fecha,$fecha2){

			$filas = CreditoProveedorModel::Reporte_Abonos_Proveedor($fecha,$fecha2);
			return $filas;

		}


		public function Listar_Creditos_Proveedor($idcredito){

			$filas = CreditoProveedorModel::Listar_Creditos_Proveedor($idcredito);
			return $filas;

		}

		public function Listar_Creditos_Espc_Proveedor($idcredito){

			$filas = CreditoProveedorModel::Listar_Creditos_Espc_Proveedor($idcredito);
			return $filas;

		}

		public function Listar_Abonos_Credito_Proveedor($idcredito){

			$filas = CreditoProveedorModel::Listar_Abonos_Credito_Proveedor($idcredito);
			return $filas;

		}

		public function Listar_Abonos_Proveedor_All(){

			$filas = CreditoProveedorModel::Listar_Abonos_Proveedor_All();
			return $filas;

		}

		public function Count_Creditos_Proveedor(){

			$filas = CreditoProveedorModel::Count_Creditos_Proveedor();
			return $filas;

		}

		public function Listar_Detalle($idcompra){

			$filas = CreditoProveedorModel::Listar_Detalle($idcompra);
			return $filas;

		}

		public function Listar_Info($idcompra){

			$filas = CreditoProveedorModel::Listar_Info($idcompra);
			return $filas;

		}

		public function Ver_Restante_Proveedor($idcredito){

			$filas = CreditoProveedorModel::Ver_Restante_Proveedor($idcredito);
			return $filas;

		}


		public function Borrar_Abono_Proveedor($idabono){

			$cmd = CreditoProveedorModel::Borrar_Abono_Proveedor($idabono);

		}


		public function Editar_Credito_Proveedor($id,$nombre,$fecha,$monto,$abonado,$restante,$estado){

			$cmd = CreditoProveedorModel::Editar_Credito_Proveedor($id,$nombre,$fecha,$monto,$abonado,$restante,$estado);

		}

		public function Insertar_Abono_Proveedor($idcredito, $monto, $idusuario){

			$cmd = CreditoProveedorModel::Insertar_Abono_Proveedor($idcredito, $monto, $idusuario);

		}

		public function Editar_Abono_Proveedor($idabono,$fecha_abono,$monto_abono){

			$cmd = CreditoProveedorModel::Editar_Abono_Proveedor($idabono,$fecha_abono,$monto_abono);

		}

		public function Monto_Maximo_Proveedor($idcredito){

			$filas = CreditoProveedorModel::Monto_Maximo_Proveedor($idcredito);
			return $filas;
		}


	}


 ?>
