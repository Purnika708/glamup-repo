<?php
include 'db.php';
include 'jwt.php';
include 'utils.php';
include 'cors.php';
session_start();
header("Content-Type: application/json");

$request_method = $_SERVER["REQUEST_METHOD"];

if ($request_method === "POST" || $request_method === "PUT" || $request_method === "DELETE" || $request_method === "PATCH") {
    $data = json_decode(file_get_contents("php://input"), true);
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }

    $user = validateJWT($token);
    if (!$user) {
        response(401, "Unauthorized: Invalid token");
    }

    switch ($request_method) {
        case "POST":
            addAddress($data, $user->user_id);
            break;
        case "PUT":
            updateAddress($data, $user->user_id);
            break;
        case "PATCH":
            patchAddress($data, $user->user_id);
            break;
        case "DELETE":
            deleteAddress($data, $user->user_id);
            break;
        default:
            response(405, "Method Not Allowed");
    }
} elseif ($request_method === "GET") {
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }
    $user = validateJWT($token); 

    if (isset($_GET['id'])) {
        getAddress($_GET['id'], $user->user_id);
    } else {
        getAddresses($user->user_id);
    }
} else {
    response(405, "Method Not Allowed");
}

function addAddress($data, $user_id) {
    $full_name = $data["full_name"];
    $phone = $data["phone"];
    $address_line = $data["address_line"];
    $city = $data["city"];
    $state = $data["state"];
    $zip_code = $data["zip_code"];
    $country = $data["country"];

    $stmt = executeQuery("INSERT INTO addresses (user_id, full_name, phone, address_line, city, state, zip_code, country) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [$user_id, $full_name, $phone, $address_line, $city, $state, $zip_code, $country], "isssssss");
    response(200, "Address added successfully");
}

function updateAddress($data, $user_id) {
    
    $id = $data["id"];
    $full_name = $data["full_name"];
    $phone = $data["phone"];
    $address_line = $data["address_line"];
    $city = $data["city"];
    $state = $data["state"];
    $zip_code = $data["zip_code"];
    $country = $data["country"];

    $stmt = executeQuery("SELECT * FROM addresses WHERE id = ? AND user_id = ?", [$id, $user_id], "ii");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(403, "Forbidden: Users can only update their own addresses");
    }

    $stmt = executeQuery("UPDATE addresses SET full_name = ?, phone = ?, address_line = ?, city = ?, state = ?, zip_code = ?, country = ? WHERE id = ?", [$full_name, $phone, $address_line, $city, $state, $zip_code, $country, $id], "sssssssi");
    response(200, "Address updated successfully");
}

function patchAddress($data, $user_id) {
    $id = $data["id"];
    $fields = [];
    $params = [];
    $types = "";

    if (isset($data["full_name"])) {
        $fields[] = "full_name = ?";
        $params[] = $data["full_name"];
        $types .= "s";
    }
    if (isset($data["phone"])) {
        $fields[] = "phone = ?";
        $params[] = $data["phone"];
        $types .= "s";
    }
    if (isset($data["address_line"])) {
        $fields[] = "address_line = ?";
        $params[] = $data["address_line"];
        $types .= "s";
    }
    if (isset($data["city"])) {
        $fields[] = "city = ?";
        $params[] = $data["city"];
        $types .= "s";
    }
    if (isset($data["state"])) {
        $fields[] = "state = ?";
        $params[] = $data["state"];
        $types .= "s";
    }
    if (isset($data["zip_code"])) {
        $fields[] = "zip_code = ?";
        $params[] = $data["zip_code"];
        $types .= "s";
    }
    if (isset($data["country"])) {
        $fields[] = "country = ?";
        $params[] = $data["country"];
        $types .= "s";
    }

    $stmt = executeQuery("SELECT * FROM addresses WHERE id = ? AND user_id = ?", [$id, $user_id], "ii");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(403, "Forbidden: Users can only update their own addresses");
    }

    $params[] = $id;
    $types .= "i";
    $query = "UPDATE addresses SET " . implode(", ", $fields) . " WHERE id = ?";
    $stmt = executeQuery($query, $params, $types);
    response(200, "Address updated successfully");
}

function deleteAddress($data, $user_id) {
    
    $id = $data["id"];

    $stmt = executeQuery("SELECT * FROM addresses WHERE id = ? AND user_id = ?", [$id, $user_id], "ii");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(403, "Forbidden: Users can only delete their own addresses");
    }

    $stmt = executeQuery("DELETE FROM addresses WHERE id = ?", [$id], "i");
    response(200, "Address deleted successfully");
}

function getAddress($id, $user_id) {
    
    $stmt = executeQuery("SELECT * FROM addresses WHERE id = ? AND user_id = ?", [$id, $user_id], "ii");
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        response(200, "Address found", $row);
    } else {
        response(404, "Address not found");
    }
}

function getAddresses($user_id) {
    
    $stmt = executeQuery("SELECT * FROM addresses WHERE user_id = ?", [$user_id], "i");
    $result = $stmt->get_result();
    $addresses = [];
    while ($row = $result->fetch_assoc()) {
        $addresses[] = $row;
    }
    response(200, "Addresses retrieved", $addresses);
}
?>