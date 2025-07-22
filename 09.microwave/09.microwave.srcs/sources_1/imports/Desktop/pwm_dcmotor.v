`timescale 1ns / 1ps

module pwm_dcmotor (
    input  wire       clk,        // 100 MHz
    input  wire       reset,      // 동기·비동기 리셋
    input  wire       operating,  // 동작 중 플래그
    output            motor_pwm,  // 50 % 듀티 PWM (JA1)
    output            in1,        // H-브리지 IN1 (JA2)
    output            in2         // H-브리지 IN2 (JA3)
);

  // 1) 4비트 카운터: 0 → 15 → 0 순환 (100 MHz → 6.25 MHz 샘플링)
  reg [3:0] cnt;
  always @(posedge clk or posedge reset) begin
    if (reset)      cnt <= 4'd0;
    else            cnt <= cnt + 4'd1;
  end

  // 2) motor_pwm 생성: operating = 1인 동안 cnt < 8 → 50 % 듀티
  assign motor_pwm = operating & (cnt < 4'd8);

  // 3) IN1/IN2 제어: 정방향(10) 또는 코스트(00)
  assign in1 = operating ? 1'b1 : 1'b0;  // operating = 1 → IN1 = 1
  assign in2 = 1'b0;                     // 항상 IN2 = 0

endmodule
