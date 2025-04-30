<?php
include 'db.php';
include 'jwt.php';
include 'utils.php';
session_start();

$request_method = $_SERVER["REQUEST_METHOD"];

if ($request_method === "POST" || $request_method === "PUT" || $request_method === "PATCH" || $request_method === "DELETE") {
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
            if ($user->role === 'user') {
                placeOrder($data, $user->user_id);
            } else {
                response(403, "Forbidden: Only users can place orders");
            }
            break;
        case "PUT":
            if ($user->role === 'admin' || $user->role === 'vendor') {
                updateOrderStatus($data, $user);
            } else {
                response(403, "Forbidden: Only vendors and admins can update order status");
            }
            break;
        case "PATCH":
            if ($user->role === 'admin' || $user->role === 'vendor') {
                patchOrder($data, $user);
            } else {
                response(403, "Forbidden: Only vendors and admins can update orders");
            }
            break;
        case "DELETE":
            if ($user->role === 'admin') {
                deleteOrder($data);
            } else {
                response(403, "Forbidden: Only admins can delete orders");
            }
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
    if (!$user) {
        response(401, "Unauthorized: Invalid token");
    }

    if (isset($_GET['id'])) {
        getOrder($_GET['id'], $user);
    } else {
        getOrders($user);
    }
} else {
    response(405, "Method Not Allowed");
}

function placeOrder($data, $user_id) {
    global $conn;
    
    // Check if cart is empty
    $stmt = executeQuery("SELECT * FROM cart WHERE user_id = ?", [$user_id], "i");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(400, "Bad Request: Cart is empty");
    }
    
    // Get shipping address details
    $address_id = $data['address_id'];
    $stmtAddress = executeQuery("SELECT * FROM addresses WHERE id = ? AND user_id = ?", [$address_id, $user_id], "ii");
    $resultAddress = $stmtAddress->get_result();
    if ($resultAddress->num_rows === 0) {
        response(400, "Bad Request: Invalid shipping address");
    }
    // Get payment details
    $payment_method = $data['payment_method'];
    $trasaction_id = $data['transaction_id'];
    
    // Get cart items grouped by vendor
    $stmt = executeQuery(
        "SELECT c.*, p.price, p.vendor_id 
        FROM cart c 
        JOIN products p ON c.product_id = p.id 
        WHERE c.user_id = ?", 
        [$user_id], "i"
    );
    $result = $stmt->get_result();
    
    // Group cart items by vendor
    $vendor_items = [];
    $total_amount = 0;
    
    while ($row = $result->fetch_assoc()) {
        $vendor_id = $row['vendor_id'];
        if (!isset($vendor_items[$vendor_id])) {
            $vendor_items[$vendor_id] = [
                'items' => [],
                'total' => 0
            ];
        }
        
        $vendor_items[$vendor_id]['items'][] = $row;
        $vendor_items[$vendor_id]['total'] += $row['price'] * $row['quantity'];
        $total_amount += $row['price'] * $row['quantity'];
    }
    
    if (empty($vendor_items)) {
        response(400, "Bad Request: Cart is empty");
    }
    
    // Begin transaction
    $conn->begin_transaction();
    
    try {
        $order_ids = [];
        
        // Create separate order for each vendor
        foreach ($vendor_items as $vendor_id => $vendor_data) {
            // Create order with vendor_id
            $stmt = executeQuery(
                "INSERT INTO orders (user_id, vendor_id, total_amount, status, address_id) VALUES (?, ?, ?, 'pending', ?)", 
                [$user_id, $vendor_id, $vendor_data['total'], $address_id], 
                "iiid"
            );
            $order_id = $conn->insert_id;
            $order_ids[] = $order_id;
            
            // response(200, "Payment method is : ", $payment_method);
            // Create payment record
            $stmt = executeQuery(
                "INSERT INTO payments (order_id, payment_method, transaction_id,  status) VALUES (?, ?,?, 'pending')", 
                [$order_id, $payment_method, $trasaction_id], 
                "isi"
            );
            
            // Add order items for this vendor
            foreach ($vendor_data['items'] as $item) {
                $stmt = executeQuery(
                    "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)", 
                    [$order_id, $item['product_id'], $item['quantity'], $item['price']], 
                    "iiid"
                );
                
                // Update product stock
                $stmt = executeQuery(
                    "UPDATE products SET stock = stock - ? WHERE id = ?", 
                    [$item['quantity'], $item['product_id']], 
                    "ii"
                );
            }
        }
        
        // Clear cart
        $stmt = executeQuery("DELETE FROM cart WHERE user_id = ?", [$user_id], "i");
        
        // Commit transaction
        $conn->commit();
        
        response(200, "Orders placed successfully", ["order_ids" => $order_ids, "total_amount" => $total_amount, "payment_method" => $payment_method]);
    } catch (Exception $e) {
        // Rollback transaction on error
        $conn->rollback();
        response(500, "Error placing order: " . $e->getMessage());
    }
}

