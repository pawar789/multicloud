<!DOCTYPE html>
<html>
  <head>
    <title>Welcome to the Cloud </title>
  </head>
<body>


<pre>
<?php

$file = file_get_contents('url.txt');

echo '<img src="'.$file.'"  width="500" height="600">';
?>
</pre>


</body>
</html>
