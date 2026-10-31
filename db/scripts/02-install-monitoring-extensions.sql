-- PostgreSQL Monitoring Extensions Installation
-- Based on CloudFormation setup_postgresql_monitoring() function
-- This script installs all the monitoring extensions required for comprehensive PostgreSQL monitoring

\echo 'Installing PostgreSQL monitoring extensions...'

-- Install pg_stat_statements extension for query performance tracking
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
\echo 'pg_stat_statements extension installed'

-- Install pg_buffercache extension for buffer cache monitoring
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
\echo 'pg_buffercache extension installed'

-- Install pgstattuple extension for table-level statistics and bloat analysis
CREATE EXTENSION IF NOT EXISTS pgstattuple;
\echo 'pgstattuple extension installed'

-- Install pgrowlocks extension for row-level locking information
CREATE EXTENSION IF NOT EXISTS pgrowlocks;
\echo 'pgrowlocks extension installed'

-- Verify all extensions are installed
\echo 'Verifying installed extensions:'
SELECT extname, extversion 
FROM pg_extension 
WHERE extname IN ('pg_stat_statements', 'pg_buffercache', 'pgstattuple', 'pgrowlocks')
ORDER BY extname;

-- Show pg_stat_statements configuration
\echo 'Current pg_stat_statements configuration:'
SELECT name, setting, unit, context, short_desc
FROM pg_settings 
WHERE name LIKE 'pg_stat_statements%'
ORDER BY name;

-- Display monitoring readiness status
\echo 'PostgreSQL monitoring extensions installation completed!'
\echo 'Installed extensions: pg_stat_statements, pg_buffercache, pgstattuple, pgrowlocks'
\echo 'These extensions provide comprehensive monitoring capabilities for New Relic PostgreSQL integration.'