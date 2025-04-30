<?php
include 'cors.php';
include 'db.php';
include 'jwt.php';
include 'utils.php';
session_start();

$request_method = $_SERVER["REQUEST_METHOD"];

if ($request_method === "POST" || $request_method === "PUT" || $request_method === "DELETE") {
    $data = json_decode(file_get_contents("php://input"), true);
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }

    $user = validateJWT($token);
    if (!$user || $user->role !== 'admin') {
        response(403, "Forbidden: Only admins can manage users");
    }

    switch ($request_method) {
        case "POST":
            addUser($data);
            break;
        case "PUT":
            updateUser($data);
            break;
        case "DELETE":
            deleteUser($data);
            break;
    }
} elseif ($request_method === "GET") {
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }

    $user = validateJWT($token);
    if (!$user || $user->role !== 'admin') {
        response(403, "Forbidden: Only admins can view user list");
    }

    if (isset($_GET['id'])) {
        if (isset($_GET['type']) && $_GET['type'] === 'vendor') {
            getVendorDetails($_GET['id']);
        } else {
            getUser($_GET['id']);
        }
    } else {
        getUsers();
    }
} else {
    response(405, "Method Not Allowed");
}

function addUser($data) {
    global $conn;
    
    // Validate required fields
    if (empty($data['name']) || empty($data['email']) || empty($data['password'])) {
        response(400, "Bad Request: Name, email and password are required");
    }
    
    // Check if email already exists
    $stmt = executeQuery("SELECT id FROM users WHERE email = ?", [$data['email']], "s");
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        response(400, "Bad Request: Email already exists");
    }
    
    // Hash password
    $password = password_hash($data['password'], PASSWORD_BCRYPT);
    $role = $data['role'] ?? 'user';
    
    // Begin transaction
    $conn->begin_transaction();
    
    try {
        // Insert user
        $stmt = executeQuery(
            "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)",
            [$data['name'], $data['email'], $password, $role],
            "ssss"
        );
        
        $user_id = $conn->insert_id;
        
        // If vendor, add vendor details
        if ($role === 'vendor' && !empty($data['business_name'])) {
            $business_name = $data['business_name'];
            $description = $data['description'] ?? '';
            
            executeQuery(
                "INSERT INTO vendors (user_id, business_name, description) VALUES (?, ?, ?)",
                [$user_id, $business_name, $description],
                "iss"
            );
        }
        
        // If admin, add to admins table
        if ($role === 'admin') {
            executeQuery(
                "INSERT INTO admins (user_id) VALUES (?)",
                [$user_id],
                "i"
            );
        }
        
        $conn->commit();
        response(200, "User created successfully", ["id" => $user_id]);
    } catch (Exception $e) {
        $conn->rollback();
        response(500, "Error creating user: " . $e->getMessage());
    }
}

