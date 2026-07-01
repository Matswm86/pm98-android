// FUN_005b5d70  entry=005b5d70  size=82 bytes

void __fastcall FUN_005b5d70(int param_1)

{
  undefined2 uVar1;
  int iVar2;
  int iVar3;
  
  iVar2 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1614) - *(int *)(param_1 + 4);
  iVar3 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1618) - *(int *)(param_1 + 8);
  if (*(int *)(param_1 + 0x3bc) != 0) {
    iVar3 = *(int *)(param_1 + 0x3c4);
    iVar2 = *(int *)(param_1 + 0x3c0);
  }
  uVar1 = FUN_005ee080(iVar2,iVar3);
  *(undefined2 *)(param_1 + 0x34) = uVar1;
  FUN_005a5430(0x38);
  return;
}


