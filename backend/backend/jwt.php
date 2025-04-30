<?php
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

require '../vendor/autoload.php';

$secret_key = "98769y8h*(&YUIG&*TIGTrufyufyfyfy78788tifr676rr67r67iifif6fi6767r44474yedytdy";  //  a secure key

function generateJWT($user_id, $email, $role) {
    global $secret_key;
    $payload = [
        "iat" => time(),
        "exp" => time() + (60 * 60 * 24 * 365 ), // Token expires in 1 year
        "user_id" => $user_id,
        "email" => $email, 
        "role" => $role
    ];
    return JWT::encode($payload, $secret_key, 'HS256');
}

function validateJWT($token) {
    global $secret_key;
    try {
        return JWT::decode($token, new Key($secret_key, 'HS256'));
    } catch (Exception $e) {
        return null;
    }
}
?>
