
module clkdivider( input PCLK, output wire newclk );

reg[1:0] counter;
always@(posedge PCLK)
begin
    counter <= counter + 1;
end
assign newclk = counter[1];
endmodule

