// FUN_00404880  entry=00404880  size=78 bytes

void __thiscall FUN_00404880(void *this,int *param_1,int param_2,uint param_3,undefined4 param_4)

{
  void *pvVar1;
  undefined4 uVar2;
  
  if (0xff < (ushort)param_4) {
    FUN_00404490(this,param_1,param_2,param_3);
    return;
  }
  pvVar1 = this;
  uVar2 = param_4;
  FUN_004042e0(&stack0xfffffff4,&param_3);
  FUN_004048d0(this,param_1,param_2,pvVar1,(ushort)uVar2);
  return;
}


