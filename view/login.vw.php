	<script type="text/javascript" src="web/custom-js/login.js"></script>
		<!-- Form with validation -->
		<div class="login-box">
		<div class="login-logo">
		
		</div>
		
		<div class="login-box-body">
   		<div class="box box-widget widget-user">

   		<!-- Add the bg color to the header using any of the bg-* classes -->
            <div class="widget-user-header bg-aqua-active">
            </div>
            
            <div class="widget-user-image">
            <img class="img-circle" src="./web/assets/images/user.jpg" alt="User Avatar">
            </div>
            
            <br>

   			<p class="login-box-msg"></p>

		<form autocomplete="off" action="" class="form-validate">
			
		<div class="text-center">

		<h5 class="content-group">Bienvenido a Ferreteria La Cruz<small class="display-block">Iniciar Sesión</small></h5>
		</div>

		<div class="form-group mb-3">
		<div class="input-group input-group-alternative">
		<div class="input-group-prepend">
        <span class="input-group-text"><i class="ni ni-email-83"></i></span>
        </div>
		
		<input type="text" class="form-control" id="username" placeholder="Usuario" name="username" required="required">
		<div class="form-control-feedback">
		<i class="icon-user text-muted"></i>
		</div>

		<span id="error-user" class="label label-danger label-block"></span>
		</div>
		</div>

		<div class="form-group">
        <div class="input-group input-group-alternative">
        <div class="input-group-prepend">
        <span class="input-group-text"><i class="ni ni-lock-circle-open"></i></span>
        </div>				
		<input type="password" class="form-control" id="password" placeholder="Password" name="password" required="required">
		<div class="form-control-feedback">
		<i class="icon-lock2 text-muted"></i>
		</div>
		</div></div>

		<div class="form-group">
		<button type="submit" class="btn bg-blue btn-block">Ingresar al Sistema <i class="icon-lock5"></i></button>
		</div>

		</form>
		</div>
		</div>
		</div>
		<!-- /form with validation -->