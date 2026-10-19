//Master : 
//        1. there should be generation of SCL which is 100 / 400 KHz
//        2. Wait for start signal and then lower the SDA value when the SCL is high.IDLE
//           and Then enable the SDA_out_en line(inout line which control by the SDA_out_en signal).
//        3. Then loading the address and read_or_write bit into the shift register
//        4. By checking the falling SCL shift register should shift the value.
//        5. After shifting all(8) bits the need to release the SDA for acknowledgement signal
//          sample the ACK at rising edge. If Acknowledgement came then check read or write bit
//        6. if Write then send the all(8) data bits at falling edges and take the control of SDA channel
//        7. after sending the 8 bits of data read the ACK signal on rising edge of SCL. then
//          accordingly stop the sending.
//        8. if Read , then release the SDA channel and sample the inputs at rising edge of the SCL
//        9.  after collecting the 8 bits then take the control over SDA channel and send the ACK




//Problems 
//start hold introduced



module I2C_Master(clk,rst,start,write_data,addr,RorW,read_data,SDA,SCL,SCL_select,byte_count);
    input clk,rst,start,SCL_select;
    input [31:0]write_data;
    input [6:0]addr;
    input RorW;
    input [2:0]byte_count;
    output reg [7:0] read_data;
    output SCL;
    inout SDA;

    reg [3:0]state;
    
    parameter [3:0] IDLE = 4'b0000;
    parameter [3:0] START = 4'b0001;
    parameter [3:0] ADDRESS_SHIFTING = 4'b0010;
    parameter [3:0] ADDRESS_ACK = 4'b0011;
    parameter [3:0] MULTI_BYTE = 4'b0100;
    parameter [3:0] WDATA_SHIFTING = 4'b0101;
    parameter [3:0] WDATA_ACK = 4'b0110;
    parameter [3:0] RDATA_SHIFTING = 4'b0111;
    parameter [3:0] RDATA_ACK = 4'b1000;
    parameter [3:0] STOP = 4'b1001; 
    
    reg [7:0]shift_reg;
    reg start_hold;
    reg SDA_out_en,SDA_out;
    reg [3:0] counter;
    reg shifting;
    reg [2:0]bytes_sent;
// master sends the data at falling edge and slave recieve the data at raising edge  
    SCL_Generator scl(.clk_in(clk),.rst(rst),.clk_out(SCL),.SCL_select(SCL_select));
    
        reg scl_sync2, scl_sync1;
        always @(posedge clk) begin
            scl_sync2 <= SCL;
            scl_sync1 <= scl_sync2;
          if(rst)begin
                start_hold <= 1'b1;
          end
          else begin
            if(start == 1)begin
                start_hold <= 1'b1;
            end
            else if(state == IDLE & SCL == 1 & start_hold & (~shifting) )begin
                start_hold <= 1'b0;
            
            end
          end
        end
        wire SCL_Rise =  scl_sync2 & ~scl_sync1;
        wire SCL_Fall = ~scl_sync2 &  scl_sync1;

    //FSM logic
    
    always@(posedge clk or posedge rst)begin
        //reset
        
        if(rst)begin
            read_data <= 8'b00000000;
            state <= IDLE;
            SDA_out <= 1'b1;
            SDA_out_en <= 1'b0; 
            shifting <= 1'b0;
            counter <= 4'b0000;
            shift_reg <= 8'b00000000;
            bytes_sent <= 3'b000;
//            start_hold <= 1'b0;
            
        end
        else begin
            case(state)
                
                IDLE : begin
                    bytes_sent <= 3'b000;
                    shifting <= 1'b0;
                    SDA_out_en <= 1'b1;   
                    
                    if(start_hold & (~shifting))begin
                        shifting <= 1'b1;
                        if(SCL)begin                //changed
                        SDA_out <= 1'b0;
                        SDA_out_en <= 1'b1;
                        state <= START;
