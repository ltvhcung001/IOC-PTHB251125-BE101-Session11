CREATE TABLE flights (
    flight_id SERIAL PRIMARY KEY,
    flight_name VARCHAR(100),
    available_seats INT
);

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    flight_id INT REFERENCES flights(flight_id),
    customer_name VARCHAR(100)
);

INSERT INTO flights (flight_name, available_seats) 
VALUES ('VN123', 3), ('VN456', 2);

-- 1. Tạo Transaction đặt vé thành công
-- Bắt đầu transaction bằng BEGIN;
-- Giảm số ghế của chuyến bay 'VN123' đi 1
-- Thêm bản ghi đặt vé của khách hàng 'Nguyen Van A'
-- Kết thúc bằng COMMIT;
-- Kiểm tra lại dữ liệu bảng flights và bookings
BEGIN;
UPDATE flights 
SET available_seats = available_seats - 1 
WHERE flight_name = 'VN123';

INSERT INTO bookings (flight_id, customer_name) 
VALUES ((SELECT flight_id FROM flights WHERE flight_name = 'VN123'), 'Nguyen Van A');
COMMIT;

-- Kiểm tra lại
SELECT * FROM flights;
SELECT * FROM bookings;

-- 2. Mô phỏng lỗi và Rollback
-- Thực hiện lại các bước trên nhưng nhập sai flight_id trong bảng bookings
-- Gọi ROLLBACK; để hủy toàn bộ thay đổi
-- Kiểm tra lại dữ liệu và chứng minh rằng số ghế không thay đổi

BEGIN;
UPDATE flights 
SET available_seats = available_seats - 1 
WHERE flight_name = 'VN123';
VALUES (9999, 'Khach Hang Loi'); 
ROLLBACK;

SELECT * FROM flights;
SELECT * FROM bookings;
