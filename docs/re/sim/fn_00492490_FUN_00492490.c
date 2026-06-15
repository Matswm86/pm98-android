// FUN_00492490  entry=00492490  size=115 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_00492490(int param_1,int param_2,int param_3)

{
  undefined4 *puVar1;
  int iVar2;
  
  iVar2 = 0;
  if (0 < *(int *)(param_1 + 0x43c)) {
    do {
      puVar1 = (undefined4 *)(param_3 + iVar2 * 4);
      iVar2 = iVar2 + 1;
      *(undefined4 *)(*(int *)(param_1 + 0x444) + -4 + iVar2 * 4) =
           *(undefined4 *)((param_2 - param_3) + (int)puVar1);
      *(undefined4 *)(*(int *)(param_1 + 0x448) + -4 + iVar2 * 4) = *puVar1;
    } while (iVar2 < *(int *)(param_1 + 0x43c));
  }
  if (*(int *)(param_1 + 0x438) < *(int *)(param_1 + 0x43c)) {
    FUN_00492510(*(undefined4 *)(param_1 + 0x930));
    return;
  }
  FUN_00492510(0);
  return;
}


