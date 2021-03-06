$: << '.'
require File.dirname(__FILE__) + "/initializers/scheduled_publishing"
# default cron env is "/usr/bin:/bin" which is not sufficient as govuk_env is in /usr/local/bin
env :PATH, '/usr/local/bin:/usr/bin:/bin'

# We need Rake to use our own environment
job_type :rake, "cd :path && govuk_setenv whitehall bundle exec rake :task --silent :output"
# We need Rails to use our own environment
job_type :runner, "cd :path && govuk_setenv whitehall script/rails runner -e :environment ':task' :output"

# Run every SCHEDULED_PUBLISHING_PRECISION_IN_MINUTES minutes, 2 minutes before the due moment
# this allows the the ruby process (and rails) time to boot up. The scheduler then sleeps until
# the edition is due
every '13,28,43,58 * * * *', roles: [:backend] do
  rake "publishing:due:publish"
end

## 14:45 is during our regular release slot, this may have to change
## post-April. 2am is our regular time for this.
every :day, at: ['2am', '2:45pm'], roles: [:admin] do
  runner 'script/dump_all_admin_to_public_documents_and_non_documents.rb'
end
