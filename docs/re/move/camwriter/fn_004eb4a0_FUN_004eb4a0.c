// FUN_004eb4a0  entry=004eb4a0  size=578 bytes

void __thiscall
FUN_004eb4a0(int param_1,int param_2,undefined4 param_3,undefined4 param_4,int param_5,int param_6)

{
  int iVar1;
  undefined4 uStack_22c;
  char *_Format;
  int local_20c;
  int local_208;
  undefined1 *local_204;
  char local_200 [500];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00615be6;
  local_c = ExceptionList;
  if (param_2 == 0x2d) {
    if ((*(int *)(param_1 + 0xb0) != 0) &&
       (ExceptionList = &local_c, iVar1 = FUN_005e2750(), iVar1 == 0)) {
      local_20c = 0;
      local_208 = 0;
      local_4 = 1;
      if ((((param_5 == 0) && (param_6 == 0)) || ((param_5 == 5 && (param_6 == 5)))) ||
         ((param_5 == 7 && (param_6 == 0)))) {
        if ((param_5 < 8) && (param_6 < 6)) {
          iVar1 = FUN_004e7dd0();
          if (iVar1 == 0) {
            _Format = s_SFX_COMENT_UK_Hlf_E_hlf_u_ua_wav_00657ed0;
          }
          else {
            _Format = s_SFX_COMENT_UK_Hlf_E_hlf_u_u_wav_00657ef4;
          }
          uStack_22c = 0x4eb56d;
          sprintf(local_200,_Format);
          uStack_22c = 0;
          iVar1 = FUN_005e2040(local_200,0x30c,0);
          if (iVar1 != 0) {
            iVar1 = local_208 + 1;
            FUN_005bbf10();
            *(undefined4 *)(local_20c + -4 + iVar1 * 4) = 0x30c;
            local_208 = iVar1;
          }
        }
      }
      else if ((param_5 < 8) && (param_6 < 6)) {
        uStack_22c = 0x4eb5e2;
        sprintf(local_200,s_SFX_COMENT_UK_Hlf_E_hlf_u_u_wav_00657ef4);
        uStack_22c = 0;
        iVar1 = FUN_005e2040(local_200,0x30c,0);
        if (iVar1 != 0) {
          iVar1 = local_208 + 1;
          FUN_005bbf10();
          *(undefined4 *)(local_20c + -4 + iVar1 * 4) = 0x30c;
          local_208 = iVar1;
        }
      }
      local_204 = (undefined1 *)&uStack_22c;
      FUN_004ec540(&local_20c);
      iVar1 = FUN_005e2210();
      if (iVar1 != 0) {
        uStack_22c = 0x4eb66a;
        FUN_004e6c20();
      }
      local_4 = 0xffffffff;
      if (local_20c != 0) {
        FUN_005bbed0();
      }
    }
  }
  else if ((((param_2 == 0xf) || (param_2 == 0x1e)) || (param_2 == 0x3c)) || (param_2 == 0x4b)) {
    uStack_22c = param_3;
    ExceptionList = &local_c;
    FUN_004eb6f0();
  }
  ExceptionList = local_c;
  return;
}


