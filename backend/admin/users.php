<?php
// Start output buffering to prevent headers already sent error
ob_start();

include 'includes/header.php';
include '../backend/db.php';

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Add new user
    if (isset($_POST['action']) && $_POST['action'] === 'add') {
        $name = trim($_POST['name']);
        $email = trim($_POST['email']);
        $password = $_POST['password'];
        $role = $_POST['role'];
        
        // Check if email already exists
        $check_query = "SELECT COUNT(*) as count FROM users WHERE email = ?";
        $check_stmt = $conn->prepare($check_query);
        $check_stmt->bind_param("s", $email);
        $check_stmt->execute();
        $result = $check_stmt->get_result();
        $row = $result->fetch_assoc();
        $check_stmt->close();
        
        if ($row['count'] > 0) {
            $_SESSION['error_message'] = "Email already exists. Please use a different email.";
        } else {
            // Hash password
            $hashed_password = password_hash($password, PASSWORD_BCRYPT);
            
            // Begin transaction
            $conn->begin_transaction();
            
            try {
                // Insert user
                $query = "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)";
                $stmt = $conn->prepare($query);
                $stmt->bind_param("ssss", $name, $email, $hashed_password, $role);
                $stmt->execute();
                $user_id = $conn->insert_id;
                $stmt->close();
                
                // If vendor, add vendor details
                if ($role === 'vendor' && !empty($_POST['business_name'])) {
                    $business_name = trim($_POST['business_name']);
                    $description = trim($_POST['business_description'] ?? '');
                    
                    $query = "INSERT INTO vendors (user_id, business_name, description) VALUES (?, ?, ?)";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("iss", $user_id, $business_name, $description);
                    $stmt->execute();
                    $stmt->close();
                }
                
                // If admin, add to admins table
                if ($role === 'admin') {
                    $query = "INSERT INTO admins (user_id) VALUES (?)";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("i", $user_id);
                    $stmt->execute();
                    $stmt->close();
                }
                
                $conn->commit();
                $_SESSION['success_message'] = "User added successfully!";
            } catch (Exception $e) {
                $conn->rollback();
                $_SESSION['error_message'] = "Error adding user: " . $e->getMessage();
            }
        }
    }
    
    // Update user
    elseif (isset($_POST['action']) && $_POST['action'] === 'edit') {
        $id = intval($_POST['id']);
        $name = trim($_POST['name']);
        $email = trim($_POST['email']);
        $role = $_POST['role'];
        $password = $_POST['password'];
        
        // Check if email exists for another user
        $check_query = "SELECT COUNT(*) as count FROM users WHERE email = ? AND id != ?";
        $check_stmt = $conn->prepare($check_query);
        $check_stmt->bind_param("si", $email, $id);
        $check_stmt->execute();
        $result = $check_stmt->get_result();
        $row = $result->fetch_assoc();
        $check_stmt->close();
        
        if ($row['count'] > 0) {
            $_SESSION['error_message'] = "Email already used by another user. Please use a different email.";
        } else {
            // Get current user role
            $role_query = "SELECT role FROM users WHERE id = ?";
            $role_stmt = $conn->prepare($role_query);
            $role_stmt->bind_param("i", $id);
            $role_stmt->execute();
            $result = $role_stmt->get_result();
            $current_role = $result->fetch_assoc()['role'];
            $role_stmt->close();
            
            // Begin transaction
            $conn->begin_transaction();
            
            try {
                // Update basic info
                if (!empty($password)) {
                    // Update with new password
                    $hashed_password = password_hash($password, PASSWORD_BCRYPT);
                    $query = "UPDATE users SET name = ?, email = ?, role = ?, password = ? WHERE id = ?";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("ssssi", $name, $email, $role, $hashed_password, $id);
                } else {
                    // Update without changing password
                    $query = "UPDATE users SET name = ?, email = ?, role = ? WHERE id = ?";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("sssi", $name, $email, $role, $id);
                }
                $stmt->execute();
                $stmt->close();
                
                // Handle role changes
                if ($current_role !== $role) {
                    // Remove from previous role tables if needed
                    if ($current_role === 'vendor') {
                        $query = "DELETE FROM vendors WHERE user_id = ?";
                        $stmt = $conn->prepare($query);
                        $stmt->bind_param("i", $id);
                        $stmt->execute();
                        $stmt->close();
                    } elseif ($current_role === 'admin') {
                        $query = "DELETE FROM admins WHERE user_id = ?";
                        $stmt = $conn->prepare($query);
                        $stmt->bind_param("i", $id);
                        $stmt->execute();
                        $stmt->close();
                    }
                    
                    // Add to new role tables if needed
                    if ($role === 'vendor') {
                        $business_name = trim($_POST['business_name'] ?? '');
                        $description = trim($_POST['business_description'] ?? '');
                        
                        $query = "INSERT INTO vendors (user_id, business_name, description) VALUES (?, ?, ?)";
                        $stmt = $conn->prepare($query);
                        $stmt->bind_param("iss", $id, $business_name, $description);
                        $stmt->execute();
                        $stmt->close();
                    } elseif ($role === 'admin') {
                        $query = "INSERT INTO admins (user_id) VALUES (?)";
                        $stmt = $conn->prepare($query);
                        $stmt->bind_param("i", $id);
                        $stmt->execute();
                        $stmt->close();
                    }
                }
                // Update vendor details if role is same but details changed
                elseif ($role === 'vendor' && isset($_POST['business_name'])) {
                    $business_name = trim($_POST['business_name']);
                    $description = trim($_POST['business_description'] ?? '');
                    
                    // Check if vendor record exists
                    $check_query = "SELECT COUNT(*) as count FROM vendors WHERE user_id = ?";
                    $check_stmt = $conn->prepare($check_query);
                    $check_stmt->bind_param("i", $id);
                    $check_stmt->execute();
                    $result = $check_stmt->get_result();
                    $row = $result->fetch_assoc();
                    $check_stmt->close();
                    
                    if ($row['count'] > 0) {
                        // Update existing vendor
                        $query = "UPDATE vendors SET business_name = ?, description = ? WHERE user_id = ?";
                        $stmt = $conn->prepare($query);
                        $stmt->bind_param("ssi", $business_name, $description, $id);
                    } else {
                        // Create new vendor record
                        $query = "INSERT INTO vendors (user_id, business_name, description) VALUES (?, ?, ?)";
                        $stmt = $conn->prepare($query);
                        $stmt->bind_param("iss", $id, $business_name, $description);
                    }
                    $stmt->execute();
                    $stmt->close();
                }
                
                $conn->commit();
                $_SESSION['success_message'] = "User updated successfully!";
            } catch (Exception $e) {
                $conn->rollback();
                $_SESSION['error_message'] = "Error updating user: " . $e->getMessage();
            }
        }
    }
    
    // Delete user
    elseif (isset($_POST['delete'])) {
        $id = intval($_POST['delete_id']);
        
        // Don't allow deleting own account
        if ($id == $_SESSION['admin_id']) {
            $_SESSION['error_message'] = "You cannot delete your own account.";
        } else {
            // Check if user has orders
            $check_query = "SELECT COUNT(*) as count FROM orders WHERE user_id = ?";
            $check_stmt = $conn->prepare($check_query);
            $check_stmt->bind_param("i", $id);
            $check_stmt->execute();
            $result = $check_stmt->get_result();
            $row = $result->fetch_assoc();
            $check_stmt->close();
            
            // Begin transaction
            $conn->begin_transaction();
            
            try {
                // Delete user from role-specific tables
                $role_query = "SELECT role FROM users WHERE id = ?";
                $role_stmt = $conn->prepare($role_query);
                $role_stmt->bind_param("i", $id);
                $role_stmt->execute();
                $result = $role_stmt->get_result();
                $user_role = $result->fetch_assoc()['role'];
                $role_stmt->close();
                
                if ($user_role === 'vendor') {
                    $query = "DELETE FROM vendors WHERE user_id = ?";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("i", $id);
                    $stmt->execute();
                    $stmt->close();
                    
                    // Also delete vendor's products
                    $query = "DELETE FROM products WHERE vendor_id IN (SELECT id FROM vendors WHERE user_id = ?)";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("i", $id);
                    $stmt->execute();
                    $stmt->close();
                } elseif ($user_role === 'admin') {
                    $query = "DELETE FROM admins WHERE user_id = ?";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("i", $id);
                    $stmt->execute();
                    $stmt->close();
                }
                
                // Delete user's addresses
                $query = "DELETE FROM addresses WHERE user_id = ?";
                $stmt = $conn->prepare($query);
                $stmt->bind_param("i", $id);
                $stmt->execute();
                $stmt->close();
                
                // Delete user
                $query = "DELETE FROM users WHERE id = ?";
                $stmt = $conn->prepare($query);
                $stmt->bind_param("i", $id);
                $stmt->execute();
                $stmt->close();
                
                $conn->commit();
                $_SESSION['success_message'] = "User deleted successfully!";
            } catch (Exception $e) {
                $conn->rollback();
                $_SESSION['error_message'] = "Error deleting user: " . $e->getMessage();
            }
        }
    }
    
    // Redirect to avoid form resubmission
    header('Location: users.php');
    exit;
}

