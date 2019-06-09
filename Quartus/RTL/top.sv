
module top(
    input  logic clk, rst_n,
    input  logic spi_miso,
    output logic spi_mosi, spi_clk, spi_cs_n,
    output logic [7:0] led,
    input  logic [3:0] key
);

logic read_start = 1'b1;
logic read_sector_no = 0;
logic read_done;

logic rvalid;
logic [ 8:0] raddr;
logic [ 7:0] rdata;
logic [ 7:0] rdatas [8];
logic [ 7:0] sdcardstate;

always @ (posedge clk)
    if(rvalid && raddr>=(512-8))
        rdatas[511-raddr] = rdata;

always @ (*) begin
    case(~key)
    4'h0 : led = sdcardstate;
    4'h1 : led = rdatas[0];
    4'h2 : led = rdatas[1];
    4'h3 : led = rdatas[2];
    4'h4 : led = rdatas[3];
    4'h5 : led = rdatas[4];
    4'h6 : led = rdatas[5];
    4'h7 : led = rdatas[6];
    4'h8 : led = rdatas[7];
    endcase
end

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

sd_spi_sector_reader sd_sector_reader(
    .clk         ( clk         ),
    .rst_n       ( rst_n       ),
    
    .sdcardstate ( sdcardstate ),
    
    .start       ( read_start  ),
    .sector_no   ( read_sector_no),
    .done        ( read_done   ),
    
    .rvalid      ( rvalid      ),
    .raddr       ( raddr       ),
    .rdata       ( rdata       ),
    
    .spi_csn     ( spi_cs_n    ),
    .spi_clk     ( spi_clk     ),
    .spi_mosi    ( spi_mosi    ),
    .spi_miso    ( spi_miso    )
);


endmodule
