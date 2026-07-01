// FUN_005ee670  entry=005ee670  size=105 bytes

undefined4 * __thiscall FUN_005ee670(undefined4 *param_1,short param_2)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  
  uVar3 = *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - param_2 >> 4 & 0xfffU) * 4);
  uVar1 = *(undefined4 *)(&DAT_006d31c8 + (param_2 + 8 >> 4 & 0xfffU) * 4);
  uVar2 = FUN_005edfb0(*param_1,uVar1,-param_1[1],uVar3);
  uVar3 = FUN_005edfb0(param_1[1],uVar1,*param_1,uVar3);
  param_1[1] = uVar3;
  *param_1 = uVar2;
  return param_1;
}


