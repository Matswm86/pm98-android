// FUN_0055e4a0  entry=0055e4a0  size=819 bytes

void __fastcall FUN_0055e4a0(int *param_1)

{
  int iVar1;
  ushort uVar2;
  uint uVar3;
  uint uVar4;
  int *piVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  int iVar9;
  uint uVar10;
  uint uVar11;
  int iVar12;
  undefined4 uVar13;
  uint local_270;
  int iStack_26c;
  uint uStack_268;
  int iStack_264;
  int *local_260;
  uint uStack_258;
  int aiStack_238 [2];
  int iStack_230;
  undefined4 uStack_210;
  CHAR aCStack_20c [512];
  void *pvStack_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_0061deed;
  pvStack_c = ExceptionList;
  ExceptionList = &pvStack_c;
  FUN_005c5e90();
  if (param_1[0x64a] == 0x1e) {
    local_260 = (int *)(&DAT_0066b190)[param_1[0x64c]];
    uVar3 = (**(code **)(*local_260 + 0x50))();
  }
  else {
    local_260 = (int *)0x0;
    uVar3 = FUN_00586730();
  }
  local_270 = uVar3;
  if ((10 < uVar3) && (local_270 = uVar3 >> 1, local_270 * 2 < uVar3)) {
    local_270 = local_270 + 1;
  }
  iVar12 = (-(uint)(param_1[0x2676] != 0xffffff) & 0xe) + 2;
  CRect::CRect((CRect *)aiStack_238,0,0,param_1[0x267f] - param_1[0x267d],
               param_1[0x2680] - param_1[0x267e]);
  uVar10 = (iStack_230 + iVar12 * -2) - aiStack_238[0];
  if (local_270 * 0x1a < uVar10) {
    uVar10 = uVar10 + local_270 * -0x1a;
  }
  else {
    uVar10 = 0;
  }
  uVar11 = 0;
  if (uVar3 != 0) {
    iStack_264 = 0;
    uStack_268 = 0;
    do {
      if (param_1[0x64a] == 0x1e) {
        uVar2 = (**(code **)(*local_260 + 0x54))();
        uVar4 = (uint)uVar2;
      }
      else {
        uVar4 = FUN_00586770();
      }
      piVar5 = operator_new(0x418);
      uStack_4 = 0;
      if (piVar5 == (int *)0x0) {
        piVar5 = (int *)0x0;
      }
      else {
        FUN_005c7e20();
        *piVar5 = (int)&PTR_LAB_00635e30;
      }
      uStack_4 = 0xffffffff;
      if (piVar5 == (int *)0x0) {
        uStack_210 = 0xffff0002;
        lstrcpyA(aCStack_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&uStack_210,(ThrowInfo *)&DAT_0063ac98);
      }
      if (uVar11 < local_270) {
        uStack_258 = uStack_268;
        iStack_26c = iStack_264;
      }
      else {
        uStack_258 = uStack_268 - local_270 * uVar10;
        iStack_26c = iStack_264 + local_270 * -0x1a;
      }
      iVar1 = *piVar5;
      FUN_00436270(0);
      iVar9 = uVar11 + 400;
      uVar13 = 0x200000;
      uVar6 = FUN_004a9b80(uVar4);
      uVar7 = FUN_00436fb0(0x1a,0x24);
      uVar8 = FUN_00436fb0(uStack_258 / local_270 + iStack_26c + uVar10 / (local_270 * 2) + iVar12,
                           (-(uint)(uVar11 < local_270) & 0xffffffdb) + 0x43);
      uVar7 = FUN_00436fd0(uVar8,uVar7);
      (**(code **)(iVar1 + 0xc0))(param_1 + 0x265f,uVar7,uVar6,uVar13,iVar9);
      FUN_005c0d50(param_1 + 0x64f,0,0,0x32,0);
      piVar5[0x15] = uVar4;
      iVar9 = (**(code **)(*param_1 + 0x120))(uVar4);
      if ((iVar9 != 0) && ((~(byte)((uint)piVar5[0x2b] >> 7) & 1) != 0)) {
        FUN_005bf8c0();
      }
      FUN_005c5d30();
      uVar11 = uVar11 + 1;
      uStack_268 = uStack_268 + uVar10;
      iStack_264 = iStack_264 + 0x1a;
    } while (uVar11 < uVar3);
  }
  param_1[0x64e] = uVar3;
  ExceptionList = pvStack_c;
  return;
}


