// FUN_004e9e00  entry=004e9e00  size=298 bytes

void __fastcall FUN_004e9e00(int param_1)

{
  int iVar1;
  undefined4 uStack_22c;
  int iStack_228;
  int local_20c;
  int local_208;
  undefined1 *local_204;
  char local_200 [500];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00615986;
  local_c = ExceptionList;
  if (*(int *)(param_1 + 0xb0) != 0) {
    ExceptionList = &local_c;
    local_20c = FUN_005e2750();
    if (local_20c == 0) {
      local_4 = 1;
      local_208 = local_20c;
      FUN_004e7dd0();
      iStack_228 = 0x4e9e6b;
      sprintf(local_200,s_SFX_COMENT_UK_Otb_E_otb_02u_wav_00657db0);
      iStack_228 = 11000;
      uStack_22c = 0;
      iVar1 = FUN_005e2040(local_200,0x1a4,0);
      if (iVar1 != 0) {
        iVar1 = local_208 + 1;
        FUN_005bbf10();
        *(undefined4 *)(local_20c + -4 + iVar1 * 4) = 0x1a4;
        local_204 = (undefined1 *)&uStack_22c;
        local_208 = iVar1;
        FUN_004ec540(&local_20c);
        iVar1 = FUN_005e2210();
        if (iVar1 != 0) {
          uStack_22c = 0x4e9ef3;
          iStack_228 = param_1;
          FUN_004e6c20();
        }
      }
      local_4 = 0xffffffff;
      if (local_20c != 0) {
        FUN_005bbed0();
      }
    }
  }
  ExceptionList = local_c;
  return;
}


