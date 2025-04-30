<?php
// Start output buffering to prevent headers already sent error
ob_start();

include 'includes/header.php';
include '../backend/db.php';

// Check if order ID is provided
if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    echo '<div class="alert alert-danger">Invalid order ID</div>';
    include 'includes/footer.php';
    exit;
}

$order_id = $_GET['id'];

// Handle form submission for status update
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['update_status'])) {
        $status = $_POST['status'];
        
        $query = "UPDATE orders SET status = ? WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("si", $status, $order_id);
        
        if ($stmt->execute()) {
            $_SESSION['success_message'] = "Order status updated successfully!";
        } else {
            $_SESSION['error_message'] = "Error updating order status: " . $conn->error;
        }
        $stmt->close();
        
        // Redirect to avoid form resubmission
        header('Location: order-details.php?id=' . $order_id);
        exit;
    } 
    elseif (isset($_POST['update_payment_status'])) {
        $payment_status = $_POST['payment_status'];
        
        $query = "UPDATE payments SET status = ? WHERE order_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("si", $payment_status, $order_id);
        
        if ($stmt->execute()) {
            $_SESSION['success_message'] = "Payment status updated successfully!";
        } else {
            $_SESSION['error_message'] = "Error updating payment status: " . $conn->error;
        }
        $stmt->close();
        
        // Redirect to avoid form resubmission
        header('Location: order-details.php?id=' . $order_id);
        exit;
    }
}

// Get order details
$order = null;
$query = "SELECT o.*, u.name as customer_name, u.email as customer_email, 
          p.payment_method, p.status as payment_status, p.transaction_id,
          a.full_name, a.phone, a.address_line, a.city, a.state, a.zip_code, a.country,
          v.business_name as vendor_name, v.id as vendor_id
          FROM orders o
          JOIN users u ON o.user_id = u.id
          LEFT JOIN payments p ON o.id = p.order_id
          LEFT JOIN addresses a ON o.address_id = a.id
          LEFT JOIN vendors v ON o.vendor_id = v.id
          WHERE o.id = ?";
          
$stmt = $conn->prepare($query);
$stmt->bind_param("i", $order_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo '<div class="alert alert-danger">Order not found</div>';
    include 'includes/footer.php';
    exit;
}

$order = $result->fetch_assoc();

// Check if there are related orders (same user, address, creation time window)
$related_orders = [];
if (!empty($order['created_at']) && !empty($order['user_id']) && !empty($order['address_id'])) {
    // Look for orders created within 1 minute of this order
    $created_time = strtotime($order['created_at']);
    $time_window_start = date('Y-m-d H:i:s', $created_time - 60); // 1 minute before
    $time_window_end = date('Y-m-d H:i:s', $created_time + 60);   // 1 minute after
    
    $query = "SELECT o.id, o.total_amount, o.status, v.business_name as vendor_name
              FROM orders o 
              LEFT JOIN vendors v ON o.vendor_id = v.id
              WHERE o.user_id = ? AND o.address_id = ? 
              AND o.created_at BETWEEN ? AND ?
              AND o.id != ?
              ORDER BY o.id";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("iissi", $order['user_id'], $order['address_id'], $time_window_start, $time_window_end, $order_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    while ($row = $result->fetch_assoc()) {
        $related_orders[] = $row;
    }
}

// Get order items
$items = [];
$query = "SELECT oi.*, p.name as product_name, p.image_url
          FROM order_items oi
          JOIN products p ON oi.product_id = p.id
          WHERE oi.order_id = ?";
          
$stmt = $conn->prepare($query);
$stmt->bind_param("i", $order_id);
$stmt->execute();
$result = $stmt->get_result();

while ($row = $result->fetch_assoc()) {
    $items[] = $row;
}

$conn->close();
?>

<div class="d-flex justify-content-between align-items-center mb-4">
    <h1 class="h2 dashboard-title mb-0">Order #<?php echo $order_id; ?></h1>
    <a href="orders.php" class="btn btn-outline-secondary">
        <i class="bi bi-arrow-left"></i> Back to Orders
    </a>
</div>

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

<?php if (!empty($related_orders)): ?>
<div class="alert alert-info alert-dismissible fade show" role="alert">
    <p><strong>This order is part of a multi-vendor purchase.</strong> Related orders:</p>
    <ul class="mb-0">
        <?php foreach ($related_orders as $related): ?>
            <li>
                <a href="order-details.php?id=<?php echo $related['id']; ?>" class="alert-link">
                    Order #<?php echo $related['id']; ?> - 
                    <?php echo htmlspecialchars($related['vendor_name'] ?? 'Unknown Vendor'); ?> - 
                    Rs. <?php echo number_format($related['total_amount'], 2); ?>
                </a>
                <span class="badge bg-<?php 
                    echo ($related['status'] == 'delivered') ? 'success' : 
                        (($related['status'] == 'pending') ? 'warning' : 
                        (($related['status'] == 'shipped') ? 'info' : 'danger')); 
                ?>">
                    <?php echo ucfirst($related['status']); ?>
                </span>
            </li>
        <?php endforeach; ?>
    </ul>
    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
<?php endif; ?>

