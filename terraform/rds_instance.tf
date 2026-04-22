# ---------------------------------------------------------
# RDS MySQL Instance (Primary)
# ---------------------------------------------------------
resource "aws_db_instance" "database" {
  identifier = "my-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = var.db_username
  password            = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible     = false
  multi_az                = true
  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = {
    Name = "database-primary"
  }
}

# ---------------------------------------------------------
# RDS MySQL Read Replica（読み取り専用レプリカ）
# ---------------------------------------------------------
resource "aws_db_instance" "database_replica" {
  identifier = "my-mysql-replica"

  replicate_source_db = aws_db_instance.database.identifier

  instance_class = "db.t3.micro"
  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "database-replica"
  }
}
