-- Users
INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `created_at`) VALUES
(11, 'Rajesh Pokhrel', 'rajesh.pokhrel@example.com', 'password123', 'admin', '2025-02-26 12:00:00'),
(12, 'Sita Thapa', 'sita.thapa@example.com', 'password456', 'vendor', '2025-02-26 12:00:00'),
(13, 'Kamal Sharma', 'kamal.sharma@example.com', 'password789', 'vendor', '2025-02-26 12:00:00'),
(14, 'Pushpa Ranamagar', 'pushpa.ranamagar@example.com', 'password000', 'vendor', '2025-02-26 12:00:00'),
(15, 'Sima Ghimire', 'sima.ghimire@example.com', 'password111', 'customer', '2025-02-26 12:00:00');


-- Vendors
INSERT INTO `vendors` (`id`, `user_id`, `business_name`, `description`, `created_at`) VALUES
(101, 11, 'Beauty Essentials', 'A trusted brand for makeup and skincare products.', '2025-02-26 12:00:00'),
(102, 12, 'Glamour Cosmetics', 'High-end cosmetics and beauty accessories for all skin types.', '2025-02-26 12:00:00'),
(103, 13, 'Radiant Beauty', 'Offering premium skincare products and makeup essentials.', '2025-02-26 12:00:00'),
(104, 14, 'Skin Glow', 'A skincare brand focused on healthy, glowing skin.', '2025-02-26 12:00:00'),
(105, 15, 'Perfect Look', 'Your one-stop shop for beauty, haircare, and skincare products.', '2025-02-26 12:00:00');


-- Categories
INSERT INTO `categories` (`id`, `name`, `created_at`, `description`) VALUES
(1, 'Face Makeup', '2025-02-26 12:00:00', 'Products for face makeup including foundation, concealer, and blush'),
(2, 'Eye Makeup', '2025-02-26 12:00:00', 'Products for eye makeup including eyeshadow, mascara, and eyeliner'),
(3, 'Lip Makeup', '2025-02-26 12:00:00', 'Products for lip makeup including lipstick and lip gloss'),
(4, 'Makeup Tools', '2025-02-26 12:00:00', 'Tools for applying makeup including brushes and sponges'),
(5, 'Makeup Removers', '2025-02-26 12:00:00', 'Products for removing makeup including wipes and cleansers'),
(6, 'Skin Care', '2025-02-26 12:00:00', 'Products for skin care including cleansers, moisturizers, and serums'),
(7, 'Hair Care', '2025-02-26 12:00:00', 'Products for hair care including shampoos, conditioners, and treatments'),
(8, 'Fragrance', '2025-02-26 12:00:00', 'Perfumes and fragrances for men and women'),
(9, 'Nail Care', '2025-02-26 12:00:00', 'Products for nail care including polish and tools'),
(10, 'Men Grooming', '2025-02-26 12:00:00', 'Grooming products for men including razors and shaving kits');

-- Products
INSERT INTO `products` (`id`, `vendor_id`, `category_id`, `name`, `description`, `price`, `stock`, `image_url`, `created_at`) VALUES
(1, 101, 1, 'Foundation', 'A smooth foundation for a flawless base', 29.99, 100, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Foundation', '2025-02-26 12:00:00'),
(2, 101, 1, 'Concealer', 'A concealer to cover blemishes and dark circles', 19.99, 150, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Concealer', '2025-02-26 12:00:00'),
(3, 101, 1, 'Blush', 'A blush to add a pop of color to your cheeks', 14.99, 200, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Blush', '2025-02-26 12:00:00'),
(4, 101, 2, 'Eyeshadow Palette', 'A palette with a variety of eyeshadow colors', 39.99, 80, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Eyeshadow+Palette', '2025-02-26 12:00:00'),
(5, 101, 2, 'Mascara', 'A mascara to lengthen and volumize your lashes', 24.99, 120, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Mascara', '2025-02-26 12:00:00'),
(6, 101, 2, 'Eyeliner', 'A precise eyeliner for defining your eyes', 12.99, 180, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Eyeliner', '2025-02-26 12:00:00'),
(7, 101, 3, 'Lipstick', 'A long-lasting lipstick in various shades', 19.99, 140, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Lipstick', '2025-02-26 12:00:00'),
(8, 101, 3, 'Lip Gloss', 'A shiny lip gloss for a glossy finish', 14.99, 160, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Lip+Gloss', '2025-02-26 12:00:00'),
(9, 101, 4, 'Makeup Brushes', 'A set of brushes for applying makeup', 49.99, 60, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Makeup+Brushes', '2025-02-26 12:00:00'),
(10, 101, 5, 'Makeup Remover Wipes', 'Wipes for removing makeup easily', 9.99, 200, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Makeup+Remover+Wipes', '2025-02-26 12:00:00'),
(11, 103, 6, 'Facial Cleanser', 'A gentle cleanser for all skin types', 19.99, 90, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Facial+Cleanser', '2025-02-26 12:00:00'),
(12, 104, 6, 'Moisturizer', 'A hydrating moisturizer for soft skin', 29.99, 110, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Moisturizer', '2025-02-26 12:00:00'),
(13, 102, 6, 'Serum', 'A brightening serum for glowing skin', 39.99, 130, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Serum', '2025-02-26 12:00:00'),
(14, 103, 7, 'Shampoo', 'A nourishing shampoo for healthy hair', 19.99, 100, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Shampoo', '2025-02-26 12:00:00'),
(15, 103, 7, 'Conditioner', 'A moisturizing conditioner for soft hair', 18.99, 140, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Conditioner', '2025-02-26 12:00:00'),
(16, 103, 7, 'Hair Treatment', 'A deep conditioning treatment for damaged hair', 34.99, 90, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Hair+Treatment', '2025-02-26 12:00:00'),
(17, 104, 8, 'Perfume', 'A luxurious fragrance for women', 49.99, 150, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Perfume', '2025-02-26 12:00:00'),
(18, 104, 8, 'Cologne', 'A refreshing cologne for men', 39.99, 120, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Cologne', '2025-02-26 12:00:00'),
(19, 105, 9, 'Nail Polish', 'A high-quality nail polish in vibrant colors', 9.99, 200, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Nail+Polish', '2025-02-26 12:00:00'),
(20, 105, 9, 'Nail Clippers', 'Durable nail clippers for perfect trimming', 5.99, 250, 'https://dummyimage.com/600x400/786278/d43bb8.jpg&text=GlamUp-Nail+Clippers', '2025-02-26 12:00:00');
