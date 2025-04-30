<?php
// Start output buffering to prevent headers already sent error
ob_start();

include 'includes/header.php';
include '../backend/db.php';

// Create uploads directory if it doesn't exist
$upload_dir = '../uploads/products/';
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0777, true);
}

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Add or update product
    if (isset($_POST['action'])) {
        $name = trim($_POST['name']);
        $description = trim($_POST['description']);
        $price = floatval($_POST['price']);
        $stock = intval($_POST['stock']);
        $category_id = intval($_POST['category_id']);
        $vendor_id = intval($_POST['vendor_id']);
        $image_url = !empty($_POST['image_url']) ? trim($_POST['image_url']) : null;
        
        // Handle image upload
        $image_uploaded = false;
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
                    $image_url = '/Glamup/uploads/products/' . $new_file_name;
                    $image_uploaded = true;
                } else {
                    $_SESSION['error_message'] = "Error uploading image.";
                }
            } else {
                $_SESSION['error_message'] = "Only JPG, JPEG, PNG and GIF files are allowed.";
            }
        }
        
        if ($_POST['action'] === 'add') {
            // Insert new product
            $query = "INSERT INTO products (name, description, price, stock, category_id, vendor_id, image_url) 
                      VALUES (?, ?, ?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ssdiiss", $name, $description, $price, $stock, $category_id, $vendor_id, $image_url);
            
            if ($stmt->execute()) {
                $_SESSION['success_message'] = "Product added successfully!";
            } else {
                $_SESSION['error_message'] = "Error adding product: " . $conn->error;
            }
            $stmt->close();
        } 
        elseif ($_POST['action'] === 'edit') {
            // Update existing product
            $id = intval($_POST['id']);
            
            // Get current image if no new image is uploaded
            if (!$image_uploaded && empty($image_url)) {
                $query = "SELECT image_url FROM products WHERE id = ?";
                $stmt = $conn->prepare($query);
                $stmt->bind_param("i", $id);
                $stmt->execute();
                $result = $stmt->get_result();
                if ($row = $result->fetch_assoc()) {
                    $image_url = $row['image_url'];
                }
                $stmt->close();
            }
            
            $query = "UPDATE products SET name = ?, description = ?, price = ?, 
                      stock = ?, category_id = ?, vendor_id = ?, image_url = ? 
                      WHERE id = ?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ssdiissi", $name, $description, $price, $stock, $category_id, $vendor_id, $image_url, $id);
            
            if ($stmt->execute()) {
                $_SESSION['success_message'] = "Product updated successfully!";
            } else {
                $_SESSION['error_message'] = "Error updating product: " . $conn->error;
            }
            $stmt->close();
        }
    }
    
    // Delete product
    elseif (isset($_POST['delete'])) {
        $id = intval($_POST['delete_id']);
        
        // Get image URL to delete the file
        $query = "SELECT image_url FROM products WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($row = $result->fetch_assoc() && !empty($row['image_url'])) {
            $image_path = $_SERVER['DOCUMENT_ROOT'] . $row['image_url'];
            if (file_exists($image_path)) {
                unlink($image_path);
            }
        }
        $stmt->close();
        
        // Delete product record
        $query = "DELETE FROM products WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            $_SESSION['success_message'] = "Product deleted successfully!";
        } else {
            $_SESSION['error_message'] = "Error deleting product: " . $conn->error;
        }
        $stmt->close();
    }
    
    // Redirect to avoid form resubmission
    header('Location: products.php');
    exit;
}

// Get products with category and vendor name
$products = [];
$query = "SELECT p.*, c.name as category_name, v.business_name as vendor_name 
          FROM products p 
          JOIN categories c ON p.category_id = c.id 
          JOIN vendors v ON p.vendor_id = v.id 
          ORDER BY p.id DESC";
$result = $conn->query($query);
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $products[] = $row;
    }
}

// Get categories for the form
$categories = [];
$result = $conn->query("SELECT * FROM categories ORDER BY name");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $categories[] = $row;
    }
}

// Get vendors for the form
$vendors = [];
$result = $conn->query("SELECT v.*, u.name as user_name FROM vendors v JOIN users u ON v.user_id = u.id ORDER BY business_name");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $vendors[] = $row;
    }
}
?>

<h1 class="h2 dashboard-title">Manage Products</h1>

<?php if (isset($_SESSION['success_message'])): ?>
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        <?php 
        echo $_SESSION['success_message']; 
        unset($_SESSION['success_message']);
        ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif; ?>

<?php if (isset($_SESSION['error_message'])): ?>
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <?php 
        echo $_SESSION['error_message']; 
        unset($_SESSION['error_message']);
        ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif; ?>

