<?php

	require_once('Conexion.php');

	class CreditoProveedorModel extends Conexion
	{

		public function Imprimir_Ticket_Abono_Proveedor($idabono)
		{
			$dbconec = Conexion::Conectar();

			try
			{
				$query = "CALL sp_imprimir_ticket_abono_proveedor(:idabono);";
				$stmt = $dbconec->prepare($query);
				$stmt->bindParam(":idabono",$idabono);
				$stmt->execute();
				$count = $stmt->rowCount();

				if($count > 0)
				{
					return $stmt;
				}


				$dbconec = null;
			} catch (Exception $e) {

				echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
			}
		}


		public function Listar_Creditos_Proveedor($criterio)
		{
			$dbconec = Conexion::Conectar();

			try
			{
				$query = "CALL sp_view_creditos_proveedor(:criterio);";
				$stmt = $dbconec->prepare($query);
				$stmt->bindParam(":criterio",$criterio);
				$stmt->execute();
				$count = $stmt->rowCount();

				if($count > 0)
				{
					return $stmt->fetchAll();
				}


				$dbconec = null;
			} catch (Exception $e) {

				echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
			}
		}

		public function Listar_Creditos_Espc_Proveedor($criterio)
		{
			$dbconec = Conexion::Conectar();

			try
			{
				$query = "CALL sp_view_creditos_espc_proveedor(:criterio);";
				$stmt = $dbconec->prepare($query);
				$stmt->bindParam(":criterio",$criterio);
				$stmt->execute();
				$count = $stmt->rowCount();

				if($count > 0)
				{
					return $stmt->fetchAll();
				}


				$dbconec = null;
			} catch (Exception $e) {

				echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
			}
		}


    public function Listar_Abonos_Credito_Proveedor($criterio)
    {
      $dbconec = Conexion::Conectar();

      try
      {
        $query = "CALL sp_view_abonos_proveedor(:criterio);";
        $stmt = $dbconec->prepare($query);
        $stmt->bindParam(":criterio",$criterio);
        $stmt->execute();
        $count = $stmt->rowCount();

        if($count > 0)
        {
          return $stmt->fetchAll();
        }


        $dbconec = null;
      } catch (Exception $e) {

        echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
      }
    }

		public function Reporte_Abonos_Proveedor($fecha,$fecha2)
		{
			$dbconec = Conexion::Conectar();

			try
			{
				$query = "CALL sp_view_total_abonos_proveedor_fechas(:fecha,:fecha2);";
				$stmt = $dbconec->prepare($query);
				$stmt->bindParam(":fecha",$fecha);
				$stmt->bindParam(":fecha2",$fecha2);
				$stmt->execute();
				$count = $stmt->rowCount();

				if($count > 0)
				{
					return $stmt->fetchAll();
				}


				$dbconec = null;
			} catch (Exception $e) {

				echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
			}
		}

    public function Listar_Abonos_Proveedor_All()
    {
      $dbconec = Conexion::Conectar();

      try
      {
        $query = "CALL sp_view_all_abonos_proveedor();";
        $stmt = $dbconec->prepare($query);
        $stmt->execute();
        $count = $stmt->rowCount();

        if($count > 0)
        {
          return $stmt->fetchAll();
        }


        $dbconec = null;
      } catch (Exception $e) {

        echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
      }
    }

		public function Listar_Detalle($idcompra)
		{
			$dbconec = Conexion::Conectar();

			try
			{
				$query = "CALL sp_view_detallecompra(:idcompra);";
				$stmt = $dbconec->prepare($query);
				$stmt->bindParam(":idcompra",$idcompra);
				$stmt->execute();
				$count = $stmt->rowCount();

				if($count > 0)
				{
					return $stmt->fetchAll();
				}


				$dbconec = null;
			} catch (Exception $e) {

				echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
			}
		}

		public function Listar_Info($idcompra)
		{
			$dbconec = Conexion::Conectar();

			try
			{
				$query = "CALL sp_view_compra(:idcompra);";
				$stmt = $dbconec->prepare($query);
				$stmt->bindParam(":idcompra",$idcompra);
				$stmt->execute();
				$count = $stmt->rowCount();

				if($count > 0)
				{
					return $stmt->fetchAll();
				}


				$dbconec = null;
			} catch (Exception $e) {

				echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
			}
		}

    public function Ver_Restante_Proveedor($idcredito){

      $dbconec = Conexion::Conectar();
      try {

        $query = "CALL sp_view_monto_credito_proveedor(:idcredito)";
        $stmt->bindParam(":idcredito",$idcredito);
        $stmt = $dbconec->prepare($query);
        $stmt->execute();
        $Data = array();

        while($row=$stmt->fetch(PDO::FETCH_ASSOC)){
            $Data[] = $row;
        }

        // header('Content-type: application/json');
         echo json_encode($Data);

      } catch (Exception $e) {

        echo "Error al cargar el listado";
      }

    }


    		public function Count_Creditos_Proveedor()
    		{
    			$dbconec = Conexion::Conectar();

    			try
    			{
    				$query = "CALL sp_count_creditos_proveedor();";
    				$stmt = $dbconec->prepare($query);
    				$stmt->execute();
    				$count = $stmt->rowCount();

    				if($count > 0)
    				{
    					return $stmt->fetchAll();
    				}


    				$dbconec = null;
    			} catch (Exception $e) {

    				echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
    			}
    		}




    public function Editar_Credito_Proveedor($id,$nombre,$fecha,$monto,$abonado,$restante,$estado)
    {
      $dbconec = Conexion::Conectar();
      try
      {
        $query = "CALL sp_update_credito_proveedor(:id,:nombre,:fecha,:monto,:abonado,:restante,:estado);";
        $stmt = $dbconec->prepare($query);
				$stmt->bindParam(":id",$id);
        $stmt->bindParam(":nombre",$nombre);
        $stmt->bindParam(":fecha",$fecha);
        $stmt->bindParam(":monto",$monto);
        $stmt->bindParam(":abonado",$abonado);
        $stmt->bindParam(":restante",$restante);
        $stmt->bindParam(":estado",$estado);


        if($stmt->execute())
        {

          $data = "Validado";
            echo json_encode($data);

        } else {

          $data = "Error";
            echo json_encode($data);
        }
        $dbconec = null;
      } catch (Exception $e) {
        $data = "Error";
        echo json_encode($data);

      }

    }

    public function Insertar_Abono_Proveedor($idcredito, $monto, $idusuario)
    {
      $dbconec = Conexion::Conectar();
      try
      {
        $query = "CALL sp_insert_abono_proveedor(:idcredito, :monto, :idusuario)";
        $stmt = $dbconec->prepare($query);
        $stmt->bindParam(":idcredito",$idcredito);
        $stmt->bindParam(":monto",$monto);
				$stmt->bindParam(":idusuario",$idusuario);

        if($stmt->execute())
        {
          $count = $stmt->rowCount();
          if($count == 0){
            $data = "Duplicado";
              echo json_encode($data);
          } else {
            $data = "Validado";
              echo json_encode($data);
          }
        } else {

          $data = "Error";
            echo json_encode($data);
        }
        $dbconec = null;
      } catch (Exception $e) {
        $data = "Error";
        echo json_encode($data);

      }

    }

    public function Editar_Abono_Proveedor($idabono,$fecha_abono,$monto_abono)
    {
      $dbconec = Conexion::Conectar();
      try
      {
        $query = "CALL sp_update_abono_proveedor(:idabono,:fecha_abono,:monto_abono);";
        $stmt = $dbconec->prepare($query);
        $stmt->bindParam(":idabono",$idabono);
        $stmt->bindParam(":fecha_abono",$fecha_abono);
        $stmt->bindParam(":monto_abono",$monto_abono);

        if($stmt->execute())
        {

          $data = "Validado";
            echo json_encode($data);

        } else {

          $data = "Error";
            echo json_encode($data);
        }
        $dbconec = null;
      } catch (Exception $e) {
        $data = "Error";
        echo json_encode($data);

      }

    }


		public function Borrar_Abono_Proveedor($idabono)
		{
			$dbconec = Conexion::Conectar();
			$response = array();
			try
			{
				$query = "CALL sp_delete_abono_proveedor(:idabono);";
				$stmt = $dbconec->prepare($query);
				$stmt->bindParam(":idabono",$idabono);

				if($stmt->execute())
				{
					$response['status']  = 'success';
					$response['message'] = 'Abono eliminado del listado Correctamente!';
				} else {

					$response['status']  = 'error';
					$response['message'] = 'No pudimos borrar el Abono!';
				}
				echo json_encode($response);
				$dbconec = null;
			} catch (Exception $e) {
				$response['status']  = 'error';
				$response['message'] = 'Error de Ejecucion';
				echo json_encode($response);

			}

		}


				public function Monto_Maximo_Proveedor($idcredito)
				{
					$dbconec = Conexion::Conectar();

					try
					{
						$query = "CALL sp_view_monto_credito_proveedor(:idcredito);";
						$stmt = $dbconec->prepare($query);
						$stmt->bindParam(":idcredito",$idcredito);
						$stmt->execute();
						$count = $stmt->rowCount();
						$Data = array();
						if($count > 0)
						{
							while($row=$stmt->fetch(PDO::FETCH_ASSOC)){
				  				$Data[] = $row;
							}
							echo json_encode($Data);
						}


						$dbconec = null;
					} catch (Exception $e) {
						//echo $e;
						echo '<span class="label label-danger label-block">ERROR AL CARGAR LOS DATOS, PRESIONE F5</span>';
					}
				}

	}


 ?>
