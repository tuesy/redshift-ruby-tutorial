# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
User.delete_all
%w(Data Jordi Will Jean-Luc Beverley Worf).each do |x|
  user = User.new
  user.name = x
  user.email = "#{x.downcase}@enterprise.fed"
  user.save!
end
