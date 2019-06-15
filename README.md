SDcard File Reader
===========================
可能是首个 **基于RTL** 的 SD 卡 **文件系统** 读取器

# 特点
* 硬件支持： **SDv2** 和 **SDHCv2** (典型大小 128MB~16GB，覆盖了使用范围很广的一类卡)
* 软件支持： **FAT32** 和 **FAT16**
* 提供功能： 指定文件名读取文件内容，或指定扇区号读取扇区内容
* **纯 RTL 实现** ：完全使用 SystemVerilog ,方便移植

# 使用方法
[读取文件示例.md](https://github.com/WangXuan95/sdcard-reader/blob/master/examples/ReadFile/ "读取文件示例.md")
[读取扇区示例.md](https://github.com/WangXuan95/sdcard-reader/blob/master/examples/ReadSector/ "读取扇区示例.md")

# 推荐硬件电路

![推荐硬件电路](https://github.com/WangXuan95/sdcard-reader/blob/master/doc/sch.png)

# 开发目标
* 在没有 MCU 或 软核 辅助的 FPGA 系统中，实现一些离线配置，例如任意波发生器的波形配置。
* 为 FPGA 中的软核配置运行程序或操作系统。

# 待实现
* SDv1 的完整支持
* 简单解析 FAT32/FAT16，读取根目录下的指定文件名的文件
