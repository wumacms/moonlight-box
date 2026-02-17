# 月光宝盒后端 (mbox-api)

Spring Boot + Maven + MySQL + MyBatis-Plus，为前端 APP 的 **card / video / chart** 三种组件类型提供列表与详情 API，并预置模拟数据。

## 技术栈

- **Java 17** / **Spring Boot 3.2**
- **Maven**
- **MySQL 8**
- **MyBatis-Plus**

## 接口说明（与前端协议一致）

- **列表**：`GET /api/{card|video|chart}/list` → `{ "code": 200, "data": [ { "id", "title", "subtitle", "imageUrl", "badge" }, ... ] }`
- **详情**：`GET /api/{card|video|chart}/detail?id=xxx` → `{ "code": 200, "data": { "id", "title", "content", "mediaUrl", "extendInfo" } }`

前端默认字段映射：`ui_title`→`title`, `ui_subtitle`→`subtitle`, `ui_image`→`imageUrl`, `ui_id`→`id`, `ui_badge`→`badge`。

## 本地运行

### 1. 创建库表并插入模拟数据（仅手动执行，应用不会自动执行任何 SQL）

SQL 脚本在 **`mbox-api/scripts/`** 下，需自行执行：

```bash
cd mbox-api
mysql -u root -p < scripts/schema.sql
mysql -u root -p < scripts/data-mock.sql
```

或在 MySQL 客户端中依次执行 `scripts/schema.sql`、`scripts/data-mock.sql`。

### 2. 修改数据库账号密码

编辑 `src/main/resources/application.yml`（或 `application-dev.yml`）中的 `spring.datasource.url`（库名）、`username`、`password`。

### 2.1 报错：`Access denied for user 'root'@'192.168.65.1'`

表示 MySQL 只允许 `root@localhost` 登录，当前连接来自本机/Docker 网卡 IP，被拒绝。任选其一即可：

**方式 A：允许 root 从任意主机连接（开发环境常用）**

```bash
mysql -u root -p
```

在 MySQL 里执行（把 `你的密码` 换成 application.yml 里配置的密码）：

```sql
CREATE DATABASE IF NOT EXISTS mbox DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '你的密码';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

**方式 B：只允许当前主机 IP**

把上面 `'root'@'%'` 改成 `'root'@'192.168.65.1'`（错误信息里的 IP）再执行。

### 3. 启动应用

```bash
cd mbox-api
mvn spring-boot:run
```

服务默认端口 **8080**。iOS 模拟器访问列表可配置为：`http://localhost:8080/api/card/list`，详情为 `http://localhost:8080/api/card/detail?id=1`。

## 组件类型与模拟数据

| 组件类型 | 列表 API | 详情 API | 模拟数据说明 |
|---------|----------|----------|----------------|
| **card** | `/api/card/list` | `/api/card/detail?id=` | 3 条文章/卡片，含标题、摘要、图片、badge、正文、extendInfo |
| **video** | `/api/video/list` | `/api/video/detail?id=` | 3 条视频项，含 mediaUrl、时长等 extendInfo |
| **chart** | `/api/chart/list` | `/api/chart/detail?id=` | 3 条图表项，含 chartType、period 等 extendInfo |

在 APP 配置页添加 API 时，可选择组件类型并填写上述 list/detail URL，即可在首页按类型拉取并展示对应模拟数据。
