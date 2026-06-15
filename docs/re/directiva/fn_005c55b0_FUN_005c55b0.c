// FUN_005c55b0  entry=005c55b0  size=387 bytes

uint __thiscall
FUN_005c55b0(int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,uint param_5,
            undefined4 param_6,undefined4 param_7,undefined4 param_8)

{
  uint uVar1;
  void *pvVar2;
  int iVar3;
  int iVar4;
  undefined4 uStack_210;
  CHAR aCStack_20c [512];
  void *pvStack_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_006212ae;
  pvStack_c = ExceptionList;
  ExceptionList = &pvStack_c;
  if ((DAT_00674c60 != (int *)0x0) && (ExceptionList = &pvStack_c, (param_5 & 0x3000) != 0)) {
    ExceptionList = &pvStack_c;
    (**(code **)(*DAT_00674c60 + 0xf0))(0xffffffff);
    DAT_00674c60 = (int *)0x0;
  }
  FUN_004ac740(&param_7);
  uVar1 = FUN_005bc780(param_2,param_3,param_4,param_5,param_6);
  if ((uVar1 != 0) && ((param_5 & 4) != 0)) {
    *(int *)(param_1 + 600) = param_1;
    iVar3 = *(int *)(param_1 + 0x80) - *(int *)(param_1 + 0x78);
    iVar4 = *(int *)(param_1 + 0x84) - *(int *)(param_1 + 0x7c);
    *(undefined4 *)(param_1 + 0x3fc) = 0;
    *(undefined4 *)(param_1 + 0x400) = 0;
    *(int *)(param_1 + 0x404) = iVar3;
    *(int *)(param_1 + 0x408) = iVar4;
    *(undefined4 *)(param_1 + 0x40c) = 0;
    *(undefined4 *)(param_1 + 0x410) = 0;
    *(int *)(param_1 + 0x414) = iVar3;
    *(int *)(param_1 + 0x418) = iVar4;
    pvVar2 = operator_new(0x194);
    uStack_4 = 0;
    if (pvVar2 == (void *)0x0) {
      iVar3 = 0;
    }
    else {
      iVar3 = FUN_005d7240();
    }
    uStack_4 = 0xffffffff;
    if (iVar3 == 0) {
      uStack_210 = 0xffff0002;
      lstrcpyA(aCStack_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&uStack_210,(ThrowInfo *)&DAT_0063ac98);
    }
    *(int *)(param_1 + 0x3f4) = iVar3;
    uVar1 = (uint)(iVar3 != 0);
  }
  ExceptionList = pvStack_c;
  return uVar1;
}