function updateOrderStatus($data, $user) {
    global $conn;
    $order_id = $data["order_id"];
    $status = isset($data["status"]) ? $data["status"] : null;
    $payment_status = isset($data["payment_status"]) ? $data["payment_status"] : null;
    
    // Check if the order exists
    $stmt = executeQuery("SELECT * FROM orders WHERE id = ?", [$order_id], "i");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(404, "Order not found");
    }
    $order = $result->fetch_assoc();
    
    // If user is vendor, check if they have products in this order
    if ($user->role === 'vendor') {
        $stmt = executeQuery("SELECT v.id FROM vendors v WHERE v.user_id = ?", [$user->user_id], "i");
        $result = $stmt->get_result();
        if ($result->num_rows === 0) {
            response(403, "Forbidden: Vendor not found");
        }
        $vendor = $result->fetch_assoc();
        $vendor_id = $vendor['id'];
        
        $stmt = executeQuery(
            "SELECT oi.* FROM order_items oi 
            JOIN products p ON oi.product_id = p.id 
            WHERE oi.order_id = ? AND p.vendor_id = ?", 
            [$order_id, $vendor_id], "ii");
        $result = $stmt->get_result();
        if ($result->num_rows === 0) {
            response(403, "Forbidden: This order does not contain your products");
        }
    }
    
    // Update order status
    if ($status !== null) {
        $stmt = executeQuery("UPDATE orders SET status = ? WHERE id = ?", [$status, $order_id], "si");
    }
    
    // Update payment status if provided
    if ($payment_status !== null) {
        $stmt = executeQuery("UPDATE payments SET status = ? WHERE order_id = ?", [$payment_status, $order_id], "si");
    }
    
    response(200, "Order status updated successfully");
}

function patchOrder($data, $user) {
    global $conn;
    $order_id = $data["order_id"];
    $fields = [];
    $params = [];
    $types = "";

    // Check if the order exists
    $stmt = executeQuery("SELECT * FROM orders WHERE id = ?", [$order_id], "i");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(404, "Order not found");
    }
    $order = $result->fetch_assoc();
    
    // If user is vendor, check if they have products in this order
    if ($user->role === 'vendor') {
        $stmt = executeQuery("SELECT v.id FROM vendors v WHERE v.user_id = ?", [$user->user_id], "i");
        $result = $stmt->get_result();
        if ($result->num_rows === 0) {
            response(403, "Forbidden: Vendor not found");
        }
        $vendor = $result->fetch_assoc();
        $vendor_id = $vendor['id'];
        
        $stmt = executeQuery(
            "SELECT oi.* FROM order_items oi 
            JOIN products p ON oi.product_id = p.id 
            WHERE oi.order_id = ? AND p.vendor_id = ?", 
            [$order_id, $vendor_id], "ii");
        $result = $stmt->get_result();
        if ($result->num_rows === 0) {
            response(403, "Forbidden: This order does not contain your products");
        }
    }
    
    if (isset($data["status"])) {
        $fields[] = "status = ?";
        $params[] = $data["status"];
        $types .= "s";
    }
    
    if (count($fields) === 0) {
        response(400, "No fields to update");
    }
    
    $params[] = $order_id;
    $types .= "i";
    $query = "UPDATE orders SET " . implode(", ", $fields) . " WHERE id = ?";
    $stmt = executeQuery($query, $params, $types);
    
    response(200, "Order updated successfully");
}

function deleteOrder($data) {
    global $conn;
    $order_id = $data["order_id"];

    // Check if order exists
    $stmt = executeQuery("SELECT * FROM orders WHERE id = ?", [$order_id], "i");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(404, "Order not found");
    }
    
    // Begin transaction
    $conn->begin_transaction();
    
    try {
        // Delete order items
        $stmt = executeQuery("DELETE FROM order_items WHERE order_id = ?", [$order_id], "i");
        
        // Delete payment
        $stmt = executeQuery("DELETE FROM payments WHERE order_id = ?", [$order_id], "i");
        
        // Delete order
        $stmt = executeQuery("DELETE FROM orders WHERE id = ?", [$order_id], "i");
        
        // Commit transaction
        $conn->commit();
        
        response(200, "Order deleted successfully");
    } catch (Exception $e) {
        // Rollback transaction on error
        $conn->rollback();
        response(500, "Error deleting order: " . $e->getMessage());
    }
}

