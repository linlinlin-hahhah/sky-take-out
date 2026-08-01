#!/bin/bash
# ============================================================
# 苍穹外卖 - GitHub Codespaces 一键环境配置脚本
# 用法：在 Codespaces 终端运行  bash setup.sh
# 作用：自动创建 .devcontainer 配置，Rebuild 后即获得完整开发环境
#   - JDK 8 + Maven（阿里云镜像加速）
#   - MySQL 8.0（自动导入 sky.sql 11张表）
#   - Redis 7
#   - Adminer 数据库可视化（替代 Navicat）
# ============================================================
set -e

echo "🚀 正在为苍穹外卖创建 Codespaces 开发环境配置..."

mkdir -p .devcontainer

# ---------- devcontainer.json ----------
cat > .devcontainer/devcontainer.json << 'DEVCONTAINER_JSON'
{
  "name": "苍穹外卖后端开发环境",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "customizations": {
    "vscode": {
      "extensions": [
        "vscjava.vscode-java-pack",
        "vmware.vscode-boot-dev-pack",
        "redhat.vscode-yaml"
      ]
    }
  },
  "postCreateCommand": "mkdir -p ~/.m2 && cp .devcontainer/maven-settings.xml ~/.m2/settings.xml && java -version && mvn -version",
  "forwardPorts": [8080, 8081, 3306, 6379],
  "remoteEnv": {
    "SKY_DATASOURCE_HOST": "mysql",
    "SKY_DATASOURCE_PORT": "3306",
    "SKY_DATASOURCE_DATABASE": "sky_take_out",
    "SKY_DATASOURCE_USERNAME": "root",
    "SKY_DATASOURCE_PASSWORD": "123456",
    "SKY_REDIS_HOST": "redis",
    "SKY_REDIS_PORT": "6379",
    "SKY_REDIS_DATABASE": "10"
  }
}
DEVCONTAINER_JSON

# ---------- docker-compose.yml ----------
cat > .devcontainer/docker-compose.yml << 'DOCKER_COMPOSE_YML'
services:
  # 开发容器（Codespaces 主容器，自带 JDK 8 + Maven）
  app:
    image: mcr.microsoft.com/devcontainers/java:8
    volumes:
      - ../..:/workspaces:cached
    command: sleep infinity
    depends_on:
      - mysql
      - redis
    environment:
      SKY_DATASOURCE_HOST: mysql
      SKY_DATASOURCE_PORT: "3306"
      SKY_DATASOURCE_DATABASE: sky_take_out
      SKY_DATASOURCE_USERNAME: root
      SKY_DATASOURCE_PASSWORD: "123456"
      SKY_REDIS_HOST: redis
      SKY_REDIS_PORT: "6379"
      SKY_REDIS_DATABASE: "10"

  # MySQL 8.0，首次启动自动导入 sky.sql（11张表）
  mysql:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: "123456"
      MYSQL_DATABASE: sky_take_out
      TZ: Asia/Shanghai
    command: --default-authentication-plugin=mysql_native_password --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
      - ../资料/day01/数据库/sky.sql:/docker-entrypoint-initdb.d/sky.sql:ro

  # Redis 7
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    ports:
      - "6379:6379"

  # Adminer - 网页版数据库可视化工具（替代 Navicat）
  adminer:
    image: adminer:latest
    restart: unless-stopped
    ports:
      - "8081:8080"
    depends_on:
      - mysql

volumes:
  mysql-data:
DOCKER_COMPOSE_YML

# ---------- maven-settings.xml ----------
cat > .devcontainer/maven-settings.xml << 'MAVEN_SETTINGS_XML'
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <name>阿里云公共仓库</name>
      <url>https://maven.aliyun.com/repository/public</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
MAVEN_SETTINGS_XML

echo ""
echo "✅ 配置文件创建完成！已生成："
echo "   .devcontainer/devcontainer.json"
echo "   .devcontainer/docker-compose.yml"
echo "   .devcontainer/maven-settings.xml"
echo ""
echo "📋 接下来请按以下步骤操作："
echo ""
echo "   ① 提交配置到你的 Fork 仓库："
echo "      git add .devcontainer"
echo "      git commit -m \"添加 Codespaces 开发环境配置\""
echo "      git push"
echo ""
echo "   ② 重建容器以应用新配置："
echo "      按 F1 → 输入 Codespaces: Rebuild Container → 回车"
echo "      （或点击左下角绿色按钮 → Rebuild Container）"
echo ""
echo "   ③ 等待重建完成（约 3-5 分钟），环境自动就绪："
echo "      ✓ JDK 8 + Maven（阿里云镜像加速）"
echo "      ✓ MySQL 8.0（已自动导入 sky.sql，11 张表）"
echo "      ✓ Redis 7"
echo "      ✓ Adminer 数据库可视化（端口 8081）"
echo ""
echo "   ④ 启动后端项目："
echo "      cd sky-take-out && mvn spring-boot:run -pl sky-server"
echo ""
echo "   ⑤ 访问地址："
echo "      接口文档：http://localhost:8080/doc.html"
echo "      数据库可视化：http://localhost:8081（系统选 MySQL，服务器填 mysql）"
echo ""
echo "📚 详细说明请查看《苍穹外卖环境搭建说明.md》"
