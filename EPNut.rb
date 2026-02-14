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
class EPNut < EPFastenerConstants
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
             @@UNITS = "SAE"
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
   def self.continue
      model = Sketchup.active_model
      #Does this Bolt exist in the model already?
      # 此螺栓是否已经在模型中存在？
      #
      #partname = "EP Threaded Nut #{@@BoltSize}..."
      #partname = "EP螺纹螺母 #{@@BoltSize}..."

      defn = Sketchup.active_model.definitions[self.partname]
      if defn.nil?
         model.start_operation(self.partname, true)
         utsnut = EPNut.new
         container= utsnut.create_entity(model)
         if container.nil?
            model.abort_operation
            return
         end
         utsnut.create_entities(container)
         model.commit_operation
         defn = utsnut.entity
      end

      self.closeDialog
      Sketchup.active_model.place_component(defn, false)
   end
#---------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------
   def self.InitializeDialog
      @@dialog = UI::WebDialog.new("Nut Create", true, "", 550, 400, 200, 200, false )
      @@dialog.add_action_callback("ruby_OKPressed") {|dialog,params| self.performOK(params)}
      @@dialog.add_action_callback("ruby_CANCELPressed") {self.performCancel()}
      @@dialog.add_action_callback("ruby_Continue") {self.continue()}
      @@dialog.add_action_callback("ruby_DocumentReady") {self.performLoadVars()}
   end

#---------------------------------------------------------------------------------------------------------
# Called when the html is initialized to set screen values
# 当HTML初始化时调用以设置屏幕值
#---------------------------------------------------------------------------------------------------------
def self.performLoadVars()         

   js_command = "$(\"#BOLTSIZE\").val('#{@@BoltSize}');"
   @@dialog.execute_script(js_command)

   ws = @@Inclwasher == "Yes"?"true":"false"
   js_command = "$(\"#WASHER\").prop(\"checked\",#{ws});"
   @@dialog.execute_script(js_command)

   js_command = "setThreadType('#{@@TPI}');"
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
        when "tt"
            @@TPI = e[1]
        when "ws"
            @@Inclwasher = e[1]=="true" ? "Yes" : "No"
     end
   }
   die  = @@UTS.select {|s| s[0]==@@BoltSize && s[1]==@@TPI}
   head = @@BOLT.select {|s| s[0]==@@BoltSize}
   @@Pitch = die[0][2]
   @@Diam = die[0][3]
   @@Maxthread = head[0][1].to_l
   @@Hex       = head[0][2]
   @@Socket    = head[0][3]
   @@Machine   = head[0][4]
   @@Set       = head[0][5]

   js_command = "setStatus('#{self.partname}');"
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
          @@HTMLFile = "#{__dir__}\\HTML\\SAENut.html".gsub("/","\\")
      else
          @@HTMLFile = "#{__dir__}\\HTML\\MetricNut.html".gsub("/","\\")
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
        @boltsize   = @@BoltSize
        @tpi        = @@TPI 
        @diam       = @@Diam
        @pitch      = @@Pitch
        @head       = @@Head
        @hex        = @@Hex
        @inclwasher = @@Inclwasher
        @units      = @@UNITS
   end

#---------------------------------------------------------------------------------------------------------
   def create_entities( container)
     draw_me( container)
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
   def self.partname()
      "EP螺母 #{@@BoltSize}-#{@@TPI}-#{@@Inclwasher}"
   end
#---------------------------------------------------------------------------------------------------------
   def partname()
      "EP螺母 #{@boltsize}-#{@tpi}-#{@inclwasher}"
   end
