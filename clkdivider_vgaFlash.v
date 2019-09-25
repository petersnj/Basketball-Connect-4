
module clkdivider_vgaFlash(input PCLK, output wire newclk );

reg[25:0] counter;
always@(posedge PCLK)
begin
    counter <= counter + 1;
end
assign newclk = counter[25];
endmodule

