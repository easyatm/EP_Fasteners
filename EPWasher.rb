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
class EPWasher < EPFastenerConstants
#=============================================================================
#---------------------------------------------------------------------------------------------------------
   def self.create(modelunits)
      @@UNITS = modelunits
      if !defined? @@PREVUNITS
          @@PREVUNITS = "UNK"
      end

      if defined? @@Boltsize
         if @@UNITS != @@PREVUNITS 
            remove_class_variable(:@@BOLTSIZE)		#If changing units reinitialize
            @@PREVUNITS = @@UNITS
         end
      end

      if !defined? @@BoltSize
         if !defined? @@UNITS
             @@UNITS = "Metric"
         end
         if @@UNITS == "SAE"
             @@BoltSize = "#10"
             @@Length = "1.00"
         else
             @@BoltSize = "M8"
             @@Length = "30"
         end
         @@TPI = "Coarse"
         @@Head   = "Hex"
         @@Fullthread = "Yes"
         @@Inclwasher = "No"
      end
      @@PREVUNITS = @@UNITS

      self.showDialog()
   end

   #---------------------------------------------------------------------------------------------------------
   def self.partname()
      "EP垫片 #{@@BoltSize}"
   end

   #---------------------------------------------------------------------------------------------------------
   def partname()
      "EP垫片 #{@boltsize}"
   end

   #---------------------------------------------------------------------------------------------------------
   def create(container, boltsize)
      washer = @@WASHER.select {|s| s[0]==boltsize }
      if washer.count > 0 
         @@BoltSize = boltsize
         if boltsize.match(/M[0-9].*/).nil?
             @@UNITS = "SAE"
         else
             @@UNITS = "Metric"
         end

         @@Od = EPWasher::cLength(washer[0][2], @@UNITS)
         @@Id = EPWasher::cLength(washer[0][1], @@UNITS)
         @@Thick = EPWasher::cLength(washer[0][3], @@UNITS)

         @boltsize = boltsize
         @od       = @@Od
         @id       = @@Id
         @thick    = @@Thick

         if container.nil?
            0.00
            return
         end

         #Does this washer exist in the model already?
         # 此垫圈是否已经在模型中存在？
         #
         #partname = "EP Washer #{@boltsize}"
         defn = Sketchup.active_model.definitions[partname]
         if defn.nil?
            entity = create_entity(Sketchup.active_model)
            create_entities(entity)
            container.entities.add_instance(entity, Geom::Transformation.new([0.0,0.0,0.0]))
         else
            #use existing one
            container.entities.add_instance(defn, Geom::Transformation.new([0.0,0.0,0.0]))
         end

         @thick
      else
         0.00
      end
   end

#---------------------------------------------------------------------------------------------------------
   def self.continue
       model = Sketchup.active_model
       #Does this Bolt exist in the model already?
       # 此螺栓是否已经在模型中存在？
       #
       #partname = "EP Washer #{@@BoltSize}..."
       defn = Sketchup.active_model.definitions[self.partname]
       if defn.nil?
          model.start_operation(self.partname, true)
          awasher = EPWasher.new
          container= awasher.create_entity(model)
          if container.nil?
             model.abort_operation
             return
          end
          awasher.create_entities(container)
          model.commit_operation
          defn = awasher.entity
       end

       self.closeDialog
       Sketchup.active_model.place_component(defn, false)
   end
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
   def self.InitializeDialog
      @@dialog = UI::WebDialog.new("EP Washer Create", true, "", 550, 400, 200, 200, false )
      @@dialog.add_action_callback("ruby_OKPressed") {|dialog,params| self.performOK(params)}
      @@dialog.add_action_callback("ruby_CANCELPressed") {|dialog,params| self.performCancel()}
      @@dialog.add_action_callback("ruby_Continue") {|dialog,params| self.continue()}
      @@dialog.add_action_callback("ruby_DocumentReady") {|dialog,params| self.performLoadVars()}
   end

#---------------------------------------------------------------------------------------------------------
   def self.performLoadVars()

       js_command = "$(\"#BOLTSIZE\").val('#{@@BoltSize}');"
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
     end
   }

   washer = @@WASHER.select {|s| s[0]==@@BoltSize }

   if washer.nil?
       js_command = "setStatus('Error... Unknown size: #{@@BoltSize}');"
   else
       @@Od = EPWasher::cLength(washer[0][2],@@UNITS)
       @@Id = EPWasher::cLength(washer[0][1],@@UNITS)
       @@Thick = EPWasher::cLength(washer[0][3],@@UNITS)
       js_command = "setStatus('#{self.partname}');"
   end

   @@dialog.execute_script(js_command)

