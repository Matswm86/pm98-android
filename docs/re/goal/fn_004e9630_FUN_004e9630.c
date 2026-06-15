// FUN_004e9630  entry=004e9630  size=474 bytes

void __thiscall FUN_004e9630(int param_1,undefined4 param_2,int param_3)

{
  int iVar1;
  undefined4 uStack_22c;
  int iStack_228;
  char *_Format;
  int local_20c;
  int local_208;
  undefined1 *local_204;
  char local_200 [500];
  void *local_c;
  undefined *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &DAT_006158c6;
  local_c = ExceptionList;
  if (*(int *)(param_1 + 0xb0) == 0) {
    return;
  }
  ExceptionList = &local_c;
  iVar1 = FUN_005e2750();
  if (iVar1 == 0) {
    iVar1 = FUN_004e79e0();
    if (((iVar1 == 0) && (iVar1 = FUN_004e79e0(), iVar1 == 0)) &&
       (iVar1 = FUN_004e79e0(), iVar1 == 0)) {
      ExceptionList = local_c;
      return;
    }
    local_20c = 0;
    local_208 = 0;
    local_4 = 1;
    iVar1 = FUN_004e79e0();
    if (((iVar1 == 0) || (param_3 != 0)) &&
       ((iVar1 = FUN_004e79e0(), iVar1 != 0 || (iVar1 = FUN_004e79e0(), iVar1 != 0)))) {
      if ((param_3 == 0) || (iVar1 = FUN_004e79e0(), iVar1 == 0)) {
        _Format = s_SFX_COMENT_JugPorte_Por_05d_00657ce4;
      }
      else {
        _Format = s_SFX_COMENT_Jug2_Jug_05d_00657d00;
      }
    }
    else {
      _Format = s_SFX_COMENT_Jug_Jug_05d_00657d18;
    }
    iStack_228 = 0x4e9749;
    sprintf(local_200,_Format);
    iStack_228 = 11000;
    uStack_22c = 0;
    iVar1 = FUN_005e2040(local_200,0x122,0);
    if (iVar1 != 0) {
      iVar1 = local_208 + 1;
      FUN_005bbf10();
      *(undefined4 *)(local_20c + -4 + iVar1 * 4) = 0x122;
      local_204 = (undefined1 *)&uStack_22c;
      local_208 = iVar1;
      FUN_004ec540(&local_20c);
      iVar1 = FUN_005e2210();
      if (iVar1 != 0) {
        uStack_22c = 0x4e97d1;
        iStack_228 = param_1;
        FUN_004e6c20();
      }
    }
    local_4 = 0xffffffff;
    if (local_20c != 0) {
      FUN_005bbed0();
    }
    ExceptionList = local_c;
    return;
  }
  ExceptionList = local_c;
  return;
}


