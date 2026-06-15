// FUN_004fa540  entry=004fa540  size=134 bytes

undefined4 __thiscall FUN_004fa540(int *param_1,int param_2)

{
  undefined4 uVar1;
  
  uVar1 = 0;
  if ((param_2 != 0) && (param_2 != param_1[0x10e])) {
    if ((DAT_00674c38 != '\0') && (param_1[0x10e] != 0)) {
      FUN_005c1db0();
    }
    FUN_005c18c0((&DAT_00658a44)[param_2],0,0,DAT_00674c38 == '\0');
    (**(code **)(*param_1 + 0x110))();
    if ((DAT_00674c38 != '\0') && (param_1[0x10e] != 0)) {
      FUN_005c1d70();
    }
    param_1[0x10e] = param_2;
    uVar1 = 1;
  }
  return uVar1;
}


