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

#=============================================================================
class EPTappedHole < EPFastenerConstants
#=============================================================================
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
   def self.create(modelunits)
      @@UNITS = modelunits
      if !defined? @@PREVUNITS
          @@PREVUNITS = "UNK"
      end

      @@ZERO = "0.0".to_l

      if defined? @@Boltsize
         if @@UNITS != @@PREVUNITS 
            remove_class_variable(:@@BOLTSIZE)		#If changing units reinitialize
            @@PREVUNITS = @@UNITS
         end
      end

      if !defined? @@BoltSize
         if @@UNITS == "SAE"
             @@BoltSize = "#10"
             @@Length = "1.00"
         else
             @@BoltSize = "M8"
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
         #partname = "Tapped Hole #{@boltsize}..."
         defn = Sketchup.active_model.definitions[self.partname]
         if defn.nil?
            model.start_operation(self.partname, true)
            utshole = EPTappedHole.new
            container= utshole.create_entity(model)
            if container.nil?
               model.abort_operation
               return
            end
            utshole.create_entities(container)
            model.commit_operation
            defn = utshole.entity
         end
         #
         self.closeDialog   
         Sketchup.active_model.place_component(defn, false)

   end
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
   def self.InitializeDialog
      @@dialog = UI::WebDialog.new("SAE Tapped Hole", true, "", 550, 400, 200, 200, false )
      @@dialog.add_action_callback("ruby_OKPressed") {|dialog,params| self.performOK(params)}
      @@dialog.add_action_callback("ruby_CANCELPressed") {self.performCancel()}
      @@dialog.add_action_callback("ruby_Continue") {self.continue()}
      @@dialog.add_action_callback("ruby_DocumentReady") {self.performLoadVars()}
   end


#---------------------------------------------------------------------------------------------------------
def self.performLoadVars()

   js_command = "$(\"#BOLTSIZE\").val('#{@@BoltSize}');"
   @@dialog.execute_script(js_command)

   js_command = "setThreadType('#{@@TPI}');"
   @@dialog.execute_script(js_command)

   js_command = "$(\"#LENGTH\").val('#{@@Length}');"
   @@dialog.execute_script(js_command)

   thruholetype = (@@ThruHole=="Yes"?"ThruHole":"Hole")
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
            @@BoltSize = e[1]
         when "ln"
            @@Length = EPTappedHole::cLength(e[1], @@UNITS)
         when "ht"
            @@ThruHole = (e[1]=="ThruHole" ? "Yes" : "No")
         when "tt"
            @@TPI = e[1]
     end
   }

   die  = @@UTS.select {|s| s[0]==@@BoltSize && s[1]==@@TPI}

   @@Pitch = die[0][2].to_l
   @@Diam = die[0][3].to_l
  
   if @@Length < 0.0 
       js_command = "setError('Length','Invalid Length Specified');"
   else
      js_command = "setStatus('#{self.partname}');"
   end
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

      if @@UNITS == "SAE"
          @@HTMLFile = "#{__dir__}\\HTML\\SAETappedHole.html".gsub("/","\\")
      else
          @@HTMLFile = "#{__dir__}\\HTML\\MetricTappedHole.html".gsub("/","\\")
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

      "EP螺纹孔 #{helper}#{@@BoltSize}-#{@@TPI}-#{@@Length}-#{@@ThruHole} "
   end
#---------------------------------------------------------------------------------------------------------
   def partname()
      helper = ""
      if @thruhole == "Yes" && @length.to_l == @@ZERO
         #Build the helper and create the hole when helper is instantiated.
         # 当助手被实例化时构建助手并创建孔。
         @length = @@ZERO
         helper = "Helper "
      end

      "EP螺纹孔 #{helper}#{@boltsize}-#{@tpi}-#{@length.to_l}-#{@thruhole} "
   end

#---------------------------------------------------------------------------------------------------------
   def helper_partname()
      length = @length.to_l
      thruhole = @thruhole
      @thruhole = "Yes" 
      @length = @@ZERO

      hpn = partname

      @length = length
      @thruhole = thruhole
 
      return hpn
   end

#---------------------------------------------------------------------------------------------------------
   def initialize
        @model    = Sketchup.active_model
        @boltsize = @@BoltSize
        @tpi      = @@TPI 
        @length   = @@Length.to_l
        @thruhole = @@ThruHole
        @pitch    = @@Pitch
        @diam     = @@Diam

    end

#---------------------------------------------------------------------------------------------------------
   def create_entities( container)
     draw_me( container)
   end

