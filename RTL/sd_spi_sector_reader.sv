
// this module can automatically initialize the sdcard and handle the read sector command from user
module sd_spi_sector_reader #(
    parameter SPI_CLK_DIV = 50  // SD spi_clk freq = clk freq/(2*SPI_CLK_DIV)
                                // modify SPI_CLK_DIV to change the SPI speed
                                // for example, when clk=50MHz, SPI_CLK_DIV=50,then spi_clk=50MHz/(2*50)=500kHz
                                // 500kHz is a typical SPI speed for SDcard
)(
    input  logic         clk, rst_n,
    // user read sector command interface
    input  logic         start, 
    input  logic [31:0]  sector_no,
    output logic         done,
    // data readout
    output logic         rvalid,
    output logic [ 8:0]  raddr,  // raddr from 0 to 511, because the sector size is 512
    output logic [ 7:0]  rdata,
    // card status (for debug)
    output logic [ 1:0]  sdcardtype,
    output logic [ 3:0]  sdcardstate,
    // SDcard spi interface
    output logic         spi_csn, spi_clk, spi_mosi,
    input  logic         spi_miso
);

localparam CMD8_VALID_RES  = 8'hAA;

enum logic [1:0] {NONE, SDv1, SDv2, SDHCv2} cardtype = NONE;
enum logic [3:0] {RESET, CMD0, CMD8, CMD1, CMD8FAILED, ACMD41, CMD58, CMD16, IDLE, READING} cardstate = RESET;

reg  spistart=0;
wire spidone;
reg  [47:0] cmd=0, acmd=0;
wire [47:0] cmdres;
reg  [ 7:0] waitcycle=0, precycle=0, startcycle=0, cmdrcycle=0, acmdcycle=0, midcycle=0, recycle=0;
wire [ 7:0] cmdrsp, acmdrsp, rwrsp;
reg  [31:0] target_sector = 0;

initial done = 1'b0;
initial begin rvalid = 1'b0; raddr  = 9'h0; rdata  = 8'h0; end
assign sdcardtype  = cardtype;
assign sdcardstate = cardstate;

