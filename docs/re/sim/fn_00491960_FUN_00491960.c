// FUN_00491960  entry=00491960  size=1622 bytes
// callers/callees expanded one level from seeds

undefined4 __thiscall
FUN_00491960(int param_1,undefined4 param_2,int *param_3,undefined2 param_4,int param_5,int param_6,
            undefined4 param_7)

{
  uint uVar1;
  bool bVar2;
  int iVar3;
  undefined4 uVar4;
  int iVar5;
  int *piVar6;
  void *pvVar7;
  uint uVar8;
  int *piVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  int local_230;
  undefined4 uStack_210;
  CHAR aCStack_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_0060eeae;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *(undefined4 *)(param_1 + 0x430) = param_7;
  iVar5 = *param_3;
  local_230 = param_3[2];
  *(undefined2 *)(param_1 + 0x434) = param_4;
  *(int *)(param_1 + 0x438) = param_5;
  *(int *)(param_1 + 0x43c) = param_6;
  if (param_5 < param_6) {
    local_230 = local_230 + 0x10;
  }
  if (param_6 < param_5) {
    *(int *)(param_1 + 0x438) = param_6;
  }
  FUN_00436270();
  iVar3 = FUN_005bc780(param_2);
  if (iVar3 == 0) {
    uVar4 = 0;
  }
  else {
    if (*(int *)(param_1 + 0x438) < *(int *)(param_1 + 0x43c)) {
      iVar3 = *(int *)(param_1 + 0x508);
      FUN_00436270();
      FUN_00436fb0(0xe);
      uVar4 = FUN_00436fb0((local_230 - iVar5) + -0x10,2);
      FUN_00436fd0(uVar4);
      iVar5 = (**(code **)(iVar3 + 0xc0))(param_1);
      if (iVar5 == 0) {
        ExceptionList = local_c;
        return 0;
      }
      FUN_005dbe70();
      FUN_005dbf00();
      FUN_005c06d0();
      FUN_005c06d0();
      FUN_005c06d0();
      FUN_005c06d0();
      *(uint *)(param_1 + 0x9e4) = *(uint *)(param_1 + 0x9e4) | 0x400800;
      *(uint *)(param_1 + 0xe00) = *(uint *)(param_1 + 0xe00) | 0x400800;
      FUN_004936f0();
      FUN_004706c0();
      FUN_00493700();
      FUN_004706c0();
      FUN_00493710();
      FUN_004706c0();
    }
    iVar5 = *(int *)(param_1 + 0x438);
    piVar6 = operator_new(iVar5 * 0x58c + 4);
    uStack_4 = 0;
    if (piVar6 == (int *)0x0) {
      piVar9 = (int *)0x0;
    }
    else {
      piVar9 = piVar6 + 1;
      *piVar6 = iVar5;
      FUN_00605ee0();
    }
    uStack_4 = 0xffffffff;
    if (piVar9 == (int *)0x0) {
      uStack_210 = 0xffff0002;
      lstrcpyA(aCStack_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&uStack_210,(ThrowInfo *)&DAT_0063ac98);
    }
    *(int **)(param_1 + 0x440) = piVar9;
    if (piVar9 == (int *)0x0) {
      uVar4 = 0;
    }
    else {
      uVar8 = 0;
      bVar2 = true;
      if (0 < *(int *)(param_1 + 0x438)) {
        do {
          uVar1 = uVar8 + 1;
          iVar5 = FUN_0048df50();
          if (iVar5 == 0) {
            bVar2 = false;
          }
          else {
            FUN_005beae0();
            if ((uVar8 & 1) == 0) {
              FUN_00437020();
              FUN_00437020();
              FUN_00437020(0xff);
              FUN_00437020(0x2a,0x3f);
              uVar11 = 0xa0;
              uVar10 = 0x8c;
              uVar4 = 0x78;
            }
            else {
              FUN_00437020();
              FUN_00437020();
              FUN_00437020(0xff);
              FUN_00437020(0x2a,0x3f);
              uVar11 = 0x8c;
              uVar10 = 0x78;
              uVar4 = 100;
            }
            FUN_00437020(uVar4,uVar10,uVar11);
            FUN_00491fc0();
          }
          uVar8 = uVar1;
        } while ((int)uVar1 < *(int *)(param_1 + 0x438));
      }
      pvVar7 = operator_new(*(int *)(param_1 + 0x43c) << 2);
      if (pvVar7 == (void *)0x0) {
        uStack_210 = 0xffff0002;
        lstrcpyA(aCStack_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&uStack_210,(ThrowInfo *)&DAT_0063ac98);
      }
      *(void **)(param_1 + 0x444) = pvVar7;
      pvVar7 = operator_new(*(int *)(param_1 + 0x43c) << 2);
      if (pvVar7 == (void *)0x0) {
        uStack_210 = 0xffff0002;
        lstrcpyA(aCStack_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&uStack_210,(ThrowInfo *)&DAT_0063ac98);
      }
      *(void **)(param_1 + 0x448) = pvVar7;
      if ((*(int *)(param_1 + 0x444) == 0) || (pvVar7 == (void *)0x0)) {
        bVar2 = false;
      }
      else {
        iVar5 = 0;
        if (0 < *(int *)(param_1 + 0x43c)) {
          do {
            iVar5 = iVar5 + 1;
            *(int *)(*(int *)(param_1 + 0x448) + -4 + iVar5 * 4) = param_1 + 0x44c;
            *(undefined4 *)(*(int *)(param_1 + 0x444) + -4 + iVar5 * 4) =
                 *(undefined4 *)(*(int *)(param_1 + 0x448) + -4 + iVar5 * 4);
          } while (iVar5 < *(int *)(param_1 + 0x43c));
        }
      }
      if (bVar2) {
        uVar4 = 1;
      }
      else {
        operator_delete(*(void **)(param_1 + 0x444));
        *(undefined4 *)(param_1 + 0x444) = 0;
        operator_delete(*(void **)(param_1 + 0x448));
        *(undefined4 *)(param_1 + 0x448) = 0;
        if (*(int **)(param_1 + 0x440) != (int *)0x0) {
          (**(code **)(**(int **)(param_1 + 0x440) + 4))();
        }
        *(undefined4 *)(param_1 + 0x440) = 0;
        uVar4 = 0;
      }
    }
  }
  ExceptionList = local_c;
  return uVar4;
}