<div class="row">
    <div class="col-md-8">
        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">Order Items</h5>
                <?php if (!empty($order['vendor_name'])): ?>
                    <div class="badge bg-secondary">Vendor: <?php echo htmlspecialchars($order['vendor_name']); ?></div>
                <?php endif; ?>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Product</th>
                                <th>Price</th>
                                <th>Quantity</th>
                                <th>Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($items as $item): ?>
                                <tr>
                                    <td>
                                        <div class="d-flex align-items-center">
                                            <?php if (!empty($item['image_url'])): ?>
                                                <img src="<?php echo htmlspecialchars($item['image_url']); ?>" 
                                                     alt="<?php echo htmlspecialchars($item['product_name']); ?>" 
                                                     width="50" class="me-3">
                                            <?php endif; ?>
                                            <div>
                                                <?php echo htmlspecialchars($item['product_name']); ?>
                                            </div>
                                        </div>
                                    </td>
                                    <td>Rs. <?php echo number_format($item['price'], 2); ?></td>
                                    <td><?php echo $item['quantity']; ?></td>
                                    <td>Rs. <?php echo number_format($item['price'] * $item['quantity'], 2); ?></td>
                                </tr>
                            <?php endforeach; ?>
                            <tr>
                                <td colspan="3" class="text-end"><strong>Total:</strong></td>
                                <td><strong>Rs. <?php echo number_format($order['total_amount'], 2); ?></strong></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-6">
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">Customer Information</h5>
                    </div>
                    <div class="card-body">
                        <p><strong>Name:</strong> <?php echo htmlspecialchars($order['customer_name']); ?></p>
                        <p><strong>Email:</strong> <?php echo htmlspecialchars($order['customer_email']); ?></p>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">Shipping Address</h5>
                    </div>
                    <div class="card-body">
                        <?php if (!empty($order['full_name'])): ?>
                            <p><strong>Name:</strong> <?php echo htmlspecialchars($order['full_name']); ?></p>
                            <p><strong>Phone:</strong> <?php echo htmlspecialchars($order['phone']); ?></p>
                            <p><strong>Address:</strong> <?php echo htmlspecialchars($order['address_line']); ?></p>
                            <p>
                                <?php echo htmlspecialchars($order['city']); ?>, 
                                <?php echo htmlspecialchars($order['state'] ?? ''); ?>
                                <?php echo htmlspecialchars($order['zip_code'] ?? ''); ?>
                            </p>
                            <p><strong>Country:</strong> <?php echo htmlspecialchars($order['country']); ?></p>
                        <?php else: ?>
                            <p class="text-muted">No shipping address provided</p>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-md-4">
        <div class="card mb-4">
            <div class="card-header">
                <h5 class="mb-0">Order Summary</h5>
            </div>
            <div class="card-body">
                <p><strong>Order ID:</strong> #<?php echo $order['id']; ?></p>
                <p><strong>Date:</strong> <?php echo date('F d, Y h:i A', strtotime($order['created_at'])); ?></p>
                <?php if (!empty($order['vendor_name'])): ?>
                    <p><strong>Vendor:</strong> <?php echo htmlspecialchars($order['vendor_name']); ?></p>
                <?php endif; ?>
                <p>
                    <strong>Status:</strong> 
                    <span class="badge bg-<?php 
                        echo ($order['status'] == 'delivered') ? 'success' : 
                            (($order['status'] == 'pending') ? 'warning' : 
                            (($order['status'] == 'shipped') ? 'info' : 'danger')); 
                    ?>">
                        <?php echo ucfirst($order['status']); ?>
                    </span>
                </p>
                <p>
                    <strong>Payment Status:</strong> 
                    <span class="badge bg-<?php 
                        echo ($order['payment_status'] == 'completed') ? 'success' : 
                            (($order['payment_status'] == 'pending') ? 'warning' : 'danger'); 
                    ?>">
                        <?php echo ucfirst($order['payment_status'] ?? 'N/A'); ?>
                    </span>
                </p>
                <p><strong>Payment Method:</strong> <?php echo ucfirst($order['payment_method'] ?? 'N/A'); ?></p>
                <?php if (!empty($order['transaction_id'])): ?>
                    <p><strong>Transaction ID:</strong> <?php echo htmlspecialchars($order['transaction_id']); ?></p>
                <?php endif; ?>
                <p><strong>Total Amount:</strong> Rs. <?php echo number_format($order['total_amount'], 2); ?></p>
                
                <hr>
                
                <h6>Update Order Status</h6>
                <form method="post" action="">
                    <input type="hidden" name="update_status" value="1">
                    <div class="mb-3">
                        <select class="form-select" id="status" name="status" required>
                            <option value="pending" <?php echo ($order['status'] == 'pending') ? 'selected' : ''; ?>>Pending</option>
                            <option value="shipped" <?php echo ($order['status'] == 'shipped') ? 'selected' : ''; ?>>Shipped</option>
                            <option value="delivered" <?php echo ($order['status'] == 'delivered') ? 'selected' : ''; ?>>Delivered</option>
                            <option value="cancelled" <?php echo ($order['status'] == 'cancelled') ? 'selected' : ''; ?>>Cancelled</option>
                        </select>
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Update Status</button>
                </form>

                <hr>

                <h6>Update Payment Status</h6>
                <form method="post" action="">
                    <input type="hidden" name="update_payment_status" value="1">
                    <div class="mb-3">
                        <select class="form-select" id="payment_status" name="payment_status" required>
                            <option value="pending" <?php echo ($order['payment_status'] == 'pending') ? 'selected' : ''; ?>>Pending</option>
                            <option value="completed" <?php echo ($order['payment_status'] == 'completed') ? 'selected' : ''; ?>>Completed</option>
                            <option value="failed" <?php echo ($order['payment_status'] == 'failed') ? 'selected' : ''; ?>>Failed</option>
                        </select>
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Update Payment Status</button>
                </form>
            </div>
        </div>
    </div>
</div>

<?php 
include 'includes/footer.php';

// End output buffering and send output to browser
ob_end_flush();
?>