// Get all users with related info
$users = [];
$query = "SELECT u.*, 
          CASE WHEN v.id IS NOT NULL THEN v.business_name ELSE NULL END AS business_name,
          CASE WHEN a.id IS NOT NULL THEN 'Yes' ELSE 'No' END AS is_admin,
          v.description AS vendor_description
          FROM users u
          LEFT JOIN vendors v ON u.id = v.user_id
          LEFT JOIN admins a ON u.id = a.user_id
          ORDER BY u.id DESC";
          
if ($conn && $conn->ping()) {
    $result = $conn->query($query);
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $users[] = $row;
        }
    } else {
        $_SESSION['error_message'] = "Error fetching users: " . $conn->error;
    }
} else {
    $_SESSION['error_message'] = "Database connection error.";
}

$conn->close();
?>

<h1 class="h2 dashboard-title">Manage Users</h1>

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
    <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addUserModal">
        <i class="bi bi-plus-circle"></i> Add New User
    </button>
</div>

<div class="card">
    <div class="card-body">
        <div class="table-responsive">
            <table id="usersTable" class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Business Name</th>
                        <th>Admin</th>
                        <th>Registration Date</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($users as $user): ?>
                        <tr>
                            <td><?php echo $user['id']; ?></td>
                            <td><?php echo htmlspecialchars($user['name']); ?></td>
                            <td><?php echo htmlspecialchars($user['email']); ?></td>
                            <td>
                                <span class="badge bg-<?php 
                                    echo ($user['role'] == 'admin') ? 'danger' : 
                                        (($user['role'] == 'vendor') ? 'success' : 'primary'); 
                                ?>">
                                    <?php echo ucfirst($user['role'] ?: 'user'); ?>
                                </span>
                            </td>
                            <td>
                                <?php if (!empty($user['business_name'])): ?>
                                    <?php echo htmlspecialchars($user['business_name']); ?>
                                <?php else: ?>
                                    <span class="text-muted">N/A</span>
                                <?php endif; ?>
                            </td>
                            <td><?php echo $user['is_admin']; ?></td>
                            <td><?php echo date('M d, Y', strtotime($user['created_at'])); ?></td>
                            <td>
                                <a href="user-details.php?id=<?php echo $user['id']; ?>" class="btn btn-sm btn-outline-info">
                                    <i class="bi bi-eye"></i>
                                </a>
                                <button type="button" class="btn btn-sm btn-outline-primary" 
                                        onclick="editUser(<?php echo $user['id']; ?>, 
                                            '<?php echo addslashes($user['name']); ?>', 
                                            '<?php echo addslashes($user['email']); ?>', 
                                            '<?php echo $user['role']; ?>',
                                            '<?php echo addslashes($user['business_name'] ?? ''); ?>',
                                            '<?php echo addslashes($user['vendor_description'] ?? ''); ?>')">
                                    <i class="bi bi-pencil"></i>
                                </button>
                                <?php if ($user['id'] != $_SESSION['admin_id']): // Prevent deleting own account ?>
                                <button type="button" class="btn btn-sm btn-outline-danger" 
                                        onclick="confirmDelete(<?php echo $user['id']; ?>, '<?php echo addslashes($user['name']); ?>')">
                                    <i class="bi bi-trash"></i>
                                </button>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Add User Modal -->
