namespace :sync do
  desc 'Synchronizes local database with production'
  task :local => :backup do
    system "mongorestore -d #{Rails.application.config.mongoid.database.name} -h localhost --drop db/backups/#{Rails.application.config.production_mongohq_db}/"
  end

  task :backup => :environment do
    system "mongodump -d #{Rails.application.config.production_mongohq_db} -h flame.mongohq.com:#{Rails.application.config.production_mongohq_port} -o db/backups -p #{Rails.application.config.production_mongohq_password} -u heroku"
  end
end