end

#---------------------------------------------------------------------------------------------------------
   def self.performCancel(*params)
      @@dialog.close()
   end

#---------------------------------------------------------------------------------------------------------
   def self.showDialog()
      if !defined?@@dialog
         self.InitializeDialog
      end

      if @@UNITS == "SAE"
          @@HTMLFile = "#{__dir__}\\HTML\\SAEWasher.html".gsub("/","\\")
      else
          @@HTMLFile = "#{__dir__}\\HTML\\MetricWasher.html".gsub("/","\\")
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
   def initialize
      if defined?@@BoltSize
         @boltsize = @@BoltSize    rescue 0.25
         @od       = @@Od.to_l     rescue 0.40
         @id       = @@Id.to_l     rescue 0.26
         @thick    = @@Thick.to_l  rescue 0.20
      end
   end

#---------------------------------------------------------------------------------------------------------
   def create_entities( container)
     draw_me( container)
   end

#---------------------------------------------------------------------------------------------------------
   def create_entity(model)
      @entity = model.definitions.add("EP Washer #{@boltsize}")
   end

#---------------------------------------------------------------------------------------------------------
   def entity
      @entity
   end

#---------------------------------------------------------------------------------------------------------
   def draw_me(container)
     puts "create_washer id=#{@id} od=#{@od} t=#{@thick}"

     scale = 1.0
     irad = (@id / 2.0)* scale 
     orad = (@od / 2.0) * scale 
     th = @thick * scale

     points = []
     p1p = Geom::Point3d.new(0.00 - irad, 0.00, 0.00)
     p2p = Geom::Point3d.new(0.00 - orad, 0.00, 0.00)
     p3p = Geom::Point3d.new(0.00 - orad, 0.00, 0.00 + th)
     p4p = Geom::Point3d.new(0.00 - irad, 0.00, 0.00 + th)
     
     numberofarcsegments = @@NumberOfArcSegments

     numberofsegments = numberofarcsegments
     angle = (2 * Math::PI) / numberofarcsegments

     pmf = Geom::PolygonMesh.new
     pmi = Geom::PolygonMesh.new
     pmo = Geom::PolygonMesh.new
     pmb = Geom::PolygonMesh.new
  
     vr = Geom::Vector3d.new(0,0,1)
     tr = Geom::Transformation.rotation([0,0,0], vr, 0.0 - angle)
 
     tprev = Geom::Transformation.new
     tcurr= tprev *  tr
     for j in 1..numberofsegments   
        p1c = p1p.transform(tcurr)
        p2c = p2p.transform(tcurr)
        p3c = p3p.transform(tcurr)
        p4c = p4p.transform(tcurr)
  
        pmf.add_polygon(p2c, p1c, p1p)
        pmf.add_polygon(p2c, p1p, p2p)

        pmo.add_polygon(p2c, p2p, p3c)
        pmo.add_polygon(p3p, p3c, p2p)

        pmb.add_polygon(p4c, p3c, p3p)
        pmb.add_polygon(p4c, p3p, p4p)

        pmi.add_polygon(p1c, p4p, p1p)
        pmi.add_polygon(p4p, p1c, p4c)

        p1p = p1c
        p2p = p2c
        p3p = p3c
        p4p = p4c
     end
   
     # Generate the faces ---------------------------------------------------------------------------------------------
     grp = container.entities.add_group
     grp.entities.add_faces_from_mesh(pmf,12)
     grp.entities.add_faces_from_mesh(pmo,12)
     grp.entities.add_faces_from_mesh(pmb,12)
     grp.entities.add_faces_from_mesh(pmi,12)
  
     newscale = 1.0000000 / scale
     t = Geom::Transformation.scaling newscale
     grp.transformation = t * grp.transformation
     grp.explode
  
     container.behavior.is2d = true
     container.behavior.snapto = SnapTo_Arbitrary
     container.behavior.cuts_opening = false
     container.behavior.no_scale_mask = 127
     container.description = "EP Washer #{@boltsize}"
     container.insertion_point = Geom::Point3d.new(0.00,0.00,0.00)
  
  end

end  #class
#=============================================================================
end  #module EPFasteners
end  #module EP
