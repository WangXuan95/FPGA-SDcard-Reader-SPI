// this example runs on Terasic DE0-CV board (Altera Cyclone V)
// see https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=163&No=921
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
    // 6 7-segment to show the status of SDcard
    output logic [ 6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);


logic        rstart=1'b1, rdone;

wire         outreq;
wire  [ 8:0] outaddr;
wire  [ 7:0] outbyte;

wire  [ 1:0] sdcardtype;
wire  [ 3:0] sdcardstate;

logic [15:0] lastdata = 16'h0;


always @ (posedge CLOCK_50 or negedge RESET_N)
    if(~RESET_N)
        rstart = 1'b1;
    else begin
        if(rdone)
            rstart = 1'b0;
    end


// For input and output definitions of this module, see sd_spi_sector_reader.sv
sd_spi_sector_reader #(
    .SPI_CLK_DIV ( 50               )   // SD spi_clk freq = clk freq/(2*SPI_CLK_DIV)
                                        // modify SPI_CLK_DIV to change the SPI speed
                                        // for example, when clk=50MHz, SPI_CLK_DIV=50,then spi_clk=50MHz/(2*50)=500kHz
                                        // 500kHz is a typical SPI speed for SDcard
) sd_sector_reader(
    .clk         ( CLOCK_50         ),
    .rst_n       ( RESET_N          ),
    
    .sdcardtype  ( sdcardtype       ),
    .sdcardstate ( sdcardstate      ),
    
    .start       ( rstart           ),
    .sector_no   ( 0                ),  // read No. 0 sector (the first sector) in SDcard
    .done        ( rdone            ),
    
    .rvalid      ( outreq           ),
    .raddr       ( outaddr          ),
    .rdata       ( outbyte          ),
    
    .spi_csn     ( SD_SPI_CS_N      ),
    .spi_clk     ( SD_SPI_SCK       ),
    .spi_mosi    ( SD_SPI_MOSI      ),
    .spi_miso    ( SD_SPI_MISO      )
);





// display SDcard status and types on 2 7-segment
SEG7_LUT  seg7_lut_i0( RESET_N,         sdcardstate   , HEX0 );
SEG7_LUT  seg7_lut_i1( RESET_N,  {2'b00, sdcardtype}  , HEX1 );  // 0=Unknown, 1=SDv1.1 , 2=SDv2 , 3=SDHCv2





// capture last 2 bytes in sector
always @ (posedge CLOCK_50 or negedge RESET_N)
    if(~RESET_N) begin
        lastdata <= 16'h0;
    end else begin
        if(outreq) begin
            if     (outaddr==9'd510)   // countdown second byte
                lastdata[15:8] <= outbyte;
            else if(outaddr==9'd511)   // countdown first byte
                lastdata[ 7:0] <= outbyte;
        end
    end




// display last 2 bytes on 4 7-segment
SEG7_LUT  seg7_lut_i2( RESET_N,  lastdata[ 3: 0]  , HEX2 );
SEG7_LUT  seg7_lut_i3( RESET_N,  lastdata[ 7: 4]  , HEX3 );
SEG7_LUT  seg7_lut_i4( RESET_N,  lastdata[11: 8]  , HEX4 );
SEG7_LUT  seg7_lut_i5( RESET_N,  lastdata[15:12]  , HEX5 );

endmodule
