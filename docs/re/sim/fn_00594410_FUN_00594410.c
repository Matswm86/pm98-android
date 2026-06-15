// FUN_00594410  entry=00594410  size=92 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_00594410(int param_1)

{
  int iVar1;
  
  iVar1 = *(int *)(param_1 + 0xa74) + *(int *)(param_1 + 0x754);
  if (iVar1 == 0) {
    iVar1 = 0x32;
  }
  else {
    iVar1 = (*(int *)(param_1 + 0x754) * 100) / iVar1;
  }
  FUN_00451180(((*(int *)(param_1 + 0x19a8) + *(int *)(param_1 + 0x450)) * 0x2d) /
               *(int *)(param_1 + 0x19ac),
               (*(int *)(param_1 + 0x450) * 0x2d) / *(int *)(param_1 + 0x19ac),iVar1);
  return;
}


