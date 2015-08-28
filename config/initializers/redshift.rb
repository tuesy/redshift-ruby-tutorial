Rails.application.secrets.redshift_config = {
  host: ENV['REDSHIFT_HOST'],
  port: ENV['REDSHIFT_PORT'],
  user: ENV['REDSHIFT_USER'],
  password: ENV['REDSHIFT_PASSWORD'],
  database: ENV['REDSHIFT_DATABASE'],
  adapter: 'redshift'
}
