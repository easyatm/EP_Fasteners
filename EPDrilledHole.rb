# Copyright 2015 Eye Physics and Jay Watson
# 版权 2015 Eye Physics 和 Jay Watson
#
# Create Bolts, Screws, Washers, Tapped holes, drilled holes and nuts
# 创建螺栓、螺丝、垫圈、攻丝孔、钻孔和螺母
# in standard sizes as components, that should print as workable parts.
# 以标准尺寸作为组件，应可打印为可工作的零件。
#
# 2.01.2015  Jay Watson, Eye Physics
#-----------------------------------------------------------------------------

require "sketchup.rb"
require_relative "EPFastenerConstants"

module EP
module EPFasteners
#============================================================================
class EPDrilledHole < EPFastenerConstants
#============================================================================
#---------------------------------------------------------------------------------------------------------
   def self.create(modelunits)
      @@UNITS = modelunits
      if !defined? @@PREVUNITS
          @@PREVUNITS = "UNK"
      end

      @@ZERO = 0.0.to_l

      if defined? @@DrillSize
         if @@UNITS != @@PREVUNITS 
            remove_class_variable(:@@DrillSize)		#If changing units reinitialize
            @@PREVUNITS = @@UNITS
         end
      end

      if !defined? @@DrillSize
         if @@UNITS == "SAE"
             @@DrillSize = "0.250"
             @@Length = "1.00"
         else
             @@DrillSize = "4.0"
             @@Length = "30"
         end
         @@ThruHole = "Yes"
         @@TPI = "Coarse"
         @@Head   = "Hex"
         @@Fullthread = "Yes"
         @@Inclwasher = "No"
      end
      @@PREVUNITS = @@UNITS

      self.showDialog()
   end
#---------------------------------------------------------------------------------------------------------
   def self.continue
      model = Sketchup.active_model

         #Does this Hole exist in the model already?
         # 此孔是否已经在模型中存在？
         #
         #partname = "EP Drilled Hole #{@drillsize}..."
         defn = Sketchup.active_model.definitions[self.partname]
         if defn.nil?
            model.start_operation(self.partname, true)
            ahole = EPDrilledHole.new
            container= ahole.create_entity(model)
            if container.nil?
               model.abort_operation
               return
            end
            ahole.create_entities(container)
            model.commit_operation
            defn = ahole.entity
         end
         #
         self.closeDialog   
         Sketchup.active_model.place_component(defn, false)

   end
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
   def self.InitializeDialog
      @@dialog = UI::WebDialog.new("EP Drilled Hole", true, "", 550, 400, 200, 200, false )
      @@dialog.add_action_callback("ruby_OKPressed") {|dialog,params| self.performOK(params)}
      @@dialog.add_action_callback("ruby_CANCELPressed") {self.performCancel()}
      @@dialog.add_action_callback("ruby_Continue") {self.continue()}
      @@dialog.add_action_callback("ruby_DocumentReady") {self.performLoadVars()}
   end

#---------------------------------------------------------------------------------------------------------
def self.performLoadVars()
puts @@DrillSize
   js_command = "setSize('#{@@DrillSize}'); $('#cbCustom').click();"
   @@dialog.execute_script(js_command)

   js_command = "$(\"#LENGTH\").val('#{@@Length}');"
   @@dialog.execute_script(js_command)

   thruholetype = @@ThruHole=="Yes"?"ThruHole":"Hole"
   js_command = "setHoleType('#{thruholetype}');"
   @@dialog.execute_script(js_command)

end

