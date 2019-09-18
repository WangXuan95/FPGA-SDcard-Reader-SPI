读取扇区示例
===========================

该示例在 [**Nexys4-DDR 开发板**](http://www.digilent.com.cn/products/product-nexys-4-ddr-artix-7-fpga-trainer-board.html) 上运行，读取 **SD卡** 的 **0号扇区**，然后用 **UART** 发送出给PC机。

# 运行示例

1、 准备一个 **microSD卡** ， 文件系统不限 。

2、 将 **microSD卡** 插入 **Nexys4-DDR 开发板** 的卡槽。

3、 将 **Nexys4-DDR 开发板** 的USB口插在PC机上，用 **串口助手** 或 **Putty** 等软件打开对应的串口。

4、 用 **Vivado2018** (或更高版本) 打开工程 **Nexys4-ReadSector.xpr** ，综合并烧录。

5、 观察到串口打印出0号扇区内容 (即 **MBR扇区** )。按下 **Nexys4-DDR 开发板** 上的红色 **CPU_RESET按钮** 可以重新读取。

6、 同时，还能看到 **Nexys4-DDR 开发板** 上的 LED 灯发生变化，它们指示了SD的状态和类型，具体含义见代码注释。
