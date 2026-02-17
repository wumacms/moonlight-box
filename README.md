# 月光宝盒（Moonlight Box）

一个「配置驱动 UI」的全栈示例项目：  
前端使用 SwiftUI + SwiftData，后端使用 Spring Boot + MyBatis-Plus + MySQL。  
你可以在 App 内配置 API 与字段映射，让列表/详情/图表按配置动态渲染。

## 项目结构

```text
moonlight-box/
├─ mbox/          # iOS 客户端（SwiftUI）
├─ mbox-api/      # 后端服务（Spring Boot）
├─ PRD.md         # 产品需求文档
└─ README.md
```

## 核心能力

- 配置 API 数据源（list/detail）并持久化到本地
- 字段映射驱动渲染（避免前端硬编码后端字段名）
- 支持 `card`、`video`、`chart` 三种组件类型
- 首页列表点击后自动携带 `id` 下钻详情
- 图表支持按 `chartType` 渲染折线/饼图/柱状图

## 技术栈

- **iOS**：SwiftUI、SwiftData、Charts
- **Backend**：Java 17、Spring Boot 3.2、MyBatis-Plus、MySQL 8

## 快速开始

### 1) 启动后端 `mbox-api`

先准备数据库与模拟数据：

```bash
cd mbox-api
mysql -u root -p < scripts/schema.sql
mysql -u root -p < scripts/data-mock.sql
```

根据本机环境修改 `mbox-api/src/main/resources/application.yml` 中的数据库连接配置，然后启动：

```bash
cd mbox-api
mvn spring-boot:run
```

默认端口：`8080`

### 2) 启动 iOS 客户端 `mbox`

1. 使用 Xcode 打开 `mbox/mbox.xcodeproj`
2. 选择模拟器并运行
3. 在 App 的「配置页」添加 API 配置并测试解析

## 默认接口（后端）

- 列表：`GET /api/{card|video|chart}/list`
- 详情：`GET /api/{card|video|chart}/detail?id={id}`

示例：

- `http://localhost:8080/api/card/list`
- `http://localhost:8080/api/chart/list`
- `http://localhost:8080/api/chart/detail?id=1`

## 字段映射说明

### 基础映射键

- `ui_title`
- `ui_subtitle`
- `ui_image`
- `ui_id`
- `ui_badge`

### 图表扩展映射键（可选）

- `chart_data`：图表数据数组字段（如 `chartData` / `series`）
- `chart_x`：维度字段（如 `x` / `month`）
- `chart_y`：数值字段（如 `y` / `uv`）

当图表映射键未配置时，前端会做兜底解析；建议线上明确配置以保证稳定性。

## 图表数据格式示例

```json
{
  "id": "1",
  "title": "近7日活跃用户趋势",
  "chartType": "line",
  "period": "7d",
  "unit": "人",
  "chartData": [
    { "x": "02-11", "y": 1280 },
    { "x": "02-12", "y": 1365 }
  ]
}
```

## 常见问题

- **iOS 访问不到本地后端？**  
  确认后端已启动在 `8080`，并检查你在配置页填写的 URL 是否正确。

- **MySQL 报 `Access denied`？**  
  参考 `mbox-api/README.md` 的数据库授权说明，允许当前主机访问。

- **图表类型显示不对？**  
  确认列表响应中包含 `chartType`，并检查 `ui_badge` / `chartType` 映射配置。
