ALTER TABLE bookings ADD COLUMN down_payment DECIMAL(12,2) DEFAULT 0.00 AFTER guest_count;
ALTER TABLE menu_items ADD COLUMN discount_price DECIMAL(12,2) DEFAULT NULL AFTER price;
ALTER TABLE bookings ADD COLUMN booking_code VARCHAR(20) DEFAULT NULL AFTER customer_email;
