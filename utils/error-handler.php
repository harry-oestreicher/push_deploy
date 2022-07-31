$email = 'hoestreicher@ce9.uscourts.gov';
$subject = 'Testing POST requests';
$remote_ip = $_SERVER['REMOTE_ADDR'];
$remote_host = $_SERVER["REMOTE_HOST"];
$user_agent = $_SERVER['HTTP_USER_AGENT'];
$method = $_SERVER['REQUEST_METHOD'];
$protocol = $_SERVER['SERVER_PROTOCOL'];
$post_vars = file_get_contents('php://input');
$message = 'IP: ' . $remote_ip . "\n";
$message .= 'HOST: ' . $remote_host . "\n";
$message .= 'User Agent: ' . $user_agent . "\n";
$message .= 'Method: ' . $method . "\n";
$message .= 'Protocol: ' . $protocol . "\n";
$message .= 'POST Vars: ' . $post_vars . "\n";
if ($method == 'POST') mail($email, $subject, $message);