<div class="d-flex justify-content-end mb-3">
    <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addProductModal">
        <i class="bi bi-plus-circle"></i> Add New Product
    </button>
</div>

<div class="card">
    <div class="card-body">
        <div class="table-responsive">
            <table id="productsTable" class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Image</th>
                        <th>Name</th>
                        <th>Category</th>
                        <th>Vendor</th>
                        <th>Price</th>
                        <th>Stock</th>
                        <th>Rating</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($products as $product): ?>
                        <tr>
                            <td><?php echo $product['id']; ?></td>
                            <td>
                                <?php if (!empty($product['image_url'])): ?>
                                    <img src="<?php echo htmlspecialchars($product['image_url']); ?>" alt="<?php echo htmlspecialchars($product['name']); ?>" width="50">
                                <?php else: ?>
                                    <span class="text-muted">No image</span>
                                <?php endif; ?>
                            </td>
                            <td><?php echo htmlspecialchars($product['name']); ?></td>
                            <td><?php echo htmlspecialchars($product['category_name']); ?></td>
                            <td><?php echo htmlspecialchars($product['vendor_name']); ?></td>
                            <td>Rs. <?php echo number_format($product['price'], 2); ?></td>
                            <td><?php echo $product['stock']; ?></td>
                            <td>
                                <?php 
                                // Get product ratings
                                $stmt = $conn->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count FROM product_ratings WHERE product_id = ?");
                                $stmt->bind_param("i", $product['id']);
                                $stmt->execute();
                                $rating_result = $stmt->get_result();
                                $rating_stats = $rating_result->fetch_assoc();
                                $avg_rating = $rating_stats['rating_count'] > 0 ? round($rating_stats['avg_rating'], 1) : 0;
                                $rating_count = $rating_stats['rating_count'];
                                ?>
                                <div class="d-flex align-items-center">
                                    <div class="me-2">
                                        <?php if ($rating_count > 0): ?>
                                            <span class="rating-stars">
                                                <?php
                                                $full_stars = floor($avg_rating);
                                                $half_star = $avg_rating - $full_stars >= 0.5;
                                                
                                                for ($i = 0; $i < $full_stars; $i++) {
                                                    echo '<i class="bi bi-star-fill text-warning"></i>';
                                                }
                                                
                                                if ($half_star) {
                                                    echo '<i class="bi bi-star-half text-warning"></i>';
                                                    $i++;
                                                }
                                                
                                                for (; $i < 5; $i++) {
                                                    echo '<i class="bi bi-star text-warning"></i>';
                                                }
                                                ?>
                                            </span>
                                            <span class="small text-muted">(<?php echo $rating_count; ?>)</span>
                                        <?php else: ?>
                                            <span class="text-muted">No ratings</span>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <button type="button" class="btn btn-sm btn-outline-primary" 
                                        onclick="editProduct(<?php echo $product['id']; ?>, 
                                                '<?php echo addslashes($product['name']); ?>', 
                                                '<?php echo addslashes($product['description']); ?>', 
                                                <?php echo $product['price']; ?>, 
                                                <?php echo $product['stock']; ?>, 
                                                <?php echo $product['category_id']; ?>, 
                                                <?php echo $product['vendor_id']; ?>, 
                                                '<?php echo addslashes($product['image_url'] ?? ''); ?>')">
                                    <i class="bi bi-pencil"></i>
                                </button>
                                <button type="button" class="btn btn-sm btn-outline-info" 
                                        onclick="viewRatings(<?php echo $product['id']; ?>, '<?php echo addslashes($product['name']); ?>')">
                                    <i class="bi bi-star"></i>
                                </button>
                                <button type="button" class="btn btn-sm btn-outline-danger" 
                                        onclick="confirmDelete(<?php echo $product['id']; ?>, '<?php echo addslashes($product['name']); ?>')">
                                    <i class="bi bi-trash"></i>
                                </button>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Add Product Modal -->
