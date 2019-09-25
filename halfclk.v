
module halfclk( input PCLK, output wire newclk );

reg counter;
always@(posedge PCLK)
begin
    counter <= counter + 1;
end
assign newclk = counter;
endmodule

