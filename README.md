## Usage

### Clone this repo
```bash
git clone git@github.com:tuesy/redshift-ruby-tutorial.git
cd redshift-ruby-tutorial
```
### Setup your environment variables
Edit your ~/.bash_profile:
```bash
export REDSHIFT_HOST=redshift-ruby-tutorial.ccmj2nxbsay7.us-east-1.redshift.amazonaws.com
export REDSHIFT_PORT=5439
export REDSHIFT_USER=deploy
export REDSHIFT_PASSWORD=
export REDSHIFT_DATABASE=analytics
export REDSHIFT_BUCKET=redshift-ruby-tutorial
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```
Reload your environment:

```source ~/.bash_profile```
### Run the demo
```
bundle install
bundle exec rake db:setup
bundle exec rails c
RedshiftUser.count
require 'loader'
Loader.load
RedshiftUser.count
RedshiftUser.first
```
### You should see something like this
```ruby
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
