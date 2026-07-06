// FUN_005eaf80  entry=005eaf80  size=168 bytes

void __thiscall
FUN_005eaf80(int param_1,int *param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5,
            undefined4 param_6,undefined4 param_7)

{
  int *piVar1;
  int iVar2;
  int iVar3;
  int *local_18;
  int local_14;
  undefined1 local_10 [8];
  undefined1 local_8 [8];
  
  iVar3 = 0;
  local_18 = (int *)(param_1 + 0x1c);
  iVar2 = 0;
  local_14 = 0;
  do {
    if (3 < local_14) break;
    if (*local_18 != 0) {
      piVar1 = (int *)FUN_005eb030(local_10,*local_18,param_3,param_4,param_5,param_6,param_7);
      iVar2 = *piVar1;
      iVar3 = piVar1[1];
      if (iVar2 == 0) {
        piVar1 = (int *)FUN_005eb240(local_8,*local_18,param_3,param_4,param_5,param_6,param_7);
        iVar2 = *piVar1;
        iVar3 = piVar1[1];
      }
    }
    local_14 = local_14 + 1;
    local_18 = local_18 + 1;
  } while (iVar2 == 0);
  *param_2 = iVar2;
  param_2[1] = iVar3;
  return;
}


