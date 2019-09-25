
module vgacontrol(  


input PCLK, 				// clock
input PRESERN, 				// system reset
input PSEL, 				// peripheral select
input PENABLE, 				// distinguishes access phase
output wire PREADY, 		// peripheral ready signal
output wire PSLVERR,		// error signal
input PWRITE,				// distinguishes read and write cycles
input [31:0] PADDR,			// I/O address
input wire [31:0] PWDATA,	// data from processor to I/O device (32 bits)
output reg [31:0] PRDATA,	// data to processor from I/O device (32-bits)
output HS, 
output VS, 
output vga_R, 
output vga_G, 
output vga_B,
input SW,
input SW2,
input SW3
);

// MMIO synchronous handler
assign PSLVERR = 0;
assign PREADY = 1;
reg [31:0] player1;
reg [31:0] player2;
reg [31:0] whichplayer;
reg [31:0] winner;
//players wires
wire player1_score;
wire player2_score;
//p1_score
wire p1_p;
//p2_score
wire p2_p;
//p_underlines
wire p_u;
//winner
wire win_out;
//winning player
wire pwin_out1;
wire pwin_out2;
wire player1_write = (PSEL & PENABLE & PWRITE & (PADDR[11:0] == 12'h104));
wire player2_write = (PSEL & PENABLE & PWRITE & (PADDR[11:0] == 12'h108));
wire whichplayer_write = (PSEL & PENABLE & PWRITE & (PADDR[11:0] == 12'h114));
wire winner_write = (PSEL & PENABLE & PWRITE & (PADDR[11:0] == 12'h118));
wire SWDebounce;
wire SWDebounce2;
wire SWDebounce3;


Button_Debouncer(PCLK, SW, SWDebounce);
Button_Debouncer(PCLK, SW2, SWDebounce2);
Button_Debouncer(PCLK, SW3, SWDebounce3);

always @(posedge PCLK) 		//register control for APB3 reads
begin
    if(PADDR[11:0] == 12'h100)
    begin
        PRDATA[31:1] <= 31'h00000000;				//initialize the PRDATA
        PRDATA[0] <= SWDebounce; 	//read switch values to PRDATA
    end
    else if(PADDR[11:0] == 12'h104)
    begin				
        PRDATA <= player1;
    end
    else if(PADDR[11:0] == 12'h108)
    begin				
        PRDATA <= player2;
    end
    else if(PADDR[11:0] == 12'h10C)
    begin
        PRDATA[31:1] <= 31'h00000000;				//initialize the PRDATA
        PRDATA[0] <= SWDebounce2; 
    end
    else if(PADDR[11:0] == 12'h114)
    begin				//initialize the PRDATA
        PRDATA <= whichplayer; 
    end
    else if(PADDR[11:0] == 12'h118)
    begin
        PRDATA[31:1] <= 31'h00000000;				//initialize the PRDATA
        PRDATA[0] <= SWDebounce3; 
    end
end

always @(posedge PCLK) 		// register control for APB3 writes
begin
	if(!PRESERN)
    begin
        player1 <= 32'd0;
        player2 <= 32'd0;
    end
    else if(player1_write)
        player1 <= PWDATA;
	else if(player2_write)
        player2 <= PWDATA;
    else if(whichplayer_write)
        whichplayer <= PWDATA;
    else if(winner_write)
        winner <= PWDATA;
end

// VGA display positioning
wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

hvsync_generator syncgen(.clk(quarterclk), .vga_h_sync(HS), .vga_v_sync(VS), 
                            .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

// Draw a border around the screen
wire border = (CounterX[9:3]==0) || (CounterX[9:3]==79) || (CounterY[8:3]==0) || (CounterY[8:3]==60) || (CounterX[9:3]==40) || (CounterX[9:3]==39);
//write each players score
scoreDraw(player1, player1_score, 32'd16, 32'd22, CounterX, CounterY, 8'd1);
scoreDraw(player2, player2_score, 32'd56, 32'd22, CounterX, CounterY, 8'd1);
//numbershift(player1, player1_score, 32'd12, 32'd22, CounterX, CounterY, 8'd1);
//numbershift(player2, player2_score, 32'd54, 32'd22, CounterX, CounterY, 8'd1);
//labels for player 1
pscoreDraw(CounterX, CounterY, 2, 2, 0, p1_p);
//labels for player 2
pscoreDraw(CounterX, CounterY, 42, 2, 1, p2_p);
//underline for players
whichDraw(CounterX, CounterY, whichplayer, p_u);
//giant winning player
pwinDraw(flashclk, CounterX, CounterY, 22, 2, 1, pwin1_out);
pwinDraw(flashclk, CounterX, CounterY, 22, 2, 2, pwin2_out);
//white winner label
winnerDraw(flashclk, CounterX, CounterY, 10, 40, win_out);

wire R = (winner>0) ? (win_out | ((winner == 1) ? (pwin1_out  | (~win_out&~pwin1_out&flashclk)) : (~win_out&~pwin2_out&flashclk))) : (border | player1_score | player2_score | p1_p);
wire G = (winner>0) ? (win_out | ((winner == 1) ? (~win_out&~pwin1_out&half_flash) : (~win_out&~pwin2_out&half_flash))) : (border | player1_score | player2_score | p_u);
wire B = (winner>0) ? (win_out | ((winner == 2) ? (pwin2_out  | (~win_out&~pwin2_out&quarter_flash)) : (~win_out&~pwin1_out&quarter_flash))) : (border | player1_score | player2_score | p2_p);
wire quarterclk;
wire flashclk, half_flash, quarter_flash;
clkdivider(PCLK, quarterclk);
clkdivider_vgaFlash(PCLK, flashclk);
halfclk(flashclk, half_flash);
halfclk(half_flash, quarter_flash);
reg vga_R, vga_G, vga_B;
always @(posedge quarterclk)
begin
  vga_R <= R & inDisplayArea;
  vga_G <= G & inDisplayArea;
  vga_B <= B & inDisplayArea;
end

endmodule

module hvsync_generator(clk, vga_h_sync, vga_v_sync, inDisplayArea, CounterX, CounterY);
input clk;
output vga_h_sync, vga_v_sync;
output inDisplayArea;
output [9:0] CounterX;
output [8:0] CounterY;

//////////////////////////////////////////////////
reg [9:0] CounterX;
reg [8:0] CounterY;
wire CounterXmaxed = (CounterX==10'h2FF);

always @(posedge clk)
if(CounterXmaxed)
	CounterX <= 0;
else
	CounterX <= CounterX + 1;

always @(posedge clk)
if(CounterXmaxed) CounterY <= CounterY + 1;

reg	vga_HS, vga_VS;
always @(posedge clk)
begin
	vga_HS <= (CounterX[9:4]==6'h2D); // change this value to move the display horizontally
	vga_VS <= (CounterY==500); // change this value to move the display vertically
end

reg inDisplayArea;
always @(posedge clk)
if(inDisplayArea==0)
	inDisplayArea <= (CounterXmaxed) && (CounterY<480);
else
	inDisplayArea <= !(CounterX==639);
	
assign vga_h_sync = ~vga_HS;
assign vga_v_sync = ~vga_VS;

endmodule

//
// *** Button debouncer. ***
// Changes in the input are ignored until they have been consistent for 2^16 clocks.
//
module Button_Debouncer(
input clk,
input PB_in, // button input
output reg PB_out // debounced output
);
    reg [15:0] PB_cnt; // 16-bit counter
    reg [1:0] sync; // used as two flip-flops to synchronize
// button to the clk domain.
// First use two flipflops to synchronize the PB signal the "clk" clock domain
    always @(posedge clk)
        sync[1:0] <= {sync[0],~PB_in};
    wire PB_idle = (PB_out==sync[1]); // See if we have a new input state for PB
    wire PB_cnt_max = &PB_cnt; // true when all bits of PB_cnt are 1's
// using & in this way is a
// "reduction operation"
// When the push-button is pushed or released, we increment the counter.
// The counter has to be maxed out before we decide that the push-button
// state has changed
    always @(posedge clk) 
    begin
        if(PB_idle)
            PB_cnt<= 16'd0; // input and output are the same so clear counter
        else 
        begin
            PB_cnt<= PB_cnt + 16'd1; // input different than output, count
            if(PB_cnt_max)
            PB_out<= ~PB_out; // if the counter is maxed out,
            // change PB output
        end
    end
endmodule

module draw(input [31:0]CounterX, input [31:0]CounterY, input [31:0]leftx, input [31:0]rightx, input [31:0]topy, input [31:0]boty, output box); //ADD COLOR LATER
    assign box = (((CounterX[9:3]>=leftx) && (CounterX[9:3]<(rightx))) && ((CounterY[8:3]>=topy) && (CounterY[8:3]<(boty))));
endmodule

module numbershift(input [31:0]number, output reg player_shift, input [31:0]x, input [31:0]y, input [31:0]CounterX, input [31:0]CounterY, input [7:0]scale);
    
    parameter S = 5; parameter C = 16; parameter O = 0; parameter R = 17; parameter E = 18; parameter P = 19; parameter Wl = 20; parameter Wr = 21; parameter N = 22;
    
    wire box1,box2,box3,box4,box5,box6,box7;    
    
    draw(CounterX, CounterY, x, x+(4 << scale), y, y+(1<<scale), box1); //Top
    draw(CounterX, CounterY, x, x+(4 << scale), y+(8 << scale), y+(8 << scale) + (1 << scale), box2); //Bottom
    draw(CounterX, CounterY, x, x+(1<<scale), y, y+(4 << scale) + (1 << scale), box3); //Left Top
    draw(CounterX, CounterY, x, x+(1<<scale), y+(4 << scale), y+(8 << scale) + (1 << scale), box4); //Left Bottom
    draw(CounterX, CounterY, x+(4 << scale) - (1 << scale), x+(4 << scale), y, y+(4 << scale) + (1 << scale), box5); //Right Top
    draw(CounterX, CounterY, x+(4 << scale) - (1 << scale), x+(4 << scale), y+(4 << scale), y+(8 << scale) + (1 << scale), box6); // Right Bottom
    draw(CounterX, CounterY, x, x+(4 << scale), y+(4 << scale), y+(4 << scale) + (1 << scale), box7); // Middle

    always @*
    begin
        if(number == 32'd0)
            player_shift = box1 | box2 | box3 | box4 | box5 | box6;
        else if(number == 32'd1)
            player_shift = box3 | box4;
         else if(number == 32'd2)
            player_shift = box1 | box5 | box7 | box4 | box2;
         else if(number == 32'd3)
            player_shift = box1 | box5 | box7 | box6 | box2;
         else if(number == 32'd4)
            player_shift = box3 | box5 | box6 | box7;
         else if(number == 32'd5)
            player_shift = box1 | box2 | box3 | box6 | box7;        
         else if(number == 32'd6)
            player_shift = box1 | box2 | box3 | box4 | box6 | box7;        
         else if(number == 32'd7)
            player_shift = box1 | box5 | box6;        
         else if(number == 32'd8)
            player_shift = box1 | box2 | box3 | box4 | box5 | box6 | box7;        
         else if(number == 32'd9)
            player_shift = box1 | box3 | box5 | box6 | box7;
         else if(number == 32'd16)
            player_shift = box1 | box2 | box3 | box4;
         else if(number == 32'd17)
            player_shift = box1 | box3 | box4;
         else if(number == 32'd18)
            player_shift = box1 | box2 | box3 | box4 | box7;  
         else if(number == 32'd19)
            player_shift = box1 | box3 | box4 | box5 | box7;
         else if(number == 32'd20)
            player_shift = box2 | box3 | box4 | box6;
         else if(number == 32'd21)
            player_shift = box2 | box5 | box6;         
         else if(number == 32'd22)
            player_shift = box1 | box3 | box4 | box5 | box6;
         else
            player_shift = 0;
    end
endmodule

module scoreDraw(input [31:0]number, output reg player_shift, input [31:0]x, input [31:0]y, input [31:0]CounterX, input [31:0]CounterY, input [7:0]scale);
    wire player_shift1, player_shift2, player_shift3;
    numbershift(number, player_shift1, x, y, CounterX, CounterY, scale);
    numbershift(32'd1, player_shift2, x-5, y, CounterX, CounterY, scale);
    numbershift(number-10, player_shift3, x+5, y, CounterX, CounterY, scale);
    
    always @*
    begin
        if(number < 10 || number >15)
            player_shift = player_shift1;
        else
            player_shift = player_shift2 | player_shift3;
    end
endmodule

module pscoreDraw(input [31:0]CounterX, input [31:0]CounterY, input [31:0]x, input [31:0]y, input player, output player_shift);
    parameter spacing = 5;
    wire p, one_two, s, c, o, r, e;

    numbershift(19, p, x, y, CounterX, CounterY, 0); // P
    numbershift(player+1, one_two, x+5, y, CounterX, CounterY, 0); // player #
    numbershift(5, s, x+12, y, CounterX, CounterY, 0); // S
    numbershift(16, c, x+17, y, CounterX, CounterY, 0); // C
    numbershift(0, o, x+22, y, CounterX, CounterY, 0); // O
    numbershift(17, r, x+27, y, CounterX, CounterY, 0); // R
    numbershift(18, e, x+32, y, CounterX, CounterY, 0); // E
   
    assign player_shift = p | one_two | s | c | o | r | e;
endmodule

module winnerDraw(input clk,input [31:0]CounterX, input [31:0]CounterY, input [31:0]x, input [31:0]y, output win_out);

    wire w1, w2, i, n1, n2, e, r;
    reg tiny;

    always@(posedge clk)
    begin
        tiny <= ~tiny;
    end

    numbershift(20, w1, x, y, CounterX, CounterY, 1); // Wl
    numbershift(21, w2, x+7, y, CounterX, CounterY, 1); // W2
    numbershift(1, i, x+20, y, CounterX, CounterY, 1); // i
    numbershift(22, n1, x+26, y, CounterX, CounterY, 1); // n1
    numbershift(22, n2, x+36, y, CounterX, CounterY, 1); // n2
    numbershift(18, e, x+46, y, CounterX, CounterY, 1); // e
    numbershift(17, r, x+56, y, CounterX, CounterY, 1); // r
    
    assign win_out = (w1 | w2 | i | n1 | n2 | e | r) & tiny;
endmodule

module pwinDraw(input clk, input [31:0]CounterX, input [31:0]CounterY, input [31:0]x, input [31:0]y, input [31:0]winner, output pwin_out);
    parameter spacing = 5;
    wire p, num;
    //reg tiny;
//
    //always@(posedge clk)
    //begin
        //tiny <= ~tiny;
    //end

    numbershift(19, p, x, y, CounterX, CounterY, 2); // P
    numbershift(winner, num, x+24, y, CounterX, CounterY, 2); // player #

    assign pwin_out = (p | num);
endmodule

module whichDraw(input [31:0]CounterX, input [31:0]CounterY, input [31:0]player, output underline);
    wire box1, box2;
    draw(CounterX, CounterY, 2, 38, 12, 13, box1);
    draw(CounterX, CounterY, 43, 78, 12, 13, box2);
    assign underline = (player[0]) ? box2: box1;
endmodule