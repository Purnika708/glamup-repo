<?php
/**
 * Generates a JWT token for admin API requests if not already in session
 * This file should be included after session_start() and before any API calls
 */

if (!isset($_SESSION['auth_token']) && isset($_SESSION['admin_id'])) {
    include_once '../backend/jwt.php';
    include_once '../backend/db.php';
    
    // Get admin user details
    $admin_id = $_SESSION['admin_id'];
    $query = "SELECT * FROM users WHERE id = ? AND role = 'admin'";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $admin_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 1) {
        $user = $result->fetch_assoc();
        $token = generateJWT($user['id'], $user['email'], $user['role']);
        $_SESSION['auth_token'] = $token;
    }
    
    $stmt->close();
    // Do not close the connection here as it may be needed by the including file
}