<div class="modal fade" id="addUserModal" tabindex="-1" aria-labelledby="addUserModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="addUserModalLabel">Add New User</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form method="post" action="">
                <input type="hidden" name="action" value="add">
                <div class="modal-body">
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="name" class="form-label">Full Name</label>
                            <input type="text" class="form-control" id="name" name="name" required>
                        </div>
                        <div class="col-md-6">
                            <label for="email" class="form-label">Email Address</label>
                            <input type="email" class="form-control" id="email" name="email" required>
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="password" class="form-label">Password</label>
                            <input type="password" class="form-control" id="password" name="password" required>
                            <div class="form-text">Minimum 8 characters recommended</div>
                        </div>
                        <div class="col-md-6">
                            <label for="role" class="form-label">User Role</label>
                            <select class="form-select" id="role" name="role" required onchange="toggleVendorFields()">
                                <option value="user">Regular User</option>
                                <option value="vendor">Vendor</option>
                                <option value="admin">Admin</option>
                            </select>
                        </div>
                    </div>
                    
                    <!-- Vendor specific fields (initially hidden) -->
                    <div id="vendor-fields" class="d-none border rounded p-3 mb-3">
                        <h6 class="mb-3">Vendor Details</h6>
                        <div class="row mb-3">
                            <div class="col-md-6">
                                <label for="business_name" class="form-label">Business Name</label>
                                <input type="text" class="form-control" id="business_name" name="business_name">
                            </div>
                            <div class="col-md-6">
                                <label for="business_description" class="form-label">Business Description</label>
                                <textarea class="form-control" id="business_description" name="business_description" rows="3"></textarea>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save User</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit User Modal -->
