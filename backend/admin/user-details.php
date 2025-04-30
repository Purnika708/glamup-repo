<?php
// Start output buffering to prevent headers already sent error
ob_start();

include 'includes/header.php';
include '../backend/db.php';

// Check if user ID is provided
if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    echo '<div class="alert alert-danger">Invalid user ID</div>';
    include 'includes/footer.php';
    exit;
}

$user_id = intval($_GET['id']);

// Get user details
$user = null;
$query = "SELECT u.*, 
          CASE WHEN v.id IS NOT NULL THEN v.business_name ELSE NULL END AS business_name,
          CASE WHEN a.id IS NOT NULL THEN 'Yes' ELSE 'No' END AS is_admin,
          v.description AS vendor_description
          FROM users u
          LEFT JOIN vendors v ON u.id = v.user_id
          LEFT JOIN admins a ON u.id = a.user_id
          WHERE u.id = ?";
          
$stmt = $conn->prepare($query);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo '<div class="alert alert-danger">User not found</div>';
    include 'includes/footer.php';
    exit;
}

$user = $result->fetch_assoc();

// Get user's addresses
$addresses = [];
$query = "SELECT * FROM addresses WHERE user_id = ? ORDER BY created_at DESC";
$stmt = $conn->prepare($query);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

while ($row = $result->fetch_assoc()) {
    $addresses[] = $row;
}

// Get user's orders
$orders = [];
$query = "SELECT o.*, p.status as payment_status, p.payment_method, p.transaction_id
          FROM orders o
          LEFT JOIN payments p ON o.id = p.order_id
          WHERE o.user_id = ?
          ORDER BY o.created_at DESC";
          
$stmt = $conn->prepare($query);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

while ($row = $result->fetch_assoc()) {
    $orders[] = $row;
}

// Get vendor products if user is a vendor
$vendor_products = [];
if ($user['role'] === 'vendor') {
    // First get vendor ID
    $query = "SELECT id FROM vendors WHERE user_id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $vendor = $result->fetch_assoc();
        $vendor_id = $vendor['id'];
        
        // Get vendor products
        $query = "SELECT p.*, c.name as category_name 
                  FROM products p 
                  JOIN categories c ON p.category_id = c.id 
                  WHERE p.vendor_id = ? 
                  ORDER BY p.id DESC";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $vendor_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        while ($row = $result->fetch_assoc()) {
            $vendor_products[] = $row;
        }
    }
}

$conn->close();
?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h1 class="h2 dashboard-title mb-0">User Details</h1>
    <a href="users.php" class="btn btn-outline-secondary">
        <i class="bi bi-arrow-left"></i> Back to Users
    </a>
</div>

