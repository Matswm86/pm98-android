// FUN_00539d70  entry=00539d70  size=156 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_00539d70(int param_1,undefined4 param_2,LPCSTR param_3,undefined4 *param_4)

{
  undefined4 *puVar1;
  int iVar2;
  
  FUN_005bbf10((int *)(param_1 + 0x1d60),(*(int *)(param_1 + 0x1d64) + 1) * 0x108);
  puVar1 = (undefined4 *)(*(int *)(param_1 + 0x1d60) + *(int *)(param_1 + 0x1d64) * 0x108);
  if (puVar1 != (undefined4 *)0x0) {
    *puVar1 = param_2;
    lstrcpyA((LPSTR)(puVar1 + 1),param_3);
    puVar1[0x41] = *param_4;
  }
  iVar2 = *(int *)(param_1 + 0x1d64) + 1;
  *(int *)(param_1 + 0x1d64) = iVar2;
  FUN_005dbe70(iVar2,0xc,1,0xc);
  FUN_005dbf00(*(int *)(param_1 + 0x1d64) + -1);
  FUN_005bec80(1);
  return;
}


