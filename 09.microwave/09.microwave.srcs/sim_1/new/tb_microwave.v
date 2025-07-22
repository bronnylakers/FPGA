`timescale 1ns/1ps

module tb_top_microwave;

  // 1) 클럭 & 리셋
  reg clk = 0;
  always #5 clk = ~clk;    // 100MHz

  reg reset;
  initial begin
    // 초기 reset 펄스
    reset = 1;
    #100;
    @(posedge clk);
    reset = 0;
  end

  // 2) DUT 입력 신호들
  reg btn_sec   = 0;
  reg btn_min   = 0;
  reg btn_start = 0;
  reg door_sw   = 0;

  // 3) DUT 출력
  wire [3:0] an;
  wire [6:0] seg;
  wire       buzzer_out;
  wire       motor_pwm;
  wire       in1, in2;
  wire       pwm_servo;

  // 4) DUT 연결
  top_microwave dut (
    .clk        (clk),
    .reset      (reset),
    .btn_sec    (btn_sec),
    .btn_min    (btn_min),
    .btn_start  (btn_start),
    .door_sw    (door_sw),
    .an         (an),
    .seg        (seg),
    .buzzer_out (buzzer_out),
    .motor_pwm  (motor_pwm),
    .in1        (in1),
    .in2        (in2),
    .pwm_servo  (pwm_servo)
  );

  // 5) 테스트 시퀀스
  initial begin
    //문 열기 
    repeat(5) begin
    #20 door_sw=1;
    end

    repeat(2) begin
        #50 btn_sec=1;
        #50 btn_sec=0;
        #50 btn_min=1;
        #50 btn_min=0;
    end

    #20

    #20 btn_start = 1;
    #20 btn_start = 0;

    #2_00

    
    // — operating → 0 로 전이시켜 완료음 발생
    force dut.operating = 0;
    #20;
    release dut.operating;

    #20 door_sw =0;
    #2000
    door_sw=1;

    $finish;

  end

endmodule
