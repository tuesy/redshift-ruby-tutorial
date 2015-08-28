# require 'loader'; Loader.load
require 'csv'
class Loader
  BUCKET = ENV['REDSHIFT_BUCKET']
  BATCH_SIZE = 1000
  TABLE = 'users'
  COLUMNS = %w(id name email sign_in_count current_sign_in_at last_sign_in_at)

  class << self
    def load
      # setup AWS credentials
      Aws.config.update({
        region: 'us-east-1',
        credentials: Aws::Credentials.new(
          ENV['AWS_ACCESS_KEY_ID'],
          ENV['AWS_SECRET_ACCESS_KEY'])
      })

      # connect to Redshift
      db = PG.connect(
        host: ENV['REDSHIFT_HOST'],
        port: ENV['REDSHIFT_PORT'],
        user: ENV['REDSHIFT_USER'],
        password: ENV['REDSHIFT_PASSWORD'],
        dbname: ENV['REDSHIFT_DATABASE'],
      )

      # extract data to CSV files and uplaod to S3
      User.find_in_batches(batch_size: BATCH_SIZE).with_index do |group, batch|
        Tempfile.open(TABLE) do |f|
          Zlib::GzipWriter.open(f) do |gz|
            csv_string = CSV.generate do |csv|
              group.each do |record|
                csv << COLUMNS.map{|x| record.send(x)}
              end
            end
            gz.write csv_string
          end
          # upload to s3
          s3 = Aws::S3::Resource.new
          key = "#{TABLE}/data-#{batch}.gz"
          obj = s3.bucket(BUCKET).object(key)
          obj.upload_file(f)
        end
      end


      # clear existing data for this table
      db.exec <<-EOS
        TRUNCATE #{TABLE}
      EOS

      # load the data, specifying the order of the fields
      db.exec <<-EOS
        COPY #{TABLE} (#{COLUMNS.join(', ')})
        FROM 's3://#{BUCKET}/#{TABLE}/data'
        CREDENTIALS 'aws_access_key_id=#{ENV['AWS_ACCESS_KEY_ID']};aws_secret_access_key=#{ENV['AWS_SECRET_ACCESS_KEY']}'
        CSV
        EMPTYASNULL
        GZIP
      EOS
    end
  end
end
