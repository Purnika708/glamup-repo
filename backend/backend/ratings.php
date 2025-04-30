<?php
include 'cors.php';
include 'db.php';
include 'jwt.php';
include 'utils.php';
header("Content-Type: application/json");

$request_method = $_SERVER["REQUEST_METHOD"];

if ($request_method === "POST") {
    $data = json_decode(file_get_contents("php://input"), true);
    addRating($data);
} elseif ($request_method === "GET") {
    if (isset($_GET['product_id']) && isset($_GET['check_can_rate'])) {
        // New endpoint to check if user can rate a product
        checkCanRateProduct($_GET['product_id']);
    } elseif (isset($_GET['product_id'])) {
        getProductRatings($_GET['product_id']);
    } elseif (isset($_GET['user_id'])) {
        getUserRatings($_GET['user_id']);
    } elseif (isset($_GET['order_id'])) {
        getOrderRatings($_GET['order_id']);
    } elseif (isset($_GET['get_ratable_products'])) {
        // New endpoint to get products user can rate
        getUserRatableProducts();
    } else {
        response(400, "Missing parameters");
    }
} elseif ($request_method === "PUT") {
    $data = json_decode(file_get_contents("php://input"), true);
    updateRating($data);
} elseif ($request_method === "DELETE") {
    $data = json_decode(file_get_contents("php://input"), true);
    deleteRating($data);
} else {
    response(405, "Method Not Allowed");
}

