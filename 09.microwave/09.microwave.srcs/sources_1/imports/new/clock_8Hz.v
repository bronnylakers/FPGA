`timescale 1ns / 1ps

module clock_8Hz(
    input i_clk,         // 100MHz 클럭 입력
    input i_reset,       // 비동기 리셋
    output reg o_clk8Hz  // 8Hz 출력 클럭
);

    reg [22:0] i_count = 0; // 12500000까지 세려면 24비트 필요

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            o_clk8Hz <= 0;
            i_count <= 0;
        end else begin
            if (i_count == (125000/2) - 1) begin
                i_count <= 0;
                o_clk8Hz <= ~o_clk8Hz;
            end else begin
                i_count <= i_count + 1;
            end
        end
    end
endmodule
