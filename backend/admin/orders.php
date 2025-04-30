<?php
// Start output buffering to prevent headers already sent error
ob_start();

include 'includes/header.php';
include '../backend/db.php';

// Get necessary data for the create order form
$conn_for_data = new mysqli($host, $user, $password, $database);

// Get users with role='user' for customer selection
$users = [];
$users_query = "SELECT id, name, email FROM users WHERE role='user' ORDER BY name";
$users_result = $conn_for_data->query($users_query);
if ($users_result) {
    while ($row = $users_result->fetch_assoc()) {
        $users[] = $row;
    }
}

// Get products for order items
$products = [];
$products_query = "SELECT p.*, c.name as category_name, v.business_name as vendor_name, v.id as vendor_id 
                 FROM products p 
                 JOIN categories c ON p.category_id = c.id 
                 JOIN vendors v ON p.vendor_id = v.id 
                 WHERE p.stock > 0
                 ORDER BY p.name";
$products_result = $conn_for_data->query($products_query);
if ($products_result) {
    while ($row = $products_result->fetch_assoc()) {
        $products[] = $row;
    }
}

$conn_for_data->close();

// Handle form submissions for status updates
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['update_status'])) {
        $order_id = intval($_POST['order_id']);
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
        header('Location: ' . $_SERVER['PHP_SELF']);
        exit;
    }
    // Handle admin order creation
    elseif (isset($_POST['create_order'])) {
        // Get form data
        $user_id = intval($_POST['user_id']);
        $payment_method = $_POST['payment_method'];
        $status = $_POST['status'] ?? 'pending';
        $shipping_fullname = trim($_POST['shipping_fullname']);
        $shipping_phone = trim($_POST['shipping_phone']);
        $shipping_address = trim($_POST['shipping_address']);
        $shipping_city = trim($_POST['shipping_city']);
        $shipping_state = trim($_POST['shipping_state']);
        $shipping_country = trim($_POST['shipping_country']);
        $shipping_zipcode = trim($_POST['shipping_zipcode']);
        
        // Create an address record if shipping info is provided
        $address_id = null;
        if (!empty($shipping_fullname) && !empty($shipping_phone) && !empty($shipping_address) && !empty($shipping_city) && !empty($shipping_country)) {
            $query = "INSERT INTO addresses (user_id, full_name, phone, address_line, city, state, country, zip_code) 
                      VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("isssssss", $user_id, $shipping_fullname, $shipping_phone, $shipping_address, $shipping_city, $shipping_state, $shipping_country, $shipping_zipcode);
            
            if ($stmt->execute()) {
                $address_id = $conn->insert_id;
                $stmt->close();
            } else {
                $_SESSION['error_message'] = "Error creating address: " . $conn->error;
                header('Location: ' . $_SERVER['PHP_SELF']);
                exit;
            }
        }
        
        // Group items by vendor
        $vendor_items = [];
        $total_amount = 0;
        
        if (isset($_POST['product_id']) && isset($_POST['quantity']) && isset($_POST['price']) && isset($_POST['vendor_id'])) {
            $product_ids = $_POST['product_id'];
            $quantities = $_POST['quantity'];
            $prices = $_POST['price'];
            $vendor_ids = $_POST['vendor_id'];
            
            for ($i = 0; $i < count($product_ids); $i++) {
                if (isset($product_ids[$i]) && isset($quantities[$i]) && isset($prices[$i]) && isset($vendor_ids[$i]) && $quantities[$i] > 0) {
                    $product_id = intval($product_ids[$i]);
                    $quantity = intval($quantities[$i]);
                    $price = floatval($prices[$i]);
                    $vendor_id = intval($vendor_ids[$i]);
                    $item_total = $price * $quantity;
                    
                    if (!isset($vendor_items[$vendor_id])) {
                        $vendor_items[$vendor_id] = [
                            'items' => [],
                            'total' => 0
                        ];
                    }
                    
                    $vendor_items[$vendor_id]['items'][] = [
                        'product_id' => $product_id,
                        'quantity' => $quantity,
                        'price' => $price
                    ];
                    
                    $vendor_items[$vendor_id]['total'] += $item_total;
                    $total_amount += $item_total;
                }
            }
        }
        
        if (empty($vendor_items)) {
            $_SESSION['error_message'] = "No valid items selected";
            header('Location: ' . $_SERVER['PHP_SELF']);
            exit;
        }
        
        // Begin transaction
        $conn->begin_transaction();
        
        try {
            $order_ids = [];
            
            // Create separate order for each vendor
            foreach ($vendor_items as $vendor_id => $vendor_data) {
                // Create order with vendor_id
                $query = "INSERT INTO orders (user_id, vendor_id, total_amount, status, address_id) VALUES (?, ?, ?, ?, ?)";
                $stmt = $conn->prepare($query);
                $stmt->bind_param("iidsi", $user_id, $vendor_id, $vendor_data['total'], $status, $address_id);
                
                if (!$stmt->execute()) {
                    throw new Exception("Error creating order: " . $stmt->error);
                }
                
                $order_id = $conn->insert_id;
                $order_ids[] = $order_id;
                $stmt->close();
                
                // Create payment record
                $query = "INSERT INTO payments (order_id, payment_method, status) VALUES (?, ?, 'pending')";
                $stmt = $conn->prepare($query);
                $stmt->bind_param("is", $order_id, $payment_method);
                
                if (!$stmt->execute()) {
                    throw new Exception("Error creating payment: " . $stmt->error);
                }
                
                $stmt->close();
                
                // Create order items for this vendor
                foreach ($vendor_data['items'] as $item) {
                    $query = "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("iiid", $order_id, $item['product_id'], $item['quantity'], $item['price']);
                    
                    if (!$stmt->execute()) {
                        throw new Exception("Error creating order item: " . $stmt->error);
                    }
                    
                    $stmt->close();
                    
                    // Update product stock
                    $query = "UPDATE products SET stock = stock - ? WHERE id = ?";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("ii", $item['quantity'], $item['product_id']);
                    
                    if (!$stmt->execute()) {
                        throw new Exception("Error updating product stock: " . $stmt->error);
                    }
                    
                    $stmt->close();
                }
            }
            
            // Commit transaction
            $conn->commit();
            
            $_SESSION['success_message'] = count($order_ids) > 1 
                ? "Multiple orders created successfully!" 
                : "Order created successfully!";
            
            // Redirect to order details page of the first order
            header('Location: order-details.php?id=' . $order_ids[0]);
            exit;
            
        } catch (Exception $e) {
            // Rollback transaction on error
            $conn->rollback();
            $_SESSION['error_message'] = $e->getMessage();
            header('Location: ' . $_SERVER['PHP_SELF']);
            exit;
        }
    }
}

