#
#  Blank.rb
#  Blank
#
#  Created by Matthieu DESILE on 9/13/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#

require 'find'

framework 'Cocoa'

class Blank
    @@base = "/Volumes/Users/furai/Powo"
    attr_accessor :base, :connections
    
    def initialize
        @connections = Hash.new
    end
    
    def scan(year=nil)
        if year.nil? then
            image_re = Regexp.new "([0-9]{4})/([0-9]{2})/.*/([^/]+\.(tif|jpg|nef|rw2))$", true
        elsif year.length == 4 then
            image_re = Regexp.new "(#{year})/([0-9]{2})/.*/([^/]+\.(tif|jpg|nef|rw2))$", true
        else
            dateparts = year.split('-')
            image_re = Regexp.new "(#{dateparts[0]})/(#{dateparts[1]})/.*/([^/]+\.(tif|jpg|nef|rw2))$", true
            #p image_re
        end
        ['photo', 'pano', 'hdr'].each do |dir|
            # ce serait plus facile de restreindre à la date ici, mais moins souple
            Find.find "#{@@base}/#{dir}" do |filename|
                if image_re.match filename then
                    date = "#{Regexp.last_match[1]}-#{Regexp.last_match[2]}"
                    image = Regexp.last_match[3]
                    check date, filename
                end
            end
            GC.start
        end
    end
    
    private
    
    def check date, filename
        if @connections[date].nil? then
            @connections[date] = HGeo.new date
        end
        @connections[date].check filename
    end
    
end

def get_options
    opts = GetoptLong.new(
        ['--global-check', '-g', GetoptLong::NO_ARGUMENT],
        ['--no-scan', '-n', GetoptLong::NO_ARGUMENT])
    a = { 'scan' => true, 'date' => nil, 'global' => false }
    opts.each do |opt, arg|
        case opt
            when '--global-check'
            a['global'] = true
            when '--no-scan'
            a['scan'] = false
        end
    end
    if ARGV.length >= 1 then
        a['date'] = ARGV.shift
    end
    return a
end

if __FILE__ == $0 then
    require 'getoptlong'
    require './BlankSqlite'
    require './HGeo'
    
    opt = get_options
    if opt['scan'] then
        Blank.new.scan opt['date']
    end
    if opt['global'] then
        HGeo.global_check opt['date']
    end
end