function getOrder($id, $user) {
    global $conn;
    
    // If admin, get any order
    if ($user->role === 'admin') {
        $stmt = executeQuery(
            "SELECT o.*, p.payment_method, p.status as payment_status, a.full_name, a.phone, a.address_line, a.city, a.state, a.zip_code, a.country, v.business_name as vendor_name
            FROM orders o 
            JOIN payments p ON o.id = p.order_id 
            LEFT JOIN addresses a ON o.address_id = a.id
            LEFT JOIN vendors v ON o.vendor_id = v.id
            WHERE o.id = ?", 
            [$id], "i");
    } 
    // If vendor, get orders containing their products
    else if ($user->role === 'vendor') {
        $stmt = executeQuery("SELECT v.id FROM vendors v WHERE v.user_id = ?", [$user->user_id], "i");
        $result = $stmt->get_result();
        if ($result->num_rows === 0) {
            response(403, "Forbidden: Vendor not found");
        }
        $vendor = $result->fetch_assoc();
        $vendor_id = $vendor['id'];
        
        $stmt = executeQuery(
            "SELECT o.*, p.payment_method, p.status as payment_status, a.full_name, a.phone, a.address_line, a.city, a.state, a.zip_code, a.country, v.business_name as vendor_name 
            FROM orders o 
            JOIN payments p ON o.id = p.order_id 
            LEFT JOIN addresses a ON o.address_id = a.id
            LEFT JOIN vendors v ON o.vendor_id = v.id
            WHERE o.id = ? AND o.vendor_id = ?", 
            [$id, $vendor_id], "ii");
    } 
    // If user, get their own order
    else {
        $stmt = executeQuery(   
            "SELECT o.*, p.payment_method, p.status as payment_status, a.full_name, a.phone, a.address_line, a.city, a.state, a.zip_code, a.country, v.business_name as vendor_name
            FROM orders o 
            JOIN payments p ON o.id = p.order_id 
            LEFT JOIN addresses a ON o.address_id = a.id
            LEFT JOIN vendors v ON o.vendor_id = v.id
            WHERE o.id = ? AND o.user_id = ?", 
            [$id, $user->user_id], "ii");
    }
    
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        // Get order items
        $stmt2 = executeQuery(
            "SELECT oi.*, p.name as product_name, p.image_url as product_image 
            FROM order_items oi 
            JOIN products p ON oi.product_id = p.id 
            WHERE oi.order_id = ?", 
            [$id], "i");
        $result2 = $stmt2->get_result();
        $items = [];
        while ($item = $result2->fetch_assoc()) {
            $items[] = $item;
        }
        $row['items'] = $items;
        
        response(200, "Order found", $row);
    } else {
        response(404, "Order not found");
    }
}

function getOrders($user) {
    global $conn;
    
    // If admin, get all orders
    if ($user->role === 'admin') {
        $stmt = executeQuery(
            "SELECT o.*, p.payment_method, p.status as payment_status, a.full_name, v.business_name as vendor_name  
            FROM orders o 
            JOIN payments p ON o.id = p.order_id 
            LEFT JOIN addresses a ON o.address_id = a.id
            LEFT JOIN vendors v ON o.vendor_id = v.id
            ORDER BY o.created_at DESC", 
            [], null);
    } 
    // If vendor, get orders containing their products
    else if ($user->role === 'vendor') {
        $stmt = executeQuery("SELECT v.id FROM vendors v WHERE v.user_id = ?", [$user->user_id], "i");
        $result = $stmt->get_result();
        if ($result->num_rows === 0) {
            response(403, "Forbidden: Vendor not found");
        }
        $vendor = $result->fetch_assoc();
        $vendor_id = $vendor['id'];
        
        $stmt = executeQuery(
            "SELECT o.*, p.payment_method, p.status as payment_status, a.full_name, v.business_name as vendor_name  
            FROM orders o 
            JOIN payments p ON o.id = p.order_id 
            LEFT JOIN addresses a ON o.address_id = a.id
            LEFT JOIN vendors v ON o.vendor_id = v.id
            WHERE o.vendor_id = ? 
            ORDER BY o.created_at DESC", 
            [$vendor_id], "i");
    } 
    // If user, get their own orders
    else {
        $stmt = executeQuery(
            "SELECT o.*, p.payment_method, p.status as payment_status, a.full_name, v.business_name as vendor_name  
            FROM orders o 
            JOIN payments p ON o.id = p.order_id 
            LEFT JOIN addresses a ON o.address_id = a.id
            LEFT JOIN vendors v ON o.vendor_id = v.id
            WHERE o.user_id = ? 
            ORDER BY o.created_at DESC", 
            [$user->user_id], "i");
    }
    
    $result = $stmt->get_result();
    $orders = [];
    while ($row = $result->fetch_assoc()) {
        $orders[] = $row;
    }
    
    response(200, "Orders retrieved", $orders);
}
?>