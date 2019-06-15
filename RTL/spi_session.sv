
module spi_session(
    input  logic clk, rst_n,
    // user command interface
    input  logic start, 
    output logic done,
    input  logic [31:0] clkdiv, // next command spi sck = clk / (2*(clkdiv+1)), for example clk=50MHz, clkdiv=124, sck=50MHz/(2*125) = 200kHz
    input  logic [47:0] cmd, acmd,
    input  logic [ 7:0] waitcycle, precycle, startcycle, cmdcycle, cmdrcycle, acmdcycle, acmdrcycle, midcycle, stopcycle, recycle, // dummy clock byte cycles

    output logic [ 7:0] cmdrsp, acmdrsp, rwrsp,
    output logic [47:0] cmdres, acmdres,
    
    output logic rvalid,
    output logic [15:0] rindex,
    output logic [ 7:0] rdata,
    // spi interface
    output logic csn, sck, mosi,
    input  logic miso
);

initial {cmdrsp, acmdrsp, rwrsp} = 0;
initial {cmdres, acmdres} = 0;
initial {csn, sck, mosi} = 3'b111;

logic start_last=1'b0;
logic [31:0] clkdivreg=0, cyccnt=0;
logic [ 2:0] bitcnt=3'b0;
logic highlow=1'b0;
logic byteend, bytestart;
logic scken=1'b0, chipselect=1'b0;
logic [ 7:0] wbyte=8'h0, rbyte=8'h0;
logic [47:0] cmdr=0, acmdr=0;
logic [ 7:0] waitc=8'h0, prec=8'h0, startc=8'h0, cmdc=8'h0, cmdrwait=8'h0, cmdrc=8'h0, acmdc=8'h0, acmdrwait=8'h0, acmdrc=8'h0, midc=8'h0, stopc=8'h0, rec=8'h0, lastc=8'h0;
logic [15:0] rwc = 16'h0;
logic iscmdr=1'b0, isacmdr=1'b0, iscmdres=1'b0, isacmdres=1'b0,ismidc=1'b0, isrwc=1'b0;

