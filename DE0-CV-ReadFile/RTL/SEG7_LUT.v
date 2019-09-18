module SEG7_LUT(
    input wire  rst_n,
    input wire  [3:0]  iDIG,
    output reg  [6:0]  oSEG
);

always @ (*)
    if(~rst_n) begin
        oSEG = 7'b1111111;
    end else begin
        case(iDIG)
        4'h0: oSEG = 7'b1000000;  //
        4'h1: oSEG = 7'b1111001;  //       ---t----
        4'h2: oSEG = 7'b0100100;  //      /      /
        4'h3: oSEG = 7'b0110000;  //      lt     rt
        4'h4: oSEG = 7'b0011001;  //     /      /
        4'h5: oSEG = 7'b0010010;  //    ---m----
        4'h6: oSEG = 7'b0000010;  //   /      /
        4'h7: oSEG = 7'b1111000;  //   lb    rb
        4'h8: oSEG = 7'b0000000;  //  /      /
        4'h9: oSEG = 7'b0011000;  // ---b----
        4'ha: oSEG = 7'b0001000;  //
        4'hb: oSEG = 7'b0000011;
        4'hc: oSEG = 7'b1000110;
        4'hd: oSEG = 7'b0100001;
        4'he: oSEG = 7'b0000110;
        4'hf: oSEG = 7'b0001110;
        endcase
    end

endmodule
