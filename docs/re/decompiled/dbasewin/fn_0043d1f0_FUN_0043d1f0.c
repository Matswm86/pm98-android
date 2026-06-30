// FUN_0043d1f0  entry=0043d1f0  size=68 bytes

void __thiscall FUN_0043d1f0(void *this,int *param_1,uint param_2,undefined4 param_3)

{
  void *pvVar1;
  undefined4 uVar2;
  
  if (0xff < (ushort)param_3) {
    FUN_0043d2d0(this,param_1,param_2);
    return;
  }
  pvVar1 = this;
  uVar2 = param_3;
  FUN_004042e0(&stack0xfffffff4,&param_2);
  FUN_0043d240(this,param_1,pvVar1,uVar2);
  return;
}


