// FUN_005d4ac0  entry=005d4ac0  size=282 bytes

undefined4 __thiscall FUN_005d4ac0(int *param_1,int *param_2,int param_3)

{
  int iVar1;
  bool bVar2;
  char extraout_AL;
  char cVar3;
  undefined3 extraout_var;
  undefined3 uVar4;
  int iVar5;
  byte *pbVar6;
  byte *pbVar7;
  int local_24;
  int local_20;
  int local_1c;
  int local_18;
  
  local_24 = *param_2 + param_1[0xe];
  local_1c = param_2[2] + param_1[0xe];
  local_20 = param_2[1] + param_1[0xf];
  local_18 = param_2[3] + param_1[0xf];
  if (local_24 <= param_1[10]) {
    local_24 = param_1[10];
  }
  if (local_20 <= param_1[0xb]) {
    local_20 = param_1[0xb];
  }
  if (param_1[0xc] <= local_1c) {
    local_1c = param_1[0xc];
  }
  if (param_1[0xd] <= local_18) {
    local_18 = param_1[0xd];
  }
  FUN_005d4240();
  param_2._3_1_ = '\x01' - (extraout_AL != '\0');
  uVar4 = extraout_var;
  if (param_2._3_1_ == '\0') {
    if ((*param_1 == 0) && (cVar3 = FUN_005cb2b0(), cVar3 == '\0')) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    uVar4 = 0;
    if (bVar2) {
      iVar1 = param_1[7];
      local_18 = local_18 - local_20;
      local_1c = local_1c - local_24;
      pbVar7 = (byte *)(local_20 * iVar1 + *param_1 + -1 + local_24);
      uVar4 = 0;
      iVar5 = local_1c;
LAB_005d4b9b:
      do {
        pbVar6 = pbVar7 + 1;
        *pbVar6 = *(byte *)(param_3 + (uint)*pbVar6);
        if (iVar5 != 1) {
          pbVar6 = pbVar7 + 2;
          *pbVar6 = *(byte *)(param_3 + (uint)*pbVar6);
          if (iVar5 != 2) {
            pbVar6 = pbVar7 + 3;
            *pbVar6 = *(byte *)(param_3 + (uint)*pbVar6);
            if (iVar5 != 3) {
              pbVar7 = pbVar7 + 4;
              iVar5 = iVar5 + -4;
              *pbVar7 = *(byte *)(param_3 + (uint)*pbVar7);
              pbVar6 = pbVar7;
              if (iVar5 != 0) goto LAB_005d4b9b;
            }
          }
        }
        pbVar7 = pbVar6 + (iVar1 - local_1c);
        local_18 = local_18 + -1;
        iVar5 = local_1c;
      } while (local_18 != 0);
      param_2._3_1_ = '\x01';
    }
  }
  return CONCAT31(uVar4,param_2._3_1_);
}


