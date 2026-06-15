// FUN_005eb400  entry=005eb400  size=225 bytes

void __thiscall FUN_005eb400(int param_1,int param_2)

{
  int iVar1;
  undefined4 *puVar2;
  int iVar3;
  HLOCAL pvVar4;
  int iVar5;
  
  iVar5 = 0;
  iVar3 = 0;
  if (0 < *(int *)(param_1 + 0xc)) {
    do {
      iVar5 = iVar3;
      iVar3 = *(int *)(*(int *)(param_1 + 0x18) + iVar5 * 4);
      if ((param_2 != 0) && (iVar1 = *(int *)(iVar3 + 0x1f8), iVar1 != 0)) {
        *(int *)(iVar3 + 0x1f8) = iVar1 + -1;
      }
      iVar3 = iVar5 + 1;
    } while (iVar5 + 1 < *(int *)(param_1 + 0xc));
  }
  if ((-1 < iVar5) && (iVar5 < *(int *)(param_1 + 0xc))) {
    if ((*(int *)(param_1 + 8) == 0) &&
       (puVar2 = *(undefined4 **)(*(int *)(param_1 + 0x18) + iVar5 * 4), puVar2 != (undefined4 *)0x0
       )) {
      (**(code **)*puVar2)(1);
    }
    if (iVar5 < *(int *)(param_1 + 0xc) + -1) {
      do {
        iVar5 = iVar5 + 1;
        *(undefined4 *)(*(int *)(param_1 + 0x18) + -4 + iVar5 * 4) =
             *(undefined4 *)(*(int *)(param_1 + 0x18) + iVar5 * 4);
      } while (iVar5 < *(int *)(param_1 + 0xc) + -1);
    }
    iVar3 = *(int *)(param_1 + 0xc) + -1;
    *(int *)(param_1 + 0xc) = iVar3;
    if ((*(int *)(param_1 + 0x14) * 2 <= *(int *)(param_1 + 0x10) - iVar3) &&
       (iVar5 = *(int *)(param_1 + 0x10) - *(int *)(param_1 + 0x14), iVar3 < iVar5)) {
      if (*(HLOCAL *)(param_1 + 0x18) == (HLOCAL)0x0) {
        pvVar4 = LocalAlloc(0x40,iVar5 * 4);
      }
      else {
        pvVar4 = LocalReAlloc(*(HLOCAL *)(param_1 + 0x18),iVar5 * 4,0x42);
      }
      *(HLOCAL *)(param_1 + 0x18) = pvVar4;
      if (pvVar4 != (HLOCAL)0x0) {
        *(int *)(param_1 + 0x10) = iVar5;
      }
    }
  }
  return;
}


