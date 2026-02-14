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

module EP
   module EPFasteners
      #=============================================================================
      class EPBolt < EPFastenerConstants
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
                  @@BoltSize = "M10"
                  @@Length = "10"
               end
               @@TPI = "Coarse"
               @@Head   = "Hex"
               @@Fullthread = "Yes"
               @@Inclwasher = "No"
               @@DiamModify = "-0.8"
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
            #partname = "EP Threaded Bolt #{@@BoltSize}..."
            #partname = "EP螺纹螺栓 #{@@BoltSize}..."
            defn = Sketchup.active_model.definitions[self.partname]
            if defn.nil?
               model.start_operation(self.partname, true)
               abolt = EPBolt.new
               container= abolt.create_entity(model)
               if container.nil?
                  model.abort_operation
                  return
               end
               abolt.create_entities(container)
               model.commit_operation
               defn = abolt.entity
            end

            self.closeDialog
            Sketchup.active_model.place_component(defn, false)
         end
         #---------------------------------------------------------------------------------------------------------
         #---------------------------------------------------------------------------------------------------------
         def self.InitializeDialog
            @@dialog = UI::WebDialog.new("EP BOLT", true, "", 550, 440, 200, 200, false )
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

            ft = @@Fullthread == "Yes"?"true":"false"
            js_command = "$(\"#FULLTHREAD\").prop(\"checked\",#{ft});"
            @@dialog.execute_script(js_command)

            js_command = "$(\"#DiamModify\").val('#{@@DiamModify}');"
            @@dialog.execute_script(js_command)

            js_command = "setHeadType('#{@@Head}');"
            @@dialog.execute_script(js_command)

         end

         #---------------------------------------------------------------------------------------------------------
         def self.performOK(*params)

            @@Inclwasher="No"

            p = params[0].split(";")
            p = p.map{|e| e.split("=")}

            p.each { |e|
               case e[0]
               when "bs"
                  @@BoltSize = e[1]
               when "ht"
                  @@Head   = e[1]
               when "ln"
                  @@Length = EPTappedHole::cLength(e[1], @@UNITS)
               when "ft"
                  @@Fullthread = e[1]=="true" ? "Yes" : "No"
               when "ws"
                  @@DiamModify = e[1]
               when "tt"
                  @@TPI = e[1]
               end
            }
            die  = @@UTS.select {|s| s[0]==@@BoltSize && s[1]==@@TPI}
            head = @@BOLT.select {|s| s[0]==@@BoltSize}
            @@Pitch = EPTappedHole::cLength(die[0][2], @@UNITS)

            #这一行是螺栓直径
            #@@Diam = EPTappedHole::cLength(die[0][3], @@UNITS)
            #修改如下

            puts "DiamModify:" + @@DiamModify
            tempStr=die[0][3]
            tempFolat=@@DiamModify.to_f

            if tempFolat != 0 then
                puts "直径微调:" + tempFolat.to_s
               tempStr=(tempStr.to_f + tempFolat).to_s + "mm"
               puts "微调2到了:" + tempStr
            end

            @@Diam = EPTappedHole::cLength(tempStr, @@UNITS)

            puts "最终直径"
            puts @@Diam

            @@Maxthread = EPTappedHole::cLength(head[0][1], @@UNITS)
            @@Hex       = head[0][2]
            @@Socket    = head[0][3]
            @@Machine   = head[0][4]
            @@Set       = head[0][5]

            if @@Length < 0.0
               js_command = "setError('Length','Invalid Length Specified');"
            else
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
               @@HTMLFile = "#{__dir__}\\HTML\\SAEBolt.html".gsub("/","\\")
            else
               @@HTMLFile = "#{__dir__}\\HTML\\MetricBolt.html".gsub("/","\\")
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

            @boltsize  = @@BoltSize
            @tpi       = @@TPI
            @diam      = @@Diam
            @pitch     = @@Pitch
            @length    = @@Length
            @head      = @@Head
            @inclwasher= @@Inclwasher
            @fullthread= @@Fullthread
            @maxthread = @@Maxthread
            @hex       = @@Hex
            @socket    = @@Socket
            @machine   = @@Machine
            @set       = @@Set

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
            "EP螺栓 #{@@BoltSize}-#{@@TPI}-#{@@Length}-#{@@Head}-#{@@Fullthread}-微调#{@@DiamModify}"
         end
         #---------------------------------------------------------------------------------------------------------
         def partname()
            "EP螺栓 #{@boltsize}-#{@tpi}-#{@length}-#{@head}-#{@fullthread}-微调#{@@DiamModify}"
         end
         #---------------------------------------------------------------------------------------------------------
         def draw_me( container)
            puts "create bolt  #{@head} d=#{@@Diam} p=#{@@Pitch} l=#{@@Length} #{@inclwasher}"
            @message = "Creating new component: <br> #{partname}"

            scale = 1.0
            d = @diam * scale
            p = @pitch * scale
            l = @length * scale
            m = @maxthread * scale

            dmin = d - (1.082532 * p)    #defined in UTS standard see: wiki UTS thread
            p8 = p / 2                   # number of 16ths
            p4 = p / 4
            p2 = p / 8
            p1 = p / 16
            dmaj2 = d / 2
            dmin2 = dmin / 2
            sin60 = 0.866025
            cos60 = 0.500000
            arcCons = p2 / 1.732050	         # Solves the radius of the arc at the bottom of each external thread
            arcCenter = [dmin2 + arcCons,0,0]
            radius = 2 * arcCons
            points = []
            points << Geom::Point3d.new(dmaj2,                         0.0, 0.0 - (0.0                     ))    #    0   |
            points << Geom::Point3d.new(dmaj2,                         0.0, 0.0 - (p2                      ))    #    1   |
            points << Geom::Point3d.new(dmin2,                         0.0, 0.0 - (p4 + p2 + p1            ))    #    2    \
            points << Geom::Point3d.new(arcCenter[0] - sin60 * radius, 0.0, 0.0 - (p8 + p1 - cos60 * radius))    #    3     )
            points << Geom::Point3d.new(arcCenter[0] - radius,         0.0, 0.0 - (p8 + p1                 ))    #    4      )
            points << Geom::Point3d.new(arcCenter[0] - sin60 * radius, 0.0, 0.0 - (p8 + p1 + cos60 * radius))    #    5     )
            points << Geom::Point3d.new(dmin2,                         0.0, 0.0 - (p8 + p2 + p1            ))    #    6    /
            points << Geom::Point3d.new(dmaj2,                         0.0, 0.0 - (p                       ))    #    7   |


            offset = 0.00
            if @inclwasher == "Yes" && @head != "Set"
               awasher = EPWasher.new
               offset = awasher.create(container, @boltsize)
            end


            case @head
            when "Hex"
               create_hexhead(@hex,dmaj2, offset, container)
            when "Socket"
               create_sockethead(@socket, dmaj2, offset, container)
            when "Machine"
               create_machinehead(@machine, dmaj2, offset, container)
            when "Set"
               create_sethead(@set, (arcCenter[0] - radius), offset, container)
            else
               create_hexhead(@hex, dmaj2, offset, container)
            end

            if @fullthread == "Yes" then
               maxthread = l
            else
               maxthread = m
            end
            hole = create_bolt(points, l, d, p, maxthread, offset, container, @head)
         end
        
         #---------------------------------------------------------------------------------------------------------
         def create_bolt(points, length, diam, pitch, maxthread, startoffset, container, headtype)
            scale = 1.0

            numberofarcsegments = @@NumberOfArcSegments
            numberofsegments = (numberofarcsegments * ((maxthread / pitch)))
            numberofsegments = numberofsegments - (3 * numberofarcsegments) + 4

            angle = (2.0 * Math::PI) / numberofarcsegments
            offset = pitch / numberofarcsegments

            pm = Geom::PolygonMesh.new
            p1 = points[0]
            p2 = points[0]
            p3 = points[0]
            p4 = points[0]

            vr = Geom::Vector3d.new(0,0,1)
            vp = Geom::Vector3d.new(0,0, 0.0 - offset)
            tr = Geom::Transformation.rotation([0,0,0], vr, 0.0 - angle)
            tp = Geom::Transformation.translation(vp)
            zmin = 0.0

            spoints = []
            if (headtype != "Set")
               tprev = Geom::Transformation.new([0.00,0.00,startoffset - (length - maxthread)])
            else
               tprev = Geom::Transformation.new([0.00,0.00,startoffset - (length - maxthread) - points[4].z])
            end
            pe1 = points[0]
            pb1 = points[0]
            pb3 = points[0]
            sx = 0

            #Beginning unthreaded and first threaded section -------------------------------------------------------------------------------------
            for j in 1..numberofarcsegments
               tcurr= tprev * tp * tr
               points.each_with_index { |e,i|
                  if (i+1) < points.length
                     if (headtype != "Set") || (i >= 3)
                        p1 = e.transform(tprev)
                        p2 = points[i + 1].transform(tprev)
                        p3 = e.transform(tcurr)
                        p4 = points[i + 1].transform(tcurr)

                        if (i == 0)
                           p1.z = startoffset
                           p3.z = startoffset
                           sx = p1.x
                        end

                        if (headtype == "Set") && (i == 3)
                           sx = points[4].transform(tprev).x
                        end

                        if j==1
                           p1.x = sx
                           p2.x = sx
                        end
                        if (headtype == "Set") && (i == 3)
                           p1 = points[4].transform(tprev)
                           p3 = points[4].transform(tcurr)
                           p1.z = startoffset
                           p3.z = startoffset
                        end
                        pm.add_polygon(p2, p1, p3)
                        pm.add_polygon(p4, p2, p3)
                     end
                  end
               }
               tprev = tcurr
            end

            #Regular threaded section -------------------------------------------------------------------------------------
            for j in 1..numberofsegments
               tcurr= tprev * tp * tr
               points.each_with_index { |e,i|
                  if (i+1) < points.length
                     p1 = e.transform(tprev)
                     p2 = points[i + 1].transform(tprev)
                     p3 = e.transform(tcurr)
                     p4 = points[i + 1].transform(tcurr)

                     if (j==1) && (headtype == "Set") && (i < 4)
                        sx = points[4].transform(tprev).x
                        p1.x = sx
                        p2.x = sx
                     end

                     pm.add_polygon(p2, p1, p3)
                     pm.add_polygon(p4, p2, p3)
                  end
               }
               tprev = tcurr
            end

            #Ending threaded section -------------------------------------------------------------------------------------
            maxz = 0.0 - length + startoffset

            for j in 1..numberofarcsegments + 1
               tcurr= tprev * tp * tr
               points.each_with_index { |e,i|
                  if (i+1) < points.length
                     p1 = e.transform(tprev)
                     p2 = points[i + 1].transform(tprev)
                     p3 = e.transform(tcurr)
                     p4 = points[i + 1].transform(tcurr)
                     plowprev = points[4].transform(tprev)
                     plowcurr = points[4].transform(tcurr)
                     p3.x = p4.x = plowcurr.x  if i > 3 || j > numberofarcsegments
                     p3.y = p4.y = plowcurr.y  if i > 3 || j > numberofarcsegments
                     p1.x = p2.x = plowprev.x  if ((i > 3) && (j > 1)) || j > (numberofarcsegments + 1)
                     p1.y = p2.y = plowprev.y  if ((i > 3) && (j > 1)) || j > (numberofarcsegments + 1)

                     p2.z = maxz if i == 4 && j > 1
                     p4.z = maxz if i == 4 && j > 1

                     pm.add_polygon(p2, p1, p3) if i < 5 || j == 1
                     pm.add_polygon(p4, p2, p3) if i < 5 || j == 1

                  end
               }
               tprev = tcurr
            end


            # Generate the faces ---------------------------------------------------------------------------------------------
            grp = container.entities.add_group
            grp.entities.add_faces_from_mesh(pm)
            edges = grp.entities.select { |e| e.typename == "Edge" &&  e.start.position.z == (startoffset - length) && e.end.position.z == (startoffset - length) }

            edges[0].find_faces if edges.count > 0

            newscale = 1.0000000 / scale
            t = Geom::Transformation.scaling newscale
            grp.transformation = t * grp.transformation
            grp.explode

            container.behavior.is2d = true
            container.behavior.snapto = SnapTo_Arbitrary
            container.behavior.cuts_opening = false
            container.behavior.no_scale_mask = 127
            container.description = "Bolt #{@boltsize} #{@tpi} Len=#{@length} @head Fullthread=#{@fullthread} Washer=#{@washer}"
            container.insertion_point = Geom::Point3d.new(0.00,0.00,0.00)

         end

         #---------------------------------------------------------------------------------------------------------
         def create_hexhead( hex, holeradius, offset, container)
            #Hex contains wrench size and head thickness
            # 六角头包含扳手尺寸和头部厚度
            #
            numberofarcsegments = @@NumberOfArcSegments		#better be a multiple of 6
            numberperside = numberofarcsegments / 6
            numberperpoint = (numberperside + 1) / 2
            pm1 = Geom::PolygonMesh.new
            pm2 = Geom::PolygonMesh.new
            pm3 = Geom::PolygonMesh.new
            size  = EPBolt::cLength(hex[0], @@UNITS)
            thick = EPBolt::cLength(hex[1], @@UNITS)

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

               pm2.add_polygon(ph1,ph2,pt2)
               pm2.add_polygon(ph1,pt2,pt1)

               for i in 0..(numberperside - 1)
                  pc2 = pc1.transform(tc)
                  pm1.add_polygon(pc1, pc2, ph1) if i < numberperpoint
                  pm1.add_polygon(ph1, pc1, ph2) if i == numberperpoint
                  pm1.add_polygon(pc1, pc2, ph2) if i >= numberperpoint

                  pc1 = pc2
               end

               pm3.add_polygon(pt0, pt1, pt2)

               ph1 = ph2
               ph2 = ph1.transform(t60)
            end
            container.entities.add_faces_from_mesh(pm1,4)
            container.entities.add_faces_from_mesh(pm2,4)
            container.entities.add_faces_from_mesh(pm3,4)

         end
         #---------------------------------------------------------------------------------------------------------
         def create_sockethead(  socket, holeradius,  offset, container)
            #socket contains wrench size, diameter and head thickness
            # 套筒头包含扳手尺寸、直径和头部厚度
            #
            numberofarcsegments = @@NumberOfArcSegments			#better be a multiple of 6
            numberperside = numberofarcsegments / 6
            numberperpoint = (numberperside + 1) / 2
            pm1 = Geom::PolygonMesh.new
            pm2 = Geom::PolygonMesh.new
            pm3 = Geom::PolygonMesh.new
            size = EPBolt::cLength(socket[0], @@UNITS)
            diam = EPBolt::cLength(socket[1], @@UNITS)
            thick = EPBolt::cLength(socket[2], @@UNITS)
            hexradius = size/1.73205

            p0  = Geom::Point3d.new([0.00,0.00,0.00])
            ph1 = Geom::Point3d.new([hexradius,0.0,thick / 3.0])
            pc1 = Geom::Point3d.new([holeradius,0.0,0.0])
            po1 = Geom::Point3d.new([diam/2.0,0.0,0.0])
            phc = Geom::Point3d.new([0.0,0.0,thick / 3.0])
            vr = Geom::Vector3d.new(0,0,1)
            a60 = (2.0 * Math::PI) / 6.0
            angle = (2.0 * Math::PI) / numberofarcsegments
            t60 = Geom::Transformation.rotation([0,0,0], vr, a60)
            tc = Geom::Transformation.rotation([0,0,0], vr,  angle)
            th = Geom::Transformation.new(Geom::Point3d.new([0.00,0.00,thick]))
            th2 = Geom::Transformation.new(Geom::Point3d.new([0.00,0.00, thick * 2.0 / 3.0 ]))

            ph2 = ph1.transform(t60)
            pc2 = pc1
            pt0 = p0.transform(th2)
            for s in 1..6
               pt1 = ph1.transform(th2)
               pt2 = ph2.transform(th2)

               pm2.add_polygon(ph1,pt2,ph2)
               pm2.add_polygon(ph1,pt1,pt2)
               pm2.add_polygon(phc, ph1, ph2)

               for i in 0..(numberperside - 1)
                  pc2 = pc1.transform(tc)
                  po2 = po1.transform(tc)
                  pm1.add_polygon(pc1, pc2, po1)
                  pm1.add_polygon(pc2, po2, po1)


                  po1t = po1.transform(th)
                  po2t = po2.transform(th)
                  pm3.add_polygon(po1t,po1,po2)
                  pm3.add_polygon(po1t,po2,po2t)

                  pm1.add_polygon(po1t, po2t, pt1) if i < numberperpoint
                  pm1.add_polygon(pt1, po1t, pt2) if i == numberperpoint
                  pm1.add_polygon(po1t, po2t, pt2) if i >= numberperpoint

                  pc1 = pc2
                  po1 = po2
               end


               ph1 = ph2
               ph2 = ph1.transform(t60)
            end
            container.entities.add_faces_from_mesh(pm1,4)
            container.entities.add_faces_from_mesh(pm2,4)
            container.entities.add_faces_from_mesh(pm3,4)
         end

         #---------------------------------------------------------------------------------------------------------
         def create_machinehead(  machine, holeradius,  offset, container)
            #machine head diam, thickness, phillips size, diameter of phillips opening
            # 机器头直径、厚度、十字螺丝尺寸、十字螺丝开口直径

            numberofarcsegments = @@NumberOfArcSegments			#better be a multiple of 6

            diameter  = EPBolt::cLength(machine[0], @@UNITS)
            thickness = EPBolt::cLength(machine[1], @@UNITS)
            pd        = EPBolt::cLength(machine[3], @@UNITS)
            pr = pd / 2.0
            ph = @@PHILLIPS.select {|s| s[0]==machine[2]}[0]

            vx = Geom::Vector3d.new(1,0,0)
            vy = Geom::Vector3d.new(0,1,0)
            vz = Geom::Vector3d.new(0,0,1)

            archeight = thickness / 2.0
            edgeheight = thickness - archeight

            w = EPBolt::cLength(ph[1], @@UNITS)  #Slot width
            z = w / 2.0

            cz = (((diameter/2.0)**2) - (archeight**2)) / (archeight * 2.0)     #center of dome below origin
            pcz = Geom::Point3d.new([0.00,0.00,edgeheight - cz])
            rc  = cz + archeight
            pz = Geom::Point3d.new(0, 0 ,0)
            planexy = [pz, vz]

            aofslotwidth = Math.asin(w/(2.0*rc))     # angle at radius for Slot Width
            aofpd      = Math.asin(pd/(2.0*rc))

            tr1 = Geom::Transformation.rotation(pcz, vy,  aofpd)
            tr90z = Geom::Transformation.rotation(pz, vz,  Math::PI / 2)

            vao = vx.transform(tr1)
            tr2 = Geom::Transformation.rotation(pcz, vao,  0.00 - aofslotwidth)     # slot width / 2
            tr3 = Geom::Transformation.rotation(pcz, vao,  aofslotwidth)

            p  = []
            pb = []
            p << Geom::Point3d.new([ 0.00, 0.00, thickness       ]).transform(tr1).transform(tr3)         #leading Edge of groove
            p << Geom::Point3d.new([ 0.00, 0.00, thickness       ]).transform(tr1)                        #Center Edge of groove
            p << Geom::Point3d.new([ 0.00, 0.00, thickness       ]).transform(tr1).transform(tr2)         #trailing Edge of groove
            p.each{ |e|
               p1b = Geom.intersect_line_plane([e, Geom::Vector3d.new(1, 0, 3)] , planexy)
               pb << p1b
            }
            p1 = p[0]
            p2 = p[2]

            tr = Geom::Transformation.rotation(pcz, vy,  0.00 - (aofpd - (aofslotwidth *2)) / 3)
            for i in 1..3
               p1 = p1.transform(tr)
               p.unshift(p1)
            end
            for i in 1..3
               p2 = p2.transform(tr)
               p << p2
            end

            # Now the arc between the gaps.
            # ----------------------------
            pca = p2.transform(tr2)
            vra = pcz.vector_to(pca)

            tra = Geom::Transformation.rotation(pca, vra,  0.00 - Math::PI / 10)   # 90 degrees in 5 steps
            for i in 1..3
               p2 = p2.transform(tra)
               p << p2
               p2b = p2.clone
               p2b.z = 0.00
               pb << p2b
            end

            # and an arc to connect the outer radius of the cutout
            #-----------------------------------------------------
            pc = []
            p2 = p[4]

            tra = Geom::Transformation.rotation([0.00,p2.y,0.00], vz,  Math::PI / 12)   # 90 degrees in 6 steps
            p2 = p2.transform(tra)   #skip 1
            for i in 1..3
               p2 = p2.transform(tra)
               pc << p2
            end

            # Create the faces
            #-----------------
            pn = []
            p.each { |e| pn << e.transform(tr90z) }
            p1 = pn[0]
            p2 = pb[0].transform(tr90z)

            pm1 = Geom::PolygonMesh.new
            pm2 = Geom::PolygonMesh.new
            pm3 = Geom::PolygonMesh.new
            pm4 = Geom::PolygonMesh.new
            pm5 = Geom::PolygonMesh.new

            pm1.add_polygon(p[1], pb[0], p[0])
            pm1.add_polygon(p[2], pb[0], p[1])
            pm1.add_polygon(p[3], pb[0], p[2])
            pm1.add_polygon(p[4], pb[0], p[3])
            pm1.add_polygon(p[4], pb[1], pb[0])
            pm1.add_polygon(p[5], pb[1], p[4])
            pm1.add_polygon(p[5], pb[2], pb[1])

            pm1.add_polygon(p[5], p[6], pb[2])
            pm1.add_polygon(p[6], p[7], pb[2])
            pm1.add_polygon(p[7], p[8], pb[2])
            pm1.add_polygon(p[8], p[9], pb[3])
            pm1.add_polygon(p[8], pb[3], pb[2])

            pm1.add_polygon(pb[4], pb[3], p[9])
            pm1.add_polygon(pb[4], p[9], p[10])
            pm1.add_polygon(pb[5], pb[4], p[10])
            pm1.add_polygon(pb[5], p[10], p[11])

            pm1.add_polygon(p[11],p1,pb[5])
            pm1.add_polygon(p1,p2,pb[5])

            pm2.add_polygon(pb[1], pz, pb[0])
            pm2.add_polygon(pb[2], pz, pb[1])
            pm2.add_polygon(pb[3], pz, pb[2])
            pm2.add_polygon(pb[4], pz, pb[3])
            pm2.add_polygon(pb[5], pz, pb[4])
            pm2.add_polygon(p2, pz, pb[5])

            for i in 5..10
               pm2.add_polygon(p[i+1], p[i], pca)
            end
            pm2.add_polygon(pn[0], p[11], pca)
            for i in 0..2
               pm2.add_polygon(pn[i+1], pn[i], pca)
            end
            pm2.add_polygon(pc[2], pn[3],  pca)
            pm2.add_polygon(pc[0], pc[1], pca)
            pm2.add_polygon(pc[1], pc[2], pca)
            pm2.add_polygon(p[5], pc[0], pca)

            pm190 = pm1
            pm290 = pm2
            pe = []
            pe << p[3..5]
            pe << pc[0..2]

            container.entities.add_faces_from_mesh(pm1,12)
            container.entities.add_faces_from_mesh(pm2,12)
            ploop = pe.flatten(1)
            p90 = []
            for i in 1..3
               pm190.transform! tr90z
               pm290.transform! tr90z
               container.entities.add_faces_from_mesh(pm190,12)
               container.entities.add_faces_from_mesh(pm290,12)
               ploop.each { |e| p90 << e.transform(tr90z) }
               pe << p90
               ploop = p90
               p90 = []
            end
            pe.flatten!(1)
            pe.rotate!(1)

            # pe is the circle of inner points, pm is the middle ring, po will be outer points, pbo is the bottom ring, to sync up with the screw
            pm = []
            po = []
            pbo = []
            pbi = []

            po << Geom::Point3d.new([(diameter/2.0),0.00,edgeheight])
            pbo << Geom::Point3d.new([(diameter/2.0),0.00,0.00])
            v1 = pcz.vector_to(pe[0])
            v2 = pcz.vector_to(po[0])
            angle = v1.angle_between(v2)
            tr = Geom::Transformation.rotation(pcz, vy,  aofpd + (angle / 2.0))
            pm << Geom::Point3d.new([ 0.00, 0.00, thickness       ]).transform(tr)

            tra = Geom::Transformation.rotation(pz, vz,  Math::PI / 12)   # 360 degrees in 24 steps
            for i in 0..22
               pm << pm[i].transform(tra)
               po << po[i].transform(tra)
               pbo << pbo[i].transform(tra)
            end

            tra = Geom::Transformation.rotation(pz, vz,  (2.0 * Math::PI )/ numberofarcsegments)   # 360 degrees in numberofarcsegments steps
            pbi << Geom::Point3d.new([holeradius,0.0,0.0])
            for i in 1..numberofarcsegments
               pbi << pbi[i-1].transform(tra)
            end

            k = 0.00
            for i in 0..23
               j = i + 1
               j = 0 if j > 23

               pm3.add_polygon(pe[i], pm[i], pm[j])
               pm3.add_polygon(pe[i], pm[j], pe[j])

               pm3.add_polygon(pm[i], po[i], po[j])
               pm3.add_polygon(pm[i], po[j], pm[j])

               pm4.add_polygon(po[i], po[j], pbo[i])
               pm4.add_polygon(pbo[i], po[j], pbo[j])
            end

            k = 0.50
            f = numberofarcsegments / 24
            for i in 0..23
               j = i + 1
               j = 0 if j > 23
               l = k + 1
               l = 0 if k >= numberofarcsegments
               pm5.add_polygon(pbo[i], pbi[k], pbo[j])
               pm5.add_polygon(pbo[j], pbi[k], pbi[l]) if l.to_i != (l+f).to_i
               k += f
            end
            container.entities.add_faces_from_mesh(pm3,12)
            container.entities.add_faces_from_mesh(pm4,12)
            container.entities.add_faces_from_mesh(pm5,12)

         end


         #---------------------------------------------------------------------------------------------------------
         #---------------------------------------------------------------------------------------------------------
         def create_sethead( set, holeradius,  offset, container)
            #set contains key size
            # 沉头螺丝包含钥匙尺寸
            #
            numberofarcsegments = @@NumberOfArcSegments			#better be a multiple of 6
            numberperside = numberofarcsegments / 6
            numberperpoint = (numberperside + 1) / 2
            pm1 = Geom::PolygonMesh.new
            pm2 = Geom::PolygonMesh.new
            pm3 = Geom::PolygonMesh.new
            size = EPBolt::cLength(set[0], @@UNITS)
            thick = size

            bottom = 0.00 - thick * 2.0 / 3.0
            top = 0.00

            hexradius = size/1.73205
            p0  = Geom::Point3d.new([0.00,0.00,0.00])
            ph1 = Geom::Point3d.new([hexradius,0.0,bottom])
            po1 = Geom::Point3d.new([holeradius,0.0,0.0])
            phc = Geom::Point3d.new([0.0,0.0,bottom])
            vr = Geom::Vector3d.new(0,0,1)
            a60 = (2.0 * Math::PI) / 6.0
            angle = (2.0 * Math::PI) / numberofarcsegments
            t60 = Geom::Transformation.rotation([0,0,0], vr, a60)
            tc = Geom::Transformation.rotation([0,0,0], vr,  angle)
            th = Geom::Transformation.new(Geom::Point3d.new([0.00,0.00,top]))
            th2 = Geom::Transformation.new(Geom::Point3d.new([0.00,0.00, thick * 2.0 / 3.0 ]))

            ph2 = ph1.transform(t60)

            pt0 = p0.transform(th2)
            for s in 1..6
               pt1 = ph1.transform(th2)
               pt2 = ph2.transform(th2)

               pm2.add_polygon(ph1,pt2,ph2)
               pm2.add_polygon(ph1,pt1,pt2)
               pm2.add_polygon(phc, ph1, ph2)

               for i in 0..(numberperside - 1)
                  po2 = po1.transform(tc)
                  po1t = po1.transform(th)
                  po2t = po2.transform(th)

                  pm1.add_polygon(po1t, po2t, pt1) if i < numberperpoint
                  pm1.add_polygon(pt1, po1t, pt2) if i == numberperpoint
                  pm1.add_polygon(po1t, po2t, pt2) if i >= numberperpoint

                  po1 = po2
               end

               ph1 = ph2
               ph2 = ph1.transform(t60)
            end
            container.entities.add_faces_from_mesh(pm1,4)
            container.entities.add_faces_from_mesh(pm2,4)
         end

      end  #class
      #=============================================================================

   end #module EPFasteners
end #module EP