// Get all orders with customer names, payment status, and vendor name
$orders = [];
$query = "SELECT o.*, u.name as customer_name, p.status as payment_status, v.business_name as vendor_name
          FROM orders o
          JOIN users u ON o.user_id = u.id
          LEFT JOIN payments p ON o.id = p.order_id
          LEFT JOIN vendors v ON o.vendor_id = v.id
          ORDER BY o.created_at DESC";
$result = $conn->query($query);
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $orders[] = $row;
    }
}

$conn->close();
?>

<h1 class="h2 dashboard-title">Manage Orders</h1>

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
    <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createOrderModal">
        <i class="bi bi-plus-circle"></i> Create Order
    </button>
</div>

<div class="card">
    <div class="card-body">
        <div class="table-responsive">
            <table id="ordersTable" class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>Order ID</th>
                        <th>Customer</th>
                        <th>Vendor</th>
                        <th>Total Amount</th>
                        <th>Status</th>
                        <th>Payment Status</th>
                        <th>Date</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($orders as $order): ?>
                        <tr>
                            <td>#<?php echo $order['id']; ?></td>
                            <td><?php echo htmlspecialchars($order['customer_name']); ?></td>
                            <td><?php echo htmlspecialchars($order['vendor_name'] ?? 'N/A'); ?></td>
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
                            <td><?php echo date('M d, Y', strtotime($order['created_at'])); ?></td>
                            <td>
                                <a href="order-details.php?id=<?php echo $order['id']; ?>" class="btn btn-sm btn-outline-info">
                                    <i class="bi bi-eye"></i>
                                </a>
                                <button type="button" class="btn btn-sm btn-outline-primary" 
                                        onclick="openUpdateStatusModal(<?php echo $order['id']; ?>, '<?php echo $order['status']; ?>')">
                                    <i class="bi bi-arrow-repeat"></i>
                                </button>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Create Order Modal -->