always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        done = 1'b0;
        spistart=0; cmd=48'h00_00000000_00; acmd=48'h00_00000000_00; waitcycle= 64; precycle=  0; startcycle=0; cmdrcycle=0; acmdcycle=0; midcycle= 0;recycle=0;
        cardtype  =  NONE;
        cardstate = RESET;
        target_sector = 0;
    end else begin
        done = 1'b0;
        spistart=0; cmd=48'h00_00000000_00; acmd=48'h00_00000000_00; waitcycle= 64; precycle=  0; startcycle=0; cmdrcycle=0; acmdcycle=0; midcycle= 0;recycle=0;
        if(spidone) begin
            case(cardstate)
            RESET : cardstate = CMD0;
            CMD0  : if(cmdrsp==8'h01) cardstate = CMD8;
            CMD1  : if(cmdrsp==8'h00) cardstate = IDLE;
            CMD8  : if(cmdrsp==8'h01) begin  // SDv2.0
                        if(cmdres[0+:8]==CMD8_VALID_RES)  // CMD8 success
                            cardstate = ACMD41;
                        else
                            cardstate = CMD8FAILED;
                    end else begin   // SDv1
                        cardstate = CMD1;   // TODO: SDv1
                        cardtype  = SDv1;
                    end
            ACMD41: if(cmdrsp==8'h01 && acmdrsp==8'h00) cardstate = CMD58;
            CMD58 : if(~cmdrsp[7]) begin  // SDv2.0
                        if((cmdres[3*8+:8]&8'hC0)==8'hC0)  // done initialize, SDHCv2
                            cardtype  = SDHCv2;
                        else                               // done initialize, SDv2
                            cardtype  = SDv2;
                        cardstate = CMD16;
                    end
            CMD16 :    if(cmdrsp==8'h00)  cardstate = IDLE;
            IDLE  :    if( (~cmdrsp[7]) && rwrsp==8'hFE) begin cardstate = READING;            end
            READING  : if( (~cmdrsp[7]) && rwrsp==8'hFE) begin cardstate = IDLE   ; done=1'b1; end
            endcase
        end else begin
            case(cardstate)
            RESET  : cardstate = CMD0;
            CMD0   : begin spistart=1; cmd=48'h40_00000000_95 ; acmd=48'h00_00000000_00; waitcycle=255; precycle=20; startcycle=0; cmdrcycle=0; acmdcycle=0; midcycle= 0;recycle=0; end
            CMD1   : begin spistart=1; cmd=48'h41_00000000_ff ; acmd=48'h00_00000000_00; waitcycle= 16; precycle= 0; startcycle=0; cmdrcycle=0; acmdcycle=0; midcycle= 0;recycle=0; end
            CMD8   : begin spistart=1; cmd=48'h48_000001aa_87 ; acmd=48'h00_00000000_00; waitcycle= 16; precycle= 0; startcycle=1; cmdrcycle=4; acmdcycle=0; midcycle= 0;recycle=0; end
            ACMD41 : begin spistart=1; cmd=48'h77_00000000_FF ; acmd=48'h69_40000000_FF; waitcycle= 16; precycle= 0; startcycle=1; cmdrcycle=0; acmdcycle=6; midcycle= 0;recycle=0; end
            CMD58  : begin spistart=1; cmd=48'h7a_00000000_FF ; acmd=48'h00_00000000_00; waitcycle= 16; precycle= 0; startcycle=1; cmdrcycle=4; acmdcycle=0; midcycle= 0;recycle=0; end
            CMD16  : begin spistart=1; cmd=48'h50_00000200_FF ; acmd=48'h00_00000000_00; waitcycle= 16; precycle= 0; startcycle=1; cmdrcycle=2; acmdcycle=0; midcycle= 0;recycle=0; end
            IDLE   : if(start) begin
                       target_sector = (cardtype==SDHCv2) ? sector_no : ( (cardtype==SDv2 || cardtype==SDv1) ? sector_no*512 : 0 );
                       spistart=1; cmd={8'h51,target_sector,8'hFF}; acmd=48'h00_00000000_00; waitcycle= 6; precycle= 0; startcycle=0; cmdrcycle=4; acmdcycle=0; midcycle=99;recycle=2;
                     end
            READING: begin
                       spistart=1; cmd={8'h51,target_sector,8'hFF}; acmd=48'h00_00000000_00; waitcycle= 6; precycle= 0; startcycle=0; cmdrcycle=4; acmdcycle=0; midcycle=99;recycle=2;
                     end
            endcase
        end
    end
end

logic rvalid_session;
logic [15:0] rindex_session;
logic [ 7:0] rdata_session;

always @ (posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        rvalid = 1'b0;
        raddr  = 9'h0;
        rdata  = 8'h0;
    end else begin
        if(cardstate==READING && rvalid_session && (rindex_session>=16'd2 && rindex_session<16'd514)) begin
            rvalid = 1'b1;
            raddr  = 16'd513 - rindex_session;
            rdata  = rdata_session;
        end else begin
            rvalid = 1'b0;
            raddr  = 9'h0;
            rdata  = 8'h0;
        end
    end
end

spi_session spi_session_for_sd_reader (
    .clk          ( clk         ),
    .rst_n        ( rst_n       ),
    // control interface
    .start        ( spistart    ),
    .done         ( spidone     ),
    .clkdiv       ( SPI_CLK_DIV ),
    .cmd          ( cmd         ),
    .acmd         ( acmd        ),
    // control interface (cycle time control parameters)
    .waitcycle    ( waitcycle   ),
    .precycle     ( precycle    ),
    .startcycle   ( startcycle  ),
    .cmdcycle     ( 6           ),
    .cmdrcycle    ( cmdrcycle   ),
    .acmdcycle    ( acmdcycle   ),
    .acmdrcycle   ( 0           ),
    .midcycle     ( midcycle    ),
    .stopcycle    ( 255         ),
    .recycle      ( recycle     ),
    // cmd result interface
    .cmdrsp       ( cmdrsp      ), 
    .acmdrsp      ( acmdrsp     ),
    .rwrsp        ( rwrsp       ),
    .cmdres       ( cmdres      ),
    // data readout
    .rvalid       ( rvalid_session  ),
    .rindex       ( rindex_session  ),
    .rdata        ( rdata_session   ),

    .csn          ( spi_csn     ),
    .sck          ( spi_clk     ),
    .mosi         ( spi_mosi    ),
    .miso         ( spi_miso    )
);

endmodule