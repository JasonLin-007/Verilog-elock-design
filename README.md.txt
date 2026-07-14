# Electronic Lock (e-lock) Design

這是一個使用 Verilog 實現的電子鎖電路專案。

## 功能簡介
此電子密碼鎖實現了以下功能： 
1. 4位數密碼 
2. 輸入失敗後有（失敗次數*10）秒的冷卻時間 
3. 可更改密碼

使用說明：此密碼鎖可以輸入最多4位數字的密碼，按下確認鍵以鎖定。鎖定後，需輸入密碼以解鎖。若解鎖成功，會亮綠燈；若失敗，則會顯示失敗次數並進入冷卻時間，冷卻時間會隨失敗次數遞增。冷卻結束後，即可繼續嘗試。成功解鎖後，可以重設密碼或沿用舊密碼並回到鎖定狀態。

## 檔案說明
* **elock.v**：電子鎖的核心控制邏輯（FSM）。包含模組：
	* elock_top：FSM與輸入密碼以外的狀態邏輯
	* number_select_save：輸入密碼時的邏輯
* **MC_TOP.v**：計數器。包含模組：
	* MC_TOP_mode4：計數器頂層模組
	* BTN_DEB：處理按鈕的debouncing
	* pulse_gen：產生一個clock的脈波
	* MC_mode4：負責計數

![簡易模組方塊圖](images/block_diagram.png)

## 使用的輸入與輸出 
1. rst：重置按鍵。按下後會從預設狀態（ PW_SELECT ）開始。 
2. btn_next_number：數字切換按鍵。可改變當前選擇的位數之數值。 
3. btn_next_digit：位數切換按鍵。可切換要輸入的位數。 
4.  btn_ENTER：確認按鍵。根據不同狀態，有送出密碼或切換狀態的功能。 
5.  display1~4：送 往 decoder 的 四 組 4-bit  BCD 碼。 此輸出各自連到麵包板上的四個IC7447，經解碼後再送往七段顯示器。  
6.  LED[0]~[3]：輸入位數指示燈，顯示當前選擇的位數。 
7.  RGBLED：顯示當前的的狀態。例如： IDLE 為白色、PW_SELECT 為黃色、 PW_ENTER 為藍色、 WRONG 與 COUNT_DOWN 為紅色、PASS 為綠色。在 FSM  diagram 裡有畫出其各自的代表顏色。

![FSM diagram](images/Elock_FSM.png)

## FSM狀態介紹
透過狀態機實現 elock 中不同 state 的切換。以下將介紹各個 state 的功能。 
1. PW_SELECT：此為 mode 4 的初始狀態，其作用為更改密碼。 
2.  SAVE_PW：儲存原始密碼。 
3.  PW_ENTER：輸入密碼。 
4.  CHECK_PW：檢查輸入密碼和原始密碼的異同。  
5.  PASS：RGBLED 亮綠光以標示，代表輸入密碼和原始密碼相同，成功解鎖。 
6.  IDLE：沿用舊密碼並重新上鎖。 
7.  WRONG：LED 亮紅光以標示，代表輸入密碼和原始密碼不同，解鎖失敗。 
8.  COUNT_DOWN：透過公式 cooling time = attend_count*10 ，計算出冷卻時間，最大值為 99 秒。冷卻時間會顯示在  7  段顯示器上並倒數，倒數結束後即回到 PW_ENTER 。