读取文件示例
===========================

该示例在 [**Nexys4-DDR 开发板**](http://www.digilent.com.cn/products/product-nexys-4-ddr-artix-7-fpga-trainer-board.html) 上运行，从 **SD卡根目录** 中找到文件 **example.txt** 并读取其全部内容，然后用 **UART** 发送出给PC机。

# 运行示例

1、 准备一个 **FAT16** 或 **FAT32** 的 **microSD卡** 。如果不是 **FAT16** 或 **FAT32**，则需要格式化一下 。 

2、 在 **microSD卡** 根目录下创建 **example.txt** (文件名大小写不限) ， 在文件中写入一些内容。

3、 将 **microSD卡** 插入 **Nexys4-DDR 开发板** 的卡槽。

4、 将 **Nexys4-DDR 开发板** 的USB口插在PC机上，用 **串口助手** 或 **Putty** 等软件打开对应的串口。

5、 用 **Vivado2018** (或更高版本) 打开工程 **Nexys4-ReadFile.xpr** ，综合并烧录。

6、 观察到串口打印出文件内容。按下 **Nexys4-DDR 开发板** 上的红色 **CPU_RESET按钮** 可以重新读取。

7、 同时，还能看到 **Nexys4-DDR 开发板** 上的 LED 灯发生变化，它们指示了SD的状态和类型，具体含义见代码注释。
