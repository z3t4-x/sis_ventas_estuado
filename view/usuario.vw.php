<?php

	$objUsuario =  new Usuario();
	if($tipo_usuario==1){
?>

			<!-- Basic initialization -->
			<div class="panel panel-flat">
				<div class="breadcrumb-line">
					<ul class="breadcrumb">
						<li><a href="?View=Inicio"><i class="icon-home2 position-left"></i> Inicio</a></li>
						<li><a href="javascript:;">Usuarios</a></li>
						<li class="active">Usuarios del Sistema</li>
					</ul>
				</div>
					<div class="panel-heading">
						<h5 class="panel-title">Usuarios del Sistema</h5>

						<div class="heading-elements">
							<button type="button" class="btn btn-primary heading-btn"
							onclick="newUsuario()">
							<i class="icon-database-add"></i> Agregar Nuevo/a</button>
						</div>
					</div>
					<div class="panel-body">
					</div>
					<div id="reload-div">
					<table class="table datatable-basic table-xxs table-hover">
						<thead>
							<tr>
								<th>No</th>
								<th>Usuario</th>
								<th>Tipo de Usuario</th>
								<th>Empleado</th>
								<th>Estado</th>
								<th class="text-center">Opciones</th>
							</tr>
						</thead>

						<tbody>

						  <?php
								$filas = $objUsuario->Listar_Usuarios();
								if (is_array($filas) || is_object($filas))
								{
								foreach ($filas as $row => $column)
								{

								?>
									<tr>
										<td><?php print($column['idusuario']); ?></td>
					                	<td><?php print($column['usuario']); ?></td>
					            		<td><?php if($column['tipo_usuario'] == '1')
					                		echo '<span class="label label-warning label-rounded"><span
					                		class="text-bold">ADMINISTRADOR</span></span>';
					                		else
					                		echo '<span class="label label-info label-rounded">
					                		<span class="text-bold">CAJA</span></span>'
						                ?></td>
						                <td><?php print($column['nombre_empleado'].' '.$column['apellido_empleado']); ?></td>
					                	<td><?php if($column['estado'] == '1')
					                		echo '<span class="label label-success label-rounded"><span
					                		class="text-bold">ACTIVO</span></span>';
					                		else
					                		echo '<span class="label label-default label-rounded">
					                	<span
					                	    class="text-bold">INACTIVO</span></span>'
						                ?></td>
					                	<td class="text-center">
										<ul class="icons-list">
											<li class="dropdown">
												<a href="#" class="dropdown-toggle" data-toggle="dropdown">
													<i class="icon-menu9"></i>
												</a>

												<ul class="dropdown-menu dropdown-menu-right">
													<li><a
													href="javascript:;" data-toggle="modal" data-target="#modal_iconified"
													onclick="openUsuario('editar',
								                     '<?php print($column["idusuario"]); ?>',
								                     '<?php print($column["usuario"]); ?>',
								                     '<?php print($column["contrasena"]); ?>',
								                     '<?php print($column["tipo_usuario"]); ?>',
								                     '<?php print($column["estado"]); ?>',
								                     '<?php print($column["idempleado"]); ?>')">
												   <i class="icon-pencil6">
											       </i> Editar</a></li>
													<li><a
													href="javascript:;" data-toggle="modal" data-target="#modal_iconified"
													onclick="openUsuario('ver',
								                     '<?php print($column["idusuario"]); ?>',
								                     '<?php print($column["usuario"]); ?>',
								                     '<?php print($column["contrasena"]); ?>',
								                     '<?php print($column["tipo_usuario"]); ?>',
								                     '<?php print($column["estado"]); ?>',
								                     '<?php print($column["idempleado"]); ?>')">
													<i class=" icon-eye8">
													</i> Ver</a></li>
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
				</div>

			<!-- Iconified modal -->
				<div id="modal_iconified" class="modal fade">
					<div class="modal-dialog">
						<div class="modal-content">
							<div class="modal-header">
								<button type="button" class="close" data-dismiss="modal">&times;</button>
								<h5 class="modal-title"><i class="icon-pencil7"></i> &nbsp; <span class="title-form"></span></h5>
							</div>

					        <form role="form" autocomplete="off" class="form-validate-jquery" id="frmModal">
								<div class="modal-body" id="modal-container">

								<div class="alert alert-info alert-styled-left text-blue-800 content-group">
						                <span class="text-semibold">Estimado usuario</span>
						                Los campos remarcados con <span class="text-danger"> * </span> son necesarios.
						                <button type="button" class="close" data-dismiss="alert">×</button>
						                <input type="hidden" id="txtID" name="txtID" class="form-control" value="">
                                      	<input type="hidden" id="txtProceso" name="txtProceso" class="form-control" value="">
						           </div>

									<div class="form-group">
										<div class="row">
											<div class="col-sm-12">
												<label>Empleado  <span class="text-danger">*</span></label>
												<select  data-placeholder="..." id="cbEmpleado" name="cbEmpleado"
													class="select-search" style="text-transform:uppercase;"
				                            		onkeyup="javascript:this.value=this.value.toUpperCase();">
				                            			 <?php
															$filas = $objUsuario->Listar_Empleados();
															if (is_array($filas) || is_object($filas))
															{
															foreach ($filas as $row => $column)
															{
															?>
																<option value="<?php print ($column["idempleado"])?>">
																<?php print ($column["nombre_empleado"].' '.$column["apellido_empleado"])?>
																</option>
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
												<label>Usuario <span class="text-danger">*</span></label>
												<input type="text" id="txtUser" name="txtUser" placeholder="EJ. ABEL20"
												class="form-control">
											</div>

											<div class="col-sm-6">
												<label>Password <span class="text-danger">*</span></label>
												<input type="password" id="txtPassword" name="txtPassword"
												class="form-control" placeholder="ESCRIBA EL PASSWORD DEL USUARIO">
											</div>

										</div>
									</div>


									<div class="form-group">
										<div class="row">
											<div class="col-sm-6">
												<label>Tipo Usuario  <span class="text-danger">*</span></label>
												<select  data-placeholder="..." id="cbTipo" name="cbTipo"
													class="select-search" style="text-transform:uppercase;"
				                            		onkeyup="javascript:this.value=this.value.toUpperCase();">
				                            			<option value="1">ADMINISTRADOR</option>
				                            			<option value="2">CAJERO/A</option>
												</select>
											</div>
										</div>
									</div>


									<div class="form-group">
										<div class="row">
											<div class="col-sm-8">
												<div class="checkbox checkbox-switchery switchery-sm">
													<label>
													<input type="checkbox" id="chkEstado" name="chkEstado"
													 class="switchery" checked="checked" >
													 <span id="lblchk">VIGENTE</span>
												   </label>
												</div>
											</div>
										</div>
									</div>


								</div>

								<div class="modal-footer">
									<button id="btnGuardar" type="submit" class="btn btn-primary">Guardar</button>
									<button id="btnEditar" type="submit" class="btn btn-warning">Editar</button>
									<button  type="reset" class="btn btn-default" id="reset"
									class="btn btn-link" data-dismiss="modal">Cerrar</button>
								</div>
							</form>
						</div>
					</div>
				</div>
				<!-- /iconified modal -->
				<?php include('./includes/footer.inc.php'); ?>
			</div>
			<!-- /content area -->
		</div>
		<!-- /main content -->
	</div>
	<!-- /page content -->
</div>
<!-- /page container -->
</body>
</html>
<script type="text/javascript" src="web/custom-js/usuario.js"></script>
<?php } else { ?>

	<div class="panel-body">
		<div class="row">
			<div class="col-md-12">

				<!-- Widget with rounded icon -->
				<div class="panel">
					<div class="panel-body text-center">
						<div class="icon-object border-danger-400 text-primary-400"><i class="icon-lock5 icon-3x text-danger-400"></i>
						</div>
						<h2 class="no-margin text-semibold"> SU USUARIO NO POSEE PERMISOS SUFICIENTES </h2>
						<span class="text-uppercase text-size-mini text-muted">Su usuario no posee los permisos respectivos
						para poder accesar a este modulo. Lo invitamos a dar click </span> <a href="./?View=Inicio">AQUI</a> <br><br>

					</div>
				</div>
				<!-- /widget with rounded icon -->
			</div>
		</div>

<?php } ?>
