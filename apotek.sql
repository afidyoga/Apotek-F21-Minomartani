-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 18 Feb 2025 pada 16.56
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `apotek`
--

DELIMITER $$
--
-- Prosedur
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_batch_procedure` (IN `pemasok_param` CHAR(36), IN `product_id_param` CHAR(36), IN `detail_id_param` CHAR(36), IN `harga_beli_param` INT, IN `expired_date_param` TIMESTAMP, IN `stock_param` INT)   BEGIN
            DECLARE existing_invoice_id CHAR(36);

            DECLARE is_transaction_successful BOOLEAN DEFAULT TRUE;

            DECLARE EXIT HANDLER FOR SQLEXCEPTION
            BEGIN
                SET is_transaction_successful = FALSE;
                ROLLBACK;
            END;

            START TRANSACTION;

            SELECT bi.buying_invoice_id INTO existing_invoice_id
            FROM buying_invoices bi
            JOIN suppliers s ON bi.supplier_name COLLATE utf8mb4_unicode_ci = s.supplier COLLATE utf8mb4_unicode_ci
            WHERE s.supplier_id COLLATE utf8mb4_unicode_ci = pemasok_param COLLATE utf8mb4_unicode_ci
                AND DATE_FORMAT(bi.order_date, '%Y-%m-%d') = DATE_FORMAT(NOW(), '%Y-%m-%d')
            LIMIT 1;

            IF existing_invoice_id IS NULL THEN
                INSERT INTO buying_invoices (buying_invoice_id, supplier_name, order_date)
                VALUES (UUID(), (SELECT s.supplier COLLATE utf8mb4_unicode_ci FROM suppliers s WHERE s.supplier_id COLLATE utf8mb4_unicode_ci = pemasok_param COLLATE utf8mb4_unicode_ci), NOW());

                SELECT buying_invoice_id INTO existing_invoice_id
                FROM buying_invoices
                WHERE supplier_name COLLATE utf8mb4_unicode_ci = (SELECT s.supplier COLLATE utf8mb4_unicode_ci FROM suppliers s WHERE s.supplier_id COLLATE utf8mb4_unicode_ci = pemasok_param COLLATE utf8mb4_unicode_ci)
                AND DATE_FORMAT(order_date, '%Y-%m-%d') = DATE_FORMAT(NOW(), '%Y-%m-%d')
                ORDER BY order_date DESC
                LIMIT 1;
            END IF;

            INSERT INTO product_details (product_id, detail_id, product_buy_price, product_expired, product_stock)
            VALUES (product_id_param, detail_id_param, harga_beli_param, expired_date_param, stock_param);

            INSERT INTO buying_invoice_details (buying_detail_id, buying_invoice_id, product_name, product_buy_price, exp_date, quantity)
            VALUES (UUID(), existing_invoice_id, (SELECT product_name FROM products WHERE product_id = product_id_param COLLATE utf8mb4_unicode_ci), harga_beli_param, expired_date_param, stock_param);

            IF is_transaction_successful THEN
                COMMIT;
            END IF;
        END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_product_procedure` (IN `product_id` CHAR(36), IN `product_name` VARCHAR(255), IN `product_status` ENUM('aktif','tidak aktif','exp'), IN `gambar_obat_file` VARCHAR(255), IN `desc_id` CHAR(36), IN `kategori` CHAR(36), IN `golongan` CHAR(36), IN `satuan_obat` CHAR(36), IN `NIE` VARCHAR(15), IN `tipe` VARCHAR(255), IN `pemasok` CHAR(36), IN `produksi` VARCHAR(255), IN `deskripsi` LONGTEXT, IN `efek_samping` LONGTEXT, IN `dosis` LONGTEXT, IN `indikasi` LONGTEXT, IN `peringatan` LONGTEXT, IN `harga_beli` INT, IN `expired_date` TIMESTAMP, IN `harga_jual` INT, IN `stock` INT, IN `detail_id` CHAR(36))   BEGIN
        
            DECLARE existing_invoice_id CHAR(36);

            DECLARE is_transaction_successful BOOLEAN DEFAULT TRUE;

            DECLARE EXIT HANDLER FOR SQLEXCEPTION
            BEGIN
                SET is_transaction_successful = FALSE;
                ROLLBACK;
            END;

            START TRANSACTION;

            SELECT bi.buying_invoice_id INTO existing_invoice_id
            FROM buying_invoices bi
            JOIN suppliers s ON bi.supplier_name COLLATE utf8mb4_unicode_ci = s.supplier COLLATE utf8mb4_unicode_ci
            WHERE s.supplier_id COLLATE utf8mb4_unicode_ci = pemasok
                AND DATE_FORMAT(bi.order_date, '%Y-%m-%d') = DATE_FORMAT(NOW(), '%Y-%m-%d')
            LIMIT 1;

            IF existing_invoice_id IS NULL THEN
                INSERT INTO buying_invoices (buying_invoice_id, supplier_name, order_date)
                VALUES (UUID(), (SELECT s.supplier COLLATE utf8mb4_unicode_ci FROM suppliers s WHERE s.supplier_id COLLATE utf8mb4_unicode_ci = pemasok), NOW());

                SELECT buying_invoice_id INTO existing_invoice_id
                FROM buying_invoices
                WHERE supplier_name COLLATE utf8mb4_unicode_ci = (SELECT s.supplier COLLATE utf8mb4_unicode_ci FROM suppliers s WHERE s.supplier_id COLLATE utf8mb4_unicode_ci = pemasok)
                AND DATE_FORMAT(order_date, '%Y-%m-%d') = DATE_FORMAT(NOW(), '%Y-%m-%d')
                ORDER BY order_date DESC
                LIMIT 1;
            END IF;

            INSERT INTO product_descriptions (description_id, category_id, group_id, unit_id, product_DPN, product_type, supplier_id, product_manufacture, product_description, product_sideEffect, product_dosage, product_indication, product_notice, product_photo)
            VALUES (desc_id, kategori, golongan, satuan_obat, NIE, tipe, pemasok, produksi, deskripsi, efek_samping, dosis, indikasi, peringatan, gambar_obat_file);

            INSERT INTO products (product_id, product_status, product_name, product_sell_price, description_id)
            VALUES (product_id, product_status, product_name, harga_jual, desc_id);

            INSERT INTO product_details (product_id, detail_id, product_buy_price, product_expired, product_stock)
            VALUES (product_id, detail_id, harga_beli, expired_date, stock);

            INSERT INTO buying_invoice_details (buying_detail_id, buying_invoice_id, product_name, product_buy_price, exp_date, quantity)
            VALUES (UUID(), existing_invoice_id, product_name, harga_beli, expired_date, stock);

            IF is_transaction_successful THEN
                COMMIT;
            END IF;
            
        END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_log` (IN `invoiceCode` VARCHAR(255), IN `cashierName` VARCHAR(255), IN `target` VARCHAR(100), IN `description` VARCHAR(6), IN `oldValue` LONGTEXT, IN `newValue` LONGTEXT)   BEGIN
            INSERT INTO logs (log_id, log_time, invoice_code, username, log_target, log_description, old_value, new_value)
            VALUES (UUID(), NOW(), invoiceCode, cashierName, target, description, oldValue, newValue);
        END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `order_fail` (IN `invoiceID` VARCHAR(36), IN `cashierName` VARCHAR(255), IN `comments` LONGTEXT)   BEGIN
            UPDATE selling_invoices SET order_status = 'Gagal', cashier_name = cashierName, reject_comment = comments, order_complete = NOW()
            WHERE selling_invoice_id COLLATE utf8mb4_unicode_ci = invoiceID COLLATE utf8mb4_unicode_ci; 
        END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `order_refund` (IN `invoiceID` VARCHAR(36), IN `cashierName` VARCHAR(255), IN `comments` LONGTEXT)   BEGIN
            UPDATE selling_invoices 
            SET order_status = 'Menunggu Pengembalian', cashier_name = cashierName, reject_comment = comments 
            WHERE selling_invoice_id COLLATE utf8mb4_unicode_ci = invoiceID COLLATE utf8mb4_unicode_ci; 
        END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `order_success` (IN `invoiceID` CHAR(36), IN `cashierName` VARCHAR(255))   BEGIN
            UPDATE selling_invoices
            SET order_status = 'Menunggu Pengambilan', cashier_name = cashierName
            WHERE selling_invoice_id COLLATE utf8mb4_unicode_ci = invoiceID COLLATE utf8mb4_unicode_ci;
        END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `stock_back` (IN `stock` INT, IN `product` CHAR(36))   BEGIN 
            UPDATE product_details 
            SET product_stock = product_stock + stock
            WHERE product_id COLLATE utf8mb4_unicode_ci = product COLLATE utf8mb4_unicode_ci
            ORDER BY product_expired LIMIT 1;
        END$$

--
-- Fungsi
--
CREATE DEFINER=`root`@`localhost` FUNCTION `Total_Harga` (`jumlah` INT, `harga` INT) RETURNS INT(11) DETERMINISTIC BEGIN
            RETURN (harga * jumlah);
        END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Total_Keuntungan` (`tanggal_awal` TIMESTAMP, `tanggal_akhir` TIMESTAMP) RETURNS INT(11) DETERMINISTIC BEGIN
            DECLARE total_pemasukan INT;
            DECLARE total_pengeluaran INT;
            
            SET total_pemasukan = COALESCE(total_pemasukan(tanggal_awal, tanggal_akhir), 0);
            SET total_pengeluaran = COALESCE(total_pengeluaran(tanggal_awal, tanggal_akhir), 0);
            
            RETURN (total_pemasukan - total_pengeluaran);
        END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Total_Pemasukan` (`tanggal_awal` TIMESTAMP, `tanggal_akhir` TIMESTAMP) RETURNS INT(11) DETERMINISTIC BEGIN
            DECLARE Total_Pemasukan INT;
        
            SELECT SUM(total_harga(b.quantity, b.product_sell_price)) AS total_pemasukan INTO Total_Pemasukan
            FROM selling_invoices a
            JOIN selling_invoice_details b ON a.selling_invoice_id = b.selling_invoice_id
            WHERE a.order_date BETWEEN tanggal_awal AND tanggal_akhir
            AND (a.order_status = 'Berhasil' OR a.order_status = 'Offline' OR a.order_status = 'Gagal');

            RETURN (Total_Pemasukan);
        END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Total_Pengeluaran` (`tanggal_awal` TIMESTAMP, `tanggal_akhir` TIMESTAMP) RETURNS INT(11) DETERMINISTIC BEGIN
            DECLARE Total_Pengeluaran INT;
        
            SELECT SUM(total_harga(b.quantity, b.product_buy_price)) AS total_pengeluaran INTO Total_Pengeluaran
            FROM buying_invoices a
            JOIN buying_invoice_details b ON a.buying_invoice_id = b.buying_invoice_id
            WHERE a.order_date BETWEEN tanggal_awal AND tanggal_akhir;

            RETURN (Total_Pengeluaran);
        END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `bestsellerproduct_view`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `bestsellerproduct_view` (
`product_name` varchar(255)
,`product_status` enum('aktif','tidak aktif','exp')
,`jumlah_kemunculan` bigint(21)
);

-- --------------------------------------------------------

--
-- Struktur dari tabel `buying_invoices`
--

