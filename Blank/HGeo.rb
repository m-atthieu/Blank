#
#  HGeo.rb
#  Blank
#
#  Created by Matthieu DESILE on 9/13/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#


require 'rubygems'
require 'sqlite3'
require 'mini_exiftool'

class HGeo
    @@docs = "/Volumes/Users/furai/Documents/HoudaGeo"
    
    def initialize date
        path = "#{@@docs}/#{date}.hgeo"
        if ! File.exists?(path) then 
            HGeo.initialize_database path 
        end
        @database = SQLite3::Database.new path
    end
    
    def check filename
        basename = File.basename(filename)
        info = HGeo.info filename
        if exists?(basename) then
            unless same_tuple?(filename, info)
                update filename, info
            end
        else
            insert filename, info
        end
    end
    
    def self.global_check(year=nil)
        sql_all = 'select count(*) from zabstractpoint'
        sql_geo = 'select count(*) from zabstractpoint where zlongitude is not null and zlatitude is not null'
        if year.nil? then
            re = Regexp.new "\.hgeo$"
        elsif year.length == 4 then
            re = Regexp.new "#{year}.*\.hgeo$"
        else
            re = Regexp.new "#{year}\.hgeo$"
        end
        Find.find(@@docs).each do |hgeo|
            if re.match(hgeo) then
                conn = SQLite3::Database.new hgeo
                all = conn.get_first_value(sql_all)
                geo = conn.get_first_value(sql_geo)
                print "#{File.basename(hgeo)};#{geo};#{all}\n"
                #p "#{hgeo} all : #{all}, geo : #{geo}"
                ratio = geo / all.to_f
                if ratio == 0 then
                    setFileColorLabel hgeo, 'red'
                elsif ratio < 0.5 then
                    setFileColorLabel hgeo, 'orange'
                elsif ratio < 1 then
                    setFileColorLabel hgeo, 'yellow'
                elsif geo == all then
                    setFileColorLabel hgeo, 'green'
                end
                conn.close
            end
        end
    end
    
    private
    
    attr_accessor :database
    
    def insert filename, info
        id = get_new_id
        values = [id, 2, 1, 0, File.expand_path(filename), File.basename(filename), info['Location'], info['City'], info['Country'], info['DateTimeOriginal']]
        @database.execute("insert into zabstractpoint(z_pk, z_ent, z_opt, zautomatic, zpath, zname, zlocation, zcity, zcountry, ztimestamp) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", values)
        #@database.commit
        print "inserting #{values}\n"
    end
    
    def update filename, info
        values = [File.expand_path(filename), info['Location'], info['City'], info['Country'], info['DateTimeOriginal'], get_id(filename)]
        print "updating #{values}\n"
        @database.execute("update zabstractpoint set zpath = ?, zlocation = ?, zcity = ?, zcountry = ?, ztimestamp = ? where z_pk = ?", values)
        #@database.commit
    end
    
    def get_id filename
        @database.get_first_value('select z_pk from zabstractpoint where zname = ?', [File.basename(filename)])
    end
    
    def get_new_id
        id = @database.get_first_value('select z_max + 1 from z_primarykey where z_name = ?', 'AbstractPoint')
        @database.execute('update z_primarykey set z_max = ? where z_name = ?', [id, 'AbstractPoint'])
        #@database.commit
        return id
    end
    
    def exists?(filename)
        row = @database.get_first_value('select count(zname) from zabstractpoint where zname = ?', [filename])
        #p "#{filename} : #{row}"
        return (row != 0)
    end
    
    def same_path?(filename)
        row = @database.get_first_value('select zpath from zabstractpoint where zname = ?', [File.basename(filename)])
        return (row == filename)
    end
    
    def same_tuple?(filename, info)
        basename = File.basename(filename)
        row = @database.get_first_row("select zpath, zname, zlocation, zcity, zcountry, ztimestamp from zabstractpoint where zname = ?", basename)
        return (info['Location'] == row[2] and info['City'] == row[3] and info['Country'] == row[4] and info['DateTimeOriginal'] == row[5] and filename == row[0])
    end
    
    #
    # Static methods
    #
    
    def self.initialize_database path
        conn = SQLite3::Database.new path
        SCHEMA.each do |sql|
            conn.execute(sql)
        end
        DATA.each do |sql|
            conn.execute(sql)
        end
        conn.close
    end

    def self.info filename
        m = MiniExiftool.new(filename).to_hash
        ext = File.extname(filename)
        xmp = filename.gsub(ext, '.xmp')
        if File.exists?(xmp) then
            #p "scanning #{xmp}"
            x = MiniExiftool.new(xmp).to_hash
            m.merge!(x)
        end
        ts = Time.local(2001,1,1, 0,0,0, "+01:00")
        m['DateTimeOriginal'] = m['DateTimeOriginal'].to_i - ts.to_i
        return m
    end

    

    @@colors = { 
        'none' => 0,
        'grey' => 1,
        'green' => 2, #NSColor.greenColor, 
        'lilas' => 3,
        'blue' => 4,
        'yellow' => 5,
        'red' => 6, #NSColor.redColor, 
        'orange' => 7 #NSColor.orangeColor 
    }

    def self.setFileColorLabel filename, color_name
        url = NSURL.fileURLWithPath filename
        #p "#{filename} : #{color_name}"
        url.setResourceValue(@@colors[color_name], forKey: NSURLLabelNumberKey, error: nil)
    end

end