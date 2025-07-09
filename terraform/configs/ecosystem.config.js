module.exports = {
  apps: [{
    name: 'foodme',
    script: 'server/start.js',
    cwd: '/var/www/foodme',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    log_file: '/var/log/foodme/combined.log',
    out_file: '/var/log/foodme/out.log',
    error_file: '/var/log/foodme/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    max_memory_restart: '1G'
  }]
};