<div class="modal fade" id="addProductModal" tabindex="-1" aria-labelledby="addProductModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="addProductModalLabel">Add New Product</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form method="post" action="" enctype="multipart/form-data">
                <input type="hidden" name="action" value="add">
                <div class="modal-body">
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="name" class="form-label">Product Name</label>
                            <input type="text" class="form-control" id="name" name="name" required>
                        </div>
                        <div class="col-md-6">
                            <label for="price" class="form-label">Price (Rs. )</label>
                            <input type="number" class="form-control" id="price" name="price" step="0.01" min="0" required>
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="category_id" class="form-label">Category</label>
                            <select class="form-select" id="category_id" name="category_id" required>
                                <option value="">Select Category</option>
                                <?php foreach ($categories as $category): ?>
                                    <option value="<?php echo $category['id']; ?>"><?php echo htmlspecialchars($category['name']); ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label for="vendor_id" class="form-label">Vendor</label>
                            <select class="form-select" id="vendor_id" name="vendor_id" required>
                                <option value="">Select Vendor</option>
                                <?php foreach ($vendors as $vendor): ?>
                                    <option value="<?php echo $vendor['id']; ?>"><?php echo htmlspecialchars($vendor['business_name']); ?> (<?php echo htmlspecialchars($vendor['user_name']); ?>)</option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="stock" class="form-label">Stock</label>
                            <input type="number" class="form-control" id="stock" name="stock" min="0" required>
                        </div>
                        <div class="col-md-6">
                            <label for="product_image" class="form-label">Product Image</label>
                            <input type="file" class="form-control" id="product_image" name="product_image" accept="image/*">
                            <div class="form-text">Upload an image file (JPG, JPEG, PNG, GIF)</div>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label for="image_url" class="form-label">Image URL (optional if uploading image)</label>
                        <input type="url" class="form-control" id="image_url" name="image_url">
                        <div class="form-text">Enter a URL or upload an image above</div>
                    </div>
                    <div class="mb-3">
                        <label for="description" class="form-label">Description</label>
                        <textarea class="form-control" id="description" name="description" rows="3" required></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Product</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit Product Modal -->
<div class="modal fade" id="editProductModal" tabindex="-1" aria-labelledby="editProductModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editProductModalLabel">Edit Product</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form method="post" action="" enctype="multipart/form-data">
                <input type="hidden" name="action" value="edit">
                <input type="hidden" id="edit_id" name="id" value="">
                <div class="modal-body">
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="edit_name" class="form-label">Product Name</label>
                            <input type="text" class="form-control" id="edit_name" name="name" required>
                        </div>
                        <div class="col-md-6">
                            <label for="edit_price" class="form-label">Price (Rs. )</label>
                            <input type="number" class="form-control" id="edit_price" name="price" step="0.01" min="0" required>
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="edit_category_id" class="form-label">Category</label>
                            <select class="form-select" id="edit_category_id" name="category_id" required>
                                <option value="">Select Category</option>
                                <?php foreach ($categories as $category): ?>
                                    <option value="<?php echo $category['id']; ?>"><?php echo htmlspecialchars($category['name']); ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label for="edit_vendor_id" class="form-label">Vendor</label>
                            <select class="form-select" id="edit_vendor_id" name="vendor_id" required>
                                <option value="">Select Vendor</option>
                                <?php foreach ($vendors as $vendor): ?>
                                    <option value="<?php echo $vendor['id']; ?>"><?php echo htmlspecialchars($vendor['business_name']); ?> (<?php echo htmlspecialchars($vendor['user_name']); ?>)</option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="edit_stock" class="form-label">Stock</label>
                            <input type="number" class="form-control" id="edit_stock" name="stock" min="0" required>
                        </div>
                        <div class="col-md-6">
                            <label for="edit_product_image" class="form-label">Product Image</label>
                            <input type="file" class="form-control" id="edit_product_image" name="product_image" accept="image/*">
                            <div class="form-text">Upload a new image or keep existing</div>
                        </div>
                    </div>
                    <div class="mb-3">
                        <div id="current_image_container" class="mb-2">
                            <label class="form-label">Current Image:</label>
                            <div id="current_image"></div>
                        </div>
                        <label for="edit_image_url" class="form-label">Image URL (optional if uploading image)</label>
                        <input type="url" class="form-control" id="edit_image_url" name="image_url">
                        <div class="form-text">Enter a URL or upload an image above</div>
                    </div>
                    <div class="mb-3">
                        <label for="edit_description" class="form-label">Description</label>
                        <textarea class="form-control" id="edit_description" name="description" rows="3" required></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Update Product</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Delete Product Modal -->
<div class="modal fade" id="deleteProductModal" tabindex="-1" aria-labelledby="deleteProductModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="deleteProductModalLabel">Confirm Delete</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <p>Are you sure you want to delete the product: <strong id="delete-product-name"></strong>?</p>
                <p class="text-danger">This action cannot be undone.</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <form method="post" action="">
                    <input type="hidden" name="delete" value="1">
                    <input type="hidden" id="delete_id" name="delete_id" value="">
                    <button type="submit" class="btn btn-danger">Delete</button>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- View Ratings Modal -->
<div class="modal fade" id="viewRatingsModal" tabindex="-1" aria-labelledby="viewRatingsModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="viewRatingsModalLabel">Ratings for: <span id="rated-product-name"></span></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="text-center mb-3">
                    <div class="d-inline-block p-3 rounded bg-light">
                        <h2 id="avg-rating">0.0</h2>
                        <div id="overall-stars" class="mb-2">
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                            <i class="bi bi-star text-warning"></i>
                        </div>
                        <span id="rating-count" class="text-muted">0 ratings</span>
                    </div>
                </div>
                <div id="ratings-container">
                    <div class="alert alert-info" id="no-ratings-message">
                        This product has no ratings yet.
                    </div>
                    <div id="ratings-list" class="list-group">
                        <!-- Ratings will be loaded here -->
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<?php include 'includes/footer.php'; ?>