<div class="modal fade" id="createOrderModal" tabindex="-1" aria-labelledby="createOrderModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="createOrderModalLabel">Create New Order</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form method="post" action="" id="createOrderForm">
                <input type="hidden" name="create_order" value="1">
                <div class="modal-body">
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="user_id" class="form-label">Customer</label>
                            <select class="form-select" id="user_id" name="user_id" required>
                                <option value="">Select Customer</option>
                                <?php foreach ($users as $user): ?>
                                    <option value="<?php echo $user['id']; ?>"><?php echo htmlspecialchars($user['name']); ?> (<?php echo htmlspecialchars($user['email']); ?>)</option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label for="payment_method" class="form-label">Payment Method</label>
                            <select class="form-select" id="payment_method" name="payment_method" required>
                                <option value="card">Card</option>
                                <option value="bank_transfer">Bank Transfer</option>
                                <option value="wallet">Wallet</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="status" class="form-label">Order Status</label>
                            <select class="form-select" id="status" name="status" required>
                                <option value="pending">Pending</option>
                                <option value="shipped">Shipped</option>
                                <option value="delivered">Delivered</option>
                            </select>
                        </div>
                    </div>
                    
                    <hr>
                    <h6 class="mb-3">Shipping Information</h6>
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label for="shipping_fullname" class="form-label">Full Name</label>
                            <input type="text" class="form-control" id="shipping_fullname" name="shipping_fullname">
                        </div>
                        <div class="col-md-6">
                            <label for="shipping_phone" class="form-label">Phone Number</label>
                            <input type="text" class="form-control" id="shipping_phone" name="shipping_phone">
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-12">
                            <label for="shipping_address" class="form-label">Address Line</label>
                            <input type="text" class="form-control" id="shipping_address" name="shipping_address">
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-4">
                            <label for="shipping_city" class="form-label">City</label>
                            <input type="text" class="form-control" id="shipping_city" name="shipping_city">
                        </div>
                        <div class="col-md-4">
                            <label for="shipping_state" class="form-label">State/Province</label>
                            <input type="text" class="form-control" id="shipping_state" name="shipping_state">
                        </div>
                        <div class="col-md-4">
                            <label for="shipping_country" class="form-label">Country</label>
                            <input type="text" class="form-control" id="shipping_country" name="shipping_country">
                        </div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-md-4">
                            <label for="shipping_zipcode" class="form-label">Zip/Postal Code</label>
                            <input type="text" class="form-control" id="shipping_zipcode" name="shipping_zipcode">
                        </div>
                    </div>
                    
                    <hr>
                    
                    <h6 class="mb-3">Order Items</h6>
                    <div id="order-items-container">
                        <div class="order-item row mb-3">
                            <div class="col-md-5">
                                <label class="form-label">Product</label>
                                <select class="form-select product-select" name="product_id[]" required>
                                    <option value="">Select Product</option>
                                    <?php foreach ($products as $product): ?>
                                        <option value="<?php echo $product['id']; ?>" 
                                                data-price="<?php echo $product['price']; ?>" 
                                                data-stock="<?php echo $product['stock']; ?>"
                                                data-vendor-id="<?php echo $product['vendor_id']; ?>"
                                                data-vendor-name="<?php echo htmlspecialchars($product['vendor_name']); ?>">
                                            <?php echo htmlspecialchars($product['name']); ?> - Rs. <?php echo $product['price']; ?> (<?php echo htmlspecialchars($product['vendor_name']); ?>)
                                        </option>
                                    <?php endforeach; ?>
                                </select>
                                <input type="hidden" class="vendor-id" name="vendor_id[]" value="">
                                <div class="vendor-info form-text"></div>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">Price</label>
                                <input type="number" class="form-control item-price" name="price[]" step="0.01" min="0" readonly required>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">Quantity</label>
                                <input type="number" class="form-control item-quantity" name="quantity[]" min="1" value="1" required>
                                <div class="stock-info form-text"></div>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">Subtotal</label>
                                <input type="text" class="form-control item-subtotal" readonly>
                            </div>
                            <div class="col-md-1 d-flex align-items-end">
                                <button type="button" class="btn btn-danger remove-item mb-3" style="display:none;"><i class="bi bi-trash"></i></button>
                            </div>
                        </div>
                    </div>
                    
                    <div class="text-center mb-3">
                        <button type="button" class="btn btn-info" id="add-more-items">
                            <i class="bi bi-plus-circle"></i> Add Another Item
                        </button>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-8">
                            <div class="alert alert-info mt-3">
                                <i class="bi bi-info-circle"></i> If you select products from multiple vendors, separate orders will be created for each vendor.
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="card">
                                <div class="card-body">
                                    <h6 class="card-title">Order Summary</h6>
                                    <div class="d-flex justify-content-between mb-2">
                                        <span>Total Items:</span>
                                        <span id="total-items">1</span>
                                    </div>
                                    <div class="d-flex justify-content-between mb-2">
                                        <span>Total Amount:</span>
                                        <span id="total-amount">Rs. 0.00</span>
                                    </div>
                                </div>
                            </div>
                            <div id="vendor-breakdown"></div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Create Order</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Update Status Modal -->
