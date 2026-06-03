# Training environment defaults — optimized for cost
project     = "k8s-training"
environment = "dev"
region      = "us-east-1"

# Networking
vpc_cidr           = "10.0.0.0/16"
az_count           = 2
enable_nat_gateway = true

# EKS
eks_version        = "1.29"
node_instance_type = "t3.medium"
node_desired_size  = 2
node_min_size      = 0
node_max_size      = 3

# RDS (minimal for training)
rds_instance_class        = "db.t3.micro"
rds_engine_version        = "15.7"
rds_db_name               = "appdb"
rds_username              = "dbadmin"
rds_multi_az              = false
rds_backup_retention_days = 1

# ElastiCache (disabled by default to save cost)
enable_elasticache    = false
elasticache_node_type = "cache.t3.micro"
elasticache_num_nodes = 1

# Observability
log_retention_days = 7
