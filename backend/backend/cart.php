<?php
include 'cors.php';
include 'db.php';
include 'jwt.php';
include 'utils.php';
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
            addCartItem($data, $user->user_id);
            break;
        case "PUT":
            updateCartItem($data, $user->user_id);
            break;
        case "PATCH":
            patchCartItem($data, $user->user_id);
            break;
        case "DELETE":
            deleteCartItem($data, $user->user_id);
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
        getCartItem($_GET['id'], $user->user_id);
    } else {
        getCartItems($user->user_id);
    }
} else {
    response(405, "Method Not Allowed");
}

function addCartItem($data, $user_id) {
    global $conn;
    $product_id = $data["product_id"];
    $quantity = $data["quantity"];

    // Check if the product belongs to the user
    $stmt = executeQuery("SELECT * FROM products WHERE id = ? AND vendor_id = ?", [$product_id, $user_id], "ii");
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        response(403, "Forbidden: Users cannot add their own products to the cart");
    }

    // Check if product is already in cart
    $stmt = executeQuery("SELECT * FROM cart WHERE user_id = ? AND product_id = ?", [$user_id, $product_id], "ii");
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        // Product already exists in cart, update quantity instead
        $cart_item = $result->fetch_assoc();
        $new_quantity = $cart_item['quantity'] + $quantity;
        $stmt = executeQuery("UPDATE cart SET quantity = ? WHERE user_id = ? AND product_id = ?", 
                            [$new_quantity, $user_id, $product_id], "iii");
        response(200, "Cart item quantity updated successfully");
    } else {
        // Product not in cart, add as new item
        $stmt = executeQuery("INSERT INTO cart (user_id, product_id, quantity) VALUES (?, ?, ?)", 
                            [$user_id, $product_id, $quantity], "iii");
        response(200, "Cart item added successfully");
    }
}

function updateCartItem($data, $user_id) {
    global $conn;
    $id = $data["id"];
    $product_id = $data["product_id"];
    $quantity = $data["quantity"];

    $stmt = executeQuery("SELECT * FROM cart WHERE id = ? AND user_id = ?", [$id, $user_id], "ii");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(403, "Forbidden: Users can only update their own cart items");
    }

    $stmt = executeQuery("UPDATE cart SET product_id = ?, quantity = ? WHERE id = ?", [$product_id, $quantity, $id], "iii");
    response(200, "Cart item updated successfully");
}

function patchCartItem($data, $user_id) {
    global $conn;
    $id = $data["id"];
    $fields = [];
    $params = [];
    $types = "";

    if (isset($data["product_id"])) {
        $fields[] = "product_id = ?";
        $params[] = $data["product_id"];
        $types .= "i";
    }
    if (isset($data["quantity"])) {
        $fields[] = "quantity = ?";
        $params[] = $data["quantity"];
        $types .= "i";
    }

    $stmt = executeQuery("SELECT * FROM cart WHERE id = ? AND user_id = ?", [$id, $user_id], "ii");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(403, "Forbidden: Users can only update their own cart items");
    }

    $params[] = $id;
    $types .= "i";
    $query = "UPDATE cart SET " . implode(", ", $fields) . " WHERE id = ?";
    $stmt = executeQuery($query, $params, $types);
    response(200, "Cart item updated successfully");
}

function deleteCartItem($data, $user_id) {
    global $conn;
    $id = $data["id"];
    $stmt = executeQuery("SELECT * FROM cart WHERE id = ? AND user_id = ?", [$id, $user_id], "ii");
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        response(403, "Forbidden: Users can only delete their own cart items");
    }

    $stmt = executeQuery("DELETE FROM cart WHERE id = ?", [$id], "i");
    response(200, "Cart item deleted successfully");
}

function getCartItem($id, $user_id) {
    global $conn;
    $stmt = executeQuery("SELECT cart.*, products.name AS product_name, products.image_url AS product_image FROM cart JOIN products ON cart.product_id = products.id WHERE cart.id = ? AND cart.user_id = ?", [$id, $user_id], "ii");
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        // Include the full URL for the image
        if (!empty($row['product_image']) && strpos($row['product_image'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['product_image'] = $protocol . '://' . $host . $row['product_image'];
        }
        
        response(200, "Cart item found", $row);
    } else {
        response(404, "Cart item not found");
    }
}

function getCartItems($user_id) {
    global $conn;
    $stmt = executeQuery("SELECT cart.*, products.name AS product_name, price AS product_price, products.image_url AS product_image FROM cart JOIN products ON cart.product_id = products.id WHERE cart.user_id = ?", [$user_id], "i");
    $result = $stmt->get_result();
    $cart_items = [];
    while ($row = $result->fetch_assoc()) {
        // Include the full URL for the image
        if (!empty($row['product_image']) && strpos($row['product_image'], 'http') !== 0) {
            $host = $_SERVER['HTTP_HOST'];
            $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
            $row['product_image'] = $protocol . '://' . $host . $row['product_image'];
        }
        $cart_items[] = $row;
    }
    response(200, "Cart items retrieved", $cart_items);
}
?>