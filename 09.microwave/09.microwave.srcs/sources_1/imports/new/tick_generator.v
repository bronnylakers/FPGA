`timescale 1ns / 1ps


module tick_generator (
    input wire clk,
    input wire reset,
    output reg ms_tick,    // 1클럭 폭의 tick 출력 
    output reg s_tick      // 1s 폭의 tick 출력
    );
parameter INPUT_FREQ = 100_000_000;
parameter TICK_HZ = 100;
parameter  TICK_S_HZ = 1;
parameter TICK_MS_COUNT = INPUT_FREQ / TICK_HZ; // 100_0000   10ms
parameter TICK_S_COUNT = INPUT_FREQ  / TICK_S_HZ; // 1_00_000_000   1s

//  $clog2(TICK_COUNT) : TICK_COUNT을 표현하기 위한 최소 비트 폭
reg [$clog2(TICK_MS_COUNT)-1:0] ms_tick_counter=0; //16bits 카운터
reg [$clog2(TICK_S_COUNT)-1:0] s_tick_counter=0; //16bits 카운터


always @(posedge clk, posedge reset) begin
    if(reset) begin
        ms_tick_counter <= 0;
        ms_tick <= 0;
        s_tick_counter <= 0;
        s_tick <=0;
    end else begin
        //10ms 펄스
        if(ms_tick_counter == TICK_MS_COUNT-1) begin
            ms_tick_counter <=0;
            ms_tick <= 1'b1;
        end else begin
            ms_tick_counter <= ms_tick_counter +1;
            ms_tick <= 1'b0;
        end
        //1s 펄스
        if(s_tick_counter == TICK_S_COUNT-1) begin
            s_tick_counter <=0;
            s_tick <= 1'b1;
        end else begin
            s_tick_counter <= s_tick_counter +1;
            s_tick <= 1'b0;
        end
    end
end

endmodule
