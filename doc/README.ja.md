# Hokuyo URG Node Humble Docker Environment

[![CI](https://github.com/ycpss91255-docker/urg_node_humble/actions/workflows/main.yaml/badge.svg)](https://github.com/ycpss91255-docker/urg_node_humble/actions/workflows/main.yaml) [![License](https://img.shields.io/badge/License-Apache--2.0-blue?style=flat-square)](../LICENSE)

**[English](../README.md)** | **[繁體中文](README.zh-TW.md)** | **[简体中文](README.zh-CN.md)** | **[日本語](README.ja.md)**

> **TL;DR** — コンテナ化された Hokuyo LiDAR ドライバ、ROS 2 Humble ベース。ソースから `urg_node2` をビルドし、Ethernet および Serial 接続のデフォルトパラメータファイルを同梱。
>
> ```bash
> ./build.sh && ./run.sh
> ```

---

## 目次

- [特徴](#特徴)
- [クイックスタート](#クイックスタート)
- [使い方](#使い方)
- [設定](#設定)
- [アーキテクチャ](#アーキテクチャ)
- [ディレクトリ構成](#ディレクトリ構成)

---

## 特徴

- **ソースからビルド**：[urg_node2](https://github.com/Hokuyo-aut/urg_node2) をクローンしてビルド
- **マルチステージビルド**：builder（コンパイル）→ devel（最小化）、イメージサイズを削減
- **Smoke Test**：Bats テストで ROS 環境、パッケージの可用性、設定ファイルを検証
- **デフォルト設定**：Hokuyo LiDAR の Ethernet・Serial パラメータファイルを同梱
- **Docker Compose**：`compose.yaml` 一つでビルドと実行を管理

## クイックスタート

```bash
# 1. ビルド
./build.sh

# 2. 実行（Hokuyo LiDAR の接続が必要）
./run.sh

# 3. 起動中のコンテナに接続
./exec.sh
```

## 使い方

### ビルド

```bash
./build.sh                       # devel をビルド（デフォルト）
./build.sh test                  # smoke test 付きビルド

docker compose build devel       # 同等のコマンド
```

### 実行

```bash
# デフォルトの launch file で実行
./run.sh

# カスタムコマンド
docker compose run --rm devel ros2 launch urg_node2 urg_node2.launch.py

# 起動中のコンテナに接続
./exec.sh
```

## 設定

### パラメータファイル

`config/` 内：

| ファイル | 接続方式 | 説明 |
|----------|---------|------|
| `params_ether.yaml` | Ethernet | デフォルト IP `192.168.1.10`、port `10940` |
| `params_ether_2nd.yaml` | Ethernet | 2台目の LiDAR、IP `192.168.0.11` |
| `params_serial.yaml` | Serial | `/dev/ttyACM0`、baud `115200` |

### 主要パラメータ

| パラメータ | 説明 | デフォルト値 |
|-----------|------|-------------|
| `ip_address` | LiDAR IP（Ethernet モード） | `192.168.1.10` |
| `ip_port` | LiDAR ポート | `10940` |
| `serial_port` | シリアルデバイス（Serial モード） | `/dev/ttyACM0` |
| `frame_id` | TF フレーム名 | `laser` |
| `angle_min` / `angle_max` | スキャン角度範囲（rad） | `-3.14` / `3.14` |
| `publish_intensity` | 強度データを配信 | `true` |

## アーキテクチャ

### Docker Build Stage 関係図

```mermaid
graph TD
    EXT1["bats/bats:latest"]
    EXT2["alpine:latest"]
    EXT3["ros:humble-ros-base-jammy"]
    EXT4["ros:humble-ros-core-jammy"]

    EXT1 --> bats-src["bats-src"]
    EXT2 --> bats-ext["bats-extensions"]

    EXT3 --> builder["builder\ngit clone urg_node2 + colcon build"]

    EXT4 --> devel["devel\nlaser-proc + builder の install"]
    builder -.->|COPY install/| devel

    bats-src --> test["test一時的\nsmoke/ ビルド後に破棄"]
    bats-ext --> test
    devel --> test

```

### Stage 説明

| Stage | FROM | 用途 |
|-------|------|------|
| `bats-src` | `bats/bats:latest` | bats バイナリソース、出荷しない |
| `bats-extensions` | `alpine:latest` | bats-support、bats-assert、出荷しない |
| `builder` | `ros:humble-ros-base-jammy` | urg_node2 をクローン + ビルド |
| `devel` | `ros:humble-ros-core-jammy` | 最小化 runtime、ビルド済みパッケージ + laser-proc |
| `test` | `devel` | Smoke test、ビルド後に破棄 |

## Smoke Tests

詳細は [TEST.md](test/TEST.md) を参照。

## ディレクトリ構成

```text
urg_node_humble/
├── compose.yaml                 # Docker Compose 定義
├── Dockerfile                   # マルチステージビルド（builder + devel + test）
├── build.sh -> .base/build.sh    # Symlink
├── run.sh -> .base/run.sh        # Symlink
├── exec.sh -> .base/exec.sh      # Symlink
├── stop.sh -> .base/stop.sh      # Symlink
├── Makefile -> .base/Makefile    # Symlink
├── .template_version            # Template subtree バージョン（v0.4.1）
├── .hadolint.yaml               # カスタム Hadolint ルール
├── script/
│   └── entrypoint.sh            # ROS 2 + workspace を source
├── config/                      # Hokuyo パラメータファイル
│   ├── params_ether.yaml        # Ethernet 接続
│   ├── params_ether_2nd.yaml    # 2台目の LiDAR（Ethernet）
│   └── params_serial.yaml       # Serial 接続
├── .base/                    # 共用テンプレート（git subtree）
├── doc/                         # 翻訳版 README
│   ├── README.zh-TW.md          # 繁体字中国語
│   ├── README.zh-CN.md          # 簡体字中国語
│   └── README.ja.md             # 日本語
├── .github/workflows/
│   └── main.yaml                # CI/CD（template reusable workflows を呼び出し）
└── test/smoke/                  # Bats 環境テスト（repo 固有）
    └── ros_env.bats
```
