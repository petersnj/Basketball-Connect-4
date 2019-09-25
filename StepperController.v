`define MAX_STEPS_FROM_ORIGIN 32'd4900
`define CLK_CYCLES_PER_MOTOR_STEP 32'd500000

module StepperController(PCLK, PRESERN, PSEL, PENABLE, PWRITE, PREADY, PSLVERR,
    PADDR, PWDATA, PRDATA,
    lsw0, lsw1, black, red, green, blue
);
    input PCLK, PRESERN, PSEL, PENABLE, PWRITE;
    output wire PREADY, PSLVERR;
    input [31:0] PADDR, PWDATA;
    output reg [31:0] PRDATA;
    input lsw0, lsw1;//, reset;
    output black, red, green, blue;

    reg dir;
    reg [2:0] sync_lsw0, sync_lsw1;
    reg [3:0] state, next_state;
    reg [31:0] steps_from_origin, cycle_counter;
    wire lsw_db0, lsw_db1;

    // The possible states
    localparam s0 = 4'b1100, s1 = 4'b0110, s2 = 4'b0011, s3 = 4'b1001;

    // Set the outputs based on the current state
    assign {black, red, green, blue } = state;

    assign PREADY = 1; //assumes zero wait
    assign PSLVERR = 0; // assumes no error generation

    MDB db0(PCLK, lsw0, lsw_db0);
    MDB db1(PCLK, lsw1, lsw_db1);

    // Report how many steps from the origin the carriage is
    always @ (posedge PCLK)
        PRDATA <= steps_from_origin;

   // Button related tasks
    always @ (posedge PCLK)
    begin
        // Synchronize buttons with the clock
        sync_lsw0 <= {sync_lsw0[1], sync_lsw0[0], lsw_db0};
        sync_lsw1 <= {sync_lsw1[1], sync_lsw1[0], lsw_db1};

        if (~PRESERN)
        begin
            dir <= 1;
            cycle_counter <= 1;
            state <= s0;
            steps_from_origin <= `MAX_STEPS_FROM_ORIGIN;
        end
        else
        begin
            // Check if either button is pressed (but not both)
            if ((sync_lsw0[1] & ~sync_lsw0[2]) ^ (sync_lsw1[1] & ~sync_lsw1[2]))
            begin
                // If button 0 is pressed, the carriage is at the origin
                if (sync_lsw0[1])
                begin
                    // Rectify any error in the steps counter
                    steps_from_origin[31:0] <= 32'd0;

                    // Change direction
                    dir <= 1;
                end

                // If button 1 is pressed, the carriage is at the non-origin end
                if (sync_lsw1[1])
                begin
                    // Rectify any error in the steps counter
                    steps_from_origin[31:0] <= `MAX_STEPS_FROM_ORIGIN;

                    // Change direction
                    dir <= 0;
                end
            end
            else if (cycle_counter >= `CLK_CYCLES_PER_MOTOR_STEP)
            begin
                // Reset the counter
                cycle_counter <= 1;

                // Latch in the new state
                state <= next_state;

                // Latch in the new number of steps from origin
                if (dir)
                    steps_from_origin <= steps_from_origin + 1;
                // Otherwise, decrement
                else
                    steps_from_origin <= steps_from_origin - 1;
            end

            // Otherwise, keep counting
            else
                cycle_counter <= cycle_counter + 1;

            // Both switches aren't pressed
            // Also if both are pressed, but that __should__ never happen
        end
    end

    // Combinational logic for next state
    always @ (state, dir)
    begin
        case(state)

        s0:
        begin
            if (~dir)
                next_state <= s1;
            else
                next_state <= s3;
        end

        s1:
        begin
            if (~dir)
                next_state <= s2;
            else
                next_state <= s0;
        end

        s2:
        begin
            if (~dir)
                next_state <= s3;
            else
                next_state <= s1;
        end

        s3:
        begin
            if (~dir)
                next_state <= s0;
            else
                next_state <= s2;
        end

        default:
            next_state <= s0;
        endcase    
    end

endmodule

module MDB(clk, raw, debounced);
    input raw, clk;
    output reg debounced;

    reg [15:0] count; // 16 bit counter
    reg [1:0] sync; // used to sync button to clk

    // Sync the button to the clk with 2 DFF
    always @ (posedge clk)
        sync <= {sync[0], raw};

    // check if the new input is the same as the current output
    wire idle = (debounced == sync[1]); 
    wire count_is_maxed = &count;

    // When the input changes state, we start counting from 0
    // If the counter gets upto a certain value, the input was constant for that 
    // many cycles, therefore we can assume that it's real and not just a bounce
    always @ (posedge clk)
    begin
        if (idle)
            count <= 16'd0;

        else
        begin
            count <= count + 16'd1;
            if (count_is_maxed)
                debounced <= ~debounced;
        end
    end

endmodule