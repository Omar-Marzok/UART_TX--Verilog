// for clock frequency 115.2 KHz
`timescale  1us/1ps

module UART_TX_tb #(parameter IN_data_tb = 8)();
    reg                   Data_Valid_tb;  
    reg                   PAR_EN_tb;
    reg                   clk_tb;
    reg                   RST_tb;
    reg [IN_data_tb -1:0] P_DATA_tb;
    reg                   PAR_TYP_tb;
   wire                   busy_tb;
   wire                   TX_OUT_tb;
   
/////////// parameters //////////
localparam CLK_PERIOD = 8.680555 ;
localparam WITH_PARITY = 1'b1, WITHOUT_PARITY = 1'b0;
localparam EVEN_PAR = 1'b0, ODD_PAR  = 1'b1;     
localparam NO_PAR_CASE = 2'b0 , EVEN_PAR_CASE = 2'B01,
           ODD_PAR_CASE = 2'B10, MULTI_VALID_CASE = 2'B11;  
/////////// reg signals ///////
reg [IN_data_tb :0]  recived_data; // this size as we have a parity bit + data size

////////// initial block //////
initial
begin
 $dumpfile("UART_TX.vcd") ;       
 $dumpvars;  
 
 initialize();
 reset ();

 send_data(8'd10,NO_PAR_CASE, recived_data );
 check_send_recived_data(8'd10, recived_data,NO_PAR_CASE  );
 
 send_data(8'd9,EVEN_PAR_CASE, recived_data );
 check_send_recived_data(8'd9, recived_data,EVEN_PAR_CASE  );
 
 send_data(8'd8,ODD_PAR_CASE, recived_data );
 check_send_recived_data(8'd8, recived_data,ODD_PAR_CASE  );
 
 send_data(8'd7,MULTI_VALID_CASE, recived_data );
 check_send_recived_data(8'd7, recived_data,MULTI_VALID_CASE  );
 
 #(3*CLK_PERIOD) $stop;
  
end
///////// tasks ////////
task initialize ;
  begin
    Data_Valid_tb = 1'b0;
    PAR_EN_tb     = 1'b0;
    clk_tb        = 1'b0;
    RST_tb        = 1'b0;
    P_DATA_tb     = 'b0;
    PAR_TYP_tb    = 1'b0;
  end
endtask

task reset ;
  begin
    RST_tb = 1'b1;
    #CLK_PERIOD
    RST_tb = 1'b0;
    #CLK_PERIOD
    RST_tb = 1'b1;
    #CLK_PERIOD;
  end
endtask

task send_data ;
  input [IN_data_tb -1:0] data;
  input [1:0] case_test;
  output [IN_data_tb :0] out_data;
  integer x;
  begin
    Data_Valid_tb = 1'b1;
    P_DATA_tb = data;
    
    case (case_test)
    NO_PAR_CASE : begin
                   PAR_EN_tb = WITHOUT_PARITY;
                   PAR_TYP_tb = EVEN_PAR;
                   $display("TEST CASE 1 send with no parity bit");
                  end
    EVEN_PAR_CASE : begin 
                     PAR_EN_tb = WITH_PARITY;
                     PAR_TYP_tb = EVEN_PAR;
                     $display("TEST CASE 2 send with even parity bit");      
                    end
    ODD_PAR_CASE : begin 
                     PAR_EN_tb = WITH_PARITY;
                     PAR_TYP_tb = ODD_PAR;
                     $display("TEST CASE 3 send with odd parity bit");      
                    end
    MULTI_VALID_CASE : begin 
                     PAR_EN_tb = WITHOUT_PARITY;
                     PAR_TYP_tb = EVEN_PAR;
                     $display("TEST CASE 4 send with multi valid  input data signal");      
                    end
      endcase
      
    #CLK_PERIOD
    Data_Valid_tb = 1'b0;
    #CLK_PERIOD
    if(busy_tb == 1'b1)
      $display("busy signal is high at simulation time %t",$time);
    else
      $display("error in busy signal is't high at the start of transmition");
    
    if(case_test == MULTI_VALID_CASE)
      begin
        Data_Valid_tb = 1'b1;
        P_DATA_tb = 8'hfc;
      end
    else
      begin
        Data_Valid_tb = 1'b0;
        P_DATA_tb = data;
      end
    
   	 for(x=0; x< IN_data_tb+1 ; x=x+1)
		  begin
		   #CLK_PERIOD out_data[x] = TX_OUT_tb ;
		  end
		  
      Data_Valid_tb = 1'b0;
      
		  #(2*CLK_PERIOD)
		  if(busy_tb == 1'b0)
      $display("busy signal is low at simulation time %t",$time);
    else
      $display("error in busy signal is't low at the_end of transmition");
  end
endtask

task check_send_recived_data ;
  input [IN_data_tb -1:0] send_data;
  input [IN_data_tb :0] reciv_data;
  input [1:0] case_test;
  begin
    if(send_data == reciv_data[IN_data_tb -1:0])
      $display("DATA was transmitted successfully");
    else
      $display("Data was transmitted faild with recived value = %0d",reciv_data[IN_data_tb -1:0]);
      
    case (case_test)
    NO_PAR_CASE : begin
                   $display("no parity bit for this Test Case ");
                  end
    EVEN_PAR_CASE : begin 
                      if(reciv_data[IN_data_tb] == 1'b0)
                        $display("EVEN parity is succeeded"); 
                      else
                        $display("ERROR IN PARITY BIT ");   
                    end
    ODD_PAR_CASE : begin 
                     if (reciv_data[IN_data_tb] == 1'b1)
                       $display("ODD parity is succeeded"); 
                     else
                        $display("ERROR IN PARITY BIT ");     
                    end
    MULTI_VALID_CASE : begin 
                          $display("no parity bit for this Test Case ");
                       end
      endcase    

  end
endtask
/////// clock generator ////////
always #(CLK_PERIOD/2) clk_tb = ~clk_tb ;

/////// instantiation ////////
UART_TX #(.IN_data(IN_data_tb)) DUT ( 
.Data_Valid(Data_Valid_tb),  
.PAR_EN(PAR_EN_tb),
.clk(clk_tb),
.RST(RST_tb),
.P_DATA(P_DATA_tb),
.PAR_TYP(PAR_TYP_tb),
.busy(busy_tb),
.TX_OUT(TX_OUT_tb) );

endmodule