<div class="row mb-4">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">User Information</h5>
            </div>
            <div class="card-body">
                <div class="row mb-3">
                    <div class="col-md-4 fw-bold">Name:</div>
                    <div class="col-md-8"><?php echo htmlspecialchars($user['name']); ?></div>
                </div>
                <div class="row mb-3">
                    <div class="col-md-4 fw-bold">Email:</div>
                    <div class="col-md-8"><?php echo htmlspecialchars($user['email']); ?></div>
                </div>
                <div class="row mb-3">
                    <div class="col-md-4 fw-bold">Role:</div>
                    <div class="col-md-8">
                        <span class="badge bg-<?php 
                            echo ($user['role'] == 'admin') ? 'danger' : 
                                (($user['role'] == 'vendor') ? 'success' : 'primary'); 
                        ?>">
                            <?php echo ucfirst($user['role'] ?: 'user'); ?>
                        </span>
                    </div>
                </div>
                <div class="row mb-3">
                    <div class="col-md-4 fw-bold">Admin:</div>
                    <div class="col-md-8"><?php echo $user['is_admin']; ?></div>
                </div>
                <div class="row mb-3">
                    <div class="col-md-4 fw-bold">Registered:</div>
                    <div class="col-md-8"><?php echo date('F d, Y h:i A', strtotime($user['created_at'])); ?></div>
                </div>
                
                <?php if (!empty($user['business_name'])): ?>
                <hr>
                <h6 class="mb-3">Vendor Details</h6>
                <div class="row mb-3">
                    <div class="col-md-4 fw-bold">Business Name:</div>
                    <div class="col-md-8"><?php echo htmlspecialchars($user['business_name']); ?></div>
                </div>
                <?php if (!empty($user['vendor_description'])): ?>
                <div class="row mb-3">
                    <div class="col-md-4 fw-bold">Description:</div>
                    <div class="col-md-8"><?php echo htmlspecialchars($user['vendor_description']); ?></div>
                </div>
                <?php endif; ?>
                <?php endif; ?>
                
                <div class="mt-3">
                    <a href="users.php" class="btn btn-outline-secondary me-2">Back</a>
                    <button type="button" class="btn btn-primary" 
                            onclick="editUser(<?php echo $user['id']; ?>, 
                                '<?php echo addslashes($user['name']); ?>', 
                                '<?php echo addslashes($user['email']); ?>', 
                                '<?php echo $user['role']; ?>',
                                '<?php echo addslashes($user['business_name'] ?? ''); ?>',
                                '<?php echo addslashes($user['vendor_description'] ?? ''); ?>')">
                        <i class="bi bi-pencil"></i> Edit User
                    </button>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-6">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">Addresses</h5>
                <span class="badge bg-primary"><?php echo count($addresses); ?> Address(es)</span>
            </div>
            <div class="card-body">
                <?php if (empty($addresses)): ?>
                    <p class="text-muted">No addresses found for this user.</p>
                <?php else: ?>
                    <div class="accordion" id="addressAccordion">
                        <?php foreach ($addresses as $index => $address): ?>
                            <div class="accordion-item">
                                <h2 class="accordion-header" id="address-heading-<?php echo $index; ?>">
                                    <button class="accordion-button <?php echo $index > 0 ? 'collapsed' : ''; ?>" type="button" 
                                            data-bs-toggle="collapse" 
                                            data-bs-target="#address-collapse-<?php echo $index; ?>" 
                                            aria-expanded="<?php echo $index === 0 ? 'true' : 'false'; ?>" 
                                            aria-controls="address-collapse-<?php echo $index; ?>">
                                        <?php echo htmlspecialchars($address['full_name']); ?> - <?php echo htmlspecialchars($address['city']); ?>, <?php echo htmlspecialchars($address['country']); ?>
                                    </button>
                                </h2>
                                <div id="address-collapse-<?php echo $index; ?>" 
                                     class="accordion-collapse collapse <?php echo $index === 0 ? 'show' : ''; ?>" 
                                     aria-labelledby="address-heading-<?php echo $index; ?>" 
                                     data-bs-parent="#addressAccordion">
                                    <div class="accordion-body">
                                        <p><strong>Name:</strong> <?php echo htmlspecialchars($address['full_name']); ?></p>
                                        <p><strong>Phone:</strong> <?php echo htmlspecialchars($address['phone']); ?></p>
                                        <p><strong>Address:</strong> <?php echo htmlspecialchars($address['address_line']); ?></p>
                                        <p><strong>City:</strong> <?php echo htmlspecialchars($address['city']); ?></p>
                                        <?php if (!empty($address['state'])): ?>
                                            <p><strong>State:</strong> <?php echo htmlspecialchars($address['state']); ?></p>
                                        <?php endif; ?>
                                        <?php if (!empty($address['zip_code'])): ?>
                                            <p><strong>ZIP Code:</strong> <?php echo htmlspecialchars($address['zip_code']); ?></p>
                                        <?php endif; ?>
                                        <p><strong>Country:</strong> <?php echo htmlspecialchars($address['country']); ?></p>
                                        <p><strong>Added On:</strong> <?php echo date('M d, Y', strtotime($address['created_at'])); ?></p>
                                    </div>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<div class="card mb-4">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">Orders</h5>
        <span class="badge bg-primary"><?php echo count($orders); ?> Order(s)</span>
    </div>
    <div class="card-body">
        <?php if (empty($orders)): ?>
            <p class="text-muted">No orders found for this user.</p>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>Order ID</th>
                            <th>Date</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Payment Status</th>
                            <th>Payment Method</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($orders as $order): ?>
                            <tr>
                                <td>#<?php echo $order['id']; ?></td>
                                <td><?php echo date('M d, Y', strtotime($order['created_at'])); ?></td>
                                <td>Rs. <?php echo number_format($order['total_amount'], 2); ?></td>
                                <td>
                                    <span class="badge bg-<?php 
                                        echo ($order['status'] == 'delivered') ? 'success' : 
                                            (($order['status'] == 'pending') ? 'warning' : 
                                            (($order['status'] == 'shipped') ? 'info' : 'danger')); 
                                    ?>">
                                        <?php echo ucfirst($order['status']); ?>
                                    </span>
                                </td>
                                <td>
                                    <span class="badge bg-<?php 
                                        echo ($order['payment_status'] == 'completed') ? 'success' : 
                                            (($order['payment_status'] == 'pending') ? 'warning' : 'danger'); 
                                    ?>">
                                        <?php echo ucfirst($order['payment_status'] ?? 'N/A'); ?>
                                    </span>
                                </td>
                                <td><?php echo ucfirst($order['payment_method'] ?? 'N/A'); ?></td>
                                <td>
                                    <a href="order-details.php?id=<?php echo $order['id']; ?>" class="btn btn-sm btn-outline-info">
                                        <i class="bi bi-eye"></i> View
                                    </a>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>

