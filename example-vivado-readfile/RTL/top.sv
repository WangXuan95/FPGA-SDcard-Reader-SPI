
//--------------------------------------------------------------------------------------------------------
// Module  : top
// Type    : synthesizable, FPGA's top, IP's example design
// Standard: SystemVerilog 2005 (IEEE1800-2005)
// Function: an example of sd_file_reader, read a file from SDcard via SPI, and send file content to UART
//           this example runs on Digilent Nexys4-DDR board (Xilinx Artix-7),
//           see http://www.digilent.com.cn/products/product-nexys-4-ddr-artix-7-fpga-trainer-board.html
//--------------------------------------------------------------------------------------------------------

module top (
    // clock = 100MHz
    input  logic         clk100mhz,
    // rst_n active-low, You can re-scan and re-read SDcard by pushing the reset button.
    input  logic         resetn,
    // when sdcard_pwr_n = 0, SDcard power on
    output logic         sdcard_pwr_n,
    // signals connect to SD SPI bus
    output logic         sd_spi_ssn,
    output logic         sd_spi_sck,
    output logic         sd_spi_mosi,
    input  logic         sd_spi_miso,
    // 8 bit led to show the status of SDcard
    output logic [15:0]  led,
    // UART tx signal, connected to host-PC's UART-RXD, baud=115200
    output logic         uart_tx
);

assign sdcard_pwr_n = 1'b0;

assign { led[7:6], led[11], led[14] } = 4'b0;


wire       outen;     // when outen=1, a byte of file content is read out from outbyte
wire [7:0] outbyte;   // a byte of file content


// For input and output definitions of this module, see sd_file_reader.sv
sd_spi_file_reader #(
    .FILE_NAME      ( "example.txt"  ),  // file name to read
    .SPI_CLK_DIV    ( 100            )   // because clk=100MHz, SPI_CLK_DIV is set to 100
) sd_spi_file_reader_i (
    .rstn           ( resetn         ),
    .clk            ( clk100mhz      ),
    .spi_ssn        ( sd_spi_ssn     ),
    .spi_sck        ( sd_spi_sck     ),
    .spi_mosi       ( sd_spi_mosi    ),
    .spi_miso       ( sd_spi_miso    ),
    .card_type      ( led[ 5: 4]     ),  // 0=Unknown, 1=SDv1.1 , 2=SDv2 , 3=SDHCv2
    .card_stat      ( led[ 3: 0]     ),
    .filesystem_type( led[13:12]     ),  // 0=Unknown, 1=invalid, 2=FAT16, 3=FAT32
    .filesystem_stat( led[10: 8]     ),
    .file_found     ( led[15   ]     ),  // 0=file not found, 1=file found
    .outen          ( outen          ),
    .outbyte        ( outbyte        )
);


//----------------------------------------------------------------------------------------------------
// send file content to UART
//----------------------------------------------------------------------------------------------------
uart_tx #(
    .CLK_DIV        ( 868            ),   // 100MHz/868 = 115200
    .PARITY         ( "NONE"         ),   // no parity bit
    .ASIZE          ( 14             ),   //
    .DWIDTH         ( 1              ),   // tx_data is 8 bit (1 Byte)
    .ENDIAN         ( "LITTLE"       ),   //
    .MODE           ( "RAW"          ),   //
    .END_OF_DATA    ( ""             ),   //
    .END_OF_PACK    ( ""             )    //
) uart_tx_i (
    .rstn           ( resetn         ),
    .clk            ( clk100mhz      ),
    .tx_data        ( outbyte        ),
    .tx_last        ( 1'b0           ),
    .tx_en          ( outen          ),
    .tx_rdy         (                ),
    .o_uart_tx      ( uart_tx        )
);

endmodule
