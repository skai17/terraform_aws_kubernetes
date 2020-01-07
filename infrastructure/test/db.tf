# create the subnet group for the databases
resource "aws_db_subnet_group" "database-subnet-group" {
  name       = "${local.cluster-name}_database-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${local.cluster-name}_database-subnet-group"
  }
}

# create the documentDB cluster
resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "${local.cluster-name}-docdb"
  engine                  = "docdb"
  db_subnet_group_name    =  aws_db_subnet_group.database-subnet-group.name
  master_username         = "user1"
  master_password         = "somepassword"
  backup_retention_period = 1
  skip_final_snapshot     = true
}

# add cluster instances
resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "${local.cluster-name}-docdb-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = "db.r5.large"
}