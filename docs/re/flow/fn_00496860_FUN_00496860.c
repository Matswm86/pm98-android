// FUN_00496860  entry=00496860  size=125 bytes
// callers/callees expanded one level from seeds

undefined4 __thiscall
FUN_00496860(int param_1,undefined4 param_2,undefined4 param_3,undefined2 param_4,undefined2 param_5
            )

{
  int iVar1;
  
  *(undefined2 *)(param_1 + 0x1c84e) = param_5;
  *(undefined2 *)(param_1 + 0x1c84c) = param_4;
  *(undefined4 *)(param_1 + 4) = param_3;
  *(undefined4 *)(param_1 + 0x1c848) = param_2;
  *(int *)(param_1 + 0x444) = param_1;
  iVar1 = FUN_004937f0(param_2,0x18,0x4c,param_1);
  if (iVar1 == 0) {
    return 0;
  }
  *(undefined4 *)(param_1 + 8) = 6;
  *(undefined4 *)(param_1 + 0xc) = 1;
  FUN_00493ed0(*(undefined4 *)(*(int *)(param_1 + 4) + 8));
  return 1;
}


