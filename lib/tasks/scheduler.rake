desc "Remove DB records"
puts "cleaning up"
task delete_10_minutes_old: :environment do
    Character.where(user_id: nil).destroy_all
end