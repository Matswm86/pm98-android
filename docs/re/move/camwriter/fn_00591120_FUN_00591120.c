// FUN_00591120  entry=00591120  size=86 bytes

void __thiscall FUN_00591120(int param_1,int param_2)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  bool bVar5;
  
  iVar2 = param_1 + 6;
  iVar3 = param_2 + 0x99c;
  iVar4 = 2;
  do {
    iVar1 = 5;
    do {
      *(undefined1 *)(iVar1 + iVar3) = *(undefined1 *)(iVar1 + iVar2);
      bVar5 = iVar1 != 0;
      iVar1 = iVar1 + -1;
    } while (bVar5);
    iVar4 = iVar4 + -1;
    iVar2 = iVar2 + -6;
    iVar3 = iVar3 + -800;
  } while (iVar4 != 0);
  FUN_005ec230(*(undefined4 *)(param_1 + 0xc));
  *(undefined2 *)(param_2 + 0x181c) = *(undefined2 *)(param_1 + 0x10);
  return;
}


