module pwmcontrol(
/*** APB3 BUS INTERFACE ***/
input PCLK, // clock
input PRESERN, // system reset
input PSEL, // peripheral select
input PENABLE, // distinguishes access phase
output wire PREADY, // peripheral ready signal
output wire PSLVERR, // error signal
input PWRITE, // distinguishes read and write cycles
input [31:0] PADDR, // I/O address
input wire [31:0] PWDATA, // data from processor to I/O device (32 bits)
output reg [31:0] PRDATA, // data to processor from I/O device (32-bits)
/*** I/O PORTS DECLARATION ***/
output reg pwm_register
);


`define period 120 //1.2 us
`define t0L 35
`define t1L 65
`define resetPeriod 900000

assign PSLVERR = 0;
assign PREADY = 1;

//MMIO addr for functions Base: 0x40050000
/*	SW: 0x4005000
    neo_info: 0x40050010
*/

reg [23:0] pwmvalue [29:0]; //number we are writing as PWM [1 or 0] for 24 bit block
reg [5:0] counter_24;
reg [5:0] counter_30;
reg [31:0] counter_reset;
reg [31:0] count;

//assign pwmvalue[0] = 24'h00FF00;
//assign pwmvalue[1] = 24'h00FF;
//assign pwmvalue[2] = 24'h00FF0F;
wire neoInfo_write = PSEL & PWRITE & PENABLE & (PADDR[11:0] == 12'h010);
//wire PWM_write = PWRITE & PSEL & PENABLE & (PADDR[5:0] == 6'h00);


////MMIO handler [READ]
//always @(posedge PCLK) 		//register control for APB3 reads
//begin	
    //PRDATA[31:1] <= 31'h00000000;				//initialize the PRDATA
	//PRDATA[0] <= buttonDebounce; 	            //read switch values to PRDATA
//end

//MMIO handler [WRITE]
always @(posedge PCLK) 		// register control for APB3 writes
begin
	if(!PRESERN)
        pwmvalue[0] <= 24'd0;
	else if(neoInfo_write)
    begin
		pwmvalue[PWDATA[31:24]] <= PWDATA[23:0];
    end
end

//led data send
always @(posedge PCLK)
begin

    if(counter_30 == 30)
    begin
        counter_30 <= 0;
        counter_reset <= 1;
    end

    if(counter_reset == 0)
    begin
        if (count == `period)
        begin
            count <= 0;
            if(counter_24 == 0)
            begin
                counter_24 <= 23;
                counter_30 <= counter_30 + 1;
                //update the LED table
                //pwmvalue[neonum][23:0] = color_val;
            end
            else
                counter_24 <= counter_24 - 1;
        end
        else
            count <= count + 1;
        
        if(pwmvalue[counter_30][counter_24] == 0)
        begin
            if (count <= `t0L)
                pwm_register <= 1;
            else
                pwm_register <= 0;
        end
        
        else if(pwmvalue[counter_30][counter_24] == 1)
        begin
            if (count <= `t1L)
                pwm_register <= 1;
            else
                pwm_register <= 0;
        end
    end
    else
    begin
        pwm_register <= 0;
        if(counter_reset >= `resetPeriod)
        begin    
            counter_reset <= 0;
            counter_30 <= 0;
            counter_24 <= 23;
            count <= 0;
        end
        else
            counter_reset <= counter_reset + 1;
    end
end
endmodule