<script>
$(document).ready(function() {
    // Initialize DataTable
    $('#productsTable').DataTable({
        "order": [[0, "desc"]]
    });
});

// Function to populate and show edit modal
function editProduct(id, name, description, price, stock, category_id, vendor_id, image_url) {
    $('#edit_id').val(id);
    $('#edit_name').val(name);
    $('#edit_description').val(description);
    $('#edit_price').val(price);
    $('#edit_stock').val(stock);
    $('#edit_category_id').val(category_id);
    $('#edit_vendor_id').val(vendor_id);
    $('#edit_image_url').val(image_url);
    
    // Show current image if available
    if (image_url) {
        $('#current_image').html('<img src="' + image_url + '" alt="Current Image" style="max-width: 100px; max-height: 100px;">');
        $('#current_image_container').show();
    } else {
        $('#current_image').html('<span class="text-muted">No image available</span>');
        $('#current_image_container').show();
    }
    
    $('#editProductModal').modal('show');
}

// Function to populate and show delete confirmation modal
function confirmDelete(id, name) {
    $('#delete_id').val(id);
    $('#delete-product-name').text(name);
    $('#deleteProductModal').modal('show');
}

// Function to view ratings
function viewRatings(productId, productName) {
    $('#rated-product-name').text(productName);
    
    // Clear previous ratings
    $('#ratings-list').empty();
    
    // Show loading state
    $('#ratings-container').html('<div class="text-center"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div></div>');
    
    // Fetch ratings from API
    $.ajax({
        url: '../backend/ratings.php?product_id=' + productId,
        method: 'GET',
        success: function(response) {
            if (response.status === 'success') {
                // Update average rating and count
                const avgRating = response.data.avg_rating;
                const ratingCount = response.data.rating_count;
                
                $('#avg-rating').text(avgRating);
                $('#rating-count').text(ratingCount + (ratingCount === 1 ? ' rating' : ' ratings'));
                
                // Update stars
                updateStars('#overall-stars', avgRating);
                
                // Display ratings
                const ratings = response.data.ratings;
                if (ratings.length === 0) {
                    $('#ratings-container').html('<div class="alert alert-info">This product has no ratings yet.</div>');
                } else {
                    let ratingsHtml = '<div class="list-group">';
                    
                    ratings.forEach(function(rating) {
                        const ratingDate = new Date(rating.created_at).toLocaleDateString();
                        
                        ratingsHtml += `
                            <div class="list-group-item">
                                <div class="d-flex justify-content-between align-items-center">
                                    <strong>${rating.user_name}</strong>
                                    <small class="text-muted">${ratingDate}</small>
                                </div>
                                <div class="mb-1">`;
                        
                        // Add stars
                        for (let i = 1; i <= 5; i++) {
                            if (i <= rating.rating) {
                                ratingsHtml += '<i class="bi bi-star-fill text-warning"></i>';
                            } else {
                                ratingsHtml += '<i class="bi bi-star text-warning"></i>';
                            }
                        }
                        
                        ratingsHtml += `</div>`;
                        
                        if (rating.review) {
                            ratingsHtml += `<p class="mb-0">${rating.review}</p>`;
                        }
                        
                        ratingsHtml += `</div>`;
                    });
                    
                    ratingsHtml += '</div>';
                    $('#ratings-container').html(ratingsHtml);
                }
            } else {
                $('#ratings-container').html('<div class="alert alert-danger">Error loading ratings: ' + response.message + '</div>');
            }
        },
        error: function() {
            $('#ratings-container').html('<div class="alert alert-danger">Error fetching ratings. Please try again.</div>');
        }
    });
    
    $('#viewRatingsModal').modal('show');
}

// Helper function to update star display based on rating
function updateStars(selector, rating) {
    const stars = $(selector).children();
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating - fullStars >= 0.5;
    
    stars.removeClass('bi-star-fill bi-star-half bi-star').addClass('bi-star');
    
    // Fill the stars according to the rating
    for (let i = 0; i < fullStars; i++) {
        $(stars[i]).removeClass('bi-star').addClass('bi-star-fill');
    }
    
    if (hasHalfStar && fullStars < 5) {
        $(stars[fullStars]).removeClass('bi-star').addClass('bi-star-half');
    }
}
</script>

<?php
// End output buffering and send output to browser
$conn->close();
ob_end_flush();
?>
