读取文件示例
===========================

该示例在 [**DE0-CV 开发板**](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=163&No=921) 上运行，从 **SD卡根目录** 中找到文件 **example.txt** 并读取其全部内容，然后显示在 **VGA屏幕** 上。

# 运行示例

1、 准备一个 **FAT16** 或 **FAT32** 的 **microSD卡** 。如果不是 **FAT16** 或 **FAT32**，则需要格式化一下 。

2、 在 **microSD卡** 根目录下创建 **example.txt** (文件名大小写不限) ， 在文件中写入一些内容。

3、 将 **microSD卡** 插入 **DE0-CV 开发板** 的卡槽。

4、 将 **DE0-CV 开发板** 上电，将 USB-Blaster 线插到 PC 机，将 **VGA 接口** 插到屏幕。

5、 用 **Quartus13.1** (或更高版本) 打开工程 **DE0-CV-ReadFile.qpf** ，综合并烧录。

6、 观察到 **VGA屏幕** 打印出文件内容。按下 **DE0-CV 开发板** 上的 **FPGA_RESET按钮** 可以重新读取。

7、 观察到开发板数码管的变化。具体含义见下（或详见代码注）。


# 数码管含义

| 数码管位 (从右往左) | 含义   |
| :-------------   | :---  |
| 第0位 | 若为 **8** ，说明SD卡已完成初始化 |
| 第1位 | **0**代表**未知类别** ，**1**代表**SDv1卡** ，**2**代表**SDv2卡** ， **3**代表**SDHCv2卡** |
| 第2位 | 若为 **6** ，说明文件系统解析器已完成工作 |
| 第3位 | **1**代表**不支持类别** ， **2**代表**FAT16** ， **3**代表**FAT32** |
| 第4位 | **1**代表已找到目标文件 ， **0**代表未找到目标文件 |

| ![readfile示例照片](https://github.com/WangXuan95/FPGA-SDcard-Reader-SPI/blob/master/images/readfile_test.jpg) |
| :------: |
| 图：在图中，数码管显示卡类型为 **SDHCv2卡** ，文件系统为 **FAT32** |

| ![读取文件后显示在VGA](https://github.com/WangXuan95/FPGA-SDcard-Reader-SPI/blob/master/images/screen.jpg) |
| :------: |
| 图：FPGA 读取文件后显示在 VGA 上 |
