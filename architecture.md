# Architecture Design (Employee Search App, AWS 3-Tier / Multi-AZ)

本ドキュメントでは、本アプリケーションが採用する **AWS 3層アーキテクチャ** の技術的背景と、
各コンポーネントをこの配置にした理由を説明します。

---

## 1. 全体構成概要

本アプリケーションは以下の 3 層で構成されています。

- **Presentation Layer（Public Subnet）**
  - Application Load Balancer（ALB）

- **Application Layer（Private Subnet）**
  - EC2（Flask App Server, Auto Scaling Group）

- **Data Layer（Private Subnet）**
  - RDS Primary（Write）
  - RDS Standby（Failover）
  - RDS Read Replica（Read）

この構成により、**高可用性（Multi-AZ）** と **読み取り性能の向上（Read Replica）** を両立しています。

---

## 2. ネットワーク構成（VPC / Subnets）

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

## 3. Application Load Balancer（ALB）

- Public Subnet に配置
- HTTP/HTTPS リクエストを Private Subnet の EC2 にルーティング
- ヘルスチェックにより ASG のインスタンスを監視
- スケールアウト時も自動でターゲット登録される

**採用理由：**
- 外部公開は ALB のみとし、EC2 を非公開化することでセキュリティを強化
- ASG と組み合わせて高可用性を実現

---

## 4. EC2（Flask App Server / Auto Scaling Group）

- Private Subnet に配置
- nginx → Flask → RDS の構成
- user_data により自動セットアップ
- Auto Scaling Group により負荷に応じてスケールアウト

**採用理由：**
- Private Subnet に置くことで外部から直接アクセスできない
- ASG により高負荷時の自動スケールが可能
- nginx によりリバースプロキシ構成を実現

---

## 5. RDS（MySQL, Multi-AZ + Read Replica）

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

## 6. Security Group 設計

- **ALB SG → EC2 SG**  
  ALB からの HTTP/HTTPS のみ許可

- **EC2 SG → RDS SG**  
  EC2 からの MySQL（3306）のみ許可

- **RDS SG**  
  外部からの直接アクセスは不可

**採用理由：**  
最小権限の原則（Least Privilege）に基づき、  
必要な通信のみを許可する構成とするため。

---

## 7. NAT Gateway

- Private Subnet の EC2 が OS パッケージ更新や pip install を行うために必要
- インバウンドは遮断しつつ、アウトバウンドのみ許可

---

## 8. まとめ

本アーキテクチャは以下を満たす構成となっています。

- 高可用性（Multi-AZ）
- 読み取り性能向上（Read Replica）
- セキュアなネットワーク分離（Public / Private）
- スケーラブルなアプリケーション層（ASG）
- AWS ベストプラクティスに準拠

Terraform によってこれらを IaC 化し、再現性と保守性を高めています。
