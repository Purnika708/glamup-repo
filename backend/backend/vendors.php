<?php
include 'cors.php';
include 'db.php';
include 'jwt.php';
include 'utils.php';
header("Content-Type: application/json");

$request_method = $_SERVER["REQUEST_METHOD"];

if ($request_method === "GET") {
    // Check if a vendor ID is provided
    if (isset($_GET['id'])) {
        // Get vendor details with products
        getVendorDetails($_GET['id']);
    } else {
        // List all vendors
        getAllVendors();
    }
} else {
    response(405, "Method Not Allowed");
}

/**
 * Get a list of all vendors
 */
function getAllVendors() {
    global $conn;
    
    $query = "SELECT v.id, v.business_name, v.description, v.created_at, 
                    u.name as owner_name,
                    (SELECT COUNT(*) FROM products p WHERE p.vendor_id = v.id) as products_count
             FROM vendors v 
             JOIN users u ON v.user_id = u.id
             ORDER BY v.business_name";
    
    $result = $conn->query($query);
    $vendors = [];
    
    while ($row = $result->fetch_assoc()) {
        // Convert numeric fields to appropriate types
        $row['id'] = (int)$row['id'];
        $row['products_count'] = (int)$row['products_count'];
        
        // Replace null values with appropriate defaults
        $row['business_name'] = $row['business_name'] ?? '';
        $row['description'] = $row['description'] ?? '';
        $row['owner_name'] = $row['owner_name'] ?? '';
        
        // Add to vendors array
        $vendors[] = $row;
    }
    
    response(200, "Vendors retrieved successfully", $vendors);
}

/**
 * Get detailed information about a specific vendor including their products
 * 
 * @param int $vendor_id The ID of the vendor to retrieve
 */
function getVendorDetails($vendor_id) {
    global $conn;
    
    // First, get vendor information
    $stmt = $conn->prepare("SELECT v.id, v.business_name, v.description, v.created_at, 
                                  u.name as owner_name, u.email as owner_email
                           FROM vendors v 
                           JOIN users u ON v.user_id = u.id
                           WHERE v.id = ?");
    $stmt->bind_param("i", $vendor_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        response(404, "Vendor not found");
    }
    
    $vendor = $result->fetch_assoc();
    $stmt->close();
    
    // Convert numeric fields
    $vendor['id'] = (int)$vendor['id'];
    
    // Replace null values with appropriate defaults
    $vendor['business_name'] = $vendor['business_name'] ?? '';
    $vendor['description'] = $vendor['description'] ?? '';
    $vendor['owner_name'] = $vendor['owner_name'] ?? '';
    $vendor['owner_email'] = $vendor['owner_email'] ?? '';
    
    // Now get vendor products
    $stmt = $conn->prepare("SELECT p.id, p.name, p.description, p.price, p.stock, 
                                  p.image_url, p.created_at, 
                                  c.name as category_name, c.id as category_id, c.description as category_description,
                                  v.business_name as vendor_name, 
                                  (SELECT AVG(r.rating) FROM product_ratings r WHERE r.product_id = p.id) as avg_rating,
                                  (SELECT COUNT(r.id) FROM product_ratings r WHERE r.product_id = p.id) as rating_count
                           FROM products p 
                           JOIN categories c ON p.category_id = c.id
                           JOIN vendors v ON p.vendor_id = v.id
                           WHERE p.vendor_id = ?
                           ORDER BY p.name");
    $stmt->bind_param("i", $vendor_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $products = [];
    while ($row = $result->fetch_assoc()) {
        // Convert numeric fields to appropriate types
        $row['id'] = (int)$row['id'];
        $row['price'] = (float)$row['price']; 
        $row['stock'] = (int)$row['stock'];
        $row['category_id'] = (int)$row['category_id'];
        $row['vendor_id'] = (int)$vendor_id;
        $row['discount'] = (int)($row['discount'] ?? 0);
        $row['avg_rating'] = isset($row['avg_rating']) ? (float)$row['avg_rating'] : 0.0;
        $row['rating_count'] = (int)($row['rating_count'] ?? 0);
        
        // Replace null values with appropriate defaults
        $row['name'] = $row['name'] ?? '';
        $row['description'] = $row['description'] ?? '';
        $row['image_url'] = $row['image_url'] ?? '';
        $row['category_name'] = $row['category_name'] ?? '';
        $row['category_description'] = $row['category_description'] ?? '';
        $row['vendor_name'] = $row['vendor_name'] ?? '';
        $row['created_at'] = $row['created_at'] ?? '';
        
        // Include the full URL for the image
        if (!empty($row['image_url']) && strpos($row['image_url'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['image_url'] = $protocol . '://' . $host . $row['image_url'];
        }
        
        $products[] = $row;
    }
    $stmt->close();
    
    // Add products to vendor data
    $vendor['products'] = $products;
    
    // Get product count
    $vendor['product_count'] = count($products);
    
    response(200, "Vendor details retrieved successfully", $vendor);

}


?>