#---------------------------------------------------------------------------------------------------------
#  Called by the InstancePlace observer to create a threaded hole of the correct length
#  被InstancePlace观察者调用以创建正确长度的螺纹孔
#
   def create(instance, length)
      @@ZERO = "0.0".to_l
      @@BoltSize = instance.get_attribute "Fastener", "BoltSize", @@BoltSize
      @@TPI = instance.get_attribute "Fastener", "TPI", @@TPI
      @@ThruHole = instance.get_attribute "Fastener", "ThruHole", @@ThruHole
      @@Pitch = instance.get_attribute "Fastener", "Pitch", @@Pitch
      @@Diam = instance.get_attribute "Fastener", "Diam", @@Diam

      @@Length     = length

      @model    = Sketchup.active_model
      @boltsize = @@BoltSize
      @tpi      = @@TPI 
      @length   = @@Length.to_l
      @thruhole = @@ThruHole
      @pitch    = @@Pitch
      @diam     = @@Diam
      defn      = ""

      #Does this Hole exist in the model already?
      # 此孔是否已经在模型中存在？
      #
      #partname = "Tapped Hole #{@boltsize}"
      defn = Sketchup.active_model.definitions[partname]
      if defn.nil?
         entity = create_entity(@model)
         create_entities(entity)
         defn = entity
      end
      @@Length = @@ZERO       #reset to automatic through holes...

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

      scale = 1.0
      d = @diam.to_l * scale 
      p = @pitch.to_l  * scale 
      l = @length.to_l  * scale

      dmin = d - (1.082532 * p)    #defined in UTS standard see: wiki UTS or Metric thread
      p8 = p / 2                   # number of 16ths
      p4 = p / 4
      p2 = p / 8
      p1 = p / 16
      dmaj2 = d / 2
      dmin2 = dmin / 2
      sin60 = 0.866025			
      cos60 = 0.500000
      arcCons = p1 / 1.732050	# Solves the radius of the arc at the bottom of each thread
      arcCenter = [dmaj2 - arcCons,0,0]
      radius = 2 * arcCons
      points = []
      points << Geom::Point3d.new(arcCenter[0] + radius,         @@ZERO, @@ZERO - (@@ZERO                 )) #    1 (
      points << Geom::Point3d.new(arcCenter[0] + sin60 * radius, @@ZERO, @@ZERO - (@@ZERO + cos60 * radius)) #    2  (
      points << Geom::Point3d.new(dmaj2,                         @@ZERO, @@ZERO - (p1                  ))    #    3   \
      points << Geom::Point3d.new(dmin2,                         @@ZERO, @@ZERO - (p4 + p2             ))    #    4    |
      points << Geom::Point3d.new(dmin2,                         @@ZERO, @@ZERO - (p8 + p2             ))    #    5    |
      points << Geom::Point3d.new(dmaj2,                         @@ZERO, @@ZERO - (p - p1              ))    #    6   /
      points << Geom::Point3d.new(arcCenter[0] + sin60 * radius, @@ZERO, @@ZERO - (p - cos60 * radius  ))    #    7  (
      points << Geom::Point3d.new(arcCenter[0] + radius,         @@ZERO, @@ZERO - (p                   ))    #    8 (
     
      if @thruhole == "Yes" && @length.to_l == @@ZERO
         #Build the helper and create the hole when the helper is instantiated.
         # 当助手被实例化时构建助手并创建孔。
         @length = @@ZERO
         create_helper(d + radius, container)    # end result is diam + 2 * H/8
      else
         hole = create_tapped_hole(points, l, d, p, scale, container)
      end
   end

