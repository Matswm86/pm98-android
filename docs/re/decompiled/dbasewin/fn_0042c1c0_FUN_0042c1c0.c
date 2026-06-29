// FUN_0042c1c0  entry=0042c1c0  size=59 bytes

void __thiscall FUN_0042c1c0(void *this,int param_1,uint param_2)

{
  char cVar1;
  void *pvVar2;
  
  if (param_1 != 0) {
    cVar1 = FUN_004589b0(this,0xffffffff);
    if (cVar1 == '\0') {
      pvVar2 = FUN_00445f10(param_2);
      if (pvVar2 != (void *)0x0) {
        FUN_00458730(this,pvVar2,0,0,0x32,0);
      }
    }
  }
  return;
}


