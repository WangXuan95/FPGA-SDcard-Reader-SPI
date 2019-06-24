FPGA SDcard File Reader
===========================
可能是首个 **基于RTL** 的 SD 卡 **文件系统** 读取器

# 特点
* **硬件支持** ： **SDv1.1** 、 **SDv2** 和 **SDHCv2** (典型大小 32MB~32GB，覆盖了最常见的一类卡)。
* **软件支持** ： **FAT32** 和 **FAT16** 。
* **提供功能** ： 指定文件名 **读取文件内容** ；或指定扇区号 **读取扇区内容**
* **纯 RTL 实现** ：完全使用 **SystemVerilog**  ,方便移植

# 使用方法
* [读取文件示例](https://github.com/WangXuan95/sdcard-reader/blob/master/examples/ReadFile/ "读取文件示例")
* [读取扇区示例](https://github.com/WangXuan95/sdcard-reader/blob/master/examples/ReadSector/ "读取扇区示例")

# 推荐硬件电路

如图，使用 SD 卡的 **SPI模式** 。其中：
* **spi_cs_n** 和 **spi_miso** 的上拉电阻是必要的。
* **spi_mosi** 的上拉电阻是可选的。
* **spi_clk** 不能加上拉电阻
* **DAT1** 和 **DAT2** 是在 **SPI模式** 下用不到的两个引脚，建议加上拉电阻。

![推荐硬件电路](https://github.com/WangXuan95/sdcard-reader/blob/master/doc/sch.png)

# 应用场景
* 在没有 MCU 或 软核 辅助的 FPGA 系统中，实现一些离线配置，例如任意波发生器的波形配置。
* 为 FPGA 中的软核配置运行程序或操作系统。
