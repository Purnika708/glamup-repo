<?php
include 'cors.php';
include 'db.php';
include 'jwt.php';
include 'utils.php';
header("Content-Type: application/json");

$request_method = $_SERVER["REQUEST_METHOD"];

// Check authentication for all requests
$token = getBearerToken();
if (!$token) {
    response(401, "Unauthorized: Token not found");
}

$user = validateJWT($token);
if (!$user) {
    response(401, "Unauthorized: Invalid token");
}

// Route requests based on method
if ($request_method === "GET") {
    getUserProfile($user->user_id);
} elseif ($request_method === "PUT" || $request_method === "POST") {
    // Handle JSON data
    $data = json_decode(file_get_contents("php://input"), true);
    handleProfileUpdate($user->user_id, $data);
} else {
    response(405, "Method Not Allowed");
}

/**
 * Get user profile information
 */
function getUserProfile($user_id) {
    global $conn;
    
    // Get basic user information
    $stmt = $conn->prepare(
        "SELECT u.id, u.name, u.email, u.role, u.created_at 
        FROM users u 
        WHERE u.id = ?"
    );
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        response(404, "User not found");
    }
    
    $user = $result->fetch_assoc();
    $role = $user['role'];
    
    // Get additional role-specific information
    if ($role === 'vendor') {
        // For vendors, get comprehensive vendor details
        $stmt = $conn->prepare(
            "SELECT v.id as vendor_id, v.business_name, v.description, 
            (SELECT COUNT(*) FROM products p WHERE p.vendor_id = v.id) as product_count 
            FROM vendors v 
            WHERE v.user_id = ?"
        );
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $vendor_result = $stmt->get_result();
        
        if ($vendor_result->num_rows > 0) {
            $vendor_data = $vendor_result->fetch_assoc();
            $user['vendor_id'] = $vendor_data['vendor_id'];
            $user['business_name'] = $vendor_data['business_name'];
            $user['description'] = $vendor_data['description'];
            $user['product_count'] = (int)$vendor_data['product_count'];
        } else {
            // If user role is vendor but no vendor record exists
            $user['vendor_id'] = null;
            $user['business_name'] = null;
            $user['description'] = null;
            $user['product_count'] = 0;
        }
    }
    
    // Get addresses
    $stmt = $conn->prepare("SELECT * FROM addresses WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $addresses_result = $stmt->get_result();
    
    $addresses = [];
    while ($address = $addresses_result->fetch_assoc()) {
        $addresses[] = $address;
    }
    
    $user['addresses'] = $addresses;
    
    response(200, "Profile retrieved successfully", $user);
}

/**
 * Handle profile update
 */
function handleProfileUpdate($user_id, $data) {
    global $conn;
    
    // Start transaction
    $conn->begin_transaction();
    
    try {
        // Update user information
        $name = $data['name'] ?? null;
        $email = $data['email'] ?? null;
        
        if ($name || $email) {
            $query = "UPDATE users SET";
            $params = [];
            $types = "";
            $updates = [];
            
            if ($name) {
                $updates[] = " name = ?";
                $params[] = $name;
                $types .= "s";
            }
            
            if ($email) {
                // Check if email is already used by another user
                $stmt = $conn->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
                $stmt->bind_param("si", $email, $user_id);
                $stmt->execute();
                $result = $stmt->get_result();
                
                if ($result->num_rows > 0) {
                    throw new Exception("Email is already used by another user");
                }
                
                $updates[] = " email = ?";
                $params[] = $email;
                $types .= "s";
            }
            
            $query .= implode(",", $updates);
            $query .= " WHERE id = ?";
            $params[] = $user_id;
            $types .= "i";
            
            $stmt = $conn->prepare($query);
            if (!empty($params)) {
                $stmt->bind_param($types, ...$params);
                $stmt->execute();
            }
        }
        
        // Update vendor information if role is vendor
        $stmt = $conn->prepare("SELECT role FROM users WHERE id = ?");
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $role = $result->fetch_assoc()['role'];
        
        if ($role === 'vendor') {
            $business_name = $data['business_name'] ?? null;
            $description = $data['description'] ?? null;
            
            // Validate business name if provided (required for vendors)
            if ($business_name === '') {
                throw new Exception("Business name is required for vendors");
            }
            
            if ($business_name || $description) {
                // Check if vendor record exists
                $stmt = $conn->prepare("SELECT id FROM vendors WHERE user_id = ?");
                $stmt->bind_param("i", $user_id);
                $stmt->execute();
                $result = $stmt->get_result();
                
                if ($result->num_rows > 0) {
                    // Update existing vendor record
                    $query = "UPDATE vendors SET";
                    $params = [];
                    $types = "";
                    $updates = [];
                    
                    if ($business_name) {
                        $updates[] = " business_name = ?";
                        $params[] = $business_name;
                        $types .= "s";
                    }
                    
                    if ($description !== null) { // Allow empty description but not null
                        $updates[] = " description = ?";
                        $params[] = $description;
                        $types .= "s";
                    }
                    
                    if (!empty($updates)) {
                        $query .= implode(",", $updates);
                        $query .= " WHERE user_id = ?";
                        $params[] = $user_id;
                        $types .= "i";
                        
                        $stmt = $conn->prepare($query);
                        $stmt->bind_param($types, ...$params);
                        $stmt->execute();
                    }
                } else {
                    // Create new vendor record
                    $business_name = $business_name ?? '';
                    $description = $description ?? '';
                    
                    $stmt = $conn->prepare("INSERT INTO vendors (user_id, business_name, description) VALUES (?, ?, ?)");
                    $stmt->bind_param("iss", $user_id, $business_name, $description);
                    $stmt->execute();
                }
            }
        } else if (array_key_exists('business_name', $data) || array_key_exists('description', $data)) {
            // If user is not a vendor but tries to update vendor fields
            throw new Exception("Only vendors can update business information");
        }
        
        $conn->commit();
        
        // Get updated profile
        getUserProfile($user_id);
    } catch (Exception $e) {
        $conn->rollback();
        response(500, "Error updating profile: " . $e->getMessage());
    }
}
?>
