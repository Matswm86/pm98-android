// FUN_004f3180  entry=004f3180  size=394 bytes

int __thiscall
FUN_004f3180(int param_1,int param_2,int *param_3,undefined4 param_4,uint param_5,undefined4 param_6
            ,undefined4 param_7,undefined4 param_8)

{
  undefined4 uVar1;
  int iVar2;
  undefined4 *puVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  int local_40;
  int local_3c;
  int local_38;
  int local_34;
  int local_30;
  int local_2c;
  int local_28;
  int local_24;
  undefined1 local_20 [16];
  undefined1 local_10 [16];
  
  uVar5 = param_8;
  uVar6 = param_8;
  FUN_004ac740(&param_7);
  param_5 = param_5 | 0x200800;
  uVar4 = param_4;
  uVar1 = FUN_004ac2b0(local_20,3);
  iVar2 = FUN_005d4410(param_2,uVar1,uVar4,param_5,param_6,uVar5,uVar6);
  if (iVar2 != 0) {
    FUN_00437be0(&local_40,param_1 + 0x78);
    local_30 = local_40 + 3;
    local_2c = local_3c + 3;
    local_28 = local_38 + -3;
    local_24 = local_34 + -3;
    FUN_00437be0(local_20,param_1 + 0x78);
    puVar3 = (undefined4 *)FUN_004aa3e0(local_10,local_20);
    *(undefined4 *)(param_1 + 0x88) = *puVar3;
    *(undefined4 *)(param_1 + 0x8c) = puVar3[1];
    *(undefined4 *)(param_1 + 0x90) = puVar3[2];
    *(undefined4 *)(param_1 + 0x94) = puVar3[3];
    if (*(int *)(param_2 + 0x60) == 0xffffff) {
      param_8 = 0xff;
    }
    else {
      param_8 = 0xffffff;
    }
    FUN_00468c80(param_8);
    FUN_005beae0(s_ProMan10_006551e0);
    FUN_005e3c30(&local_40,param_4);
    if ((param_3[2] - *param_3) + -6 < local_40) {
      FUN_005beae0(s_ProMan8_00658928);
    }
    uVar4 = FUN_005e4670(s_Pasa8_00658920);
    *(undefined4 *)(param_1 + 0x3ac) = uVar4;
    uVar4 = FUN_005e4670(s_Selec8_00658918);
    *(undefined4 *)(param_1 + 0x398) = uVar4;
  }
  return iVar2;
}


