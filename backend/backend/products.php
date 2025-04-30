<?php
include 'cors.php';
include 'db.php';
include 'jwt.php';
include 'utils.php';
header("Content-Type: application/json");

$request_method = $_SERVER["REQUEST_METHOD"];

// Create uploads directory if it doesn't exist
$upload_dir = '../uploads/products/';
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0777, true);
}

if ($request_method === "POST") {
    // Check for form data vs JSON data
    if (!empty($_FILES['product_image'])) {
        // Handle multipart form data (with file upload)
        $product_data = $_POST;

        // Check if the action is 'update'
        $is_update = isset($product_data['action']) && $product_data['action'] === 'update';
        handleProductImageUpload($product_data, $is_update);
    } else {
        // Handle JSON data
        $data = json_decode(file_get_contents("php://input"), true);
        addProduct($data);
    }
} elseif ($request_method === "GET") {
    if (isset($_GET['id'])) {
        getProduct($_GET['id']);
    } elseif (isset($_GET['category_id'])) {
        getProductsByCategory($_GET['category_id']);
    } elseif (isset($_GET['vendor_id'])) {
        getProductsByVendor($_GET['vendor_id']);
    } else {
        getAllProducts();
    }
} elseif ($request_method === "PUT") {
    if (!empty($_FILES['product_image'])) {
        // Handle multipart form data (with file upload)
        $product_data = $_POST;
        handleProductImageUpload($product_data, true);
    } else {
        // Handle JSON data
        $data = json_decode(file_get_contents("php://input"), true);
        updateProduct($data);
    }
} elseif ($request_method === "DELETE") {
    // Check if ID is in the URL parameters
    if (isset($_GET['id'])) {
        $product_id = $_GET['id'];
        deleteProduct($product_id);
    } else {
        // Fallback to JSON body if ID isn't in URL
        $data = json_decode(file_get_contents("php://input"), true);
        if (isset($data['id'])) {
            deleteProduct($data['id']);
        } else {
            response(400, "Bad Request: Product ID is required");
        }
    }
} elseif ($request_method === "PATCH") {
    $data = json_decode(file_get_contents("php://input"), true);

    // Check if it's a stock update request
    if (isset($data['action']) && $data['action'] === 'update_stock') {
        updateProductStock($data);
    } else {
        response(400, "Bad Request: Unknown PATCH action");
    }
} else {
    response(405, "Method Not Allowed");
}

// Handle image upload from multipart form data
function handleProductImageUpload(&$product_data, $is_update = false)
{
    global $upload_dir;

    // Process image upload
    if (!empty($_FILES['product_image']['name'])) {
        $file_name = $_FILES['product_image']['name'];
        $file_tmp = $_FILES['product_image']['tmp_name'];
        $file_type = $_FILES['product_image']['type'];
        $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));

        // Allowed extensions
        $allowed_extensions = array("jpg", "jpeg", "png", "gif");

        if (in_array($file_ext, $allowed_extensions)) {
            // Generate a unique file name
            $new_file_name = uniqid('product_') . '.' . $file_ext;
            $destination = $upload_dir . $new_file_name;

            if (move_uploaded_file($file_tmp, $destination)) {
                // Set the image URL in product data
                $product_data['image_url'] = '/Glamup/uploads/products/' . $new_file_name;
            } else {
                response(500, "Failed to upload image");
            }
        } else {
            response(400, "Invalid file type. Only JPG, JPEG, PNG and GIF are allowed");
        }
    }

    // Call appropriate function based on operation
    if ($is_update) {
        updateProduct($product_data);
    } else {
        addProduct($product_data);
    }
}

