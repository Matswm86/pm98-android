// FUN_00404930  entry=00404930  size=78 bytes

void __thiscall FUN_00404930(void *this,int *param_1,int param_2,uint param_3,undefined4 param_4)

{
  void *pvVar1;
  undefined4 uVar2;
  
  if (0xff < (ushort)param_4) {
    FUN_00404510(this,param_1,param_2,param_3);
    return;
  }
  pvVar1 = this;
  uVar2 = param_4;
  FUN_004042e0(&stack0xfffffff4,&param_3);
  FUN_00404980(this,param_1,param_2,pvVar1,(ushort)uVar2);
  return;
}


