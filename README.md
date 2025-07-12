# la32r_soc_ciciec_semifinal
不出意外的话可以直接开始第二章部分了：第2章  分区赛决赛SoC扩展
这里我完成了第一部分的修改即： ⑦ 完成修改，试试之前初赛跑过的ciciec_func是否仿真和FPGA验证依然正常。-----这一步已经完成并且试验正常（我只实验了Hello_world）

# 前端
1. 主要任务：confreg的功能拓展
2. (潜在)问题：边沿中断检测可能存在问题
3. 测试程序：int_test,nano_thread
4. 截图：
    int_test结果截图,nano_thread结果截图

# 后端
1. 主要任务：
    (1) 逻辑综合设计报告（包含详细SDC约束文件）
    (2) 形式验证报告（包含RTL和Netlist的一致性检查结果）
    (3) 布局布线报告（包含GDSII的版图文件截图和说明）
    (4) 静态时序电路分析报告（setup和hold的时序分析说明）
    (5) 物理验证报告（包含DRC和LVS的检查结果分析）

2. 工艺库
    (1)物理库
        ①technology lef/tf
        lef/tf
        主要包括金属层定义、通孔层定义、cell定义
        金属：库单位、绕线规则、TRACK；
        通孔：Via array 形状、生成规格；
        ②cell lef/milkyway db
        标准单元、IO、Hard Macro/形状、pin位置、方向
    (2)时序库
        ①lib
        Innovus
        Tempus
        加密-->db（ICC、PT、DC）
        ②rc tech file
        ③sdc（约束文件）