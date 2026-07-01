// FUN_004ec1e0  entry=004ec1e0  size=853 bytes

void __thiscall FUN_004ec1e0(int param_1)

{
  int iVar1;
  int in_stack_0000001c;
  int in_stack_00000020;
  char *_Format;
  int local_210;
  int local_20c;
  undefined1 *local_208;
  int local_204;
  char local_200 [500];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00615d26;
  local_c = ExceptionList;
  if (*(int *)(param_1 + 0xb0) == 0) {
    return;
  }
  ExceptionList = &local_c;
  iVar1 = FUN_005e2750();
  if (iVar1 != 0) {
    ExceptionList = local_c;
    return;
  }
  local_210 = 0;
  local_20c = 0;
  local_4 = 1;
  if (in_stack_0000001c == in_stack_00000020) {
    iVar1 = FUN_004e7dd0();
    if ((iVar1 != 0) || (5 < in_stack_0000001c)) {
      FUN_004e7dd0();
      sprintf(local_200,s_SFX_COMENT_UK_End_E_end_02u_wav_00658040);
      iVar1 = FUN_005e2040(local_200,1000,0);
      if (iVar1 != 0) {
        iVar1 = local_20c + 1;
        FUN_005bbf10();
        *(undefined4 *)(local_210 + -4 + iVar1 * 4) = 1000;
        local_20c = iVar1;
      }
      goto LAB_004ec4cc;
    }
    if ((7 < in_stack_0000001c) || (5 < in_stack_00000020)) goto LAB_004ec4cc;
    FUN_004e7dd0();
    sprintf(local_200,s_SFX_COMENT_UK_Fll_E_fll_u_u_c_wa_00658060);
    iVar1 = FUN_005e2040(local_200,1000,0);
  }
  else {
    if (*(int *)(param_1 + 0xb4) == 0) {
      FUN_004e7dd0();
      sprintf(local_200,s_SFX_COMENT_UK_End_E_end_02u_wav_00658040);
      iVar1 = FUN_005e2040(local_200,1000,0);
      if (iVar1 != 0) {
        local_204 = local_20c + 1;
        local_208 = (undefined1 *)(local_204 * 4);
        FUN_005bbf10();
        local_20c = local_204;
        *(undefined4 *)(local_210 + -4 + (int)local_208) = 1000;
      }
      if ((in_stack_0000001c < 8) && (in_stack_00000020 < 6)) {
        FUN_004e7dd0();
        sprintf(local_200,s_SFX_COMENT_UK_Fll_E_fll_u_u_c_wa_00658060);
        iVar1 = FUN_005e2040(local_200,0x3e9,0);
        if (iVar1 != 0) {
          iVar1 = local_20c + 1;
          FUN_005bbf10();
          *(undefined4 *)(local_210 + -4 + iVar1 * 4) = 0x3e9;
          local_20c = iVar1;
        }
      }
      goto LAB_004ec4cc;
    }
    if (in_stack_00000020 < in_stack_0000001c) {
      FUN_004e7dd0();
      _Format = s_SFX_COMENT_UK_Hw11_W_htw_02u_wav_0065801c;
    }
    else {
      FUN_004e7dd0();
      _Format = s_SFX_COMENT_UK_Aw11_E_atw_02u_wav_00657ff8;
    }
    sprintf(local_200,_Format);
    iVar1 = FUN_005e2040(local_200,1000,0);
  }
  if (iVar1 != 0) {
    iVar1 = local_20c + 1;
    FUN_005bbf10();
    *(undefined4 *)(local_210 + -4 + iVar1 * 4) = 1000;
    local_20c = iVar1;
  }
LAB_004ec4cc:
  local_208 = &stack0xfffffdcc;
  FUN_004ec540(&local_210);
  iVar1 = FUN_005e2210();
  if (iVar1 != 0) {
    FUN_004e6c20();
  }
  local_4 = 0xffffffff;
  if (local_210 != 0) {
    FUN_005bbed0();
  }
  ExceptionList = local_c;
  return;
}


