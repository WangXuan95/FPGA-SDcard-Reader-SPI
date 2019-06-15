读取扇区示例
===========================

该示例读取 **SD卡** 的 **0号扇区**，然后用 **UART** 发送出去。如果 **UART** 连接到 电脑，可以看到扇区内容。

**./RTL/top.sv** 是该示例的工程顶层，它调用了：
* [./RTL 下的 uart_tx.sv 和 ram.sv](https://github.com/WangXuan95/sdcard-reader/blob/master/examples/ReadSector/RTL "./RTL 下的 uart_tx.sv 和 ram.sv")
* [../../RTL 下的 sd_spi_sector_reader.sv 和 spi_session.sv](https://github.com/WangXuan95/sdcard-reader/blob/master/RTL "../../RTL 下的所有 .sv 文件")

你需要手动建立工程并为 **top.sv** 分配引脚。详见 **top.sv** 里的注释

另外，**./Quartus** 目录中提供了一个基于 Altera FPGA 的工程示例。但你多半需要重新为它调整器件型号和引脚分配，才能在你的 FPGA 板子上正确的运行。
