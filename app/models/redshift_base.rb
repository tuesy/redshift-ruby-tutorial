class RedshiftBase < ActiveRecord::Base
  establish_connection Rails.application.secrets.redshift_config
  self.abstract_class = true
end