#---------------------------------------------------------------------------------------------------------
def self.performOK(*params)

   p = params[0].split(";")
   p = p.map{|e| e.split("=")}
   p.each { |e|
      case e[0]
         when "bs"
            @@DrillSize = EPDrilledHole::cLength(e[1], @@UNITS)
         when "ln"
            @@Length = EPDrilledHole::cLength(e[1], @@UNITS)
         when "ht"
            @@ThruHole = e[1]=="ThruHole" ? "Yes" : "No"
      end
   }
   @@Diam  = @@DrillSize
   
   if @@DrillSize < 0.0 
      js_command = "setError('Size', 'Invalid Size Specified');"
   elsif @@Length < 0.0 
       js_command = "setError('Length','Invalid Length Specified');"
   else
      js_command = "setStatus('#{self.partname}');"
   end
   @@dialog.execute_script(js_command)
end

#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
   def self.performCancel(*params)
      self.closeDialog()
   end

#---------------------------------------------------------------------------------------------------------
   def self.showDialog()
      if !defined?@@dialog
         self.InitializeDialog()
      end

      if @@UNITS == "SAE"
          @@HTMLFile = "#{__dir__}\\HTML\\SAEDrilledHole.html".gsub("/","\\")
      else
          @@HTMLFile = "#{__dir__}\\HTML\\MetricDrilledHole.html".gsub("/","\\")
      end
      @@dialog.set_file(@@HTMLFile)

      @@dialog.show()
   end

#---------------------------------------------------------------------------------------------------------
   def self.closeDialog()
      if defined?@@dialog
         @@dialog.close()
      end
   end

#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
   def self.partname()
      helper = ""
      if @@ThruHole == "Yes" && @@Length == @@ZERO
         #Build the helper and create the hole when helper is instantiated.
         # 当助手被实例化时构建助手并创建孔。
         @@Length = @@ZERO
         helper = "Helper "
      end

      "EP钻孔 #{helper}#{@@DrillSize}-#{@@Length}-#{@@ThruHole} "
   end
#---------------------------------------------------------------------------------------------------------
   def partname()
      helper = ""
      if @thruhole == "Yes" && @length == @@ZERO
         #Build the helper and create the hole when helper is instantiated.
         # 当助手被实例化时构建助手并创建孔。
         @length = @@ZERO
         helper = "Helper "
      end
      
      "EP钻孔 #{helper}#{@drillsize}-#{@length}-#{@thruhole} "
   end
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
   def initialize

      @model    = Sketchup.active_model
      @drillsize= @@DrillSize
      @length   = @@Length
      @thruhole = @@ThruHole
      @diam     = @@Diam

    end

#---------------------------------------------------------------------------------------------------------
   def create_entities( container)
     draw_me( container)
   end

#---------------------------------------------------------------------------------------------------------
   def create(instance, length)
      @@ZERO = "0.00\"".to_l
      @@DrillSize = instance.get_attribute "Fastener", "DrillSize", @@DrillSize
      @@Diam = instance.get_attribute "Fastener", "Diam", @@Diam
      @@ThruHole = instance.get_attribute "Fastener", "ThruHole", @@ThruHole

      @@Length     = length

      @model    = Sketchup.active_model
      @drillsize = @@DrillSize
      @length   = @@Length.to_l
      @thruhole = @@ThruHole
      @diam     = @@Diam.to_l
      defn      = ""

      #Does this Hole exist in the model already?
      # 此孔是否已经在模型中存在？
      #
      #partname = "EP Drilled Hole #{@drillsize}"
      defn = Sketchup.active_model.definitions[partname]
      if defn.nil?

         entity = create_entity(@model)
         create_entities(entity)
         defn = entity
      end

      @@Length = @@ZERO         #reset to automatic through holes...
      return defn
   end
#---------------------------------------------------------------------------------------------------------
   def create_entity(model)
      @entity = model.definitions.add(partname)
   end

#---------------------------------------------------------------------------------------------------------
   def entity
      @entity
   end

#---------------------------------------------------------------------------------------------------------
   def draw_me( container)
      puts "create_drilled_hole d=#{@diam}  l=#{@length}"

      scale = 1.0
      d = @diam * scale 
      l = @length * scale

      if @thruhole == "Yes" && @length == @@ZERO
         #Build the helper and create the hole when helper is instantiated.
         # 当助手被实例化时构建助手并创建孔。
         @length = @@ZERO
         create_helper(d, container)
      else
         hole = create_drilled_hole(l, d, scale, container)
      end
   end

