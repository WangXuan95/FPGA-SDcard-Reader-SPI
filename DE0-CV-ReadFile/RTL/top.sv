// this example runs on Terasic DE0-CV board (Altera Cyclone V)
// see https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=163&No=921
//
//
// a example top for using sd_file_reader.sv
// function : find example.txt in the rootdir of SDcard and read out its content on VGA screen
// the SDcard must be SDv1.1 (typically  32MB~ 2GB)
//                 or SDv2   (typically 128MB~ 2GB)
//                 or SDHCv2 (typically   2GB~16GB)
// the file-system must be FAT16 or FAT32. If not, reformat the SD card.
// Store example.txt in the root directory, case-insensitive
//


module top(
    // clock = 50MHz
    input  logic         CLOCK_50,
    // rst_n active-low, You can re-scan and re-read SDcard by pushing the reset button.
    input  logic         RESET_N,
    // signals connect to SDcard SPI bus
    output logic         SD_SPI_CS_N,
    output logic         SD_SPI_SCK,
    output logic         SD_SPI_MOSI,
    input  logic         SD_SPI_MISO,
    // VGA signals, use VGA screen to show file content
    output logic         VGA_HS, VGA_VS,
    output logic [ 3:0]  VGA_R , VGA_G , VGA_B,
    // 5 7-segment to show the status of SDcard
    output logic [ 6:0]  HEX0, HEX1, HEX2, HEX3, HEX4
);


wire       outreq;    // when outreq=1, a byte of file content is read out from outbyte
wire [7:0] outbyte;   // a byte of file content

wire [3:0] sdcardstate;
wire [1:0] sdcardtype;
wire [2:0] fatstate;
wire [1:0] filesystemtype;
wire       file_found;




// For input and output definitions of this module, see sd_file_reader.sv
sd_file_reader #(
    .FILE_NAME      ( "example.txt"  ), // file to read, ignore Upper and Lower Case
                                        // For example, if you want to read a file named HeLLo123.txt in the SD card,
                                        // the parameter here can be hello123.TXT, HELLO123.txt or HEllo123.Txt
    
    .SPI_CLK_DIV    ( 50             )  // SD spi_clk freq = clk freq/(2*SPI_CLK_DIV)
                                        // modify SPI_CLK_DIV to change the SPI speed
                                        // for example, when clk=50MHz, SPI_CLK_DIV=50,then spi_clk=50MHz/(2*50)=500kHz
                                        // 500kHz is a typical SPI speed for SDcard
) sd_file_reader_inst(
    .clk            ( CLOCK_50       ),
    .rst_n          ( RESET_N        ),
    
    .spi_miso       ( SD_SPI_MISO    ),
    .spi_mosi       ( SD_SPI_MOSI    ),
    .spi_clk        ( SD_SPI_SCK     ),
    .spi_cs_n       ( SD_SPI_CS_N    ),
    
    .sdcardtype     ( sdcardtype     ),
    .filesystemtype ( filesystemtype ),
    .sdcardstate    ( sdcardstate    ),
    .fatstate       ( fatstate       ),
    .file_found     ( file_found     ),
    
    .outreq         ( outreq         ),
    .outbyte        ( outbyte        )
);





// show file content on VGA
vga_char_stream vga_char_stream_i(
    .clk            ( CLOCK_50       ),
    .rst_n          ( RESET_N        ),
    
    // signals connect to VGA
    .hsync          ( VGA_HS         ),
    .vsync          ( VGA_VS         ),
    .red            ( VGA_R          ),
    .green          ( VGA_G          ),
    .blue           ( VGA_B          ),
    
    // file content stream from SDFileReader
    .wreq           ( outreq         ),
    .wchar          ( outbyte        )
);




// display SDcard status and types on 5 7-segment
SEG7_LUT  seg7_lut_i0( RESET_N,              sdcardstate   , HEX0 );
SEG7_LUT  seg7_lut_i1( RESET_N,  {2'b00  ,    sdcardtype}  , HEX1 );  // 0=Unknown, 1=SDv1.1 , 2=SDv2 , 3=SDHCv2
SEG7_LUT  seg7_lut_i2( RESET_N,  {1'b0   ,      fatstate}  , HEX2 );
SEG7_LUT  seg7_lut_i3( RESET_N,  {2'b00  ,filesystemtype}  , HEX3 );  // 0=Unknown, 1=invalid, 2=FAT16, 3=FAT32
SEG7_LUT  seg7_lut_i4( RESET_N,  {3'b000 ,    file_found}  , HEX4 );  // 0=file not found, 1=file found

endmodule
