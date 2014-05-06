<!DOCTYPE html>
<html>
<head>
   <title>Minerva</title>
   <meta charset="utf-8">
   <meta name="viewport" content="width=device-width, initial-scale=1.0">
   <meta name="description" content="">
   <meta name="author" content="">

   <link rel="icon" type="image/ico" href="/favicon.ico"/>
   <link href="css/bootstrap.min.css" rel="stylesheet">
   <link href="css/bootstrap-modifications.css" rel="stylesheet">
</head>
  
<body>

<!--Navbar-->

<div class="navbar navbar-default navbar-fixed-top">
   <div class="container">
      <div class="navbar-header">
         <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
         </button>
         <a class="navbar-brand" href="#"><b>MINERVA</b></a>
      </div>
      <div class="navbar-collapse collapse">
         <ul class="nav navbar-nav">
            <li><a href="index.php">Jobstatus</a></li>
            <li class="active"><a href="nodestatus.php">Nodestatus</a></li>
            <li><a href="lastjoboutput.php">Lastjoboutput</a></li>
         </ul>
      </div>
   </div>
</div>

<!--Content-->
<div class="container">
   <?php
   include 'config.php';
   $userName = str_replace('.u.hpc.mssm.edu', '', $_SERVER['SERVER_NAME']);
   echo "<a href=\"javascript:window.location.reload()\">Node status on: &nbsp; " . strftime('%c') . "</a>";
   echo "<pre>";
   if (preg_match('/([a-z]|[A-Z])+\d+/',$userName)){
      system("$minerva_queue_bin/nodestatus");
   }
   else{
      echo "Username not formatted correctly\n";
   }
   echo "</pre>";
   ?>
</div>

<!--Load javascript-->
<script src="js/jquery.min.js"></script>
<script src="js/bootstrap.min.js"></script>

</body>
</html>