#---------------------------------------------------------------------------------------------------------
   def create_helper(diam, container)
      #Place the opening and then build the hole once we find the other side with another component...
      # 放置开口，然后一旦我们用另一个组件找到另一侧就构建孔...

      numberofarcsegments = @@NumberOfArcSegments
      angle = (2 * Math::PI) / numberofarcsegments
      vr = Geom::Vector3d.new(0,0,1)
      tr = Geom::Transformation.rotation([0,0,0], vr, 0.0 - angle)
      p = []
      p << Geom::Point3d.new(0.0 - (diam/2.0), 0.0, 0.0)
      for i in 0..(numberofarcsegments - 2)
         p << p[i].transform(tr)
      end
      face = container.entities.add_face p
      container.entities.erase_entities face			#Keep just the edges
      container.behavior.is2d = true
      container.behavior.snapto = SnapTo_Arbitrary
      container.behavior.cuts_opening = true
      container.behavior.no_scale_mask = 127
      container.description = "EP Drilled Hole Helper for #{@drillsize}"
      container.insertion_point = Geom::Point3d.new(0.00,0.00,0.0)
      container.set_attribute "Fastener","Helper", "EP::EPFasteners::EPDrilledHole"
      container.set_attribute "Fastener","Length", @@ZERO
      container.set_attribute "Fastener", "DrillSize", @drillsize
      container.set_attribute "Fastener", "Diam", @diam
      container.set_attribute "Fastener", "ThruHole", @thruhole
   end

   #---------------------------------------------------------------------------------------------------------
   def create_drilled_hole(length, diam, scale, container)
      numberofarcsegments = @@NumberOfArcSegments
      pm = Geom::PolygonMesh.new

      angle = (2 * Math::PI) / numberofarcsegments
      vr = Geom::Vector3d.new(0,0,1)
      vl = Geom::Vector3d.new(0, 0, 0.0 - length)
      tr = Geom::Transformation.rotation([0,0,0], vr, 0.0 - angle)
      tl = Geom::Transformation.translation(vl)

      p = []
      pe = []
      p << Geom::Point3d.new( 0.0 - (diam/2.0),0.0,0.0)
      pe << p[0].transform(tl)

      for i in 0..(numberofarcsegments - 2)
         p  << p[i].transform(tr)
         pe << pe[i].transform(tr)
      end

      p1 = p[-1]
      p2 = pe[-1]
      for i in 0..(p.length()-1)
         p3 = p[i]
         p4 = pe[i]
         pm.add_polygon(p1, p2, p3)
         pm.add_polygon(p2, p4, p3)
         p1 = p3
         p2 = p4
      end
   
      # Generate the faces ---------------------------------------------------------------------------------------------

      grp = container.entities.add_group
      grp.entities.add_faces_from_mesh(pm)
  
      if @thruhole == "No"
         edges = grp.entities.select { |e| e.typename == "Edge" &&  e.start.position.z == (0.0 - length) && e.end.position.z == (0.0 - length) }
         edges[0].find_faces if edges.count > 0
      end
  
      newscale = 1.0000000 / scale
      t = Geom::Transformation.scaling newscale
      grp.transformation = t * grp.transformation
      grp.explode
  
      container.behavior.is2d = true
      container.behavior.snapto = SnapTo_Arbitrary
      container.behavior.cuts_opening = true
      container.behavior.no_scale_mask = 127
      container.description = "EP Drilled Hole #{@drillsize} Len=#{@length} Thru=#{@thruhole}"
      container.insertion_point = Geom::Point3d.new(0.00,0.00,0.00)
   end

end  #class
#=============================================================================

end #module EPFasteners
end #module EP