# 版权 2015 Eye Physics 和 Jay Watson
# Copyright 2015 Eye Physics and Jay Watson
#
# 创建标准尺寸的螺栓、螺丝、垫圈、攻丝孔、钻孔和螺母作为组件，应该可以打印为可工作的零件。
# Create Bolts, Screws, Washers, Tapped holes, drilled holes and nuts 
# in standard sizes as components, that should print as workable parts.
#
# 2.01.2015  Jay Watson, Eye Physics
#-----------------------------------------------------------------------------

require "sketchup.rb"
require_relative "EPFastenerConstants"
require_relative "EPWasher"
require_relative "EPTappedHole"
require_relative "EPBolt"
require_relative "EPNut"
require_relative "EPDrilledHole"

module EP
module EPFasteners
#=============================================================================
class EPFastenersMenu 
#=============================================================================
#---------------------------------------------------------------------------------------------------------
   def self.create
      self.showDialog()
   end

#---------------------------------------------------------------------------------------------------------
   def self.continue
      self.closeDialog()

      puts "continue #{@@Function} in #{@@MeasurementType} "

      case @@Function
          when "DRILLEDHOLE"
              EP::EPFasteners::EPDrilledHole.create(@@MeasurementType)
          when "TAPPEDHOLE"
              EP::EPFasteners::EPTappedHole.create(@@MeasurementType)
          when "BOLT"
              EP::EPFasteners::EPBolt.create(@@MeasurementType)
          when "NUT"
              EP::EPFasteners::EPNut.create(@@MeasurementType)
          when "WASHER"
              EP::EPFasteners::EPWasher.create(@@MeasurementType)
      end
   end
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
   def self.InitializeDialog
      @@dialog = UI::WebDialog.new("创建标准螺栓/螺母/打孔", true, "", 550, 530, 200, 200, false )
      @@HTMLFile = "#{__dir__}\\HTML\\EP_Fasteners.html".gsub("/","\\")
      @@dialog.set_file(@@HTMLFile)
      @@dialog.add_action_callback("ruby_OKPressed") {|dialog,params| self.performOK(params)}
      @@dialog.add_action_callback("ruby_CANCELPressed") {self.performCancel()}
      @@dialog.add_action_callback("ruby_Continue") {self.continue()}
      @@dialog.add_action_callback("ruby_DocumentReady") {self.performLoadVars()}
   end


#---------------------------------------------------------------------------------------------------------
   def self.performLoadVars()

      if !defined? @@MeasurementType
         @@MeasurementType = "Metric"
         @@Function = "Unknown?"
      end

      js_command = "setMeasurementType('#{@@MeasurementType}');"
      puts js_command
      @@dialog.execute_script(js_command)
   end

#---------------------------------------------------------------------------------------------------------
   def self.performOK(*params)

      p = params[0].split(";")
      p = p.map{|e| e.split("=")}
      p.each { |e|
         case e[0]
            when "me"
               @@MeasurementType = e[1]
            when "fn"
               @@Function = e[1]
         end
      }
  
      js_command = "setStatus('Creating a #{@@MeasurementType} #{@@Function}');"
      puts js_command
      @@dialog.execute_script(js_command)

   end

#---------------------------------------------------------------------------------------------------------
   def self.performCancel(*params)

      self.closeDialog()
   end

#---------------------------------------------------------------------------------------------------------
   def self.showDialog()
      if !defined?@@dialog
         self.InitializeDialog()
      end

      @@dialog.show()
   end

#---------------------------------------------------------------------------------------------------------
   def self.closeDialog()
      if defined?@@dialog
         @@dialog.close()
      end
   end

   def checkme()
      puts "OK"
   end
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------

end #class
end #module
end #module