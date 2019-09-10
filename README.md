![test](https://img.shields.io/badge/test-passing-green.svg)
![docs](https://img.shields.io/badge/docs-passing-green.svg)

FPGA SDcard File Reader (SPI)
===========================
**基于 FPGA 的 SD卡文件读取器**

* **基本功能** ：FPGA作为 **SD-host** ， 指定文件名 **读取文件内容** ；或指定扇区号 **读取扇区内容**。
* **兼容性强** : 自动适配 **SD卡版本** ，自动适配 **FAT16/FAT32文件系统**。
* **RTL实现** ：完全使用 **SystemVerilog**  ,便于移植和仿真。

> 注：该库基于 **SPI总线** 的，笔者也有 **[SD版本](https://github.com/WangXuan95/FPGA-SDcard-Reader/ "SD版本")** 。 更加稳定和高效 ，推荐使用 **SD版本** 

|           |  SDv1.1 card       |  SDv2 card          | SDHCv2 card           |
| :-----:   | :------------:     |   :------------:    | :------------:        |
| **FAT16** | :heavy_check_mark: |  :heavy_check_mark: | :heavy_check_mark: \* |
| **FAT32** | :heavy_check_mark: |  :heavy_check_mark: | :heavy_check_mark:    |

> \* 注： SDHCv2 card 一般不使用 FAT16 文件系统


# 示例

* [读取文件示例](https://github.com/WangXuan95/FPGA-SDcard-Reader-SPI/blob/master/examples/ReadFile/ "读取文件示例")

* [读取扇区示例](https://github.com/WangXuan95/FPGA-SDcard-Reader-SPI/blob/master/examples/ReadSector/ "读取扇区示例")


# 推荐硬件电路

如图，使用 SD 卡的 **SPI模式** 。其中：
* **spi_cs_n** 和 **spi_miso** 的上拉电阻是必要的。
* **spi_mosi** 的上拉电阻是可选的。
* **spi_clk** 不能加上拉电阻
* **DAT1** 和 **DAT2** 是在 **SPI模式** 下忽略的两个引脚。

![推荐硬件电路](https://github.com/WangXuan95/FPGA-SDcard-Reader-SPI/blob/master/doc/sch.png)


# 相关链接

* [FPGA SD卡读取器 (SD总线版本)](https://github.com/WangXuan95/FPGA-SDcard-Reader/ "SD总线版本") : 与该库功能相同，但使用 **SD总线**。

* [FPGA SD卡模拟器](https://github.com/WangXuan95/FPGA-SDcard-Simulator/ "SD卡模拟器") : FPGA模仿SD卡行为，实现FPGA 模拟 **SDHC v2 ROM卡**
