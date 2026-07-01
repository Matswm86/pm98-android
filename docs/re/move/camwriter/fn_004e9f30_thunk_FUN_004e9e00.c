// thunk_FUN_004e9e00  entry=004e9f30  size=5 bytes

void __fastcall thunk_FUN_004e9e00(int param_1)

{
  int iVar1;
  undefined4 uStack_22c;
  int iStack_228;
  int iStack_20c;
  int iStack_208;
  undefined1 *puStack_204;
  char acStack_200 [500];
  void *pvStack_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_00615986;
  pvStack_c = ExceptionList;
  if (*(int *)(param_1 + 0xb0) != 0) {
    ExceptionList = &pvStack_c;
    iStack_20c = FUN_005e2750();
    if (iStack_20c == 0) {
      uStack_4 = 1;
      iStack_208 = iStack_20c;
      FUN_004e7dd0();
      iStack_228 = 0x4e9e6b;
      sprintf(acStack_200,s_SFX_COMENT_UK_Otb_E_otb_02u_wav_00657db0);
      iStack_228 = 11000;
      uStack_22c = 0;
      iVar1 = FUN_005e2040(acStack_200,0x1a4,0);
      if (iVar1 != 0) {
        iVar1 = iStack_208 + 1;
        FUN_005bbf10();
        *(undefined4 *)(iStack_20c + -4 + iVar1 * 4) = 0x1a4;
        puStack_204 = (undefined1 *)&uStack_22c;
        iStack_208 = iVar1;
        FUN_004ec540(&iStack_20c);
        iVar1 = FUN_005e2210();
        if (iVar1 != 0) {
          uStack_22c = 0x4e9ef3;
          iStack_228 = param_1;
          FUN_004e6c20();
        }
      }
      uStack_4 = 0xffffffff;
      if (iStack_20c != 0) {
        FUN_005bbed0();
      }
    }
  }
  ExceptionList = pvStack_c;
  return;
}


