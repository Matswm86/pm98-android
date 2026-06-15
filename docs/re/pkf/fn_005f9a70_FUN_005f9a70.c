// FUN_005f9a70  entry=005f9a70  size=112 bytes

undefined4 __thiscall FUN_005f9a70(undefined4 *param_1,undefined4 *param_2,uint param_3)

{
  BOOL BVar1;
  uint uVar2;
  undefined4 *puVar3;
  
  uVar2 = param_3;
  if ((param_1[1] != 0) && (param_1[1] != -1)) {
    puVar3 = (undefined4 *)(param_1[2] + param_1[4]);
    for (uVar2 = param_3 >> 2; uVar2 != 0; uVar2 = uVar2 - 1) {
      *param_2 = *puVar3;
      puVar3 = puVar3 + 1;
      param_2 = param_2 + 1;
    }
    for (uVar2 = param_3 & 3; uVar2 != 0; uVar2 = uVar2 - 1) {
      *(undefined1 *)param_2 = *(undefined1 *)puVar3;
      puVar3 = (undefined4 *)((int)puVar3 + 1);
      param_2 = (undefined4 *)((int)param_2 + 1);
    }
    param_1[4] = param_1[4] + param_3;
    return 1;
  }
  if (((param_3 != 0) &&
      (BVar1 = ReadFile((HANDLE)*param_1,param_2,param_3,&param_3,(LPOVERLAPPED)0x0), BVar1 == 1))
     && (param_3 == uVar2)) {
    return 1;
  }
  return 0;
}