assign byteend   = (cyccnt==0) && ({bitcnt,highlow}==4'h0) ;
assign bytestart = (cyccnt==1) && ({bitcnt,highlow}==4'h0) ;

always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        cyccnt = 0;
        {bitcnt,highlow} = 3'h0;
        {csn, sck, mosi} = 3'b111;
        rbyte = 8'h0;
    end else begin
        if(~start) begin
            cyccnt = 0;
            {bitcnt,highlow} = 3'h0;
            {csn, sck, mosi} = 3'b111;
            rbyte = 8'h0;
        end else if(cyccnt<clkdivreg) begin
            cyccnt++;
        end else begin
            csn  = ~chipselect;
            sck = scken ? highlow : 1'b1;
            if(highlow) // posedge of sck, capture miso
                rbyte[7-bitcnt]= miso;
            else        // negedge of sck, set mosi
                mosi = wbyte[7-bitcnt];
            {bitcnt,highlow}++;
            cyccnt = 0;
        end
    end

always @ (posedge clk or negedge rst_n)
    if(~rst_n) begin
        start_last   = 1'b0;
        clkdivreg    = 0;
        {cmdr,acmdr} = 0;
        {cmdrsp, acmdrsp, rwrsp} = 0;
        {cmdres, acmdres} = 0;
        {waitc,prec,startc,cmdc,cmdrwait,cmdrc,acmdc,acmdrwait,acmdrc,midc,rwc,stopc,rec,lastc} = 0;
        {iscmdr, isacmdr,iscmdres,isacmdres,ismidc,isrwc} = 0;
        {chipselect,scken,wbyte} = {2'b00, 8'hff};
        {rvalid, rdata, rindex} = 0;
    end else begin
        {rvalid, rdata, rindex} = 0;
        if(~start) begin
            start_last   = 1'b0;
            clkdivreg    = 0;
            {cmdr,acmdr} = 0;
            {cmdrsp, acmdrsp, rwrsp} = 0;
            {cmdres, acmdres} = 0;
            {waitc,prec,startc,cmdc,cmdrwait,cmdrc,acmdc,acmdrwait,acmdrc,midc,rwc,stopc,rec,lastc} = 0;
            {iscmdr, isacmdr,iscmdres,isacmdres,ismidc,isrwc} = 0;
            {chipselect,scken,wbyte} = {2'b00, 8'hff};
        end else if(~start_last) begin
            start_last   = 1'b1;
            clkdivreg    = clkdiv<2 ? 2 : clkdiv;
            {cmdr,acmdr} = {cmd, acmd};
            {cmdrsp, acmdrsp, rwrsp} = 0;
            {cmdres, acmdres} = 0;
            {waitc    ,prec    ,startc    ,cmdc    ,cmdrwait               ,cmdrc    ,acmdc    ,acmdrwait               ,acmdrc    ,midc    ,rwc                       ,stopc    ,rec    ,lastc   } = 
            {waitcycle,precycle,startcycle,cmdcycle,(cmdcycle>0)?8'h20:8'h0,cmdrcycle,acmdcycle,(acmdcycle>0)?8'h20:8'h0,acmdrcycle,midcycle,(midcycle>0)?16'd514:16'd0,stopcycle,recycle,8'h2    };
            {iscmdr, isacmdr,iscmdres,isacmdres,ismidc,isrwc} = 0;
            {chipselect,scken,wbyte} = {2'b00, 8'hff};
        end else if(bytestart) begin
            if(waitc>0) begin
                waitc--;
                {chipselect,scken,wbyte} = {2'b00, 8'hff};
            end else if(prec>0) begin
                prec--;
                {chipselect,scken,wbyte} = {2'b01, 8'hff};
            end else if(startc>0) begin
                startc--;
                {chipselect,scken,wbyte} = {2'b11, 8'hff};
            end else if(cmdc>0) begin
                cmdc--;
                {chipselect,scken,wbyte} = {2'b11, cmdr[cmdc*8+:8]};
            end else if(cmdrwait>0) begin     iscmdr = 1'b1;
                cmdrwait--;
                {chipselect,scken,wbyte} = {2'b11, 8'hff};
            end else if(cmdrc>0) begin        iscmdres = 1'b1;
                cmdrc--;
                {chipselect,scken,wbyte} = {2'b11, 8'hff};
            end else if(acmdc>0) begin
                acmdc--;
                {chipselect,scken,wbyte} = {2'b11, acmdr[acmdc*8+:8]};
            end else if(acmdrwait>0) begin    isacmdr = 1'b1;
                acmdrwait--;
                {chipselect,scken,wbyte} = {2'b11, 8'hff};
            end else if(acmdrc>0) begin       isacmdres = 1'b1;
                acmdrc--;
                {chipselect,scken,wbyte} = {2'b11, 8'hff};
            end else if(midc>0) begin         ismidc = 1'b1;
                midc--;
                {chipselect,scken,wbyte} = {2'b11, 8'hff};
            end else if(rwc>0) begin          isrwc  = 1'b1;
                rwc--;
                {chipselect,scken,wbyte} = {2'b11, 8'hff};
            end else if(stopc>0) begin
                stopc--;
                {chipselect,scken,wbyte} = {2'b11, 8'hff};
            end else if(rec>0) begin
                rec--;
                {chipselect,scken,wbyte} = {2'b01, 8'hff};
            end else if(lastc>0) begin
                lastc--;
                {chipselect,scken,wbyte} = {2'b00, 8'hff};
            end else begin
                {chipselect,scken,wbyte} = {2'b00, 8'hff};
            end
        end else if(byteend) begin
            if(iscmdr && ~rbyte[7]) begin
                cmdrsp    = rbyte;
                cmdrwait  = 0;
            end
            if( iscmdres) cmdres[cmdrc*8+:8] = rbyte;
            if(isacmdr && ~rbyte[7]) begin
                acmdrsp   = rbyte;
                acmdrwait = 0;
            end
            if(isacmdres) acmdres[acmdrc*8+:8] = rbyte;
            if(ismidc && rbyte==8'hFE) begin
                rwrsp = rbyte;
                midc  = 0;
            end
            if(isrwc) begin
                {rvalid, rdata} = {1'b1, rbyte};
                rindex = rwc;
            end
            {iscmdr, isacmdr,iscmdres,isacmdres,ismidc,isrwc} = 0;
        end
    end

assign done = start && start_last && (lastc==0);

endmodule
