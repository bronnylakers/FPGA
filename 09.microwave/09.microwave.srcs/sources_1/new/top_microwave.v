`timescale 1ns / 1ps

module top_microwave(
    input  wire        clk,         // 100MHz
    input  wire        reset,       // 리셋
    input  wire        btn_sec,     // 분 설정 버튼
    input  wire        btn_min,     // 초 설정 버튼
    input  wire        btn_start,   // 시작 버튼
    input  wire        door_sw,     // 문 열림/닫힘 스위치 (no debounce)
    output wire [3:0]  an,          // FND 자릿수 선택 (active low)
    output wire [6:0]  seg,         // FND 세그먼트 (gfedcba)
    output wire        buzzer_out,   // 부저 출력
    output             motor_pwm,    // 모터 드라이버 PWM 출력
    output wire        in1,         // JA1
    output wire        in2,         // JA2/JA3
    output             pwm_servo    //servo pwm 출력
);

    // 1) 버튼 디바운스 (분/초/시작 버튼만)
    wire sec_clean, min_clean, start_clean;
    button_debounce u_sec_deb   (.i_clk(clk), .i_reset(reset), .i_btn(btn_sec),   .o_btn_clean(sec_clean));
    button_debounce u_min_deb   (.i_clk(clk), .i_reset(reset), .i_btn(btn_min),   .o_btn_clean(min_clean));
    button_debounce u_start_deb (.i_clk(clk), .i_reset(reset), .i_btn(btn_start), .o_btn_clean(start_clean));

    // 2) 틱 생성기 (1ms, 1s)
    wire ms_tick, s_tick;
    tick_generator u_tick_gen (
      .clk     (clk),
      .reset   (reset),
      .ms_tick (ms_tick),
      .s_tick  (s_tick)
    );

    // 3) 분·초 설정 및 카운트다운 FSM
    wire [6:0] sec_seg, min_seg;
    wire       operating;
    wire       sec_evt, min_evt, start_evt;
    clock_setting u_clock (
      .i_clk       (clk),
      .i_reset     (reset),
      .i_btn_sec   (sec_clean),
      .i_btn_min   (min_clean),
      .i_btn_start (start_clean),
      .s_tick      (s_tick),
      .sec_seg     (sec_seg),
      .min_seg     (min_seg),
      .operating   (operating),
      .sec_evt     (sec_evt),
      .min_evt     (min_evt),
      .start_evt   (start_evt)
    );

    // 4) FND 컨트롤러
    fnd_controller u_fnd (
      .i_clk      (clk),
      .i_reset    (reset),
      .sec_data   (sec_seg),
      .min_data   (min_seg),
      .s_tick     (s_tick),
      .operating  (operating),
      .an         (an),
      .seg_data   (seg)
    );

    // 5) 부저: 버튼·문·조리완료 이벤트에 따라 beep
    buzzer u_buzzer (
      .clk        (clk),
      .reset      (reset),
      .operating  (operating),
      .sec_evt    (sec_evt),
      .min_evt    (min_evt),
      .start_evt  (start_evt),
      .door_sw   (door_sw),    // 바로 스위치 신호 전달
      .buzzer_out (buzzer_out)
    );

    pwm_dcmotor u_motor (
      .clk       (clk),
      .reset     (reset),
      .operating (operating),      // clock_setting 으로부터 넘어오는 동작 플래그
      .motor_pwm (motor_pwm), // Pmod 드라이버 IN 핀 등에 연결
      .in1       (in1),
      .in2       (in2)
    );

    pwm_servo u_servo (
      .clk       (clk),
      .reset     (reset),
      .door_sw   (door_sw),
      .pwm_servo (pwm_servo)
    );


endmodule
