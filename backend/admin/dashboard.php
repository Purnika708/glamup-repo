<?php
include 'includes/header.php';
include '../backend/db.php';
include 'auth-helper.php';

// Get statistics
$stats = [
    'products' => 0,
    'categories' => 0,
    'orders' => 0,
    'orders_pending' => 0
];

// Count products
$result = $conn->query("SELECT COUNT(*) as count FROM products");
if ($result) {
    $row = $result->fetch_assoc();
    $stats['products'] = $row['count'];
}

// Count categories
$result = $conn->query("SELECT COUNT(*) as count FROM categories");
if ($result) {
    $row = $result->fetch_assoc();
    $stats['categories'] = $row['count'];
}

// Count orders
$result = $conn->query("SELECT COUNT(*) as count FROM orders");
if ($result) {
    $row = $result->fetch_assoc();
    $stats['orders'] = $row['count'];
}

// Count pending orders
$result = $conn->query("SELECT COUNT(*) as count FROM orders WHERE status = 'pending'");
if ($result) {
    $row = $result->fetch_assoc();
    $stats['orders_pending'] = $row['count'];
}

// Get recent orders
$recent_orders = [];
$result = $conn->query("SELECT o.*, u.name as customer_name 
                       FROM orders o 
                       JOIN users u ON o.user_id = u.id 
                       ORDER BY o.created_at DESC LIMIT 5");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $recent_orders[] = $row;
    }
}

$conn->close();
?>

<h1 class="h2 dashboard-title">Dashboard</h1>

<div class="row mb-4">
    <div class="col-md-3">
        <div class="card text-white bg-primary mb-3">
            <div class="card-body">
                <h5 class="card-title">Products</h5>
                <p class="card-text display-4"><?php echo $stats['products']; ?></p>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card text-white bg-success mb-3">
            <div class="card-body">
                <h5 class="card-title">Categories</h5>
                <p class="card-text display-4"><?php echo $stats['categories']; ?></p>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card text-white bg-info mb-3">
            <div class="card-body">
                <h5 class="card-title">Total Orders</h5>
                <p class="card-text display-4"><?php echo $stats['orders']; ?></p>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card text-white bg-warning mb-3">
            <div class="card-body">
                <h5 class="card-title">Pending Orders</h5>
                <p class="card-text display-4"><?php echo $stats['orders_pending']; ?></p>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-12">
        <div class="card">
            <div class="card-header">
                <h5>Recent Orders</h5>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Order ID</th>
                                <th>Customer</th>
                                <th>Amount</th>
                                <th>Status</th>
                                <th>Date</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (empty($recent_orders)): ?>
                                <tr>
                                    <td colspan="6" class="text-center">No orders found</td>
                                </tr>
                            <?php else: ?>
                                <?php foreach ($recent_orders as $order): ?>
                                    <tr>
                                        <td>#<?php echo $order['id']; ?></td>
                                        <td><?php echo htmlspecialchars($order['customer_name']); ?></td>
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
                                        <td><?php echo date('M d, Y', strtotime($order['created_at'])); ?></td>
                                        <td>
                                            <a href="order-details.php?id=<?php echo $order['id']; ?>" class="btn btn-sm btn-outline-info">View</a>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
                <a href="orders.php" class="btn btn-outline-primary">View All Orders</a>
            </div>
        </div>
    </div>
</div>

<?php include 'includes/footer.php'; ?>