function updateUser($data) {
    global $conn;
    
    // Validate required fields
    if (empty($data['id']) || empty($data['name']) || empty($data['email'])) {
        response(400, "Bad Request: ID, name and email are required");
    }
    
    $id = $data['id'];
    $name = $data['name'];
    $email = $data['email'];
    $role = $data['role'] ?? 'user';
    
    // Check if email exists for another user
    $stmt = executeQuery("SELECT id FROM users WHERE email = ? AND id != ?", [$email, $id], "si");
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        response(400, "Bad Request: Email already used by another user");
    }
    
    // Get current user role
    $stmt = executeQuery("SELECT role FROM users WHERE id = ?", [$id], "i");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(404, "User not found");
    }
    $current_role = $result->fetch_assoc()['role'];
    
    // Begin transaction
    $conn->begin_transaction();
    
    try {
        // Update user basic info
        $query = "UPDATE users SET name = ?, email = ?, role = ?";
        $params = [$name, $email, $role];
        $types = "sss";
        
        // Update password if provided
        if (!empty($data['password'])) {
            $password = password_hash($data['password'], PASSWORD_BCRYPT);
            $query .= ", password = ?";
            $params[] = $password;
            $types .= "s";
        }
        
        $query .= " WHERE id = ?";
        $params[] = $id;
        $types .= "i";
        
        executeQuery($query, $params, $types);
        
        // Handle role changes
        if ($current_role !== $role) {
            // Remove from previous role tables if needed
            if ($current_role === 'vendor') {
                executeQuery("DELETE FROM vendors WHERE user_id = ?", [$id], "i");
            } elseif ($current_role === 'admin') {
                executeQuery("DELETE FROM admins WHERE user_id = ?", [$id], "i");
            }
            
            // Add to new role tables if needed
            if ($role === 'vendor') {
                $business_name = $data['business_name'] ?? '';
                $description = $data['description'] ?? '';
                
                executeQuery(
                    "INSERT INTO vendors (user_id, business_name, description) VALUES (?, ?, ?)",
                    [$id, $business_name, $description],
                    "iss"
                );
            } elseif ($role === 'admin') {
                executeQuery(
                    "INSERT INTO admins (user_id) VALUES (?)",
                    [$id],
                    "i"
                );
            }
        } 
        // If role is the same but vendor details changed
        elseif ($role === 'vendor' && !empty($data['business_name'])) {
            $business_name = $data['business_name'];
            $description = $data['description'] ?? '';
            
            // Check if vendor record exists
            $stmt = executeQuery("SELECT id FROM vendors WHERE user_id = ?", [$id], "i");
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                // Update existing vendor
                executeQuery(
                    "UPDATE vendors SET business_name = ?, description = ? WHERE user_id = ?",
                    [$business_name, $description, $id],
                    "ssi"
                );
            } else {
                // Create new vendor record
                executeQuery(
                    "INSERT INTO vendors (user_id, business_name, description) VALUES (?, ?, ?)",
                    [$id, $business_name, $description],
                    "iss"
                );
            }
        }
        
        $conn->commit();
        response(200, "User updated successfully");
    } catch (Exception $e) {
        $conn->rollback();
        response(500, "Error updating user: " . $e->getMessage());
    }
}

function deleteUser($data) {
    global $conn;
    $id = $data["id"];

    // Don't allow deleting own account
    $token = getBearerToken();
    $user = validateJWT($token);
    if ($user->user_id == $id) {
        response(400, "Bad Request: Cannot delete your own account");
    }

    // Start transaction to ensure data consistency
    $conn->begin_transaction();

    try {
        // Delete user
        $stmt = executeQuery("DELETE FROM users WHERE id = ?", [$id], "i");
        
        // Foreign key constraints with ON DELETE CASCADE will handle related records

        $conn->commit();
        response(200, "User deleted successfully");
    } catch (Exception $e) {
        $conn->rollback();
        response(500, "Error deleting user: " . $e->getMessage());
    }
}

function getUser($id) {
    global $conn;
    $stmt = executeQuery("SELECT * FROM users WHERE id = ?", [$id], "i");
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        response(200, "User found", $row);
    } else {
        response(404, "User not found");
    }
}

function getVendorDetails($user_id) {
    global $conn;
    $stmt = executeQuery("SELECT * FROM vendors WHERE user_id = ?", [$user_id], "i");
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        response(200, "Vendor details found", $row);
    } else {
        response(404, "Vendor details not found");
    }
}

function getUsers() {
    global $conn;
    $stmt = executeQuery(
        "SELECT u.*, 
         CASE WHEN v.id IS NOT NULL THEN v.business_name ELSE NULL END AS business_name,
         CASE WHEN a.id IS NOT NULL THEN 1 ELSE 0 END AS is_admin
         FROM users u
         LEFT JOIN vendors v ON u.id = v.user_id
         LEFT JOIN admins a ON u.id = a.user_id
         ORDER BY u.id DESC",
        [], null);
    $result = $stmt->get_result();
    $users = [];
    while ($row = $result->fetch_assoc()) {
        $users[] = $row;
    }
    response(200, "Users retrieved", $users);
}
?>
