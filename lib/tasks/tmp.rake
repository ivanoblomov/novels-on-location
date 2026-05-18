# frozen_string_literal: true

namespace :tmp do
  task clear: :environment do
    capybara_dir = Rails.root.join('tmp/capybara')

    if Dir.exist?(capybara_dir)
      files = Dir.glob("#{capybara_dir}/*")

      unless files.empty?
        FileUtils.rm_rf(files)
        puts "Cleared #{capybara_dir} (#{files.size} items removed)"
      end
    end
  end
end
