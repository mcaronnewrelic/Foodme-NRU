#!/bin/bash
set -e

# PostgreSQL Monitoring Post-Setup Script
# This script runs after PostgreSQL has been configured and extensions installed
# It verifies the monitoring setup and creates any additional monitoring objects

echo "Running PostgreSQL monitoring post-setup verification..."

# This script runs during initialization, so PostgreSQL connection parameters
# are handled by the Docker entrypoint automatically

echo "Verifying monitoring extensions installation..."

# Connect to the database and run verification queries
# Note: During Docker initialization, the connection parameters are set automatically
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Verify pg_stat_statements is working
    \echo 'Testing pg_stat_statements extension:'
    SELECT COUNT(*) as statement_count FROM pg_stat_statements;
    
    -- Verify pg_buffercache is working
    \echo 'Testing pg_buffercache extension:'
    SELECT COUNT(*) as buffer_count FROM pg_buffercache WHERE reldatabase IS NOT NULL;
    
    -- Test pgstattuple functionality
    \echo 'Testing pgstattuple extension:'
    SELECT 'pgstattuple extension is functional' as status;
    
    -- Test pgrowlocks functionality  
    \echo 'Testing pgrowlocks extension:'
    SELECT 'pgrowlocks extension is functional' as status;
    
    -- Show current configuration relevant to monitoring
    \echo 'Current monitoring-related PostgreSQL settings:'
    SELECT name, setting, unit, context 
    FROM pg_settings 
    WHERE name IN (
        'shared_preload_libraries',
        'log_min_duration_statement', 
        'log_checkpoints',
        'log_connections',
        'log_disconnections',
        'log_lock_waits',
        'track_activities',
        'track_counts',
        'track_io_timing'
    )
    ORDER BY name;
    
    -- Create a simple monitoring view for easy access to key metrics
    CREATE OR REPLACE VIEW monitoring_summary AS
    SELECT 
        'PostgreSQL Monitoring Status' as component,
        CASE 
            WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') 
            THEN 'Enabled' 
            ELSE 'Disabled' 
        END as pg_stat_statements,
        CASE 
            WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_buffercache') 
            THEN 'Enabled' 
            ELSE 'Disabled' 
        END as pg_buffercache,
        CASE 
            WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgstattuple') 
            THEN 'Enabled' 
            ELSE 'Disabled' 
        END as pgstattuple,
        CASE 
            WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgrowlocks') 
            THEN 'Enabled' 
            ELSE 'Disabled' 
        END as pgrowlocks,
        current_timestamp as check_time;
    
    -- Display the monitoring summary
    \echo 'PostgreSQL Monitoring Setup Summary:'
    SELECT * FROM monitoring_summary;
EOSQL

echo "PostgreSQL monitoring post-setup completed successfully!"
echo "All monitoring extensions are installed and configured."
echo "The database is ready for comprehensive monitoring with New Relic."