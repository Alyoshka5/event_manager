require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def check_phone_number(phone_number)
    return if phone_number.nil?
    phone_number.gsub!(/[ ()-.]/, '')
    if phone_number.length == 10
        phone_number
    elsif phone_number.length == 11 && phone_number[0] == '1'
        phone_number[1..-1]
    else
        "invalid number"
    end
end

def get_hour(date)
    date.split(" ")[1].split(":")[0]
end

def get_day(date)
    date = date.split(" ")[0].split("/")
    month = date[0].to_i
    day_of_month = date[1].to_i
    year = "20#{date[2]}".to_i
    Date.new(year, month, day_of_month).wday
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    begin
        legislators = civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')
    filename = "output/thanks_#{id}.html"
    File.open(filename, 'w') {|file| file.puts form_letter}
end

def get_peak(reg)
    peak_key = []
    peak_count = 0
    reg.each do |key, count|
        if count == peak_count
            peak_key.push(key)
        elsif count > peak_count
            peak_key = [key]
            peak_count = count
        end
    end
    peak_key
end

puts 'EventManager Initialized.'
reg_hours = Hash.new(0)
reg_days = Hash.new(0)

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter
contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phone_number = check_phone_number(row[:homephone])
    hour = get_hour(row[:regdate])
    reg_hours[hour] = 0 if reg_hours[hour] == nil
    reg_hours[hour] += 1
    day = get_day(row[:regdate])
    reg_days[day] = 0 if reg_days[day] == nil
    reg_days[day] += 1
    legislators = legislators_by_zipcode(zipcode)
    
    form_letter = erb_template.result(binding)
    save_thank_you_letter(id, form_letter)
end

peak_hours = get_peak(reg_hours)
p peak_hours
peak_days = get_peak(reg_days)
p peak_days