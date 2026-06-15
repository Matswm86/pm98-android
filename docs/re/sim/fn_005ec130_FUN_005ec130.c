// FUN_005ec130  entry=005ec130  size=116 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_005ec130(int param_1)

{
  int iVar1;
  int *piVar2;
  int iVar3;
  int iVar4;
  
  if ((*(int *)(param_1 + 0x108) != 0) && (*(int *)(param_1 + 0x104) == 0)) {
    piVar2 = *(int **)(*(int *)((int)ThreadLocalStoragePointer + _tls_index * 4) + 8);
    iVar3 = piVar2[1];
    iVar1 = (iVar3 + 1) * 8;
    FUN_005bbf10(piVar2,iVar1);
    iVar4 = *piVar2;
    piVar2[1] = iVar3 + 1;
    *(undefined4 *)(iVar4 + -8 + iVar1) = *(undefined4 *)(param_1 + 0x100);
    *(undefined4 *)(iVar4 + -4 + iVar1) = *(undefined4 *)(param_1 + 0x104);
  }
  *(undefined4 *)(param_1 + 0x110) = 0;
  *(undefined4 *)(param_1 + 0x10c) = 0;
  *(undefined4 *)(param_1 + 0x108) = 0;
  return;
}


