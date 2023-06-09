<!DOCTYPE html>
<html>
<head>
   <title>Minerva</title>
   <meta charset="utf-8">
   <meta name="viewport" content="width=device-width, initial-scale=1.0">
   <meta name="description" content="">
   <meta name="author" content="">
   <META http-equiv="refresh" content="300">
   
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
            <li class="active"><a href="index.php">Jobstatus</a></li>
            <li><a href="nodestatus.php">Nodestatus</a></li>
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
   echo "<a href=\"javascript:window.location.reload()\">Job Status on: &nbsp; " . strftime('%c') . "</a>";
   echo "<pre>";
   if (preg_match('/([a-z]|[A-Z])+\d+/',$userName)){
      $output = shell_exec("2>&1 bash -c \"source /etc/profile.d/lsf.sh; $minerva_queue_bin/jobstatus -w $userName\"");
      echo $output;
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
