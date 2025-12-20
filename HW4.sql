CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    balance NUMERIC(12, 2)
);

CREATE TABLE transactions (
    trans_id SERIAL PRIMARY KEY,
    account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(12, 2),
    trans_type VARCHAR(20), -- 'WITHDRAW' hoặc 'DEPOSIT'
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO accounts (customer_name, balance) VALUES ('Nguyen Van A', 10000000);

-- 1. Viết Transaction thực hiện rút tiền
-- Bắt đầu BEGIN;
-- Kiểm tra balance của tài khoản
-- Nếu đủ, trừ số dư và ghi vào bảng transactions
-- Nếu bất kỳ bước nào thất bại → ROLLBACK;
-- Nếu thành công → COMMIT;
DO $$
DECLARE
    v_account_id INT := 1;      -- ID tài khoản muốn rút
    v_amount NUMERIC := 500000; -- Số tiền muốn rút
    v_current_balance NUMERIC;
BEGIN
    SELECT balance INTO v_current_balance 
    FROM accounts WHERE account_id = v_account_id FOR UPDATE;

    IF v_current_balance >= v_amount THEN
        -- Trừ số dư
        UPDATE accounts 
        SET balance = balance - v_amount 
        WHERE account_id = v_account_id;

        INSERT INTO transactions (account_id, amount, trans_type) 
        VALUES (v_account_id, v_amount, 'WITHDRAW');

        RAISE NOTICE 'Giao dịch thành công! Số dư mới: %', v_current_balance - v_amount;
    ELSE
        RAISE EXCEPTION 'Số dư không đủ để thực hiện giao dịch!';
    END IF;
END $$;


-- 2. Mô phỏng lỗi
-- Cố ý chèn lỗi trong bước ghi log (ví dụ nhập sai account_id trong bảng transactions)
-- Quan sát và chứng minh rằng sau khi ROLLBACK, số dư vẫn không thay đổi

-- Kiểm tra số dư trước khi chạy
SELECT * FROM accounts WHERE account_id = 1;

BEGIN;
    UPDATE accounts 
    SET balance = balance - 2000000 
    WHERE account_id = 1;
    --Cố ý chèn lỗi (account_id 9999 không tồn tại)
    INSERT INTO transactions (account_id, amount, trans_type) 
    VALUES (9999, 2000000, 'WITHDRAW'); 
    -- LỖI XUẤT HIỆN Ở ĐÂY: Key (account_id)=(9999) is not present in table "accounts".
    -- Do có lỗi, toàn bộ transaction này sẽ bị hủy bỏ (ROLLBACK) tự động hoặc bạn chạy lệnh:
ROLLBACK;
-- Quan sát
SELECT * FROM accounts WHERE account_id = 1;
-- KẾT QUẢ: Số dư vẫn giữ nguyên như ban đầu, không bị trừ 2 triệu.

-- 3.

-- 1. Chạy một giao dịch hợp lệ (Rút 100k)
BEGIN;
    UPDATE accounts SET balance = balance - 100000 WHERE account_id = 1;
    INSERT INTO transactions (account_id, amount, trans_type) VALUES (1, 100000, 'WITHDRAW');
COMMIT;

-- 2. Chạy tiếp một giao dịch hợp lệ nữa (Rút 200k)
BEGIN;
    UPDATE accounts SET balance = balance - 200000 WHERE account_id = 1;
    INSERT INTO transactions (account_id, amount, trans_type) VALUES (1, 200000, 'WITHDRAW');
COMMIT;

-- 3. Kiểm tra tính toàn vẹn dữ liệu
-- Chạy Transaction nhiều lần, đảm bảo rằng mỗi bản ghi trong transactions tương ứng đúng với một thay đổi balance
SELECT 
    a.customer_name,
    a.balance AS so_du_hien_tai,
    (10000000 - COALESCE((SELECT SUM(amount) FROM transactions WHERE account_id = a.account_id), 0)) AS so_du_tinh_toan
FROM accounts a
WHERE a.account_id = 1;

