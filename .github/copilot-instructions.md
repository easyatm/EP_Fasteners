# EP_Fasteners SketchUp 插件 - AI 编码代理指令

## 项目概述
这是一个 SketchUp Ruby 插件，用于创建标准紧固件（螺栓、螺母、垫圈、攻丝孔/钻孔）作为可打印组件。该插件支持公制和 SAE/UTS 标准，具有中文本地化和 3D 打印调整。

## 架构
- **主模块**：`EP::EPFasteners` 在 `EPFasteners.rb` 中
- **UI 层**：基于 WebDialog 的 HTML 界面在 `HTML/` 目录中
- **组件类**：单个紧固件类型（EPBolt、EPNut 等）继承自 EPFastenerConstants
- **常量**：标准尺寸存储在数组中（@@WASHER、@@UTS、@@METRIC）在 EPFastenerConstants.rb 中
- **观察者**：模型观察者处理贯穿孔的动态组件放置

## 关键模式
- **组件创建**：使用 `Sketchup.active_model.definitions` 创建可重用组件，然后 `place_component()` 用于实例
- **对话框流程**：`create()` → `showDialog()` → 用户输入 → `continue()` → `create_entity()` → `place_component()`
- **贯穿孔处理**：ModelObserver.onPlaceComponent 为远侧切割创建辅助组件
- **属性存储**：使用 `set_attribute("Fastener", key, value)` 存储组件元数据
- **HTML UI**：WebDialog 与 JavaScript 回调（例如 "ruby_Continue"）执行 Ruby 方法

## 约定
- **命名**：类/方法使用 CamelCase，常量使用 UPPERCASE
- **注释**：意图使用中文，技术细节使用英文
- **日志**：调试使用英文 `puts` 语句
- **文件结构**：每个类一个文件，使用 require_relative 依赖
- **单位**：支持 "Metric" 与 "SAE"，使用单独的常量数组

## 工作流
- **测试**：在 SketchUp 中加载插件，通过工具菜单或工具栏按钮访问
- **调试**：使用 `puts` 控制台输出，SketchUp Ruby 控制台查看错误
- **修改**：对于 3D 打印，使用 DiamModify 参数调整直径（例如 "-0.8mm"）
- **本地化**：UI 字符串在 HTML 文件中，代码注释使用中文

## 示例
- **创建螺栓**：`EPBolt.create("Metric")` → 显示对话框 → 用户选择 M10x20 → 创建组件定义
- **贯穿孔**：放置攻丝孔，观察者自动创建远侧切割器组件
- **常量访问**：`@@METRIC.find { |row| row[0] == "M10" }[1]` 获取螺纹间距

## 依赖
- SketchUp Ruby API（无外部 gem）
- UI 使用 HTML/JavaScript（包含 jQuery）

## 注意事项
- 组件必须粘接到面上以正确方向
- 弧段必须是 6 的倍数以获得干净几何
- 辅助组件使用变换轴反转以放置远侧

## 文件说明
- **EPFasteners.rb**: 主模块文件，定义观察者类监听模型事件，处理贯穿孔的辅助组件创建，并设置插件菜单和工具栏。
- **EPFastenersMenu.rb**: 菜单类，管理用户界面对话框，用户选择紧固件类型和单位，然后调用相应类的创建方法。
- **EPFastenerConstants.rb**: 常量类，存储标准紧固件尺寸数组，包括垫圈、螺纹和公制/SAE 标准。
- **EPBolt.rb**: 螺栓类，处理螺栓组件的创建，包括对话框显示、用户输入处理和几何生成。
- **EPNut.rb**: 螺母类，负责螺母组件的创建和放置。
- **EPWasher.rb**: 垫圈类，用于创建垫圈组件。
- **EPTappedHole.rb**: 攻丝孔类，生成攻丝孔组件，支持贯穿孔处理。
- **EPDrilledHole.rb**: 钻孔类，创建钻孔组件。
- **EP_Fasteners上级目录(Plugins)的文件.rb**: 上级目录中的文件，可能包含插件加载或初始化相关代码。</content>
<parameter name="filePath">c:\Users\Administrator\AppData\Roaming\SketchUp\SketchUp 2024\SketchUp\Plugins\EP_Fasteners\.github\copilot-instructions.md