// FUN_0057a3a0  entry=0057a3a0  size=55 bytes

int __fastcall FUN_0057a3a0(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  
  iVar3 = 0;
  for (iVar1 = *(int *)(param_1 + 0x24); iVar1 != 0; iVar1 = *(int *)(iVar1 + 0x100)) {
    if ((*(byte *)(iVar1 + 0x19) < 0xc) && (iVar2 = FUN_005836a0(), iVar2 == 0)) {
      iVar2 = FUN_00581e60();
      iVar3 = iVar3 + iVar2;
    }
  }
  return iVar3;
}


