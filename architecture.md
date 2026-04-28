# Architecture Design (Employee Search App, AWS 3-Tier / Multi-AZ)

本ドキュメントでは、本アプリケーションが採用する **AWS 3層アーキテクチャ** の技術的背景と、
各コンポーネントをこの配置にした理由、さらに Flask アプリケーションの動作フローについて説明します。

---

## 1. 全体構成概要

本アプリケーションは以下の 3 層で構成されています。

- **Presentation Layer（Public Subnet）**
  - Application Load Balancer（HTTP）

- **Application Layer（Private Subnet）**
  - EC2（Flask App Server, Auto Scaling Group）
  - nginx（リバースプロキシ）

- **Data Layer（Private Subnet）**
  - RDS Primary（Write）
  - RDS Standby（Failover）
  - RDS Read Replica（Read）

この構成により、**高可用性（Multi-AZ）** と **読み取り性能の向上（Read Replica）** を両立しています。

---

## 2. Flask アプリケーションの動作フロー

本アプリケーションは「社員検索」を行う Web アプリであり、
ユーザの入力した社員名をもとに RDS の社員テーブルを検索し、結果を Web UI に表示します。

### ● リクエスト処理の流れ

1. **ユーザ → ALB**
   ブラウザから `/search` にアクセスすると、ALB がリクエストを受け取る。

2. **ALB → EC2（nginx）**
   ALB はヘルスチェック済みの EC2 インスタンスへルーティング。

3. **nginx → Flask**
   nginx がリバースプロキシとして動作し、Flask の 5000 番ポートへ転送。

4. **Flask → RDS Read Replica**
   Flask アプリは社員検索クエリを **Read Replica** に対して実行し、読み取り負荷を分散。

5. **Flask → HTML テンプレート**
   取得した社員情報を Jinja2 テンプレートで整形し、ユーザに返却。

### ● Flask アプリの役割

- `/search` で社員名を受け取り、部分一致検索を実行
- MySQL Connector を使用して RDS に接続
- 結果を HTML で返すシンプルな Web アプリ
- インフラ動作確認に最適な最小構成

---

## 3. ネットワーク構成（VPC / Subnets）

### ● Public Subnet
- ALB を配置
- Internet Gateway と接続し、外部からの唯一の入口となる
- NAT Gateway を配置し、Private Subnet からのアウトバウンド通信を提供

### ● Private Subnet
- EC2（Flask App Server）を配置
- RDS（Primary / Standby / Read Replica）を配置
- 外部公開されず、ALB 経由でのみアクセス可能

**理由：**
アプリケーションサーバやデータベースを Public に置くのはセキュリティ上のアンチパターンであり、
AWS Well-Architected Framework でも Private Subnet 配置が推奨されているため。

---

## 4. Application Load Balancer（ALB）
Public Subnet に配置
HTTP（80番）リクエストのみ を Private Subnet の EC2 にルーティング
ヘルスチェックにより ASG のインスタンスを監視
スケールアウト時も自動でターゲット登録される

**採用理由：**
外部公開は ALB のみとし、EC2 を非公開化することでセキュリティを強化
ASG と組み合わせて高可用性を実現
今回は学習目的のため HTTP のみを使用（本番では HTTPS が推奨）

---

## 5. EC2（Flask App Server / Auto Scaling Group）

- Private Subnet に配置
- nginx → Flask → RDS の構成
- user_data により自動セットアップ
- Auto Scaling Group により負荷に応じてスケールアウト

**採用理由：**
- Private Subnet に置くことで外部から直接アクセスできない
- ASG により高負荷時の自動スケールが可能
- nginx によりリバースプロキシ構成を実現

---

## 6. RDS（MySQL, Multi-AZ + Read Replica）

### ● Primary（Write）
- すべての書き込み処理を担当

### ● Standby（Failover）
- Primary 障害時に自動昇格
- 同期レプリケーションによりデータ整合性を保持

### ● Read Replica（Read）
- 社員検索クエリなどの読み取り処理を担当
- 読み取り負荷を分散し、アプリの応答性を向上

**採用理由：**
- Multi-AZ により高可用性を確保
- Read Replica により読み取り性能を向上
- アプリの特性（検索中心）に最適

---

## 7. Security Group 設計

ALB SG → EC2 SG
ALB からの HTTP（80番） のみ許可
EC2 SG → RDS SG
EC2 からの MySQL（3306）のみ許可
RDS SG
外部からの直接アクセスは不可

**採用理由：**
最小権限の原則（Least Privilege）に基づき、
必要な通信のみを許可する構成とするため。

---

## 8. NAT Gateway

- Private Subnet の EC2 が OS パッケージ更新や pip install を行うために必要
- インバウンドは遮断しつつ、アウトバウンドのみ許可

---

## 9. Terraform による IaC 化

本アーキテクチャは Terraform により完全 IaC 化されており、以下を自動構築します。

- VPC / Subnets / Route Tables
- ALB / Target Group / Listener
- Auto Scaling Group / Launch Template
- EC2（Flask + nginx セットアップ）
- RDS（Primary / Standby / Read Replica）
- Security Groups
- NAT Gateway / Internet Gateway

**メリット：**

- 再現性の高い環境構築
- 手作業による設定ミスの防止
- バージョン管理による変更追跡
- チーム開発に適した構成管理

---

## 10. まとめ

本アーキテクチャは以下を満たす構成となっています。

- 高可用性（Multi-AZ）
- 読み取り性能向上（Read Replica）
- セキュアなネットワーク分離（Public / Private）
- スケーラブルなアプリケーション層（ASG）
- Flask によるシンプルで拡張可能なアプリ層
- AWS ベストプラクティスに準拠
- Terraform による完全 IaC 化

本構成は、検索中心の Web アプリケーションに最適化されており可用性・性能・保守性のバランスが取れた設計となっています。
