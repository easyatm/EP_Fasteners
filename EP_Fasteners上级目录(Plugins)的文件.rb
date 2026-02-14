# Copyright 2015 Eye Physics and Jay Watson
#
# Create Bolts, Screws, Washers, Tapped holes, drilled holes and nuts 
# in standard sizes as components, that should print as workable parts.
#
# 2.01.2015  Jay Watson, Eye Physics
#-----------------------------------------------------------------------------

require "sketchup.rb"
require "extensions.rb"

module EP
  module EPFasteners

    # Create the extension.
    loader = File.join(File.dirname(__FILE__), "EP_Fasteners", "EPFasteners.rb")
    extension = SketchupExtension.new("EP Fasteners Tool", loader)
    extension.description = "Creates Standard bolts, nuts and threaded holes"
    extension.version     = "1.02"
    extension.creator     = "Jay Watson"
    extension.copyright   = "2015, Eye Physics, llc and " <<
                            "Jay Watson"

    # Register the extension with Sketchup so it show up in the Preference panel.
    Sketchup.register_extension(extension, true)

  end # module Fasteners
end # module EP
