<?php 

	function __autoload($className){
		$model = "../../model/". $className ."_model.php";
		$controller = "../../controller/". $className ."_controller.php";
	
		require_once($model);
		require_once($controller);
	}

	$objInventario =  new Inventario();

	$mes = isset($_GET['mes']) ? $_GET['mes'] : '';

	if($mes!='reload')
	{
		$mes = DateTime::createFromFormat('m/Y', $mes)->format('Y-m');

	} else {

		$mes = '';
	}
	
?>


	   <div class="panel panel-body">
 		
	 	<table class="table datatable-basic table-borderless table-hover table-xs">
						<thead>
							<tr>
								<th>Fecha Ingreso</th>
								<th>Descripción</th>
								<th>Código</th>
								<th>Nombre</th>
								<th>Cantidad</th>
								<th>Costo total</th>
								<th>Opciones</th>

							<!--	<th>SALDO INICIAL</th>
								<th>ENTRADAS</th>
								<th>SALIDAS</th>
								<th>SALDO</th>-->
							</tr>
						</thead>

				 	<tbody>
				         <?php 
								 $filas = $objInventario->Listar_Entradas($mes); 
								if (is_array($filas) || is_object($filas))
								{
								foreach ($filas as $row => $column) 
								{
								?>
							    	<tr>
							    	    <td><?php print($column['fecha_entrada']); ?></td> 
							    	    <td><?php print($column['descripcion_entrada']); ?></td> 
							    	    <td><?php print($column['codigo_barra']); ?></td>
							    	    <td><?php print($column['nombre_producto']); ?></td> 
					                	<td><?php print($column['cantidad_entrada']); ?></td> 
					                	<td><?php print($column['costo_total_entrada']); ?></td> 
                                    	<td class="text-center">
																			<ul class="icons-list">
																				<li class="dropdown">
																					<a href="#" class="dropdown-toggle" data-toggle="dropdown">
																						<i class="icon-menu9"></i>
																					</a>
																					<ul class="dropdown-menu dropdown-menu-right">

																					   <li><a id="delete_product"
																					   data-id="<?php print($column['idventa']); ?>"
																						href="javascript:void(0)">
																					   <i class="icon-cancel-circle2">
																				       </i> Anular</a></li>

																					   <li><a id="detail_pay"  data-toggle="modal" data-target="#modal_detalle" data-toggle="modal" data-target="#modal_detalle"
																					   data-id="<?php print($column['idventa']); ?>"
																						href="javascript:void(0)">
																					   <i class="icon-file-spreadsheet">
																				       </i> Ver Detalle</a></li>

																				       <li><a id="print_entradas"
																					   data-id="<?php print($column['idventa']); ?>"
																						 data-tipo="<?php print($tipo_comprobante); ?>"
																						href="javascript:void(0)">
																					   <i class="icon-typewriter">
																				       </i> Comprobante</a></li>

																					</ul>
																				</li>
																			</ul>
									    </td>
									    </tr>
								
								<?php  
								}
							}   
							?>
						</tbody> 
					</table>

		</div>
	<script type="text/javascript" src="web/custom-js/kardex.js"></script>