<?php
include 'cors.php';
include 'db.php';
include 'jwt.php';
include 'mailer.php';
include 'utils.php';
session_start();
header("Content-Type: application/json");

$request_method = $_SERVER["REQUEST_METHOD"];

if ($request_method === "OPTIONS") {
    header("HTTP/1.1 200 OK");
    exit();
}


if ($request_method === "POST") {
    $data = json_decode(file_get_contents("php://input"), true);

    // //check application/json
    // if (json_last_error() !== JSON_ERROR_NONE) {
    //     response(400, "Invalid JSON");
    // }
    
    if (isset($data["action"])) {
        switch ($data["action"]) {
            case "register":
                registerUser($data);
                break;

            case "registerVendor":
                registerVendor($data);
                break;

            case "registerAdmin":
                registerAdmin($data);
                break;
                
            case "login":
                loginUser($data);
                break;
            case "forgotPassword":
                forgotPassword($data);
                break;
            case "checkOTP":
                checkOTP($data);
                break;
            case "changePassword":
                changePassword($data);
                break;
            default:
                response(400, "Invalid action");
        }
    } else {
        response(400, "Action is required");
    }
} else {
    response(405, "Method Not Allowed");
}
function registerUser($data) {
    global $conn;
    $name = $data["name"];
    $email = $data["email"];
    $password = password_hash($data["password"], PASSWORD_BCRYPT);

    $stmt = executeQuery("SELECT * FROM users WHERE email = ?", [$email], "s");
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        response(400, "Email already exists");
    }

    $stmt = executeQuery("INSERT INTO users (name, email, password) VALUES (?, ?, ?)", [$name, $email, $password], "sss");
    $user_id = $stmt->insert_id;

    $token = generateJWT($user_id, $email, "user");
    $user_data = [
        "id" => $user_id,
        "email" => $email,
        "role" => "user",
        "name" => $name
    ];

    response(200, "Registration successful", ["token" => $token, "user" => $user_data]);
}

function registerVendor($data) {
    global $conn;
    $name = $data["name"];
    $email = $data["email"];
    $password = password_hash($data["password"], PASSWORD_BCRYPT);
    $business_name = $data["business_name"];
    $description = $data["description"];

    $stmt = executeQuery("SELECT * FROM users WHERE email = ?", [$email], "s");
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        response(400, "Email already exists");
    }

    $stmt = executeQuery("INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, 'vendor')", [$name, $email, $password], "sss");
    $user_id = $stmt->insert_id;
    $stmt = executeQuery("INSERT INTO vendors (user_id, business_name, description) VALUES (?, ?, ?)", [$user_id, $business_name, $description], "iss");

    $token = generateJWT($user_id, $email, "vendor");
    $user_data = [
        "id" => $user_id,
        "email" => $email,
        "role" => "vendor",
        "name" => $name,
        "vendor_id" => $stmt->insert_id
    ];

    response(200, "Vendor registration successful", ["token" => $token, "user" => $user_data]);
}

function registerAdmin($data) {
    global $conn;
    $name = $data["name"];
    $email = $data["email"];
    $password = password_hash($data["password"], PASSWORD_BCRYPT);

    $stmt = executeQuery("SELECT * FROM users WHERE email = ?", [$email], "s");
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        response(400, "Email already exists");
    }

    $stmt = executeQuery("INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, 'admin')", [$name, $email, $password], "sss");
    $user_id = $stmt->insert_id;
    $stmt = executeQuery("INSERT INTO admins (user_id) VALUES (?)", [$user_id], "i");

    $token = generateJWT($user_id, $email, "admin");
    $user_data = [
        "id" => $user_id,
        "email" => $email,
        "role" => "admin",
        "name" => $name
    ];

    response(200, "Admin registration successful", ["token" => $token, "user" => $user_data]);
}

function loginUser($data) {
    global $conn;
    $email = $data["email"];
    $password = $data["password"];

    $stmt = executeQuery("SELECT * FROM users WHERE email = ?", [$email], "s");
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        if (password_verify($password, $row['password'])) {
            $token = generateJWT($row['id'], $row['email'], $row['role']);

            $user_data = [
                "id" => $row['id'],
                "email" => $row['email'],
                "role" => $row['role'],
                "name" => $row['name']
            ];
            
            // If user is a vendor, get the vendor_id and add it to the response
            if ($row['role'] === 'vendor') {
                $vendorStmt = executeQuery("SELECT id FROM vendors WHERE user_id = ?", [$row['id']], "i");
                $vendorResult = $vendorStmt->get_result();
                if ($vendorRow = $vendorResult->fetch_assoc()) {
                    $user_data["vendor_id"] = (int)$vendorRow['id'];
                }
                $vendorResult->close();
            }
            
            $result->close(); // Close the result set

            response(200, "Login successful", ["token" => $token, "user" => $user_data]);
        } else {
            response(400, "Invalid password");
        }
    } else {
        response(400, "User not found");
    }
}

function forgotPassword($data) {
    global $conn;
    $email = $data["email"];
    $stmt = executeQuery("SELECT * FROM users WHERE email = ?", [$email], "s");
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        $otp = rand(100000, 999999);
        $expires_at = date("Y-m-d H:i:s", strtotime("+15 days"));
        $stmt = executeQuery("INSERT INTO user_tokens (user_id, token, expires_at) VALUES (?, ?, ?)", [$row['id'], $otp, $expires_at], "iss");
        if (sendEmailOTP($email, $otp)) {
            response(200, "OTP sent to email", ["expires_at" => $expires_at, "now" => date("Y-m-d H:i:s")]);
        } else {
            response(500, "Failed to send OTP email");
        }
    } else {
        response(400, "User not found");
    }
}

function checkOTP($data) {
    global $conn;
    $email = $data["email"];
    $otp = $data["otp"];
    $stmt = executeQuery("SELECT * FROM users WHERE email = ?", [$email], "s");
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        $user_id = $row['id'];
        $stmt = executeQuery("SELECT * FROM user_tokens WHERE user_id = ? AND token = ? AND expires_at > NOW()", [$user_id, $otp], "is");
        $result = $stmt->get_result();
        if ($result->num_rows > 0) {
            response(200, "OTP is valid", ["valid" => true]);
        } else {
            response(400, "Invalid or expired OTP");
        }
    } else {
        response(400, "User not found");
    }
}

function changePassword($data) {
    global $conn;
    $email = $data["email"];
    $otp = $data["otp"];
    $new_password = password_hash($data["new_password"], PASSWORD_BCRYPT);
    $stmt = executeQuery("SELECT * FROM users WHERE email = ?", [$email], "s");
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        $user_id = $row['id'];
        $stmt = executeQuery("SELECT * FROM user_tokens WHERE user_id = ? AND token = ? AND expires_at > NOW()", [$user_id, $otp], "is");
        $result = $stmt->get_result();
        if ($result->num_rows > 0) {
            $stmt = executeQuery("UPDATE users SET password = ? WHERE id = ?", [$new_password, $user_id], "si");
            executeQuery("DELETE FROM user_tokens WHERE user_id = ?", [$user_id], "i");
            response(200, "Password changed successfully");
        } else {
            response(400, "Invalid or expired OTP");
        }
    } else {
        response(400, "User not found");
    }
}


?>