// FUN_00404c20  entry=00404c20  size=68 bytes

void __thiscall FUN_00404c20(void *this,int *param_1,uint param_2,undefined4 param_3)

{
  void *pvVar1;
  undefined4 uVar2;
  
  if (0xff < (ushort)param_3) {
    FUN_00404e60(this,param_1,param_2);
    return;
  }
  pvVar1 = this;
  uVar2 = param_3;
  FUN_004042e0(&stack0xfffffff4,&param_2);
  FUN_00404c70(this,param_1,pvVar1,uVar2);
  return;
}


