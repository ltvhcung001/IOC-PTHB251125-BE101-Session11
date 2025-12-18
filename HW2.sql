CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    owner_name VARCHAR(100),
    balance NUMERIC(10,2)
);

INSERT INTO accounts (owner_name, balance)
VALUES ('A', 500.00), ('B', 300.00);

-- 1. Thực hiện giao dịch chuyển tiền hợp lệ
-- Dùng BEGIN; để bắt đầu transaction
-- Cập nhật giảm số dư của A, tăng số dư của B
-- Dùng COMMIT; để hoàn tất
-- Kiểm tra số dư mới của cả hai tài khoản
BEGIN;
UPDATE accounts 
SET balance = balance - 100.00 
WHERE owner_name = 'A';

UPDATE accounts 
SET balance = balance + 100.00 
WHERE owner_name = 'B';
COMMIT;

-- d. Kiểm tra kết quả: A còn 400, B lên 400
SELECT * FROM accounts;

-- 2. Thử mô phỏng lỗi và Rollback
-- Lặp lại quy trình trên, nhưng cố ý nhập sai account_id của người nhận
-- Gọi ROLLBACK; khi xảy ra lỗi
-- Kiểm tra lại số dư, đảm bảo không có thay đổi

BEGIN;
UPDATE accounts 
SET balance = balance - 100.00 
WHERE owner_name = 'A';

UPDATE accounts 
SET balance = balance + 100.00 
WHERE account_id = 999; 
ROLLBACK;

-- Kết quả: A vẫn là 400 (như kết thúc Phần 2), tiền không bị trừ.
SELECT * FROM accounts;
