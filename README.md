## Usage

### Clone this repo
```
git clone git@github.com:tuesy/redshift-ruby-tutorial.git
cd redshift-ruby-tutorial
```
### Setup your environment variables
Note: use your own cluster credentials
```
# ~/.bash_profile
export REDSHIFT_HOST=redshift-ruby-tutorial.ccmj2nxbsay7.us-east-1.redshift.amazonaws.com
export REDSHIFT_PORT=5439
export REDSHIFT_USER=deploy
export REDSHIFT_PASSWORD=
export REDSHIFT_DATABASE=analytics
export REDSHIFT_BUCKET=redshift-ruby-tutorial
```
###
```bundle exec rake db:setup```
```

