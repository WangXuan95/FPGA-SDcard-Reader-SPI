module vga_char_stream #(
    parameter   VGA_CLK_DIV = 1  // when clk= 50MHz, set VGA_CLK_DIV to 1
                                 // when clk=100MHz, set VGA_CLK_DIV to 2
                                 // when clk=150MHz, set VGA_CLK_DIV to 3
                                 // when clk=200MHz, set VGA_CLK_DIV to 4
                                 // ......
) (
    // clock and reset
	input  logic         clk, rst_n,
    // vga interfaces
	output logic         hsync, vsync,
	output logic [3:0]   red, green, blue,
    // user char stream input interface
    input  logic         wreq,
    input  logic [7:0]   wchar
);

logic         last_cr = 1'b0;
logic [ 6:0]  wx='0, wy='0;
wire          wx_inrange = (wx<7'd86);
wire          wy_inrange = (wy<7'd32);

logic         wreql  = 1'b0;
logic [11:0]  waddrl = 12'h0;
logic [ 7:0]  wcharl = 8'h0;

logic redb, greenb, blueb;

logic [ 6:0]  reqx;
logic [ 4:0]  reqy;
logic [ 7:0]  reqascii;

assign   red = {4{  redb}};
assign green = {4{greenb}};
assign  blue = {4{ blueb}};

vga_char_86x32 #(
    .VGA_CLK_DIV   ( VGA_CLK_DIV    )
) vga_char_86x32_i (
    // clock and reset
    .clk           ( clk            ),
    .rst_n         ( 1'b1           ),
    
    // vga interfaces
    .hsync         ( hsync          ),
    .vsync         ( vsync          ),
    .red           ( redb           ),
    .green         ( greenb         ),
    .blue          ( blueb          ),

    // user interface
    .reqx          ( reqx           ),
    .reqy          ( reqy           ),
    .ascii         ( reqascii       )
);


always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        wx      <= 7'd0;
        wy      <= 7'd0;
        last_cr <= 1'b0;
    end else begin
        if(wreq) begin
            if         (wchar==8'd13) begin    // \r
                wx <= 7'd0;
                wy <= wy_inrange ? wy+7'd1 : wy;
                last_cr <= 1'b1;
            end else if(wchar==8'd10) begin    // \n
                if(~last_cr) begin
                    wx <= 7'd0;
                    wy <= wy_inrange ? wy+7'd1 : wy;
                end
                last_cr <= 1'b0;
            end else begin
                wx <= wx_inrange ? wx+7'd1 : wx;
                last_cr <= 1'b0;
            end
        end
    end
    
    
always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        wreql  <= 1'b0;
        waddrl <= 12'h0;
        wcharl <= 8'h0;
    end else begin
        wreql  <= (wreq & wx_inrange & wy_inrange);
        waddrl <= {wy[4:0], wx};
        wcharl <= wchar;
    end


ram_for_vga ram_for_vga_i(
    .clk           ( clk            ),
    .wreq          ( wreql          ),
    .waddr         ( waddrl         ),
    .wdata         ( wcharl         ),
    .raddr         ( {reqy, reqx}   ),
    .rdata         ( reqascii       )
);

endmodule






module ram_for_vga(
    input  logic         clk,
    input  logic         wreq,
    input  logic [11:0]  waddr,
    input  logic [ 7:0]  wdata,
    input  logic [11:0]  raddr,
    output logic [ 7:0]  rdata
);
initial rdata = 8'h0;

logic [7:0] data_ram_cell [4096];
    
always @ (posedge clk)
    rdata <= data_ram_cell[raddr];

always @ (posedge clk)
    if(wreq) 
        data_ram_cell[waddr] <= wdata;

endmodule
