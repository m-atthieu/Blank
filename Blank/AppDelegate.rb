#
#  AppDelegate.rb
#  Blank
#
#  Created by Matthieu DESILE on 9/11/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#

require 'find'

class AppDelegate
    attr_accessor :window, :base, :docs
    
    def initialize
        @docs = "/Volumes/Users/furai/Documents/HoudaGeo"
        @base = "/Volumes/Users/furai/Powo"
    end
    
    def applicationDidFinishLaunching(a_notification)
        f = FileColorSetter.new "/Volumes/Users/furai/Documents/HoudaGeo/2004-11.hgeo"
    end
end

