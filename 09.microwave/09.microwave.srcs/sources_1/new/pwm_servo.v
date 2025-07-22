`timescale 1ns / 1ps

module pwm_servo(
    input  wire       clk,         // 100 MHz
    input  wire       reset,       // 비동기·동기 리셋
    input  wire       door_sw,     // 1: 문 열림 → 90°, 0: 문 닫힘 → 0°
    output reg         pwm_servo    // Pmod 헤더의 PWM 출력
);

    // 20 ms 주기 = 100 MHz × 20 ms = 2_000_000 사이클
    localparam integer PERIOD_CYCLES = 2_000_000;
    // 0° 위치 (1 ms 펄스)
    localparam integer PULSE_0DEG  = 60_000;
    // 90° 위치 (1.5 ms 펄스)
    localparam integer PULSE_90DEG = 150_000;

    // 주기 카운터 (21비트로 충분)
    reg [20:0] cycle_cnt;
    // 문 상태에 따라 선택될 펄스 폭
    reg [20:0] target_pulse;

    // 1) 주기 카운터
    always @(posedge clk or posedge reset) begin
        if (reset)                  cycle_cnt <= 21'd0;
        else if (cycle_cnt == PERIOD_CYCLES - 1)
                                    cycle_cnt <= 21'd0;
        else                        cycle_cnt <= cycle_cnt + 1;
    end

    // 2) 스위치(1=open, 0=close)에 따라 목표 펄스 폭 선택
    always @(*) begin
        if (door_sw)                // 1: 문 열림
            target_pulse = PULSE_90DEG;
        else                        // 0: 문 닫힘
            target_pulse = PULSE_0DEG;
    end

    // 3) PWM 생성
    always @(*) begin
        pwm_servo = (cycle_cnt < target_pulse) ? 1'b1 : 1'b0;
    end

endmodule