#---------------------------------------------------------------------------------------------------------
   def draw_me( container)
     puts "create nut  d=#{@diam} p=#{@pitch} washer=#{@inclwasher}"

     scale = 1.0
     d = EPNut::cLength(@diam, @units) * scale 
     p = EPNut::cLength(@pitch, @units) * scale 

     dmin = d - (1.082532 * p)    #defined in UTS standard see: wiki UTS thread
     p8 = p / 2.0                   # number of 16ths
     p4 = p / 4.0
     p2 = p / 8.0
     p1 = p / 16.0
     dmaj2 = d / 2.0
     dmin2 = dmin / 2.0
     sin60 = 0.866025			
     cos60 = 0.500000
     arcCons = p1 / 1.732050	# Solves the radius of the arc at the bottom of each thread
     arcCenter = [dmaj2 - arcCons,0,0]
     radius = 2 * arcCons
     points = []
     points << Geom::Point3d.new(arcCenter[0] + radius,         0.0, 0.0 - (0.0                 ))    #    1 (
     points << Geom::Point3d.new(arcCenter[0] + sin60 * radius, 0.0, 0.0 - (0.0 + cos60 * radius))    #    2  (
     points << Geom::Point3d.new(dmaj2,                         0.0, 0.0 - (p1                  ))    #    3   \
     points << Geom::Point3d.new(dmin2,                         0.0, 0.0 - (p4 + p2             ))    #    4    |
     points << Geom::Point3d.new(dmin2,                         0.0, 0.0 - (p8 + p2             ))    #    5    |
     points << Geom::Point3d.new(dmaj2,                         0.0, 0.0 - (p - p1              ))    #    6   /
     points << Geom::Point3d.new(arcCenter[0] + sin60 * radius, 0.0, 0.0 - (p - cos60 * radius  ))    #    7  (
     points << Geom::Point3d.new(arcCenter[0] + radius,         0.0, 0.0 - (p                   ))    #    8 (
     
     l = @hex[1].to_l

     offset = 0.00
     if @inclwasher == "Yes"
        awasher = EPWasher.new
        offset = awasher.create(container, @boltsize)
     end


     create_hexnut(@hex, arcCenter[0] + radius, offset, container)
     hole = create_nut(points, l, d, p, offset, container)
   end


  #---------------------------------------------------------------------------------------------------------
  def create_nut(points, length, diam, pitch, startoffset, container)
     scale = 1.0

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
     vp = Geom::Vector3d.new(0,0, 0.0 - offset)
     vso = Geom::Vector3d.new(0,0, 0.0 + startoffset)
     tr = Geom::Transformation.rotation([0,0,0], vr, 0.0 - angle)
     tp = Geom::Transformation.translation(vp)
  
     spoints = []
     tprev = Geom::Transformation.translation(vso)
 
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
                 pb1.z = startoffset
                 pb3.z = startoffset
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
     pc = Geom::Point3d.new(0.0, 0.0, 0.0 - length)
  
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
                 p1.z = (0.0 - length + startoffset)
                 p3.z = (0.0 - length + startoffset)
  
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
  
     newscale = 1.0000000 / scale
     t = Geom::Transformation.scaling newscale
     grp.transformation = t * grp.transformation
     ptc = Geom::Point3d.new(0.0, 0.0, 0.0 + length)
     t = Geom::Transformation.new(ptc)
     grp.transformation = t * grp.transformation
     grp.explode
  
     container.behavior.is2d = true
     container.behavior.snapto = SnapTo_Arbitrary
     container.behavior.cuts_opening = false
     container.behavior.no_scale_mask = 127
     container.description = "EP Threaded Nut #{@boltsize} #{@tpi}"
     container.insertion_point = Geom::Point3d.new(0.00,0.00,0.00)
  
   end

  #---------------------------------------------------------------------------------------------------------
  def create_hexnut(hex, holeradius, offset, container)
     #Hex contains wrench size and head thickness
     # 六角头包含扳手尺寸和头部厚度
     #
     numberofarcsegments = @@NumberOfArcSegments		#better be a multiple of 6
     numberperside = numberofarcsegments / 6
     numberperpoint = (numberperside + 1) / 2
     pm1 = Geom::PolygonMesh.new
     pm2 = Geom::PolygonMesh.new
     pm3 = Geom::PolygonMesh.new
     size = EPNut::cLength(hex[0], @units)
     thick = EPNut::cLength(hex[1], @units)

     hexradius = size/1.73205
     p0  = Geom::Point3d.new([0.00,0.00,0.00 + offset])
     ph1 = Geom::Point3d.new([hexradius,0.0, + offset])
     pc1 = Geom::Point3d.new([holeradius,0.0, + offset])
     vr = Geom::Vector3d.new(0,0,1)
     a60 = (2.0 * Math::PI) / 6.0
     angle = (2.0 * Math::PI) / numberofarcsegments
     t60 = Geom::Transformation.rotation([0,0,0], vr, a60)
     tc = Geom::Transformation.rotation([0,0,0], vr,  angle)
     th = Geom::Transformation.new(Geom::Point3d.new([0.00,0.00,thick]))
     ph2 = ph1.transform(t60)
     pc2 = pc1
     pt0 = p0.transform(th)
     for s in 1..6
        pt1 = ph1.transform(th)
        pt2 = ph2.transform(th)
        ptc1 = pc1.transform(th)
        ptc2 = ptc1

        pm2.add_polygon(ph1,ph2,pt2)    #sides
        pm2.add_polygon(ph1,pt2,pt1)

        for i in 0..(numberperside - 1)
           pc2 = pc1.transform(tc)
           pm1.add_polygon(pc1, pc2, ph1) if i < numberperpoint      #bottom
           pm1.add_polygon(ph1, pc1, ph2) if i == numberperpoint
           pm1.add_polygon(pc1, pc2, ph2) if i >= numberperpoint

           ptc2 = ptc1.transform(tc)
           pm3.add_polygon(ptc1, ptc2, pt1) if i < numberperpoint    #top
           pm3.add_polygon(pt1, ptc1, pt2)  if i == numberperpoint
           pm3.add_polygon(ptc1, ptc2, pt2) if i >= numberperpoint

           pc1 = pc2
           ptc1 = ptc2
        end

        #pm3.add_polygon(pt0, pt1, pt2)

        ph1 = ph2
        ph2 = ph1.transform(t60)
     end
     container.entities.add_faces_from_mesh(pm1,4)
     container.entities.add_faces_from_mesh(pm2,4)
     container.entities.add_faces_from_mesh(pm3,4)
 
  end

end  #class
#============================================================================

end #module EPFasteners
end #module EP