<div class="modal fade" id="updateStatusModal" tabindex="-1" aria-labelledby="updateStatusModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="updateStatusModalLabel">Update Order Status</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form method="post" action="">
                <input type="hidden" name="update_status" value="1">
                <input type="hidden" id="order_id" name="order_id" value="">
                <div class="modal-body">
                    <div class="mb-3">
                        <label for="status" class="form-label">Status</label>
                        <select class="form-select" id="status" name="status" required>
                            <option value="pending">Pending</option>
                            <option value="shipped">Shipped</option>
                            <option value="delivered">Delivered</option>
                            <option value="cancelled">Cancelled</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Update Status</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php include 'includes/footer.php'; ?>

<script>
$(document).ready(function() {
    // Initialize DataTable
    $('#ordersTable').DataTable({
        "order": [[6, "desc"]] // Order by date column
    });
    
    // Order creation form functionality
    setupOrderCreationForm();
});

// Function to open and populate the update status modal
function openUpdateStatusModal(orderId, currentStatus) {
    document.getElementById('order_id').value = orderId;
    document.getElementById('status').value = currentStatus;
    $('#updateStatusModal').modal('show');
}

// Function to set up order creation form
function setupOrderCreationForm() {
    // Handle product selection changes
    $(document).on('change', '.product-select', function() {
        const selectedOption = $(this).find('option:selected');
        const price = selectedOption.data('price');
        const stock = selectedOption.data('stock');
        const vendorId = selectedOption.data('vendor-id');
        const vendorName = selectedOption.data('vendor-name');
        const itemRow = $(this).closest('.order-item');
        
        // Update price field
        itemRow.find('.item-price').val(price);
        
        // Update vendor ID field
        itemRow.find('.vendor-id').val(vendorId);
        
        // Update vendor info
        if (vendorName) {
            itemRow.find('.vendor-info').text(`Vendor: ${vendorName}`);
        } else {
            itemRow.find('.vendor-info').text('');
        }
        
        // Update stock info
        itemRow.find('.stock-info').text(`Available stock: ${stock}`);
        
        // Update max quantity
        itemRow.find('.item-quantity').attr('max', stock);
        
        // Calculate subtotal
        updateSubtotal(itemRow);
        
        // Update order summary
        updateOrderSummary();
    });
    
    // Handle quantity changes
    $(document).on('change', '.item-quantity', function() {
        const itemRow = $(this).closest('.order-item');
        
        // Calculate subtotal
        updateSubtotal(itemRow);
        
        // Update order summary
        updateOrderSummary();
    });
    
    // Add more items button
    $('#add-more-items').on('click', function() {
        const itemRow = $('.order-item:first').clone();
        
        // Reset select and inputs
        itemRow.find('.product-select').val('');
        itemRow.find('.item-price').val('');
        itemRow.find('.item-quantity').val('1');
        itemRow.find('.item-subtotal').val('');
        itemRow.find('.stock-info').text('');
        itemRow.find('.vendor-info').text('');
        itemRow.find('.vendor-id').val('');
        
        // Show remove button
        itemRow.find('.remove-item').show();
        
        // Add to container
        $('#order-items-container').append(itemRow);
        
        // Update order summary
        updateOrderSummary();
    });
    
    // Remove item button
    $(document).on('click', '.remove-item', function() {
        $(this).closest('.order-item').remove();
        
        // Update order summary
        updateOrderSummary();
    });
    
    // Show remove button for existing items (except first one)
    $('.order-item:not(:first)').find('.remove-item').show();
}

