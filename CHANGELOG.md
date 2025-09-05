# Changle Log

### Added
- Added Firelens and Fluentbit long configuration for all ECS tasks
- Created stage environment (porting over initial files from dmsp_aws_prototype repo) 

### Updated
- Updated Fluentbit config to push everything into an `extra` field and then pull only the fields we want to be able to filter by to the top level.

### Removed

