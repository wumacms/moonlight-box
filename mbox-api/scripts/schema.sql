-- 月光宝盒 - 建表脚本（MySQL 8+）
-- 本脚本仅手动执行，应用启动时不会自动执行
CREATE DATABASE IF NOT EXISTS mbox DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mbox;

-- 卡片组件（文章/卡片）
CREATE TABLE IF NOT EXISTS content_card (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(256) NOT NULL DEFAULT '',
    subtitle    VARCHAR(512) DEFAULT '',
    image_url   VARCHAR(1024) DEFAULT NULL,
    badge       VARCHAR(64) DEFAULT NULL,
    content     TEXT,
    media_url   VARCHAR(1024) DEFAULT NULL,
    extend_info JSON DEFAULT NULL,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 视频组件
CREATE TABLE IF NOT EXISTS content_video (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(256) NOT NULL DEFAULT '',
    subtitle    VARCHAR(512) DEFAULT '',
    image_url   VARCHAR(1024) DEFAULT NULL,
    badge       VARCHAR(64) DEFAULT NULL,
    content     TEXT,
    media_url   VARCHAR(1024) DEFAULT NULL,
    extend_info JSON DEFAULT NULL,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 图表组件
CREATE TABLE IF NOT EXISTS content_chart (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(256) NOT NULL DEFAULT '',
    subtitle    VARCHAR(512) DEFAULT '',
    image_url   VARCHAR(1024) DEFAULT NULL,
    badge       VARCHAR(64) DEFAULT NULL,
    content     TEXT,
    media_url   VARCHAR(1024) DEFAULT NULL,
    extend_info JSON DEFAULT NULL,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