// Function to update subtotal
function updateSubtotal(itemRow) {
    const price = parseFloat(itemRow.find('.item-price').val()) || 0;
    const quantity = parseInt(itemRow.find('.item-quantity').val()) || 0;
    const subtotal = price * quantity;
    
    itemRow.find('.item-subtotal').val('Rs. ' + subtotal.toFixed(2));
}

// Function to update order summary
function updateOrderSummary() {
    let totalItems = 0;
    let totalAmount = 0;
    let vendorSummary = {};
    
    $('.order-item').each(function() {
        const quantity = parseInt($(this).find('.item-quantity').val()) || 0;
        const price = parseFloat($(this).find('.item-price').val()) || 0;
        const vendorId = $(this).find('.vendor-id').val();
        
        if (quantity > 0 && price > 0 && vendorId) {
            const subtotal = price * quantity;
            totalItems += quantity;
            totalAmount += subtotal;
            
            if (!vendorSummary[vendorId]) {
                const vendorName = $(this).find('.product-select option:selected').data('vendor-name') || 'Unknown Vendor';
                vendorSummary[vendorId] = {
                    name: vendorName,
                    total: 0,
                    items: 0
                };
            }
            
            vendorSummary[vendorId].total += subtotal;
            vendorSummary[vendorId].items += quantity;
        }
    });
    
    $('#total-items').text(totalItems);
    $('#total-amount').text('Rs. ' + totalAmount.toFixed(2));
    
    // Update vendor breakdown if there are multiple vendors
    const vendorKeys = Object.keys(vendorSummary);
    
    if (vendorKeys.length > 1) {
        let breakdownHtml = '<div class="mt-3"><h6>Order breakdown by vendor:</h6><ul class="list-group list-group-flush">';
        
        vendorKeys.forEach(vendorId => {
            const vendor = vendorSummary[vendorId];
            breakdownHtml += `<li class="list-group-item p-2">
                <div class="d-flex justify-content-between">
                    <span>${vendor.name} (${vendor.items} items)</span>
                    <span>Rs. ${vendor.total.toFixed(2)}</span>
                </div>
            </li>`;
        });
        
        breakdownHtml += '</ul><div class="mt-2 text-info"><small>Each vendor will receive a separate order</small></div></div>';
        
        const existingBreakdown = $('#vendor-breakdown');
        if (existingBreakdown.length) {
            existingBreakdown.html(breakdownHtml);
        } else {
            $('.card-body:last').append(`<div id="vendor-breakdown">${breakdownHtml}</div>`);
        }
    } else {
        $('#vendor-breakdown').remove();
    }
}

// End output buffering and send output to browser
ob_end_flush();
</script>
