// this example runs on Digilent Nexys4-DDR board (Xilinx Artix-7)
// see http://www.digilent.com.cn/products/product-nexys-4-ddr-artix-7-fpga-trainer-board.html
//

module top(
    // clock = 100MHz
    input  logic         CLK100MHZ,
    // rst_n active-low, You can re-scan and re-read SDcard by pushing the reset button.
    input  logic         RESETN,
    // when SD_RESET = 0, SDcard power on
    output logic         SD_RESET,
    // signals connect to SD bus
    output logic         SD_SPI_CS_N,
    output logic         SD_SPI_SCK,
    output logic         SD_SPI_MOSI,
    input  logic         SD_SPI_MISO,
    // 8 bit LED to show the status of SDcard
    output logic [15:0]  LED,
    // UART tx signal, connect it to host-PC's UART-RXD, baud=115200
    output logic         UART_TX
);

logic        rstart=1'b1, rdone;
logic        outreq;
logic [ 7:0] outbyte;

assign SD_RESET = 1'b0;

assign {LED[15:10], LED[7:4]} = 10'h0;

always @ (posedge CLK100MHZ or negedge RESETN)
    if(~RESETN)
        rstart = 1'b1;
    else begin
        if(rdone)
            rstart = 1'b0;
    end


// For input and output definitions of this module, see sd_spi_sector_reader.sv
sd_spi_sector_reader #(
    .SPI_CLK_DIV    ( 100            )  // SD spi_clk freq = clk freq/(2*SPI_CLK_DIV)
                                        // modify SPI_CLK_DIV to change the SPI speed
                                        // for example, when clk=100MHz, SPI_CLK_DIV=100,then spi_clk=100MHz/(2*100)=500kHz
                                        // 500kHz is a typical SPI speed for SDcard
) sd_sector_reader(
    .clk         ( CLK100MHZ        ),
    .rst_n       ( RESETN           ),
    
    .spi_csn     ( SD_SPI_CS_N      ),
    .spi_clk     ( SD_SPI_SCK       ),
    .spi_mosi    ( SD_SPI_MOSI      ),
    .spi_miso    ( SD_SPI_MISO      ),
    
    .sdcardtype  ( LED[9:8]         ),
    .sdcardstate ( LED[3:0]         ),
    
    .start       ( rstart           ),
    .sector_no   ( 0                ),  // read No. 0 sector (the first sector) in SDcard
    .done        ( rdone            ),
    
    .rvalid      ( outreq           ),
    .rdata       ( outbyte          )
);


uart_tx #(
    .UART_CLK_DIV    ( 868          ),  // UART baud rate = clk freq/(2*UART_TX_CLK_DIV)
                                        // modify UART_TX_CLK_DIV to change the UART baud
                                        // for example, when clk=100MHz, UART_TX_CLK_DIV=868, then baud=100MHz/(2*868)=115200
                                        // 115200 is a typical SPI baud rate for UART
                                        
    .FIFO_ASIZE      ( 12           ),  // UART TX buffer size=2^FIFO_ASIZE bytes, Set it smaller if your FPGA doesn't have enough BRAM
    .BYTE_WIDTH      ( 1            ),
    .MODE            ( 2            )
) uart_tx_inst (
    .clk             ( CLK100MHZ    ),
    .rst_n           ( RESETN       ),
    
    .wreq            ( outreq       ),
    .wgnt            (              ),
    .wdata           ( outbyte      ),
    
    .o_uart_tx       ( UART_TX      )
);

endmodule
