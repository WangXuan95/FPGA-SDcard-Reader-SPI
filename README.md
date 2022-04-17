![语言](https://img.shields.io/badge/语言-systemverilog_(IEEE1800_2005)-CAD09D.svg) ![部署](https://img.shields.io/badge/部署-quartus-blue.svg) ![部署](https://img.shields.io/badge/部署-vivado-FF1010.svg)

中文 | [English](#en)

FPGA SDcard File Reader (SPI)
===========================

基于 FPGA 的 SD卡文件读取器（通过 SPI 总线），指定文件名，读出文件内容。

能够自动适配 **SD卡版本** ，自动适配 **FAT16/FAT32文件系统**。

|           |    SDv1.1 card     |     SDv2 card      |    SDHCv2 card     |
| :-------: | :----------------: | :----------------: | :----------------: |
| **FAT16** | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| **FAT32** | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |



# 背景知识

SD卡最常用的接口总线是 SD总线，然而它也支持 SPI 总线， SPI 的复杂度和对时序的要求低于 SD 总线。之所以支持 SPI 总线，是为了让一些低端的单片机也能读写 SD 卡。

SD 卡和 microSD 卡的 SPI 接口的引脚定义如下图（SD卡和microSD卡除了外形尺寸外，功能上没有差别）。

|             ![pin](./figures/pin.png)             |
| :-----------------------------------------------: |
| 图：SD 卡（左）与 microSD 卡（右）的 SPI 引脚定义 |

SD卡本身只是一大块线性的数据存储空间，分为多个扇区 (sector)，每个扇区 512 字节，扇区0的地址范围为 0x00000000\~0x000001FF，扇区1的地址范围为 0x00000200\~0x000003FF，以此类推……。底层的读取和写入操作都以扇区为单位。为了在这片线性的存储空间中组织磁盘分区和文件，人们规定了复杂的数据结构——文件系统，SD卡最常用的文件系统是 FAT16 和 FAT32 。

为了从 SD 卡中读取文件数据，本库分为两个功能模块：

- 按照 SD 卡的 SPI 总线标准操控 SPI 总线，指定扇区号，读取扇区。。
- 在能够读取扇区的基础上，解析文件系统，也就是给定文件名，找到文件所在的位置和长度。实际上，文件可能不是连续存储的（被拆成多块放在不同扇区），本库会正确地处理这种情况。



# 如何调用本模块

RTL目录中的 sd_spi_file_reader.sv 是 SD卡 SPI 文件读取器的顶层模块，它的定义如下：

```
module sd_spi_file_reader #(
    parameter FILE_NAME = "example.txt",
    parameter SPI_CLK_DIV = 50
)(
    input  wire       rstn,   // rstn active-low, 1:working, 0:reset
    input  wire       clk,    // clock 
    // SDcard spi interface
    output wire       spi_ssn, spi_sck, spi_mosi,
    input  wire       spi_miso,
    // status output (optional for user)
    output wire [1:0] card_type,         // SDv1, SDv2, SDHCv2 or UNKNOWN
    output wire [3:0] card_stat,         // show the sdcard initialize status
    output wire [1:0] filesystem_type,   // FAT16, FAT32 or UNKNOWN
    output wire [2:0] filesystem_stat,   // show the filesystem initialize status
    output reg        file_found,        // 0=file not found, 1=file found
    // file content data output (sync with clk)
    output reg        outen,             // when outen=1, a byte of file content is read out from outbyte
    output reg  [7:0] outbyte            // a byte of file content
);
```

其中：

- `FILE_NAME` 指定要读的目标文件名。
- `SPI_CLK_DIV` 是时钟分频系数，它的取值需要根据你提供的 clk 的时钟频率来决定（详见代码注释）。
- `clk` 是模块驱动时钟。
- `rstn` 是复位信号，在开始工作前需要令 `rstn=0` 复位一下，然后令 `rstn=1` 释放。
- `spi_ssn` 、 `spi_sck` 、 `spi_mosi` 、 `spi_miso` 是 SPI 总线信号，需要连接到 SD 卡。
- `card_type` 输出检测到的 SD 卡的类型：0对应未知、1对应SDv1、2对应SDv2、3对应SDHCv2。
- `file_system_type` 输出检测到的 SD 卡的文件系统：0对应未知、1对应FAT16、2对应FAT32。
- `file_found` 输出是否找到目标文件：0代表未找到，1代表找到。
- 模块会逐个输出目标文件中的所有字节，每输出一个字节，`outen` 上就产生一个高电平脉冲，同时该字节出现在 `outbyte` 上。



运行示例工程
===========================

example-vivado-readfile 文件夹中包含一个 vivado 工程，该示例在 [Nexys4开发板](http://www.digilent.com.cn/products/product-nexys-4-ddr-artix-7-fpga-trainer-board.html) 上运行（因为 Nexys4 开发板有 microSD 卡槽，比较方便），它会从SD卡根目录中找到文件 example.txt 并读取其全部内容，然后用 UART 发送出给PC机。

按以下步骤运行该示例：

1. 准备一张 **FAT16** 或 **FAT32** 的 **microSD卡** 。如果不是 **FAT16** 或 **FAT32**，则需要格式化一下 。 
2. 在根目录下创建 **example.txt** (文件名大小写不限) ， 在文件中写入一些内容。
3. 将卡插入 Nexys4 的卡槽。
4. 将 Nexys4 的USB口插在PC机上，用 **串口助手** 或 **Putty** 等软件打开对应的串口。
5. 用 vivado 打开目录 example-vivado-readfile 中的工程，综合并烧录。
6. 观察到串口打印出文件内容。
7. 同时，还能看到 Nexys4 上的 LED 灯发生变化，它们指示了SD的类型和状态，具体含义见代码注释。
8. 按下 Nexys4 上的红色 CPU_RESET 按钮可以重新读取，再次打印出文件内容。



# 相关链接

* [FPGA SD卡读取器 (SD总线版本)](https://github.com/WangXuan95/FPGA-SDcard-Reader/) ：与该库功能相同，但通过**SD总线**。



<span id="en">FPGA SDcard File Reader (SPI)</span>
===========================

FPGA-based SD card file reader via SPI bus, specify the file name, and read the file content.

|           |    SDv1.1 card     |     SDv2 card      |    SDHCv2 card     |
| :-------: | :----------------: | :----------------: | :----------------: |
| **FAT16** | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| **FAT32** | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |



# Background

The most commonly used interface bus for SDcard is SD bus, however, it also supports SPI bus. The complexity and timing requirements of SPI are lower. The reason it support SPI bus is to allow some low-end microcontrollers to read and write SDcard.

The pin definitions of the SPI bus of SDcard and microSDcard are as shown in the figure below (SD card and microSD card have no difference in function except for shape and appearance).

|                  ![pin](./figures/pin.png)                   |
| :----------------------------------------------------------: |
| Figure : SPI pin defination of SDcard (left) and microSDcard. |

SDcard is just a large linear data storage space, which is divided into multiple sectors, each sector contains 512 bytes, the address range of sector 0 is 0x00000000\~0x000001FF, the address range of sector 1 is 0x00000200\~0x000003FF, and so on…. The underlying read and write operations are performed in sectors. In order to organize disk partitions and files in this linear storage space, people stipulate complex data structures: file system. The most commonly used file systems for SDcard are FAT16 and FAT32.

In order to read file content from SD card, this library is divided into two functional modules:

- Control the SPI bus according to the SPI bus standard of SDcard, specify the sector number and read the sector.
- On the basis of being able to read sectors, parse the file system, that is, given the file name, to find the location and length of the file. In fact, the file may not be stored contiguously (split into multiple blocks in different sectors), the library will handle this case correctly.



# How to use this module

sd_spi_file_reader.sv in the [RTL](./RTL) folder is the top-level module of the SDcard SPI file reader, which is defined as follow:

```
module sd_spi_file_reader #(
    parameter FILE_NAME = "example.txt",
    parameter SPI_CLK_DIV = 50
)(
    input  wire       rstn,   // rstn active-low, 1:working, 0:reset
    input  wire       clk,    // clock 
    // SDcard spi interface
    output wire       spi_ssn, spi_sck, spi_mosi,
    input  wire       spi_miso,
    // status output (optional for user)
    output wire [1:0] card_type,         // SDv1, SDv2, SDHCv2 or UNKNOWN
    output wire [3:0] card_stat,         // show the sdcard initialize status
    output wire [1:0] filesystem_type,   // FAT16, FAT32 or UNKNOWN
    output wire [2:0] filesystem_stat,   // show the filesystem initialize status
    output reg        file_found,        // 0=file not found, 1=file found
    // file content data output (sync with clk)
    output reg        outen,             // when outen=1, a byte of file content is read out from outbyte
    output reg  [7:0] outbyte            // a byte of file content
);
```

where:

- `FILE_NAME` specify the file name to read.
- `SPI_CLK_DIV` is the clock frequency division factor, and its value needs to be determined according to the clock frequency of the `clk` that you provide (see code comments for details).
- `clk` is the module driving clock.
- `rstn` It is a reset signal, you need to set `rstn=0` to reset the module before starting to work, and then set`rstn=1` to release.
- `spi_ssn` , `spi_sck` , `spi_mosi` , `spi_miso` is SPI bus, should be connect to SDcard.
- `card_type` will output the detected SD card type: 0 corresponds to unknown, 1 corresponds to SDv1, 2 corresponds to SDv2, 3 corresponds to SDHCv2.
- `file_system_type` will output the detected file system of SD card: 0 corresponds to unknown, 1 corresponds to FAT16, 2 corresponds to FAT32.
- `file_found` will output whether the target file was found: 0 means not found, 1 means found.
- The module will output all the bytes in the file. For each output byte, a high-level pulse will be generated on `outen`, and the byte will appear on `outbyte`.



Run FPGA demo
===========================

The [example-vivado-readfile](./example-vivado-readfile) folder contains a demo vivado project, the demo runs on [Nexys4 development board](http://www.digilent.com.cn/products/product-nexys-4-ddr-artix-7-fpga- trainer-board.html) (because the Nexys4 development board has a microSDcard slot), it will find the file example.txt from the root directory of the SDcard and read out its entire content, and then send it to the PC via **UART** .

Run the demo as follows:

1. Prepare a **microSDcard** of **FAT16** or **FAT32**. If it is not **FAT16** or **FAT32**, you need to format it.
2. Create **example.txt** in the root directory (the file name is case-insensitive), and write some content in the file.
3. Insert SDcard into the card slot of Nexys4.
4. Plug the USB port of Nexys4 into the PC, and open the corresponding serial port with software such as **Serial Assistant**, **Putty**, **minicom** or **HyperTerminal**.
5. Open the project in the directory [example-vivado-readfile](./example-vivado-readfile) using vivado, synthesize and program it.
6. Observe that the serial port prints out the file contents.
7. Simutinously, you can see that the LEDs on the Nexys4 change, they indicate the type and status of the SDcard, see the code comments for the specific meaning.
8. Press the red CPU\_RESET button on Nexys4 to re-read and print out the file content again.



# Related link

* [FPGA SD Card Reader (SD bus version)](https://github.com/WangXuan95/FPGA-SDcard-Reader/) : Same function as this repository, but via **SD bus**.

