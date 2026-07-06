// FUN_00579a00  entry=00579a00  size=378 bytes

void __fastcall FUN_00579a00(int param_1)

{
  void *pvVar1;
  int iVar2;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_0061feab;
  local_c = ExceptionList;
  pvVar1 = *(void **)(param_1 + 0x268);
  local_4 = 0;
  ExceptionList = &local_c;
  if (pvVar1 != (void *)0x0) {
    ExceptionList = &local_c;
    if (*(int *)((int)pvVar1 + 8) != 0) {
      ExceptionList = &local_c;
      FUN_005bbed0(*(int *)((int)pvVar1 + 8));
      *(undefined4 *)((int)pvVar1 + 8) = 0;
    }
    *(undefined4 *)((int)pvVar1 + 0xc) = 0;
    operator_delete(pvVar1);
  }
  pvVar1 = *(void **)(param_1 + 0x26c);
  *(undefined4 *)(param_1 + 0x268) = 0;
  if (pvVar1 != (void *)0x0) {
    if (*(int *)((int)pvVar1 + 8) != 0) {
      FUN_005bbed0(*(int *)((int)pvVar1 + 8));
      *(undefined4 *)((int)pvVar1 + 8) = 0;
    }
    *(undefined4 *)((int)pvVar1 + 0xc) = 0;
    operator_delete(pvVar1);
  }
  *(undefined4 *)(param_1 + 0x26c) = 0;
  FUN_0057ce40();
  operator_delete(*(void **)(param_1 + 0x200));
  *(undefined4 *)(param_1 + 0x200) = 0;
  operator_delete(*(void **)(param_1 + 0x204));
  *(undefined4 *)(param_1 + 0x204) = 0;
  operator_delete(*(void **)(param_1 + 0x1e0));
  *(undefined4 *)(param_1 + 0x1e0) = 0;
  operator_delete(*(void **)(param_1 + 0x1e4));
  *(undefined4 *)(param_1 + 0x1e4) = 0;
  FUN_0057d230();
  iVar2 = *(int *)(param_1 + 0x3c);
  while (iVar2 != 0) {
    pvVar1 = *(void **)(param_1 + 0x3c);
    iVar2 = *(int *)((int)pvVar1 + 0x100);
    if (pvVar1 != (void *)0x0) {
      FUN_00581d70();
      operator_delete(pvVar1);
    }
    *(int *)(param_1 + 0x3c) = iVar2;
  }
  iVar2 = *(int *)(param_1 + 0x24);
  while (iVar2 != 0) {
    pvVar1 = *(void **)(param_1 + 0x24);
    iVar2 = *(int *)((int)pvVar1 + 0x100);
    if (pvVar1 != (void *)0x0) {
      FUN_00581d70();
      operator_delete(pvVar1);
    }
    *(int *)(param_1 + 0x24) = iVar2;
  }
  operator_delete(*(void **)(param_1 + 0xc));
  *(undefined4 *)(param_1 + 0xc) = 0;
  local_4 = 0xffffffff;
  if (*(int *)(param_1 + 0x44) != 0) {
    FUN_005bbed0(*(int *)(param_1 + 0x44));
    *(undefined4 *)(param_1 + 0x44) = 0;
  }
  *(undefined4 *)(param_1 + 0x48) = 0;
  ExceptionList = local_c;
  return;
}


