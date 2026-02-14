#编码：utf-8
#encoding:utf-8

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
require_relative "EPFastenersMenu"
require_relative "EPFastenerConstants"
require_relative "EPWasher"
require_relative "EPTappedHole"
require_relative "EPBolt"
require_relative "EPNut"
require_relative "EPDrilledHole"

module EP
module EPFasteners


# 监听新模型打开并启动模型观察者
# Watch for new models opening and start the model observer
#=============================================================================
class EPFastenerAppObserver < Sketchup::AppObserver
#=============================================================================
   def onNewModel(model)
      puts "onNewModel: " + model.to_s
      model.add_observer(EPFastenerModelObserver.new)           #Setup a listener for thru holes
   end

   def onOpenModel(model)
      puts "onOpenModel: " + model.to_s
      model.add_observer(EPFastenerModelObserver.new)           #Setup a listener for thru holes
   end

   def expectsStartupModelNotifications()
      puts "expectsStartupModelNotifications: " 
      return true
   end
end

#-----------------------------------------------------------------------------
# 对于钻孔和攻丝孔，如果孔是"贯穿"的，则创建第二个组件粘接到远侧以切割开口。
# For Drilled Holes and Tapped Holes, if the hole is "Thru" then create a 2nd 
# component to Glue to the far side to cut the opening. 
# 如果长度大于0.0，则两个组件都存在，只需将另一个放在正确的面上。
# If length is greater than 0.0 then both components exist, just place the other one on the correct face.
# 如果长度为0，确定正确的面和长度并调用<obj>.create(instance, length)方法来构建新组件。然后将其粘接到正确的面上。
# If length is 0, determine the correct face and length and call the <obj>.create(instance, length) method
# to build a new component. Then glue it to the correct face.
#
#=============================================================================
class EPFastenerModelObserver < Sketchup::ModelObserver
#=============================================================================
   def onPlaceComponent(holeinstance)
      @instance = holeinstance
      @zero = "0.0".to_l
      definition = @instance.definition
      @helpername = definition.get_attribute "Fastener", "Helper", "None"
      helperdone = @instance.get_attribute "Fastener", "Helper", "None"

      if (@helpername != "None") && (@helpername != helperdone)
         @length = definition.get_attribute "Fastener", "Length", @zero
         if @length ==  @zero
            #---------------------------------------------------------------------
            #Determine the length to the nearest face along the z axis of @instance
            #---------------------------------------------------------------------
            @glued_to = @instance.glued_to

            if !@glued_to.nil?
               #------------------------------------
               # @instance must be glued to a face...
               #------------------------------------
               t  = @instance.transformation
               p1 = t.origin
               p2 = Geom::Point3d.new(0, 0 ,-1).transform(t)

               #Find the face the hole should go on...
               line = [p1, p1.vector_to(p2)]

               faces = Sketchup.active_model.entities.select { |f| 
                 if (f.typename == "Face") 
                    pi = Geom.intersect_line_plane(line, f.plane)
                    if !pi.nil? && f != @glued_to
                       (f.classify_point(Geom.intersect_line_plane(line, f.plane)) == 1)
                    end
                 end
               }
               if faces.count > 0      #more than one face? use the closest one along the vector...
                  @glue_to = faces[0]
                  v = p1.vector_to(p2)
                  faces.each{ |f| 
                     if p1.distance_to_plane(@glue_to.plane) >= p1.distance_to_plane(f.plane)
                        #--------------------------------------------
                        #距离较小。方向正确吗？
                        #Less distance. Is it in the right direction?
                        #--------------------------------------------
                        vg = p1.vector_to(Geom.intersect_line_plane(line, f.plane))
                        if v.samedirection?(vg)
                           @glue_to = f
                        end
                     end
                  }
                  p2 = Geom.intersect_line_plane(line, @glue_to.plane)  # intersction along vector from center 
                  @length = p1.distance(p2)

                  helperclass = Object.const_get(@helpername)           # Helperclass needs to exist!
                  if !helperclass.nil?
                     @helperobj = helperclass.new() #rescue nil;
                  end
                  
                  #--------------------------------------------------------------------             
                  # 紧固件辅助类必须有一个create(instance, length)方法
                  # Fastener helper classes must have a create(instance, length) method
                  #--------------------------------------------------------------------
                  @Partname = @instance.description + " Length=#{@length.to_s}"
                  showStatus()
               end
            end
        else
            #---------------------------------------------------------------
            #指定长度... 辅助应该已经作为定义存在
            #Length specified... Helper should already exist as a definition
            #---------------------------------------------------------------

            helper = Sketchup.active_model.definitions[@helpername]
            if !helper.nil?
               #Create an instance to open the hole on the other side.
               f = @instance.glued_to

               if !f.nil?
                  t  = @instance.transformation
                  tz = Geom::Transformation.new([@zero, @zero, @zero - @length])
                  th = t * tz

                  h = Sketchup.active_model.entities.add_instance(helper, th)
                  #Find the face the hole  is on...
                  o = h.transformation.origin
                  faces = Sketchup.active_model.entities.select { |f| (f.typename == "Face") && (f.classify_point(o) == 1) }
                  if faces.count == 1      #more than one face? give up
                     h.glued_to = faces[0]
                  end

                  @instance.set_attribute "Fastener", "Helper", @helpername      # mark it as done by this helper
               end
            end
         end
      end 
    end


   #---------------------------------------------------------------------------------------------------------
   #---------------------------------------------------------------------------------------------------------
   #---------------------------------------------------------------------------------------------------------
   def continue()
      defn = @helperobj.create(@instance,@length) #rescue nil  # call fails for whatever reason... we are done.
 
      if !defn.nil? 
         t  = @instance.transformation
         p2 = Geom::Point3d.new(0, 0 ,@zero - @length).transform(t)                                        #根据实例方向沿z轴偏移原点长度
         tz = Geom::Transformation.axes(p2, [0.00 - t.xaxis.x, 0.00 - t.xaxis.y, 0.00 - t.xaxis.z], 
                                            [0.00 - t.yaxis.x, 0.00 - t.yaxis.y, 0.00 - t.yaxis.z], 
                                            [0.00 - t.zaxis.x, 0.00 - t.zaxis.y, 0.00 - t.zaxis.z])        #反转轴方向以面向原始实例

         h = Sketchup.active_model.entities.add_instance(defn, tz)

         if Geom.intersect_plane_plane(@glued_to.plane, @glue_to.plane).nil?                               # 如果平面不平行，不要粘接... 看起来很丑。
            h.glued_to = @glue_to
         end
     end
     @instance.set_attribute "Fastener", "Helper", @helpername                                             # 标记为由这个辅助完成

     closeStatus()

   end

   #---------------------------------------------------------------------------------------------------------
   def showStatus()
      if defined?@dialogStatus
         remove_instance_variable(:@dialogStatus)
      end
      InitializeDialogStatus()

      @dialogStatus.show()
   end

   #---------------------------------------------------------------------------------------------------------
   def closeStatus()
      if defined?@dialogStatus
         @dialogStatus.close()
         remove_instance_variable(:@dialogStatus)
      end
   end

   #---------------------------------------------------------------------------------------------------------
   def InitializeDialogStatus
      @dialogStatus = UI::WebDialog.new("EPFastener Status", true, "", 550, 400, 200, 200, false )
      @@HTMLFile = "#{__dir__}\\HTML\\SAEStatus.html".gsub("/","\\")
      @dialogStatus.set_file(@@HTMLFile)
      @dialogStatus.add_action_callback("ruby_Continue") {continue()}
      @dialogStatus.add_action_callback("ruby_DocumentReady") {performLoadStatusVars()}
   end

   #---------------------------------------------------------------------------------------------------------
   def performLoadStatusVars()
      js_command = "setStatus('#{@Partname}');"
      @dialogStatus.execute_script(js_command)
   end
end

#-----------------------------------------------------------------------------
# 检查此脚本文件是否在此SU会话中之前已加载
# Checks if this script file has been loaded before in this SU session
unless file_loaded?(__FILE__)                   # 如果没有，创建菜单条目

    names=["螺纹工具","align_large.png","align_small.png","螺栓/螺母/螺纹孔/钻孔"]

    add_separator_to_menu("Tool")
    mnu = UI.menu("Tool").add_item(names[0])  { EP::EPFasteners::EPFastenersMenu.create }
    
    #自己添加的工具栏按钮
    #@toolbar = UI::Toolbar.new(names[0])
    @toolbar = UI.toolbar("easy Tools")
    @commands= UI::Command.new(names[0]){ EP::EPFasteners::EPFastenersMenu.create }
    @commands.large_icon = names[1]
    @commands.small_icon = names[2]
    @commands.status_bar_text = names[3]
    @commands.tooltip= names[0]
    @commands.menu_text = names[0]
    @toolbar = @toolbar.add_item @commands
    @toolbar.show if @toolbar.get_last_state.abs == 1

    Sketchup.add_observer(EPFastenerAppObserver.new)
    file_loaded(__FILE__)

end

end # module EPFasteners
end # module EP