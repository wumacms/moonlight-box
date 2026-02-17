-- 月光宝盒 - 按组件类型插入模拟数据（执行前请先执行 schema.sql）
-- 本脚本仅手动执行，应用启动时不会自动执行

USE mbox;

-- ========== 卡片组件 card：文章/卡片 ==========
INSERT INTO content_card (title, subtitle, image_url, badge, content, media_url, author, pub_date, category) VALUES
('月光下的设计哲学', '探索极简 with 留白的平衡', 'https://picsum.photos/400/240?random=1', '推荐', '## 设计哲学\n\n在月光银的基调下，我们追求**极简**与**留白**的平衡。\n\n- 减少视觉噪音\n- 突出核心内容\n- 适配深色模式', 'https://picsum.photos/800/450?random=1', '月光编辑部', '2024-02-01', '设计'),
('SwiftUI 动态解析实践', '配置驱动 UI 的落地方案', 'https://picsum.photos/400/240?random=2', '技术', '本文介绍如何通过 **API 配置** 和 **字段映射** 实现列表与详情的动态解析，告别硬编码。', NULL, '开发组', '2024-02-15', 'iOS'),
('产品需求文档导读', '从 PRD 到实现的闭环', 'https://picsum.photos/400/240?random=3', '产品', '从 PRD 到上线，如何保持产品与研发的对齐？本文梳理 **配置即所得** 的协作方式。', NULL, '产品组', '2024-02-10', '产品');

-- ========== 视频组件 video ==========
INSERT INTO content_video (title, subtitle, image_url, badge, content, media_url, duration, resolution, author) VALUES
('月光宝盒功能演示', '列表、详情与配置页全流程', 'https://picsum.photos/400/240?random=4', '视频', '本视频演示首页列表、点击下钻详情、以及配置页的 API 与字段映射设置。', 'https://example.com/demo.mp4', '03:24', '1080p', '演示中心'),
('动态字段映射详解', '如何配置 ui_title 与后端 key', 'https://picsum.photos/400/240?random=5', '教程', '讲解在 APP 内配置 **ui_title**、**ui_subtitle** 等与后端 JSON 键名的对应关系。', 'https://example.com/mapping.mp4', '05:10', '720p', '开发组'),
('深色模式与主题', '月光银与深邃蓝的搭配', 'https://picsum.photos/400/240?random=6', '设计', '介绍 AppTheme 中月光银、深邃蓝及圆角 12pt 卡片的视觉规范。', NULL, '12:00', '4K', '设计组');

-- ========== 图表组件 chart ==========
INSERT INTO content_chart (id, title, subtitle, chart_type, period, unit) VALUES
(1, '近7日活跃用户趋势', '每日 DAU 变化（真实采样模拟）', 'line', '7d', '人'),
(2, '功能模块访问占比', '首页核心模块流量结构', 'pie', 'today', '%'),
(3, '接口 P99 响应耗时', 'list/detail 接口稳定性监控', 'bar', '24h', 'ms');

INSERT INTO content_chart_data (chart_id, x_label, y_value, sort_order) VALUES
(1, '02-11', 1280, 1), (1, '02-12', 1365, 2), (1, '02-13', 1422, 3), (1, '02-14', 1578, 4), (1, '02-15', 1496, 5), (1, '02-16', 1683, 6), (1, '02-17', 1760, 7),
(2, 'card', 46, 1), (2, 'video', 31, 2), (2, 'chart', 23, 3),
(3, 'card-list', 118, 1), (3, 'card-detail', 162, 2), (3, 'video-list', 135, 3), (3, 'video-detail', 188, 4), (3, 'chart-list', 142, 5), (3, 'chart-detail', 205, 6);
