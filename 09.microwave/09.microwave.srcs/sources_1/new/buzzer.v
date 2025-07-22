`timescale 1ns/1ps

module buzzer(
    input  wire       clk,         // 100 MHz
    input  wire       reset,       // 비동기·동기 리셋
    input  wire       operating,   // 전자레인지 동작 중 플래그
    input  wire       sec_evt,     // 분 버튼 상승 엣지
    input  wire       min_evt,     // 초 버튼 상승 엣지
    input  wire       start_evt,   // 시작 버튼 상승 엣지
    input  wire       door_sw,     // 문 스위치 (열림/닫힘)
    output wire       buzzer_out   // 피에조 버저 출력
);

  //==========================================================================
  // 1) 음계별 half‐period 값 (100 MHz 기준, 반 주기)
  //==========================================================================
  localparam integer P_DO   = 382_444; // 130.8 Hz
  localparam integer P_RE   = 340_134; // 146.8 Hz
  localparam integer P_MI   = 303_041; // 164.8 Hz
  localparam integer P_SOL  = 255_102; // 196.0 Hz
  localparam integer P_LA   = 227_273; // 220.0 Hz

  //==========================================================================
  // 2) “50 ms” 비프용 타이머
  //==========================================================================
  localparam integer BEEP_LEN = 5_000_000; // 50 ms @100 MHz

  // 각 이벤트별 비프 플래그 및 카운터
  reg beep_do, beep_re, beep_mi, beep_sol, beep_la;
  reg [22:0] cnt_do, cnt_re, cnt_mi, cnt_sol, cnt_la;

  // 문 엣지, on/off 엣지 생성
  reg prev_door, prev_op;
  wire door_evt    = door_sw       ^ prev_door;
  wire onoff_evt   = (operating    ^ prev_op);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      prev_door <= 0;
      prev_op   <= 0;
    end else begin
      prev_door <= door_sw;
      prev_op   <= operating;
    end
  end

  //==========================================================================
  // 3) 이벤트 감지 → 50 ms 플래그 유지
  //==========================================================================
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      {beep_do, cnt_do,
       beep_re, cnt_re,
       beep_mi, cnt_mi,
       beep_sol, cnt_sol,
       beep_la, cnt_la} <= 0;
    end else begin
      // “도” (분 버튼)
      if      (sec_evt)      begin beep_do <= 1; cnt_do <= 0; end
      else if (beep_do)      if (cnt_do < BEEP_LEN) cnt_do <= cnt_do + 1; else beep_do <= 0;

      // “레” (초 버튼)
      if      (min_evt)      begin beep_re <= 1; cnt_re <= 0; end
      else if (beep_re)      if (cnt_re < BEEP_LEN) cnt_re <= cnt_re + 1; else beep_re <= 0;

      // “미” (시작 버튼)
      if      (start_evt)    begin beep_mi <= 1; cnt_mi <= 0; end
      else if (beep_mi)      if (cnt_mi < BEEP_LEN) cnt_mi <= cnt_mi + 1; else beep_mi <= 0;

      // “솔” (문 열림/닫힘)
      if      (door_evt)     begin beep_sol <= 1; cnt_sol <= 0; end
      else if (beep_sol)     if (cnt_sol < BEEP_LEN) cnt_sol <= cnt_sol + 1; else beep_sol <= 0;

      // “라” (ON/OFF 토글)
      if      (onoff_evt)    begin beep_la <= 1; cnt_la <= 0; end
      else if (beep_la)      if (cnt_la < BEEP_LEN) cnt_la <= cnt_la + 1; else beep_la <= 0;
    end
  end

  //==========================================================================
  // 4) Generate 로톤 제너레이터: 5개 톤 중 활성된 것만 위상 토글
  //==========================================================================
  reg [17:0]   r_cnt  [0:4];
  reg          r_phase[0:4];

  genvar i;
  generate
    for (i=0; i<5; i=i+1) begin : TONE
      // i==0: Do, 1:Re, 2:Mi, 3:Sol, 4:La
      wire enable = (i==0)? beep_do
                  : (i==1)? beep_re
                  : (i==2)? beep_mi
                  : (i==3)? beep_sol
                  :            beep_la;
      wire [17:0] halfp = (i==0)? P_DO
                        : (i==1)? P_RE
                        : (i==2)? P_MI
                        : (i==3)? P_SOL
                        :            P_LA;

      always @(posedge clk or posedge reset) begin
        if (reset) begin
          r_cnt[i]   <= 0;
          r_phase[i] <= 0;
        end else if (!enable) begin
          r_cnt[i]   <= 0;
          r_phase[i] <= 0;
        end else if (r_cnt[i] >= halfp-1) begin
          r_cnt[i]   <= 0;
          r_phase[i] <= ~r_phase[i];
        end else begin
          r_cnt[i] <= r_cnt[i] + 1;
        end
      end
    end
  endgenerate

  //==========================================================================
  // 5) 합산 출력
  //==========================================================================
  assign buzzer_out = |{r_phase[0], r_phase[1], r_phase[2], r_phase[3], r_phase[4]};

endmodule
