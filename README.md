# Setting up a Data Warehouse with AWS Redshift and Ruby
Published on the [Credible Blog](https://www.credible.com/code/setting-up-a-data-warehouse-with-aws-redshift-and-ruby/)

![Screenshot](https://www.credible.com/code/wp-content/uploads/2015/09/AUvn49gey8Y-thumb.png)

Most startups eventually need a robust solution for storing large amounts of data for analytics. Perhaps you're running a video app trying to understand user drop-off or you're studying user behavior on your website like we do at Credible. 

You might start with a few tables in your primary database. Soon you may create a separate web app with a nightly cron job to sync data. Before you know it, you have more data than you can handle, jobs are taking way too long, and you're being asked to integrate data from more sources. This is where a [data warehouse](https://en.wikipedia.org/wiki/Data_warehouse) comes in handy. It allows your team to store and query terabytes or even petabytes of data from many sources without writing a bunch of custom code.

In the past, only big companies like Amazon had data warehouses because they were expensive, hard to setup, and time-consuming to maintain. With AWS Redshift and Ruby, we'll show you how to setup your own simple, inexpensive, and scalable data warehouse. We'll provide [sample code](https://github.com/tuesy/redshift-ruby-tutorial) that will show you to how to extract, transform, and load (ETL) data into Redshift as well as how to access the data from a Rails app.

## Part I: Setting up AWS Redshift

### Creating a Redshift Cluster

We chose AWS's Redshift offering because it's easy to set up, inexpensive (it's AWS after all), and its interface is pretty similar to that of Postgres so you can manage it using tools like [Postico](https://eggerapps.at/postico/), a Postgres database manager for OSX, and use with Ruby via an [activerecord adapter](https://github.com/aamine/activerecord4-redshift-adapter). Let's begin by logging into your AWS console and creating a new Redshift cluster. Make sure to write down your cluster info as we'll need it later.

![Screenshot](https://13217-presscdn-0-50-pagely.netdna-ssl.com/code/wp-content/uploads/2015/09/Redshift_%C2%B7_AWS_Console_4.png)

We're going with a single node here for development and QA environments but for production, you'll want to create a multi-node cluster so you can get faster importing and querying as well as handle more data.

![Screenshot](https://13217-presscdn-0-50-pagely.netdna-ssl.com/code/wp-content/uploads/2015/09/Redshift_%C2%B7_AWS_Console_3.png)

You can optionally encrypt the data and enable other security settings here. You can go with defaults the rest of the way for the purposes of this tutorial. Note that you'll start incurring charges once you create the cluster ($0.25 an hour for DC1.Large and first 2 months free).

![Screenshot](https://13217-presscdn-0-50-pagely.netdna-ssl.com/code/wp-content/uploads/2015/09/Redshift_%C2%B7_AWS_Console_2.png)

When you're done, you'll see a summary page for the cluster. Please jot down the hostname in the Endpoint.

![Screenshot](https://13217-presscdn-0-50-pagely.netdna-ssl.com/code/wp-content/uploads/2015/09/Redshift_%C2%B7_AWS_Console_1.png)

By default, nothing is allowed to connect to the cluster. You can create one for your computer by going to Security > Add Connection Type > Authorize--AWS will automatically fill in your current IP address for convenience.

![Screenshot](https://13217-presscdn-0-50-pagely.netdna-ssl.com/code/wp-content/uploads/2015/09/Redshift_%C2%B7_AWS_Console.png)

### Verifying Your Cluster

Now, let's try connecting to your cluster using [Postico](https://eggerapps.at/postico/). You'll need to create a Favorite and fill in the info you used to create the cluster. Note that the Endpoint url you got from the Redshift cluster contains both the host and port--you'll need to put them in separate fields. 

![Screenshot](https://13217-presscdn-0-50-pagely.netdna-ssl.com/code/wp-content/uploads/2015/09/Postico_Favorites.png)

If you're successful, you'll see something like this.

![Screenshot](https://13217-presscdn-0-50-pagely.netdna-ssl.com/code/wp-content/uploads/2015/09/redshift-ruby-tutorial_%E2%80%93_analytics_and__bash_profile_%E2%80%94_redshift-ruby-tutorial_and_3__bash.png)

Congrats, you've created your first data warehouse! For your Production environment, you may want to beef up the security or use a multi-node cluster for redundancy and performance.

The next step is to configure Redshift so we can load data into it. Redshift acts like Postgres for the most part. For example, you need to create tables ahead of time and you'll need to specify the data types for each column. There are some differences that may trip you up. We ran into issues at first because the default Rails data types don't map correctly. The following are some examples of Rails data types and how they should be mapped to Redshift:

* integer => int
* string => varchar
* date => date
* datetime => timestamp
* boolean => bool
* text => varchar(65535)
* decimal(precision, scale) => decimal(precision, scale)

Note that the ID column should be of type "bigint". The [Redshift documentation](https://aws.amazon.com/documentation/redshift/) has more details. Here's how we mapped the "users" table for the sample app.

![Screenshot](https://13217-presscdn-0-50-pagely.netdna-ssl.com/code/wp-content/uploads/2015/09/redshift-ruby-tutorial_%E2%80%93_analytics_and_schema_rb_%E2%80%94_redshift-ruby-tutorial_and_3__bash.png)

You should also note that we didn't map all fields. You'll want to omit sensitive fields like "password" or add fields on an as-needed basis to reduce complexity and costs.

## Part 2: Extracting, Transforming, and Loading (ETL)

### Create an S3 Bucket

You'll need to create an S3 bucket either via the AWS Console or through their API. For this sample, we've created one called "redshift-ruby-tutorial".

### Setup the Sample App

We created a [sample Rails app](https://github.com/tuesy/redshift-ruby-tutorial) for this part. It contains a User table,  some seed data, and a Loader class that will perform ETL. The high-level approach is to output the User data to CSV files, upload the files to an AWS S3 bucket, and then trigger Redshift to load the CSV files.

Let's start by cloning the app:

```bash
git clone git@github.com:tuesy/redshift-ruby-tutorial.git
cd redshift-ruby-tutorial
```

Next, update your environment variables by editing and sourcing the ~/.bash_profile. You should use the info from  when you created your cluster.

```bash
# redshift-ruby-tutorial
export REDSHIFT_HOST=redshift-ruby-tutorial.ccmj2nxbsay7.us-east-1.redshift.amazonaws.com
export REDSHIFT_PORT=5439
export REDSHIFT_USER=deploy
export REDSHIFT_PASSWORD=<your password here>
export REDSHIFT_DATABASE=analytics
export REDSHIFT_BUCKET=redshift-ruby-tutorial
```

We're ready to bundle our gems, create our database, and seed the dummy data:

```bash
bundle install
bundle exec rake db:setup
```

Before we run ETL, let's check the connection to Redshift. This should return "0 users" because we haven't loaded any data yet:

```bash
bundle exec rails c
RedshiftUser.count
```

Now let's run ETL and then count users again (there should be some users now):

```ruby
require 'loader'
Loader.load
RedshiftUser.count
```

Here's an example of the output you should see:

```bash
~/git/redshift-ruby-tutorial(master)$ bundle exec rails c
Loading development environment (Rails 4.2.3)
irb(main):001:0> RedshiftUser.count
unknown OID 16: failed to recognize type of 'attnotnull'. It will be treated as String.
   (1055.2ms)  SELECT COUNT(*) FROM "users"
=> 0
irb(main):002:0> require 'loader'
=> true
irb(main):003:0> Loader.load
  User Load (0.2ms)  SELECT  "users".* FROM "users"  ORDER BY "users"."id" ASC LIMIT 1000
INFO:  Load into table 'users' completed, 6 record(s) loaded successfully.
=> #<PG::Result:0x007ff31da1de08 status=PGRES_COMMAND_OK ntuples=0 nfields=0 cmd_tuples=0>
irb(main):004:0> RedshiftUser.count
   (95.7ms)  SELECT COUNT(*) FROM "users"
=> 6
irb(main):005:0> RedshiftUser.first
  RedshiftUser Load (1528.4ms)  SELECT  "users".* FROM "users"  ORDER BY "users"."id" ASC LIMIT 1
=> #<RedshiftUser id: 1, name: "Data", email: "data@enterprise.fed", sign_in_count: 0, current_sign_in_at: nil, last_sign_in_at: nil, current_sign_in_ip: nil, last_sign_in_ip: nil, created_at: nil, updated_at: nil>
```

### How to Connect to Redshift

Redshift is based on Postgres so we can use a slightly modified ActiveRecord adapter:

```ruby
gem 'activerecord4-redshift-adapter', '~> 0.2.0'
```

We use an initializer to DRY things up a bit:

```ruby
Rails.application.secrets.redshift_config = {
  host: ENV['REDSHIFT_HOST'],
  port: ENV['REDSHIFT_PORT'],
  user: ENV['REDSHIFT_USER'],
  password: ENV['REDSHIFT_PASSWORD'],
  database: ENV['REDSHIFT_DATABASE'],
  adapter: 'redshift'
}
```

You can configure each Rails model to connect to a separate database so we created a base class for all the tables we'll use to connect to Redshift:

```ruby
class RedshiftBase < ActiveRecord::Base
  establish_connection Rails.application.secrets.redshift_config
  self.abstract_class = true
end
```

For the RedshiftUser class, we'll just need to specify the name of the table, otherwise Rails would look for a table named "redshift_users". This is also necessary because we have our own User class for the local database.

```ruby
class RedshiftUser < RedshiftBase
  self.table_name = :users
end
```

With this configured, you can query the table. For associations, you'll have to do some more customizations if you want niceties like "@user.posts".

### How to ETL

This task is performed by the Loader class. We begin by connecting to AWS and Redshift:

```ruby
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
```

This is the heart of the process. The source data comes from the User table. We're fetching users in fixed-size batches to avoid timeouts. For now, we're querying for all users, but you can modify this to return only active users, for example. 

Don't be alarmed by all the nested blocks--we're just creating temporary files, generating an array with the values for each column, and then compressing the data using gzip so we can save time and money. We're not doing any transformation here, but you could do things like format a column or generate new columns. We upload each CSV file to our S3 bucket after processing each batch but you could upload after everything is generated if desired.

```ruby
# extract data to CSV files and upload to S3
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
```

Finally, we clear existing data in this Redshift table and tell Redshift to load the new data from S3. Note that we are specifying the column names for the table so that the right data goes to the right columns in the database. We also specify "GZIP" so that Redshift knows that the files are compressed. Using multiple files also allows Redshift to load data in parallel if you have multiple nodes.

```ruby
# clear existing data for this table
db.exec <<-EOS
TRUNCATE #{TABLE}
EOS
&nbsp;
# load the data, specifying the order of the fields
db.exec <<-EOS
COPY #{TABLE} (#{COLUMNS.join(', ')})
FROM 's3://#{BUCKET}/#{TABLE}/data'
CREDENTIALS 'aws_access_key_id=#{ENV['AWS_ACCESS_KEY_ID']};aws_secret_access_key=#{ENV['AWS_SECRET_ACCESS_KEY']}'
CSV
EMPTYASNULL
GZIP
EOS
```

There are other improvements you can add. For example, using a manifest file, you can have full control over which CSVs are loaded. Also, while the current approach truncates and reloads the table on each run, which can be slow, you can do incremental loads.

## Links

* [Sample Rails app on Github](https://github.com/tuesy/redshift-ruby-tutorial)
* [Postico](https://eggerapps.at/postico/)
* [Redshift documentation](https://aws.amazon.com/documentation/redshift/)
* [activerecord adapter](https://github.com/aamine/activerecord4-redshift-adapter)
* [@mankindforward](https://twitter.com/mankindforward)

## We're hiring!
Checkout our [jobs page](https://angel.co/credible/jobs/)