<?php if (!empty($vendor_products)): ?>
<div class="card mb-4">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0">Vendor Products</h5>
        <span class="badge bg-primary"><?php echo count($vendor_products); ?> Product(s)</span>
    </div>
    <div class="card-body">
        <?php foreach ($vendor_products as $product): ?>
            <div class="card mb-3">
                <div class="row g-0">
                    <div class="col-md-2">
                        <?php if (!empty($product['image_url'])): ?>
                            <img src="<?php echo htmlspecialchars($product['image_url']); ?>" 
                                 alt="<?php echo htmlspecialchars($product['name']); ?>" 
                                 class="img-fluid rounded-start" style="max-height: 150px; object-fit: cover;">
                        <?php else: ?>
                            <div class="d-flex justify-content-center align-items-center bg-light" style="height: 150px;">
                                <span class="text-muted">No image</span>
                            </div>
                        <?php endif; ?>
                    </div>
                    <div class="col-md-10">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start">
                                <h5 class="card-title"><?php echo htmlspecialchars($product['name']); ?></h5>
                                <span class="badge bg-success">Rs. <?php echo number_format($product['price'], 2); ?></span>
                            </div>
                            <p class="card-text">
                                <small class="text-muted">ID: #<?php echo $product['id']; ?> | Category: <?php echo htmlspecialchars($product['category_name']); ?></small>
                            </p>
                            
                            <?php if (!empty($product['description'])): ?>
                                <p class="card-text"><?php echo mb_substr(htmlspecialchars($product['description']), 0, 100); ?>
                                    <?php if (mb_strlen($product['description']) > 100): ?>...<?php endif; ?>
                                </p>
                            <?php endif; ?>
                            
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <span class="badge bg-<?php echo ($product['stock'] > 0) ? 'info' : 'danger'; ?>">
                                        Stock: <?php echo $product['stock']; ?> units
                                    </span>
                                    
                                    <?php if (isset($product['status'])): ?>
                                        <span class="badge bg-<?php echo ($product['status'] == 'active') ? 'success' : 'warning'; ?> ms-2">
                                            <?php echo ucfirst($product['status']); ?>
                                        </span>
                                    <?php endif; ?>
                                </div>
                                <div>
                                    <a href="products.php?id=<?php echo $product['id']; ?>" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-eye"></i> View
                                    </a>
                                    <a href="products.php?edit=<?php echo $product['id']; ?>" class="btn btn-sm btn-outline-info">
                                        <i class="bi bi-pencil"></i> Edit
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        <?php endforeach; ?>
    </div>
</div>
<?php endif; ?>

<!-- Edit User Modal (same as in users.php) -->
<div class="modal fade" id="editUserModal" tabindex="-1" aria-labelledby="editUserModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editUserModalLabel">Edit User</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form method="post" action="users.php">
                <input type="hidden" name="action" value="edit">
                <input type="hidden" id="edit_id" name="id" value="">
                <div class="modal-body">
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="edit_name" class="form-label">Full Name</label>
                            <input type="text" class="form-control" id="edit_name" name="name" required>
                        </div>
                        <div class="col-md-6">
                            <label for="edit_email" class="form-label">Email Address</label>
                            <input type="email" class="form-control" id="edit_email" name="email" required>
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="edit_password" class="form-label">Password (leave blank to keep current)</label>
                            <input type="password" class="form-control" id="edit_password" name="password">
                            <div class="form-text">Only fill this if you want to change the password</div>
                        </div>
                        <div class="col-md-6">
                            <label for="edit_role" class="form-label">User Role</label>
                            <select class="form-select" id="edit_role" name="role" required onchange="toggleEditVendorFields()">
                                <option value="user">Regular User</option>
                                <option value="vendor">Vendor</option>
                                <option value="admin">Admin</option>
                            </select>
                        </div>
                    </div>
                    
                    <!-- Vendor specific fields (initially hidden) -->
                    <div id="edit-vendor-fields" class="d-none border rounded p-3 mb-3">
                        <h6 class="mb-3">Vendor Details</h6>
                        <div class="row mb-3">
                            <div class="col-md-6">
                                <label for="edit_business_name" class="form-label">Business Name</label>
                                <input type="text" class="form-control" id="edit_business_name" name="business_name">
                            </div>
                            <div class="col-md-6">
                                <label for="edit_business_description" class="form-label">Business Description</label>
                                <textarea class="form-control" id="edit_business_description" name="business_description" rows="3"></textarea>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Update User</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php include 'includes/footer.php'; ?>

<script>
// Function to toggle vendor fields in edit user form
function toggleEditVendorFields() {
    const role = document.getElementById('edit_role').value;
    const vendorFields = document.getElementById('edit-vendor-fields');
    
    if (role === 'vendor') {
        vendorFields.classList.remove('d-none');
        document.getElementById('edit_business_name').setAttribute('required', 'required');
    } else {
        vendorFields.classList.add('d-none');
        document.getElementById('edit_business_name').removeAttribute('required');
    }
}

// Function to populate and show edit modal
function editUser(id, name, email, role, businessName, businessDesc) {
    document.getElementById('edit_id').value = id;
    document.getElementById('edit_name').value = name;
    document.getElementById('edit_email').value = email;
    document.getElementById('edit_role').value = role;
    document.getElementById('edit_business_name').value = businessName;
    document.getElementById('edit_business_description').value = businessDesc;
    
    // Show vendor fields if applicable
    if (role === 'vendor') {
        document.getElementById('edit-vendor-fields').classList.remove('d-none');
    } else {
        document.getElementById('edit-vendor-fields').classList.add('d-none');
    }
    
    $('#editUserModal').modal('show');
}
</script>

<?php
// End output buffering and send output to browser
ob_end_flush();
?>