function updateProductStock($data)
{
    global $conn;

    // Validate token for admin or vendor
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }

    $user = validateJWT($token);
    if (!$user || ($user->role !== 'admin' && $user->role !== 'vendor')) {
        response(403, "Forbidden: Only admins or vendors can update product stock");
    }

    // Validate required fields
    if (empty($data['id']) || !isset($data['stock']) || !is_numeric($data['stock'])) {
        response(400, "Bad Request: Product ID and valid stock value are required");
    }

    $product_id = $data['id'];
    $stock = intval($data['stock']);

    // Negative stock doesn't make sense
    if ($stock < 0) {
        response(400, "Bad Request: Stock cannot be negative");
    }

    // Check if product exists and if user has permission
    $stmt = $conn->prepare("SELECT p.*, v.user_id as vendor_user_id FROM products p JOIN vendors v ON p.vendor_id = v.id WHERE p.id = ?");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        response(404, "Product not found");
    }

    $product = $result->fetch_assoc();
    $stmt->close();

    // Check if user has permission (admin or the product owner)
    if ($user->role !== 'admin' && $user->user_id != $product['vendor_user_id']) {
        response(403, "Forbidden: You don't have permission to update this product's stock");
    }

    // Update product stock only
    $stmt = $conn->prepare("UPDATE products SET stock = ? WHERE id = ?");
    $stmt->bind_param("ii", $stock, $product_id);

    if ($stmt->execute()) {
        // Get the updated product data (limited to necessary fields)
        $stmt->close();
        $stmt = $conn->prepare("SELECT id, name, stock FROM products WHERE id = ?");
        $stmt->bind_param("i", $product_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $updated_product = $result->fetch_assoc();

        // Convert to proper types
        $updated_product['id'] = (int)$updated_product['id'];
        $updated_product['stock'] = (int)$updated_product['stock'];

        response(200, "Product stock updated successfully", $updated_product);
    } else {
        response(500, "Failed to update product stock: " . $conn->error);
    }
}

