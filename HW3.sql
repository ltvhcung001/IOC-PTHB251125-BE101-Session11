CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    stock INT,
    price NUMERIC(10, 2)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    total_amount NUMERIC(10, 2),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    subtotal NUMERIC(10, 2)
);

INSERT INTO products (product_name, stock, price) VALUES 
('Laptop', 10, 1000.00),  -- product_id = 1
('Mouse', 5, 50.00);      -- product_id = 2

-- Viết Transaction thực hiện toàn bộ quy trình đặt hàng cho khách "Nguyen Van A" gồm:
-- Mua 2 sản phẩm:
-- product_id = 1, quantity = 2
-- product_id = 2, quantity = 1
-- Nếu một trong hai sản phẩm không đủ hàng, toàn bộ giao dịch phải bị ROLLBACK
-- Nếu thành công, COMMIT và cập nhật chính xác số lượng tồn kho
DO $$
DECLARE
    -- Khai báo biến để lưu trữ giá trị tạm
    v_order_id INT;
    v_price1 NUMERIC;
    v_price2 NUMERIC;
    v_total NUMERIC := 0;
    v_stock1 INT;
    v_stock2 INT;
BEGIN
    SELECT stock, price INTO v_stock1, v_price1 FROM products WHERE product_id = 1;
    SELECT stock, price INTO v_stock2, v_price2 FROM products WHERE product_id = 2;

    IF v_stock1 < 2 THEN
        RAISE EXCEPTION 'Sản phẩm 1 không đủ hàng! Tồn kho hiện tại: %', v_stock1;
    END IF;

    IF v_stock2 < 1 THEN
        RAISE EXCEPTION 'Sản phẩm 2 không đủ hàng! Tồn kho hiện tại: %', v_stock2;
    END IF;

    UPDATE products SET stock = stock - 2 WHERE product_id = 1;
    UPDATE products SET stock = stock - 1 WHERE product_id = 2;

    INSERT INTO orders (customer_name, total_amount) 
    VALUES ('Nguyen Van A', 0)
    RETURNING order_id INTO v_order_id;

    INSERT INTO order_items (order_id, product_id, quantity, subtotal)
    VALUES (v_order_id, 1, 2, v_price1 * 2);
    v_total := v_total + (v_price1 * 2);

    INSERT INTO order_items (order_id, product_id, quantity, subtotal)
    VALUES (v_order_id, 2, 1, v_price2 * 1);
    v_total := v_total + (v_price2 * 1);

    UPDATE orders SET total_amount = v_total WHERE order_id = v_order_id;

    RAISE NOTICE 'Đặt hàng thành công! Order ID: %, Tổng tiền: %', v_order_id, v_total;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Giao dịch bị hủy: %', SQLERRM;
END $$;


-- Mô phỏng lỗi:
-- Giảm tồn kho của một sản phẩm xuống 0, sau đó chạy Transaction đặt hàng
UPDATE products SET stock = 0 WHERE product_id = 1;
DO $$
DECLARE
    -- Khai báo biến để lưu trữ giá trị tạm
    v_order_id INT;
    v_price1 NUMERIC;
    v_price2 NUMERIC;
    v_total NUMERIC := 0;
    v_stock1 INT;
    v_stock2 INT;
BEGIN
    SELECT stock, price INTO v_stock1, v_price1 FROM products WHERE product_id = 1;
    SELECT stock, price INTO v_stock2, v_price2 FROM products WHERE product_id = 2;

    IF v_stock1 < 2 THEN
        RAISE EXCEPTION 'Sản phẩm 1 không đủ hàng! Tồn kho hiện tại: %', v_stock1;
    END IF;

    IF v_stock2 < 1 THEN
        RAISE EXCEPTION 'Sản phẩm 2 không đủ hàng! Tồn kho hiện tại: %', v_stock2;
    END IF;

    UPDATE products SET stock = stock - 2 WHERE product_id = 1;
    UPDATE products SET stock = stock - 1 WHERE product_id = 2;

    INSERT INTO orders (customer_name, total_amount) 
    VALUES ('Nguyen Van A', 0)
    RETURNING order_id INTO v_order_id;

    INSERT INTO order_items (order_id, product_id, quantity, subtotal)
    VALUES (v_order_id, 1, 2, v_price1 * 2);
    v_total := v_total + (v_price1 * 2);

    INSERT INTO order_items (order_id, product_id, quantity, subtotal)
    VALUES (v_order_id, 2, 1, v_price2 * 1);
    v_total := v_total + (v_price2 * 1);

    UPDATE orders SET total_amount = v_total WHERE order_id = v_order_id;

    RAISE NOTICE 'Đặt hàng thành công! Order ID: %, Tổng tiền: %', v_order_id, v_total;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Giao dịch bị hủy: %', SQLERRM;
END $$;

-- Kiểm tra kết quả khi có và không có Transaction
