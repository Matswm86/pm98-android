// FUN_0051c2e0  entry=0051c2e0  size=2236 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_0051c2e0(int param_1)

{
  char cVar1;
  int iVar2;
  int iVar3;
  int *piVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  int *piVar7;
  int iVar8;
  int iVar9;
  uint uVar10;
  int extraout_ECX;
  int extraout_ECX_00;
  int extraout_ECX_01;
  int extraout_ECX_02;
  int iVar11;
  uint uVar12;
  int unaff_EBP;
  int unaff_ESI;
  uint uVar13;
  undefined1 *puVar14;
  undefined4 uVar15;
  int local_2c4;
  uint local_2c0;
  int local_2bc;
  uint local_2b8;
  int local_2b4;
  undefined4 local_2a4;
  undefined4 local_2a0;
  undefined4 local_29c;
  undefined4 local_298;
  undefined4 uStack_22c;
  CHAR aCStack_228 [24];
  undefined4 local_210;
  CHAR local_20c [484];
  void *pvStack_28;
  undefined4 uStack_20;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00618c71;
  local_c = ExceptionList;
  local_2bc = *(int *)(param_1 + 0x40);
  iVar2 = *(int *)(*(int *)(param_1 + 0x54) + 0x1e0);
  local_2b8 = (uint)*(byte *)(iVar2 + 0x34);
  local_2c0 = (uint)(*(char *)(iVar2 + 0x32) == '\x01');
  local_2c4 = *(int *)(iVar2 + 4) + *(int *)(iVar2 + 8);
  local_2b4 = param_1;
  if (*(int *)(iVar2 + 8) == 0) {
    ExceptionList = &local_c;
    piVar4 = operator_new(0x418);
    local_4 = 2;
    if (piVar4 == (int *)0x0) {
      piVar4 = (int *)0x0;
      iVar9 = extraout_ECX_01;
    }
    else {
      FUN_0043e8c0();
      *piVar4 = (int)&PTR_LAB_00624d08;
      iVar9 = extraout_ECX_02;
    }
    local_4 = 0xffffffff;
    if (piVar4 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar11 = *piVar4;
    FUN_00437020();
    FUN_00436fb0();
    FUN_00436fb0();
  }
  else {
    ExceptionList = &local_c;
    piVar4 = operator_new(0x418);
    local_4 = 0;
    if (piVar4 == (int *)0x0) {
      piVar4 = (int *)0x0;
    }
    else {
      FUN_0043e8c0();
      *piVar4 = (int)&PTR_LAB_00624d08;
    }
    local_4 = 0xffffffff;
    if (piVar4 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar9 = *piVar4;
    FUN_00437020();
    FUN_00436fb0();
    FUN_00436fb0();
    FUN_00436fd0();
    (**(code **)(iVar9 + 0xc0))();
    FUN_005beae0();
    FUN_005c5d30();
    piVar4 = operator_new(0x418);
    local_4 = 1;
    if (piVar4 == (int *)0x0) {
      piVar4 = (int *)0x0;
      iVar9 = extraout_ECX;
    }
    else {
      FUN_0043e8c0();
      *piVar4 = (int)&PTR_LAB_00624d08;
      iVar9 = extraout_ECX_00;
    }
    local_4 = 0xffffffff;
    if (piVar4 == (int *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    iVar11 = *piVar4;
    FUN_00437020();
    FUN_00436fb0();
    FUN_00436fb0();
  }
  FUN_00436fd0();
  (**(code **)(iVar11 + 0xc0))();
  FUN_005beae0();
  FUN_005c5d30();
  uVar13 = 0;
  iVar11 = iVar9;
  do {
    piVar4 = operator_new(0x418);
    uStack_20 = 3;
    if (piVar4 == (int *)0x0) {
      piVar4 = (int *)0x0;
    }
    else {
      FUN_005c7e20();
      *piVar4 = (int)&PTR_LAB_00630940;
    }
    uStack_20 = 0xffffffff;
    if (piVar4 == (int *)0x0) {
      uStack_22c = 0xffff0002;
      lstrcpyA(aCStack_228,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&uStack_22c,(ThrowInfo *)&DAT_0063ac98);
    }
    if (*(int *)(iVar9 + 8) == 0) {
      iVar8 = *piVar4;
      FUN_00436270(0xffffffff);
      iVar9 = uVar13 + 400;
      uVar15 = 0x60020;
      puVar14 = &DAT_00666f70;
      uVar5 = FUN_00436fb0(0xfe,0x2e);
      uVar6 = FUN_00436fb0(8,uVar13 * 0x3c + 0xa8);
      uVar5 = FUN_00436fd0(uVar6,uVar5);
      (**(code **)(iVar8 + 0xc0))(param_1,uVar5,puVar14,uVar15,iVar9);
      local_2c4 = 9;
      local_2bc = 0x16;
      local_2c0 = 0xd;
      local_2b8 = 0x1a;
      FUN_00437be0();
      piVar7 = (int *)FUN_004aa3e0();
      piVar4[0x22] = *piVar7;
      piVar4[0x23] = piVar7[1];
      piVar4[0x24] = piVar7[2];
      iVar8 = param_1 + 0x440;
      piVar4[0x25] = piVar7[3];
      iVar9 = iVar11;
    }
    else {
      iVar8 = *piVar4;
      FUN_00436270(0xffffffff);
      iVar9 = uVar13 + 400;
      uVar15 = 0x60020;
      puVar14 = &DAT_00666f70;
      uVar5 = FUN_00436fb0(0xfe,0x21);
      uVar6 = FUN_00436fb0(8,uVar13 * 0x24 + 0x8c);
      uVar5 = FUN_00436fd0(uVar6,uVar5);
      (**(code **)(iVar8 + 0xc0))(param_1,uVar5,puVar14,uVar15,iVar9);
      local_2a4 = 9;
      local_29c = 0x16;
      local_2a0 = 8;
      local_298 = 0x15;
      FUN_00437be0();
      piVar7 = (int *)FUN_004aa3e0();
      piVar4[0x22] = *piVar7;
      piVar4[0x23] = piVar7[1];
      piVar4[0x24] = piVar7[2];
      iVar8 = param_1 + 0x48c;
      piVar4[0x25] = piVar7[3];
      iVar9 = iVar11;
    }
    FUN_005c0d50(iVar8,1,0);
    if (((uVar13 == 0) || (uVar13 == 1)) || (uVar13 == 2)) {
      FUN_00468c70();
    }
    piVar4[0x15] = *(int *)(param_1 + 0x54);
    FUN_005beae0();
    FUN_005c0d50(param_1 + 0x4d8,0,0);
    iVar11 = iVar9;
    if ((unaff_EBP != 0) && (*(byte *)(iVar9 + 0x33) == uVar13)) {
      (**(code **)(*piVar4 + 0x114))();
    }
    if ((&stack0x00000000 != (undefined1 *)0x2ec) ||
       (iVar8 = FUN_0057e3f0(), 149999 < (uint)(iVar8 + unaff_ESI))) {
      FUN_005bf8c0();
    }
    FUN_005c5d30();
    uVar13 = uVar13 + 1;
  } while (uVar13 < 3);
  uVar13 = *(uint *)(iVar9 + 8);
  if (uVar13 != 0) {
    cVar1 = *(char *)(iVar9 + 0x32);
    uVar12 = 0;
    iVar9 = param_1;
    do {
      piVar4 = operator_new(0x418);
      uStack_20 = 4;
      if (piVar4 == (int *)0x0) {
        piVar4 = (int *)0x0;
      }
      else {
        FUN_005c7e20();
        *piVar4 = (int)&PTR_LAB_00630940;
      }
      uStack_20 = 0xffffffff;
      if (piVar4 == (int *)0x0) {
        uStack_22c = 0xffff0002;
        lstrcpyA(aCStack_228,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&uStack_22c,(ThrowInfo *)&DAT_0063ac98);
      }
      iVar3 = *piVar4;
      FUN_00436270(0xffffffff);
      iVar8 = uVar12 + 0x195;
      uVar15 = 0x60020;
      puVar14 = &DAT_00666f70;
      uVar5 = FUN_00436fb0(0xfe,0x21);
      uVar6 = FUN_00436fb0(8,uVar12 * 0x24 + 0x10c);
      uVar5 = FUN_00436fd0(uVar6,uVar5);
      (**(code **)(iVar3 + 0xc0))(iVar9,uVar5,puVar14,uVar15,iVar8);
      iVar8 = piVar4[0x20] - piVar4[0x1e];
      iVar9 = piVar4[0x21] - piVar4[0x1f];
      if (0x15 < iVar9) {
        iVar9 = 0x15;
      }
      if (0x16 < iVar8) {
        iVar8 = 0x16;
      }
      CRect::CRect((CRect *)&local_2c4,9,8,iVar8,iVar9);
      piVar4[0x22] = local_2c4;
      piVar4[0x23] = local_2c0;
      piVar4[0x24] = local_2bc;
      piVar4[0x25] = local_2b8;
      if (((uVar12 == 0) || (uVar12 == 1)) || (uVar12 == 2)) {
        FUN_00468c70();
      }
      piVar4[0x15] = *(int *)(iVar2 + 0x54);
      FUN_005beae0();
      FUN_005c0d50(param_1 + 0x4d8,0,0);
      FUN_005c0d50(param_1 + 0x48c,1,0);
      if ((cVar1 == '\x02') && (*(byte *)(iVar11 + 0x33) == uVar12)) {
        (**(code **)(*piVar4 + 0x114))();
      }
      if ((&stack0x00000000 != (undefined1 *)0x2ec) ||
         ((uVar12 != 0 && (uVar10 = FUN_0057e3f0(), uVar13 < uVar10)))) {
        FUN_005bf8c0();
      }
      FUN_005c5d30();
      uVar12 = uVar12 + 1;
      iVar9 = iVar2;
    } while (uVar12 < 3);
  }
  ExceptionList = pvStack_28;
  return;
}


