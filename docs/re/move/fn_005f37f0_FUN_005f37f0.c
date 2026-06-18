// FUN_005f37f0  entry=005f37f0  size=88 bytes

bool __thiscall FUN_005f37f0(int param_1,undefined4 param_2)

{
  int iVar1;
  int iVar2;
  bool bVar3;
  
  bVar3 = false;
  FUN_005f3600();
  FUN_005d82b0(param_1 + 0x10);
  iVar2 = *(int *)(param_1 + 4);
  do {
    if (iVar2 == 0) {
      return bVar3;
    }
    iVar1 = FUN_005f2990(param_2,0);
    bVar3 = iVar1 != 0;
    iVar2 = iVar2 + -1;
  } while (!bVar3);
  return bVar3;
}


