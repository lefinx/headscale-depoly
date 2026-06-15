# headscale-depoly

Headscale + DERP + Tailscale client 的 Docker Compose 部署示例。

## 目录结构

```text
.
├── client/                 # Tailscale 客户端接入示例
├── derp/                   # 自建 DERP 服务
└── headscale/              # Headscale 服务和 Web UI
    ├── config/             # Headscale 配置
    ├── gen_apikes.sh       # 生成 Headscale API key
    └── gen_authkey.sh      # 生成客户端 pre-auth key
```

## 部署前配置

需要先按实际环境替换以下占位值：

- `headscale/config/config.yaml` 里的 `server_url`
- `headscale/config/derp.yaml` 里的 `hostname`
- `derp/docker-compose.yml` 里的 `DERP_DOMAIN`
- `client/docker-compose.yml` 里的 `TS_AUTHKEY` 和 `TS_EXTRA_ARGS`

默认端口：

- Headscale: `58318 -> 8080`
- Headscale UI: `58319 -> 7070`
- DERP: `56060 -> 6060`
- STUN: `3478/udp`

如果外层还有 Nginx、Caddy、Traefik 等反向代理，需要把公网域名转发到对应服务端口，并配置 HTTPS。

## 启动 Headscale

```bash
cd headscale
docker compose up -d
```

查看服务状态：

```bash
docker compose ps
docker logs -f headscale-server
```

创建用户：

```bash
docker exec headscale-server headscale users create default
```

生成 Web UI 使用的 API key：

```bash
./gen_apikes.sh
```

生成客户端接入使用的 pre-auth key：

```bash
./gen_authkey.sh
```

脚本会把结果写入 `api_keys.txt` 和 `authkey.txt`，这两个文件已在 `.gitignore` 中排除，不应提交到仓库。

## 启动 DERP

```bash
cd derp
docker compose up -d --build
```

查看日志：

```bash
docker logs -f headscale-derp
```

如果 DERP 对外使用标准 HTTPS 端口，建议在反向代理中把公网 `443` 转发到 `56060`，并确认 `headscale/config/derp.yaml` 中的 `derpport` 与公网访问端口一致。

## 接入客户端

先把 `client/docker-compose.yml` 中的 `TS_AUTHKEY` 替换为 `gen_authkey.sh` 生成的 pre-auth key，并把 `--login-server` 替换为实际 Headscale 地址。

```bash
cd client
docker compose up -d
```

查看客户端状态：

```bash
docker logs -f tailscale-client
```

## 常用维护命令

停止服务：

```bash
docker compose down
```

更新镜像：

```bash
docker compose pull
docker compose up -d
```

查看 Headscale 节点：

```bash
docker exec headscale-server headscale nodes list
```

## 注意事项

- `headscale/data/`、`headscale/run/`、`client/tailscale-state/` 和 `derp/tailscale/` 是本地运行状态目录，不提交到仓库。
- 当前配置使用 SQLite，数据库文件位于容器内 `/var/lib/headscale/db.sqlite`，对应宿主机 `headscale/data/`。
- `client/docker-compose.yml` 中的 `TS_AUTHKEY=hskey-auth-xxx` 是占位值，部署前必须替换。
- 生产环境建议固定镜像版本，避免 `latest` 在升级时引入不可预期变更。
