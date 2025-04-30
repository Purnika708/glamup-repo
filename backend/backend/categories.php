<?php
include 'cors.php';
include 'db.php';
include 'jwt.php';
include 'utils.php';
session_start();
header("Content-Type: application/json");

$request_method = $_SERVER["REQUEST_METHOD"];

if ($request_method === "POST" || $request_method === "PUT" || $request_method === "DELETE") {
    $data = json_decode(file_get_contents("php://input"), true);
    $token = getBearerToken();
    $user = validateJWT($token);

    if ($user->role !== 'admin') {
        response(403, "Forbidden: Only admins can perform this action");
    }

    switch ($request_method) {
        case "POST":
            addCategory($data);
            break;
        case "PUT":
            updateCategory($data);
            break;
        case "DELETE":
            deleteCategory($data);
            break;
        default:
            response(405, "Method Not Allowed");
    }
} elseif ($request_method === "GET") {
    if (isset($_GET['id'])) {
        getCategory($_GET['id']);
    } else {
        getCategories();
    }
} else {
    response(405, "Method Not Allowed");
}

function addCategory($data) {
    global $conn;
    $name = $data["name"];
    $description = $data["description"];

    $stmt = executeQuery("INSERT INTO categories (name, description) VALUES (?, ?)", [$name, $description], "ss");
    response(200, "Category added successfully");
}

function updateCategory($data) {
    global $conn;
    $id = $data["id"];
    $name = $data["name"];
    $description = $data["description"];

    $stmt = executeQuery("UPDATE categories SET name = ?, description = ? WHERE id = ?", [$name, $description, $id], "ssi");
    response(200, "Category updated successfully");
}

function deleteCategory($data) {
    global $conn;
    $id = $data["id"];

    $stmt = executeQuery("DELETE FROM categories WHERE id = ?", [$id], "i");
    response(200, "Category deleted successfully");
}

function getCategory($id) {
    global $conn;
    $stmt = executeQuery("SELECT * FROM categories WHERE id = ?", [$id], "i");
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        response(200, "Category found", $row);
    } else {
        response(404, "Category not found");
    }
}

function getCategories() {
    global $conn;
    $stmt = executeQuery("SELECT * FROM categories", [], null);
    $result = $stmt->get_result();
    $categories = [];
    while ($row = $result->fetch_assoc()) {
        $categories[] = $row;
    }
    response(200, "Categories retrieved", $categories);
}
?>