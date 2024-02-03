<?php 
	session_start();
	$tipo_usuario = $_SESSION['user_tipo'];
	function __autoload($className){
		$model = "../../model/". $className ."_model.php";
		$controller = "../../controller/". $className ."_controller.php";
	
		require_once($model);
		require_once($controller);
	}

	$objInventario =  new Inventario();
	$objProducto = new Producto();

 ?>

	<div class="breadcrumb-line">
		<ul class="breadcrumb">
			<li><a href="?View=Inicio"><i class="icon-home2 position-left"></i> Inicio</a></li>
			<li><a href="javascript:;">Inventario</a></li>
			<li class="active">Entradas y Salidas de Productos</li>
		</ul> 
	  <div class="row">
		 <div class="breadcrumb col-lg-12">
				<div style="background-color: #FF5722;color: white;padding: 2px;font-size: 20px;
				text-align: center; text-transform: uppercase;font-weight: bold;width: 100%;">
					<span>
					resumen de saldos y movimientos de productos</span>
			    </div>
	   	  </div>
	  </div>
	</div>
	<br>
	 <div class="row">
		 <div class="col-sm-6 col-md-3">
		 	<form role="form" autocomplete="off" class="form-validate-jquery" id="frmSearch">
				<div class="form-group">
					<div class="row">
						<div class="col-sm-6">
							<label>Mes Inventario</label>
							<div class="input-group">
							<span class="input-group-addon"><i class="icon-calendar3"></i></span>
							<input type="text" id="txtMes" name="txtMes" placeholder=""
							 class="form-control input-sm" style="text-transform:uppercase;" 
	                		onkeyup="javascript:this.value=this.value.toUpperCase();">
	                		</div>
						</div>
						<div class="col-sm-4">
							<button style="margin-top: 27px;" id="btnGuardar" type="submit" class="btn btn-primary btn-sm"> 
							<i class="icon-search4"></i> Consultar</button>
						</div>
					</div>
				</div>
			  </form>
	   	  </div>
	  </div>

	  <div class="row">
		 <div class="col-md-12 col-lg-12">
			<!-- Basic initialization -->
			<div class="panel panel-flat">
				<div class="panel-heading">
					<h5 class="panel-title">INGRESO DE PRODUCTOS</h5>
					<div class="heading-elements">

					<?php  if($tipo_usuario == '1'){ ?>

						<div class="btn-group">
	                    	<button type="button" class="btn btn-danger dropdown-toggle" data-toggle="dropdown">
	                    	<i class="icon-printer2 position-left"></i> Imprimir Reporte 
	                    	<span class="caret"></span></button>
	                    	<ul class="dropdown-menu dropdown-menu-right">
								<li><a id="print_saldos" href="javascript:void(0)"
								><i class="icon-file-pdf"></i> Saldos y Movimientos</a></li>
								<li class="divider"></li>
								<li><a id="print_entradas" href="javascript:void(0)">
								<i class="icon-file-pdf"></i> Entradas del Mes</a></li>
								<li class="divider"></li>
								<li><a id="print_salidas" href="javascript:void(0)">
								<i class="icon-file-pdf"></i> Salidas del Mes</a></li>
							</ul>
						</div>

						<div class="btn-group">
	                    	<button type="button" class="btn btn-info dropdown-toggle" data-toggle="dropdown">
	                    	<i class="icon-pencil6 position-left"></i> Registrar Movimiento 
	                    	<span class="caret"></span></button>
	                    	<ul class="dropdown-menu dropdown-menu-right">
								<li><a data-toggle="modal" data-target="#modal_iconified" 
								 id="new_salida" href="javascript:void(0)">
								<i class="icon-point-left"></i> Registrar Salida por producto</a></li>
								<li class="divider"></li>
								<li><a data-toggle="modal" data-target="#modal_iconified" 
								id="new_entrada" href="javascript:void(0)">
								<i class="icon-point-right"></i> Registrar Entrada por producto</a></li>
								
							</ul>
						</div>
						
						<?php } else { ?>

						<div class="btn-group">
	                    	<button type="button" class="btn btn-danger dropdown-toggle" data-toggle="dropdown">
	                    	<i class="icon-printer2 position-left"></i> Imprimir Reporte 
	                    	<span class="caret"></span></button>
	                    	<ul class="dropdown-menu dropdown-menu-right">
								<li><a id="print_saldos" href="javascript:void(0)"
								><i class="icon-file-pdf"></i> Saldos y Movimientos</a></li>
								<li class="divider"></li>
								<li><a id="print_entradas" href="javascript:void(0)">
								<i class="icon-file-pdf"></i> Entradas del Mes</a></li>
								<li class="divider"></li>
								<li><a id="print_salidas" href="javascript:void(0)">
								<i class="icon-file-pdf"></i> Salidas del Mes</a></li>
							</ul>
						</div>

						<?php } ?>
					</div>
				</div>

				<div id="reload-div">
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
							</tr>
						</thead>

				 	<tbody>
				         <?php 
     							 $filas = $objInventario->Listar_Entradas(''); 
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
									    </tr>
								
								<?php  
								}
							}   
							?>
						</tbody> 
					</table>
					</div>
				</div>	
			 </div>
	   	  </div>
	   	  
	   	  
	   	  		 <div class="col-md-12 col-lg-12">
			<!-- Basic initialization -->
			<div class="panel panel-flat">
				<div class="panel-heading">
					<h5 class="panel-title">SALIDA DE PRODUCTOS</h5>
				</div>

				<div id="reload-div">
				   <div class="panel panel-body">
					<table class="table datatable-basic table-borderless table-hover table-xs">
						<thead>
							<tr>
								<th>Fecha Salida</th>
								<th>Descripción</th>
								<th>Código</th>
								<th>Nombre</th>
								<th>Cantidad</th>
								<th>Costo total</th>
							<!--	<th>Opciones</th>-->
							</tr>
						</thead>

				 	<tbody>
				         <?php 
							    $filas2 = $objInventario->Listar_Salidas(''); 
								if (is_array($filas2) || is_object($filas2))
								{
								foreach ($filas2 as $row => $column) 
								{
								?>
								         
								 
							    	<tr>
					                	<td><?php print($column['fecha_salida']); ?></td> 
					                	<td><?php print($column['descripcion_salida']); ?></td> 
							    	    <td><?php print($column['codigo_barra']); ?></td>
			                            <td><?php print($column['nombre_producto']); ?></td> 
					                	<td><?php print($column['cantidad_salida']); ?></td> 
					                	<td><?php print($column['costo_total_salida']); ?></td> 
					                </tr>
								
								<?php  
								}
							}   
							?>
						</tbody> 
					</table>
					</div>
				</div>	
			 </div>
	   	  </div>

	  </div>


	  <!-- Iconified modal -->
		<div id="modal_iconified" class="modal fade">
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-header">
						<button type="button" class="close" data-dismiss="modal">&times;</button>
						<h5 class="modal-title"><i class="icon-pencil7"></i> &nbsp; <span class="title-form"></span></h5>
					</div>

			        <form role="form" autocomplete="off" class="form-validate-jquery" id="frmMov">
						<div class="modal-body" id="modal-container">

						<div class="alert alert-info alert-styled-left text-blue-800 content-group">
				                <span class="text-semibold">Estimado usuario</span> 
				                Los campos remarcados con <span class="text-danger"> * </span> son necesarios.
				                <button type="button" class="close" data-dismiss="alert">×</button>
	                          	<input type="hidden" id="txtProceso" name="txtProceso" class="form-control" value="">
				        </div>
				        
						<div class="form-group">
						     
							<div class="row">
								
								
								<div class="col-sm-12">
								    
									<label>Producto <span class="text-danger"> * </span></label>
									<select  data-placeholder="..." id="cbProducto" name="cbProducto" 
										class="select-search" style="text-transform:uppercase;" 
	                            		onkeyup="javascript:this.value=this.value.toUpperCase();">
	                            			 <?php 
												$filas = $objProducto->Listar_Productos(); 
												if (is_array($filas) || is_object($filas))
												{
												foreach ($filas as $row => $column) 
												{
												?>
													<option value="<?php print ($column["idproducto"])?>">
													<?php print ($column["codigo_barra"].' - '.$column["nombre_producto"])?></option>
												<?php 
													}
												}
												 ?>
									</select>
								</div>
							</div>
						</div>


						<div class="form-group">
							<div class="row">
								<div class="col-sm-6">
									<label>Motivo <span class="text-danger"> * </span></label>
									<select  data-placeholder="..." id="cbMotivo" name="cbMotivo" 
										class="select-search" style="text-transform:uppercase;" 
	                            		onkeyup="javascript:this.value=this.value.toUpperCase();">
	                            		<option id="" value=""></option>
	                            		
	                            		<option id="IN-INI" value="POR INVENTARIO INICIAL">POR INVENTARIO INICIAL</option>
                            			<option  id="AJUSTE" value="POR AJUSTE DE INVENTARIO">POR AJUSTE DE INVENTARIO</option>
                            			<option id="AVERIA" value="POR AVERIA DE PRODUCTO">POR AVERIA DE PRODUCTO</option>
                            			<option id="PROMOCIONAL" 
                            			value="POR PROMOCIONAL DE PROVEEDOR">POR PROMOCIONAL DE PROVEEDOR</option>
                            			<option id="CANJE" value="POR CANJE DE PROVEEDOR">POR CANJE DE PROVEEDOR</option>
                            			<option value="POR MOVIENTO ENTRE LOCALES">POR MOVIENTO ENTRE LOCALES</option>

									</select>
								</div>

								<div class="col-sm-6">
									<label>Cantidad Movimiento</label>
										<input type="text" id="txtCant" name="txtCant" placeholder="0.00"
										class="touchspin-prefix" style="text-transform:uppercase;" 
	                            		 onkeyup="javascript:this.value=this.value.toUpperCase();">
								</div>

							</div>
						</div>

						</div>

						<div class="modal-footer">
							<button  type="reset" class="btn btn-default" id="reset" 
							class="btn btn-link" data-dismiss="modal">Cerrar</button>
							<button id="btnGuardar" type="submit" class="btn btn-primary">Guardar</button>
						</div>
					</form>
				</div>	
			</div>
		</div>
		<!-- /iconified modal -->
 
	
<script type="text/javascript" src="web/custom-js/kardex.js"></script>