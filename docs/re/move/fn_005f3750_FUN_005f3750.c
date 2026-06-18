// FUN_005f3750  entry=005f3750  size=151 bytes

void __thiscall
FUN_005f3750(int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5
            )

{
  undefined4 *puVar1;
  int iVar2;
  undefined4 *puVar3;
  undefined4 local_60 [6];
  undefined4 local_48;
  undefined4 local_44;
  undefined1 local_30 [48];
  
  FUN_005f3600();
  FUN_005eea50(0x10000,0x10000,0);
  local_48 = param_3;
  local_44 = param_4;
  puVar1 = (undefined4 *)FUN_005ee800(local_30,local_60);
  puVar3 = local_60;
  for (iVar2 = 0xc; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar3 = *puVar1;
    puVar1 = puVar1 + 1;
    puVar3 = puVar3 + 1;
  }
  FUN_005d82b0(local_60);
  for (iVar2 = *(int *)(param_1 + 4); iVar2 != 0; iVar2 = iVar2 + -1) {
    FUN_005f2260(param_2,2,param_5);
  }
  return;
}


