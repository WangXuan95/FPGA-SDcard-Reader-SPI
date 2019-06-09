SDcard Reader
===========================
**纯RTL** (SystemVerilog) 实现的 SD卡读取器

## 已实现
* 自动 **初始化 SD 卡** ，并识别卡的类型 **(SDv1, SDv2, SDHCv2)**
* **读取单个扇区** (必须为 SDv2 或 SDHCv2)

## 待实现
* SDv1 的完整支持
* 简单解析 FAT32/FAT16，读取根目录下的指定文件名的文件

# 使用
**./RTL/sd\_spi\_sector\_reader.sv** 是一个能自动初始化 SD 卡并读取指定扇区的模块。
**./Quartus/RTL/top.sv** 提供一个调用示例，读取第0扇区。一般的SD卡在格式化后第0扇区为MBR，末尾为0x55AA,可以通过按按钮观察LED来检查。
