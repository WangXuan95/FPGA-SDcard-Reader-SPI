读取文件示例
===========================

该示例从 **SD卡根目录** 中找到文件 **example.txt** 并读取其全部内容，然后用 **UART** 发送出去。如果 **UART** 连接到 电脑，可以看到文件内容。

为了适配你的开发板，你需要重新分配器件和引脚。详见 **top.sv** 里的注释.


运行结果：

我用了手头所有能用的 SD卡 测试了该示例的兼容性，如下表：

| |  SDv1.1 2GB card | SDv2 128MB card  | SDv2 2GB card  | SDHCv2 8GB card |
| :------: | :------------: | :------------: | :------------: | :-----------: |
| **FAT16** | :heavy_check_mark:  |  :heavy_check_mark: | :heavy_check_mark:  | NaN\* |
| **FAT32** | :heavy_check_mark:  |  :heavy_check_mark: | :heavy_check_mark:  | :heavy_check_mark: |

>  因为 SDHCv2 似乎无法在 Windows 中格式化成 FAT16 格式，所以也没法测试

下图展示了使用 **SDHCv2 card** + **FAT32** 测试的结果。图中的 8 个 LED 来自 top.sv 中的输出端口 **output [7:0] led** ，编码为 **11111110** ， 最前面两个 **11** 代表SD卡类型为 **SDHCv2** ； 紧接着的两个 **11** 代表文件系统为 **FAT32** ；再接着的一个 *1* 代表找到目标文件（本示例中为 **example.txt** ，你可以修改）；最后的三个位 **110** 代表任务结束，这仅仅是 **sd_file_reader.sv** 内的状态机码而已。 这 8 位 LED 的具体含义请见 **top.sv** 中的注释。

![测试结果照片](https://github.com/WangXuan95/FPGA-SDcard-Reader-SPI/blob/master/doc/ReadFile.png)

另外， **最关键** 的是，该示例将 目标文件( **example.txt** ) 中的内容通过 **UART** 发送了出去( **波特率=115200** )，如果你的 FPGA 开发板有 UART，请将 **top.sv** 的 **output uart_tx** 引脚正确的分配，以在上位机中观察读到的文件内容。

最后注意，clk 的频率需要给 50MHz，如果你没办法给 50MHz，请按照注释修改一些参数后，程序照样能正确运行。另外， rst_n 信号是低电平复位的，你可以把它连接到按钮上，每次复位都能重新读取一遍 SD 卡。如果你的 FPGA 开发板没有按钮，请将 rst_n 赋值为 **1'b1**

