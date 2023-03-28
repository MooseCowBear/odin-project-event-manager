puts 'Event Manager Initialized!'

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(number)
  number = number.delete('^0-9')
  if number.length == 10 || (number.length == 11 && number.start_with?("1"))
    number.to_s[-10..-1]
  else
    ''.rjust(10, '0')
  end
end

def get_hour(date) #helper methods
  date.hour
end

def get_weekday(date)
  date.wday
end

def convert_weekday(num)
  day = case num
        when 0 then "Sunday"
        when 1 then "Monday"
        when 2 then "Tuesday"
        when 3 then "Wednesday"
        when 4 then "Thursday"
        when 5 then "Friday"
        else "Saturday"
        end
end

def most_popular(dates, num, type)
  dates.map { |elem| type.call(elem) }.tally.sort_by { |k, v| v }.reverse
  .map { |k, v| k }[0...num]
end

def most_popular_hours(dates, num)
  most_popular(dates, num, method(:get_hour))
end

def most_popular_days(dates, num)
  most_popular(dates, num, method(:get_weekday)).map { |elem| convert_weekday(elem) }
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_datetimes = Array.new

contents.each do |row|
  id = row[0] #bc col had no name
  name = row[:first_name]
  phone_number = row[:homephone]

  phone_number = clean_phone_number(phone_number)

  registration_datetimes.push(DateTime.strptime(row[:regdate], '%m/%d/%y %k:%M'))

  puts "#{name}'s phone number is #{phone_number}"

  #zipcode = clean_zipcode(row[:zipcode])

  #legislators = legislators_by_zipcode(zipcode)

  #form_letter = erb_template.result(binding)
  
  #save_thank_you_letter(id, form_letter)

end

top_hours = most_popular_hours(registration_datetimes, 2)
puts top_hours

top_days = most_popular_days(registration_datetimes, 2)
puts top_days