function addProduct($data)
{
    global $conn;

    // Validate token for admin or vendor
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }

    $user = validateJWT($token);
    if (!$user || ($user->role !== 'admin' && $user->role !== 'vendor')) {
        response(403, "Forbidden: Only admins or vendors can add products");
    }

    // Validate required fields
    if (
        empty($data['name']) || empty($data['description']) ||
        !isset($data['price']) || !isset($data['stock']) ||
        empty($data['category_id'])
    ) {
        response(400, "Bad Request: Missing required fields");
    }

    // If user is a vendor, get vendor_id
    $vendor_id = null;
    if ($user->role === 'vendor') {
        $stmt = $conn->prepare("SELECT id FROM vendors WHERE user_id = ?");
        $stmt->bind_param("i", $user->user_id);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            response(400, "Bad Request: Vendor profile not found");
        }

        $vendor = $result->fetch_assoc();
        $vendor_id = $vendor['id'];
        $stmt->close();
    } else {
        // If admin, use the vendor_id from the request
        if (empty($data['vendor_id'])) {
            response(400, "Bad Request: Vendor ID is required");
        }
        $vendor_id = $data['vendor_id'];
    }

    // Process the data
    $name = $data['name'];
    $description = $data['description'];
    $price = floatval($data['price']);
    $stock = intval($data['stock']);
    $category_id = $data['category_id'];
    $image_url = $data['image_url'] ?? null;

    // Insert product
    $stmt = $conn->prepare("INSERT INTO products (name, description, price, stock, category_id, vendor_id, image_url) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("ssdiiss", $name, $description, $price, $stock, $category_id, $vendor_id, $image_url);

    if ($stmt->execute()) {
        $product_id = $conn->insert_id;

        // Get the full product data
        $stmt->close();
        $stmt = $conn->prepare("SELECT p.*, c.name as category_name, v.business_name as vendor_name 
                               FROM products p 
                               JOIN categories c ON p.category_id = c.id 
                               JOIN vendors v ON p.vendor_id = v.id 
                               WHERE p.id = ?");
        $stmt->bind_param("i", $product_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $product = $result->fetch_assoc();

        // Include the full URL for the image
        if (!empty($product['image_url']) && strpos($product['image_url'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $product['image_url'] = $protocol . '://' . $host . $product['image_url'];
        }

        response(201, "Product created successfully", $product);
    } else {
        response(500, "Failed to create product: " . $conn->error);
    }
}

function updateProduct($data)
{
    global $conn;

    // Validate token for admin or vendor
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }

    $user = validateJWT($token);
    if (!$user || ($user->role !== 'admin' && $user->role !== 'vendor')) {
        response(403, "Forbidden: Only admins or vendors can update products");
    }

    // Validate required fields
    if (
        empty($data['id']) || empty($data['name']) || empty($data['description']) ||
        !isset($data['price']) || !isset($data['stock']) ||
        empty($data['category_id'])
    ) {
        response(400, "Bad Request: Missing required fields");
    }

    $product_id = $data['id'];

    // Check if product exists and if user has permission
    $stmt = $conn->prepare("SELECT p.*, v.user_id as vendor_user_id FROM products p JOIN vendors v ON p.vendor_id = v.id WHERE p.id = ?");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        response(404, "Product not found");
    }

    $product = $result->fetch_assoc();
    $stmt->close();

    // Check if user has permission (admin or the product owner)
    if ($user->role !== 'admin' && $user->user_id != $product['vendor_user_id']) {
        response(403, "Forbidden: You don't have permission to update this product");
    }

    // Process the data
    $name = $data['name'];
    $description = $data['description'];
    $price = floatval($data['price']);
    $stock = intval($data['stock']);
    $category_id = $data['category_id'];
    $vendor_id = $user->role === 'admin' ? ($data['vendor_id'] ?? $product['vendor_id']) : $product['vendor_id'];
    $image_url = $data['image_url'] ?? $product['image_url'];

    // Update product
    $stmt = $conn->prepare("UPDATE products SET name = ?, description = ?, price = ?, stock = ?, category_id = ?, vendor_id = ?, image_url = ? WHERE id = ?");
    $stmt->bind_param("ssdiissi", $name, $description, $price, $stock, $category_id, $vendor_id, $image_url, $product_id);

    if ($stmt->execute()) {
        // Get the updated product data
        $stmt->close();
        $stmt = $conn->prepare("SELECT p.*, c.name as category_name, v.business_name as vendor_name 
                               FROM products p 
                               JOIN categories c ON p.category_id = c.id 
                               JOIN vendors v ON p.vendor_id = v.id 
                               WHERE p.id = ?");
        $stmt->bind_param("i", $product_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $updated_product = $result->fetch_assoc();

        // Include the full URL for the image
        if (!empty($updated_product['image_url']) && strpos($updated_product['image_url'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $updated_product['image_url'] = $protocol . '://' . $host . $updated_product['image_url'];
        }

        response(200, "Product updated successfully", $updated_product);
    } else {
        response(500, "Failed to update product: " . $conn->error);
    }
}

function deleteProduct($product_id)
{
    global $conn;

    // Validate token for admin or vendor
    $token = getBearerToken();
    if (!$token) {
        response(401, "Unauthorized: Token not found");
    }

    $user = validateJWT($token);
    if (!$user || ($user->role !== 'admin' && $user->role !== 'vendor')) {
        response(403, "Forbidden: Only admins or vendors can delete products");
    }

    if (empty($product_id)) {
        response(400, "Bad Request: Product ID is required");
    }

    // Check if product exists and if user has permission
    $stmt = $conn->prepare("SELECT p.*, v.user_id as vendor_user_id, p.image_url FROM products p JOIN vendors v ON p.vendor_id = v.id WHERE p.id = ?");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        response(404, "Product not found");
    }

    $product = $result->fetch_assoc();
    $stmt->close();

    // Check if user has permission (admin or the product owner)
    if ($user->role !== 'admin' && $user->user_id != $product['vendor_user_id']) {
        response(403, "Forbidden: You don't have permission to delete this product");
    }

    // Delete the image file if it exists
    if (!empty($product['image_url']) && strpos($product['image_url'], '/uploads/products/') !== false) {
        $image_path = $_SERVER['DOCUMENT_ROOT'] . $product['image_url'];
        if (file_exists($image_path)) {
            unlink($image_path);
        }
    }

    // Delete the product
    $stmt = $conn->prepare("DELETE FROM products WHERE id = ?");
    $stmt->bind_param("i", $product_id);

    if ($stmt->execute()) {
        response(200, "Product deleted successfully");
    } else {
        response(500, "Failed to delete product: " . $conn->error);
    }
}

function getProduct($id)
{
    global $conn;

    $stmt = $conn->prepare("SELECT p.*, c.name as category_name, c.description as category_description, v.business_name as vendor_name 
                           FROM products p 
                           JOIN categories c ON p.category_id = c.id 
                           JOIN vendors v ON p.vendor_id = v.id 
                           WHERE p.id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        response(404, "Product not found");
    }

    $product = $result->fetch_assoc();

    // Get product ratings
    $stmt = $conn->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count 
                          FROM product_ratings 
                          WHERE product_id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    $rating_stats = $result->fetch_assoc();

    // Add rating information to product
    $product['avg_rating'] = $result->num_rows > 0 && $rating_stats['rating_count'] > 0
        ? round(floatval($rating_stats['avg_rating']), 1)
        : 0;
    $product['rating_count'] = intval($rating_stats['rating_count']);

    // Get the most recent ratings (limit to 5)
    $stmt = $conn->prepare("SELECT pr.*, u.name as user_name 
                          FROM product_ratings pr 
                          JOIN users u ON pr.user_id = u.id 
                          WHERE pr.product_id = ? 
                          ORDER BY pr.created_at DESC LIMIT 5");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();

    $recent_ratings = [];
    while ($row = $result->fetch_assoc()) {
        $recent_ratings[] = [
            'id' => intval($row['id']),
            'rating' => intval($row['rating']),
            'review' => $row['review'],
            'user_name' => $row['user_name'],
            'created_at' => $row['created_at']
        ];
    }
    $product['recent_ratings'] = $recent_ratings;

    // Convert numeric fields to appropriate types
    $product['id'] = (int)$product['id'];
    $product['vendor_id'] = (int)$product['vendor_id'];
    $product['category_id'] = (int)$product['category_id'];
    $product['price'] = (float)$product['price'];
    $product['stock'] = (int)$product['stock'];

    // Replace null values with appropriate defaults
    $product['description'] = $product['description'] ?? '';
    $product['image_url'] = $product['image_url'] ?? '';
    $product['category_name'] = $product['category_name'] ?? '';
    $product['category_description'] = $product['category_description'] ?? '';
    $product['vendor_name'] = $product['vendor_name'] ?? '';

    // Include the full URL for the image
    if (!empty($product['image_url']) && strpos($product['image_url'], 'http') !== 0) {
        $host = $_SERVER['HTTP_HOST'];
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
        $product['image_url'] = $protocol . '://' . $host . $product['image_url'];
    }

    response(200, "Product retrieved successfully", $product);
}

function getAllProducts()
{
    global $conn;

    $query = "SELECT p.*, c.name as category_name, v.business_name as vendor_name 
             FROM products p 
             JOIN categories c ON p.category_id = c.id 
             JOIN vendors v ON p.vendor_id = v.id 
             ORDER BY p.id DESC";

    $result = $conn->query($query);
    $products = [];

    while ($row = $result->fetch_assoc()) {
        // Get product ratings
        $product_id = $row['id'];
        $stmt = $conn->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count 
                              FROM product_ratings 
                              WHERE product_id = ?");
        $stmt->bind_param("i", $product_id);
        $stmt->execute();
        $rating_result = $stmt->get_result();
        $rating_stats = $rating_result->fetch_assoc();

        // Add rating information to product
        $row['avg_rating'] = $rating_result->num_rows > 0 && $rating_stats['rating_count'] > 0
            ? round(floatval($rating_stats['avg_rating']), 1)
            : 0;
        $row['rating_count'] = intval($rating_stats['rating_count']);

        // Convert numeric fields to appropriate types
        $row['id'] = (int)$row['id'];
        $row['vendor_id'] = (int)$row['vendor_id'];
        $row['category_id'] = (int)$row['category_id'];
        $row['price'] = (float)$row['price'];
        $row['stock'] = (int)$row['stock'];

        // Replace null values with appropriate defaults
        $row['description'] = $row['description'] ?? '';
        $row['image_url'] = $row['image_url'] ?? '';
        $row['category_name'] = $row['category_name'] ?? '';
        $row['vendor_name'] = $row['vendor_name'] ?? '';

        // Include the full URL for the image
        if (!empty($row['image_url']) && strpos($row['image_url'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['image_url'] = $protocol . '://' . $host . $row['image_url'];
        }

        $products[] = $row;
    }

    response(200, "Products retrieved successfully", $products);
}

function getProductsByCategory($category_id)
{
    global $conn;

    $stmt = $conn->prepare("SELECT p.*, c.name as category_name, v.business_name as vendor_name 
                           FROM products p 
                           JOIN categories c ON p.category_id = c.id 
                           JOIN vendors v ON p.vendor_id = v.id 
                           WHERE p.category_id = ?
                           ORDER BY p.id DESC");
    $stmt->bind_param("i", $category_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $products = [];
    while ($row = $result->fetch_assoc()) {
        // Get product ratings
        $product_id = $row['id'];
        $stmt2 = $conn->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count 
                              FROM product_ratings 
                              WHERE product_id = ?");
        $stmt2->bind_param("i", $product_id);
        $stmt2->execute();
        $rating_result = $stmt2->get_result();
        $rating_stats = $rating_result->fetch_assoc();

        // Add rating information to product
        $row['avg_rating'] = $rating_result->num_rows > 0 && $rating_stats['rating_count'] > 0
            ? round(floatval($rating_stats['avg_rating']), 1)
            : 0;
        $row['rating_count'] = intval($rating_stats['rating_count']);

        // Convert numeric fields to appropriate types
        $row['id'] = (int)$row['id'];
        $row['vendor_id'] = (int)$row['vendor_id'];
        $row['category_id'] = (int)$row['category_id'];
        $row['price'] = (float)$row['price'];
        $row['stock'] = (int)$row['stock'];

        // Replace null values with appropriate defaults
        $row['description'] = $row['description'] ?? '';
        $row['image_url'] = $row['image_url'] ?? '';
        $row['category_name'] = $row['category_name'] ?? '';
        $row['vendor_name'] = $row['vendor_name'] ?? '';

        // Include the full URL for the image
        if (!empty($row['image_url']) && strpos($row['image_url'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['image_url'] = $protocol . '://' . $host . $row['image_url'];
        }

        $products[] = $row;

        // Close the statement
        $stmt2->close();
    }

    response(200, "Products retrieved successfully", $products);
}

function getProductsByVendor($vendor_id)
{
    global $conn;

    $stmt = $conn->prepare("SELECT p.*, c.name as category_name, v.business_name as vendor_name 
                           FROM products p 
                           JOIN categories c ON p.category_id = c.id 
                           JOIN vendors v ON p.vendor_id = v.id 
                           WHERE p.vendor_id = ?
                           ORDER BY p.id DESC");
    $stmt->bind_param("i", $vendor_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $products = [];
    while ($row = $result->fetch_assoc()) {
        // Get product ratings
        $product_id = $row['id'];
        $stmt2 = $conn->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count 
                              FROM product_ratings 
                              WHERE product_id = ?");
        $stmt2->bind_param("i", $product_id);
        $stmt2->execute();
        $rating_result = $stmt2->get_result();
        $rating_stats = $rating_result->fetch_assoc();

        // Add rating information to product
        $row['avg_rating'] = $rating_result->num_rows > 0 && $rating_stats['rating_count'] > 0
            ? round(floatval($rating_stats['avg_rating']), 1)
            : 0;
        $row['rating_count'] = intval($rating_stats['rating_count']);

        // Convert numeric fields to appropriate types
        $row['id'] = (int)$row['id'];
        $row['vendor_id'] = (int)$row['vendor_id'];
        $row['category_id'] = (int)$row['category_id'];
        $row['price'] = (float)$row['price'];
        $row['stock'] = (int)$row['stock'];

        // Replace null values with appropriate defaults
        $row['description'] = $row['description'] ?? '';
        $row['image_url'] = $row['image_url'] ?? '';
        $row['category_name'] = $row['category_name'] ?? '';
        $row['vendor_name'] = $row['vendor_name'] ?? '';

        // Include the full URL for the image
        if (!empty($row['image_url']) && strpos($row['image_url'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['image_url'] = $protocol . '://' . $host . $row['image_url'];
        }

        $products[] = $row;

        // Close the statement
        $stmt2->close();
    }

    response(200, "Products retrieved successfully", $products);
}
