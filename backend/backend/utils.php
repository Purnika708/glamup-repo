<?php
function executeQuery($query, $params, $types) {
    global $conn;
    $stmt = $conn->prepare($query);
    if ($stmt === false) {
        response(500, "Failed to prepare statement: " . $conn->error);
    }
    if (!empty($types)) {
        $stmt->bind_param($types, ...$params);
    }
    if ($stmt->execute()) {
        return $stmt;
    } else {
        response(500, "Failed to execute statement: " . $stmt->error);
    }
}

function response($status, $message, $data = []) {
    http_response_code($status);
    echo json_encode(["status" => $status, "message" => $message, "data" => $data]);
    exit();
}

function getBearerToken() {
    $headers = apache_request_headers();
    if (isset($headers['authorization'])) {
        $matches = [];
        if (preg_match('/Bearer\s(\S+)/', $headers['authorization'], $matches)) {
            return $matches[1];
        }
    }
    return null;
}
?>