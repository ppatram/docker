# --- DB Subnet Group ---

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db-subnet"
  subnet_ids = aws_subnet.data[*].id
  tags       = merge(local.common_tags, { Name = "${local.name}-db-subnet" })
}

# --- RDS PostgreSQL ---

resource "aws_db_instance" "postgres" {
  identifier     = "${local.name}-postgres"
  engine         = "postgres"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage = 20
  storage_encrypted = true
  storage_type      = "gp3"

  db_name  = var.rds_db_name
  username = var.rds_username
  password = random_password.rds.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.data.id]

  multi_az            = var.rds_multi_az
  publicly_accessible = false
  skip_final_snapshot = true

  backup_retention_period = var.rds_backup_retention_days

  tags = local.common_tags
}

resource "random_password" "rds" {
  length  = 24
  special = false
}

# --- ElastiCache Redis ---

resource "aws_elasticache_subnet_group" "main" {
  count      = var.enable_elasticache ? 1 : 0
  name       = "${local.name}-cache-subnet"
  subnet_ids = aws_subnet.data[*].id
}

resource "aws_elasticache_replication_group" "redis" {
  count                = var.enable_elasticache ? 1 : 0
  replication_group_id = "${local.name}-redis"
  description          = "Redis cache for ${local.name}"
  node_type            = var.elasticache_node_type
  num_cache_clusters   = var.elasticache_num_nodes

  engine_version     = "7.0"
  port               = 6379
  subnet_group_name  = aws_elasticache_subnet_group.main[0].name
  security_group_ids = [aws_security_group.data.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = local.common_tags
}

# --- Secrets Manager ---

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.name}/db-credentials"
  description = "RDS credentials for ${local.name}"
  tags        = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.postgres.username
    password = random_password.rds.result
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = aws_db_instance.postgres.db_name
  })
}
