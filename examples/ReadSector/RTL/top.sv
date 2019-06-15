// a example top for using sd_spi_sector_reader.sv
// function : find TARGET.TXT in the rootdir of SDcard and read out its content to UART(baud=115200)
// the SDcard must be SDv2   (typically 128MB~ 2GB)
//                 or SDHCv2 (typically   2GB~16GB)
// the file-system must be FAT16 or FAT32. If not, reformat the SD card.
// Store target.txt in the root directory, case-insensitive
//

module top(
    // clk = 50MHz, rst_n active low, You can read the SD card again with the reset button.
    input  logic clk, rst_n,
    // signals connect to SD spi
    input  logic spi_miso,
    output logic spi_mosi, spi_clk, spi_cs_n,
    // 8 bit LED to show the status and type of SDcard
    output logic [7:0] led,
    // UART tx signal, connect it to host's RXD
    output logic uart_tx
);

wire outreq;        // when outreq=1, a byte of file content is read out from outbyte
wire [7:0] outbyte; // a byte of file content

// type and status
logic [3:0] sdcardstate;
logic [1:0] sdcardtype;     // 0=Unknown, 1=SDv1 , 2=SDv2 , 3=SDHCv3  (SDv1 Not yet supported)

// display status on 8bit LED
assign led = {sdcardtype,2'b00,sdcardstate};

logic read_start = 1'b1;
logic read_sector_no = 0;
logic read_done;
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        read_start = 1'b1;
        read_sector_no = 0;
    end else begin
        if(read_done) begin
            read_start = 1'b0;
            read_sector_no = 0;
        end
    end
end

// For input and output definitions of this module, see sd_spi_sector_reader.sv
sd_spi_sector_reader #(
    .SPI_CLK_DIV    ( 50             )  // SD spi_clk freq = clk freq/(2*SPI_CLK_DIV)
                                        // modify SPI_CLK_DIV to change the SPI speed
                                        // for example, when clk=50MHz, SPI_CLK_DIV=50,then spi_clk=50MHz/(2*50)=500kHz
                                        // 500kHz is a typical SPI speed for SDcard
) sd_sector_reader(
    .clk         ( clk              ),
    .rst_n       ( rst_n            ),
    
    .sdcardtype  ( sdcardtype       ),
    .sdcardstate ( sdcardstate      ),
    
    .start       ( read_start       ),
    .sector_no   ( read_sector_no   ),
    .done        ( read_done        ),
    
    .rvalid      ( outreq           ),
    .raddr       (                  ),
    .rdata       ( outbyte          ),
    
    .spi_csn     ( spi_cs_n         ),
    .spi_clk     ( spi_clk          ),
    .spi_mosi    ( spi_mosi         ),
    .spi_miso    ( spi_miso         )
);


// send file content to UART
uart_tx #(
    .UART_CLK_DIV    ( 434          ),  // UART baud rate = clk freq/(2*UART_TX_CLK_DIV)
                                        // modify UART_TX_CLK_DIV to change the UART baud
                                        // for example, when clk=50MHz, UART_TX_CLK_DIV=434, then baud=50MHz/(2*434)=115200
                                        // 115200 is a typical SPI baud rate for UART
                                        
    .FIFO_ASIZE      ( 12           ),  // UART TX buffer size=2^FIFO_ASIZE bytes, Set it smaller if your FPGA doesn't have enough BRAM
    
    .BYTE_WIDTH      ( 1            ),
    
    .MODE            ( 2            )
) uart_tx_inst (
    .clk             ( clk          ),
    .rst_n           ( rst_n        ),
    
    .wreq            ( outreq       ),
    .wgnt            (              ),
    .wdata           ( outbyte      ),
    
    .o_uart_tx       ( uart_tx      )
);

endmodule
