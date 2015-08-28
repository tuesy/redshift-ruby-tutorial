## Usage

### Clone this repo
```
git clone git@github.com:tuesy/redshift-ruby-tutorial.git
cd redshift-ruby-tutorial
```
### Setup your environment variables
Edit your ~/.bash_profile:
```
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
require 'loader'
Loader.load
```