#---------------------------------------------------------------------------------------------------------
   def create_helper(diam, container)
      #Place the opening and then build the tapped hole once we find the other side with another component...
      # 放置开口，然后一旦我们用另一个组件找到另一侧就构建螺纹孔...
 
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
      container.description = "EP Tapped Hole Helper for #{@boltsize}-#{@tpi}"
      container.insertion_point = Geom::Point3d.new(0.00,0.00,0.0)
      container.set_attribute "Fastener","Helper", "EP::EPFasteners::EPTappedHole"
      container.set_attribute "Fastener","Length", @@ZERO
      container.set_attribute "Fastener", "BoltSize", @boltsize
      container.set_attribute "Fastener", "Diam", @diam
      container.set_attribute "Fastener", "TPI", @tpi
      container.set_attribute "Fastener", "Pitch", @pitch
      container.set_attribute "Fastener", "ThruHole", @thruhole
   end

  #---------------------------------------------------------------------------------------------------------
  def create_tapped_hole(points, length, diam, pitch, scale, container)
     numberofarcsegments = @@NumberOfArcSegments
     numberofsegments = (numberofarcsegments * ((length / pitch)))
     numberofsegments = numberofsegments - (3.0 * numberofarcsegments)
  
     angle = (2 * Math::PI) / numberofarcsegments
     offset = pitch / numberofarcsegments
  
     pm = Geom::PolygonMesh.new
     p1 = points[0]
     p2 = points[0]
     p3 = points[0]
     p4 = points[0]
  
     vr = Geom::Vector3d.new(0,0,1)
     vp = Geom::Vector3d.new(0,0, @@ZERO - offset)
     tr = Geom::Transformation.rotation([0,0,0], vr, 0.0 - angle)
     tp = Geom::Transformation.translation(vp)
     zmin = @@ZERO
  
     spoints = []
     tprev = Geom::Transformation.new
     pe1 = points[0]
     pb1 = points[0]
     pb3 = points[0]
     #Entry section of hole -------------------------------------------------------------------------------
     for j in 1..numberofarcsegments
        tcurr  = tprev * tp * tr
        points.each_with_index { |e,i|
           if (i+1) < points.length
              p1 = e.transform(tprev)
              p2 = points[i + 1].transform(tprev)
              p3 = e.transform(tcurr)
              p4 = points[i + 1].transform(tcurr)
  
              if (i == 0)
                 pb1 = p1.clone
                 pb3 = p3.clone
                 pb1.z = @@ZERO
                 pb3.z = @@ZERO
                 spoints << pb1
                 if (j == 1)
                    pe1 = pb1
                 end
                 pm.add_polygon(pb1, p1, pb3)
                 pm.add_polygon(p1, p3, pb3)
              end
   
              if j > 1
                 pm.add_polygon(p1, p2, p3)
                 pm.add_polygon(p2, p4, p3)
              else
                 # flatten the leadin
                 p1.x = pe1.x
                 p1.y = pe1.y
                 p2.x = pe1.x
                 p2.y = pe1.y
                 pm.add_polygon(p1, p2, p3)
                 pm.add_polygon(p2, p4, p3)
              end
           end
        }
        tprev = tcurr
  
     end
     spoints << pb3
  
     #Regular threaded section -------------------------------------------------------------------------------------
     for j in 1..numberofsegments   
        tcurr= tprev * tp * tr
        points.each_with_index { |e,i|
          if (i+1) < points.length
              p1 = e.transform(tprev)
              p2 = points[i + 1].transform(tprev)
              p3 = e.transform(tcurr)
              p4 = points[i + 1].transform(tcurr)
  
              pm.add_polygon(p1, p2, p3)
              pm.add_polygon(p2, p4, p3)
           end
        }
        tprev = tcurr
     end
  
  
     #Bottom section of hole --------------------------------------------------------------------------------------
     pc = Geom::Point3d.new(@@ZERO, @@ZERO, @@ZERO - length)
  
     for j in 1..numberofarcsegments
        tcurr  = tprev * tp * tr
        points.each_with_index { |e,i|
           if (i+1) < points.length
              p1 = e.transform(tprev)
              p2 = points[i + 1].transform(tprev)
              p3 = e.transform(tcurr)
              p4 = points[i + 1].transform(tcurr)
  
              if j < numberofarcsegments
                 pm.add_polygon(p1, p2, p3)
                 pm.add_polygon(p2, p4, p3)
              else
                 p3.x = pe1.x
                 p3.y = pe1.y
                 p4.x = pe1.x
                 p4.y = pe1.y
                 pm.add_polygon(p1, p2, p3)
                 pm.add_polygon(p2, p4, p3)
              end
  
              if (i+2) == points.length
                 p1 = p2.clone
                 p3 = p4.clone
                 p1.z = (@@ZERO - length)
                 p3.z = (@@ZERO - length)
  
                 if (j == 1)
                    pe1 = p1
                 end
                 pm.add_polygon(p2, p1, p3)
                 pm.add_polygon(p4, p2, p3)
              end
           end
        }
        tprev = tcurr
  
     end
  
  
     # Generate the faces ---------------------------------------------------------------------------------------------
     grp = container.entities.add_group
     grp.entities.add_faces_from_mesh(pm)
     edges = grp.entities.select { |e| e.typename == "Edge" &&  e.start.position.z == (@@ZERO - length) && e.end.position.z == (@@ZERO - length) }
     if @thruhole == "No"
        edges[0].find_faces if edges.count > 0
     else
        helpername = helper_partname
        container.set_attribute "Fastener","Helper",helpername
        container.set_attribute "Fastener","Length",length
     end

     newscale = 1.0000000 / scale
     if newscale != 1.000000 then
        t = Geom::Transformation.scaling newscale
        grp.transformation = t * grp.transformation
     end
     grp.explode

     container.behavior.is2d = true
     container.behavior.snapto = SnapTo_Arbitrary
     container.behavior.cuts_opening = true

     container.behavior.no_scale_mask = 127
     container.description = "EP Threaded Hole #{@boltsize} #{@tpi} Len=#{@length.to_l}"
     container.insertion_point = Geom::Point3d.new(@@ZERO,@@ZERO,@@ZERO) 

  end

end  #class
#=============================================================================

end #module EPFasteners
end #module EP