CREATE TABLE `buying_invoices` (
  `buying_invoice_id` char(36) NOT NULL,
  `order_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `supplier_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `buying_invoices`
--

INSERT INTO `buying_invoices` (`buying_invoice_id`, `order_date`, `supplier_name`) VALUES
('61ec74f9-6c23-3d9c-89fd-b280177f76ce', '2019-01-11 00:18:09', 'Mekada Abadi'),
('a71dd466-6ca0-3082-99da-aec0f1a09a21', '2022-03-16 01:29:01', 'Mensa Binasukses'),
('b83d2a88-0757-3273-bf15-c57bba569a6b', '2023-06-25 18:03:45', 'Mekada Abadi'),
('f243ce6f-53e6-3a26-a826-9ea36ff1f9fe', '2018-03-14 05:53:50', 'Global Mitra Prima'),
('fc1466de-5099-323d-820d-9daab63c8820', '2024-04-28 19:20:34', 'Global Mitra Prima');

--
-- Trigger `buying_invoices`
--
DELIMITER $$
CREATE TRIGGER `cannot_delete_buying_invoice` BEFORE DELETE ON `buying_invoices` FOR EACH ROW BEGIN 
            SIGNAL SQLSTATE '45000' SET
            MESSAGE_TEXT = 'Tidak Dapat Menghapus Invoice';
        END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `buying_invoice_details`
--

CREATE TABLE `buying_invoice_details` (
  `buying_detail_id` char(36) NOT NULL,
  `buying_invoice_id` char(36) NOT NULL,
  `product_name` varchar(255) NOT NULL,
  `product_buy_price` int(11) NOT NULL,
  `exp_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `buying_invoice_details`
--

INSERT INTO `buying_invoice_details` (`buying_detail_id`, `buying_invoice_id`, `product_name`, `product_buy_price`, `exp_date`, `quantity`) VALUES
('012aeace-ce1b-3e5a-9386-e1086fb465ac', 'fc1466de-5099-323d-820d-9daab63c8820', 'Animi qui odit quis nulla.', 96393, '1972-12-26 03:35:41', 20),
('03bad98a-3ef3-3b5e-a23f-5b1267243458', '61ec74f9-6c23-3d9c-89fd-b280177f76ce', 'Quasi exercitationem sed accusamus quod.', 76614, '1984-11-27 20:56:02', 15),
('0be6f29c-b7a8-3092-8c7f-b22f271793be', 'b83d2a88-0757-3273-bf15-c57bba569a6b', 'Est quo sit provident earum qui.', 55246, '2016-07-05 12:26:37', 16),
('0c8f8543-9791-39b4-9b23-ffda69d8862c', 'f243ce6f-53e6-3a26-a826-9ea36ff1f9fe', 'Ut soluta dolore at facilis qui et nulla.', 31206, '2007-01-06 22:31:02', 19),
('2d479bda-1eed-39a2-b611-529137378ea1', 'f243ce6f-53e6-3a26-a826-9ea36ff1f9fe', 'Sint error tempora architecto dolor id non a.', 77747, '1972-04-07 15:26:33', 15),
('3312517c-a30f-3088-b596-27066841cb38', 'b83d2a88-0757-3273-bf15-c57bba569a6b', 'Dolor illum nobis et molestias sit non sint.', 50842, '2012-12-13 17:38:53', 9),
('3986a0d9-9949-32fc-8648-1e838d157409', 'b83d2a88-0757-3273-bf15-c57bba569a6b', 'Est voluptas voluptatem distinctio inventore.', 98039, '1979-04-29 15:46:35', 1),
('3ab7eb2f-c019-3129-8a4e-e8d85748ebdd', '61ec74f9-6c23-3d9c-89fd-b280177f76ce', 'Fugit voluptatem cum et et facere est.', 21676, '1986-11-12 05:30:36', 17),
('5c4ed73c-843e-30f9-9e71-1e812df08807', 'a71dd466-6ca0-3082-99da-aec0f1a09a21', 'Occaecati est sit quo eius magni.', 52602, '1991-08-24 15:09:14', 17),
('750b99a1-f2d0-340b-b0f6-a2a442ddfd2c', 'b83d2a88-0757-3273-bf15-c57bba569a6b', 'Sit nihil explicabo veritatis fugit omnis.', 25349, '2000-01-13 09:42:09', 2),
('7e4871a9-e013-3c8b-b810-d09fa39e7903', 'fc1466de-5099-323d-820d-9daab63c8820', 'Asperiores molestiae ab soluta unde unde.', 33511, '1989-02-20 06:04:34', 3),
('b45ac10f-e665-3974-a265-c65c11122fb0', 'fc1466de-5099-323d-820d-9daab63c8820', 'Voluptatibus optio magnam ut veniam culpa eos.', 90415, '1988-12-21 22:04:41', 13),
('c3f14c9b-0259-3723-95de-5148c5207087', 'f243ce6f-53e6-3a26-a826-9ea36ff1f9fe', 'Quisquam facere provident alias excepturi.', 6760, '2009-03-26 14:52:06', 18),
('cba8eb31-a28e-382d-a384-073d94733e05', 'f243ce6f-53e6-3a26-a826-9ea36ff1f9fe', 'Nihil laudantium officia commodi et.', 22337, '2005-09-15 00:27:12', 17),
('d0f4e5e6-e56a-3a74-92fd-9be437629b76', 'fc1466de-5099-323d-820d-9daab63c8820', 'Beatae excepturi et quia eum sit voluptatum et.', 64691, '2016-02-14 11:06:50', 6),
('db3e383f-222f-35d6-8119-c8c680579633', '61ec74f9-6c23-3d9c-89fd-b280177f76ce', 'Sint error tempora architecto dolor id non a.', 22668, '2008-11-02 01:12:19', 7),
('dc5297b3-d15a-30ba-81a5-0cd58b3155f8', 'a71dd466-6ca0-3082-99da-aec0f1a09a21', 'Culpa error et ratione cumque assumenda.', 92990, '2017-02-06 17:25:49', 10),
('ece14529-6d5f-38b5-ae67-d495a6cf24ef', 'b83d2a88-0757-3273-bf15-c57bba569a6b', 'Sit est cumque repellendus repudiandae.', 95707, '1998-03-23 20:37:55', 13),
('f93fa911-eda6-3a08-b720-fa7f893797eb', 'a71dd466-6ca0-3082-99da-aec0f1a09a21', 'Quae aut ea quasi ut molestias.', 65795, '2022-06-19 12:43:07', 1),
('f9c004ec-b2b7-36c3-8ce3-128ae2eb1ebc', '61ec74f9-6c23-3d9c-89fd-b280177f76ce', 'Eos eveniet totam sequi nemo.', 85459, '2024-07-22 01:45:39', 18);

-- --------------------------------------------------------

--
-- Struktur dari tabel `carts`
--

CREATE TABLE `carts` (
  `cart_id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `product_id` char(36) NOT NULL,
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `carts`
--

INSERT INTO `carts` (`cart_id`, `user_id`, `product_id`, `quantity`) VALUES
('13bdeb07-68a6-3b25-b52d-122517b57b14', 'e45b61f5-e663-3dae-9c66-7c04f76dc1ff', '42ef317a-a6ff-3fcb-ac93-bf9cfdc5e4da', 4),
('14f061b6-9fd5-342c-8924-4d982b47608a', 'b5112031-4c58-3bd0-9a66-cf12c56949dd', '1c64ee27-d4dd-31c6-8f31-ceaa05dd9154', 5),
('1afab99d-894f-37e1-8fd8-b048a30c63a7', 'b5112031-4c58-3bd0-9a66-cf12c56949dd', '48ebac60-b705-3212-aff9-fafba57b92ce', 4),
('1b5c282c-4ccc-3f7f-952e-d873095936df', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', '9319db65-9b38-3285-a53d-90ee22e534b3', 7),
('1ece69b5-1152-303d-af0e-bd1102d5647e', '8170ebb2-f923-3822-adb3-c1a10a9572d6', '685df6ec-fefb-31ba-9f92-1aa78c528105', 9),
('20f0324d-2063-36ff-86ba-acb8890792d8', '8170ebb2-f923-3822-adb3-c1a10a9572d6', 'b0de50b5-0caf-333c-9ca5-761429925f17', 8),
('28c9194e-2ffc-391b-8d89-bca7e405aab1', '5756b26d-5bb1-3b61-a441-5fa214a7c637', 'b424959e-e85d-3e6e-95ac-2fa39955955a', 9),
('2c8f22d4-6365-3569-8e0f-58416392cb11', 'b5112031-4c58-3bd0-9a66-cf12c56949dd', '685df6ec-fefb-31ba-9f92-1aa78c528105', 4),
('2f80e247-6ba9-362c-badd-ec298c8dc39f', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', '1bdfb774-0c11-3bd1-8682-861c66ed256a', 4),
('36cacce0-1e66-36cf-964b-e5360704946e', 'e45b61f5-e663-3dae-9c66-7c04f76dc1ff', 'bf97831a-9836-3809-ac51-01094e4cbbd5', 8),
('43e30f0b-73ae-3970-b098-6d7ac353b02a', '6f5616cb-9679-329b-ae1c-0373d177860d', '4f4f3c0a-9f0e-3b19-9978-133910980efe', 2),
('46a84934-a2e7-37e3-b571-3277cf06dae8', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', '7bee6455-edd0-3b1b-b808-c623b7a0638f', 10),
('47f83775-1fd4-342f-846d-b671f2b3f782', 'b5112031-4c58-3bd0-9a66-cf12c56949dd', '15d21639-b534-39b9-b87e-775ae6aa2752', 10),
('5d50d617-b661-372e-8920-75a6457fb79f', 'fa61d061-116b-3bd5-a805-1693ae311c3d', 'ab95b8c4-2279-3242-8e01-042d87d6f723', 7),
('6f21004b-b671-31cf-8189-cf16ebd9eece', '8170ebb2-f923-3822-adb3-c1a10a9572d6', 'b424959e-e85d-3e6e-95ac-2fa39955955a', 6),
('7202653f-c522-3d42-a671-1c095191b4c3', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', '8b28808b-6316-3128-a601-945b4976d130', 9),
('76d68787-be7c-3a4d-95f0-09423153c25d', 'fa61d061-116b-3bd5-a805-1693ae311c3d', '48ebac60-b705-3212-aff9-fafba57b92ce', 8),
('81493af3-7be4-3787-9fa8-3a542863d8e5', 'dd26224b-5f69-3935-9f43-dbb7a0cd0daf', '4f4f3c0a-9f0e-3b19-9978-133910980efe', 9),
('8b2a9032-9e1f-35c0-a611-227e025f3f08', '9995c553-fb5c-35f4-bc50-2f1d608729ff', '65482e67-259f-3e21-aa26-01dbfac1b912', 6),
('8d09c692-73f5-3940-bbae-1289bdc0fee8', '6f5616cb-9679-329b-ae1c-0373d177860d', 'ab95b8c4-2279-3242-8e01-042d87d6f723', 9),
('96654367-a745-3b0f-9806-c22c49ff6e36', '9995c553-fb5c-35f4-bc50-2f1d608729ff', '7ab7b981-d342-353e-9560-f4cb566b762f', 2),
('9c5813ea-658f-3444-ab82-2c2a500c34db', 'dd26224b-5f69-3935-9f43-dbb7a0cd0daf', '89591f8c-f9d2-3a57-bdb4-87ed25292fb3', 8),
('a3934331-08bf-324c-9367-7ce99da5bcf7', '5756b26d-5bb1-3b61-a441-5fa214a7c637', '65482e67-259f-3e21-aa26-01dbfac1b912', 10),
('ae5f6ab6-1eb3-3d10-9f2c-afa065b70760', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', 'f2c9334a-1520-3657-9be0-3b9aaaca05af', 10),
('c54f42fe-db13-3bcb-9814-aa521d02f572', '8170ebb2-f923-3822-adb3-c1a10a9572d6', 'f0b5c97e-252a-3bbf-b59a-f676219fe466', 7),
('ce201709-4833-3a6d-9df4-826f88e1e3da', 'fa61d061-116b-3bd5-a805-1693ae311c3d', 'f0b5c97e-252a-3bbf-b59a-f676219fe466', 8),
('d72ea160-09a6-3a0b-a00d-e6359395ff7d', 'dd26224b-5f69-3935-9f43-dbb7a0cd0daf', '685df6ec-fefb-31ba-9f92-1aa78c528105', 8),
('eb477d4a-0f2b-32ad-a4ea-680de8adcc2a', '9995c553-fb5c-35f4-bc50-2f1d608729ff', '0fec533b-7f50-3ef5-8c89-5b1646859b98', 10),
('eb8a571f-c927-3c27-b561-fcb54500cb4a', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', '0fec533b-7f50-3ef5-8c89-5b1646859b98', 2),
('fa974aee-b5e0-3fbd-af06-c684ff923691', '8170ebb2-f923-3822-adb3-c1a10a9572d6', '1bdfb774-0c11-3bd1-8682-861c66ed256a', 9);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `cart_view`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `cart_view` (
`cart_id` char(36)
,`user_id` char(36)
,`product_id` char(36)
,`product_photo` varchar(255)
,`product_name` varchar(255)
,`category` varchar(100)
,`product_type` enum('umum','resep dokter')
,`product_stock` decimal(32,0)
,`product_expired` timestamp
,`product_sell_price` int(11)
,`quantity` int(11)
,`total_harga` int(11)
);

-- --------------------------------------------------------

--
-- Struktur dari tabel `cashiers`
--

CREATE TABLE `cashiers` (
  `cashier_id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `cashier_phone` varchar(14) NOT NULL,
  `cashier_gender` enum('pria','wanita') NOT NULL,
  `cashier_address` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `cashiers`
--

INSERT INTO `cashiers` (`cashier_id`, `user_id`, `cashier_phone`, `cashier_gender`, `cashier_address`) VALUES
('eaa965a8-ef47-3516-a6c4-e4a888c84e02', 'ebe44704-9623-3452-b23d-aebffafe6dad', '084265475916', 'wanita', 'Ab voluptas architecto quisquam dolorem velit illum sunt aspernatur animi ad quae hic.');

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `cashier_view`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `cashier_view` (
`user_id` char(36)
,`username` varchar(255)
,`email` varchar(255)
,`password` varchar(255)
,`role` enum('owner','cashier','user')
,`cashier_phone` varchar(14)
,`cashier_gender` enum('pria','wanita')
,`cashier_address` varchar(150)
);

-- --------------------------------------------------------

--
-- Struktur dari tabel `categories`
--

CREATE TABLE `categories` (
  `category_id` char(36) NOT NULL,
  `category` varchar(100) NOT NULL,
  `category_image` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `categories`
--

INSERT INTO `categories` (`category_id`, `category`, `category_image`) VALUES
('4d65dee3-2837-39a2-9e3a-db3afb96e5b0', 'Pencernaan', 'Pencernaan.png'),
('55ddcfa7-7192-3752-b7c2-7ebb4bd26c71', 'Kesehatan Wanita', 'Kesehatan Wanita.png'),
('91e3d4d9-cd51-349b-9e07-1ed45b1d4b8f', 'Alergi', 'Alergi.png'),
('93845cdc-ed09-3bf6-bd78-1152c94718eb', 'Asam Urat', 'Asam Urat.png'),
('ca610106-eea9-3226-ad42-fc42086314dd', 'Diabetes', 'Diabetes.png'),
('d8f0aa52-eb4e-3a1d-addc-776c13fdf6bd', 'Hipertensi', 'Hipertensi.png'),
('dc1a7b6b-ede8-3c2e-bed4-c058f6c7acc7', 'Demam', 'Demam.png'),
('fa84f808-91c6-3715-b90d-897b1c2d5d4c', 'Flu dan Batuk', 'Flu dan Batuk.png');

-- --------------------------------------------------------

--
-- Struktur dari tabel `customers`
--

CREATE TABLE `customers` (
  `customer_id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `customer_phone` varchar(14) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `customers`
--

INSERT INTO `customers` (`customer_id`, `user_id`, `customer_phone`) VALUES
('2ed9c708-41b8-3fa0-bec2-7421414535db', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', '083397809858'),
('61241a08-fddb-383e-9587-9147da996205', 'fa61d061-116b-3bd5-a805-1693ae311c3d', '083153557246'),
('6970feaf-95b0-3c32-a7a6-059e1202d19a', '9995c553-fb5c-35f4-bc50-2f1d608729ff', '089485105373'),
('8ae205a2-62ee-3802-b904-7c04948add91', '5756b26d-5bb1-3b61-a441-5fa214a7c637', '088021701185'),
('a7bb095a-a842-3d2a-910c-282cdd01f4fb', '8170ebb2-f923-3822-adb3-c1a10a9572d6', '089979579666'),
('d53b776d-60fd-36e2-afb8-b7ad98509cb0', 'e45b61f5-e663-3dae-9c66-7c04f76dc1ff', '088063138573'),
('ee838558-64a1-33d2-8452-7f7699c8b391', 'b5112031-4c58-3bd0-9a66-cf12c56949dd', '088670721462'),
('f0e24fd7-025e-3253-b87f-21ea5dee1de3', 'dd26224b-5f69-3935-9f43-dbb7a0cd0daf', '088399384588'),
('f4eee792-af41-4aba-9d76-a374cfb72c82', '1de85640-defd-4a3e-bfe3-16a25114a9e1', NULL),
('fbf4ae2e-c7e4-354d-a2a3-41230fe4695b', '6f5616cb-9679-329b-ae1c-0373d177860d', '083224265075');

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `customer_view`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `customer_view` (
`user_id` char(36)
,`username` varchar(255)
,`email` varchar(255)
,`password` varchar(255)
,`role` enum('owner','cashier','user')
,`customer_phone` varchar(14)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `expired_product_view`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `expired_product_view` (
`product_name` varchar(255)
,`supplier` varchar(255)
,`product_stock` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Struktur dari tabel `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `groups`
--

CREATE TABLE `groups` (
  `group_id` char(36) NOT NULL,
  `group` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `groups`
--

INSERT INTO `groups` (`group_id`, `group`) VALUES
('1d9706c4-c1bd-31f1-bfd4-40d63c22074d', 'Bebas'),
('79c8cac2-5264-3c8a-b02f-6657c71dfc2f', 'Bebas Terbatas'),
('d0cea926-721d-3f5e-9aa0-f5f9f2f087e2', 'Keras'),
('3da63f41-fcb5-3aa8-953c-589f77077e40', 'Narkotika');

-- --------------------------------------------------------

--
-- Struktur dari tabel `information`
--

CREATE TABLE `information` (
  `information_id` char(36) NOT NULL,
  `apotic_name` varchar(255) NOT NULL,
  `apotic_web_name` varchar(255) NOT NULL,
  `SIA_number` varchar(50) NOT NULL,
  `SIPA_number` varchar(50) NOT NULL,
  `apotic_owner` varchar(100) NOT NULL,
  `apotic_address` varchar(100) NOT NULL,
  `monday_schedule` varchar(25) NOT NULL,
  `tuesday_schedule` varchar(25) NOT NULL,
  `wednesday_schedule` varchar(25) NOT NULL,
  `thursday_schedule` varchar(25) NOT NULL,
  `friday_schedule` varchar(25) NOT NULL,
  `saturday_schedule` varchar(25) NOT NULL,
  `sunday_schedule` varchar(25) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `information`
--

INSERT INTO `information` (`information_id`, `apotic_name`, `apotic_web_name`, `SIA_number`, `SIPA_number`, `apotic_owner`, `apotic_address`, `monday_schedule`, `tuesday_schedule`, `wednesday_schedule`, `thursday_schedule`, `friday_schedule`, `saturday_schedule`, `sunday_schedule`) VALUES
('fea7c744-2f55-3de7-a84c-b19ace237925', 'Apotik Jati Negara', 'www.ApotikJatiNegara.com', '0321/SK-ADP/SPMTPSP/JKT/3.2/IX/2024', '3152/SDP/DAMTSPU/JKT/3.1/IX/2024', 'apt. Lala Musana, S.Si.', 'Jl. Suka Lama No.29, Jakarta', '09.00 - 20.00', '09.00 - 20.00', '09.00 - 20.00', '09.00 - 20.00', '09.00 - 20.00', '09.00 - 20.00', '13.30 - 20.00');

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `last_transaction_view`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `last_transaction_view` (
`tanggal_transaksi` timestamp
,`invoice_code` varchar(36)
,`tipe_transaksi` varchar(11)
,`metode_pembayaran` varchar(255)
,`total_pengeluaran` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Struktur dari tabel `logs`
--

CREATE TABLE `logs` (
  `log_id` char(36) NOT NULL,
  `log_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `invoice_code` varchar(255) DEFAULT NULL,
  `username` varchar(255) NOT NULL,
  `log_target` varchar(100) NOT NULL,
  `log_description` enum('insert','update','delete') NOT NULL,
  `old_value` longtext NOT NULL,
  `new_value` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Trigger `logs`
--
DELIMITER $$
CREATE TRIGGER `cannot_delete_log` BEFORE DELETE ON `logs` FOR EACH ROW BEGIN 
            SIGNAL SQLSTATE '45000' SET
            MESSAGE_TEXT = 'Tidak Dapat Menghapus Log';
        END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `cannot_update_log` BEFORE UPDATE ON `logs` FOR EACH ROW BEGIN 
            SIGNAL SQLSTATE '45000' SET
            MESSAGE_TEXT = 'Tidak Dapat Mengubah Log';
        END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '2014_10_12_000000_create_users_table', 1),
(2, '2014_10_12_100000_create_password_reset_tokens_table', 1),
(3, '2019_08_19_000000_create_failed_jobs_table', 1),
(4, '2019_12_14_000001_create_personal_access_tokens_table', 1),
(5, '2023_10_30_153907_create_cashiers_table', 1),
(6, '2023_10_30_155910_create_customers_table', 1),
(7, '2023_11_01_165431_create_categories_table', 1),
(8, '2023_11_01_172806_create_units_table', 1),
(9, '2023_11_01_173649_create_groups_table', 1),
(10, '2023_11_01_180454_create_suppliers_table', 1),
(11, '2023_11_02_153409_create_product_descriptions_table', 1),
(12, '2023_11_02_172800_create_products_table', 1),
(13, '2023_11_02_173800_create_product_details_table', 1),
(14, '2023_11_03_160430_create_selling_invoices_table', 1),
(15, '2023_11_03_172649_create_selling_invoice_details_table', 1),
(16, '2023_11_06_163104_create_buying_invoices_table', 1),
(17, '2023_11_06_170123_create_buying_invoice_details_table', 1),
(18, '2023_11_06_171917_create_information_table', 1),
(19, '2023_11_06_175340_create_logs_table', 1),
(20, '2023_11_12_065004_create_carts_table', 1),
(21, '2023_11_12_140834_create_product_view', 1),
(22, '2023_11_22_181459_best_seller_product_view', 1),
(23, '2023_11_22_183823_customer_view', 1),
(24, '2023_11_22_184148_cashier_view', 1),
(25, '2023_11_22_193310_total__harga__function', 1),
(26, '2023_11_23_182909_cart_view', 1),
(27, '2023_11_24_165540_delete__cart__trigger', 1),
(28, '2023_11_24_170020_cannot__delete__log__trigger', 1),
(29, '2023_11_24_173259_stock__back__procedure', 1),
(30, '2023_11_25_160327_log_procedure', 1),
(31, '2023_11_25_161614_selling_update_trigger', 1),
(32, '2023_11_25_174127_expired_event', 1),
(33, '2023_11_26_172842_expired_product_view', 1),
(34, '2023_11_26_190225_total_pengeluaran_function', 1),
(35, '2023_11_26_190357_total_pemasukan_function', 1),
(36, '2023_11_26_190503_total_keuntungan_function', 1),
(37, '2023_11_26_195751_order_success_procedure', 1),
(38, '2023_11_26_195852_order_fail_procedure', 1),
(39, '2023_11_26_195943_order_refund_procedure', 1),
(40, '2023_11_26_201938_cannot_update_selling_invoice_trigger', 1),
(41, '2023_11_26_202737_cannot_update_log_trigger', 1),
(42, '2023_11_26_202852_cannot_delete_selling_invoice_trigger', 1),
(43, '2023_11_26_203102_cannot_delete_buying_invoice_trigger', 1),
(44, '2023_11_27_134636_last_selling_transaction_view', 1),
(45, '2023_11_28_082120_add_product_procedure', 1),
(46, '2023_12_18_055255_add_batch_procedure', 1);

-- --------------------------------------------------------

--
-- Struktur dari tabel `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `products`
--

CREATE TABLE `products` (
  `product_id` char(36) NOT NULL,
  `description_id` char(36) NOT NULL,
  `product_name` varchar(255) NOT NULL,
  `product_sell_price` int(11) NOT NULL,
  `product_status` enum('aktif','tidak aktif','exp') NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `products`
--

INSERT INTO `products` (`product_id`, `description_id`, `product_name`, `product_sell_price`, `product_status`, `created_at`, `updated_at`) VALUES
('053be1ef-09eb-33ac-94db-4e15bdf873c8', 'b1499566-71e0-301b-869f-dc5eddc036ba', 'Animi qui odit quis nulla.', 44981, 'tidak aktif', '2025-02-18 08:48:37', '2025-02-18 08:48:37'),
('0ebe1ae5-5ce6-3dd8-95f3-cd5693ec8d5f', '6e124d78-b650-30e4-b572-54eecd9cb4e0', 'Quia quasi minima autem quis ratione nemo.', 90404, 'aktif', '2025-02-18 08:48:37', '2025-02-18 08:48:37'),
('0fec533b-7f50-3ef5-8c89-5b1646859b98', '8d67f8cd-0a38-3c3a-8f75-0ea8c5bf4593', 'Dolores esse non sequi vel et.', 73170, 'aktif', '2025-02-18 08:48:38', '2025-02-18 08:48:38'),
('13f1f2f3-4a8d-33d4-8185-aaf27e5bae73', 'ec6bd722-1c4e-3764-a4fc-1ac0ca96303c', 'Sed non molestiae sunt tempora eaque.', 44639, 'tidak aktif', '2025-02-18 08:48:40', '2025-02-18 08:48:40'),
('15d21639-b534-39b9-b87e-775ae6aa2752', 'acaa76a4-f5fb-362a-a8a9-44dd6185134b', 'Sit blanditiis omnis molestiae quae.', 38620, 'aktif', '2025-02-18 08:48:33', '2025-02-18 08:48:33'),
('1bdfb774-0c11-3bd1-8682-861c66ed256a', '31fe2e89-8057-35c8-b035-c5086c3aa642', 'Saepe facere ut excepturi iure.', 1136, 'aktif', '2025-02-18 08:48:40', '2025-02-18 08:48:40'),
('1c64ee27-d4dd-31c6-8f31-ceaa05dd9154', '74461f26-578b-3e32-8566-e1f85b1a5b98', 'Voluptatem necessitatibus a quia rerum.', 13496, 'tidak aktif', '2025-02-18 08:48:35', '2025-02-18 08:48:35'),
('25b03272-1515-3373-9eec-2631f6cd237d', '4a13930d-e1c2-327a-ba95-e0215035fd62', 'Quis rerum blanditiis a earum.', 35833, 'tidak aktif', '2025-02-18 08:48:40', '2025-02-18 08:48:40'),
('328394d6-cb2a-39e3-85ed-2666f6b71407', 'fdf1bcab-c337-3d94-a05b-ece5599059e0', 'Occaecati est sit quo eius magni.', 52776, 'tidak aktif', '2025-02-18 08:48:37', '2025-02-18 08:48:37'),
('40617e87-c213-3290-93d9-30fafb3eaf3c', '25e614c6-b0c6-38ec-a19f-abc05a3c9416', 'Quisquam facere provident alias excepturi.', 85825, 'tidak aktif', '2025-02-18 08:48:41', '2025-02-18 08:48:41'),
('42ef317a-a6ff-3fcb-ac93-bf9cfdc5e4da', '2eb95a4f-4698-33cd-bf8b-5fdc7b600cb3', 'Nihil ullam esse nemo natus quas ducimus.', 12741, 'tidak aktif', '2025-02-18 08:48:40', '2025-02-18 08:48:40'),
('48ebac60-b705-3212-aff9-fafba57b92ce', '9d43933f-aa3f-379e-a6e7-becf06be6640', 'Fugit voluptatem cum et et facere est.', 7808, 'tidak aktif', '2025-02-18 08:48:34', '2025-02-18 08:48:34'),
('4f4f3c0a-9f0e-3b19-9978-133910980efe', '35e697d4-949c-39b9-bdc8-f3a9517c076d', 'Sit nihil explicabo veritatis fugit omnis.', 28630, 'tidak aktif', '2025-02-18 08:48:36', '2025-02-18 08:48:36'),
('65482e67-259f-3e21-aa26-01dbfac1b912', '79d2ce3e-c2d5-3c92-9ef9-6d5d73ac041e', 'Deleniti cupiditate dolor maxime dicta qui.', 7849, 'aktif', '2025-02-18 08:48:36', '2025-02-18 08:48:36'),
('6687dbd5-2598-3a18-bf47-9adbc8638e10', '07d05bc0-b87a-328c-b3ba-28893902b91d', 'Odio ut nihil molestiae fuga.', 37419, 'aktif', '2025-02-18 08:48:38', '2025-02-18 08:48:38'),
('685df6ec-fefb-31ba-9f92-1aa78c528105', 'bb35c30c-d745-33a0-b2f7-acdbf42f7b33', 'Aut corporis enim temporibus id voluptas.', 28709, 'tidak aktif', '2025-02-18 08:48:38', '2025-02-18 08:48:38'),
('6ccec9da-d198-3e24-a56b-f4cc852547b2', 'd8cc0dec-3b01-3fad-b303-66a132c03fc0', 'Animi voluptatem et doloremque dolorum culpa.', 3867, 'aktif', '2025-02-18 08:48:41', '2025-02-18 08:48:41'),
('6e5a9395-92ed-337a-9cfc-e2c322669bdc', '31772749-07a2-38a0-a7ba-3a25e38dcf82', 'Quasi exercitationem sed accusamus quod.', 17607, 'aktif', '2025-02-18 08:48:38', '2025-02-18 08:48:38'),
('7ab7b981-d342-353e-9560-f4cb566b762f', '56d46667-e812-35d2-aa53-096c9e7423e8', 'Dolor illum nobis et molestias sit non sint.', 20899, 'tidak aktif', '2025-02-18 08:48:40', '2025-02-18 08:48:40'),
('7bee6455-edd0-3b1b-b808-c623b7a0638f', '9541f898-4c5f-3b2b-b30b-1654eaafc148', 'Culpa error et ratione cumque assumenda.', 56902, 'aktif', '2025-02-18 08:48:41', '2025-02-18 08:48:41'),
('848312c2-8075-36af-8a51-738d06b066c7', 'f5fc092d-5fed-3050-bf7c-cd44ddf2e70a', 'Voluptatibus optio magnam ut veniam culpa eos.', 41671, 'aktif', '2025-02-18 08:48:34', '2025-02-18 08:48:34'),
('85bfee4b-db10-3c1e-bcc8-8f2d330236c9', 'd4430f9a-ecef-30b5-ba12-64c89f4c3297', 'Aliquid qui atque iste sed quod excepturi porro.', 92440, 'tidak aktif', '2025-02-18 08:48:37', '2025-02-18 08:48:37'),
('89591f8c-f9d2-3a57-bdb4-87ed25292fb3', '9f242e75-1c81-3e47-a5e0-35bbd85d2f9c', 'Asperiores molestiae ab soluta unde unde.', 99428, 'tidak aktif', '2025-02-18 08:48:33', '2025-02-18 08:48:33'),
('8b28808b-6316-3128-a601-945b4976d130', '0b427933-5da4-3739-b6a1-da95ad45e641', 'Laboriosam sed et qui nostrum.', 23137, 'tidak aktif', '2025-02-18 08:48:34', '2025-02-18 08:48:34'),
('8bdf3b69-7417-383d-b255-27294c4a9240', '3f626890-de85-3a4a-b48b-c0de174fed58', 'Ipsum qui et ut veniam libero.', 41988, 'tidak aktif', '2025-02-18 08:48:35', '2025-02-18 08:48:35'),
('9319db65-9b38-3285-a53d-90ee22e534b3', '1d6eff42-1653-3892-a2e7-398d5150383d', 'Quae aut ea quasi ut molestias.', 67168, 'aktif', '2025-02-18 08:48:37', '2025-02-18 08:48:37'),
('ab95b8c4-2279-3242-8e01-042d87d6f723', '07ccacce-572c-34a8-aef0-e146a1a54b0b', 'Sint error tempora architecto dolor id non a.', 15212, 'aktif', '2025-02-18 08:48:37', '2025-02-18 08:48:37'),
('b0de50b5-0caf-333c-9ca5-761429925f17', 'a7198ac4-8315-394c-a594-57ba021a7622', 'Et et molestias ut nihil rerum amet facere.', 8984, 'tidak aktif', '2025-02-18 08:48:35', '2025-02-18 08:48:35'),
('b424959e-e85d-3e6e-95ac-2fa39955955a', '05b20837-eebd-3221-94ba-a8c66c34e299', 'Est voluptas voluptatem distinctio inventore.', 25386, 'aktif', '2025-02-18 08:48:36', '2025-02-18 08:48:36'),
('bf97831a-9836-3809-ac51-01094e4cbbd5', '47a6a86b-ac77-3a90-8ab4-8e6c33240869', 'Modi aut natus nobis vitae exercitationem rem.', 2575, 'tidak aktif', '2025-02-18 08:48:33', '2025-02-18 08:48:33'),
('c5c9e404-5014-347e-b890-ee621618932e', '78a59bb5-b9b8-3c05-8f5e-e8a391968663', 'Quidem error quis blanditiis.', 9050, 'tidak aktif', '2025-02-18 08:48:38', '2025-02-18 08:48:38'),
('d20ff44c-a491-3b35-94dc-a2066a4f720b', '18789052-f1fb-3ed1-b5ad-987d733d1622', 'Nihil laudantium officia commodi et.', 20052, 'tidak aktif', '2025-02-18 08:48:34', '2025-02-18 08:48:34'),
('d439cfc0-6751-372d-90cf-5e67476f370c', '5a393506-79a4-3640-9532-085bf77c42c5', 'Ut soluta dolore at facilis qui et nulla.', 85339, 'tidak aktif', '2025-02-18 08:48:36', '2025-02-18 08:48:36'),
('d6565d09-8f31-3988-954b-cd0e2877f4ff', 'a6dbc70d-f26e-352a-a511-2c12ef5bc3f6', 'Est quo sit provident earum qui.', 92977, 'tidak aktif', '2025-02-18 08:48:41', '2025-02-18 08:48:41'),
('e1d9d80d-41a9-38a1-9bfe-49dce9968586', 'e8bfca70-fed0-3397-858a-aa64cb657c4e', 'Beatae excepturi et quia eum sit voluptatum et.', 79802, 'aktif', '2025-02-18 08:48:36', '2025-02-18 08:48:36'),
('e9e59ffe-cca2-31ba-8434-397b44513248', '9523c1c6-1f2f-3f3c-a59e-27a852e21c30', 'Minus quidem suscipit expedita totam ut dolores.', 32376, 'tidak aktif', '2025-02-18 08:48:34', '2025-02-18 08:48:34'),
('f0b5c97e-252a-3bbf-b59a-f676219fe466', '593f1cca-86b7-3d0d-829f-97b34e356e68', 'Eos eveniet totam sequi nemo.', 83376, 'aktif', '2025-02-18 08:48:37', '2025-02-18 08:48:37'),
('f2c9334a-1520-3657-9be0-3b9aaaca05af', 'f4d9fa59-04ba-3d55-9324-8e75862c1552', 'Atque eos animi optio est quae officiis ad earum.', 96869, 'aktif', '2025-02-18 08:48:35', '2025-02-18 08:48:35'),
('fa572c02-0605-3ac2-8073-82f7b284ae32', '54499ca2-8ff9-31be-b2d8-efc7834cd2db', 'Enim hic et unde ab nulla.', 91067, 'tidak aktif', '2025-02-18 08:48:39', '2025-02-18 08:48:39'),
('fa6d8860-317d-3663-a198-d42fe9a361b4', 'bb3a5733-d34d-33ca-8509-ca8d43162eec', 'Sit est cumque repellendus repudiandae.', 29070, 'tidak aktif', '2025-02-18 08:48:35', '2025-02-18 08:48:35');

--
-- Trigger `products`
--
DELIMITER $$
CREATE TRIGGER `delete_cart` AFTER UPDATE ON `products` FOR EACH ROW BEGIN 
            IF NEW.product_status = 'tidak aktif' OR NEW.product_status = 'exp' THEN 
                DELETE FROM carts WHERE product_id = NEW.product_id;
            END IF;
        END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `product_descriptions`
--

CREATE TABLE `product_descriptions` (
  `description_id` char(36) NOT NULL,
  `category_id` char(36) NOT NULL,
  `group_id` char(36) NOT NULL,
  `unit_id` char(36) NOT NULL,
  `supplier_id` char(36) NOT NULL,
  `product_type` enum('umum','resep dokter') NOT NULL,
  `product_photo` varchar(255) DEFAULT NULL,
  `product_manufacture` varchar(255) NOT NULL,
  `product_DPN` varchar(15) NOT NULL,
  `product_sideEffect` longtext NOT NULL,
  `product_description` longtext NOT NULL,
  `product_dosage` longtext NOT NULL,
  `product_indication` longtext DEFAULT NULL,
  `product_notice` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `product_descriptions`
--

INSERT INTO `product_descriptions` (`description_id`, `category_id`, `group_id`, `unit_id`, `supplier_id`, `product_type`, `product_photo`, `product_manufacture`, `product_DPN`, `product_sideEffect`, `product_description`, `product_dosage`, `product_indication`, `product_notice`) VALUES
('05b20837-eebd-3221-94ba-a8c66c34e299', '55ddcfa7-7192-3752-b7c2-7ebb4bd26c71', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', 'debe1171-514e-3007-9da5-cd8f308cb294', '430f8245-0948-3d3f-a058-0090e7a5076f', 'umum', NULL, 'id et et distinctio delectus', 'DKL492024277A21', 'Quam asperiores voluptatibus maxime nostrum. Aut doloribus recusandae nostrum et possimus sapiente aut. Rerum suscipit possimus eos libero dolorem et. Labore natus sunt doloremque labore a eos. Non rerum facere voluptates alias. Maxime nihil atque ex omnis corrupti voluptatibus.', 'Vel distinctio incidunt blanditiis ut. Rerum blanditiis ut vel doloremque labore. Voluptas vero ut qui. Molestiae velit veniam numquam beatae et magnam laborum. Ea quidem quasi eum animi et occaecati. Perferendis ducimus vel ullam laboriosam ad aut praesentium.', 'Consequatur aut dicta voluptatem iusto. Nihil est molestias eligendi aperiam ad ex minima vero. Et exercitationem officiis eos illo consequatur nihil. Ad alias est deserunt recusandae ipsum cum exercitationem. Illo qui labore repellat nulla totam. Eum quos sed ab magni aut amet.', 'Sapiente quisquam et animi in ullam est. Id inventore saepe aut nihil est est quidem. Nemo quisquam repudiandae consectetur. Occaecati placeat laudantium praesentium accusamus possimus aut. Ipsa rerum eligendi atque et iusto velit dolorem. Quisquam harum sed commodi blanditiis eius harum provident.', ''),
('07ccacce-572c-34a8-aef0-e146a1a54b0b', '4d65dee3-2837-39a2-9e3a-db3afb96e5b0', '3da63f41-fcb5-3aa8-953c-589f77077e40', '8a633afa-c9f4-34c8-aca6-d8f42916c443', '38a67053-741e-38fd-a7ea-235857760165', 'resep dokter', NULL, 'dolorem corporis voluptas voluptatem tempore', 'DKL141508241A21', 'Qui alias aut nisi quos eum quia quo voluptatem. Et quibusdam esse aut esse. Explicabo inventore ut quod praesentium doloremque eum. Expedita ut excepturi veritatis illum nobis tenetur. Ratione exercitationem fugit modi tempora ratione consequuntur quidem. Esse doloremque quaerat rerum.', 'Eius quibusdam consequatur at maxime voluptate. Totam aut quidem sit error inventore. Quis est earum iusto unde beatae ducimus. Neque non natus animi eaque sequi. Nesciunt aut iusto necessitatibus voluptatibus porro alias est. Ullam in non blanditiis illo incidunt.', 'Vero hic unde aperiam enim ut enim totam. Consectetur molestiae sit optio commodi aut. Dolorem ut deserunt molestias fuga tenetur non id. Sit voluptas consequatur ut. Fugiat repellat et voluptatem est iusto explicabo quam. Est ratione nemo sint minima voluptatem omnis.', 'Modi magnam vitae voluptatibus asperiores omnis. Incidunt distinctio eveniet aut animi excepturi. Expedita suscipit reprehenderit voluptas enim culpa reprehenderit. Eum exercitationem illo eaque et sint perspiciatis qui. Totam ipsam odit similique molestias. Et doloremque eveniet inventore.', ''),
('07d05bc0-b87a-328c-b3ba-28893902b91d', 'dc1a7b6b-ede8-3c2e-bed4-c058f6c7acc7', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', '49692d4b-f5ab-37af-9e93-54c932e0917c', '38a67053-741e-38fd-a7ea-235857760165', 'resep dokter', NULL, 'eos sed quia ullam unde', 'DKL943065822A21', 'Est omnis porro eligendi porro. Et dolores similique neque. Reiciendis rerum iure beatae molestiae odit. Quod qui tempora eum culpa tempore provident soluta voluptatem. Aut eaque blanditiis est et. Sit et odit deleniti provident.', 'Consequatur at eum et quis odit. Accusantium architecto impedit sint eveniet at odio natus. Dolor molestias doloremque consequatur dolores. Quidem corporis beatae voluptatem. Eum natus enim illo aut. Sed fuga a ipsum culpa quisquam non et.', 'Neque reprehenderit totam quae eum beatae. Doloribus aut magnam sed commodi. Excepturi aspernatur cupiditate cumque in laborum. Quo illum aut quae maxime sunt et. Numquam veniam perspiciatis libero quam dicta consequuntur. Sequi ea aut voluptatum quis vero nesciunt rerum.', 'Ut deserunt et quam dicta. Excepturi omnis occaecati dolorem iste corrupti laborum autem. Illum laborum et maxime. Hic recusandae eum quam ipsa repellendus ducimus vitae quae. Expedita sunt culpa aut itaque et eaque. Magnam sed vero temporibus et aut beatae nam dolor.', 'Eum similique eum sit non consequatur in. Expedita libero quo praesentium id. Corrupti sunt nisi quia sit facilis tenetur omnis. Temporibus inventore corrupti porro voluptatibus totam. Eligendi odit temporibus culpa nostrum nemo est deleniti. Et fugiat nisi dolor reiciendis non.'),
('0b427933-5da4-3739-b6a1-da95ad45e641', '55ddcfa7-7192-3752-b7c2-7ebb4bd26c71', '79c8cac2-5264-3c8a-b02f-6657c71dfc2f', 'debe1171-514e-3007-9da5-cd8f308cb294', '430f8245-0948-3d3f-a058-0090e7a5076f', 'resep dokter', NULL, 'officiis dolor qui quis quibusdam', 'DKL639423498A21', 'Aperiam corrupti eos dolores voluptas quia quia nobis. Similique nam voluptatem rerum aut repudiandae. Error ea magnam voluptatum. Aliquam ipsam consequatur nam id. Aut aliquid quas unde tenetur. Qui dolores exercitationem error eligendi natus perspiciatis in optio.', 'Voluptatem aut molestias quam nulla qui reprehenderit. Voluptatem qui quod voluptatem. Omnis at fugiat vel at eum. Eos veritatis earum odio inventore doloribus pariatur ut possimus. Eligendi qui tenetur ratione quidem. Adipisci molestias quis voluptatem tempora.', 'Voluptas est repudiandae id ex. Dolor quis animi dolore aut reiciendis voluptatum. Et aut beatae voluptas dolorem voluptas. Delectus est porro voluptatem ipsum consequatur reiciendis molestiae eos. Et autem dolor nobis quo consequatur tempore reprehenderit. Soluta id quaerat eius consectetur est omnis velit.', 'Recusandae eos nostrum neque qui sint veritatis in aspernatur. Nostrum est minus enim deserunt sapiente excepturi dolor assumenda. Consequatur recusandae mollitia veniam quo ut occaecati ut. Est dicta consequatur quis ipsa ex pariatur. Accusantium molestiae sequi tenetur deleniti quidem nemo velit. Nulla minus distinctio voluptatem ut fuga in.', 'Ut autem deleniti qui modi cupiditate dolores ab. Eaque aspernatur molestiae necessitatibus qui eos sint quidem. Veritatis quam repellat perspiciatis nemo ut aut et. Ipsam expedita eos libero est in omnis. Totam esse reiciendis quae eos. Excepturi est possimus dolorem modi totam qui minima velit.'),
('18789052-f1fb-3ed1-b5ad-987d733d1622', 'fa84f808-91c6-3715-b90d-897b1c2d5d4c', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', 'debe1171-514e-3007-9da5-cd8f308cb294', '25b30e61-8287-3c07-bc6a-b13a5dfb1707', 'resep dokter', NULL, 'nulla nemo debitis illo eaque', 'DKL661931680A21', 'Exercitationem voluptates perspiciatis expedita perspiciatis dicta minima sit. Aut quia laborum rem corrupti provident error mollitia sunt. Aut quibusdam quam explicabo earum sint sed nihil iste. Dolorum rerum veritatis expedita id et aspernatur. In quia dolor ut quibusdam. Voluptas asperiores itaque facilis dolore.', 'Reprehenderit dicta ex aut aperiam maxime distinctio voluptas animi. Doloremque tenetur quasi excepturi reprehenderit illo eum corporis. Labore est est qui modi sapiente. Molestias iste vel aut adipisci. Aut est dignissimos quis est. Nesciunt quia officia suscipit voluptas est sed.', 'Blanditiis autem magni non ut molestiae perferendis. Eum et debitis voluptas nemo qui. Nemo labore pariatur cum. Consequuntur suscipit aut optio dolor aut qui. Totam corporis consequatur doloremque aut sit. Dolore praesentium et ut eligendi et doloremque neque qui.', 'Vel fugiat ea sit. Odio veniam nam harum. Aut provident reprehenderit incidunt inventore ut nobis voluptatem. Enim sint et et excepturi ea. Placeat nesciunt magnam et quia est quod assumenda. Sint et sed ea et omnis.', ''),
('1d6eff42-1653-3892-a2e7-398d5150383d', 'fa84f808-91c6-3715-b90d-897b1c2d5d4c', '3da63f41-fcb5-3aa8-953c-589f77077e40', 'debe1171-514e-3007-9da5-cd8f308cb294', 'feb86d29-dcff-380b-b55c-c4ffbc9b946d', 'resep dokter', NULL, 'perspiciatis consectetur tempore qui dolorem', 'DKL519770028A21', 'Corrupti totam sapiente consequatur recusandae labore. Placeat ad sit reprehenderit hic sunt autem sint. Laudantium dignissimos quia eos aut aut quidem dolorem. Ut harum est molestiae quas ipsam facere ea. Quo quis repudiandae consequatur ut. Illum harum id nemo sit asperiores.', 'Quae quo nihil corrupti ipsum reprehenderit harum adipisci. Dolorem necessitatibus sunt sapiente sapiente. Veritatis labore aliquam quo in culpa esse maxime. Enim voluptatem et quo quidem repudiandae sapiente. Autem dolore aut blanditiis esse placeat. Quaerat nisi ut magnam fugiat ab eos dignissimos.', 'Sint sunt provident nihil eveniet ipsa facere. Qui aperiam similique modi nemo non adipisci vitae. Incidunt dolorum at dolor excepturi quia qui. Aut odio autem laborum et dicta nulla. Voluptatibus tenetur ut et officia consectetur eius iure. Consequatur eum atque nihil ratione.', '', 'Assumenda sed sint rerum similique dolorem illo. Voluptatem quos consequatur nihil laboriosam commodi et dolorem. In quidem et et consequuntur aspernatur tempore. Non ipsam maiores odit sit dolores deserunt perferendis. Est minus nam eius recusandae quidem ut. Laboriosam animi minima vero id eos.'),
('25e614c6-b0c6-38ec-a19f-abc05a3c9416', '93845cdc-ed09-3bf6-bd78-1152c94718eb', '3da63f41-fcb5-3aa8-953c-589f77077e40', '75956a1a-c277-39bd-999f-d8bfe783759a', 'cfde7cd4-3d33-3b72-b7b2-badfddde4b6e', 'resep dokter', NULL, 'sint esse fuga tenetur ratione', 'DKL412227931A21', 'Ex voluptates saepe at quod adipisci aut sint. Laborum qui temporibus iure expedita ex. Vero est non animi sint minima ipsam. Itaque molestiae officia et debitis qui impedit nostrum. Sed repudiandae ratione sed aut. Excepturi quasi autem sunt.', 'Numquam laboriosam quae ipsa corporis doloribus. Doloremque neque qui dicta. Quasi quo necessitatibus laudantium deleniti consequatur sit. Doloremque a et assumenda eligendi et aperiam. At aspernatur magnam asperiores et. Repudiandae sunt possimus delectus ut.', 'Sed iusto quidem modi iste earum ut non. Pariatur omnis nemo voluptatibus incidunt. Officia officiis sunt voluptas modi vel. Cumque consequatur repudiandae qui voluptatibus qui ut quibusdam eum. Quasi repellat sequi sint eos. Repudiandae autem atque veniam commodi et velit sed.', 'Nostrum ratione corrupti quos ea aut animi. Voluptas sequi suscipit ullam sed. Excepturi ipsam praesentium mollitia dolorem quis qui veritatis. Corporis eveniet sit molestiae. Nulla sed iusto architecto nihil reiciendis sit. Explicabo iusto quaerat nihil error.', ''),
('2eb95a4f-4698-33cd-bf8b-5fdc7b600cb3', 'ca610106-eea9-3226-ad42-fc42086314dd', '3da63f41-fcb5-3aa8-953c-589f77077e40', '75956a1a-c277-39bd-999f-d8bfe783759a', '5349f59e-d1c8-30a6-a080-a70da8d67cbe', 'resep dokter', NULL, 'aspernatur nihil quia facere sed', 'DKL932609408A21', 'Quod vel minima quia earum aspernatur est ut. Quos reiciendis accusantium iusto ex. Nihil quia praesentium maiores laborum quia voluptatem odit. Similique laborum eius rem omnis asperiores. Officiis assumenda dolores tempore fuga. Ratione sint quibusdam alias vitae minus.', 'Nesciunt recusandae non eum eum excepturi veritatis id. Veritatis quibusdam laudantium autem. Quia libero sunt rerum delectus voluptas. Dolorem quia quis pariatur aut harum. Exercitationem animi et ducimus enim aut. Ea est pariatur repellendus nihil excepturi dolorem non.', 'Tenetur quia dolore atque tempore ut voluptatem est. Omnis dolorem rerum voluptatem optio. Tempore tempora fuga voluptatem cupiditate libero. Est veniam libero odit maiores. Ut voluptas eum aut. Neque cumque nihil aperiam sed eaque.', 'Velit adipisci sunt est ea quia sed ratione magni. Et error ut mollitia. Incidunt cupiditate sit hic repudiandae nemo voluptatum. Quaerat assumenda quod earum deleniti accusamus. Possimus quo et soluta non sit dolorum quam. Quos quam voluptatem ut ullam accusamus.', ''),
('31772749-07a2-38a0-a7ba-3a25e38dcf82', 'd8f0aa52-eb4e-3a1d-addc-776c13fdf6bd', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', '49692d4b-f5ab-37af-9e93-54c932e0917c', '5349f59e-d1c8-30a6-a080-a70da8d67cbe', 'resep dokter', NULL, 'et odio dolores laboriosam optio', 'DKL376034292A21', 'Ea omnis omnis tempore dolor repellendus veritatis quidem. Consequuntur perferendis sit aliquid et. Facilis magni reiciendis eveniet est aut molestiae. Magnam sit expedita omnis blanditiis quia amet rerum. Laboriosam voluptas ab possimus omnis. Sunt ex esse et aliquam a nostrum.', 'Quidem sapiente deserunt ea consequatur. Pariatur et quas voluptatem in consequatur laboriosam. Ex dolorum et alias corrupti minus aut recusandae magnam. Dolorum sed est cupiditate iure natus in molestiae eveniet. Tenetur assumenda ex debitis soluta non corporis architecto perferendis. Aut quo voluptatem laboriosam et.', 'In non sint placeat. Cumque velit exercitationem labore ut itaque. Labore ipsum ipsa quibusdam possimus voluptas soluta officiis aliquid. Optio blanditiis id sunt quis sed. Voluptatem ut ut corporis molestias. Qui quia distinctio cupiditate voluptatem aut aut id.', '', 'Sint ullam eos quam voluptas velit amet architecto inventore. Consequuntur ut est corporis dolorem neque in velit eos. Quia impedit omnis occaecati et ipsa. Odit ratione eligendi sequi eligendi velit vel nihil. Pariatur harum qui rem. Molestiae corporis omnis autem voluptatem quasi sit et.'),
('31fe2e89-8057-35c8-b035-c5086c3aa642', '93845cdc-ed09-3bf6-bd78-1152c94718eb', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', '762e69a6-cf92-3dc1-9543-fd178e7aa96b', '430f8245-0948-3d3f-a058-0090e7a5076f', 'umum', NULL, 'voluptas dolore molestiae officia qui', 'DKL808538893A21', 'Tempore dolor sit molestiae reiciendis quis esse sed. Quo iusto ullam voluptate quis deserunt dicta incidunt modi. Hic et reprehenderit itaque adipisci. Voluptates repellendus autem enim vitae incidunt ab temporibus. Aperiam quibusdam quia itaque provident. Iste ratione voluptatibus error sit.', 'Est et fugiat ducimus odio optio. Nemo dicta est voluptas rerum qui. Et sequi dicta sed eligendi facere perspiciatis reiciendis. Quia modi aut dolorem. Ut laudantium harum et. Cumque est quis quae.', 'Ea placeat nesciunt sed voluptatem soluta inventore. Quidem voluptatem nostrum voluptatem. Dolores animi ut sit id dolorem sed vitae. Quod animi rerum ex adipisci in aliquid itaque. Similique atque maiores laboriosam aut. Debitis qui quod minus quisquam doloremque.', 'Non debitis quisquam animi ad. Nesciunt est voluptatem ratione laboriosam. In suscipit suscipit rem fugit aperiam autem. Qui quo aut explicabo. Ut laudantium suscipit quia vitae quidem omnis. Quia sit adipisci quis ullam eum et deleniti.', ''),
('35e697d4-949c-39b9-bdc8-f3a9517c076d', '91e3d4d9-cd51-349b-9e07-1ed45b1d4b8f', '3da63f41-fcb5-3aa8-953c-589f77077e40', '49692d4b-f5ab-37af-9e93-54c932e0917c', 'cfde7cd4-3d33-3b72-b7b2-badfddde4b6e', 'resep dokter', NULL, 'quo doloremque magni qui optio', 'DKL540490952A21', 'Delectus est assumenda corporis nulla autem eum ad. Ut cum officiis tenetur minima. Ut ea ad velit qui dolore nisi. Asperiores tenetur minus recusandae illo blanditiis. Est qui enim voluptates dicta sunt fugit. Vitae ducimus et numquam voluptatem repudiandae.', 'Maiores facere molestiae ipsum deserunt velit. Sint dolores labore natus. Nihil atque et eaque rerum animi tempore eligendi cupiditate. Facilis et quia ipsum minus voluptatem. Delectus laborum dicta laborum est. Esse reiciendis similique explicabo laborum aliquid ad.', 'Eveniet quia quis ratione voluptatem dolores modi veritatis. Nostrum delectus et quasi sapiente animi vel ea. Maxime laudantium quo eos eos eos. Beatae vel expedita quia animi consequatur. Qui nostrum et rerum maxime quisquam et. Officia ut autem et ducimus expedita.', 'Aspernatur quia quam est sed dolorum. Dignissimos dolorem optio recusandae voluptatem esse. Nesciunt aspernatur veniam voluptatem error. Aut reprehenderit porro temporibus quisquam. Ipsa qui qui ipsam laudantium et aperiam dolorem. Ab ipsa vitae sed eius.', ''),
('3f626890-de85-3a4a-b48b-c0de174fed58', '93845cdc-ed09-3bf6-bd78-1152c94718eb', '79c8cac2-5264-3c8a-b02f-6657c71dfc2f', 'debe1171-514e-3007-9da5-cd8f308cb294', 'cfde7cd4-3d33-3b72-b7b2-badfddde4b6e', 'resep dokter', NULL, 'sequi atque aut nulla molestiae', 'DKL493023904A21', 'Velit voluptates doloribus et labore voluptatem eos. Nobis voluptas dolorem corrupti minus et cumque a. Accusamus hic perspiciatis iure saepe. Eum et quas commodi quia doloremque et qui. Debitis accusantium at optio aut ea illo accusamus. Dolor non quia quos maiores explicabo quidem.', 'Maxime non sed dolore quo. Ad deserunt voluptates sit dolorem dignissimos necessitatibus. Expedita pariatur necessitatibus et similique ea eveniet vero. Molestiae est qui ducimus magnam ea. Sed dolor maxime eveniet qui magnam consequatur libero. Itaque dolore ea libero amet repudiandae.', 'Libero labore quis explicabo sit. Voluptas dignissimos ipsum eveniet est omnis maxime veritatis cumque. Aut molestiae laudantium ut voluptas iure natus. Architecto quo natus commodi iusto. Aspernatur laudantium id iure quia. Quo aspernatur hic sapiente iste.', '', ''),
('47a6a86b-ac77-3a90-8ab4-8e6c33240869', 'd8f0aa52-eb4e-3a1d-addc-776c13fdf6bd', '3da63f41-fcb5-3aa8-953c-589f77077e40', '762e69a6-cf92-3dc1-9543-fd178e7aa96b', 'cfde7cd4-3d33-3b72-b7b2-badfddde4b6e', 'resep dokter', NULL, 'eum rem sunt maxime nihil', 'DKL873630407A21', 'Eligendi consequatur exercitationem assumenda quam ullam omnis. Ullam voluptatibus repellendus fugit ut nulla quaerat. Qui incidunt minus delectus ipsam aut voluptate. Et perferendis neque qui non labore molestiae ipsa accusantium. Officia aut excepturi pariatur in in ea qui quod. Nobis ut impedit distinctio officiis saepe ipsa id aliquam.', 'Aut numquam nihil ut veniam necessitatibus et aut. Consectetur autem tempore rem temporibus eos aut at impedit. Consectetur iure voluptatem sit similique est eos et maiores. Quis ipsa illo et esse sed molestiae. Autem velit aliquid aspernatur eius asperiores adipisci quia voluptates. Vero impedit tempore dolores.', 'Rerum adipisci dicta sit exercitationem. Molestiae qui aliquam quis velit. Voluptas omnis quia consequuntur aut rerum voluptas eaque. Quo placeat labore et eum nostrum. Autem adipisci esse fuga. Maiores consequatur rerum autem voluptatem.', 'Quidem facilis doloremque maiores aspernatur laboriosam quod. Ratione fugit ipsa facilis architecto. Suscipit id voluptas consequatur ad odio consectetur temporibus. Aperiam ipsa qui amet itaque officia saepe ullam non. Quis placeat consequatur omnis asperiores mollitia placeat. Laboriosam incidunt ullam rerum minus in.', 'Qui ut culpa cumque vitae labore voluptatem. Similique temporibus earum numquam consequuntur fugiat quas. Eius autem officia ducimus veritatis explicabo eum cumque. Doloremque quam est soluta deserunt recusandae. Omnis recusandae earum ut inventore itaque cupiditate mollitia. Voluptatem et ea iusto rerum possimus fugiat doloremque.'),
('4a13930d-e1c2-327a-ba95-e0215035fd62', 'd8f0aa52-eb4e-3a1d-addc-776c13fdf6bd', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', 'f2022abe-4fa3-36c7-b3a4-2d08d3346989', '5349f59e-d1c8-30a6-a080-a70da8d67cbe', 'resep dokter', NULL, 'odit voluptatem voluptatem qui magni', 'DKL293710083A21', 'Voluptatem alias voluptas optio dolorum inventore quia. Blanditiis omnis deserunt dolore eaque et ea. Culpa doloribus est ullam reiciendis at. Tempora laudantium consectetur quia inventore. Aut cumque ut soluta sed quae ducimus et. Qui eum sequi eos harum eos deleniti repudiandae error.', 'Voluptates velit sit officia omnis quod quidem omnis. Expedita id fugiat natus sed aperiam. Autem praesentium placeat commodi voluptate qui quia facere animi. Magnam voluptate maiores voluptate alias. Blanditiis rerum ad earum recusandae sed et consequatur eius. Incidunt autem molestias aspernatur voluptatem exercitationem quaerat.', 'Exercitationem quos officia blanditiis molestiae sed. Alias animi autem inventore qui et. Ab maiores nemo est accusantium modi qui. Ullam eligendi accusamus aut vero repellendus rem sunt soluta. Mollitia voluptatem vero sed unde. Consequuntur ea soluta dolores suscipit.', '', ''),
('54499ca2-8ff9-31be-b2d8-efc7834cd2db', 'fa84f808-91c6-3715-b90d-897b1c2d5d4c', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', '75956a1a-c277-39bd-999f-d8bfe783759a', '430f8245-0948-3d3f-a058-0090e7a5076f', 'umum', NULL, 'voluptas nihil iste est dolore', 'DKL594586086A21', 'Voluptates possimus occaecati quas adipisci numquam. Ducimus et ipsam nisi aut quisquam. Harum est consequuntur autem aliquid illum. Temporibus aperiam quia dolorem tenetur. Possimus nisi qui dolorem quam. Commodi laboriosam in numquam autem incidunt veniam.', 'Et qui eos enim non. Suscipit et aut illo. Similique cum beatae et quia in accusantium sit. Aut praesentium reiciendis ducimus at. Nihil quia autem maiores in qui eum omnis. Sequi incidunt omnis labore eligendi doloribus debitis.', 'Sequi est quae assumenda cupiditate repudiandae. Eos mollitia sint neque a eaque. Voluptatem veritatis sunt optio. Fugit sed ea expedita debitis id accusantium mollitia. Blanditiis quod cum ullam non. Aspernatur aut ut placeat quas ut modi qui ut.', 'Vel quia in modi modi quos autem. Ex beatae hic omnis eos numquam saepe. Voluptatum soluta nihil sequi est delectus laborum. Voluptate sunt sed quaerat harum est magnam optio. Est ut eius nobis ratione adipisci. Quod necessitatibus mollitia ex omnis impedit.', 'Aut suscipit et id id sint quae cumque et. Voluptas id amet similique neque nemo consequatur id. Illum molestiae et quisquam architecto cumque quasi. Architecto necessitatibus hic qui qui. Nobis omnis sequi exercitationem neque. Fugiat ea sint veniam.'),
('56d46667-e812-35d2-aa53-096c9e7423e8', 'dc1a7b6b-ede8-3c2e-bed4-c058f6c7acc7', '79c8cac2-5264-3c8a-b02f-6657c71dfc2f', 'debe1171-514e-3007-9da5-cd8f308cb294', 'a6c9b5ef-5e4a-3671-a0f2-74a21e9bf3c5', 'umum', NULL, 'aut reprehenderit voluptas aspernatur deleniti', 'DKL470682643A21', 'Tempora culpa odit sequi ipsum minima. Sed ut possimus exercitationem dignissimos excepturi. Et ut sapiente minima commodi ratione inventore. Enim repudiandae non cum ut. Saepe impedit qui sed. Excepturi minus ipsam quasi quia eius.', 'Rerum aut voluptas repellat ut velit eligendi. Quisquam doloremque quo est est sequi ipsa nobis. Aut dolor cupiditate blanditiis est. A qui perferendis rem nihil dolorem distinctio. Ut quos est et odio. Voluptates a illo beatae.', 'Aperiam at ratione doloremque repellendus ab. Maiores qui vero et molestiae commodi optio. Et blanditiis aut animi. Perferendis vitae ut adipisci saepe reprehenderit ducimus voluptatum. Et optio sit ex minima impedit consequatur. Officia provident omnis necessitatibus autem et voluptatem quia sint.', 'Ut iusto ut magnam qui sint quia. Ea cum quasi minus nostrum dolor. Ex illum harum dolores velit aut. Assumenda modi enim ut eius. Necessitatibus optio et facilis earum. Enim in commodi maiores unde.', 'Quidem doloremque consequatur eligendi qui non repudiandae. Eveniet aliquid voluptas recusandae accusantium. Est in animi explicabo eos rerum minus. Libero ducimus sint iure asperiores. Placeat et ea aliquam error cupiditate nesciunt voluptate enim. Molestiae neque ab temporibus sunt.'),
('593f1cca-86b7-3d0d-829f-97b34e356e68', '93845cdc-ed09-3bf6-bd78-1152c94718eb', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', '49692d4b-f5ab-37af-9e93-54c932e0917c', 'feb86d29-dcff-380b-b55c-c4ffbc9b946d', 'umum', NULL, 'est tempore et ratione ut', 'DKL381206236A21', 'Voluptate hic ut quas nulla. Vitae deleniti quasi repellat occaecati velit quaerat. Consequuntur est omnis vero. Rerum sit nesciunt ipsa dicta omnis. Odio magnam architecto natus delectus fugiat fugit. Esse repellat temporibus explicabo animi beatae odit.', 'Voluptas illo neque dignissimos expedita distinctio. Vel dolor nam vitae cumque eius. Cupiditate necessitatibus incidunt recusandae sint quas non. Nemo dolores est consequatur. Recusandae aut magni quidem magni dolorem velit. Optio voluptas quibusdam enim necessitatibus harum nihil asperiores.', 'Doloremque nam quae non quisquam reiciendis sint. Mollitia dicta quas dolores doloremque consequuntur. Ut ex qui iste repellat unde. Molestiae consequatur suscipit molestiae mollitia autem corrupti quia omnis. Odio officia repellat ab tempore rerum. Dolor eius est ducimus molestiae excepturi odit animi.', 'Consequuntur consequatur quas commodi sapiente deleniti recusandae. Provident mollitia rerum voluptatum consequuntur. Atque sit consequatur autem soluta ut ratione. Libero nostrum repellendus aut et dolores. Qui rerum est neque beatae. Quae quia delectus voluptas voluptatum expedita.', 'Blanditiis quasi eveniet nisi ea eos. Alias consequatur rerum ut recusandae voluptate at repudiandae. Et reprehenderit quasi vero omnis sapiente ipsum dolore. Dolor rerum voluptas inventore sint beatae ea minima. Tempora dolorem perspiciatis deserunt quo. Iusto culpa fugiat ullam iusto consectetur.'),
('5a393506-79a4-3640-9532-085bf77c42c5', '91e3d4d9-cd51-349b-9e07-1ed45b1d4b8f', '79c8cac2-5264-3c8a-b02f-6657c71dfc2f', 'debe1171-514e-3007-9da5-cd8f308cb294', '38a67053-741e-38fd-a7ea-235857760165', 'umum', NULL, 'voluptatem explicabo laboriosam molestias odit', 'DKL409181947A21', 'Inventore tempore veritatis vel. Harum debitis earum hic. Quaerat et amet dignissimos exercitationem veniam rerum. Pariatur at voluptatem aut est. Natus rem et quos commodi blanditiis. Fugiat mollitia et enim in.', 'Quia sunt dolores dolorum iste eum praesentium rem. Quia sed distinctio corporis blanditiis minima. Ut ipsum ut qui quos id similique. Asperiores ut et fugiat ratione. Ullam voluptas culpa repellendus nostrum maxime quidem tenetur provident. Fuga doloremque incidunt quasi consequatur magni omnis provident.', 'Architecto nisi sapiente qui at voluptas. Magni quia aliquid odio voluptatum distinctio consequatur rem. Sit exercitationem quia quaerat sint blanditiis culpa maiores corporis. Quia maxime maxime et autem. Aliquid omnis laudantium quae deleniti qui asperiores pariatur. Enim quo autem dolorem impedit ipsum deserunt ut.', '', 'Aut illum dolor numquam nisi dolores sit. Eum quidem vel officiis repudiandae consequatur dolorem deleniti sit. Aut inventore deleniti id voluptatem cupiditate. Consectetur eaque et quas. Est odio iste accusantium quia voluptatem accusamus. Et ut totam aperiam aut facere dolor.'),
('6e124d78-b650-30e4-b572-54eecd9cb4e0', 'ca610106-eea9-3226-ad42-fc42086314dd', '3da63f41-fcb5-3aa8-953c-589f77077e40', '8a633afa-c9f4-34c8-aca6-d8f42916c443', '38a67053-741e-38fd-a7ea-235857760165', 'umum', NULL, 'repellat consectetur quas qui et', 'DKL651624945A21', 'Ad voluptates est blanditiis dolorem laudantium possimus. Accusantium sit est reiciendis ut totam ut libero. Delectus pariatur nam libero qui. Esse voluptas nisi expedita numquam laudantium earum. Corporis est repellat quia enim eaque qui eius. Et vero ut expedita cupiditate autem porro.', 'In sed sed et et error id quibusdam dolores. Quidem dolor omnis voluptatibus veritatis et. Totam soluta a quam qui est culpa culpa. Repellendus quae in natus quisquam ad sequi est. Est deleniti nemo molestiae. Ut non laudantium minima suscipit voluptatem accusantium doloremque.', 'Itaque ratione culpa magnam et beatae qui officiis. Eum deserunt autem recusandae aut consequuntur sunt nihil quia. Est omnis aut quas temporibus dolore placeat. Veritatis qui dignissimos ea. Accusantium libero veniam dolor quia impedit magni blanditiis ea. Est id nobis architecto neque ut molestias.', 'Incidunt et consequatur velit dolor impedit velit ipsum. Magnam qui laborum velit autem. Occaecati ipsam in ut est explicabo. Voluptate mollitia eum officiis possimus. Nisi ab ratione architecto. Nemo harum dolorem voluptas fuga mollitia voluptatem ut.', 'Et aut recusandae nam ut non quia sunt. Architecto saepe omnis eum illo aspernatur dicta saepe. Odio minus esse labore officia a qui. Fuga voluptas praesentium et voluptate. Ut omnis atque cumque voluptatem aut. Amet vel in perspiciatis aut aperiam enim et.'),
('74461f26-578b-3e32-8566-e1f85b1a5b98', 'ca610106-eea9-3226-ad42-fc42086314dd', '79c8cac2-5264-3c8a-b02f-6657c71dfc2f', '49692d4b-f5ab-37af-9e93-54c932e0917c', 'cfde7cd4-3d33-3b72-b7b2-badfddde4b6e', 'umum', NULL, 'accusamus eveniet et quae voluptas', 'DKL189390136A21', 'Occaecati nihil architecto ullam ipsam corrupti dolorem. Minus facilis quae a ex laboriosam. Eaque ea est blanditiis maiores quasi in reprehenderit. Ut ad voluptatem eveniet. Debitis rerum porro quia laudantium voluptas. Consequatur quod voluptates unde corrupti placeat.', 'In esse ea qui. Laboriosam ea aut debitis perspiciatis. Fuga et natus quas et laboriosam commodi. Qui molestiae id sint eius aut optio. Ut omnis aut aspernatur ea quos rerum. Modi eos voluptas magni et placeat.', 'Culpa quod adipisci doloribus dolorem beatae. Dolorem quisquam sunt praesentium vero occaecati. Repellendus eius voluptatibus sint nisi sunt aliquam itaque aliquid. Sunt facere id repudiandae. Quo illum sint reprehenderit et dolorem reprehenderit. Omnis eaque omnis et fuga est.', '', 'Perferendis veniam ut enim quos amet iure. Sed quibusdam molestiae voluptatem dolor. Fuga aperiam aliquam eaque quia autem sed. Quaerat esse impedit itaque eum error adipisci. Dolor harum velit voluptas atque. Doloremque expedita earum sint nemo.'),
('78a59bb5-b9b8-3c05-8f5e-e8a391968663', 'd8f0aa52-eb4e-3a1d-addc-776c13fdf6bd', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', 'debe1171-514e-3007-9da5-cd8f308cb294', 'cfde7cd4-3d33-3b72-b7b2-badfddde4b6e', 'resep dokter', NULL, 'cupiditate provident ea sunt eveniet', 'DKL452979539A21', 'Similique adipisci consequatur excepturi. Corporis dolor ad qui et accusamus et. Ut maiores fugiat corporis dolorem ut magnam. Ut nisi ipsam hic officiis quia omnis qui. Quia perspiciatis deleniti cupiditate fugit perferendis placeat placeat. Praesentium ipsa sapiente adipisci voluptatum reiciendis sint facilis fugit.', 'Neque eum adipisci vero quos est. Recusandae rerum modi facilis. Sed id perferendis aut occaecati qui ad assumenda. Autem vel dolorem saepe quo quia itaque. Aliquid voluptas harum sit molestiae. Voluptatem labore aut quas sequi ut.', 'Molestias ea sit non natus dolorem deserunt qui. Cumque aliquam adipisci sed dolor. Amet doloremque sed quos ullam autem sapiente odio. Omnis cumque in sed quae voluptates dolor temporibus. Consequuntur et aspernatur dolor facere. Ut occaecati vero quaerat quia suscipit aspernatur est possimus.', 'Neque est quaerat aperiam placeat sint sit vel exercitationem. Est modi repudiandae eum temporibus ducimus amet quos. Voluptatibus sapiente ratione et quam voluptatem. Corporis excepturi labore iure consequatur nobis sed quae. Autem exercitationem eveniet autem minima non ipsa. Et et saepe itaque eum omnis voluptas dolore.', ''),
('79d2ce3e-c2d5-3c92-9ef9-6d5d73ac041e', 'ca610106-eea9-3226-ad42-fc42086314dd', '79c8cac2-5264-3c8a-b02f-6657c71dfc2f', '762e69a6-cf92-3dc1-9543-fd178e7aa96b', 'feb86d29-dcff-380b-b55c-c4ffbc9b946d', 'resep dokter', NULL, 'rerum tempora aut officia consequatur', 'DKL896549692A21', 'Et asperiores animi voluptatem qui magnam. Consequatur modi non id enim et nemo accusantium. Ratione accusantium debitis qui autem quisquam deleniti eveniet quia. Voluptatibus est optio cumque voluptatem et eligendi. Sint amet et incidunt est et. A voluptates qui officia molestiae eum.', 'Molestias amet possimus minus labore enim architecto. Sed assumenda cumque aperiam doloremque. Est rerum dolor modi provident inventore consequuntur sed. Quis sed quo totam eveniet corrupti. Iste unde tempora et praesentium ad omnis. Distinctio qui occaecati sint eaque dolores doloremque est architecto.', 'Quis sit cupiditate consequatur accusamus dolorum praesentium sit. Nostrum enim ducimus in et ex quis. Distinctio quis recusandae molestiae tempore. Facere quis ex labore odio sapiente sint itaque deserunt. Illum veniam voluptas architecto hic earum et. Ut ducimus dolor quia dolorem.', '', ''),
('8d67f8cd-0a38-3c3a-8f75-0ea8c5bf4593', '91e3d4d9-cd51-349b-9e07-1ed45b1d4b8f', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', '762e69a6-cf92-3dc1-9543-fd178e7aa96b', '5349f59e-d1c8-30a6-a080-a70da8d67cbe', 'resep dokter', NULL, 'facere ut accusamus aspernatur repellat', 'DKL843666685A21', 'Dolores qui et ut et harum. Consequatur cupiditate soluta et est libero possimus molestias. Deserunt ipsam nisi laboriosam recusandae temporibus vitae tenetur aliquid. Eum impedit qui nostrum qui assumenda. Quas et dolores magnam velit laboriosam nisi fuga. Quisquam consequatur dolores et tenetur consectetur.', 'Illo sequi quis sed assumenda et. Voluptatibus accusantium ipsam sequi sed aut esse. Molestiae dolorem hic dolorem impedit. Error harum culpa officia veritatis dolorem eius. Sapiente ex qui pariatur. Et ratione nesciunt distinctio assumenda.', 'Nulla vel aut minus vero. Corporis autem aut maiores velit dolor qui. Dolores at voluptatibus sit cupiditate nam blanditiis. Dolorem voluptatem nisi atque officiis eaque dolorem aut ratione. Autem fugit reiciendis fugiat similique qui et doloribus. Et cum minus iusto.', 'Possimus quasi id eligendi error blanditiis. Nemo unde placeat et dolorem voluptates. Qui consectetur accusamus non ad nobis quia magni. Aut et consequatur laudantium labore sed nihil est. Deleniti reprehenderit quia suscipit numquam. Fuga iure unde temporibus ex officiis corporis eaque.', 'Deserunt cum fuga qui cum fugit quidem veniam. Aut fugit et molestias. Nihil delectus eius voluptas dolore est. Labore nam et enim qui. Eum omnis architecto alias nihil accusamus quis. Consequatur impedit quis voluptatum tempora numquam pariatur.'),
('9523c1c6-1f2f-3f3c-a59e-27a852e21c30', 'fa84f808-91c6-3715-b90d-897b1c2d5d4c', '3da63f41-fcb5-3aa8-953c-589f77077e40', 'debe1171-514e-3007-9da5-cd8f308cb294', 'a6c9b5ef-5e4a-3671-a0f2-74a21e9bf3c5', 'umum', NULL, 'ipsam omnis reprehenderit enim necessitatibus', 'DKL751806015A21', 'Sit repudiandae similique libero et reprehenderit unde. Velit dolorem dolores hic qui et. Vero excepturi voluptatem laboriosam temporibus qui. Magnam repellat ut in quas voluptas. Facilis ducimus ea ad dolorem. Cupiditate et vel veritatis expedita.', 'Voluptatem facere ut natus in. Fuga deleniti ab dignissimos doloremque mollitia sapiente. Et veniam harum quo officiis sunt rerum ipsa. Culpa nulla quis temporibus dolor. Ipsa ea quia eum est. Qui cupiditate sit et cumque aut doloribus repellat.', 'Corrupti hic doloremque et officiis omnis occaecati qui. Impedit et voluptatem error vitae vel maxime. Earum unde qui facere dolores laudantium. Laudantium architecto facilis impedit sint. Excepturi nulla quaerat itaque et animi asperiores voluptatum. Et ducimus ducimus rerum laborum.', '', ''),
('9541f898-4c5f-3b2b-b30b-1654eaafc148', 'dc1a7b6b-ede8-3c2e-bed4-c058f6c7acc7', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', '36742a49-bdb0-34ae-8e70-0e220078cc61', 'a6c9b5ef-5e4a-3671-a0f2-74a21e9bf3c5', 'resep dokter', NULL, 'est qui tempora qui veniam', 'DKL123992479A21', 'Placeat dolores in maxime ratione quo repellendus. Voluptatem veniam et est laudantium excepturi sequi. Dolor nam dolorum molestiae. Quasi vel quo et adipisci nisi et exercitationem. Totam quis corporis et et libero. Sit necessitatibus delectus laborum animi illum.', 'Non quis aliquid dolore accusamus qui. Error aspernatur consectetur vero sit. Assumenda libero omnis esse dolor qui rerum veniam aspernatur. Ut ea laudantium aut nam. Velit illo soluta quasi aspernatur saepe. Est expedita ex aut odio corporis quas.', 'Voluptates praesentium sit non dolorem. Necessitatibus voluptas facere nobis assumenda ipsa. Voluptates dolor consequuntur dolores quae sapiente natus. Placeat repellat ratione consequatur dolorum ducimus laudantium. Enim blanditiis illo saepe illum iure. Maiores cupiditate animi fuga quos et quis velit quo.', '', ''),
('9d43933f-aa3f-379e-a6e7-becf06be6640', '4d65dee3-2837-39a2-9e3a-db3afb96e5b0', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', '8a633afa-c9f4-34c8-aca6-d8f42916c443', 'a6c9b5ef-5e4a-3671-a0f2-74a21e9bf3c5', 'resep dokter', NULL, 'omnis earum eum ut explicabo', 'DKL490078311A21', 'Expedita mollitia autem vero ut consequuntur. Rerum dicta nisi dicta sequi atque. Eos officia necessitatibus sequi illum qui. Inventore quis quaerat eligendi. Qui odio voluptatem et fugit ullam. Repellat quae voluptas cumque pariatur reiciendis qui nisi atque.', 'Rerum dolorum deserunt optio perspiciatis in aut. Iure minus velit sed rerum aliquam fugiat. Consequatur officiis quia ut dignissimos commodi harum consequuntur consectetur. Corrupti dolore autem praesentium et. Qui dolor magni laboriosam porro. Rem commodi vel debitis officiis natus nam doloremque.', 'Voluptate enim laboriosam et hic omnis dolor error. Id odit maxime aliquid ducimus. Et eaque dolores tempore corrupti debitis officia accusantium laborum. Ratione excepturi quia repellat non repellendus. Qui facere aliquam omnis aut et in. Aperiam similique veritatis aut hic dolores rerum temporibus aut.', '', 'Pariatur aut aliquid rerum. Sunt sint quod cum. Sed est architecto ut nisi voluptas cupiditate. Consequuntur ab voluptatem temporibus est nihil debitis accusantium. Deserunt explicabo qui voluptatem id qui. Odio dolores facilis fugiat hic eum velit eaque.'),
('9f242e75-1c81-3e47-a5e0-35bbd85d2f9c', '91e3d4d9-cd51-349b-9e07-1ed45b1d4b8f', '3da63f41-fcb5-3aa8-953c-589f77077e40', '36742a49-bdb0-34ae-8e70-0e220078cc61', '430f8245-0948-3d3f-a058-0090e7a5076f', 'umum', NULL, 'aut nobis reprehenderit quia cupiditate', 'DKL797498351A21', 'Mollitia ut quasi enim. Est pariatur soluta quia consequatur consequatur quod dolor. Nihil a vel iure autem ullam repudiandae non. Nesciunt sunt enim voluptas et accusamus qui possimus. Fugit neque reiciendis aut et repudiandae et. Consequuntur voluptas qui sed.', 'Dolor ea ut libero provident cumque. Nulla voluptatem consequuntur similique natus voluptatum. Laborum autem nesciunt omnis praesentium dicta velit nostrum sit. Incidunt et voluptatum non quia in quo omnis autem. Tempora delectus ut voluptatibus. Consequatur sed rerum beatae est et odio voluptatem.', 'Magnam saepe ut eos debitis eius enim doloribus. Inventore aut eaque suscipit ut. Aut sed eum nulla labore magnam officiis. Aut in dolores ut in eligendi. Quas aspernatur qui earum dolor et veritatis. Minus est et corrupti autem.', 'Veniam et in rerum. Enim alias tempore aperiam qui veniam nihil. Accusamus itaque veritatis fugiat voluptatum quasi nemo. Aspernatur quisquam ipsum vel et tempore modi quidem. Quibusdam blanditiis quis quis ipsam. Non quidem dolorem expedita reprehenderit dolor minima libero.', 'Deserunt quis autem illum quae aliquam. Dolor est temporibus iure a. Voluptatem quidem labore sit aut minus architecto. Recusandae qui fugiat accusamus dolor at. Vero distinctio sint rerum quas. Eaque delectus et suscipit nesciunt ut.'),
('a6dbc70d-f26e-352a-a511-2c12ef5bc3f6', 'd8f0aa52-eb4e-3a1d-addc-776c13fdf6bd', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', '49692d4b-f5ab-37af-9e93-54c932e0917c', 'cfde7cd4-3d33-3b72-b7b2-badfddde4b6e', 'resep dokter', NULL, 'et quis nostrum neque assumenda', 'DKL901349222A21', 'Quis sint aliquid ut est non minus sunt. Voluptatibus id animi esse. Accusantium cum sunt dolorum facilis eius. Nihil voluptatibus in ea eligendi quidem. Minima sequi est ea harum similique. Et totam qui in voluptatibus et in.', 'Occaecati vero ut voluptatem et fuga eligendi. Quod perferendis est ut ex autem. Adipisci quo accusamus ipsa iure temporibus doloribus et fuga. Amet illum qui iure quo omnis. Sed et voluptatem modi debitis ab. Inventore accusamus non ratione ut velit qui.', 'Temporibus vero dolores iusto atque nam. Eum delectus eos atque ab quis porro consequuntur. Voluptate aspernatur et quis autem excepturi ut. Officiis provident enim rem similique. Consequatur id praesentium nobis officia. Est quibusdam laudantium harum voluptatem nulla.', 'Rerum id magni accusamus et nam. At eligendi iusto enim iste blanditiis. Et corrupti tempora nihil commodi nemo nulla. Est fugiat ut ullam nihil culpa esse. Qui deleniti odio voluptas eum illum. Praesentium repellat et dolores.', 'Dolorem et quas aut. Dignissimos voluptatem dolorem ipsum error. Voluptatibus esse quibusdam dolorem aut laudantium inventore quia fugiat. Laborum excepturi facilis temporibus commodi. Impedit ducimus voluptas ducimus sint. Reprehenderit facere minima ut vel.'),
('a7198ac4-8315-394c-a594-57ba021a7622', '91e3d4d9-cd51-349b-9e07-1ed45b1d4b8f', '3da63f41-fcb5-3aa8-953c-589f77077e40', '36742a49-bdb0-34ae-8e70-0e220078cc61', '5349f59e-d1c8-30a6-a080-a70da8d67cbe', 'resep dokter', NULL, 'voluptatem ab sit sit qui', 'DKL387747534A21', 'Ea optio voluptatem autem et numquam laborum. Qui provident nesciunt voluptatem doloribus necessitatibus architecto. Aut ut eligendi voluptatum unde rerum laborum cum nobis. Asperiores laboriosam commodi voluptatum et provident maiores pariatur quisquam. Sed et ex quod error veritatis. Doloremque nihil nihil architecto consectetur pariatur.', 'Ut sed culpa autem id consequatur et a aut. Aperiam repudiandae et consequatur illo aspernatur. Illum quod ipsa aut ipsum velit. Ut veritatis libero iste sit facere accusantium omnis. Porro sequi possimus exercitationem sed provident vero laudantium. Necessitatibus minus minus at dolore ipsum dicta.', 'Temporibus aliquid id ex dolorem aliquid ducimus. Sunt necessitatibus occaecati rerum aspernatur voluptas repellat totam. Quis officiis eius ratione incidunt nisi ea. Minima nobis fugit neque assumenda quod voluptas. Et neque consequuntur voluptatem atque numquam natus. Pariatur est odio hic nam sint.', '', 'Eius non sapiente possimus non necessitatibus consectetur. Unde ab et voluptatem aut. Et temporibus est suscipit facere vel beatae et. Eius totam molestias quis qui. Similique quis enim dicta minus ut est corporis. Ex vitae a beatae magnam voluptates iure.'),
('acaa76a4-f5fb-362a-a8a9-44dd6185134b', '4d65dee3-2837-39a2-9e3a-db3afb96e5b0', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', 'debe1171-514e-3007-9da5-cd8f308cb294', '5349f59e-d1c8-30a6-a080-a70da8d67cbe', 'resep dokter', NULL, 'autem eum et voluptate cum', 'DKL215902985A21', 'Beatae quasi adipisci nulla soluta ex. Voluptatem unde aut atque enim rem omnis. Aliquid placeat eaque qui. Quia occaecati explicabo temporibus mollitia quis dolorem. Sit et velit exercitationem et et deserunt qui. Mollitia qui voluptate maxime sint accusantium magnam.', 'Ullam alias facere impedit reiciendis. Quas et est harum assumenda non nemo. Quia facere ut voluptas enim. Sequi molestiae asperiores quia. Vitae dolorem et voluptatem enim et dolore. Ad qui quibusdam quia deserunt.', 'Aperiam adipisci a in quidem dolorem. Et nemo ea sit sint. Laborum nisi in saepe. Consequatur magnam magnam accusantium qui quo cumque debitis. Et minus nisi eius officia. Voluptatibus sint omnis asperiores nostrum omnis molestias.', 'Ad atque voluptas sunt natus. Dicta dolorem et corporis quis nam rem est. Magni aut recusandae mollitia et molestiae quis. Quod quia eligendi numquam est. Consequatur laborum ad et voluptatem quia voluptatum voluptatem. Iure aspernatur tempora molestias officiis.', ''),
('b1499566-71e0-301b-869f-dc5eddc036ba', 'fa84f808-91c6-3715-b90d-897b1c2d5d4c', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', '36742a49-bdb0-34ae-8e70-0e220078cc61', 'a6c9b5ef-5e4a-3671-a0f2-74a21e9bf3c5', 'umum', NULL, 'odit magnam officiis temporibus eum', 'DKL472963271A21', 'Amet laborum nihil accusantium. Provident totam accusantium molestiae tenetur minima reprehenderit. Ut quam nihil est blanditiis corrupti. Quia repudiandae veritatis inventore itaque. Reprehenderit est earum aut accusantium. Necessitatibus corrupti et officia qui.', 'Voluptas quos quis officia saepe in eveniet est. Nisi omnis consequuntur omnis. Fugit eveniet voluptatem dolorum. Et autem at tempore et. Ut neque sunt quis itaque ipsam suscipit dolorem. Accusantium iste et aut rerum ea eum dolorum.', 'Reprehenderit veritatis mollitia asperiores libero sit. Rerum velit autem repellat quia earum praesentium non. Ab suscipit eum maxime voluptate nobis. Dolor voluptas et enim similique. Quis cupiditate omnis qui aut a. Dolorem eaque blanditiis totam modi.', 'Architecto voluptatem dolore doloribus mollitia praesentium commodi. Aspernatur et corrupti minus perferendis veniam. Saepe sit ipsa fuga magnam est. Vitae ducimus molestiae vel. Facere exercitationem sit eos ab. Aperiam consequuntur alias nihil quis animi.', ''),
('bb35c30c-d745-33a0-b2f7-acdbf42f7b33', '4d65dee3-2837-39a2-9e3a-db3afb96e5b0', '3da63f41-fcb5-3aa8-953c-589f77077e40', '75956a1a-c277-39bd-999f-d8bfe783759a', '38a67053-741e-38fd-a7ea-235857760165', 'umum', NULL, 'quidem voluptas ex qui sit', 'DKL996882843A21', 'Aut voluptates aspernatur harum dolorem. Nihil mollitia suscipit modi rerum et. Dolor nemo repudiandae quo molestias at officiis excepturi culpa. Dicta dolore ut ipsa vel eius quia assumenda. Voluptatem assumenda sapiente ut. Non quis sequi ea dolorem.', 'Non omnis accusamus accusantium eum. Non aut quia et fuga minus. Labore quisquam dolor porro occaecati adipisci dolor at. Debitis consequuntur nobis et a enim quae. Amet sit natus voluptatem. Quo adipisci rerum reiciendis tempore aliquam veritatis rerum accusamus.', 'Sed aut provident at quaerat quo est et. Voluptatem illum non ab nostrum corporis. Aperiam ea non perferendis et et error rerum eius. Pariatur inventore quisquam quisquam. Non voluptatibus libero ut aliquam. Ipsa tempora et illum quia sequi blanditiis.', 'Eius qui magni sit sed. Doloribus aliquid et at provident. Molestiae sunt ipsam sed officiis. Officia consequuntur deleniti nam. Voluptatem animi aut et omnis eum tempora distinctio. Veritatis vero voluptatem est reiciendis.', 'Non consequuntur pariatur dolorum. Explicabo eaque consectetur aut quo repudiandae sapiente. Unde inventore incidunt porro voluptates quas aut accusamus. Ratione ipsum perspiciatis voluptatem. Ullam ab error aut tempora ut aspernatur molestiae. Est sequi placeat reiciendis.'),
('bb3a5733-d34d-33ca-8509-ca8d43162eec', 'fa84f808-91c6-3715-b90d-897b1c2d5d4c', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', '49692d4b-f5ab-37af-9e93-54c932e0917c', 'a6c9b5ef-5e4a-3671-a0f2-74a21e9bf3c5', 'umum', NULL, 'omnis fuga neque qui assumenda', 'DKL239928020A21', 'Repellendus qui sit vel et. Enim amet qui quam id provident. Quo dolorum occaecati quas corporis culpa excepturi et laudantium. Reiciendis repudiandae pariatur suscipit praesentium delectus dolores ad hic. Eveniet quos porro incidunt voluptas molestiae harum. Quia odit est aut fugiat.', 'Non quam aut omnis quis laudantium occaecati est. Culpa similique voluptate suscipit quas dicta optio repudiandae. Sequi voluptate est maiores laboriosam. Et et voluptatem fugiat voluptas ipsa dolorum. Incidunt doloribus veniam autem sunt et ad asperiores. Unde sed iusto aut id aut aut.', 'Nihil ut dolorem quas quas. Eligendi consequatur quae exercitationem saepe explicabo. Aliquam nulla in sequi laudantium necessitatibus autem. Reprehenderit delectus incidunt id voluptas velit alias. Repellat omnis rerum nulla pariatur. Perferendis earum ab enim harum sit nulla.', 'Est numquam optio nam atque. Provident dicta vel veniam et esse est. Nisi aperiam laboriosam unde. Qui numquam qui exercitationem qui excepturi assumenda. Ea magnam quia est praesentium id dolor. Quia eveniet rerum vel ad ut voluptatem.', ''),
('d4430f9a-ecef-30b5-ba12-64c89f4c3297', 'd8f0aa52-eb4e-3a1d-addc-776c13fdf6bd', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', '36742a49-bdb0-34ae-8e70-0e220078cc61', '5349f59e-d1c8-30a6-a080-a70da8d67cbe', 'resep dokter', NULL, 'blanditiis velit in eaque cumque', 'DKL956981129A21', 'Non ab quam consectetur porro dolor molestias. Quis qui non fugiat sunt nesciunt sunt sit. Dolores repellendus officia iusto vel porro. Placeat architecto enim ut ut saepe eos. Quo ipsum hic aut quia est sapiente sunt. Voluptas molestiae quod qui dolorum odio voluptatem.', 'Ut maiores omnis voluptatum nihil accusamus non. Atque est vero ipsa veniam porro molestias. Est aut totam tenetur sit explicabo. In hic veniam earum qui hic laudantium sit. Quibusdam rerum ducimus quisquam a esse. Culpa est quia iste nisi illum officiis.', 'Aspernatur quibusdam illo rerum excepturi totam numquam est ipsam. Vel recusandae nulla eligendi veritatis perferendis in sunt. Delectus quia ut aut et nemo possimus. Similique quibusdam iste quia ipsam omnis. Reprehenderit dolores mollitia autem. Debitis eum sit aut odit.', '', ''),
('d8cc0dec-3b01-3fad-b303-66a132c03fc0', '93845cdc-ed09-3bf6-bd78-1152c94718eb', '3da63f41-fcb5-3aa8-953c-589f77077e40', '75956a1a-c277-39bd-999f-d8bfe783759a', '430f8245-0948-3d3f-a058-0090e7a5076f', 'umum', NULL, 'neque distinctio cumque eius eaque', 'DKL685914362A21', 'Dolorum sint occaecati non voluptatum. Et sequi molestias nesciunt tempore. Illo et mollitia quia cum enim aliquid debitis. Consequatur a animi porro modi voluptatum eos voluptatem. Provident et non ea et rerum sequi similique. Et doloribus in magnam libero quidem nam.', 'Iste quia non molestias ut. Consequuntur dolorem atque voluptas omnis sit mollitia dolorem. Provident provident recusandae dolorum et quia. Earum maxime veritatis nisi vel consequuntur nulla doloribus. Libero autem ab cum alias ex ut. Aspernatur perferendis necessitatibus eveniet voluptas suscipit soluta.', 'Nam totam qui autem eos. Suscipit non ad ut sed reprehenderit eaque doloribus et. Velit rerum eum assumenda magni earum molestias et. Totam distinctio ratione cupiditate ratione voluptas. Commodi ducimus aut omnis omnis qui ut. Reiciendis iusto sed ea voluptatem sunt itaque ea.', '', 'Sed eos et sed nostrum. Qui sequi sit ab nostrum eaque. Libero quod quae cumque repellat mollitia. Corporis tempora neque quas nobis eligendi. Quod ex qui magnam sed adipisci et aperiam. Cumque dolorem similique aliquid molestiae.');
INSERT INTO `product_descriptions` (`description_id`, `category_id`, `group_id`, `unit_id`, `supplier_id`, `product_type`, `product_photo`, `product_manufacture`, `product_DPN`, `product_sideEffect`, `product_description`, `product_dosage`, `product_indication`, `product_notice`) VALUES
('e8bfca70-fed0-3397-858a-aa64cb657c4e', 'fa84f808-91c6-3715-b90d-897b1c2d5d4c', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', '49692d4b-f5ab-37af-9e93-54c932e0917c', 'a6c9b5ef-5e4a-3671-a0f2-74a21e9bf3c5', 'umum', NULL, 'accusamus labore enim earum fugit', 'DKL146249710A21', 'Commodi autem illo quia sit est et. Repellat nihil qui ullam rem qui dolorem voluptas dolor. Nostrum amet est cupiditate quia. Libero architecto perspiciatis pariatur sit et blanditiis. Voluptatem maxime omnis nesciunt consequatur illum. At rerum eum quis suscipit quia ut suscipit.', 'Et nobis eos libero incidunt rerum. Laudantium labore autem itaque dolor harum earum voluptas inventore. Minima veniam dicta velit cupiditate eligendi adipisci ut. Corrupti nobis odit quaerat nihil. Corrupti ducimus debitis debitis. Mollitia fuga nihil eum dolores nam eveniet fugit.', 'Fugit dolor consequuntur soluta voluptate porro perspiciatis. Velit sit voluptas pariatur eum ex. Rem esse ea blanditiis rerum quo aspernatur. Mollitia consequatur natus dolor id. Dolores illum eos autem necessitatibus. Omnis eum quidem perspiciatis qui doloremque.', '', ''),
('ec6bd722-1c4e-3764-a4fc-1ac0ca96303c', 'd8f0aa52-eb4e-3a1d-addc-776c13fdf6bd', '1d9706c4-c1bd-31f1-bfd4-40d63c22074d', '8a633afa-c9f4-34c8-aca6-d8f42916c443', '430f8245-0948-3d3f-a058-0090e7a5076f', 'umum', NULL, 'ullam repudiandae consequuntur ullam iste', 'DKL133400357A21', 'Repudiandae aliquam odit amet cumque. Ut voluptate nulla ipsum ad corrupti sit ea. Officiis ut est optio dolor amet. Esse illum nostrum aut enim est. Iste suscipit dolorem qui et omnis quis. Dolores iusto nihil occaecati quam nihil.', 'Est quis voluptatum sed occaecati. Qui et enim porro et non ut. Rem temporibus reprehenderit veniam nihil sit sint. Quidem illum enim magnam aspernatur sapiente in. Ut in ipsam voluptatum nam voluptatibus. Natus cum rerum ea debitis.', 'Sit odit commodi quisquam. Exercitationem voluptas sunt fuga atque et. Ut quas voluptatem ipsam quibusdam omnis itaque quo. Possimus id impedit consectetur saepe aut laudantium. Quam quod distinctio est itaque nam. Recusandae et molestias quisquam facere.', 'Perferendis nihil qui similique minus fugit. Culpa nobis voluptas quo quis maiores possimus et. Vel exercitationem et non modi. Nemo dolor tempore occaecati molestiae. Sed eum illo reprehenderit quis. Doloribus ullam facilis repellat laborum.', 'Deleniti facere dolor incidunt eveniet esse itaque fugit ut. Aliquid nihil ut cupiditate cum. Qui dolore suscipit optio. Exercitationem voluptatem ad eos architecto et. Ratione fugit corrupti iure delectus dicta quia laboriosam. Iste vitae officia repellat consequatur dolores.'),
('f4d9fa59-04ba-3d55-9324-8e75862c1552', 'fa84f808-91c6-3715-b90d-897b1c2d5d4c', 'd0cea926-721d-3f5e-9aa0-f5f9f2f087e2', '762e69a6-cf92-3dc1-9543-fd178e7aa96b', 'cfde7cd4-3d33-3b72-b7b2-badfddde4b6e', 'resep dokter', NULL, 'et dolore nulla iusto aliquid', 'DKL428291219A21', 'Dolor tempore consequuntur dolor at recusandae sunt quos dolore. In incidunt ipsum vitae dolores quidem accusamus. Quas ullam a vel voluptas illum ut. Cupiditate voluptatum eum nam atque ratione earum nostrum dicta. Temporibus modi eligendi quod ut atque aspernatur. Optio inventore illum voluptate modi beatae.', 'Quia sint nobis dolor optio ad. At natus eius veniam quasi ea. Quo qui nisi sint incidunt ea iusto aut recusandae. Voluptate consequuntur est et libero quisquam neque dolorem rerum. Et sint ratione qui culpa qui aliquam. Quod libero similique ab voluptas ut dolorem soluta.', 'Et voluptas dolorem laudantium. Dicta ut quam autem rerum dolores ipsam. Officiis quaerat qui quam eum voluptas quae. Qui commodi dolorum quis culpa voluptate qui. Veniam est odio totam error eligendi occaecati. Ut soluta repellat itaque quas nam.', 'In iure modi numquam nobis soluta beatae. Dolor eveniet veniam et placeat nostrum suscipit. Enim mollitia aut in totam ut illo itaque. Quo veniam qui omnis amet quas est. Ex aliquid autem amet aliquid dolore libero. Iste ducimus cupiditate quod odio ullam ut quos eveniet.', 'Voluptas quaerat itaque et necessitatibus voluptas. Perspiciatis sed nulla beatae voluptas qui molestiae. At sit temporibus temporibus. Molestiae in aliquid alias natus aut modi asperiores est. Quae rerum et fugiat quia commodi odit. Sint aperiam porro natus porro id.'),
('f5fc092d-5fed-3050-bf7c-cd44ddf2e70a', '93845cdc-ed09-3bf6-bd78-1152c94718eb', '79c8cac2-5264-3c8a-b02f-6657c71dfc2f', '36742a49-bdb0-34ae-8e70-0e220078cc61', 'a6c9b5ef-5e4a-3671-a0f2-74a21e9bf3c5', 'resep dokter', NULL, 'asperiores enim ut occaecati consequuntur', 'DKL124997299A21', 'Aut ut minus ipsam. Repellat dolores occaecati sit soluta maxime ut maiores eveniet. Eum error animi esse labore est. Hic aut quidem atque ut eos. Consequatur suscipit facilis quia. Molestias doloribus qui ipsam enim.', 'Consequatur consequatur sed perspiciatis pariatur maxime et quisquam consequatur. Molestiae dicta aspernatur accusamus. Eius reiciendis rerum voluptatem et quidem. Veniam blanditiis et unde cum. Laboriosam sed et qui eaque est. Odio tenetur expedita laudantium eligendi excepturi.', 'Minima ut porro quia iusto voluptates beatae reprehenderit. Dolorem est aut in sapiente suscipit sint. Voluptatem dolorum quas quidem rerum autem tempora possimus. Quia sit alias et natus voluptas dolores. Quo et est molestiae quis sit voluptatem. Et fuga ea quia.', 'Quis et nulla vitae. Minus consectetur voluptatem at saepe aut dolore ut ut. Esse odit esse eaque. Occaecati culpa totam porro ipsam qui qui facere in. Cumque omnis qui dolor beatae tempora consequatur dignissimos nihil. Soluta tempore autem quis adipisci voluptatem ad sit quia.', ''),
('fdf1bcab-c337-3d94-a05b-ece5599059e0', 'fa84f808-91c6-3715-b90d-897b1c2d5d4c', '79c8cac2-5264-3c8a-b02f-6657c71dfc2f', '75956a1a-c277-39bd-999f-d8bfe783759a', '5349f59e-d1c8-30a6-a080-a70da8d67cbe', 'umum', NULL, 'quam est ea exercitationem porro', 'DKL403527926A21', 'Quos similique quia voluptatem vel blanditiis inventore expedita. Delectus recusandae accusamus exercitationem earum doloribus et quae. Velit repellendus corporis qui. Quos nostrum dolor incidunt unde. Mollitia ea voluptatem distinctio quas saepe nisi ad quidem. Et rem saepe consectetur minus.', 'Nemo impedit consequatur recusandae vel voluptas. Enim et voluptates culpa. Voluptatibus dolores unde sit facere eum. Fugiat in voluptatibus expedita rerum et. Libero esse adipisci temporibus quaerat. Harum aut quas harum illo delectus architecto.', 'Ullam commodi non qui dolor deleniti. Quos perferendis voluptas nemo voluptas. Aliquid recusandae ad explicabo maiores nemo et deserunt id. Similique suscipit voluptas voluptatum sint. Veniam dolorum amet in et qui voluptas. Recusandae veritatis id labore et.', 'Dignissimos et ullam exercitationem amet nemo doloribus. Distinctio veritatis illo veritatis quaerat nobis. Quas quis quia culpa. Accusantium ipsam et eos ut. Quisquam omnis iure ut corporis cupiditate nostrum sint libero. Sit earum vel debitis non.', '');

-- --------------------------------------------------------

--
-- Struktur dari tabel `product_details`
--

CREATE TABLE `product_details` (
  `detail_id` char(36) NOT NULL,
  `product_id` char(36) NOT NULL,
  `product_expired` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `product_stock` int(11) NOT NULL,
  `product_buy_price` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `product_details`
--

INSERT INTO `product_details` (`detail_id`, `product_id`, `product_expired`, `product_stock`, `product_buy_price`) VALUES
('0d98c3f5-4a50-3657-a686-805dacfcdcaf', '8bdf3b69-7417-383d-b255-27294c4a9240', '1999-11-22 00:48:20', 30, 36712),
('11912eb9-d328-3262-a7c7-deffef5cf090', '48ebac60-b705-3212-aff9-fafba57b92ce', '1996-10-16 20:47:55', 15, 30961),
('11e05ab6-45e2-3378-bcef-88415b400a4f', '6687dbd5-2598-3a18-bf47-9adbc8638e10', '1980-04-24 10:46:19', 38, 29060),
('149def2a-fca5-3be4-9ba5-8b1b72cd0161', '85bfee4b-db10-3c1e-bcc8-8f2d330236c9', '1975-04-05 02:02:56', 30, 71184),
('1601cfdd-09ef-35e6-b620-8fd6dc2c7224', '15d21639-b534-39b9-b87e-775ae6aa2752', '2012-11-20 03:22:31', 38, 43522),
('1819a48d-e2da-3ea6-93f3-dc2226989ba5', '848312c2-8075-36af-8a51-738d06b066c7', '1982-01-24 07:11:41', 31, 17288),
('1b699ae9-05e3-3eb9-8107-d587ef7ca4ac', 'f2c9334a-1520-3657-9be0-3b9aaaca05af', '2002-09-18 12:20:17', 6, 55232),
('1e8a0660-78e0-3ad0-a99e-c713bd027e49', '42ef317a-a6ff-3fcb-ac93-bf9cfdc5e4da', '1970-07-05 21:53:03', 20, 99000),
('374ad697-362b-3697-a092-905160715bda', 'd20ff44c-a491-3b35-94dc-a2066a4f720b', '1999-04-02 04:46:00', 6, 59383),
('3a636c80-cd4e-3edf-9910-59c90a6d453c', '053be1ef-09eb-33ac-94db-4e15bdf873c8', '1999-06-05 19:06:17', 26, 31940),
('3c32dbd0-f881-3db2-b1ad-b26a3c572ad5', 'ab95b8c4-2279-3242-8e01-042d87d6f723', '2003-11-15 06:59:20', 48, 92674),
('40b0e322-6d7c-3ed8-a400-4c36d9ef9f8a', 'e1d9d80d-41a9-38a1-9bfe-49dce9968586', '1990-10-30 07:55:32', 43, 81414),
('4209401b-2792-3ce1-a84e-a8e248a8f7bc', '0fec533b-7f50-3ef5-8c89-5b1646859b98', '1987-11-05 21:09:06', 18, 81427),
('4523ecda-deca-3529-9df8-a59988cb8838', '685df6ec-fefb-31ba-9f92-1aa78c528105', '1970-07-16 14:49:42', 25, 13209),
('4ccb669d-60cd-305e-8f0f-a72a5290f3c2', 'b0de50b5-0caf-333c-9ca5-761429925f17', '2014-11-19 04:44:40', 14, 11770),
('5932cead-0c7b-39d7-9535-cd10791b526b', 'd439cfc0-6751-372d-90cf-5e67476f370c', '1981-01-11 23:36:07', 2, 68263),
('5bb6e1fd-7d79-31c5-ac50-19dacfc2787f', '6e5a9395-92ed-337a-9cfc-e2c322669bdc', '1987-09-04 15:48:08', 38, 3393),
('5c72bc4f-0c2e-3d25-8fff-62acdac60410', '89591f8c-f9d2-3a57-bdb4-87ed25292fb3', '2011-01-27 00:38:46', 39, 7061),
('61b14cdc-8da9-3de2-bee3-e98a656601f5', '8b28808b-6316-3128-a601-945b4976d130', '2021-07-13 15:19:17', 6, 32521),
('63e2face-0f7d-3caa-9ef7-82b934e3dfa6', '328394d6-cb2a-39e3-85ed-2666f6b71407', '2007-12-14 23:30:26', 43, 94689),
('6b14ede0-186b-34ce-948c-bcec6a0d9a04', '6ccec9da-d198-3e24-a56b-f4cc852547b2', '2011-12-14 10:04:55', 5, 71796),
('703b047f-9fce-3c9e-af6d-f30d53c51eb6', '9319db65-9b38-3285-a53d-90ee22e534b3', '1971-06-28 23:05:17', 22, 22935),
('72958ca7-9a00-312b-9332-5c7d8227dca1', 'fa6d8860-317d-3663-a198-d42fe9a361b4', '2022-08-17 19:43:41', 27, 31087),
('770da9bc-7dcb-377a-973c-b702848f82a5', '40617e87-c213-3290-93d9-30fafb3eaf3c', '2004-01-16 21:41:27', 42, 10048),
('7749fe6a-b8c2-3fe3-af1f-17c9adcba31c', '25b03272-1515-3373-9eec-2631f6cd237d', '2006-03-30 12:56:03', 21, 83529),
('7c90cf29-c5b8-3256-af81-b7d68562741c', 'd6565d09-8f31-3988-954b-cd0e2877f4ff', '1970-02-06 04:27:15', 31, 2542),
('90ebce6a-0740-3390-bf0d-fae5ad8f47f6', 'c5c9e404-5014-347e-b890-ee621618932e', '1971-07-09 11:51:22', 32, 83237),
('97a2ca45-1ffb-3404-b15a-e0a4ade9f380', 'fa572c02-0605-3ac2-8073-82f7b284ae32', '1982-10-18 02:26:36', 37, 45949),
('a808d23b-b1b6-30d2-9626-b4bcb0d13271', '0ebe1ae5-5ce6-3dd8-95f3-cd5693ec8d5f', '1983-06-17 20:55:50', 11, 76726),
('af78a658-a0dc-3cc8-8ac9-efe6c2756d6c', '4f4f3c0a-9f0e-3b19-9978-133910980efe', '1990-06-04 09:32:58', 31, 71658),
('b3d1d461-4b32-3bb9-8c79-4c371e7439c2', 'e9e59ffe-cca2-31ba-8434-397b44513248', '2017-02-18 11:01:42', 23, 14820),
('b578ae73-d18f-3db5-915c-72e61a2a8b8e', '13f1f2f3-4a8d-33d4-8185-aaf27e5bae73', '1978-02-26 07:04:51', 12, 97902),
('bf73533b-4c5d-3ef6-af90-7045212054c7', '7ab7b981-d342-353e-9560-f4cb566b762f', '2019-04-14 14:25:33', 37, 80645),
('bfb573ea-53ff-3ef5-b334-a217550c0d97', '65482e67-259f-3e21-aa26-01dbfac1b912', '2012-02-27 02:10:00', 48, 38357),
('c0a701e6-9770-33b1-b583-45f7796bd4b0', '1c64ee27-d4dd-31c6-8f31-ceaa05dd9154', '2002-02-06 08:01:17', 43, 29649),
('cf09c7b9-2ba7-3463-b600-fe5717f3c657', '1bdfb774-0c11-3bd1-8682-861c66ed256a', '1974-03-01 07:06:45', 14, 85574),
('d410d7fb-d845-350b-9120-48d56cf01fc1', 'f0b5c97e-252a-3bbf-b59a-f676219fe466', '2001-01-11 01:47:14', 42, 37097),
('e78cd7d8-5722-3ce4-87e3-9dfc48fe7ad0', '7bee6455-edd0-3b1b-b808-c623b7a0638f', '2001-06-09 11:01:16', 2, 4318),
('ece7d8b4-932d-3535-baf8-af602021f515', 'b424959e-e85d-3e6e-95ac-2fa39955955a', '2018-09-11 11:37:27', 14, 80808),
('f02de254-b28b-3af9-aa03-504cb0491f65', 'bf97831a-9836-3809-ac51-01094e4cbbd5', '2003-11-28 02:27:47', 20, 60796);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `product_view`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `product_view` (
`product_id` char(36)
,`product_name` varchar(255)
,`product_status` enum('aktif','tidak aktif','exp')
,`category` varchar(100)
,`group` varchar(30)
,`unit` varchar(30)
,`supplier` varchar(255)
,`product_type` enum('umum','resep dokter')
,`product_photo` varchar(255)
,`product_manufacture` varchar(255)
,`product_DPN` varchar(15)
,`product_sideEffect` longtext
,`product_description` longtext
,`product_dosage` longtext
,`product_indication` longtext
,`product_notice` longtext
,`product_expired` timestamp
,`product_stock` decimal(32,0)
,`product_buy_price` int(11)
,`product_sell_price` int(11)
);

-- --------------------------------------------------------

--
-- Struktur dari tabel `selling_invoices`
--

CREATE TABLE `selling_invoices` (
  `selling_invoice_id` char(36) NOT NULL,
  `invoice_code` varchar(20) NOT NULL,
  `cashier_name` varchar(100) DEFAULT NULL,
  `customer_id` char(36) DEFAULT NULL,
  `recipient_name` varchar(100) DEFAULT NULL,
  `recipient_phone` varchar(14) DEFAULT NULL,
  `recipient_file` varchar(255) DEFAULT NULL,
  `recipient_request` longtext DEFAULT NULL,
  `recipient_bank` varchar(255) DEFAULT NULL,
  `recipient_payment` varchar(255) DEFAULT NULL,
  `order_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `order_complete` timestamp NULL DEFAULT NULL,
  `refund_file` varchar(255) DEFAULT NULL,
  `reject_comment` varchar(255) DEFAULT NULL,
  `order_status` enum('Berhasil','Gagal','Menunggu Pengembalian','Menunggu Konfirmasi','Menunggu Pengambilan','Offline','Refund') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `selling_invoices`
--

INSERT INTO `selling_invoices` (`selling_invoice_id`, `invoice_code`, `cashier_name`, `customer_id`, `recipient_name`, `recipient_phone`, `recipient_file`, `recipient_request`, `recipient_bank`, `recipient_payment`, `order_date`, `order_complete`, `refund_file`, `reject_comment`, `order_status`) VALUES
('06533a7f-eb5f-3c78-8ceb-da328715b04a', 'INV-000036', 'kasir1', 'e45b61f5-e663-3dae-9c66-7c04f76dc1ff', 'aperiam', '088283260303', 'facere.jpg', 'qui quasi sapiente reiciendis saepe voluptatibus vel quia accusamus cumque', 'ipsum', 'perferendis.jpg', '2018-11-11 16:20:11', '2021-09-14 23:23:04', 'sit.jpg', 'nulla aliquid eos suscipit repellat voluptatibus quia quis dolorem nobis dolores quia esse modi quis', 'Menunggu Pengembalian'),
('0cee2e0a-750b-3b79-bdd6-2e7cf090f946', 'INV-000025', 'kasir1', 'fa61d061-116b-3bd5-a805-1693ae311c3d', 'architecto', '083406717461', 'est.jpg', 'quod minus rerum enim dignissimos ab recusandae consequatur et sint', 'in', 'et.jpg', '2021-09-13 09:25:10', '2020-12-30 02:35:55', 'adipisci.jpg', 'ad perferendis accusamus ab rerum ea magni qui non cumque ea et ab aliquam excepturi', 'Gagal'),
('0f2432f2-09c1-3b6f-aa30-ae87f64dd053', 'INV-000009', 'kasir1', '6f5616cb-9679-329b-ae1c-0373d177860d', 'architecto', '083131679970', 'dolores.jpg', 'unde eum ea nam reiciendis nobis consequuntur voluptas sequi sed', 'ipsam', 'culpa.jpg', '2018-11-21 05:43:01', '2021-04-07 22:34:49', 'qui.jpg', 'est iure expedita impedit id hic qui veritatis veritatis sed eius a porro ratione dignissimos', 'Menunggu Pengembalian'),
('1687b8ba-52bf-3f4e-93a8-ef93fd5d535b', 'INV-000022', 'kasir1', '5756b26d-5bb1-3b61-a441-5fa214a7c637', 'quibusdam', '088519502720', 'ut.jpg', 'veritatis reprehenderit ipsam quis harum doloribus libero atque sit architecto', 'excepturi', 'nihil.jpg', '2018-06-27 14:46:27', '2018-11-04 15:33:25', 'modi.jpg', 'alias illum aliquid labore vel aut reiciendis occaecati porro facere ex blanditiis eum tempore dolorum', 'Berhasil'),
('2d91b66b-8594-35ba-8e87-b595eec6b510', 'INV-000005', 'kasir1', '6f5616cb-9679-329b-ae1c-0373d177860d', 'distinctio', '087546822517', 'consectetur.jpg', 'quis adipisci ratione autem quae voluptatum sed minima esse qui', 'nihil', 'aut.jpg', '2018-07-08 12:01:18', '2021-08-11 19:32:04', 'quidem.jpg', 'repellendus sed modi voluptate ratione atque inventore omnis et qui necessitatibus autem dolores voluptas tempore', 'Menunggu Konfirmasi'),
('3dcf4b74-aa5e-38ec-a86d-109b17ecfb70', 'INV-000001', 'kasir1', 'e45b61f5-e663-3dae-9c66-7c04f76dc1ff', 'adipisci', '084157832190', 'rerum.jpg', 'iusto velit eos voluptatem illo eum expedita velit nesciunt non', 'inventore', 'recusandae.jpg', '2021-12-06 10:01:26', '2020-03-19 03:11:58', 'doloribus.jpg', 'deleniti soluta qui similique iure debitis magnam minus eaque numquam non dolor distinctio dolor commodi', 'Refund'),
('3f4d0c10-fcdb-3e29-bd36-0b150b76860a', 'INV-000010', 'kasir1', '5756b26d-5bb1-3b61-a441-5fa214a7c637', 'adipisci', '083877933233', 'aliquid.jpg', 'aut eum tenetur molestias temporibus iusto veritatis et vel a', 'sed', 'ut.jpg', '2019-06-20 12:59:40', '2019-12-10 11:43:33', 'ut.jpg', 'provident vel non qui autem alias qui voluptatum dignissimos aut dicta ea nihil asperiores a', 'Menunggu Pengembalian'),
('57f16ced-8820-3343-950a-4306d8d084de', 'INV-000020', 'kasir1', 'fa61d061-116b-3bd5-a805-1693ae311c3d', 'winzliu', '086324861264', 'omnis.jpg', 'est adipisci maiores eligendi aut autem repellendus quia in odio', 'rerum', 'odio.jpg', '2024-02-19 16:18:31', '2024-09-30 19:15:26', 'tempore.jpg', 'et ipsa qui sint eos soluta vitae sit ipsum aut modi et omnis rem temporibus', 'Refund'),
('61766a6b-cb12-3840-9392-9ba29a98626d', 'INV-000016', 'kasir1', 'e45b61f5-e663-3dae-9c66-7c04f76dc1ff', 'facere', '086318005018', 'quibusdam.jpg', 'et doloremque aut nostrum veniam provident velit et nesciunt eaque', 'fugit', 'fugiat.jpg', '2020-10-26 02:52:54', '2019-05-17 11:45:46', 'aut.jpg', 'sed dolorem voluptas modi in hic dolorem quibusdam voluptatem neque officiis pariatur veniam id et', 'Refund'),
('6298084c-fd96-3834-9df6-ee6d2be91359', 'INV-000035', 'kasir1', 'b5112031-4c58-3bd0-9a66-cf12c56949dd', 'quibusdam', '087142448995', 'maiores.jpg', 'nisi molestias pariatur qui error alias nemo voluptas nulla excepturi', 'itaque', 'nesciunt.jpg', '2022-11-28 05:27:50', '2024-05-19 20:16:15', 'repellendus.jpg', 'blanditiis sed asperiores laudantium assumenda ab expedita consequatur ut magni qui non qui sunt minima', 'Menunggu Pengembalian'),
('62c09244-e01e-3a81-9802-2f47ec7229ad', 'INV-000017', 'kasir1', '5756b26d-5bb1-3b61-a441-5fa214a7c637', 'dolorem', '088767810567', 'officiis.jpg', 'ipsa non voluptas voluptatum fugiat rerum autem sapiente expedita voluptas', 'accusantium', 'asperiores.jpg', '2024-03-21 15:23:11', '2022-01-18 03:18:02', 'eum.jpg', 'earum recusandae cum mollitia molestias provident sit laborum molestiae est dolore omnis eos ea expedita', 'Menunggu Pengembalian'),
('66574338-a84f-39ec-bd12-14aa813018cb', 'INV-000034', 'kasir1', '8170ebb2-f923-3822-adb3-c1a10a9572d6', 'quibusdam', '089149965121', 'totam.jpg', 'sed eaque qui totam est veritatis cupiditate quia eveniet omnis', 'est', 'tempora.jpg', '2021-10-26 19:07:03', '2018-04-20 02:49:50', 'culpa.jpg', 'sunt ex quo vero enim ipsa exercitationem molestiae alias illo perspiciatis occaecati facere aliquid voluptatem', 'Gagal'),
('734c3bb9-df08-319d-add5-f59a966d7085', 'INV-000032', 'kasir1', 'fa61d061-116b-3bd5-a805-1693ae311c3d', 'aperiam', '084261333026', 'nemo.jpg', 'ut velit id debitis nesciunt quia hic ut beatae qui', 'facilis', 'qui.jpg', '2021-09-24 14:28:42', '2022-07-07 00:38:49', 'earum.jpg', 'ut voluptas facere aut ratione est at culpa numquam harum eius dolorum et fugiat et', 'Gagal'),
('8464bcc8-1668-39ae-8e71-dbbbfc86642f', 'INV-000038', 'kasir1', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', 'aperiam', '084786232869', 'sit.jpg', 'et dolorum hic asperiores beatae dolores voluptas eveniet libero vel', 'sed', 'et.jpg', '2024-07-13 16:57:17', '2021-06-03 21:02:36', 'maiores.jpg', 'libero eos quo expedita voluptatem earum voluptatibus sed impedit corporis et voluptatem eligendi deleniti eligendi', 'Menunggu Pengembalian'),
('87a56ca2-017b-37ce-8ec2-59f129f62b0f', 'INV-000030', 'kasir1', '5756b26d-5bb1-3b61-a441-5fa214a7c637', 'quibusdam', '082946253273', 'recusandae.jpg', 'consequuntur quo ipsa ut est et dolores delectus nam voluptas', 'voluptate', 'aliquam.jpg', '2022-05-09 05:36:20', '2019-09-07 20:54:53', 'cumque.jpg', 'odit vel officiis reiciendis animi omnis et similique dolorum sit cupiditate quia non culpa quibusdam', 'Menunggu Pengambilan'),
('88154e0e-2d64-3579-8ad0-24e616b505e6', 'INV-000029', 'kasir1', 'fa61d061-116b-3bd5-a805-1693ae311c3d', 'winzliu', '083423937250', 'eos.jpg', 'provident libero accusantium similique est recusandae velit commodi aut eius', 'omnis', 'placeat.jpg', '2022-09-30 07:48:05', '2024-03-23 11:13:29', 'magnam.jpg', 'rem labore quia nobis quia aperiam est suscipit est amet ut incidunt totam ut autem', 'Berhasil'),
('8b787d38-7724-34a2-a409-45d3b5b9c8c7', 'INV-000024', 'kasir1', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', 'dolorem', '082472148674', 'et.jpg', 'explicabo sunt in non corrupti et id autem nihil ratione', 'tempora', 'vel.jpg', '2021-02-24 09:40:55', '2020-12-27 02:37:56', 'fugiat.jpg', 'voluptatem odio modi voluptatum maxime illo praesentium expedita minima quis et minus culpa qui est', 'Menunggu Konfirmasi'),
('8d2fda91-e710-390a-a269-863220b595d1', 'INV-000003', 'kasir1', '8170ebb2-f923-3822-adb3-c1a10a9572d6', 'architecto', '087286640635', 'et.jpg', 'culpa fugit tenetur dolor facere molestias quis expedita consectetur repudiandae', 'nam', 'fuga.jpg', '2018-05-02 02:01:29', '2023-07-14 13:29:13', 'similique.jpg', 'et totam voluptas est saepe qui sunt occaecati eligendi officiis ut labore facilis suscipit natus', 'Menunggu Pengambilan'),
('90473284-b1c2-38df-b6c9-77bc1b85a350', 'INV-000007', 'kasir1', '5756b26d-5bb1-3b61-a441-5fa214a7c637', 'architecto', '085245190848', 'veritatis.jpg', 'sequi accusantium mollitia qui non suscipit quod quis autem at', 'nostrum', 'consequatur.jpg', '2022-08-09 10:31:00', '2019-03-29 22:01:36', 'quidem.jpg', 'voluptatem non autem nihil quo excepturi sint quidem soluta molestias praesentium velit sapiente in quidem', 'Berhasil'),
('99641d34-fb42-3d3d-a318-33a2f32f24a1', 'INV-000040', 'kasir1', '9995c553-fb5c-35f4-bc50-2f1d608729ff', 'aperiam', '082965509434', 'veritatis.jpg', 'atque nisi officia a sequi sunt vitae autem maiores adipisci', 'ipsum', 'similique.jpg', '2021-10-09 02:51:05', '2022-10-14 04:51:33', 'rem.jpg', 'doloribus quia unde neque distinctio numquam vero fugiat reprehenderit possimus nobis ut quia quos quasi', 'Menunggu Pengembalian'),
('9bbc7213-fa32-3b35-b626-ae2f002bb59e', 'INV-000019', 'kasir1', 'e45b61f5-e663-3dae-9c66-7c04f76dc1ff', 'quibusdam', '084012961372', 'enim.jpg', 'omnis cum repellendus est quibusdam aperiam delectus voluptatem dolor quidem', 'quia', 'vel.jpg', '2023-08-10 06:46:54', '2019-03-21 22:19:32', 'nihil.jpg', 'similique ut non earum saepe recusandae ipsum occaecati nemo quis et tempora in unde voluptates', 'Menunggu Pengambilan'),
('a46db931-b106-32d1-b79a-626dd9c31946', 'INV-000018', 'kasir1', 'dd26224b-5f69-3935-9f43-dbb7a0cd0daf', 'voluptatum', '082052066099', 'qui.jpg', 'non cupiditate laboriosam corporis cumque enim repellat ab aut voluptas', 'vel', 'dolorum.jpg', '2019-07-09 17:24:32', '2021-07-25 04:33:53', 'aspernatur.jpg', 'ut placeat quisquam commodi sapiente tempora quisquam reprehenderit beatae possimus iusto ratione vel odit cum', 'Menunggu Konfirmasi'),
('b003cee8-637b-3205-a72d-e7eb040fff76', 'INV-000006', 'kasir1', 'e45b61f5-e663-3dae-9c66-7c04f76dc1ff', 'facere', '083034127814', 'et.jpg', 'doloribus nobis laboriosam ad aut mollitia distinctio laboriosam dolor ad', 'dolorum', 'quia.jpg', '2021-07-12 08:01:51', '2019-02-15 06:16:46', 'aspernatur.jpg', 'inventore nihil quo unde quam voluptatem autem maiores iure nostrum voluptatem id nulla nemo quia', 'Berhasil'),
('b0685476-8d03-330d-84ba-890e0af0d3f7', 'INV-000033', 'kasir1', '6f5616cb-9679-329b-ae1c-0373d177860d', 'facere', '087209783477', 'corporis.jpg', 'quis amet cumque incidunt praesentium corporis blanditiis doloremque explicabo dolor', 'exercitationem', 'consequuntur.jpg', '2024-07-04 01:43:03', '2024-10-24 20:22:36', 'rerum.jpg', 'nam placeat corporis maxime dignissimos qui quos vel accusamus eos qui molestiae vel et asperiores', 'Menunggu Pengambilan'),
('b24236e0-1d81-37f5-9513-ee7f30b6eead', 'INV-000015', 'kasir1', 'b5112031-4c58-3bd0-9a66-cf12c56949dd', 'aperiam', '087388891209', 'vitae.jpg', 'odit qui amet molestias animi libero ullam maiores consequuntur ut', 'id', 'et.jpg', '2024-01-17 11:11:33', '2023-01-23 06:33:21', 'ut.jpg', 'error quis doloribus provident nihil sed neque molestias asperiores officiis dolorum est soluta et nostrum', 'Menunggu Pengembalian'),
('b5452664-62ff-3ffe-821b-bc82d50a49f5', 'INV-000027', 'kasir1', '8170ebb2-f923-3822-adb3-c1a10a9572d6', 'facere', '084471643357', 'ut.jpg', 'ut eaque voluptatem velit tempore dolorem qui facilis soluta asperiores', 'optio', 'et.jpg', '2022-02-07 05:34:42', '2024-04-21 01:00:32', 'nihil.jpg', 'qui qui et ut sit nostrum aut nostrum cum quam velit fugit molestiae mollitia doloribus', 'Menunggu Pengambilan'),
('b7ddc3b4-2ce6-305f-bc24-5fd7cadfcd69', 'INV-000039', 'kasir1', '9995c553-fb5c-35f4-bc50-2f1d608729ff', 'distinctio', '083504101007', 'aut.jpg', 'nostrum quos non non incidunt est minima at dolores sunt', 'ut', 'cum.jpg', '2021-01-09 02:44:24', '2022-08-01 02:55:13', 'facilis.jpg', 'autem et vel rerum sit iure nulla neque dolor natus est asperiores rerum id ut', 'Gagal'),
('ba71c34b-bb97-35b9-9e62-c9605e374dab', 'INV-000031', 'kasir1', 'dd26224b-5f69-3935-9f43-dbb7a0cd0daf', 'adipisci', '082406463608', 'vitae.jpg', 'blanditiis ad dolore id aliquid culpa hic quasi quisquam sequi', 'accusantium', 'odio.jpg', '2022-08-01 20:39:03', '2019-10-08 08:43:55', 'voluptas.jpg', 'magni vel fugit tenetur expedita et qui ipsam facilis aut provident aut et quas ut', 'Gagal'),
('ba7a22b3-53da-3259-aff9-f4c1c6eec2b7', 'INV-000023', 'kasir1', 'fa61d061-116b-3bd5-a805-1693ae311c3d', 'dolorem', '084694922200', 'consequatur.jpg', 'veniam ex dolore vitae molestiae quia eius illum excepturi autem', 'sequi', 'delectus.jpg', '2023-08-09 20:25:18', '2019-01-18 19:31:42', 'dolores.jpg', 'neque facilis doloremque dicta vero dolorum enim ut quaerat asperiores consequatur voluptas suscipit similique neque', 'Gagal'),
('bafbf8b8-f9f8-35cf-a9e6-13d794a591a0', 'INV-000013', 'kasir1', '6f5616cb-9679-329b-ae1c-0373d177860d', 'winzliu', '085235750268', 'cum.jpg', 'excepturi enim soluta laborum et vel consectetur non adipisci sed', 'dignissimos', 'aut.jpg', '2019-01-22 04:57:22', '2023-01-02 08:55:56', 'facere.jpg', 'excepturi deleniti facere repellendus aut dolorem sit consequatur eum quia aut modi facere ipsa laboriosam', 'Refund'),
('be8c2ab5-8ac7-3471-8ba3-22b9401d1dee', 'INV-000021', 'kasir1', 'e45b61f5-e663-3dae-9c66-7c04f76dc1ff', 'dolorem', '085510326876', 'iure.jpg', 'cupiditate sequi ex vero asperiores rerum eius nemo porro itaque', 'sequi', 'reprehenderit.jpg', '2022-04-30 16:13:50', '2020-11-09 04:41:19', 'quasi.jpg', 'quibusdam est sed aut sed consequatur temporibus doloribus ab reiciendis nostrum error iusto quidem sint', 'Menunggu Pengambilan'),
('c10a1f6f-fe4e-3b72-af38-48871db80528', 'INV-000014', 'kasir1', 'b5112031-4c58-3bd0-9a66-cf12c56949dd', 'winzliu', '086256658974', 'repellat.jpg', 'aut voluptas velit earum accusamus reprehenderit molestiae eum ut modi', 'magni', 'eaque.jpg', '2023-06-11 22:42:21', '2024-06-26 02:50:02', 'repellat.jpg', 'ut repellendus quod eos adipisci cupiditate natus aspernatur consequatur et tenetur dolore cupiditate quo et', 'Menunggu Pengembalian'),
('cd569301-f8ac-3c0f-b418-65b2035cd60c', 'INV-000004', 'kasir1', 'dd26224b-5f69-3935-9f43-dbb7a0cd0daf', 'quibusdam', '086120722520', 'quam.jpg', 'voluptates rerum laboriosam et accusamus maiores aut nulla dolor in', 'officiis', 'pariatur.jpg', '2022-06-18 21:57:03', '2022-10-04 17:38:25', 'temporibus.jpg', 'aut non dolorum aut et earum pariatur ut nisi eveniet officiis ducimus molestias in sed', 'Menunggu Konfirmasi'),
('ceee3306-8952-3bd0-b901-ac260bc46091', 'INV-000011', 'kasir1', '8170ebb2-f923-3822-adb3-c1a10a9572d6', 'facere', '082304991611', 'rerum.jpg', 'saepe qui et et in non repellat ipsam repellendus ut', 'est', 'illo.jpg', '2020-09-28 04:11:07', '2018-05-06 14:33:22', 'harum.jpg', 'corrupti sunt ratione ut vel facilis temporibus odit ipsa ut sint aperiam et qui iure', 'Menunggu Konfirmasi'),
('d1a2bf7a-ddcb-3671-b1ad-e17e2ce6f70b', 'INV-000026', 'kasir1', '9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', 'aperiam', '089125451245', 'assumenda.jpg', 'veritatis sunt quaerat sapiente quia incidunt et sed facere accusamus', 'quam', 'ipsam.jpg', '2022-09-10 11:43:00', '2020-05-15 16:21:41', 'qui.jpg', 'animi itaque omnis et natus perspiciatis fuga quia saepe velit non voluptatum sequi consequatur libero', 'Refund'),
('dd6c5bff-4a4d-3c86-b83f-f756ecfd77b6', 'INV-000037', 'kasir1', 'fa61d061-116b-3bd5-a805-1693ae311c3d', 'distinctio', '086912391972', 'dignissimos.jpg', 'quasi perspiciatis qui aperiam temporibus consequuntur labore est sunt dolorem', 'omnis', 'eum.jpg', '2023-10-09 20:18:20', '2024-03-20 16:16:22', 'molestiae.jpg', 'delectus placeat velit quia quo natus itaque impedit praesentium quia modi totam et mollitia id', 'Menunggu Konfirmasi'),
('ed0b5c52-40e3-38d2-98ed-989dcb9d8313', 'INV-000028', 'kasir1', 'dd26224b-5f69-3935-9f43-dbb7a0cd0daf', 'dolorem', '086396771560', 'voluptatibus.jpg', 'maxime soluta ea recusandae at illum repellat doloribus temporibus magni', 'in', 'quam.jpg', '2021-11-13 07:07:54', '2024-12-13 10:51:03', 'at.jpg', 'sed iure ut amet et quas quaerat numquam at explicabo et eaque cupiditate et aliquid', 'Menunggu Konfirmasi'),
('ef128db1-355b-3549-a2e9-d0b02f5e1aad', 'INV-000012', 'kasir1', '8170ebb2-f923-3822-adb3-c1a10a9572d6', 'winzliu', '088082300777', 'aliquid.jpg', 'ex eum dolor omnis enim autem quia est et unde', 'rerum', 'veritatis.jpg', '2019-04-05 00:12:50', '2023-03-03 07:13:18', 'id.jpg', 'et sit sit consequatur facere ut consequatur ipsam molestiae accusantium earum consectetur temporibus sed aut', 'Menunggu Konfirmasi'),
('f6b2c8ef-ca30-37c1-9dee-5ed282afaf18', 'INV-000002', 'kasir1', '6f5616cb-9679-329b-ae1c-0373d177860d', 'voluptatum', '088438688490', 'quia.jpg', 'aut sed impedit sit quod nam est vel deserunt quos', 'veritatis', 'et.jpg', '2019-05-01 08:04:39', '2020-02-07 07:57:48', 'eius.jpg', 'ratione omnis aut unde sit rem vel ab nisi debitis placeat aliquid distinctio ratione rerum', 'Berhasil'),
('f93f0435-8e4d-31fb-9c97-17396dd7d630', 'INV-000008', 'kasir1', '8170ebb2-f923-3822-adb3-c1a10a9572d6', 'adipisci', '081141265075', 'voluptas.jpg', 'consequuntur deleniti fuga maiores ad quisquam nesciunt dolore labore amet', 'aliquid', 'consequatur.jpg', '2019-07-26 11:05:02', '2018-09-21 17:25:47', 'accusantium.jpg', 'ut accusantium blanditiis illo dolore perferendis ratione dolorem sit expedita facilis dolor voluptas qui rem', 'Menunggu Konfirmasi');

--
-- Trigger `selling_invoices`
--
DELIMITER $$
CREATE TRIGGER `cannot_delete_selling_invoice` BEFORE DELETE ON `selling_invoices` FOR EACH ROW BEGIN 
            SIGNAL SQLSTATE '45000' SET
            MESSAGE_TEXT = 'Tidak Dapat Menghapus Invoice';
        END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `cannot_update_selling_invoices` BEFORE UPDATE ON `selling_invoices` FOR EACH ROW BEGIN
            IF (OLD.invoice_code <> NEW.invoice_code OR OLD.customer_id <> NEW.customer_id OR OLD.recipient_name <> NEW.recipient_name OR OLD.recipient_phone <> NEW.recipient_phone OR OLD.recipient_file <> NEW.recipient_file OR OLD.recipient_request <> NEW.recipient_request OR OLD.recipient_bank <> NEW.recipient_bank OR OLD.recipient_payment <> NEW.recipient_payment OR OLD.order_date <> NEW.order_date) THEN
                SIGNAL SQLSTATE '45000' SET
                MESSAGE_TEXT = 'Tidak Dapat Mengupdate Data Berikut Pada Invoice';
            END IF;
        END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `selling_update_trigger` AFTER UPDATE ON `selling_invoices` FOR EACH ROW BEGIN 
            CALL insert_log(NEW.invoice_code ,NEW.cashier_name ,'Status Penjualan', 'update', OLD.order_status, NEW.order_status);
        END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `selling_invoice_details`
--

CREATE TABLE `selling_invoice_details` (
  `selling_detail_id` char(36) NOT NULL,
  `selling_invoice_id` char(36) NOT NULL,
  `product_name` varchar(255) NOT NULL,
  `product_type` enum('umum','resep dokter') NOT NULL,
  `product_sell_price` int(11) NOT NULL,
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `selling_invoice_details`
--

INSERT INTO `selling_invoice_details` (`selling_detail_id`, `selling_invoice_id`, `product_name`, `product_type`, `product_sell_price`, `quantity`) VALUES
('01abac83-c29b-36f3-a857-ab9e71093b94', '8b787d38-7724-34a2-a409-45d3b5b9c8c7', 'Atque eos animi optio est quae officiis ad earum.', 'umum', 96869, 1),
('0210999d-d415-31f9-9286-0d40b2333544', 'b5452664-62ff-3ffe-821b-bc82d50a49f5', 'Est voluptas voluptatem distinctio inventore.', 'umum', 25386, 16),
('04c31f36-dc83-3cdc-94a3-e499a1340a2a', 'ba7a22b3-53da-3259-aff9-f4c1c6eec2b7', 'Sint error tempora architecto dolor id non a.', 'umum', 15212, 20),
('0bafc05f-ba78-3ff1-9163-7c256c58919a', '3dcf4b74-aa5e-38ec-a86d-109b17ecfb70', 'Minus quidem suscipit expedita totam ut dolores.', 'umum', 32376, 9),
('11a10ef3-fe0c-334d-9b43-330e0423ae08', '06533a7f-eb5f-3c78-8ceb-da328715b04a', 'Quidem error quis blanditiis.', 'umum', 9050, 19),
('14892a7b-91e2-3960-b809-0d93f4a9be8f', '1687b8ba-52bf-3f4e-93a8-ef93fd5d535b', 'Voluptatibus optio magnam ut veniam culpa eos.', 'umum', 41671, 16),
('17febe37-b6d2-396f-804a-f3e4cab6c270', '8b787d38-7724-34a2-a409-45d3b5b9c8c7', 'Animi qui odit quis nulla.', 'umum', 44981, 17),
('190113b9-aa0b-3af9-91d5-0d8bdd8c2d40', 'b24236e0-1d81-37f5-9513-ee7f30b6eead', 'Odio ut nihil molestiae fuga.', 'umum', 37419, 12),
('1983743e-6ac9-3bb2-9644-b5ec98174feb', '06533a7f-eb5f-3c78-8ceb-da328715b04a', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 14),
('1ae6ded7-f0eb-36f6-a372-12cf3f76461d', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Dolores esse non sequi vel et.', 'umum', 73170, 8),
('1d4e5c08-10aa-3a0f-8790-1d1bdc6d7d1d', '0cee2e0a-750b-3b79-bdd6-2e7cf090f946', 'Voluptatem necessitatibus a quia rerum.', 'umum', 13496, 20),
('1e140ecc-b5fc-30e4-b7ad-1f34719ab818', 'cd569301-f8ac-3c0f-b418-65b2035cd60c', 'Est voluptas voluptatem distinctio inventore.', 'umum', 25386, 14),
('1f9b9cbc-ead7-3a51-9d8d-e1166a5dc568', '87a56ca2-017b-37ce-8ec2-59f129f62b0f', 'Eos eveniet totam sequi nemo.', 'umum', 83376, 10),
('2317c98b-a0e1-3872-943a-ab40941f1588', '8b787d38-7724-34a2-a409-45d3b5b9c8c7', 'Culpa error et ratione cumque assumenda.', 'umum', 56902, 15),
('25bf279d-9cf7-3f4e-81dd-5cf7888f9c14', 'be8c2ab5-8ac7-3471-8ba3-22b9401d1dee', 'Voluptatibus optio magnam ut veniam culpa eos.', 'umum', 41671, 6),
('26d5525c-7cf2-388e-ba62-da8ec88708f5', '87a56ca2-017b-37ce-8ec2-59f129f62b0f', 'Dolores esse non sequi vel et.', 'umum', 73170, 15),
('2cbdbf9d-284c-353c-903b-b1b4c8ff7757', 'ceee3306-8952-3bd0-b901-ac260bc46091', 'Quae aut ea quasi ut molestias.', 'umum', 67168, 18),
('2eae5d7c-1054-3113-bb0a-bcdb1b5bb9ef', 'be8c2ab5-8ac7-3471-8ba3-22b9401d1dee', 'Nihil laudantium officia commodi et.', 'umum', 20052, 11),
('3012c5de-c0f6-33ea-9ea0-f76227d9c9aa', 'b0685476-8d03-330d-84ba-890e0af0d3f7', 'Eos eveniet totam sequi nemo.', 'umum', 83376, 5),
('30790f57-d40d-365a-a162-b80817360738', '1687b8ba-52bf-3f4e-93a8-ef93fd5d535b', 'Laboriosam sed et qui nostrum.', 'umum', 23137, 6),
('30ab1a5d-99ec-3306-9f23-caab4ba20f23', '3dcf4b74-aa5e-38ec-a86d-109b17ecfb70', 'Sit nihil explicabo veritatis fugit omnis.', 'umum', 28630, 16),
('33c0d30f-5b06-34c3-b7e8-282bb172fd94', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Atque eos animi optio est quae officiis ad earum.', 'umum', 96869, 6),
('3479a25e-cc0a-3e99-8348-9d54e3c37135', '99641d34-fb42-3d3d-a318-33a2f32f24a1', 'Voluptatem necessitatibus a quia rerum.', 'umum', 13496, 3),
('34b41733-67b0-33fe-bc75-617bea86a115', '88154e0e-2d64-3579-8ad0-24e616b505e6', 'Est voluptas voluptatem distinctio inventore.', 'umum', 25386, 20),
('358f0112-fd4e-3c47-ae9e-d97f4c8af1ac', 'b5452664-62ff-3ffe-821b-bc82d50a49f5', 'Laboriosam sed et qui nostrum.', 'umum', 23137, 13),
('36b73135-7390-3aef-879f-65f26a73448f', 'b7ddc3b4-2ce6-305f-bc24-5fd7cadfcd69', 'Est voluptas voluptatem distinctio inventore.', 'umum', 25386, 2),
('37e01ffd-4fa6-3afe-be7f-6fa529bfae1b', 'be8c2ab5-8ac7-3471-8ba3-22b9401d1dee', 'Ipsum qui et ut veniam libero.', 'umum', 41988, 16),
('39e6c93c-45bc-3b87-ba5e-23eadf9e8f05', '3dcf4b74-aa5e-38ec-a86d-109b17ecfb70', 'Atque eos animi optio est quae officiis ad earum.', 'umum', 96869, 6),
('3b8268d8-6946-3211-a1cf-ab7b1f752565', '57f16ced-8820-3343-950a-4306d8d084de', 'Culpa error et ratione cumque assumenda.', 'umum', 56902, 20),
('3c3467c6-7242-3558-86d5-7d89438fb5cf', '3f4d0c10-fcdb-3e29-bd36-0b150b76860a', 'Nihil laudantium officia commodi et.', 'umum', 20052, 8),
('40fde1cb-d3da-39a9-82a5-840b86aa50bb', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Culpa error et ratione cumque assumenda.', 'umum', 56902, 8),
('42e3369d-8870-399a-a301-52874edcb6ac', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Nihil ullam esse nemo natus quas ducimus.', 'umum', 12741, 19),
('437bb867-10ed-31d0-9108-170bdb6a1b43', 'dd6c5bff-4a4d-3c86-b83f-f756ecfd77b6', 'Sit est cumque repellendus repudiandae.', 'umum', 29070, 20),
('44cee517-b64a-361e-a0da-80ec4fbf2beb', '62c09244-e01e-3a81-9802-2f47ec7229ad', 'Voluptatem necessitatibus a quia rerum.', 'umum', 13496, 12),
('4841866c-21a3-3dda-9ef3-e1f020945aed', '57f16ced-8820-3343-950a-4306d8d084de', 'Sit est cumque repellendus repudiandae.', 'umum', 29070, 5),
('4877c34c-9778-3463-aba7-2f9f3167d984', 'f93f0435-8e4d-31fb-9c97-17396dd7d630', 'Quasi exercitationem sed accusamus quod.', 'umum', 17607, 17),
('493103d3-a91b-3517-9bd2-4673be01b3ef', '57f16ced-8820-3343-950a-4306d8d084de', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 15),
('4c0472d3-c3ec-33ac-bebc-a547f813f20f', '0f2432f2-09c1-3b6f-aa30-ae87f64dd053', 'Est voluptas voluptatem distinctio inventore.', 'umum', 25386, 13),
('4f836a1e-ce96-3f9f-b431-598979671213', 'ef128db1-355b-3549-a2e9-d0b02f5e1aad', 'Sit blanditiis omnis molestiae quae.', 'umum', 38620, 11),
('4ffe6b25-02c2-37f9-9e37-a92849a9866d', 'ed0b5c52-40e3-38d2-98ed-989dcb9d8313', 'Aliquid qui atque iste sed quod excepturi porro.', 'umum', 92440, 15),
('5125c284-c772-33d7-8da0-de2e68886d86', 'cd569301-f8ac-3c0f-b418-65b2035cd60c', 'Sint error tempora architecto dolor id non a.', 'umum', 15212, 20),
('512f54df-d60d-35d6-922e-b0257f0ab499', 'c10a1f6f-fe4e-3b72-af38-48871db80528', 'Sed non molestiae sunt tempora eaque.', 'umum', 44639, 5),
('53fff52c-e5a0-3518-acea-2c21aeb25979', '62c09244-e01e-3a81-9802-2f47ec7229ad', 'Nihil laudantium officia commodi et.', 'umum', 20052, 17),
('5553aa07-4246-3c2c-929b-1f3dc86b64aa', 'be8c2ab5-8ac7-3471-8ba3-22b9401d1dee', 'Aut corporis enim temporibus id voluptas.', 'umum', 28709, 15),
('58548234-1570-3ccf-97c2-9abe9d0f0edc', '90473284-b1c2-38df-b6c9-77bc1b85a350', 'Est voluptas voluptatem distinctio inventore.', 'umum', 25386, 14),
('58f3ac59-16fe-3962-913e-507b4b3c2566', 'b24236e0-1d81-37f5-9513-ee7f30b6eead', 'Dolores esse non sequi vel et.', 'umum', 73170, 20),
('59ef371e-895f-3ea9-8bb9-1c99b1ec3e8b', '9bbc7213-fa32-3b35-b626-ae2f002bb59e', 'Saepe facere ut excepturi iure.', 'umum', 1136, 18),
('5a25a648-b3ab-3eef-9d5f-24bd375e833c', 'ef128db1-355b-3549-a2e9-d0b02f5e1aad', 'Animi voluptatem et doloremque dolorum culpa.', 'umum', 3867, 14),
('5aad09ae-863f-398f-96e3-a89670be0756', '62c09244-e01e-3a81-9802-2f47ec7229ad', 'Quisquam facere provident alias excepturi.', 'umum', 85825, 18),
('5cf54914-567e-3339-abac-c5614d044483', 'b24236e0-1d81-37f5-9513-ee7f30b6eead', 'Odio ut nihil molestiae fuga.', 'umum', 37419, 17),
('5d48031a-7151-3f8e-9b06-117b286c3e8f', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Quae aut ea quasi ut molestias.', 'umum', 67168, 6),
('5d8dd2df-d010-32c0-a8f1-57e130744dc6', 'c10a1f6f-fe4e-3b72-af38-48871db80528', 'Nihil laudantium officia commodi et.', 'umum', 20052, 15),
('6018f156-e6de-3485-a918-7d37da6862a0', 'b003cee8-637b-3205-a72d-e7eb040fff76', 'Dolor illum nobis et molestias sit non sint.', 'umum', 20899, 4),
('6275bf4b-5034-3257-ad3c-c5124c00112d', '0cee2e0a-750b-3b79-bdd6-2e7cf090f946', 'Est voluptas voluptatem distinctio inventore.', 'umum', 25386, 16),
('631b5330-bc19-38db-a994-8dc511b97a12', '1687b8ba-52bf-3f4e-93a8-ef93fd5d535b', 'Nihil ullam esse nemo natus quas ducimus.', 'umum', 12741, 17),
('6397e1a4-e883-36fd-b9e7-c6991df7a391', 'c10a1f6f-fe4e-3b72-af38-48871db80528', 'Aut corporis enim temporibus id voluptas.', 'umum', 28709, 20),
('6413f24c-9f60-36d7-b7d4-f8b6c3a01b2e', '88154e0e-2d64-3579-8ad0-24e616b505e6', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 8),
('6471998d-4a98-31af-bc4b-6eb015a5379a', 'b003cee8-637b-3205-a72d-e7eb040fff76', 'Animi voluptatem et doloremque dolorum culpa.', 'umum', 3867, 15),
('64d34e78-58f6-3a56-b8be-7d5340eb673a', 'cd569301-f8ac-3c0f-b418-65b2035cd60c', 'Modi aut natus nobis vitae exercitationem rem.', 'umum', 2575, 9),
('656277f8-acef-3f3b-a594-0cec06b7b599', 'f93f0435-8e4d-31fb-9c97-17396dd7d630', 'Dolores esse non sequi vel et.', 'umum', 73170, 11),
('67edd5cb-dee8-39e9-bad7-b39534f2940f', 'f6b2c8ef-ca30-37c1-9dee-5ed282afaf18', 'Modi aut natus nobis vitae exercitationem rem.', 'umum', 2575, 19),
('695878f2-27aa-3bc2-a189-1c50ccf8cde8', 'f6b2c8ef-ca30-37c1-9dee-5ed282afaf18', 'Quidem error quis blanditiis.', 'umum', 9050, 18),
('6ad1366d-573a-3fd4-8628-26a146525920', '8464bcc8-1668-39ae-8e71-dbbbfc86642f', 'Modi aut natus nobis vitae exercitationem rem.', 'umum', 2575, 12),
('6d6381b2-7fc3-3347-8ff8-9961873b49c6', 'b7ddc3b4-2ce6-305f-bc24-5fd7cadfcd69', 'Quisquam facere provident alias excepturi.', 'umum', 85825, 13),
('6e6c6d75-677b-3c5c-86ca-fcd2f65a330e', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Culpa error et ratione cumque assumenda.', 'umum', 56902, 2),
('713749ff-2868-3045-97e2-00199476e327', 'ba71c34b-bb97-35b9-9e62-c9605e374dab', 'Atque eos animi optio est quae officiis ad earum.', 'umum', 96869, 17),
('729acbe6-7721-307e-a366-c33c0c5dc632', '66574338-a84f-39ec-bd12-14aa813018cb', 'Quae aut ea quasi ut molestias.', 'umum', 67168, 11),
('742bc73a-984a-352a-a973-c38addbedab5', 'ba7a22b3-53da-3259-aff9-f4c1c6eec2b7', 'Eos eveniet totam sequi nemo.', 'umum', 83376, 19),
('74aec77f-0323-3442-a0ba-73c9dd339206', 'b24236e0-1d81-37f5-9513-ee7f30b6eead', 'Dolor illum nobis et molestias sit non sint.', 'umum', 20899, 5),
('75f0da19-4891-32b7-9999-5c40515cc1d8', '06533a7f-eb5f-3c78-8ceb-da328715b04a', 'Enim hic et unde ab nulla.', 'umum', 91067, 11),
('77c6b7a8-85af-3ebb-ba1e-aeae56823d54', '66574338-a84f-39ec-bd12-14aa813018cb', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 1),
('78710c18-b1ae-333e-bdb7-a324aa536295', 'ef128db1-355b-3549-a2e9-d0b02f5e1aad', 'Occaecati est sit quo eius magni.', 'umum', 52776, 19),
('7a291133-73da-325b-ac47-911b212dc94e', 'bafbf8b8-f9f8-35cf-a9e6-13d794a591a0', 'Ipsum qui et ut veniam libero.', 'umum', 41988, 4),
('7cf506f8-e6b6-3e06-b1b1-6aa216285389', 'bafbf8b8-f9f8-35cf-a9e6-13d794a591a0', 'Quisquam facere provident alias excepturi.', 'umum', 85825, 15),
('7e77fdfa-3ef5-3490-9461-c2a7f91e5e2e', 'dd6c5bff-4a4d-3c86-b83f-f756ecfd77b6', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 17),
('7f4adf98-f69b-317c-aa14-4baa99e661ca', '66574338-a84f-39ec-bd12-14aa813018cb', 'Animi voluptatem et doloremque dolorum culpa.', 'umum', 3867, 16),
('8102592b-fbf1-3952-8619-66442bdeb9c0', 'b7ddc3b4-2ce6-305f-bc24-5fd7cadfcd69', 'Eos eveniet totam sequi nemo.', 'umum', 83376, 9),
('83e38809-e670-3ccf-ab5b-d0b1a64ead83', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Enim hic et unde ab nulla.', 'umum', 91067, 5),
('882f9ff2-e39e-3674-a3b7-336251d1d109', 'ba7a22b3-53da-3259-aff9-f4c1c6eec2b7', 'Fugit voluptatem cum et et facere est.', 'umum', 7808, 16),
('8892a5b9-dab2-3314-8e85-4ff994b061cb', '3dcf4b74-aa5e-38ec-a86d-109b17ecfb70', 'Laboriosam sed et qui nostrum.', 'umum', 23137, 6),
('8a03fed7-4a00-3b1c-9dc7-d36792cda747', 'b0685476-8d03-330d-84ba-890e0af0d3f7', 'Nihil laudantium officia commodi et.', 'umum', 20052, 19),
('8ab53e37-761f-3a10-92f8-fa8676591d7d', '734c3bb9-df08-319d-add5-f59a966d7085', 'Deleniti cupiditate dolor maxime dicta qui.', 'umum', 7849, 14),
('8be996e1-ea1f-3037-9310-75d6cb9bcea2', '9bbc7213-fa32-3b35-b626-ae2f002bb59e', 'Sit nihil explicabo veritatis fugit omnis.', 'umum', 28630, 18),
('8cd3b643-394e-3602-a85b-d52c8469f36b', '66574338-a84f-39ec-bd12-14aa813018cb', 'Asperiores molestiae ab soluta unde unde.', 'umum', 99428, 2),
('8d23a055-5e12-3928-9fbf-d16a564e8eef', '66574338-a84f-39ec-bd12-14aa813018cb', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 18),
('8e16850d-e108-3f82-84fb-8dc5fe26008c', '88154e0e-2d64-3579-8ad0-24e616b505e6', 'Laboriosam sed et qui nostrum.', 'umum', 23137, 9),
('8f032cf5-b748-3de6-a774-a85cd85c4125', 'ba7a22b3-53da-3259-aff9-f4c1c6eec2b7', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 12),
('8f96b4c7-0849-3c75-826a-9b0d88acbc83', '734c3bb9-df08-319d-add5-f59a966d7085', 'Enim hic et unde ab nulla.', 'umum', 91067, 10),
('8fa924c5-4e7c-3bac-b92d-b6f4eacf16f5', 'dd6c5bff-4a4d-3c86-b83f-f756ecfd77b6', 'Aliquid qui atque iste sed quod excepturi porro.', 'umum', 92440, 14),
('903d9a54-6f87-3f11-b4b9-8b3c1c7ea89d', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Laboriosam sed et qui nostrum.', 'umum', 23137, 15),
('91f205c8-68f2-3858-aa9d-2795a42444d5', 'b7ddc3b4-2ce6-305f-bc24-5fd7cadfcd69', 'Deleniti cupiditate dolor maxime dicta qui.', 'umum', 7849, 13),
('941e5faa-e437-345b-b1dc-0bd497841426', '8464bcc8-1668-39ae-8e71-dbbbfc86642f', 'Laboriosam sed et qui nostrum.', 'umum', 23137, 4),
('9900b068-8662-3b6f-9815-9a8b4a40f08c', '8d2fda91-e710-390a-a269-863220b595d1', 'Ut soluta dolore at facilis qui et nulla.', 'umum', 85339, 14),
('995f47cd-9276-3f61-89f8-ce29a6112f21', 'd1a2bf7a-ddcb-3671-b1ad-e17e2ce6f70b', 'Quis rerum blanditiis a earum.', 'umum', 35833, 10),
('9e2973f1-5430-3122-8dfa-5554caa7ce81', '9bbc7213-fa32-3b35-b626-ae2f002bb59e', 'Atque eos animi optio est quae officiis ad earum.', 'umum', 96869, 7),
('9fe97e94-251d-35c4-ac05-9e6e18583de1', '06533a7f-eb5f-3c78-8ceb-da328715b04a', 'Est voluptas voluptatem distinctio inventore.', 'umum', 25386, 13),
('a00a4222-8ed8-3ad9-83a1-6c9a52f45952', 'a46db931-b106-32d1-b79a-626dd9c31946', 'Sed non molestiae sunt tempora eaque.', 'umum', 44639, 6),
('a0713f1d-1fe5-3321-b2ba-6c965d1ad9ce', 'bafbf8b8-f9f8-35cf-a9e6-13d794a591a0', 'Asperiores molestiae ab soluta unde unde.', 'umum', 99428, 6),
('a1762d46-1bcd-378d-bbe2-d41fa65df919', 'cd569301-f8ac-3c0f-b418-65b2035cd60c', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 1),
('a2ba6710-7f1c-3065-8da3-7298c90ac6a5', 'b003cee8-637b-3205-a72d-e7eb040fff76', 'Quisquam facere provident alias excepturi.', 'umum', 85825, 10),
('a324a0e0-a715-396d-a938-afcfb3a4c409', '6298084c-fd96-3834-9df6-ee6d2be91359', 'Enim hic et unde ab nulla.', 'umum', 91067, 19),
('a432bfc5-3c8d-3930-b58f-66211cf24d96', 'b7ddc3b4-2ce6-305f-bc24-5fd7cadfcd69', 'Fugit voluptatem cum et et facere est.', 'umum', 7808, 1),
('a57c1562-2369-3b16-829a-db1325a0774d', '99641d34-fb42-3d3d-a318-33a2f32f24a1', 'Animi voluptatem et doloremque dolorum culpa.', 'umum', 3867, 13),
('a6123e91-ceb5-31dd-99e4-249a41fcbb82', '0f2432f2-09c1-3b6f-aa30-ae87f64dd053', 'Laboriosam sed et qui nostrum.', 'umum', 23137, 5),
('aad3fdd2-d67c-3fb2-bb13-708fa63f8945', 'b0685476-8d03-330d-84ba-890e0af0d3f7', 'Sed non molestiae sunt tempora eaque.', 'umum', 44639, 1),
('abec8549-5021-360f-b590-11a8958e7915', 'b0685476-8d03-330d-84ba-890e0af0d3f7', 'Aut corporis enim temporibus id voluptas.', 'umum', 28709, 12),
('ac80730d-1649-3357-84a2-741445e52790', '734c3bb9-df08-319d-add5-f59a966d7085', 'Quis rerum blanditiis a earum.', 'umum', 35833, 16),
('adf69065-1b3a-3d5d-ab6d-2b412bf2148d', 'b003cee8-637b-3205-a72d-e7eb040fff76', 'Nihil ullam esse nemo natus quas ducimus.', 'umum', 12741, 6),
('ae691803-8b8c-3ee6-8692-cec900763bd8', '8464bcc8-1668-39ae-8e71-dbbbfc86642f', 'Aliquid qui atque iste sed quod excepturi porro.', 'umum', 92440, 11),
('b077d3fa-d4bf-3740-86df-d8830bf685ab', '8464bcc8-1668-39ae-8e71-dbbbfc86642f', 'Aut corporis enim temporibus id voluptas.', 'umum', 28709, 2),
('b23e2c72-dc9b-3eb8-9d18-8511735102a6', '66574338-a84f-39ec-bd12-14aa813018cb', 'Enim hic et unde ab nulla.', 'umum', 91067, 3),
('b4bfed7c-9251-3d1c-8e17-fc163647597c', '2d91b66b-8594-35ba-8e87-b595eec6b510', 'Fugit voluptatem cum et et facere est.', 'umum', 7808, 18),
('b5e6fba2-87aa-3e16-ba1d-782e145cb50d', 'c10a1f6f-fe4e-3b72-af38-48871db80528', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 17),
('b614089c-2905-340d-911c-b1256f93346d', '57f16ced-8820-3343-950a-4306d8d084de', 'Sed non molestiae sunt tempora eaque.', 'umum', 44639, 3),
('b69434a0-a038-3999-aadf-7b5efbc27e2b', '87a56ca2-017b-37ce-8ec2-59f129f62b0f', 'Sed non molestiae sunt tempora eaque.', 'umum', 44639, 2),
('ba1dfaf1-4b1c-3b37-a673-c3b77112183a', '3dcf4b74-aa5e-38ec-a86d-109b17ecfb70', 'Dolor illum nobis et molestias sit non sint.', 'umum', 20899, 20),
('ba54efb1-de4f-3ffc-8fc2-1fa562deccad', '8464bcc8-1668-39ae-8e71-dbbbfc86642f', 'Ut soluta dolore at facilis qui et nulla.', 'umum', 85339, 8),
('c26fa945-3150-3cfa-a200-19463a54da8c', '99641d34-fb42-3d3d-a318-33a2f32f24a1', 'Saepe facere ut excepturi iure.', 'umum', 1136, 4),
('c2a859f2-21d3-3858-8deb-977d9e3faaa6', 'dd6c5bff-4a4d-3c86-b83f-f756ecfd77b6', 'Beatae excepturi et quia eum sit voluptatum et.', 'umum', 79802, 15),
('c2d62207-b67b-371c-83e2-5f73efcbf6c5', 'ed0b5c52-40e3-38d2-98ed-989dcb9d8313', 'Est voluptas voluptatem distinctio inventore.', 'umum', 25386, 7),
('c47f4254-9917-39a5-8299-46e7162142fb', 'b5452664-62ff-3ffe-821b-bc82d50a49f5', 'Ut soluta dolore at facilis qui et nulla.', 'umum', 85339, 7),
('c49d99bd-ea14-328d-a32e-2a4b2291604a', '88154e0e-2d64-3579-8ad0-24e616b505e6', 'Nihil ullam esse nemo natus quas ducimus.', 'umum', 12741, 18),
('c4bfa280-803b-316b-994d-015dd4e9a881', 'ba7a22b3-53da-3259-aff9-f4c1c6eec2b7', 'Voluptatem necessitatibus a quia rerum.', 'umum', 13496, 5),
('c61fc28c-7d4f-341a-9977-8e2b1da044b9', '90473284-b1c2-38df-b6c9-77bc1b85a350', 'Quasi exercitationem sed accusamus quod.', 'umum', 17607, 3),
('c64499a7-87e9-3072-a6fb-700fae834da2', '9bbc7213-fa32-3b35-b626-ae2f002bb59e', 'Enim hic et unde ab nulla.', 'umum', 91067, 7),
('c6465958-7b1c-3036-a0d9-84d9218ab881', 'f93f0435-8e4d-31fb-9c97-17396dd7d630', 'Minus quidem suscipit expedita totam ut dolores.', 'umum', 32376, 10),
('c84fdbf2-67aa-3c84-8d7b-677e8c73078d', '8b787d38-7724-34a2-a409-45d3b5b9c8c7', 'Beatae excepturi et quia eum sit voluptatum et.', 'umum', 79802, 12),
('cb71b544-c681-3ed7-83f0-e8eb0c02b6f6', 'ceee3306-8952-3bd0-b901-ac260bc46091', 'Quia quasi minima autem quis ratione nemo.', 'umum', 90404, 11),
('cbd87e7c-02f8-3302-ab85-e5cfe13b16e9', 'ceee3306-8952-3bd0-b901-ac260bc46091', 'Quasi exercitationem sed accusamus quod.', 'umum', 17607, 5),
('ceb965c7-e618-3a92-9ecd-24dfd1cd9b96', '06533a7f-eb5f-3c78-8ceb-da328715b04a', 'Occaecati est sit quo eius magni.', 'umum', 52776, 2),
('cfa87542-9d59-349a-8a59-c9d6a1502eae', 'cd569301-f8ac-3c0f-b418-65b2035cd60c', 'Occaecati est sit quo eius magni.', 'umum', 52776, 14),
('d374e037-680a-31cc-93c0-033651a4c414', '06533a7f-eb5f-3c78-8ceb-da328715b04a', 'Nihil ullam esse nemo natus quas ducimus.', 'umum', 12741, 12),
('d40f22f3-628b-37b6-8e58-24254451c1a3', '0cee2e0a-750b-3b79-bdd6-2e7cf090f946', 'Sit nihil explicabo veritatis fugit omnis.', 'umum', 28630, 1),
('d4484698-b45f-3b3c-8d14-02f2ba836f89', '8b787d38-7724-34a2-a409-45d3b5b9c8c7', 'Animi qui odit quis nulla.', 'umum', 44981, 15),
('d44dd883-e0ba-32a8-8d30-01466879fbf4', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Est quo sit provident earum qui.', 'umum', 92977, 3),
('d6619bb6-9a35-3473-904d-ec450bdffe9c', '1687b8ba-52bf-3f4e-93a8-ef93fd5d535b', 'Modi aut natus nobis vitae exercitationem rem.', 'umum', 2575, 15),
('d76f9841-0387-32ce-8be3-0386a093fe07', '87a56ca2-017b-37ce-8ec2-59f129f62b0f', 'Quidem error quis blanditiis.', 'umum', 9050, 10),
('da46150b-416a-37d8-8b5d-81b6fcc27531', '90473284-b1c2-38df-b6c9-77bc1b85a350', 'Nihil ullam esse nemo natus quas ducimus.', 'umum', 12741, 3),
('dc2b62d3-40e1-3cda-920a-e2ddacca4d1e', '3f4d0c10-fcdb-3e29-bd36-0b150b76860a', 'Sed non molestiae sunt tempora eaque.', 'umum', 44639, 15),
('df5c7214-f060-3ceb-a6ab-6415466f5d7a', '57f16ced-8820-3343-950a-4306d8d084de', 'Odio ut nihil molestiae fuga.', 'umum', 37419, 5),
('e0170427-8c5b-3db6-972e-d178ea37af99', 'ba71c34b-bb97-35b9-9e62-c9605e374dab', 'Aliquid qui atque iste sed quod excepturi porro.', 'umum', 92440, 20),
('e29d7858-f4c4-3674-86bb-dc2663dfe81d', '61766a6b-cb12-3840-9392-9ba29a98626d', 'Atque eos animi optio est quae officiis ad earum.', 'umum', 96869, 7),
('e3b893f7-25d1-3a38-9a58-9ccfb7b92825', 'f6b2c8ef-ca30-37c1-9dee-5ed282afaf18', 'Occaecati est sit quo eius magni.', 'umum', 52776, 4),
('e3d0a604-43ce-3620-a5db-bd7267a15569', '8464bcc8-1668-39ae-8e71-dbbbfc86642f', 'Quis rerum blanditiis a earum.', 'umum', 35833, 16),
('e6dc853c-33c7-3109-8863-5c74c9fcb16c', '0f2432f2-09c1-3b6f-aa30-ae87f64dd053', 'Beatae excepturi et quia eum sit voluptatum et.', 'umum', 79802, 7),
('e77de3be-139a-330f-ac4b-990fece22b3f', '1687b8ba-52bf-3f4e-93a8-ef93fd5d535b', 'Nihil laudantium officia commodi et.', 'umum', 20052, 17),
('e94064a7-2104-3473-8da7-f84c5430214b', '62c09244-e01e-3a81-9802-2f47ec7229ad', 'Laboriosam sed et qui nostrum.', 'umum', 23137, 16),
('ea37f749-ee50-3170-82dd-0beca88ff42f', 'b24236e0-1d81-37f5-9513-ee7f30b6eead', 'Minus quidem suscipit expedita totam ut dolores.', 'umum', 32376, 10),
('ea4404d1-407c-3e7c-b718-e874d202383f', 'b7ddc3b4-2ce6-305f-bc24-5fd7cadfcd69', 'Est quo sit provident earum qui.', 'umum', 92977, 8),
('ead880c6-415b-3396-a4ba-09c7eb40b9e5', '3dcf4b74-aa5e-38ec-a86d-109b17ecfb70', 'Enim hic et unde ab nulla.', 'umum', 91067, 14),
('ecd945a1-3051-38de-8086-dfa0e1f98506', 'f93f0435-8e4d-31fb-9c97-17396dd7d630', 'Sit blanditiis omnis molestiae quae.', 'umum', 38620, 15),
('ef6626a8-df97-3352-9273-aece0d395d94', '9bbc7213-fa32-3b35-b626-ae2f002bb59e', 'Culpa error et ratione cumque assumenda.', 'umum', 56902, 19),
('efcfbfc3-1b82-35e4-8a48-423180a7ae51', '8d2fda91-e710-390a-a269-863220b595d1', 'Culpa error et ratione cumque assumenda.', 'umum', 56902, 2),
('f1cf2026-c944-3545-9552-730c665e6ce8', '88154e0e-2d64-3579-8ad0-24e616b505e6', 'Ipsum qui et ut veniam libero.', 'umum', 41988, 4),
('f3268aa5-26d7-3fb1-ac3b-fae9a783d132', '62c09244-e01e-3a81-9802-2f47ec7229ad', 'Beatae excepturi et quia eum sit voluptatum et.', 'umum', 79802, 20),
('f3d2ba33-f05d-3b7c-8ef7-39fa31781dc9', 'b24236e0-1d81-37f5-9513-ee7f30b6eead', 'Fugit voluptatem cum et et facere est.', 'umum', 7808, 7),
('f44f1fa9-d4ee-39bb-a8a5-bd1b964ab1f3', 'a46db931-b106-32d1-b79a-626dd9c31946', 'Fugit voluptatem cum et et facere est.', 'umum', 7808, 18),
('f8242cae-386a-3c5a-9fce-62a577df67f3', '0cee2e0a-750b-3b79-bdd6-2e7cf090f946', 'Asperiores molestiae ab soluta unde unde.', 'umum', 99428, 6),
('ff404fef-3e90-3699-b548-581a75e424ef', '90473284-b1c2-38df-b6c9-77bc1b85a350', 'Minus quidem suscipit expedita totam ut dolores.', 'umum', 32376, 9),
('ff7375de-8459-321a-a8de-f0db57f65b26', 'ef128db1-355b-3549-a2e9-d0b02f5e1aad', 'Quis rerum blanditiis a earum.', 'umum', 35833, 9);

-- --------------------------------------------------------

--
-- Struktur dari tabel `suppliers`
--

CREATE TABLE `suppliers` (
  `supplier_id` char(36) NOT NULL,
  `supplier` varchar(255) NOT NULL,
  `supplier_address` varchar(150) NOT NULL,
  `supplier_phone` varchar(14) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `suppliers`
--

INSERT INTO `suppliers` (`supplier_id`, `supplier`, `supplier_address`, `supplier_phone`) VALUES
('25b30e61-8287-3c07-bc6a-b13a5dfb1707', 'Global Mitra Prima', 'Jl. Budi Luhur No. 196 Medan - 20123', '(061)8444555'),
('38a67053-741e-38fd-a7ea-235857760165', 'Menara Abadi Sentosa', 'Jl. Pancing No.20, Kenangan Baru, Kec. Percut Sei Tuan, Medan, Sumatera Utara 20371', '(061)7332182'),
('430f8245-0948-3d3f-a058-0090e7a5076f', 'Merapi Utama', 'Jl. Tapian Nauli, Pasar 1 No. 5, Sunggal, Kec. Medan Sunggal, Kota Medan, Sumatera Utara 20133', '(061)8449505'),
('5349f59e-d1c8-30a6-a080-a70da8d67cbe', 'Bina San Prima', 'Jl. Gatot Subroto KM 5,5 No. 210AB Kel. Sei Sikambing CII Kec. Medan Helvetia 20123', '(061)8443113'),
('a6c9b5ef-5e4a-3671-a0f2-74a21e9bf3c5', 'Mekada Abadi', 'Jl. Kapten Muslim No.235, Helvetia Tengah, Kec. Medan Helvetia, Kota Medan, Sumatera Utara 20124', '(061)8471900'),
('cfde7cd4-3d33-3b72-b7b2-badfddde4b6e', 'Mensa Binasukses', 'Jl. Tempua No.36, Sei Sikambing B, Kec. Medan Sunggal, Kota Medan, Sumatera Utara 20122', '(061)42008266'),
('feb86d29-dcff-380b-b55c-c4ffbc9b946d', 'Antarmitra Sembada', 'Jl. Asoka No. 95/97 Kelurahan Asam Kumbang, Kecamatan Medan 20122', '(061)80015580');

-- --------------------------------------------------------

--
-- Struktur dari tabel `units`
--

CREATE TABLE `units` (
  `unit_id` char(36) NOT NULL,
  `unit` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `units`
--

INSERT INTO `units` (`unit_id`, `unit`) VALUES
('49692d4b-f5ab-37af-9e93-54c932e0917c', 'Ampul'),
('762e69a6-cf92-3dc1-9543-fd178e7aa96b', 'Botol'),
('36742a49-bdb0-34ae-8e70-0e220078cc61', 'Kotak'),
('debe1171-514e-3007-9da5-cd8f308cb294', 'Pot'),
('75956a1a-c277-39bd-999f-d8bfe783759a', 'Sachet'),
('8a633afa-c9f4-34c8-aca6-d8f42916c443', 'Strip'),
('f2022abe-4fa3-36c7-b3a4-2d08d3346989', 'Tube');

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

CREATE TABLE `users` (
  `user_id` char(36) NOT NULL,
  `username` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `google_id` varchar(255) DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('owner','cashier','user') NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `users`
--

INSERT INTO `users` (`user_id`, `username`, `email`, `google_id`, `email_verified_at`, `password`, `role`, `created_at`, `updated_at`, `remember_token`) VALUES
('1de85640-defd-4a3e-bfe3-16a25114a9e1', 'afidyoga', 'afidyoga45dr@gmail.com', NULL, '2025-02-18 08:52:32', '$2y$10$hYCzQXvg/FYxUUJ0gHlAtuBcNMVJsy2CE7nW3YFiEWe.DWIR8z40.', 'user', '2025-02-18 08:51:51', '2025-02-18 08:52:32', NULL),
('4caad2c0-9d73-31cb-a166-ca75c12583cb', 'owner', 'rem@gmail.com', NULL, '2025-02-18 08:48:29', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'owner', '2025-02-18 08:48:29', '2025-02-18 08:48:29', NULL),
('5756b26d-5bb1-3b61-a441-5fa214a7c637', 'dolorem', 'officiis@gmail.com', NULL, '2025-02-18 08:48:28', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', '2025-02-18 08:48:29', '2025-02-18 08:48:29', NULL),
('6f5616cb-9679-329b-ae1c-0373d177860d', 'facere', 'maiores@gmail.com', NULL, '2025-02-18 08:48:28', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', '2025-02-18 08:48:29', '2025-02-18 08:48:29', NULL),
('8170ebb2-f923-3822-adb3-c1a10a9572d6', 'aperiam', 'laboriosam@gmail.com', NULL, '2025-02-18 08:48:28', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', '2025-02-18 08:48:29', '2025-02-18 08:48:29', NULL),
('9995c553-fb5c-35f4-bc50-2f1d608729ff', 'voluptatum', 'aliquid@gmail.com', NULL, '2025-02-18 08:48:27', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', '2025-02-18 08:48:28', '2025-02-18 08:48:28', NULL),
('9cdb41eb-cfd6-3666-b12d-2c3fad6edbd0', 'quibusdam', 'sed@gmail.com', NULL, '2025-02-18 08:48:28', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', '2025-02-18 08:48:28', '2025-02-18 08:48:28', NULL),
('b5112031-4c58-3bd0-9a66-cf12c56949dd', 'architecto', 'autem@gmail.com', NULL, '2025-02-18 08:48:28', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', '2025-02-18 08:48:29', '2025-02-18 08:48:29', NULL),
('dd26224b-5f69-3935-9f43-dbb7a0cd0daf', 'adipisci', 'ducimus@gmail.com', NULL, '2025-02-18 08:48:28', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', '2025-02-18 08:48:29', '2025-02-18 08:48:29', NULL),
('e45b61f5-e663-3dae-9c66-7c04f76dc1ff', 'distinctio', 'minus@gmail.com', NULL, '2025-02-18 08:48:28', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', '2025-02-18 08:48:28', '2025-02-18 08:48:28', NULL),
('ebe44704-9623-3452-b23d-aebffafe6dad', 'kasir1', 'voluptatem@gmail.com', NULL, '2025-02-18 08:48:29', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cashier', '2025-02-18 08:48:29', '2025-02-18 08:48:29', NULL),
('fa61d061-116b-3bd5-a805-1693ae311c3d', 'winzliu', 'sint@gmail.com', NULL, '2025-02-18 08:48:29', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'user', '2025-02-18 08:48:29', '2025-02-18 08:48:29', NULL);

-- --------------------------------------------------------

--
-- Struktur untuk view `bestsellerproduct_view`
--
DROP TABLE IF EXISTS `bestsellerproduct_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bestsellerproduct_view`  AS SELECT `a`.`product_name` AS `product_name`, `b`.`product_status` AS `product_status`, count(0) AS `jumlah_kemunculan` FROM (`selling_invoice_details` `a` join `products` `b` on(`a`.`product_name` = `b`.`product_name`)) GROUP BY `a`.`product_name`, `b`.`product_status` ORDER BY count(0) DESC ;

-- --------------------------------------------------------

--
-- Struktur untuk view `cart_view`
--
DROP TABLE IF EXISTS `cart_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `cart_view`  AS SELECT `a`.`cart_id` AS `cart_id`, `a`.`user_id` AS `user_id`, `b`.`product_id` AS `product_id`, `b`.`product_photo` AS `product_photo`, `b`.`product_name` AS `product_name`, `b`.`category` AS `category`, `b`.`product_type` AS `product_type`, `b`.`product_stock` AS `product_stock`, `b`.`product_expired` AS `product_expired`, `b`.`product_sell_price` AS `product_sell_price`, `a`.`quantity` AS `quantity`, `Total_Harga`(`a`.`quantity`,`b`.`product_sell_price`) AS `total_harga` FROM (`carts` `a` join `product_view` `b` on(`a`.`product_id` = `b`.`product_id`)) ;

-- --------------------------------------------------------

--
-- Struktur untuk view `cashier_view`
--
DROP TABLE IF EXISTS `cashier_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `cashier_view`  AS SELECT `a`.`user_id` AS `user_id`, `a`.`username` AS `username`, `a`.`email` AS `email`, `a`.`password` AS `password`, `a`.`role` AS `role`, `b`.`cashier_phone` AS `cashier_phone`, `b`.`cashier_gender` AS `cashier_gender`, `b`.`cashier_address` AS `cashier_address` FROM (`users` `a` join `cashiers` `b` on(`a`.`user_id` = `b`.`user_id`)) WHERE `a`.`role` = 'cashier' ;

-- --------------------------------------------------------

--
-- Struktur untuk view `customer_view`
--
DROP TABLE IF EXISTS `customer_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `customer_view`  AS SELECT `a`.`user_id` AS `user_id`, `a`.`username` AS `username`, `a`.`email` AS `email`, `a`.`password` AS `password`, `a`.`role` AS `role`, `b`.`customer_phone` AS `customer_phone` FROM (`users` `a` join `customers` `b` on(`a`.`user_id` = `b`.`user_id`)) WHERE `a`.`role` = 'user' ;

-- --------------------------------------------------------

--
-- Struktur untuk view `expired_product_view`
--
DROP TABLE IF EXISTS `expired_product_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `expired_product_view`  AS SELECT `a`.`product_name` AS `product_name`, `d`.`supplier` AS `supplier`, sum(`b`.`product_stock`) AS `product_stock` FROM (((`products` `a` join `product_details` `b` on(`a`.`product_id` = `b`.`product_id`)) join `product_descriptions` `c` on(`a`.`description_id` = `c`.`description_id`)) join `suppliers` `d` on(`d`.`supplier_id` = `c`.`supplier_id`)) WHERE current_timestamp() + interval 3 month >= `b`.`product_expired` GROUP BY `a`.`product_name`, `d`.`supplier` ;

-- --------------------------------------------------------

--
-- Struktur untuk view `last_transaction_view`
--
DROP TABLE IF EXISTS `last_transaction_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `last_transaction_view`  AS SELECT `si`.`order_complete` AS `tanggal_transaksi`, `si`.`invoice_code` AS `invoice_code`, 'Penjualanan' AS `tipe_transaksi`, `si`.`recipient_bank` AS `metode_pembayaran`, (select sum(`Total_Harga`(`sid`.`quantity`,`sid`.`product_sell_price`)) from `selling_invoice_details` `sid` where `sid`.`selling_invoice_id` = `si`.`selling_invoice_id` group by `sid`.`selling_invoice_id`) AS `total_pengeluaran` FROM `selling_invoices` AS `si` WHERE `si`.`order_complete` is not nullunionselect `bi`.`order_date` AS `tanggal_transaksi`,`bi`.`buying_invoice_id` AS `invoice_code`,'Pembelian' AS `tipe_transaksi`,'Tunai' AS `metode_pembayaran`,(select sum(`Total_Harga`(`bid`.`quantity`,`bid`.`product_buy_price`)) from `buying_invoice_details` `bid` where `bid`.`buying_invoice_id` = `bi`.`buying_invoice_id` group by `bid`.`buying_invoice_id`) AS `total_pengeluaran` from `buying_invoices` `bi` order by `tanggal_transaksi` desc  ;

-- --------------------------------------------------------

--
-- Struktur untuk view `product_view`
--
DROP TABLE IF EXISTS `product_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `product_view`  AS SELECT DISTINCT `a`.`product_id` AS `product_id`, `a`.`product_name` AS `product_name`, `a`.`product_status` AS `product_status`, `c`.`category` AS `category`, `d`.`group` AS `group`, `e`.`unit` AS `unit`, `f`.`supplier` AS `supplier`, `b`.`product_type` AS `product_type`, `b`.`product_photo` AS `product_photo`, `b`.`product_manufacture` AS `product_manufacture`, `b`.`product_DPN` AS `product_DPN`, `b`.`product_sideEffect` AS `product_sideEffect`, `b`.`product_description` AS `product_description`, `b`.`product_dosage` AS `product_dosage`, `b`.`product_indication` AS `product_indication`, `b`.`product_notice` AS `product_notice`, (select `g_sub`.`product_expired` from `product_details` `g_sub` where `g_sub`.`product_stock` > 0 and `g_sub`.`product_id` = `a`.`product_id` order by `g_sub`.`product_expired` limit 1) AS `product_expired`, sum(`g`.`product_stock`) AS `product_stock`, (select `g_sub`.`product_buy_price` from `product_details` `g_sub` where `g_sub`.`product_stock` > 0 and `g_sub`.`product_id` = `a`.`product_id` order by `g_sub`.`product_expired` limit 1) AS `product_buy_price`, `a`.`product_sell_price` AS `product_sell_price` FROM ((((((`products` `a` join `product_descriptions` `b` on(`a`.`description_id` = `b`.`description_id`)) join `categories` `c` on(`b`.`category_id` = `c`.`category_id`)) join `groups` `d` on(`b`.`group_id` = `d`.`group_id`)) join `units` `e` on(`b`.`unit_id` = `e`.`unit_id`)) join `suppliers` `f` on(`b`.`supplier_id` = `f`.`supplier_id`)) join `product_details` `g` on(`a`.`product_id` = `g`.`product_id`)) GROUP BY `a`.`product_id`, `a`.`product_name`, `a`.`product_status`, `c`.`category`, `d`.`group`, `e`.`unit`, `f`.`supplier`, `b`.`product_type`, `b`.`product_photo`, `b`.`product_manufacture`, `b`.`product_DPN`, `b`.`product_sideEffect`, `b`.`product_description`, `b`.`product_dosage`, `b`.`product_indication`, `b`.`product_notice`, `a`.`product_sell_price` ;

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `buying_invoices`
--
ALTER TABLE `buying_invoices`
  ADD PRIMARY KEY (`buying_invoice_id`);

--
-- Indeks untuk tabel `buying_invoice_details`
--
ALTER TABLE `buying_invoice_details`
  ADD PRIMARY KEY (`buying_detail_id`),
  ADD KEY `buying_invoice_details_buying_invoice_id_foreign` (`buying_invoice_id`);

--
-- Indeks untuk tabel `carts`
--
ALTER TABLE `carts`
  ADD PRIMARY KEY (`cart_id`),
  ADD KEY `carts_user_id_foreign` (`user_id`),
  ADD KEY `carts_product_id_foreign` (`product_id`);

--
-- Indeks untuk tabel `cashiers`
--
ALTER TABLE `cashiers`
  ADD PRIMARY KEY (`cashier_id`),
  ADD KEY `cashiers_user_id_foreign` (`user_id`);

--
-- Indeks untuk tabel `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `categories_category_unique` (`category`);

--
-- Indeks untuk tabel `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`customer_id`),
  ADD KEY `customers_user_id_foreign` (`user_id`);

--
-- Indeks untuk tabel `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indeks untuk tabel `groups`
--
ALTER TABLE `groups`
  ADD PRIMARY KEY (`group_id`),
  ADD UNIQUE KEY `groups_group_unique` (`group`);

--
-- Indeks untuk tabel `information`
--
ALTER TABLE `information`
  ADD PRIMARY KEY (`information_id`);

--
-- Indeks untuk tabel `logs`
--
ALTER TABLE `logs`
  ADD PRIMARY KEY (`log_id`);

--
-- Indeks untuk tabel `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indeks untuk tabel `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indeks untuk tabel `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`product_id`),
  ADD KEY `products_description_id_foreign` (`description_id`);

--
-- Indeks untuk tabel `product_descriptions`
--
ALTER TABLE `product_descriptions`
  ADD PRIMARY KEY (`description_id`),
  ADD KEY `product_descriptions_category_id_foreign` (`category_id`),
  ADD KEY `product_descriptions_group_id_foreign` (`group_id`),
  ADD KEY `product_descriptions_unit_id_foreign` (`unit_id`),
  ADD KEY `product_descriptions_supplier_id_foreign` (`supplier_id`);

--
-- Indeks untuk tabel `product_details`
--
ALTER TABLE `product_details`
  ADD PRIMARY KEY (`detail_id`),
  ADD KEY `product_details_product_id_foreign` (`product_id`);

--
-- Indeks untuk tabel `selling_invoices`
--
ALTER TABLE `selling_invoices`
  ADD PRIMARY KEY (`selling_invoice_id`),
  ADD UNIQUE KEY `selling_invoices_invoice_code_unique` (`invoice_code`);

--
-- Indeks untuk tabel `selling_invoice_details`
--
ALTER TABLE `selling_invoice_details`
  ADD PRIMARY KEY (`selling_detail_id`),
  ADD KEY `selling_invoice_details_selling_invoice_id_foreign` (`selling_invoice_id`);

--
-- Indeks untuk tabel `suppliers`
--
ALTER TABLE `suppliers`
  ADD PRIMARY KEY (`supplier_id`),
  ADD UNIQUE KEY `suppliers_supplier_unique` (`supplier`);

--
-- Indeks untuk tabel `units`
--
ALTER TABLE `units`
  ADD PRIMARY KEY (`unit_id`),
  ADD UNIQUE KEY `units_unit_unique` (`unit`);

--
-- Indeks untuk tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `users_username_unique` (`username`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD UNIQUE KEY `users_google_id_unique` (`google_id`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=47;

--
-- AUTO_INCREMENT untuk tabel `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `buying_invoice_details`
--
ALTER TABLE `buying_invoice_details`
  ADD CONSTRAINT `buying_invoice_details_buying_invoice_id_foreign` FOREIGN KEY (`buying_invoice_id`) REFERENCES `buying_invoices` (`buying_invoice_id`) ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `carts`
--
ALTER TABLE `carts`
  ADD CONSTRAINT `carts_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `carts_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `cashiers`
--
ALTER TABLE `cashiers`
  ADD CONSTRAINT `cashiers_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `customers`
--
ALTER TABLE `customers`
  ADD CONSTRAINT `customers_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_description_id_foreign` FOREIGN KEY (`description_id`) REFERENCES `product_descriptions` (`description_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `product_descriptions`
--
ALTER TABLE `product_descriptions`
  ADD CONSTRAINT `product_descriptions_category_id_foreign` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_descriptions_group_id_foreign` FOREIGN KEY (`group_id`) REFERENCES `groups` (`group_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_descriptions_supplier_id_foreign` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`supplier_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `product_descriptions_unit_id_foreign` FOREIGN KEY (`unit_id`) REFERENCES `units` (`unit_id`) ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `product_details`
--
ALTER TABLE `product_details`
  ADD CONSTRAINT `product_details_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ketidakleluasaan untuk tabel `selling_invoice_details`
--
ALTER TABLE `selling_invoice_details`
  ADD CONSTRAINT `selling_invoice_details_selling_invoice_id_foreign` FOREIGN KEY (`selling_invoice_id`) REFERENCES `selling_invoices` (`selling_invoice_id`) ON UPDATE CASCADE;

DELIMITER $$
--
-- Event
--
CREATE DEFINER=`root`@`localhost` EVENT `check_expired` ON SCHEDULE EVERY 1 DAY STARTS '2025-02-18 22:48:08' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN 
                CREATE TEMPORARY TABLE IF NOT EXISTS temp_expired_products (product_id_expired char(36)); 
                
                INSERT INTO temp_expired_products (product_id_expired) SELECT product_id FROM product_details WHERE product_expired = CURDATE(); 
                
                UPDATE products SET product_status = 'exp' WHERE product_id IN (SELECT product_id_expired FROM temp_expired_products); 
            END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
