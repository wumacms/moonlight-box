-- 月光宝盒 - 按组件类型插入模拟数据（执行前请先执行 schema.sql）
-- 本脚本仅手动执行，应用启动时不会自动执行

USE mbox;

-- ========== 卡片组件 card：文章/卡片 ==========
INSERT INTO content_card (title, subtitle, image_url, badge, content, media_url, extend_info) VALUES
('月光下的设计哲学', '探索极简与留白的平衡', 'https://picsum.photos/400/240?random=1', '推荐', '## 设计哲学\n\n在月光银的基调下，我们追求**极简**与**留白**的平衡。\n\n- 减少视觉噪音\n- 突出核心内容\n- 适配深色模式', 'https://picsum.photos/800/450?random=1', '{"author":"月光编辑部","date":"2024-02-01"}'),
('SwiftUI 动态解析实践', '配置驱动 UI 的落地方案', 'https://picsum.photos/400/240?random=2', '技术', '本文介绍如何通过 **API 配置** 和 **字段映射** 实现列表与详情的动态解析，告别硬编码。', NULL, '{"author":"开发组","category":"iOS"}'),
('产品需求文档导读', '从 PRD 到实现的闭环', 'https://picsum.photos/400/240?random=3', '产品', '从 PRD 到上线，如何保持产品与研发的对齐？本文梳理 **配置即所得** 的协作方式。', NULL, '{"author":"产品组"}');

-- ========== 视频组件 video ==========
INSERT INTO content_video (title, subtitle, image_url, badge, content, media_url, extend_info) VALUES
('月光宝盒功能演示', '列表、详情与配置页全流程', 'https://picsum.photos/400/240?random=4', '视频', '本视频演示首页列表、点击下钻详情、以及配置页的 API 与字段映射设置。', 'https://example.com/demo.mp4', '{"duration":"03:24","resolution":"1080p"}'),
('动态字段映射详解', '如何配置 ui_title 与后端 key', 'https://picsum.photos/400/240?random=5', '教程', '讲解在 APP 内配置 **ui_title**、**ui_subtitle** 等与后端 JSON 键名的对应关系。', 'https://example.com/mapping.mp4', '{"duration":"05:10"}'),
('深色模式与主题', '月光银与深邃蓝的搭配', 'https://picsum.photos/400/240?random=6', '设计', '介绍 AppTheme 中月光银、深邃蓝及圆角 12pt 卡片的视觉规范。', NULL, '{"author":"设计组"}');

-- ========== 图表组件 chart ==========
INSERT INTO content_chart (title, subtitle, image_url, badge, content, media_url, extend_info) VALUES
('近7日活跃用户趋势', '每日 DAU 变化（真实采样模拟）', 'https://picsum.photos/400/240?random=7', '图表', '展示近 7 日活跃用户变化趋势，便于观察增长与波动。', NULL, '{"chartType":"line","period":"7d","unit":"人","chartData":[{"x":"02-11","y":1280},{"x":"02-12","y":1365},{"x":"02-13","y":1422},{"x":"02-14","y":1578},{"x":"02-15","y":1496},{"x":"02-16","y":1683},{"x":"02-17","y":1760}]}'),
('功能模块访问占比', '首页核心模块流量结构', 'https://picsum.photos/400/240?random=8', '统计', '用于评估卡片、视频、图表三类模块的访问占比与资源投入。', NULL, '{"chartType":"pie","period":"today","unit":"%","chartData":[{"x":"card","y":46},{"x":"video","y":31},{"x":"chart","y":23}]}'),
('接口 P99 响应耗时', 'list/detail 接口稳定性监控', 'https://picsum.photos/400/240?random=9', '监控', '按接口名称展示 P99 响应耗时，快速定位性能瓶颈。', NULL, '{"chartType":"bar","period":"24h","unit":"ms","chartData":[{"x":"card-list","y":118},{"x":"card-detail","y":162},{"x":"video-list","y":135},{"x":"video-detail","y":188},{"x":"chart-list","y":142},{"x":"chart-detail","y":205}]}');