//                        start_hold <= 1'b0;
                     
                    end
                    end
                end
                
              START : begin
                
                shift_reg <= {addr[6:0],RorW};
                counter <= 4'b0000;
                state <= ADDRESS_SHIFTING;
                
              
              end
              
           ADDRESS_SHIFTING: begin
           
                if(SCL_Fall)begin
                    SDA_out <= shift_reg[7];
                    shift_reg <= {shift_reg[6:0],1'b1};
                    SDA_out_en <= 1'b1;
                    if(counter == 8)begin
                        state <= ADDRESS_ACK;
//                        if(SCL_Fall)begin
                        SDA_out_en <= 1'b0;
                        counter <= 4'b0000;
//                        end
                    end
                    else begin
                        counter <= counter + 1;
                    end
                                        
                end
                
           
           end   
           
           ADDRESS_ACK : begin
                 // release the SDA_out_en
//                 if(SCL_Fall)begin
//                    SDA_out_en <= 1'b0;
                 
//                 end
                 
                 if(SCL_Rise)begin
                    if(SDA == 1'b0)begin
                        SDA_out <= SDA;
                        
                        if(RorW == 1'b0)begin
                              
                            shift_reg <= write_data[7:0];
                            counter <= 4'b0000;
                            state <= WDATA_SHIFTING;
                            SDA_out_en <= 1'b1;
                        end
                        else begin
                            
                            counter <= 4'b0000;
                            state <= RDATA_SHIFTING;
                           
                        end
                    end
                    else begin // SDA != 0; then
                        
                        state <= STOP;
                        SDA_out_en <= 1'b1;
                    end
                 end
           
           end
           
           MULTI_BYTE : begin
           
                                if(bytes_sent == 0)
                                       shift_reg <= write_data[7:0];
                                 else if(bytes_sent == 1)
                                     shift_reg <= write_data[15:8];
                                 else if(bytes_sent == 2)
                                      shift_reg <= write_data[23:16];
                                else if(bytes_sent == 3)
                                     shift_reg <= write_data[31:24];  
                                  
                                  state <= WDATA_SHIFTING;
           end
           
           WDATA_SHIFTING :begin
              if(bytes_sent < byte_count)begin
                                
                if(SCL_Fall)begin
                    SDA_out <= shift_reg[7];
                    shift_reg <= {shift_reg[6:0],1'b1};
                    SDA_out_en <= 1'b1;
                    if(counter == 8)begin
                        state <= WDATA_ACK;
                        bytes_sent <= bytes_sent + 1;
                        SDA_out_en <= 1'b0;
                        counter <= 4'b0000;
                    end
                    else begin
                        counter <= counter + 1;
                    end
                
                end
           end
           
           else begin
                state <= STOP;
           end
           end
           
           WDATA_ACK : begin
//                if(SCL_Fall)begin
//                    SDA_out_en <= 1'b0; // release the SDA line
               
//                end
                if(SCL_Rise)begin               //cahnged
                    if(SDA == 1'b0)begin
                        
                        counter <= 4'b0000;
                        state <= MULTI_BYTE;
                         
                       
                    end
                    else begin
                        SDA_out_en <= 1'b1;
                        state <= STOP;
                    end
                end
               
               if(SCL_Fall)begin
                       SDA_out_en <= 1'b1; 
                    
               end
           end
           
           RDATA_SHIFTING : begin
                
                SDA_out_en <= 1'b0;
                if(SCL_Rise)begin// sample at posedge
//                    shift_reg[0] <= SDA;
                    shift_reg <= {shift_reg[6:0],SDA}; 
//                    read_data <= read_data[]
                    if(counter == 8)begin
                        state <= RDATA_ACK;
                        SDA_out <= 1'b0;
                        SDA_out_en <= 1'b1;
                        read_data <= shift_reg;
                        counter <= 4'b0000;
                    end
                    else begin
                        counter <= counter + 1;
                    end
                end
           end
           
           RDATA_ACK : begin
                if(SCL_Fall)begin
                    if(SDA == 0)begin
                        state <= RDATA_SHIFTING;
                    end
                    else begin
//                        SDA_out <= 1'b1;
//                       SDA_out_en <= 1'b1;
                        state <= STOP;
                    end
                end
           end
           
           STOP : begin  // stop condition is when the SCL is high at that time the SDA changes from 0 -> 1
                if(SCL_Fall)begin
                    SDA_out <= 1'b0;
                    SDA_out_en <= 1'b1;
                    
                end
                
                if(SCL_Rise)begin
                    SDA_out <= 1'b1;
                    SDA_out_en <= 1'b1;
                    state <= IDLE;
                    shifting <= 1'b0;
                end
           end
                
                default : begin
                
                        state <= IDLE;
                end
            endcase
        end
    
    end
    
assign SDA = SDA_out_en ? SDA_out : 1'bz;

endmodule


