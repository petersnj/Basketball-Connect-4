module BreakBeam(
    input clk,
    input wire signal_in,
    output reg FABINT
);

    wire db_signal;

    Button_Debouncer db(clk, signal_in, db_signal);

    //shift debounced switch input//
    reg synced_pulse[2:0];
    always@( posedge clk)
    begin
        synced_pulse[0] <= db_signal;
        synced_pulse[1] <= synced_pulse[0];
        synced_pulse[2] <= synced_pulse[1];
    end

    //use shifted switch inputs to create a one clock cycle pulse//
    wire bb_int = (synced_pulse[1] == 1'b0) & (synced_pulse[2] == 1'b1);
    
    reg [50:0]counter;
    reg timing;
    //create a FABINT pulse if break beam has been broken
    always@(posedge clk)
    begin
        if(bb_int && timing)
        begin
            FABINT <= 1;
            timing <= 0;
            counter <= 50'd0;
        end
        else
        begin
            FABINT <= 0;
            counter <= counter + 1;
            if(counter > 100000000)
                timing <= 1;            
        end
    end

endmodule

