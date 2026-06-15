// FUN_005bebc0  entry=005bebc0  size=181 bytes

void __thiscall FUN_005bebc0(int *param_1,undefined1 param_2)

{
  char cVar1;
  bool bVar2;
  
  if (((*(char *)((int)param_1 + 0x3ee) != '\0') && (DAT_00674c60 != (int *)0x0)) &&
     (DAT_00674c60 != param_1)) {
    *(undefined1 *)((int)param_1 + 0x3ee) = 2;
    (**(code **)(*DAT_00674c60 + 0xf0))(0xffffffff,0xffffffff,0);
    DAT_00674c60 = (int *)0x0;
    *(undefined1 *)((int)param_1 + 0x3ee) = 1;
  }
  if (DAT_006658f4 != '\0') {
    *(undefined1 *)((int)param_1 + 0x69) = param_2;
    DAT_00674c70 = param_1;
  }
  cVar1 = *(char *)((int)param_1 + 0x69);
  if (((((cVar1 == '\x01') || (cVar1 == '\x02')) ||
       ((cVar1 == '\x04' || ((cVar1 == '\b' || (cVar1 == '\t')))))) || (cVar1 == '\x05')) ||
     ((((cVar1 == '\x06' || (cVar1 == '\n')) || (cVar1 == '\v')) ||
      ((cVar1 == '\r' || (cVar1 == '\x0e')))))) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  if ((bVar2) || (*(char *)((int)param_1 + 0x3ee) != '\0')) {
    FUN_005bec80(0);
  }
  return;
}


