#!/bin/bash
set -e

# PostgreSQL Monitoring Configuration Script
# Based on CloudFormation setup_postgresql_monitoring() function
# This script configures PostgreSQL for comprehensive monitoring with New Relic

echo "Setting up PostgreSQL monitoring configuration..."

# Configure shared_preload_libraries for pg_stat_statements
PGCONF="/var/lib/postgresql/data/postgresql.conf"

echo "Configuring PostgreSQL for monitoring..."

# Configure shared_preload_libraries
if ! grep -q "shared_preload_libraries" "$PGCONF"; then
    echo "shared_preload_libraries = 'pg_stat_statements'" >> "$PGCONF"
else
    sed -i "s/^#*shared_preload_libraries = .*/shared_preload_libraries = 'pg_stat_statements'/" "$PGCONF"
fi

# Add comprehensive monitoring configuration
cat >> "$PGCONF" << 'EOF'

# PostgreSQL Monitoring Configuration
# Based on CloudFormation setup_postgresql_monitoring() function

# pg_stat_statements configuration
pg_stat_statements.max = 10000
pg_stat_statements.track = all
pg_stat_statements.save = on
pg_stat_statements.track_utility = on
pg_stat_statements.track_planning = on

# Additional performance monitoring settings
log_statement_stats = off
log_parser_stats = off
log_planner_stats = off
log_executor_stats = off

# Query logging for additional monitoring
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Log file permissions for monitoring
log_file_mode = 0644

# Additional monitoring-friendly settings
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_truncate_on_rotation = off

# Performance monitoring
track_activities = on
track_counts = on
track_io_timing = on
track_functions = all
EOF

echo "PostgreSQL monitoring configuration completed!"
echo "Note: Extensions will be installed after PostgreSQL is fully initialized."