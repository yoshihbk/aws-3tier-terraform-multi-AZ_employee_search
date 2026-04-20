# AWS 3-Tier Architecture (Employee Search App, Multi-AZ)

本プロジェクトは、AWS 上に構築する **複数AZ対応の Web 3層アーキテクチャ** 上でFlask を用いた **社員検索アプリケーション** を動作させる構成を
Terraform によって IaC 化したものです。

本アプリケーションは、RDS（MySQL）に保存された社員情報を検索し、結果を Web UI（Flask）で表示します。

## アーキテクチャ図

<p align="center">
  <img src="./diagrams/3tier-architecture-app.png" width="700">
</p>

## 主な構成要素

- **ALB（Application Load Balancer）**
  - Flask アプリへのルーティングを担当

- **EC2（Auto Scaling Group）**
  - Flask + nginx を実行
  - user_data により自動セットアップ

- **RDS（MySQL, Multi-AZ）**
  - Primary：書き込み
  - Read Replica：読み取り（社員検索クエリを実行）

- **VPC（Public / Private Subnets, Multi-AZ）**
  - AWS ベストプラクティスに準拠したネットワーク構成

## 機能概要

- 社員名で検索
- RDS の社員テーブルから該当データを取得
- 結果を Flask テンプレートで表示
- Read Replica を使用した読み取り負荷分散