function addRating($data) {
    global $conn;
    
    // Validate token
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }
    
    $user = validateJWT($token);
    if (!$user) {
        response(401, "Unauthorized: Invalid token");
    }
    
    // Validate required fields
    if (empty($data['product_id']) || empty($data['order_id']) || 
        !isset($data['rating']) || $data['rating'] < 1 || $data['rating'] > 5) {
        response(400, "Bad Request: Missing or invalid required fields");
    }
    
    $product_id = $data['product_id'];
    $order_id = $data['order_id'];
    $rating = intval($data['rating']);
    $review = $data['review'] ?? null;
    $user_id = $user->user_id;
    
    // Verify the user has ordered this product
    $stmt = $conn->prepare("SELECT oi.* FROM order_items oi 
                          JOIN orders o ON oi.order_id = o.id 
                          WHERE oi.product_id = ? AND oi.order_id = ? AND o.user_id = ? AND o.status = 'delivered'");
    $stmt->bind_param("iii", $product_id, $order_id, $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        response(403, "Forbidden: You can only rate products you have ordered and received");
    }
    
    // Check if rating already exists
    $stmt = $conn->prepare("SELECT * FROM product_ratings 
                          WHERE product_id = ? AND user_id = ? AND order_id = ?");
    $stmt->bind_param("iii", $product_id, $user_id, $order_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        // Update existing rating
        $stmt = $conn->prepare("UPDATE product_ratings SET rating = ?, review = ? 
                              WHERE product_id = ? AND user_id = ? AND order_id = ?");
        $stmt->bind_param("isiii", $rating, $review, $product_id, $user_id, $order_id);
    } else {
        // Insert new rating
        $stmt = $conn->prepare("INSERT INTO product_ratings (product_id, user_id, order_id, rating, review) 
                              VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("iiiis", $product_id, $user_id, $order_id, $rating, $review);
    }
    
    if ($stmt->execute()) {
        // Get product average rating
        $stmt = $conn->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count 
                              FROM product_ratings WHERE product_id = ?");
        $stmt->bind_param("i", $product_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $rating_stats = $result->fetch_assoc();
        
        response(200, "Rating submitted successfully", [
            "product_id" => $product_id,
            "avg_rating" => round(floatval($rating_stats['avg_rating']), 1),
            "rating_count" => intval($rating_stats['rating_count'])
        ]);
    } else {
        response(500, "Failed to submit rating: " . $conn->error);
    }
}

function updateRating($data) {
    global $conn;
    
    // Validate token
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }
    
    $user = validateJWT($token);
    if (!$user) {
        response(401, "Unauthorized: Invalid token");
    }
    
    // Validate required fields
    if (empty($data['id']) || !isset($data['rating']) || 
        $data['rating'] < 1 || $data['rating'] > 5) {
        response(400, "Bad Request: Missing or invalid required fields");
    }
    
    $rating_id = $data['id'];
    $rating = intval($data['rating']);
    $review = $data['review'] ?? null;
    $user_id = $user->user_id;
    
    // Check if the rating belongs to the user
    $stmt = $conn->prepare("SELECT product_id FROM product_ratings WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $rating_id, $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        response(403, "Forbidden: You can only update your own ratings");
    }
    
    $product_id = $result->fetch_assoc()['product_id'];
    
    // Update the rating
    $stmt = $conn->prepare("UPDATE product_ratings SET rating = ?, review = ? WHERE id = ?");
    $stmt->bind_param("isi", $rating, $review, $rating_id);
    
    if ($stmt->execute()) {
        // Get product average rating
        $stmt = $conn->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count 
                              FROM product_ratings WHERE product_id = ?");
        $stmt->bind_param("i", $product_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $rating_stats = $result->fetch_assoc();
        
        response(200, "Rating updated successfully", [
            "product_id" => $product_id,
            "avg_rating" => round(floatval($rating_stats['avg_rating']), 1),
            "rating_count" => intval($rating_stats['rating_count'])
        ]);
    } else {
        response(500, "Failed to update rating: " . $conn->error);
    }
}

function deleteRating($data) {
    global $conn;
    
    // Validate token
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }
    
    $user = validateJWT($token);
    if (!$user) {
        response(401, "Unauthorized: Invalid token");
    }
    
    if (empty($data['id'])) {
        response(400, "Bad Request: Rating ID is required");
    }
    
    $rating_id = $data['id'];
    $user_id = $user->user_id;
    
    // Check if the rating belongs to the user or if the user is an admin
    if ($user->role === 'admin') {
        $stmt = $conn->prepare("SELECT product_id FROM product_ratings WHERE id = ?");
        $stmt->bind_param("i", $rating_id);
    } else {
        $stmt = $conn->prepare("SELECT product_id FROM product_ratings WHERE id = ? AND user_id = ?");
        $stmt->bind_param("ii", $rating_id, $user_id);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        response(403, "Forbidden: You can only delete your own ratings");
    }
    
    $product_id = $result->fetch_assoc()['product_id'];
    
    // Delete the rating
    $stmt = $conn->prepare("DELETE FROM product_ratings WHERE id = ?");
    $stmt->bind_param("i", $rating_id);
    
    if ($stmt->execute()) {
        // Get product average rating
        $stmt = $conn->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count 
                              FROM product_ratings WHERE product_id = ?");
        $stmt->bind_param("i", $product_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $rating_stats = $result->fetch_assoc();
        
        $avg_rating = $result->num_rows > 0 ? round(floatval($rating_stats['avg_rating']), 1) : 0;
        $rating_count = $result->num_rows > 0 ? intval($rating_stats['rating_count']) : 0;
        
        response(200, "Rating deleted successfully", [
            "product_id" => $product_id,
            "avg_rating" => $avg_rating,
            "rating_count" => $rating_count
        ]);
    } else {
        response(500, "Failed to delete rating: " . $conn->error);
    }
}

function getProductRatings($product_id) {
    global $conn;
    
    $stmt = $conn->prepare("SELECT pr.*, u.name as user_name 
                          FROM product_ratings pr 
                          JOIN users u ON pr.user_id = u.id 
                          WHERE pr.product_id = ? 
                          ORDER BY pr.created_at DESC");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $ratings = [];
    while ($row = $result->fetch_assoc()) {
        $ratings[] = $row;
    }
    
    // Get product average rating
    $stmt = $conn->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count 
                          FROM product_ratings WHERE product_id = ?");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $rating_stats = $result->fetch_assoc();
    
    $response = [
        "ratings" => $ratings,
        "avg_rating" => round(floatval($rating_stats['avg_rating']), 1),
        "rating_count" => intval($rating_stats['rating_count'])
    ];
    
    response(200, "Ratings retrieved successfully", $response);
}

function getUserRatings($user_id) {
    global $conn;
    
    // Validate token
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }
    
    $user = validateJWT($token);
    if (!$user) {
        response(401, "Unauthorized: Invalid token");
    }
    
    // Only allow users to view their own ratings or admins to view any
    if ($user->role !== 'admin' && $user->user_id != $user_id) {
        response(403, "Forbidden: You can only view your own ratings");
    }
    
    $stmt = $conn->prepare("SELECT pr.*, p.name as product_name, p.image_url as product_image
                          FROM product_ratings pr 
                          JOIN products p ON pr.product_id = p.id 
                          WHERE pr.user_id = ? 
                          ORDER BY pr.created_at DESC");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $ratings = [];
    while ($row = $result->fetch_assoc()) {
        // Include the full URL for the image
        if (!empty($row['product_image']) && strpos($row['product_image'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['product_image'] = $protocol . '://' . $host . $row['product_image'];
        }
        
        $ratings[] = $row;
    }
    
    response(200, "User ratings retrieved successfully", $ratings);
}

function getOrderRatings($order_id) {
    global $conn;
    
    // Validate token
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }
    
    $user = validateJWT($token);
    if (!$user) {
        response(401, "Unauthorized: Invalid token");
    }
    
    // If not admin, check if the order belongs to the user
    if ($user->role !== 'admin') {
        $stmt = $conn->prepare("SELECT user_id FROM orders WHERE id = ?");
        $stmt->bind_param("i", $order_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            response(404, "Order not found");
        }
        
        $order = $result->fetch_assoc();
        if ($order['user_id'] != $user->user_id) {
            response(403, "Forbidden: You can only view ratings for your own orders");
        }
    }
    
    $stmt = $conn->prepare("SELECT pr.*, p.name as product_name, p.image_url as product_image 
                          FROM product_ratings pr 
                          JOIN products p ON pr.product_id = p.id 
                          WHERE pr.order_id = ? 
                          ORDER BY pr.created_at DESC");
    $stmt->bind_param("i", $order_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $ratings = [];
    while ($row = $result->fetch_assoc()) {
        // Include the full URL for the image
        if (!empty($row['product_image']) && strpos($row['product_image'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['product_image'] = $protocol . '://' . $host . $row['product_image'];
        }
        
        $ratings[] = $row;
    }
    
    response(200, "Order ratings retrieved successfully", $ratings);
}

function checkCanRateProduct($product_id) {
    global $conn;
    
    // Validate token
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }
    
    $user = validateJWT($token);
    if (!$user) {
        response(401, "Unauthorized: Invalid token");
    }
    
    $user_id = $user->user_id;
    
    // Check if the user has ordered and received this product
    $stmt = $conn->prepare("SELECT o.id as order_id, oi.id as order_item_id
                          FROM order_items oi 
                          JOIN orders o ON oi.order_id = o.id 
                          LEFT JOIN product_ratings pr ON pr.product_id = oi.product_id AND pr.user_id = o.user_id AND pr.order_id = o.id
                          WHERE oi.product_id = ? AND o.user_id = ? AND o.status = 'delivered'
                          AND pr.id IS NULL
                          ORDER BY o.created_at DESC");
    $stmt->bind_param("ii", $product_id, $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $ratable_orders = [];
    while ($row = $result->fetch_assoc()) {
        $ratable_orders[] = [
            'order_id' => intval($row['order_id']),
            'order_item_id' => intval($row['order_item_id'])
        ];
    }
    
    // Get existing ratings for this product by the user
    $stmt = $conn->prepare("SELECT pr.*, o.created_at as order_date
                          FROM product_ratings pr
                          JOIN orders o ON pr.order_id = o.id
                          WHERE pr.product_id = ? AND pr.user_id = ?");
    $stmt->bind_param("ii", $product_id, $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $existing_ratings = [];
    while ($row = $result->fetch_assoc()) {
        $existing_ratings[] = [
            'id' => intval($row['id']),
            'order_id' => intval($row['order_id']),
            'rating' => intval($row['rating']),
            'review' => $row['review'],
            'created_at' => $row['created_at'],
            'order_date' => $row['order_date']
        ];
    }
    
    response(200, "Product rating eligibility checked", [
        'product_id' => intval($product_id),
        'can_rate' => count($ratable_orders) > 0,
        'ratable_orders' => $ratable_orders,
        'existing_ratings' => $existing_ratings
    ]);
}

function getUserRatableProducts() {
    global $conn;
    
    // Validate token
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }
    
    $user = validateJWT($token);
    if (!$user) {
        response(401, "Unauthorized: Invalid token");
    }
    
    $user_id = $user->user_id;
    
    // Get all products that the user has ordered and received but hasn't rated yet
    $stmt = $conn->prepare("SELECT DISTINCT p.id, p.name, p.image_url, p.price, o.id as order_id, o.created_at as order_date
                          FROM products p
                          JOIN order_items oi ON p.id = oi.product_id
                          JOIN orders o ON oi.order_id = o.id
                          LEFT JOIN product_ratings pr ON p.id = pr.product_id AND o.id = pr.order_id AND o.user_id = pr.user_id
                          WHERE o.user_id = ? AND o.status = 'delivered' AND pr.id IS NULL
                          ORDER BY o.created_at DESC");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $ratable_products = [];
    while ($row = $result->fetch_assoc()) {
        // Format image URL
        if (!empty($row['image_url']) && strpos($row['image_url'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['image_url'] = $protocol . '://' . $host . $row['image_url'];
        }
        
        $ratable_products[] = [
            'product_id' => intval($row['id']),
            'name' => $row['name'],
            'image_url' => $row['image_url'],
            'price' => floatval($row['price']),
            'order_id' => intval($row['order_id']),
            'order_date' => $row['order_date']
        ];
    }
    
    // Get products that the user has already rated
    $stmt = $conn->prepare("SELECT DISTINCT p.id, p.name, p.image_url, p.price, pr.id as rating_id, pr.rating, pr.review, 
                          pr.created_at as rating_date, o.id as order_id, o.created_at as order_date
                          FROM products p
                          JOIN product_ratings pr ON p.id = pr.product_id
                          JOIN orders o ON pr.order_id = o.id
                          WHERE pr.user_id = ?
                          ORDER BY pr.created_at DESC");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $rated_products = [];
    while ($row = $result->fetch_assoc()) {
        // Format image URL
        if (!empty($row['image_url']) && strpos($row['image_url'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['image_url'] = $protocol . '://' . $host . $row['image_url'];
        }
        
        $rated_products[] = [
            'product_id' => intval($row['id']),
            'name' => $row['name'],
            'image_url' => $row['image_url'],
            'price' => floatval($row['price']),
            'rating_id' => intval($row['rating_id']),
            'rating' => intval($row['rating']),
            'review' => $row['review'],
            'rating_date' => $row['rating_date'],
            'order_id' => intval($row['order_id']),
            'order_date' => $row['order_date']
        ];
    }
    
    response(200, "Ratable products retrieved successfully", [
        'ratable_products' => $ratable_products,
        'rated_products' => $rated_products
    ]);
}
?>