<div class="modal fade" id="editUserModal" tabindex="-1" aria-labelledby="editUserModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editUserModalLabel">Edit User</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form method="post" action="">
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

<!-- Delete User Modal -->
<div class="modal fade" id="deleteUserModal" tabindex="-1" aria-labelledby="deleteUserModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="deleteUserModalLabel">Confirm Delete</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <p>Are you sure you want to delete the user: <strong id="delete-user-name"></strong>?</p>
                <p class="text-danger">This will also delete all associated data (addresses, products, etc). This action cannot be undone.</p>
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

<?php include 'includes/footer.php'; ?>

<script>
$(document).ready(function() {
    // Initialize DataTable
    $('#usersTable').DataTable({
        "order": [[0, "desc"]]
    });
});

// Toggle vendor fields in add user form
function toggleVendorFields() {
    const role = document.getElementById('role').value;
    const vendorFields = document.getElementById('vendor-fields');
    
    if (role === 'vendor') {
        vendorFields.classList.remove('d-none');
        document.getElementById('business_name').setAttribute('required', 'required');
    } else {
        vendorFields.classList.add('d-none');
        document.getElementById('business_name').removeAttribute('required');
    }
}

// Toggle vendor fields in edit user form
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

// Function to populate and show delete confirmation modal
function confirmDelete(id, name) {
    document.getElementById('delete_id').value = id;
    document.getElementById('delete-user-name').textContent = name;
    $('#deleteUserModal').modal('show');
}
</script>

<?php
// End output buffering and send output to browser
ob_end_flush();
?>
