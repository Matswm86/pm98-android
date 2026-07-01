// FUN_005910c0  entry=005910c0  size=84 bytes

int __thiscall FUN_005910c0(int param_1,int param_2)

{
  int iVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  bool bVar6;
  
  iVar4 = param_1 + 6;
  iVar3 = param_2 + 0x99c;
  iVar5 = 2;
  do {
    iVar1 = 5;
    do {
      *(undefined1 *)(iVar1 + iVar4) = *(undefined1 *)(iVar1 + iVar3);
      bVar6 = iVar1 != 0;
      iVar1 = iVar1 + -1;
    } while (bVar6);
    iVar5 = iVar5 + -1;
    iVar3 = iVar3 + -800;
    iVar4 = iVar4 + -6;
  } while (iVar5 != 0);
  uVar2 = FUN_005ec240();
  *(undefined4 *)(param_1 + 0xc) = uVar2;
  *(undefined2 *)(param_1 + 0x10) = *(undefined2 *)(param_2 + 0x181c);
  return param_1;
}


